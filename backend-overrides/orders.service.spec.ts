import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { OrderStatus } from '@prisma/client';
import { OrdersService } from './orders.service';

describe('OrdersService safety checks', () => {
  const prisma: any = {
    $transaction: jest.fn(),
    driver: { findUnique: jest.fn() },
    order: { findUnique: jest.fn(), updateMany: jest.fn() },
    orderStatusHistory: { create: jest.fn() },
  };
  let service: OrdersService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new OrdersService(prisma);
  });

  it('creates a peer-delivery order without vendor or catalog items', async () => {
    const create = jest.fn().mockResolvedValue({ id: 'peer-1', type: 'PEER_DELIVERY' });
    const tx: any = {
      address: { findFirst: jest.fn().mockResolvedValue({ id: 'address-1' }) },
      city: { findFirst: jest.fn().mockResolvedValue({ id: 'city-1', defaultCurrency: 'SYP' }) },

      order: { create },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback(tx));

    await service.createPeerDelivery('customer-1', {
      cityId: 'city-1', addressId: 'address-1', pickupAddress: 'شارع الجامعة، حلب', pickupLatitude: 36.2021, pickupLongitude: 37.1343,
    });

    expect(create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        type: 'PEER_DELIVERY', status: 'PENDING', cityId: 'city-1',
        customerId: 'customer-1', addressId: 'address-1',
        pickupAddress: 'شارع الجامعة، حلب', pickupLatitude: 36.2021, pickupLongitude: 37.1343,
        subtotal: 0, deliveryFee: 0, total: 0,
        payment: { create: expect.objectContaining({ method: 'CASH_ON_DELIVERY', amount: 0, currency: 'SYP' }) },
        statusHistory: { create: { status: 'PENDING', changedBy: 'customer-1' } },
      }),
      include: { payment: true, address: true },
    }));
  });

  it('rejects a peer-delivery pickup address that is too short before opening a transaction', async () => {
    await expect(service.createPeerDelivery('customer-1', {
      cityId: 'city-1', addressId: 'address-1', pickupAddress: 'abc', pickupLatitude: 36.2, pickupLongitude: 37.1,
    })).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('rejects an empty order before opening a transaction', async () => {
    await expect(service.create('customer-1', {
      cityId: 'city-1', addressId: 'address-1', vendorId: 'vendor-1', items: [],
    })).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('rejects duplicate product lines inside the transaction', async () => {
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) =>
      callback({ address: { findFirst: jest.fn().mockResolvedValue({ id: 'address-1' }) },
        city: { findFirst: jest.fn().mockResolvedValue({ id: 'city-1', defaultCurrency: 'SYP' }) },
        vendor: { findFirst: jest.fn().mockResolvedValue({ id: 'vendor-1' }) },
        deliveryZone: { findFirst: jest.fn().mockResolvedValue({ feeBase: 100 }) },
      }),
    );
    await expect(service.create('customer-1', {
      cityId: 'city-1', addressId: 'address-1', vendorId: 'vendor-1',
      items: [{ productId: 'product-1', quantity: 1 }, { productId: 'product-1', quantity: 2 }],
    })).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects checkout for a closed vendor before reading products or reserving stock', async () => {
    const productFindMany = jest.fn();
    const tx: any = {
      address: { findFirst: jest.fn().mockResolvedValue({ id: 'address-1' }) },
      city: { findFirst: jest.fn().mockResolvedValue({ id: 'city-1', defaultCurrency: 'SYP' }) },
      vendor: { findFirst: jest.fn().mockResolvedValue({ id: 'vendor-1', isOpen: false }) },
      deliveryZone: { findUnique: jest.fn().mockResolvedValue({ feeBase: 100, feePerKm: 0 }) },
      product: { findMany: productFindMany },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback(tx));

    await expect(service.create('customer-1', {
      cityId: 'city-1',
      addressId: 'address-1',
      vendorId: 'vendor-1',
      items: [{ productId: 'product-1', quantity: 1 }],
    })).rejects.toBeInstanceOf(BadRequestException);

    expect(productFindMany).not.toHaveBeenCalled();
  });

  it('adds the rounded-up PostGIS distance fee to the order total', async () => {
    const create = jest.fn().mockResolvedValue({ id: 'order-1' });
    const tx: any = {
      address: { findFirst: jest.fn().mockResolvedValue({ id: 'address-1' }) },
      city: { findFirst: jest.fn().mockResolvedValue({ id: 'city-1', defaultCurrency: 'SYP' }) },
      vendor: { findFirst: jest.fn().mockResolvedValue({ id: 'vendor-1' }) },
      deliveryZone: { findUnique: jest.fn().mockResolvedValue({ feeBase: 100, feePerKm: 25 }) },
      $queryRaw: jest.fn().mockResolvedValue([{ distanceKm: 1.25 }]),
      product: { findMany: jest.fn().mockResolvedValue([{
        id: 'product-1', currency: 'SYP', basePrice: 50, stockQty: null,
        translations: [{ name: 'منتج' }],
      }]) },
      order: { create },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback(tx));

    await service.create('customer-1', {
      cityId: 'city-1', addressId: 'address-1', vendorId: 'vendor-1',
      items: [{ productId: 'product-1', quantity: 1 }],
    });

    expect(create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ deliveryFee: 150, total: 200 }),
    }));
  });

  it('refuses per-kilometre pricing when either GPS point is missing', async () => {
    const create = jest.fn();
    const tx: any = {
      address: { findFirst: jest.fn().mockResolvedValue({ id: 'address-1' }) },
      city: { findFirst: jest.fn().mockResolvedValue({ id: 'city-1', defaultCurrency: 'SYP' }) },
      vendor: { findFirst: jest.fn().mockResolvedValue({ id: 'vendor-1' }) },
      deliveryZone: { findUnique: jest.fn().mockResolvedValue({ feeBase: 100, feePerKm: 25 }) },
      $queryRaw: jest.fn().mockResolvedValue([{ distanceKm: null }]),
      product: { findMany: jest.fn() },
      order: { create },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback(tx));

    await expect(service.create('customer-1', {
      cityId: 'city-1', addressId: 'address-1', vendorId: 'vendor-1',
      items: [{ productId: 'product-1', quantity: 1 }],
    })).rejects.toBeInstanceOf(BadRequestException);
    expect(create).not.toHaveBeenCalled();
  });

  it('uses an atomic READY/unassigned claim and rejects a lost race', async () => {
    prisma.driver.findUnique.mockResolvedValue({
      id: 'driver-1', cityId: 'city-1', status: 'APPROVED', isOnline: true,
    });
    const tx = {
      order: { updateMany: jest.fn().mockResolvedValue({ count: 0 }), findUnique: jest.fn() },
      orderStatusHistory: { create: jest.fn() },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback(tx));

    await expect(service.claim('driver-user-1', 'order-1')).rejects.toBeInstanceOf(BadRequestException);
    expect(tx.order.updateMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'order-1', cityId: 'city-1', status: 'READY', driverId: null },
      data: { driverId: 'driver-1', status: 'ASSIGNED' },
    }));
    expect(tx.orderStatusHistory.create).not.toHaveBeenCalled();
  });

  it('blocks a vendor from changing another vendor order', async () => {
    prisma.order.findUnique.mockResolvedValue({
      id: 'order-1', status: 'PENDING',
      vendor: { userId: 'different-vendor-user' }, driver: null,
    });
    await expect(service.updateStatus('vendor-user-1', 'VENDOR', 'order-1', OrderStatus.ACCEPTED))
      .rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('rejects invalid status transitions before writing history', async () => {
    prisma.order.findUnique.mockResolvedValue({
      id: 'order-1', status: 'PENDING',
      vendor: { userId: 'vendor-user-1' }, driver: null,
    });
    await expect(service.updateStatus('vendor-user-1', 'VENDOR', 'order-1', OrderStatus.READY))
      .rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('restores reserved finite stock exactly when a vendor cancellation succeeds', async () => {
    prisma.order.findUnique.mockResolvedValue({
      id: 'order-1', status: 'PENDING', vendorId: 'vendor-1',
      vendor: { id: 'vendor-1', userId: 'vendor-user-1' }, driver: null,
      items: [{ productId: 'product-1', quantity: 3 }, { productId: 'product-2', quantity: 1 }],
    });
    const productUpdateMany = jest.fn().mockResolvedValue({ count: 1 });
    const orderUpdateMany = jest.fn().mockResolvedValue({ count: 1 });
    const tx = {
      order: { updateMany: orderUpdateMany, findUnique: jest.fn().mockResolvedValue({ id: 'order-1', status: 'CANCELLED' }) },
      product: { updateMany: productUpdateMany },
      orderStatusHistory: { create: jest.fn() },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback(tx));

    await service.updateStatus('vendor-user-1', 'VENDOR', 'order-1', OrderStatus.CANCELLED);

    expect(orderUpdateMany).toHaveBeenCalledWith({
      where: { id: 'order-1', status: 'PENDING', vendorId: 'vendor-1' },
      data: { status: OrderStatus.CANCELLED },
    });
    expect(productUpdateMany).toHaveBeenNthCalledWith(1, {
      where: { id: 'product-1', stockQty: { not: null } },
      data: { stockQty: { increment: 3 } },
    });
    expect(productUpdateMany).toHaveBeenNthCalledWith(2, {
      where: { id: 'product-2', stockQty: { not: null } },
      data: { stockQty: { increment: 1 } },
    });
    expect(tx.orderStatusHistory.create).toHaveBeenCalledWith({
      data: { orderId: 'order-1', status: OrderStatus.CANCELLED, changedBy: 'vendor-user-1' },
    });
  });

  it('rejects stale concurrent status updates', async () => {
    prisma.order.findUnique.mockResolvedValue({
      id: 'order-1', status: 'PENDING',
      vendor: { userId: 'vendor-user-1' }, driver: null,
    });
    const tx = {
      order: { updateMany: jest.fn().mockResolvedValue({ count: 0 }), findUnique: jest.fn() },
      orderStatusHistory: { create: jest.fn() },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback(tx));
    await expect(service.updateStatus('vendor-user-1', 'VENDOR', 'order-1', OrderStatus.ACCEPTED))
      .rejects.toBeInstanceOf(BadRequestException);
    expect(tx.orderStatusHistory.create).not.toHaveBeenCalled();
  });
  it('blocks shopping pickup until an approved purchase proof is recorded', async () => {
    prisma.order.findUnique.mockResolvedValue({
      id: 'shopping-1', type: 'SHOPPING_DELIVERY', status: 'ASSIGNED', driverId: 'driver-1',
      driver: { userId: 'driver-user-1' }, vendor: null, items: [],
    });
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    const findProof = jest.fn().mockResolvedValue(null);
    const tx: any = {
      order: { updateMany },
      shoppingPurchaseQuote: { findFirst: findProof },
      orderStatusHistory: { create: jest.fn() },
    };
    prisma.$transaction.mockImplementation(async (cb: (tx: any) => unknown) => cb(tx));
    await expect(service.updateStatus('driver-user-1', 'DRIVER', 'shopping-1', OrderStatus.PICKED_UP)).rejects.toBeInstanceOf(BadRequestException);
    expect(findProof).toHaveBeenCalled();
    expect(tx.orderStatusHistory.create).not.toHaveBeenCalled();
  });
  it('creates a shopping delivery request with a separate purchase budget', async () => {
    const create = jest.fn().mockResolvedValue({ id: 'shopping-1', type: 'SHOPPING_DELIVERY' });
    const tx: any = {
      address: { findFirst: jest.fn().mockResolvedValue({ id: 'address-1' }) },
      city: { findFirst: jest.fn().mockResolvedValue({ id: 'city-1', defaultCurrency: 'SYP' }) },
      order: { create },
    };
    prisma.$transaction.mockImplementation(async (cb: (tx: any) => unknown) => cb(tx));
    await service.createShoppingRequest('customer-1', { cityId: 'city-1', addressId: 'address-1', itemName: 'مستلزمات منزلية', description: 'منظف وورق مطبخ', maxPurchaseBudget: 250 });
    expect(create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({
      type: 'SHOPPING_DELIVERY', shoppingItemName: 'مستلزمات منزلية', shoppingDescription: 'منظف وورق مطبخ',
      shoppingMaxBudget: 250, subtotal: 0, deliveryFee: 0, total: 0,
    }) }));
  });

  it('requires explicit customer override when a shopping quote exceeds the budget', async () => {
    const tx: any = {
      $queryRaw: jest.fn(),
      order: { findFirst: jest.fn().mockResolvedValue({ id: 'shopping-1', shoppingMaxBudget: 100 }) },
      shoppingPurchaseQuote: { findFirst: jest.fn().mockResolvedValue({ id: 'quote-1', amount: 150 }) },
    };
    prisma.$transaction.mockImplementation(async (cb: (tx: any) => unknown) => cb(tx));
    await expect(service.approveShoppingPurchaseQuote('customer-1', 'shopping-1', 'quote-1', false)).rejects.toBeInstanceOf(BadRequestException);
    expect(tx.shoppingPurchaseQuote.update).toBeUndefined();
  });

  it('records shopping proof only against an approved quote assigned to the driver', async () => {
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', status: 'APPROVED' });
    const update = jest.fn().mockResolvedValue({ id: 'quote-1', purchasedAt: new Date() });
    const tx: any = {
      $queryRaw: jest.fn(),
      order: { findFirst: jest.fn().mockResolvedValue({ id: 'shopping-1' }) },
      shoppingPurchaseQuote: { findFirst: jest.fn().mockResolvedValue({ id: 'quote-1' }), update },
    };
    prisma.$transaction.mockImplementation(async (cb: (tx: any) => unknown) => cb(tx));
    await service.recordShoppingPurchaseProof('driver-user-1', 'shopping-1', { receiptReference: 'INV-2026-11' });
    expect(update).toHaveBeenCalledWith(expect.objectContaining({ where: { id: 'quote-1' }, data: expect.objectContaining({ receiptReference: 'INV-2026-11', purchasedAt: expect.any(Date) }) }));
  });

  it('does not allow a driver to record purchase proof before customer approval', async () => {
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', status: 'APPROVED' });
    const tx: any = {
      $queryRaw: jest.fn(),
      order: { findFirst: jest.fn().mockResolvedValue({ id: 'shopping-1' }) },
      shoppingPurchaseQuote: { findFirst: jest.fn().mockResolvedValue(null), update: jest.fn() },
    };
    prisma.$transaction.mockImplementation(async (cb: (tx: any) => unknown) => cb(tx));
    await expect(service.recordShoppingPurchaseProof('driver-user-1', 'shopping-1', { receiptReference: 'INV-1' })).rejects.toBeInstanceOf(BadRequestException);
    expect(tx.shoppingPurchaseQuote.update).not.toHaveBeenCalled();
  });
});

