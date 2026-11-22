import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Locale } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class CatalogService {
  constructor(private readonly prisma: PrismaService) {}

  async list(vendorId: string, locale = 'ar', filters?: { category?: string; q?: string }) {
    const vendor = await this.prisma.vendor.findFirst({
      where: { id: vendorId, status: 'APPROVED' },
      select: { id: true },
    });
    if (!vendor) throw new NotFoundException('المتجر غير متاح');

    const safeLocale = Object.values(Locale).includes(locale as Locale) ? (locale as Locale) : Locale.ar;
    const category = filters?.category?.trim();
    const query = filters?.q?.trim();

    return this.prisma.product.findMany({
      where: {
        vendorId,
        isAvailable: true,
        ...(category ? { category } : {}),
        ...(query ? { translations: { some: { name: { contains: query, mode: 'insensitive' } } } } : {}),
      },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        basePrice: true,
        currency: true,
        category: true,
        stockQty: true,
        isAvailable: true,
        imageUrl: true,
        variants: { where: { isAvailable: true } },
        translations: { where: { locale: { in: [safeLocale, Locale.ar] } } },
      },
    });
  }

  async listMine(userId: string, q?: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId }, select: { id: true } });
    if (!vendor) throw new ForbiddenException('لا يوجد متجر مرتبط بهذا الحساب');
    const query = q?.trim();
    return this.prisma.product.findMany({
      where: {
        vendorId: vendor.id,
        ...(query ? { translations: { some: { name: { contains: query, mode: 'insensitive' } } } } : {}),
      },
      orderBy: { createdAt: 'desc' },
      include: {
        translations: true,
        variants: true,
      },
    });
  }

  async create(
    userId: string,
    dto: {
      name: string;
      description?: string;
      price: number;
      currency?: string;
      category?: string;
      imageUrl?: string;
      stockQty?: number;
      isAvailable?: boolean;
    },
  ) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId } });
    if (!vendor || vendor.status !== 'APPROVED') throw new ForbiddenException('حساب البائع غير معتمد');
    return this.prisma.product.create({
      data: {
        vendorId: vendor.id,
        basePrice: dto.price,
        currency: dto.currency ?? 'SYP',
        category: dto.category?.trim() || null,
        imageUrl: dto.imageUrl?.trim() || null,
        stockQty: dto.stockQty,
        isAvailable: dto.isAvailable ?? true,
        translations: {
          create: {
            locale: Locale.ar,
            name: dto.name.trim(),
            description: dto.description?.trim() || null,
          },
        },
      },
      include: { translations: true },
    });
  }

  async update(
    userId: string,
    productId: string,
    dto: {
      name?: string;
      description?: string;
      price?: number;
      category?: string;
      imageUrl?: string;
      stockQty?: number;
      isAvailable?: boolean;
    },
  ) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId }, select: { id: true, status: true } });
    if (!vendor || vendor.status !== 'APPROVED') throw new ForbiddenException('حساب البائع غير معتمد');

    const existing = await this.prisma.product.findFirst({
      where: { id: productId, vendorId: vendor.id },
      select: { id: true },
    });
    if (!existing) throw new NotFoundException('المنتج غير موجود');

    return this.prisma.$transaction(async (tx) => {
      if (dto.name !== undefined || dto.description !== undefined) {
        const currentTr = await tx.productTranslation.findUnique({
          where: { productId_locale: { productId, locale: Locale.ar } },
        });
        await tx.productTranslation.upsert({
          where: { productId_locale: { productId, locale: Locale.ar } },
          create: {
            productId,
            locale: Locale.ar,
            name: dto.name?.trim() ?? 'منتج',
            description: dto.description?.trim() ?? null,
          },
          update: {
            name: dto.name !== undefined ? dto.name.trim() : currentTr?.name ?? 'منتج',
            description: dto.description !== undefined ? dto.description.trim() || null : currentTr?.description,
          },
        });
      }

      return tx.product.update({
        where: { id: productId },
        data: {
          ...(dto.price !== undefined ? { basePrice: dto.price } : {}),
          ...(dto.category !== undefined ? { category: dto.category.trim() || null } : {}),
          ...(dto.imageUrl !== undefined ? { imageUrl: dto.imageUrl.trim() || null } : {}),
          ...(dto.stockQty !== undefined ? { stockQty: dto.stockQty } : {}),
          ...(dto.isAvailable !== undefined ? { isAvailable: dto.isAvailable } : {}),
        },
        include: { translations: true },
      });
    });
  }

  async remove(userId: string, productId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId }, select: { id: true } });
    if (!vendor) throw new ForbiddenException('حساب البائع غير معتمد');

    const existing = await this.prisma.product.findFirst({
      where: { id: productId, vendorId: vendor.id },
      select: { id: true, _count: { select: { orderItems: true } } },
    });
    if (!existing) throw new NotFoundException('المنتج غير موجود');

    if (existing._count.orderItems > 0) {
      await this.prisma.product.update({
        where: { id: productId },
        data: { isAvailable: false },
      });
      return { id: productId, archived: true, deleted: false };
    }

    await this.prisma.product.delete({ where: { id: productId } });
    return { id: productId, archived: false, deleted: true };
  }
}
