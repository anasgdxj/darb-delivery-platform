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
      const source = raw.trim();
      let parsed: unknown;
      try {
        parsed = JSON.parse(source);
      } catch {
        const encoded = source.startsWith('base64:') ? source.slice(7) : source;
        parsed = JSON.parse(Buffer.from(encoded, 'base64').toString('utf8'));
      }
      if (typeof parsed === 'string') parsed = JSON.parse(parsed);
      if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
        throw new Error('Service-account value must be a JSON object or base64-encoded JSON.');
      }

      const credentials = parsed as {
        project_id?: string;
        client_email?: string;
        private_key?: string;
        projectId?: string;
        clientEmail?: string;
        privateKey?: string;
      };
      const projectId = credentials.project_id ?? credentials.projectId;
      const clientEmail = credentials.client_email ?? credentials.clientEmail;
      const privateKey = credentials.private_key ?? credentials.privateKey;
      if (!projectId || !clientEmail || !privateKey) {
        const missing = [
          !projectId ? 'project_id' : null,
          !clientEmail ? 'client_email' : null,
          !privateKey ? 'private_key' : null,
        ].filter((field): field is string => field !== null);
        throw new Error(`Service-account JSON is missing required fields: ${missing.join(', ')}.`);
      }

      const normalizedPrivateKey = privateKey.replace(/\\n/g, '\n');
      const app: App =
        getApps().find((x) => x.name === 'darb-notifications') ??
        initializeApp(
          {
            credential: cert({
              projectId,
              clientEmail,
              privateKey: normalizedPrivateKey,
            }),
            projectId,
          },
          'darb-notifications',
        );
      this.messaging = getMessaging(app);
      this.logger.log(`Firebase Admin initialized for project ${projectId}.`);
    } catch (error) {
      const reason = error instanceof Error ? error.message : 'Unknown initialization error';
      this.logger.error(`Firebase Admin initialization failed: ${reason}. Push delivery is disabled.`);
    }
  }

  isMessagingConfigured(): boolean {
    return this.messaging !== undefined;
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


  async broadcastRelease(input: {
    releaseTag: string;
    versionCode: number;
    versionName: string;
    apkUrl: string;
    releaseNotes?: string;
  }) {
    const devices = await this.prisma.userDevice.findMany({
      select: { userId: true, token: true },
    });
    if (!devices.length) {
      return { targetedUsers: 0, targetedDevices: 0, pushSent: 0, pushFailed: 0, pushSkipped: !this.messaging };
    }

    const releaseTag = input.releaseTag.slice(0, 80);
    const title = 'تحديث جديد لتطبيق دازريفو';
    const body = `الإصدار ${input.versionName} أصبح متاحاً. افتح دازريفو لتثبيته.`;
    const data = {
      type: 'APP_UPDATE',
      releaseTag,
      versionCode: String(input.versionCode),
      versionName: input.versionName.slice(0, 40),
      apkUrl: input.apkUrl,
    };
    const userIds = [...new Set(devices.map((device) => device.userId))];

    await this.prisma.userNotification.createMany({
      data: userIds.map((userId) => ({
        userId,
        title,
        body,
        type: 'APP_UPDATE',
        data: { ...data, releaseNotes: (input.releaseNotes ?? '').slice(0, 1000) },
      })),
    });

    if (!this.messaging) {
      this.logger.warn(`Release ${releaseTag} was saved in inboxes, but FCM is not configured.`);
      return {
        targetedUsers: userIds.length,
        targetedDevices: devices.length,
        pushSent: 0,
        pushFailed: 0,
        pushSkipped: true,
      };
    }

    let pushSent = 0;
    let pushFailed = 0;
    const invalidTokens: string[] = [];
    const tokens = devices.map((device) => device.token);
    for (let offset = 0; offset < tokens.length; offset += 500) {
      const batch = tokens.slice(offset, offset + 500);
      try {
        const result = await this.messaging.sendEachForMulticast({
          tokens: batch,
          notification: { title, body },
          data,
          android: {
            priority: 'high',
            notification: {
              channelId: 'dazrevo_high_importance',
              sound: 'default',
              color: '#8A651F',
            },
          },
        });
        pushSent += result.successCount;
        result.responses.forEach((response, index) => {
          if (response.success) return;
          const code = response.error?.code ?? '';
          if (
            ['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(code)
          ) {
            invalidTokens.push(batch[index]);
            return;
          }
          pushFailed += 1;
        });
      } catch (error) {
        pushFailed += batch.length;
        this.logger.error(`FCM release notification batch failed for ${releaseTag}.`);
      }
    }
    if (invalidTokens.length) {
      await this.prisma.userDevice.deleteMany({ where: { token: { in: invalidTokens } } });
    }

    return {
      targetedUsers: userIds.length,
      targetedDevices: devices.length,
      pushSent,
      pushFailed,
      pushSkipped: false,
    };
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
      const invalid: string[] = [];
      const tokens = devices.map((device) => device.token);
      for (let offset = 0; offset < tokens.length; offset += 500) {
        const batch = tokens.slice(offset, offset + 500);
        const result = await this.messaging.sendEachForMulticast({
          tokens: batch,
          notification: { title, body },
          data,
          android: {
            priority: 'high',
            notification: {
              channelId: 'dazrevo_high_importance',
              sound: 'default',
              color: '#8A651F',
            },
          },
        });
        result.responses.forEach((response, index) => {
          const code = response.error?.code ?? '';
          if (
            !response.success &&
            ['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(code)
          ) {
            invalid.push(batch[index]);
          }
        });
      }
      if (invalid.length) {
        await this.prisma.userDevice.deleteMany({
          where: { token: { in: invalid } },
        });
      }
    } catch (error) {
      this.logger.error('Firebase push processing failed; order processing will continue.');
    }
  }
}
