import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Locale } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class VendorsService {
  constructor(private readonly prisma: PrismaService) {}

  async apply(
    userId: string,
    dto: { name: string; type: string; cityId: string; description?: string; address?: string; latitude?: number; longitude?: number },
  ) {
    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.findUnique({ where: { id: userId } });
      if (!user || user.role !== 'CUSTOMER') throw new BadRequestException('الحساب غير مؤهل لتقديم طلب بائع');
      const city = await tx.city.findFirst({ where: { id: dto.cityId, isActive: true }, select: { id: true } });
      if (!city) throw new NotFoundException('المدينة غير متاحة');
      if (await tx.vendor.findUnique({ where: { userId } })) throw new BadRequestException('يوجد طلب بائع لهذا الحساب');
      if (await tx.driver.findUnique({ where: { userId } })) throw new BadRequestException('لديك طلب سائق قائم بالفعل');
      if ((dto.latitude === undefined) !== (dto.longitude === undefined)) throw new BadRequestException('أرسل إحداثيات موقع المتجر كاملة');

      const vendor = await tx.vendor.create({
        data: {
          userId,
          type: dto.type,
          status: 'PENDING',
          isOpen: true,
          translations: { create: { locale: 'ar', name: dto.name, description: dto.description } },
          cities: { create: { cityId: dto.cityId } },
          location: { create: { cityId: dto.cityId, address: dto.address } },
        },
      });
      if (dto.latitude !== undefined && dto.longitude !== undefined) {
        await tx.$executeRaw`UPDATE "VendorLocation" SET "point" = ST_SetSRID(ST_MakePoint(${dto.longitude}, ${dto.latitude}), 4326)::geography WHERE "vendorId" = ${vendor.id}`;
      }
      return { id: vendor.id, status: vendor.status, message: 'تم استلام طلبك وسيتم مراجعته قبل تفعيل المتجر' };
    });
  }

  mine(userId: string) {
    return this.prisma.vendor.findUnique({
      where: { userId },
      select: {
        id: true,
        type: true,
        status: true,
        isOpen: true,
        ratingAvg: true,
        translations: { where: { locale: 'ar' }, take: 1 },
        location: { select: { address: true, cityId: true } },
        _count: { select: { products: true, orders: true } },
      },
    });
  }

  async stats(userId: string) {
    const vendor = await this.prisma.vendor.findUnique({
      where: { userId },
      select: {
        id: true,
        isOpen: true,
        ratingAvg: true,
        cities: { take: 1, select: { city: { select: { defaultCurrency: true } } } },
      },
    });
    if (!vendor) throw new ForbiddenException('لا يوجد متجر مرتبط بهذا الحساب');

    const now = new Date();
    const todayStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

    const [totalOrders, pendingOrders, activeOrders, deliveredAgg, todayOrders, todayRevenueAgg] = await Promise.all([
      this.prisma.order.count({ where: { vendorId: vendor.id } }),
      this.prisma.order.count({ where: { vendorId: vendor.id, status: 'PENDING' } }),
      this.prisma.order.count({
        where: { vendorId: vendor.id, status: { in: ['PENDING', 'ACCEPTED', 'PREPARING', 'READY', 'ASSIGNED', 'PICKED_UP'] } },
      }),
      this.prisma.order.aggregate({
        where: { vendorId: vendor.id, status: 'DELIVERED' },
        _count: { id: true },
        _sum: { subtotal: true },
      }),
      this.prisma.order.count({ where: { vendorId: vendor.id, createdAt: { gte: todayStart } } }),
      this.prisma.order.aggregate({
        where: { vendorId: vendor.id, status: 'DELIVERED', updatedAt: { gte: todayStart } },
        _sum: { subtotal: true },
      }),
    ]);

    return {
      vendorId: vendor.id,
      isOpen: vendor.isOpen,
      ratingAvg: Number(vendor.ratingAvg ?? 0),
      totalOrders,
      pendingOrders,
      activeOrders,
      deliveredOrders: deliveredAgg._count.id,
      totalRevenue: Number(deliveredAgg._sum.subtotal ?? 0),
      todayOrders,
      todayRevenue: Number(todayRevenueAgg._sum.subtotal ?? 0),
      currency: vendor.cities[0]?.city?.defaultCurrency ?? 'SYP',
    };
  }

  async updateMine(
    userId: string,
    dto: {
      name?: string;
      description?: string;
      type?: string;
      address?: string;
      isOpen?: boolean;
      latitude?: number;
      longitude?: number;
    },
  ) {
    if ((dto.latitude === undefined) !== (dto.longitude === undefined)) {
      throw new BadRequestException('أرسل إحداثيات موقع المتجر كاملة');
    }
    const vendor = await this.prisma.vendor.findUnique({
      where: { userId },
      select: { id: true, status: true },
    });
    if (!vendor) throw new ForbiddenException('لا يوجد متجر مرتبط بهذا الحساب');

    await this.prisma.$transaction(async (tx) => {
      if (dto.type !== undefined || dto.isOpen !== undefined) {
        await tx.vendor.update({
          where: { id: vendor.id },
          data: {
            ...(dto.type !== undefined ? { type: dto.type.trim() } : {}),
            ...(dto.isOpen !== undefined ? { isOpen: dto.isOpen } : {}),
          },
        });
      }
      if (dto.name !== undefined || dto.description !== undefined) {
        const current = await tx.vendorTranslation.findUnique({
          where: { vendorId_locale: { vendorId: vendor.id, locale: Locale.ar } },
        });
        await tx.vendorTranslation.upsert({
          where: { vendorId_locale: { vendorId: vendor.id, locale: Locale.ar } },
          create: {
            vendorId: vendor.id,
            locale: Locale.ar,
            name: dto.name?.trim() ?? current?.name ?? 'متجر',
            description: dto.description?.trim() ?? null,
          },
          update: {
            name: dto.name !== undefined ? dto.name.trim() : current?.name ?? 'متجر',
            description: dto.description !== undefined ? dto.description.trim() || null : current?.description,
          },
        });
      }
      if (dto.address !== undefined) {
        await tx.vendorLocation.updateMany({
          where: { vendorId: vendor.id },
          data: { address: dto.address.trim() || null },
        });
      }
      if (dto.latitude !== undefined && dto.longitude !== undefined) {
        await tx.$executeRaw`UPDATE "VendorLocation" SET "point" = ST_SetSRID(ST_MakePoint(${dto.longitude}, ${dto.latitude}), 4326)::geography WHERE "vendorId" = ${vendor.id}`;
      }
    });

    return this.mine(userId);
  }

  list(cityId?: string, locale = 'ar', filters?: { type?: string; q?: string }) {
    const safeLocale = Object.values(Locale).includes(locale as Locale) ? (locale as Locale) : Locale.ar;
    const type = filters?.type?.trim();
    const query = filters?.q?.trim();
    return this.prisma.vendor.findMany({
      where: {
        status: 'APPROVED',
        ...(cityId ? { cities: { some: { cityId } } } : {}),
        ...(type ? { type } : {}),
        ...(query ? { translations: { some: { name: { contains: query, mode: 'insensitive' } } } } : {}),
      },
      orderBy: [{ isOpen: 'desc' }, { ratingAvg: 'desc' }, { createdAt: 'desc' }],
      select: {
        id: true,
        type: true,
        isOpen: true,
        ratingAvg: true,
        translations: { where: { locale: { in: [safeLocale, Locale.ar] } } },
        location: { select: { address: true, cityId: true } },
        _count: { select: { products: true, reviews: true } },
      },
    });
  }

  async get(id: string, locale = 'ar') {
    const safeLocale = Object.values(Locale).includes(locale as Locale) ? (locale as Locale) : Locale.ar;
    const vendor = await this.prisma.vendor.findFirst({
      where: { id, status: 'APPROVED' },
      select: {
        id: true,
        type: true,
        isOpen: true,
        ratingAvg: true,
        translations: { where: { locale: { in: [safeLocale, Locale.ar] } } },
        location: { select: { address: true, cityId: true } },
        cities: { select: { city: { select: { id: true, code: true, names: true } } } },
        _count: { select: { reviews: true } },
      },
    });
    if (!vendor) throw new NotFoundException('المتجر غير موجود');
    return vendor;
  }

  async reviews(id: string) {
    const vendor = await this.prisma.vendor.findFirst({
      where: { id, status: 'APPROVED' },
      select: { id: true, ratingAvg: true },
    });
    if (!vendor) throw new NotFoundException('المتجر غير موجود');
    const [items, total] = await Promise.all([
      this.prisma.review.findMany({
        where: { vendorId: id },
        orderBy: { createdAt: 'desc' },
        take: 30,
        select: {
          id: true,
          rating: true,
          comment: true,
          createdAt: true,
          author: { select: { name: true } },
        },
      }),
      this.prisma.review.count({ where: { vendorId: id } }),
    ]);
    return {
      vendorId: id,
      ratingAvg: Number(vendor.ratingAvg ?? 0),
      total,
      items,
    };
  }
}
