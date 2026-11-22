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
        _count: { select: { products: true } },
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
      },
    });
    if (!vendor) throw new NotFoundException('المتجر غير موجود');
    return vendor;
  }
}
