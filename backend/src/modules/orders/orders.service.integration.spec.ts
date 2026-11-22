import { PrismaClient, UserRole } from '@prisma/client';
import { randomUUID } from 'crypto';
import { OrdersService } from './orders.service';

const runDatabaseTests = process.env.DATABASE_URL ? describe : describe.skip;

runDatabaseTests('OrdersService PostgreSQL integration', () => {
  let prisma: PrismaClient;
  let service: OrdersService;
  let suffix: string;
  let customerId: string;
  let vendorUserId: string;
  let vendorId: string;
  let cityId: string;
  let addressId: string;
  let productId: string;
  let driverUserIds: string[] = [];

  const createDriver = async (status: 'APPROVED' | 'PENDING' = 'APPROVED') => {
    const user = await prisma.user.create({ data: { name: 'Integration driver' } });
    driverUserIds.push(user.id);
    const driver = await prisma.driver.create({
      data: { userId: user.id, cityId, status, isOnline: true },
    });
    return { userId: user.id, driverId: driver.id };
  };

  const createPeerOrder = async () => service.createPeerDelivery(customerId, {
    cityId,
    addressId,
    pickupAddress: 'Integration pickup, Aleppo',
    pickupLatitude: 36.2021,
    pickupLongitude: 37.1343,
  });

  beforeAll(async () => {
    prisma = new PrismaClient();
    service = new OrdersService(prisma as any);
  });

  beforeEach(async () => {
    suffix = randomUUID();
    driverUserIds = [];
    const customer = await prisma.user.create({ data: { name: 'Integration customer' } });
    const vendorUser = await prisma.user.create({ data: { name: 'Integration vendor' } });
    customerId = customer.id;
    vendorUserId = vendorUser.id;

    const city = await prisma.city.create({
      data: { code: `IT-${suffix.slice(0, 8)}`, isActive: true, defaultCurrency: 'SYP' },
    });
    cityId = city.id;
    const address = await prisma.address.create({ data: { userId: customerId, label: 'Home' } });
    addressId = address.id;

    const vendor = await prisma.vendor.create({
      data: { userId: vendorUserId, type: 'GROCERY', status: 'APPROVED' },
    });
    vendorId = vendor.id;
    await prisma.vendorCity.create({ data: { vendorId, cityId } });
    await prisma.deliveryZone.create({
      data: { cityId, name: 'Integration zone', feeBase: 100, feePerKm: 0 },
    });
    const product = await prisma.product.create({
      data: {
        vendorId, basePrice: 50, currency: 'SYP', isAvailable: true, stockQty: 1,
        translations: { create: { locale: 'ar', name: 'Integration product' } },
      },
    });
    productId = product.id;
  });

  afterEach(async () => {
    if (!cityId) return;
    await prisma.order.deleteMany({ where: { cityId } });
    await prisma.deliveryZone.deleteMany({ where: { cityId } });
    await prisma.vendorCity.deleteMany({ where: { cityId } });
    await prisma.driver.deleteMany({ where: { cityId } });
    await prisma.address.deleteMany({ where: { userId: customerId } });
    await prisma.product.deleteMany({ where: { vendorId } });
    await prisma.vendor.deleteMany({ where: { id: vendorId } });
    await prisma.city.deleteMany({ where: { id: cityId } });
    await prisma.user.deleteMany({ where: { id: { in: [customerId, vendorUserId, ...driverUserIds] } } });
  });

  afterAll(async () => {
    await prisma?.$disconnect();
  });

  it('reserves finite stock atomically when two orders compete for the last unit', async () => {
    const attempts = await Promise.allSettled([
      service.create(customerId, {
        cityId, addressId, vendorId, items: [{ productId, quantity: 1 }],
      }),
      service.create(customerId, {
        cityId, addressId, vendorId, items: [{ productId, quantity: 1 }],
      }),
    ]);

    expect(attempts.filter(x => x.status === 'fulfilled')).toHaveLength(1);
    expect(attempts.filter(x => x.status === 'rejected')).toHaveLength(1);
    expect(await prisma.product.findUnique({ where: { id: productId } }).then(p => p?.stockQty)).toBe(0);
    expect(await prisma.order.count({ where: { cityId, type: 'VENDOR_ORDER' } })).toBe(1);
  });

  it('restores reserved stock exactly once when cancellation requests race', async () => {
    const order = await service.create(customerId, {
      cityId, addressId, vendorId, items: [{ productId, quantity: 1 }],
    });
    expect((await prisma.product.findUnique({ where: { id: productId } }))?.stockQty).toBe(0);

    const outcomes = await Promise.allSettled([
      service.updateStatus(vendorUserId, UserRole.VENDOR, order.id, 'CANCELLED' as any),
      service.updateStatus(vendorUserId, UserRole.VENDOR, order.id, 'CANCELLED' as any),
    ]);

    expect(outcomes.filter(x => x.status === 'fulfilled')).toHaveLength(1);
    expect(outcomes.filter(x => x.status === 'rejected')).toHaveLength(1);
    expect((await prisma.product.findUnique({ where: { id: productId } }))?.stockQty).toBe(1);
    expect(await prisma.orderStatusHistory.count({ where: { orderId: order.id, status: 'CANCELLED' } })).toBe(1);
  });

  it('serializes a new peer-delivery offer against selection and leaves no pending offer on an assigned order', async () => {
    const order = await createPeerOrder();
    const first = await createDriver();
    const second = await createDriver();
    const firstOffer = await prisma.deliveryOffer.create({
      data: { orderId: order.id, driverId: first.driverId, amount: 80, currency: 'SYP' },
    });

    const results = await Promise.allSettled([
      service.submitDeliveryOffer(second.userId, order.id, 90),
      service.selectDeliveryOffer(customerId, order.id, firstOffer.id),
    ]);

    expect(results.some(x => x.status === 'fulfilled')).toBe(true);
    const persistedOrder = await prisma.order.findUnique({ where: { id: order.id } });
    expect(persistedOrder?.status).toBe('ASSIGNED');
    expect(persistedOrder?.driverId).toBe(first.driverId);
    expect(await prisma.deliveryOffer.count({ where: { orderId: order.id, status: 'PENDING' } })).toBe(0);
  });

  it('allows only one of two concurrent customer offer selections to assign a peer order', async () => {
    const order = await createPeerOrder();
    const first = await createDriver();
    const second = await createDriver();
    const [firstOffer, secondOffer] = await Promise.all([
      prisma.deliveryOffer.create({
        data: { orderId: order.id, driverId: first.driverId, amount: 80, currency: 'SYP' },
      }),
      prisma.deliveryOffer.create({
        data: { orderId: order.id, driverId: second.driverId, amount: 90, currency: 'SYP' },
      }),
    ]);

    const results = await Promise.allSettled([
      service.selectDeliveryOffer(customerId, order.id, firstOffer.id),
      service.selectDeliveryOffer(customerId, order.id, secondOffer.id),
    ]);

    expect(results.filter(x => x.status === 'fulfilled')).toHaveLength(1);
    expect(results.filter(x => x.status === 'rejected')).toHaveLength(1);
    expect(await prisma.order.count({ where: { id: order.id, status: 'ASSIGNED', driverId: { not: null } } })).toBe(1);
    expect(await prisma.deliveryOffer.count({ where: { orderId: order.id, status: 'ACCEPTED' } })).toBe(1);
    expect(await prisma.deliveryOffer.count({ where: { orderId: order.id, status: 'PENDING' } })).toBe(0);
  });
});
