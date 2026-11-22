import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { OrderStatus, UserRole } from '@prisma/client';
import { randomBytes } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class OrdersService {
  constructor(private readonly prisma: PrismaService) {}

  async createPeerDelivery(
    customerId: string,
    dto: {
      cityId: string;
      addressId: string;
      pickupAddress: string;
      pickupLatitude: number;
      pickupLongitude: number;
      notes?: string;
    },
  ) {
    const pickupAddress = dto.pickupAddress.trim();
    if (pickupAddress.length < 5 || pickupAddress.length > 500) throw new BadRequestException('عنوان الاستلام غير صالح');
    if (
      !Number.isFinite(dto.pickupLatitude) ||
      dto.pickupLatitude < -90 ||
      dto.pickupLatitude > 90 ||
      !Number.isFinite(dto.pickupLongitude) ||
      dto.pickupLongitude < -180 ||
      dto.pickupLongitude > 180
    ) {
      throw new BadRequestException('حدد موقع الاستلام على الخريطة');
    }
    return this.prisma.$transaction(async (tx) => {
      const [address, city] = await Promise.all([
        tx.address.findFirst({ where: { id: dto.addressId, userId: customerId }, select: { id: true } }),
        tx.city.findFirst({ where: { id: dto.cityId, isActive: true }, select: { id: true, defaultCurrency: true } }),
      ]);
      if (!address) throw new BadRequestException('عنوان التسليم غير صالح');
      if (!city) throw new BadRequestException('المدينة غير متاحة');
      return tx.order.create({
        data: {
          orderNumber: `DRB-${Date.now().toString(36).toUpperCase()}-${randomBytes(2).toString('hex').toUpperCase()}`,
          type: 'PEER_DELIVERY',
          status: 'PENDING',
          cityId: city.id,
          customerId,
          addressId: address.id,
          pickupAddress,
          pickupLatitude: dto.pickupLatitude,
          pickupLongitude: dto.pickupLongitude,
          currency: city.defaultCurrency,
          subtotal: 0,
          deliveryFee: 0,
          total: 0,
          notes: dto.notes,
          payment: { create: { method: 'CASH_ON_DELIVERY', amount: 0, currency: city.defaultCurrency } },
          statusHistory: { create: { status: 'PENDING', changedBy: customerId } },
        },
        include: { payment: true, address: true },
      });
    });
  }

  async estimate(
    customerId: string,
    dto: { cityId: string; addressId: string; vendorId: string; items: { productId: string; quantity: number }[] },
  ) {
    if (!dto.items?.length || dto.items.length > 30) throw new BadRequestException('قائمة المنتجات غير صالحة');
    const ids = [...new Set(dto.items.map((x) => x.productId))];
    if (ids.length !== dto.items.length) throw new BadRequestException('لا تكرر المنتج في السلة');

    const [address, city, vendor, deliveryZone] = await Promise.all([
      this.prisma.address.findFirst({ where: { id: dto.addressId, userId: customerId }, select: { id: true } }),
      this.prisma.city.findFirst({ where: { id: dto.cityId, isActive: true }, select: { id: true, defaultCurrency: true } }),
      this.prisma.vendor.findFirst({
        where: { id: dto.vendorId, status: 'APPROVED', cities: { some: { cityId: dto.cityId } } },
        select: { id: true, isOpen: true },
      }),
      this.prisma.deliveryZone.findUnique({ where: { cityId: dto.cityId } }),
    ]);

    if (!address) throw new BadRequestException('عنوان التوصيل غير صالح');
    if (!city) throw new BadRequestException('المدينة غير متاحة');
    if (!vendor) throw new BadRequestException('المتجر غير متاح في هذه المدينة');
    if (!deliveryZone) throw new BadRequestException('لم يتم إعداد رسوم التوصيل لهذه المدينة بعد');

    const feeBase = Number(deliveryZone.feeBase);
    const feePerKm = Number(deliveryZone.feePerKm);
    let distanceKm: number | null = null;
    if (feePerKm > 0) {
      const distances = await this.prisma.$queryRaw<Array<{ distanceKm: number | null }>>`
        SELECT CASE
          WHEN a."point" IS NULL OR vl."point" IS NULL THEN NULL
          ELSE ST_Distance(a."point", vl."point") / 1000.0
        END AS "distanceKm"
        FROM "Address" a
        CROSS JOIN "VendorLocation" vl
        WHERE a."id" = ${dto.addressId}
          AND a."userId" = ${customerId}
          AND vl."vendorId" = ${vendor.id}
      `;
      distanceKm = distances[0]?.distanceKm ?? null;
      if (distanceKm === null) {
        throw new BadRequestException('حدد موقع عنوان التوصيل وموقع المتجر لحساب رسوم التوصيل لكل كيلومتر');
      }
    }

    const deliveryFee = feeBase + Math.ceil(distanceKm ?? 0) * feePerKm;
    const products = await this.prisma.product.findMany({
      where: { id: { in: ids }, vendorId: vendor.id, isAvailable: true },
      select: { id: true, basePrice: true, currency: true, stockQty: true },
    });
    if (products.length !== ids.length) throw new BadRequestException('بعض المنتجات لم تعد متاحة');

    const byId = new Map(products.map((p) => [p.id, p]));
    const subtotal = dto.items.reduce((sum, line) => {
      const p = byId.get(line.productId)!;
      if (p.currency !== city.defaultCurrency) throw new BadRequestException('عملة المنتج لا تطابق عملة المدينة');
      if (p.stockQty !== null && p.stockQty < line.quantity) throw new BadRequestException('الكمية المطلوبة غير متوفرة');
      return sum + Number(p.basePrice) * line.quantity;
    }, 0);

    return {
      currency: city.defaultCurrency,
      subtotal,
      deliveryFee,
      total: subtotal + deliveryFee,
      distanceKm: distanceKm !== null ? Number(distanceKm.toFixed(2)) : null,
      vendorOpen: vendor.isOpen,
    };
  }

  async create(
    customerId: string,
    dto: {
      cityId: string;
      addressId: string;
      vendorId: string;
      items: { productId: string; quantity: number }[];
      notes?: string;
    },
  ) {
    if (!dto.items?.length || dto.items.length > 30) throw new BadRequestException('قائمة المنتجات غير صالحة');
    const ids = [...new Set(dto.items.map((x) => x.productId))];
    if (ids.length !== dto.items.length) throw new BadRequestException('لا تكرر المنتج في السلة');
    return this.prisma.$transaction(async (tx) => {
      const [address, city, vendor, deliveryZone] = await Promise.all([
        tx.address.findFirst({ where: { id: dto.addressId, userId: customerId }, select: { id: true } }),
        tx.city.findFirst({ where: { id: dto.cityId, isActive: true }, select: { id: true, defaultCurrency: true } }),
        tx.vendor.findFirst({
          where: { id: dto.vendorId, status: 'APPROVED', cities: { some: { cityId: dto.cityId } } },
          select: { id: true, isOpen: true },
        }),
        tx.deliveryZone.findUnique({ where: { cityId: dto.cityId } }),
      ]);
      if (!address) throw new BadRequestException('عنوان التوصيل غير صالح');
      if (!city) throw new BadRequestException('المدينة غير متاحة');
      if (!vendor) throw new BadRequestException('المتجر غير متاح في هذه المدينة');
      if (vendor.isOpen === false) throw new BadRequestException('المتجر مغلق حالياً ولا يستقبل طلبات جديدة');
      if (!deliveryZone) throw new BadRequestException('لم يتم إعداد رسوم التوصيل لهذه المدينة بعد');
      const feeBase = Number(deliveryZone.feeBase);
      const feePerKm = Number(deliveryZone.feePerKm);
      let distanceKm: number | null = null;
      if (feePerKm > 0) {
        const distances = await tx.$queryRaw<Array<{ distanceKm: number | null }>>`
          SELECT CASE
            WHEN a."point" IS NULL OR vl."point" IS NULL THEN NULL
            ELSE ST_Distance(a."point", vl."point") / 1000.0
          END AS "distanceKm"
          FROM "Address" a
          CROSS JOIN "VendorLocation" vl
          WHERE a."id" = ${dto.addressId}
            AND a."userId" = ${customerId}
            AND vl."vendorId" = ${vendor.id}
        `;
        distanceKm = distances[0]?.distanceKm ?? null;
        if (distanceKm === null) throw new BadRequestException('حدد موقع عنوان التوصيل وموقع المتجر لحساب رسوم التوصيل لكل كيلومتر');
      }
      const deliveryFee = feeBase + Math.ceil(distanceKm ?? 0) * feePerKm;
      const products = await tx.product.findMany({
        where: { id: { in: ids }, vendorId: vendor.id, isAvailable: true },
        include: { translations: { where: { locale: 'ar' }, take: 1 } },
      });
      if (products.length !== ids.length) throw new BadRequestException('بعض المنتجات لم تعد متاحة');
      const byId = new Map(products.map((p) => [p.id, p]));
      const subtotal = dto.items.reduce((sum, line) => {
        const p = byId.get(line.productId)!;
        if (p.currency !== city.defaultCurrency) throw new BadRequestException('عملة المنتج لا تطابق عملة المدينة');
        if (p.stockQty !== null && p.stockQty < line.quantity) throw new BadRequestException('الكمية المطلوبة غير متوفرة');
        return sum + Number(p.basePrice) * line.quantity;
      }, 0);
      // خصم المخزون داخل المعاملة نفسها لمنع بيع آخر قطعة مرتين عند وصول طلبين متزامنين.
      for (const line of dto.items) {
        const product = byId.get(line.productId)!;
        if (product.stockQty !== null) {
          const reserved = await tx.product.updateMany({
            where: { id: product.id, isAvailable: true, stockQty: { gte: line.quantity } },
            data: { stockQty: { decrement: line.quantity } },
          });
          if (reserved.count !== 1) throw new BadRequestException('نفدت كمية أحد المنتجات، حدّث السلة وحاول مجدداً');
        }
      }
      const order = await tx.order.create({
        data: {
          orderNumber: `DRB-${Date.now().toString(36).toUpperCase()}-${randomBytes(2).toString('hex').toUpperCase()}`,
          type: 'VENDOR_ORDER',
          status: 'PENDING',
          cityId: city.id,
          customerId,
          vendorId: vendor.id,
          addressId: address.id,
          currency: city.defaultCurrency,
          subtotal,
          deliveryFee,
          total: subtotal + deliveryFee,
          notes: dto.notes,
          items: {
            create: dto.items.map((line) => {
              const p = byId.get(line.productId)!;
              return {
                productId: p.id,
                quantity: line.quantity,
                unitPrice: p.basePrice,
                currency: p.currency,
                nameSnapshot: p.translations[0]?.name ?? 'منتج',
              };
            }),
          },
          payment: { create: { method: 'CASH_ON_DELIVERY', amount: subtotal + deliveryFee, currency: city.defaultCurrency } },
          statusHistory: { create: { status: 'PENDING', changedBy: customerId } },
        },
        include: { items: true, payment: true },
      });
      return order;
    });
  }

  async cancelByCustomer(customerId: string, orderId: string, reason?: string) {
    return this.prisma.$transaction(async (tx) => {
      const order = await tx.order.findFirst({
        where: { id: orderId, customerId },
        include: { items: { select: { productId: true, quantity: true } } },
      });
      if (!order) throw new NotFoundException('الطلب غير موجود');
      if (order.status !== OrderStatus.PENDING) {
        throw new BadRequestException('لا يمكن إلغاء الطلب بعد بدء تجهيزه أو إسناده لمندوب');
      }
      const updated = await tx.order.updateMany({
        where: { id: orderId, customerId, status: OrderStatus.PENDING },
        data: {
          status: OrderStatus.CANCELLED,
          ...(reason?.trim() ? { cancelReason: reason.trim().slice(0, 240) } : {}),
        },
      });
      if (!updated.count) {
        throw new BadRequestException('تغيّرت حالة الطلب قبل تنفيذ الإلغاء');
      }
      for (const item of order.items) {
        await tx.product.updateMany({
          where: { id: item.productId, stockQty: { not: null } },
          data: { stockQty: { increment: item.quantity } },
        });
      }
      await tx.deliveryOffer.updateMany({
        where: { orderId, status: 'PENDING' },
        data: { status: 'REJECTED' },
      });
      await tx.orderStatusHistory.create({
        data: { orderId, status: OrderStatus.CANCELLED, changedBy: customerId },
      });
      return tx.order.findUnique({ where: { id: orderId }, include: { statusHistory: true } });
    });
  }

  mine(userId: string) {
    return this.prisma.order.findMany({
      where: { customerId: userId },
      orderBy: { createdAt: 'desc' },
      include: { items: true, address: true, payment: true, statusHistory: { orderBy: { createdAt: 'asc' } } },
    });
  }

  async vendorOrders(userId: string) {
    const vendor = await this.prisma.vendor.findUnique({ where: { userId }, select: { id: true } });
    if (!vendor) throw new ForbiddenException();
    return this.prisma.order.findMany({
      where: { vendorId: vendor.id },
      orderBy: { createdAt: 'desc' },
      include: { items: true, address: true, customer: { select: { name: true, phone: true } } },
    });
  }

  async driverMine(userId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId }, select: { id: true } });
    if (!driver) throw new ForbiddenException();
    return this.prisma.order.findMany({
      where: { driverId: driver.id },
      orderBy: { createdAt: 'desc' },
      include: { items: true, address: true, vendor: { include: { location: true, translations: true } } },
    });
  }

  async availableForDriver(userId: string) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId },
      select: { id: true, cityId: true, status: true, isOnline: true },
    });
    if (!driver || driver.status !== 'APPROVED' || !driver.isOnline) {
      throw new ForbiddenException('السائق غير متصل أو غير معتمد');
    }
    const orders = await this.prisma.order.findMany({
      where: {
        cityId: driver.cityId,
        driverId: null,
        OR: [
          { type: 'VENDOR_ORDER', status: 'READY' },
          { type: 'PEER_DELIVERY', status: 'PENDING' },
        ],
      },
      orderBy: { createdAt: 'asc' },
      include: { items: true, vendor: { include: { location: true, translations: true } }, address: true },
    });
    if (!orders.length) return orders;

    const distances = await this.prisma.$queryRaw<Array<{ orderId: string; distanceKm: number | null }>>`
      SELECT o."id" AS "orderId",
        CASE
          WHEN dl."point" IS NULL OR dl."updatedAt" < NOW() - INTERVAL '2 minutes' THEN NULL
          WHEN o."type" = 'PEER_DELIVERY'
            AND o."pickupLatitude" IS NOT NULL AND o."pickupLongitude" IS NOT NULL
            THEN ST_Distance(
              dl."point",
              ST_SetSRID(ST_MakePoint(o."pickupLongitude", o."pickupLatitude"), 4326)::geography
            ) / 1000.0
          WHEN o."type" = 'VENDOR_ORDER' AND vl."point" IS NOT NULL
            THEN ST_Distance(dl."point", vl."point") / 1000.0
          ELSE NULL
        END AS "distanceKm"
      FROM "Order" o
      LEFT JOIN "DriverLocation" dl ON dl."driverId" = ${driver.id}
      LEFT JOIN "VendorLocation" vl ON vl."vendorId" = o."vendorId"
      WHERE o."cityId" = ${driver.cityId}
        AND o."driverId" IS NULL
        AND ((o."type" = 'VENDOR_ORDER' AND o."status" = 'READY')
          OR (o."type" = 'PEER_DELIVERY' AND o."status" = 'PENDING'))
    `;
    const distanceByOrder = new Map(distances.map((row) => [row.orderId, row.distanceKm]));
    return orders
      .map((order) => ({ ...order, distanceKm: distanceByOrder.get(order.id) ?? null }))
      .sort((a, b) => {
        if (a.distanceKm == null && b.distanceKm == null) {
          return a.createdAt.getTime() - b.createdAt.getTime();
        }
        if (a.distanceKm == null) return 1;
        if (b.distanceKm == null) return -1;
        return a.distanceKm - b.distanceKm || a.createdAt.getTime() - b.createdAt.getTime();
      });
  }

  async submitDeliveryOffer(userId: string, orderId: string, amount: number) {
    if (!Number.isFinite(amount) || amount <= 0 || amount > 10000000) {
      throw new BadRequestException('أدخل أجرة صحيحة أكبر من صفر');
    }
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver || driver.status !== 'APPROVED' || !driver.isOnline) {
      throw new ForbiddenException('يجب أن يكون حساب السائق معتمداً ومتصلًا');
    }
    return this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT "id" FROM "Order" WHERE "id" = ${orderId} FOR UPDATE`;
      const order = await tx.order.findFirst({
        where: { id: orderId, cityId: driver.cityId, type: 'PEER_DELIVERY', status: 'PENDING', driverId: null },
        select: { id: true, currency: true },
      });
      if (!order) throw new BadRequestException('الطلب لم يعد متاحاً لتقديم عرض');
      return tx.deliveryOffer.upsert({
        where: { orderId_driverId: { orderId, driverId: driver.id } },
        create: { orderId, driverId: driver.id, amount, currency: order.currency, status: 'PENDING' },
        update: { amount, currency: order.currency, status: 'PENDING', updatedAt: new Date() },
      });
    });
  }

  async deliveryOffersForCustomer(userId: string, orderId: string) {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, customerId: userId, type: 'PEER_DELIVERY' },
      select: { id: true, status: true },
    });
    if (!order) throw new NotFoundException('الطلب غير موجود');
    return this.prisma.deliveryOffer.findMany({
      where: { orderId, status: { in: ['PENDING', 'ACCEPTED'] } },
      orderBy: [{ amount: 'asc' }, { createdAt: 'asc' }],
      include: { driver: { select: { vehicleType: true, user: { select: { name: true } } } } },
    });
  }

  async selectDeliveryOffer(userId: string, orderId: string, offerId: string) {
    return this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT "id" FROM "Order" WHERE "id" = ${orderId} FOR UPDATE`;
      const order = await tx.order.findFirst({
        where: { id: orderId, customerId: userId, type: 'PEER_DELIVERY', status: 'PENDING', driverId: null },
        select: { id: true },
      });
      if (!order) throw new BadRequestException('لا يمكن اختيار عرض لهذا الطلب');
      const offer = await tx.deliveryOffer.findFirst({
        where: { id: offerId, orderId, status: 'PENDING', driver: { status: 'APPROVED', isOnline: true } },
        select: { id: true, driverId: true, amount: true, currency: true },
      });
      if (!offer) throw new BadRequestException('العرض لم يعد متاحاً');
      const changed = await tx.order.updateMany({
        where: { id: orderId, customerId: userId, status: 'PENDING', driverId: null },
        data: { driverId: offer.driverId, status: 'ASSIGNED', deliveryFee: offer.amount, total: offer.amount },
      });
      if (!changed.count) throw new BadRequestException('تم حجز الطلب من جلسة أخرى؛ حدّث الصفحة');
      await tx.payment.updateMany({ where: { orderId }, data: { amount: offer.amount, currency: offer.currency } });
      await tx.deliveryOffer.update({ where: { id: offer.id }, data: { status: 'ACCEPTED' } });
      await tx.deliveryOffer.updateMany({ where: { orderId, id: { not: offer.id }, status: 'PENDING' }, data: { status: 'REJECTED' } });
      await tx.orderStatusHistory.create({ data: { orderId, status: 'ASSIGNED', changedBy: userId } });
      return tx.order.findUnique({
        where: { id: orderId },
        include: { payment: true, address: true, driver: { include: { user: { select: { name: true } } } } },
      });
    });
  }

  async claim(userId: string, orderId: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver || driver.status !== 'APPROVED' || !driver.isOnline) {
      throw new ForbiddenException('السائق غير معتمد أو غير متصل');
    }
    return this.prisma.$transaction(async (tx) => {
      const result = await tx.order.updateMany({
        where: { id: orderId, cityId: driver.cityId, status: 'READY', driverId: null },
        data: { driverId: driver.id, status: 'ASSIGNED' },
      });
      if (!result.count) throw new BadRequestException('الطلب لم يعد متاحاً');
      await tx.orderStatusHistory.create({ data: { orderId, status: 'ASSIGNED', changedBy: userId } });
      return tx.order.findUnique({ where: { id: orderId }, include: { items: true, address: true } });
    });
  }

  async updateStatus(userId: string, role: UserRole, orderId: string, status: OrderStatus) {
    const allowed: Record<string, OrderStatus[]> = {
      VENDOR: [OrderStatus.ACCEPTED, OrderStatus.PREPARING, OrderStatus.READY, OrderStatus.CANCELLED],
      DRIVER: [OrderStatus.PICKED_UP, OrderStatus.DELIVERED],
    };
    if (!allowed[role]?.includes(status)) throw new BadRequestException('انتقال الحالة غير مسموح');
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { vendor: true, driver: true, items: { select: { productId: true, quantity: true } } },
    });
    if (!order) throw new NotFoundException('الطلب غير موجود');
    if (role === 'VENDOR' && order.vendor?.userId !== userId) throw new ForbiddenException();
    if (role === 'DRIVER' && order.driver?.userId !== userId) throw new ForbiddenException();
    const transitions: Record<string, OrderStatus[]> = {
      PENDING: [OrderStatus.ACCEPTED, OrderStatus.CANCELLED],
      ACCEPTED: [OrderStatus.PREPARING, OrderStatus.CANCELLED],
      PREPARING: [OrderStatus.READY],
      ASSIGNED: [OrderStatus.PICKED_UP],
      PICKED_UP: [OrderStatus.DELIVERED],
    };
    if (!transitions[order.status]?.includes(status)) throw new BadRequestException('تسلسل حالة الطلب غير صحيح');
    return this.prisma.$transaction(async (tx) => {
      const ownershipWhere: Record<string, unknown> = { id: orderId, status: order.status };
      if (role === 'VENDOR') ownershipWhere.vendorId = order.vendorId;
      if (role === 'DRIVER') ownershipWhere.driverId = order.driverId;
      const changed = await tx.order.updateMany({ where: ownershipWhere, data: { status } });
      if (!changed.count) throw new BadRequestException('تم تحديث الطلب من مستخدم آخر؛ أعد تحميله');
      if (status === OrderStatus.CANCELLED) {
        for (const item of order.items) {
          await tx.product.updateMany({
            where: { id: item.productId, stockQty: { not: null } },
            data: { stockQty: { increment: item.quantity } },
          });
        }
      }
      await tx.orderStatusHistory.create({ data: { orderId, status, changedBy: userId } });
      return tx.order.findUnique({ where: { id: orderId } });
    });
  }
}
