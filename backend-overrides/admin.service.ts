import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { DriverStatus, Locale, OrderStatus, OrderType, Prisma, UserRole, VendorStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  private async writeAudit(
    actorId: string | undefined,
    action: string,
    targetType: string,
    targetId?: string,
    metadata?: Record<string, unknown>,
  ) {
    try {
      await this.prisma.auditLog.create({
        data: {
          actorId: actorId ?? null,
          actorRole: UserRole.ADMIN,
          action,
          targetType,
          targetId: targetId ?? null,
          metadata: metadata ? (metadata as Prisma.InputJsonValue) : undefined,
        },
      });
    } catch {
      // Audit logging must not crash core admin mutations if optional table isn't migrated yet.
    }
  }

  async stats() {
    const [
      usersTotal,
      vendorsApproved,
      vendorsPending,
      driversApproved,
      driversPending,
      driversOnline,
      citiesActive,
      ordersTotal,
      ordersPending,
      ordersActive,
      ordersDelivered,
      ordersCancelled,
      revenueAgg,
      ordersToday,
      deliveredToday,
      delayedOrders,
      revenueToday,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.vendor.count({ where: { status: VendorStatus.APPROVED } }),
      this.prisma.vendor.count({ where: { status: VendorStatus.PENDING } }),
      this.prisma.driver.count({ where: { status: DriverStatus.APPROVED } }),
      this.prisma.driver.count({ where: { status: DriverStatus.PENDING } }),
      this.prisma.driver.count({ where: { status: DriverStatus.APPROVED, isOnline: true } }),
      this.prisma.city.count({ where: { isActive: true } }),
      this.prisma.order.count(),
      this.prisma.order.count({ where: { status: OrderStatus.PENDING } }),
      this.prisma.order.count({
        where: { status: { in: [OrderStatus.ACCEPTED, OrderStatus.PREPARING, OrderStatus.READY, OrderStatus.ASSIGNED, OrderStatus.PICKED_UP] } },
      }),
      this.prisma.order.count({ where: { status: OrderStatus.DELIVERED } }),
      this.prisma.order.count({ where: { status: OrderStatus.CANCELLED } }),
      this.prisma.order.aggregate({
        where: { status: OrderStatus.DELIVERED },
        _sum: { total: true, deliveryFee: true },
      }),
      this.prisma.order.count({
        where: { createdAt: { gte: this.businessDayStart() } },
      }),
      this.prisma.order.count({
        where: { status: OrderStatus.DELIVERED, updatedAt: { gte: this.businessDayStart() } },
      }),
      this.prisma.order.count({
        where: {
          status: { in: [OrderStatus.ACCEPTED, OrderStatus.PREPARING, OrderStatus.READY, OrderStatus.ASSIGNED, OrderStatus.PICKED_UP] },
          updatedAt: { lt: new Date(Date.now() - 45 * 60 * 1000) },
        },
      }),
      this.prisma.order.aggregate({
        where: { status: OrderStatus.DELIVERED, updatedAt: { gte: this.businessDayStart() } },
        _sum: { total: true, deliveryFee: true },
      }),
    ]);

    return {
      snapshotAt: new Date().toISOString(),
      usersTotal,
      vendorsApproved,
      vendorsPending,
      driversApproved,
      driversPending,
      driversOnline,
      citiesActive,
      ordersTotal,
      ordersPending,
      ordersActive,
      ordersDelivered,
      ordersCancelled,
      deliveredGrossTotal: Number(revenueAgg._sum.total ?? 0),
      deliveredDeliveryFees: Number(revenueAgg._sum.deliveryFee ?? 0),
      ordersToday,
      deliveredToday,
      delayedOrders,
      deliveredGrossToday: Number(revenueToday._sum.total ?? 0),
      deliveredDeliveryFeesToday: Number(revenueToday._sum.deliveryFee ?? 0),
    };
  }

  private businessDayStart() {
    const businessNow = new Date(Date.now() + 3 * 60 * 60 * 1000);
    businessNow.setUTCHours(0, 0, 0, 0);
    return new Date(businessNow.getTime() - 3 * 60 * 60 * 1000);
  }

  async orders(query: { status?: OrderStatus; type?: OrderType; page?: number; limit?: number }) {
    const where = {
      ...(query.status ? { status: query.status } : {}),
      ...(query.type ? { type: query.type } : {}),
    };
    const page = query.page || 1;
    const limit = query.limit || 20;
    const [items, total] = await this.prisma.$transaction([
      this.prisma.order.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: {
          city: { select: { code: true, names: true } },
          customer: { select: { name: true, phone: true, email: true } },
          vendor: { include: { translations: true } },
          driver: { include: { user: { select: { name: true, phone: true } } } },
          payment: true,
        },
      }),
      this.prisma.order.count({ where }),
    ]);
    return { items, total, page, limit, pages: Math.ceil(total / limit) };
  }

  async users(query: { role?: UserRole; q?: string; page?: number; limit?: number }) {
    const page = query.page || 1;
    const limit = query.limit || 25;
    const q = query.q?.trim();
    const where: Prisma.UserWhereInput = {
      ...(query.role ? { role: query.role } : {}),
      ...(q
        ? {
            OR: [
              { name: { contains: q, mode: 'insensitive' } },
              { phone: { contains: q } },
              { email: { contains: q, mode: 'insensitive' } },
            ],
          }
        : {}),
    };
    const [items, total] = await this.prisma.$transaction([
      this.prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        select: {
          id: true,
          name: true,
          phone: true,
          email: true,
          role: true,
          locale: true,
          createdAt: true,
          vendor: { select: { id: true, status: true } },
          driver: { select: { id: true, status: true, vehicleType: true, isOnline: true } },
        },
      }),
      this.prisma.user.count({ where }),
    ]);
    return { items, total, page, limit, pages: Math.ceil(total / limit) };
  }

  async setUserRole(actorId: string, userId: string, role: UserRole) {
    if (actorId === userId && role !== UserRole.ADMIN) {
      throw new BadRequestException('لا يمكنك إزالة صلاحية الإدارة عن حسابك الحالي');
    }
    const existing = await this.prisma.user.findUnique({ where: { id: userId }, select: { id: true, role: true } });
    if (!existing) throw new NotFoundException('المستخدم غير موجود');

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { role },
      select: { id: true, name: true, phone: true, email: true, role: true },
    });
    await this.writeAudit(actorId, 'USER_ROLE_UPDATED', 'User', userId, { from: existing.role, to: role });
    return updated;
  }

  deliveryZones() {
    return this.prisma.deliveryZone.findMany({
      orderBy: [{ cityId: 'asc' }, { name: 'asc' }],
      include: { city: { select: { id: true, code: true, names: true } } },
    });
  }

  async createDeliveryZone(
    actorId: string,
    dto: { cityId: string; name: string; feeBase: number; feePerKm: number },
  ) {
    const city = await this.prisma.city.findFirst({ where: { id: dto.cityId, isActive: true }, select: { id: true } });
    if (!city) throw new BadRequestException('المدينة غير متاحة');
    if (await this.prisma.deliveryZone.findUnique({ where: { cityId: dto.cityId } })) {
      throw new BadRequestException('تم إعداد رسوم هذه المدينة مسبقاً؛ عدّل الإعداد الموجود');
    }
    const zone = await this.prisma.deliveryZone.create({ data: dto });
    await this.writeAudit(actorId, 'DELIVERY_ZONE_CREATED', 'DeliveryZone', zone.id, { cityId: dto.cityId });
    return zone;
  }

  async updateDeliveryZone(
    actorId: string,
    id: string,
    dto: { name?: string; feeBase?: number; feePerKm?: number },
  ) {
    const zone = await this.prisma.deliveryZone.update({ where: { id }, data: dto });
    await this.writeAudit(actorId, 'DELIVERY_ZONE_UPDATED', 'DeliveryZone', id, { ...dto });
    return zone;
  }

  async removeDeliveryZone(actorId: string, id: string) {
    const existing = await this.prisma.deliveryZone.findUnique({ where: { id }, select: { id: true } });
    if (!existing) throw new NotFoundException('منطقة التوصيل غير موجودة');
    await this.prisma.deliveryZone.delete({ where: { id } });
    await this.writeAudit(actorId, 'DELIVERY_ZONE_DELETED', 'DeliveryZone', id);
    return { id, deleted: true };
  }

  pendingVendors() {
    return this.prisma.vendor.findMany({
      where: { status: VendorStatus.PENDING },
      orderBy: { createdAt: 'asc' },
      include: {
        user: { select: { id: true, name: true, phone: true, email: true } },
        translations: true,
        cities: { include: { city: { select: { id: true, code: true, names: true } } } },
        location: true,
      },
    });
  }

  allVendors(status?: VendorStatus) {
    return this.prisma.vendor.findMany({
      where: status ? { status } : {},
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { id: true, name: true, phone: true, email: true } },
        translations: true,
        cities: { include: { city: { select: { id: true, code: true, names: true } } } },
        location: true,
        _count: { select: { products: true, orders: true } },
      },
    });
  }

  async setVendorStatus(actorId: string, id: string, status: VendorStatus) {
    const vendor = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.vendor.update({ where: { id }, data: { status } });
      if (status === VendorStatus.APPROVED) {
        await tx.user.update({ where: { id: updated.userId }, data: { role: UserRole.VENDOR } });
      } else {
        await tx.user.updateMany({ where: { id: updated.userId, role: UserRole.VENDOR }, data: { role: UserRole.CUSTOMER } });
      }
      return updated;
    });
    await this.writeAudit(actorId, 'VENDOR_STATUS_UPDATED', 'Vendor', id, { status });
    return vendor;
  }

  pendingDrivers() {
    return this.prisma.driver.findMany({
      where: { status: DriverStatus.PENDING },
      orderBy: { createdAt: 'asc' },
      include: {
        user: { select: { id: true, name: true, phone: true, email: true } },
        city: { select: { id: true, code: true, names: true } },
      },
    });
  }

  allDrivers(status?: DriverStatus) {
    return this.prisma.driver.findMany({
      where: status ? { status } : {},
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { id: true, name: true, phone: true, email: true } },
        city: { select: { id: true, code: true, names: true } },
        _count: { select: { orders: true } },
      },
    });
  }

  async setDriverStatus(actorId: string, id: string, status: DriverStatus) {
    const driver = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.driver.update({
        where: { id },
        data: { status, ...(status === DriverStatus.APPROVED ? {} : { isOnline: false }) },
      });
      if (status === DriverStatus.APPROVED) {
        await tx.user.update({ where: { id: updated.userId }, data: { role: UserRole.DRIVER } });
      } else {
        await tx.user.updateMany({ where: { id: updated.userId, role: UserRole.DRIVER }, data: { role: UserRole.CUSTOMER } });
      }
      return updated;
    });
    await this.writeAudit(actorId, 'DRIVER_STATUS_UPDATED', 'Driver', id, { status });
    return driver;
  }

  cities() {
    return this.prisma.city.findMany({
      orderBy: { code: 'asc' },
      include: {
        names: true,
        zone: true,
        _count: { select: { vendors: true, drivers: true, orders: true } },
      },
    });
  }

  async createCity(
    actorId: string,
    dto: { code: string; nameAr: string; nameEn?: string; nameTr?: string; defaultCurrency?: string; isActive?: boolean },
  ) {
    const code = dto.code.trim().toLowerCase();
    if (!/^[a-z0-9_-]{2,24}$/.test(code)) {
      throw new BadRequestException('رمز المدينة يجب أن يحتوي على أحرف إنجليزية صغيرة أو أرقام فقط');
    }
    const exists = await this.prisma.city.findUnique({ where: { code }, select: { id: true } });
    if (exists) throw new BadRequestException('رمز المدينة مسجل مسبقاً');

    const translations = [
      { locale: Locale.ar, name: dto.nameAr.trim() },
      ...(dto.nameEn?.trim() ? [{ locale: Locale.en, name: dto.nameEn.trim() }] : []),
      ...(dto.nameTr?.trim() ? [{ locale: Locale.tr, name: dto.nameTr.trim() }] : []),
    ];

    const city = await this.prisma.city.create({
      data: {
        code,
        defaultCurrency: (dto.defaultCurrency ?? 'SYP').trim().toUpperCase().slice(0, 3),
        supportedLocales: [Locale.ar, Locale.en, Locale.tr],
        isActive: dto.isActive ?? true,
        names: { create: translations },
      },
      include: { names: true, zone: true },
    });
    await this.writeAudit(actorId, 'CITY_CREATED', 'City', city.id, { code });
    return city;
  }

  async updateCity(
    actorId: string,
    id: string,
    dto: { isActive?: boolean; defaultCurrency?: string; nameAr?: string; nameEn?: string; nameTr?: string },
  ) {
    const city = await this.prisma.city.findUnique({ where: { id }, select: { id: true } });
    if (!city) throw new NotFoundException('المدينة غير موجودة');

    const updated = await this.prisma.$transaction(async (tx) => {
      if (dto.isActive !== undefined || dto.defaultCurrency !== undefined) {
        await tx.city.update({
          where: { id },
          data: {
            ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
            ...(dto.defaultCurrency !== undefined
              ? { defaultCurrency: dto.defaultCurrency.trim().toUpperCase().slice(0, 3) }
              : {}),
          },
        });
      }
      const localePairs: Array<[Locale, string | undefined]> = [
        [Locale.ar, dto.nameAr],
        [Locale.en, dto.nameEn],
        [Locale.tr, dto.nameTr],
      ];
      for (const [locale, value] of localePairs) {
        if (value?.trim()) {
          await tx.cityTranslation.upsert({
            where: { cityId_locale: { cityId: id, locale } },
            create: { cityId: id, locale, name: value.trim() },
            update: { name: value.trim() },
          });
        }
      }
      return tx.city.findUnique({ where: { id }, include: { names: true, zone: true } });
    });

    await this.writeAudit(actorId, 'CITY_UPDATED', 'City', id, { ...dto });
    return updated;
  }

  async getSettings() {
    const rows = await this.prisma.platformSetting.findMany();
    const map: Record<string, unknown> = {
      commissionPercent: 10,
      defaultCurrency: 'SYP',
      peerDeliveryEnabled: true,
      aiAssistantEnabled: true,
      maintenanceMode: false,
      supportContact: '',
    };
    for (const row of rows) {
      map[row.key] = row.value;
    }
    return map;
  }

  async updateSettings(
    actorId: string,
    updates: {
      commissionPercent?: number;
      defaultCurrency?: string;
      peerDeliveryEnabled?: boolean;
      aiAssistantEnabled?: boolean;
      maintenanceMode?: boolean;
      supportContact?: string;
    },
  ) {
    const entries = Object.entries(updates).filter(([, v]) => v !== undefined);
    await this.prisma.$transaction(
      entries.map(([key, value]) =>
        this.prisma.platformSetting.upsert({
          where: { key },
          create: { key, value: value as Prisma.InputJsonValue, updatedBy: actorId },
          update: { value: value as Prisma.InputJsonValue, updatedBy: actorId },
        }),
      ),
    );
    await this.writeAudit(actorId, 'PLATFORM_SETTINGS_UPDATED', 'PlatformSetting', 'global', updates);
    return this.getSettings();
  }

  async auditLogs(limit = 50) {
    const safeLimit = Math.max(1, Math.min(200, limit));
    return this.prisma.auditLog.findMany({
      orderBy: { createdAt: 'desc' },
      take: safeLimit,
    });
  }
}