describe('Peer delivery offers', () => {
  const prisma: any = {
    $transaction: jest.fn(),
    driver: { findUnique: jest.fn() },
    order: { findFirst: jest.fn() },
    deliveryOffer: { findMany: jest.fn() },
  };
  let service: OrdersService;
  beforeEach(() => { jest.clearAllMocks(); service = new OrdersService(prisma); });

  it('allows only an approved online driver to submit a positive offer', async () => {
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', cityId: 'city-1', status: 'APPROVED', isOnline: true });
    const upsert = jest.fn().mockResolvedValue({ id: 'offer-1', amount: 75 });
    const tx: any = {
      $queryRaw: jest.fn().mockResolvedValue([]),
      order: { findFirst: jest.fn().mockResolvedValue({ id: 'order-1', currency: 'SYP' }) },
      deliveryOffer: { upsert },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback(tx));

    await service.submitDeliveryOffer('driver-user-1', 'order-1', 75);

    expect(upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { orderId_driverId: { orderId: 'order-1', driverId: 'driver-1' } },
      create: expect.objectContaining({ orderId: 'order-1', driverId: 'driver-1', amount: 75, currency: 'SYP', status: 'PENDING' }),
    }));
  });

  it('rejects an offer with zero or negative amount before database access', async () => {
    await expect(service.submitDeliveryOffer('driver-user-1', 'order-1', 0)).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.driver.findUnique).not.toHaveBeenCalled();
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('assigns a peer order to exactly the selected driver and closes other pending offers', async () => {
    const orderUpdateMany = jest.fn().mockResolvedValue({ count: 1 });
    const offerUpdate = jest.fn();
    const offerUpdateMany = jest.fn();
    const historyCreate = jest.fn();
    const tx: any = {
      $queryRaw: jest.fn().mockResolvedValue([]),
      order: { findFirst: jest.fn().mockResolvedValue({ id: 'order-1' }), updateMany: orderUpdateMany, findUnique: jest.fn().mockResolvedValue({ id: 'order-1', status: 'ASSIGNED' }) },
      deliveryOffer: {
        findFirst: jest.fn().mockResolvedValue({ id: 'offer-1', driverId: 'driver-1', amount: 75, currency: 'SYP' }),
        update: offerUpdate, updateMany: offerUpdateMany,
      },
      payment: { updateMany: jest.fn() },
      orderStatusHistory: { create: historyCreate },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback(tx));

    await service.selectDeliveryOffer('customer-1', 'order-1', 'offer-1');

    expect(orderUpdateMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'order-1', customerId: 'customer-1', status: 'PENDING', driverId: null },
      data: { driverId: 'driver-1', status: 'ASSIGNED', deliveryFee: 75, total: 75 },
    }));
    expect(offerUpdate).toHaveBeenCalledWith({ where: { id: 'offer-1' }, data: { status: 'ACCEPTED' } });
    expect(offerUpdateMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { orderId: 'order-1', id: { not: 'offer-1' }, status: 'PENDING' },
      data: { status: 'REJECTED' },
    }));
    expect(historyCreate).toHaveBeenCalled();
  });

  it('rejects a selection if another customer session already claimed the order', async () => {
    const tx: any = {
      $queryRaw: jest.fn().mockResolvedValue([]),
      order: { findFirst: jest.fn().mockResolvedValue({ id: 'order-1' }), updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
      deliveryOffer: { findFirst: jest.fn().mockResolvedValue({ id: 'offer-1', driverId: 'driver-1', amount: 75, currency: 'SYP' }) },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback(tx));
    await expect(service.selectDeliveryOffer('customer-1', 'order-1', 'offer-1')).rejects.toBeInstanceOf(BadRequestException);
  });
  it('rejects offers from drivers who are not approved or online', async () => {
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', cityId: 'city-1', status: 'PENDING', isOnline: true });
    await expect(service.submitDeliveryOffer('driver-user-1', 'order-1', 75)).rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('rejects offers when the order is not pending or belongs to another city', async () => {
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', cityId: 'city-2', status: 'APPROVED', isOnline: true });
    const findFirst = jest.fn().mockResolvedValue(null);
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback({
      $queryRaw: jest.fn().mockResolvedValue([]),
      order: { findFirst }, deliveryOffer: { upsert: jest.fn() },
    }));
    await expect(service.submitDeliveryOffer('driver-user-1', 'order-1', 75)).rejects.toBeInstanceOf(BadRequestException);
    expect(findFirst).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'order-1', cityId: 'city-2', type: { in: ['PEER_DELIVERY', 'SHOPPING_DELIVERY'] }, status: 'PENDING', driverId: null },
    }));
  });

  it('does not expose offers to a customer who does not own the peer order', async () => {
    prisma.order.findFirst.mockResolvedValue(null);
    await expect(service.deliveryOffersForCustomer('another-customer', 'order-1')).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.order.findFirst).toHaveBeenCalledWith({
      where: { id: 'order-1', customerId: 'another-customer', type: { in: ['PEER_DELIVERY', 'SHOPPING_DELIVERY'] } },
      select: { id: true, status: true },
    });
    expect(prisma.deliveryOffer.findMany).not.toHaveBeenCalled();
  });

  it('rejects selecting an offer when the customer does not own the order', async () => {
    const orderFindFirst = jest.fn().mockResolvedValue(null);
    const offerFindFirst = jest.fn();
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback({
      $queryRaw: jest.fn().mockResolvedValue([]),
      order: { findFirst: orderFindFirst }, deliveryOffer: { findFirst: offerFindFirst },
    }));
    await expect(service.selectDeliveryOffer('another-customer', 'order-1', 'offer-1')).rejects.toBeInstanceOf(BadRequestException);
    expect(offerFindFirst).not.toHaveBeenCalled();
  });

  it('rejects selecting an offer from a driver who is no longer approved and online', async () => {
    const offerFindFirst = jest.fn().mockResolvedValue(null);
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback({
      $queryRaw: jest.fn().mockResolvedValue([]),
      order: { findFirst: jest.fn().mockResolvedValue({ id: 'order-1' }) },
      deliveryOffer: { findFirst: offerFindFirst },
    }));
    await expect(service.selectDeliveryOffer('customer-1', 'order-1', 'offer-1')).rejects.toBeInstanceOf(BadRequestException);
    expect(offerFindFirst).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'offer-1', orderId: 'order-1', status: 'PENDING', driver: { status: 'APPROVED', isOnline: true } },
    }));
  });

  it('allows only one concurrent offer selection to win the conditional order claim', async () => {
    const orderUpdateMany = jest.fn()
      .mockResolvedValueOnce({ count: 1 })
      .mockResolvedValueOnce({ count: 0 });
    const tx: any = {
      $queryRaw: jest.fn().mockResolvedValue([]),
      order: {
        findFirst: jest.fn().mockResolvedValue({ id: 'order-1' }),
        updateMany: orderUpdateMany,
        findUnique: jest.fn().mockResolvedValue({ id: 'order-1', status: 'ASSIGNED' }),
      },
      deliveryOffer: {
        findFirst: jest.fn().mockImplementation(({ where }: any) => Promise.resolve({
          id: where.id, driverId: where.id === 'offer-1' ? 'driver-1' : 'driver-2', amount: 75, currency: 'SYP',
        })),
        update: jest.fn(), updateMany: jest.fn(),
      },
      payment: { updateMany: jest.fn() },
      orderStatusHistory: { create: jest.fn() },
    };
    prisma.$transaction.mockImplementation(async (callback: (tx: any) => unknown) => callback(tx));
    const results = await Promise.allSettled([
      service.selectDeliveryOffer('customer-1', 'order-1', 'offer-1'),
      service.selectDeliveryOffer('customer-1', 'order-1', 'offer-2'),
    ]);
    expect(results.filter(result => result.status === 'fulfilled')).toHaveLength(1);
    expect(results.filter(result => result.status === 'rejected')).toHaveLength(1);
    expect(orderUpdateMany).toHaveBeenCalledTimes(2);
  });
});


