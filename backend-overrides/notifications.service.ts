import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';
import { cert, getApps, initializeApp, App } from 'firebase-admin/app';
import { getMessaging, Messaging } from 'firebase-admin/messaging';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private messaging?: Messaging;

  constructor(private readonly prisma: PrismaService, config: ConfigService) {
    const raw = config.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON');
    if (!raw) return;
    try {
      let parsed: unknown = JSON.parse(raw.trim());
      if (typeof parsed === 'string') parsed = JSON.parse(parsed);
      if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
        throw new Error('Service-account value must be a JSON object.');
      }

      const credentials = parsed as {
        type?: string;
        project_id?: string;
        client_email?: string;
        private_key?: string;
      };

      if (
        credentials.type !== 'service_account' ||
        !credentials.project_id ||
        !credentials.client_email ||
        !credentials.private_key
      ) {
        throw new Error('Service-account JSON is missing required fields.');
      }

      credentials.private_key = credentials.private_key.replace(/\\\\n/g, '\\n');
      const app: App =
        getApps().find((x) => x.name === 'darb-notifications') ??
        initializeApp(
          {
            credential: cert(credentials),
            projectId: credentials.project_id,
          },
          'darb-notifications',
        );
      this.messaging = getMessaging(app);
      this.logger.log(`Firebase Admin initialized for project ${credentials.project_id}.`);
    } catch (error) {
      const reason = error instanceof Error ? error.message : 'Unknown initialization error';
      this.logger.error(`Firebase Admin initialization failed: ${reason}. Push delivery is disabled.`);
    }
  }

  async register(userId: string, token: string, platform?: string) {
    return this.prisma.userDevice.upsert({
      where: { token },
      create: { userId, token, platform: platform?.slice(0, 20) },
      update: { userId, platform: platform?.slice(0, 20), updatedAt: new Date() },
      select: { id: true },
    });
  }

  async unregister(userId: string, token: string) {
    await this.prisma.userDevice.deleteMany({ where: { userId, token } });
    return { success: true };
  }

  async listMine(userId: string) {
    const [items, unreadCount] = await Promise.all([
      this.prisma.userNotification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 50,
        select: { id: true, title: true, body: true, type: true, data: true, readAt: true, createdAt: true },
      }),
      this.prisma.userNotification.count({ where: { userId, readAt: null } }),
    ]);
    return { items, unreadCount };
  }

  async markRead(userId: string, id: string) {
    const existing = await this.prisma.userNotification.findFirst({
      where: { id, userId },
      select: { id: true, readAt: true },
    });
    if (!existing) throw new NotFoundException('الإشعار غير موجود');
    if (existing.readAt) return { id: existing.id, readAt: existing.readAt };
    return this.prisma.userNotification.update({
      where: { id: existing.id },
      data: { readAt: new Date() },
      select: { id: true, readAt: true },
    });
  }

  async markAllRead(userId: string) {
    const res = await this.prisma.userNotification.updateMany({
      where: { userId, readAt: null },
      data: { readAt: new Date() },
    });
    return { updated: res.count };
  }

  async notifyVendor(vendorId: string, title: string, body: string, data: Record<string, string>) {
    try {
      const vendor = await this.prisma.vendor.findUnique({ where: { id: vendorId }, select: { userId: true } });
      if (vendor) await this.notifyUser(vendor.userId, title, body, data);
    } catch (error) {
      this.logger.error('Could not notify vendor; order processing will continue.');
    }
  }

  async notifyDriversInCity(cityId: string, title: string, body: string, data: Record<string, string>) {
    try {
      const drivers = await this.prisma.driver.findMany({
        where: { cityId, status: 'APPROVED', isOnline: true },
        select: { userId: true },
      });
      const results = await Promise.allSettled(drivers.map((driver) => this.notifyUser(driver.userId, title, body, data)));
      const failed = results.filter((result) => result.status === 'rejected').length;
      if (failed) this.logger.warn(`Push notification failed for ${failed} of ${drivers.length} drivers.`);
      return { targetedDrivers: drivers.length, failed };
    } catch (error) {
      this.logger.error('Could not notify drivers; peer-delivery order remains created.');
      return { targetedDrivers: 0, failed: 0, skipped: true };
    }
  }

  async notifyDriver(driverId: string, title: string, body: string, data: Record<string, string>) {
    try {
      const driver = await this.prisma.driver.findUnique({ where: { id: driverId }, select: { userId: true } });
      if (driver) await this.notifyUser(driver.userId, title, body, data);
    } catch (error) {
      this.logger.error('Could not notify the assigned driver; order processing will continue.');
    }
  }

  async notifyCustomer(customerId: string, title: string, body: string, data: Record<string, string>) {
    await this.notifyUser(customerId, title, body, data);
  }

  private async notifyUser(userId: string, title: string, body: string, data: Record<string, string>) {
    try {
      await this.prisma.userNotification?.create?.({
        data: {
          userId,
          title: title.slice(0, 160),
          body,
          type: (data.type ?? 'GENERAL').slice(0, 48),
          data,
        },
      });
    } catch (error) {
      this.logger.warn('Could not persist in-app notification; continuing.');
    }

    if (!this.messaging) return;
    try {
      const devices = await this.prisma.userDevice.findMany({ where: { userId }, select: { token: true } });
      if (!devices.length) return;
      const result = await this.messaging.sendEachForMulticast({
        tokens: devices.map((x) => x.token),
        notification: { title, body },
        data,
        android: { priority: 'high' },
      });
      const invalid = result.responses.flatMap((r, i) =>
        !r.success && ['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(r.error?.code ?? '')
          ? [devices[i].token]
          : [],
      );
      if (invalid.length) await this.prisma.userDevice.deleteMany({ where: { token: { in: invalid } } });
    } catch (error) {
      this.logger.error('Firebase push processing failed; order processing will continue.');
    }
  }
}