describe('Driver available-order proximity ranking', () => {
  const prisma: any = {
    driver: { findUnique: jest.fn() },
    order: { findMany: jest.fn() },
    $queryRaw: jest.fn(),
  };
  const service = new OrdersService(prisma);
  const createdAt = (minute: number) => new Date(Date.UTC(2026, 0, 1, 0, minute));

  beforeEach(() => jest.clearAllMocks());

  it('ranks vendor and peer-delivery pickup tasks by fresh driver distance', async () => {
    prisma.driver.findUnique.mockResolvedValue({
      id: 'driver-1', cityId: 'city-1', status: 'APPROVED', isOnline: true,
    });
    prisma.order.findMany.mockResolvedValue([
      { id: 'far', type: 'VENDOR_ORDER', createdAt: createdAt(0) },
      { id: 'near', type: 'PEER_DELIVERY', createdAt: createdAt(1) },
      { id: 'middle', type: 'VENDOR_ORDER', createdAt: createdAt(2) },
    ]);
    prisma.$queryRaw.mockResolvedValue([
      { orderId: 'far', distanceKm: 8.2 },
      { orderId: 'near', distanceKm: 0.7 },
      { orderId: 'middle', distanceKm: 3.1 },
    ]);

    const result = await service.availableForDriver('driver-user-1');

    expect(result.map((order: any) => order.id)).toEqual(['near', 'middle', 'far']);
    expect(result.map((order: any) => order.distanceKm)).toEqual([0.7, 3.1, 8.2]);
    expect(prisma.$queryRaw).toHaveBeenCalledTimes(1);
  });

  it('keeps orders without a usable fresh distance after ranked orders', async () => {
    prisma.driver.findUnique.mockResolvedValue({
      id: 'driver-1', cityId: 'city-1', status: 'APPROVED', isOnline: true,
    });
    prisma.order.findMany.mockResolvedValue([
      { id: 'older-no-gps', type: 'PEER_DELIVERY', createdAt: createdAt(0) },
      { id: 'near', type: 'VENDOR_ORDER', createdAt: createdAt(1) },
      { id: 'newer-no-gps', type: 'VENDOR_ORDER', createdAt: createdAt(2) },
    ]);
    prisma.$queryRaw.mockResolvedValue([
      { orderId: 'older-no-gps', distanceKm: null },
      { orderId: 'near', distanceKm: 1.2 },
      { orderId: 'newer-no-gps', distanceKm: null },
    ]);

    const result = await service.availableForDriver('driver-user-1');

    expect(result.map((order: any) => order.id)).toEqual(['near', 'older-no-gps', 'newer-no-gps']);
    expect((result[1] as any).distanceKm).toBeNull();
    expect((result[2] as any).distanceKm).toBeNull();
  });

  it('does not query or return tasks for an offline driver', async () => {
    prisma.driver.findUnique.mockResolvedValue({
      id: 'driver-1', cityId: 'city-1', status: 'APPROVED', isOnline: false,
    });

    await expect(service.availableForDriver('driver-user-1')).rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.order.findMany).not.toHaveBeenCalled();
    expect(prisma.$queryRaw).not.toHaveBeenCalled();
  });
});

describe('Order dismissal, offer withdrawal, and reviews', () => {
  const prisma: any = {
    $transaction: jest.fn(),
    driver: { findUnique: jest.fn() },
    order: { findFirst: jest.fn() },
    driverDismissedOrder: { upsert: jest.fn() },
  };
  const service = new OrdersService(prisma);

  beforeEach(() => jest.clearAllMocks());

  it('records a driver dismissal for an available order', async () => {
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', cityId: 'city-1', status: 'APPROVED' });
    prisma.order.findFirst.mockResolvedValue({ id: 'order-1' });
    prisma.driverDismissedOrder.upsert.mockResolvedValue({ id: 'dismiss-1' });

    const res = await service.dismissOrder('driver-user-1', 'order-1');
    expect(res).toEqual({ dismissed: true, orderId: 'order-1' });
    expect(prisma.driverDismissedOrder.upsert).toHaveBeenCalled();
  });

  it('allows a driver to withdraw their own pending delivery offer', async () => {
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', status: 'APPROVED' });
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    prisma.$transaction.mockImplementation(async (cb: (tx: any) => unknown) => cb({ deliveryOffer: { updateMany } }));

    const res = await service.withdrawDeliveryOffer('driver-user-1', 'order-1');
    expect(res).toEqual({ withdrawn: true, orderId: 'order-1' });
    expect(updateMany).toHaveBeenCalledWith({
      where: { orderId: 'order-1', driverId: 'driver-1', status: 'PENDING' },
      data: { status: 'WITHDRAWN' },
    });
  });

  it('creates a review for a delivered order and recalculates vendor ratingAvg', async () => {
    const tx: any = {
      order: { findFirst: jest.fn().mockResolvedValue({ id: 'order-1', status: 'DELIVERED', vendorId: 'vendor-1' }) },
      review: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue({ id: 'rev-1', orderId: 'order-1', vendorId: 'vendor-1', rating: 5, comment: 'ممتاز' }),
        aggregate: jest.fn().mockResolvedValue({ _avg: { rating: 4.5 } }),
      },
      vendor: { update: jest.fn() },
    };
    prisma.$transaction.mockImplementation(async (cb: (t: any) => unknown) => cb(tx));

    const result = await service.createReview('customer-1', 'order-1', { rating: 5, comment: 'ممتاز' });
    expect(result.ratingAvg).toBe(4.5);
    expect(tx.vendor.update).toHaveBeenCalledWith({ where: { id: 'vendor-1' }, data: { ratingAvg: 4.5 } });
  });

  it('rejects reviewing an order that has not been delivered yet', async () => {
    const tx: any = {
      order: { findFirst: jest.fn().mockResolvedValue({ id: 'order-1', status: 'PREPARING', vendorId: 'vendor-1' }) },
    };
    prisma.$transaction.mockImplementation(async (cb: (t: any) => unknown) => cb(tx));

    await expect(service.createReview('customer-1', 'order-1', { rating: 5 })).rejects.toBeInstanceOf(BadRequestException);
  });
});
