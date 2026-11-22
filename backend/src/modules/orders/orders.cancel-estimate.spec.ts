import { BadRequestException } from '@nestjs/common';
import { OrderStatus } from '@prisma/client';
import { OrdersService } from './orders.service';

describe('OrdersService cancel and estimate', () => {
  const prisma: any = {
    $transaction: jest.fn(),
    address: { findFirst: jest.fn() },
    city: { findFirst: jest.fn() },
    vendor: { findFirst: jest.fn() },
    deliveryZone: { findUnique: jest.fn() },
    product: { findMany: jest.fn() },
    $queryRaw: jest.fn(),
  };
  let service: OrdersService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new OrdersService(prisma);
  });

  it('allows customer cancellation only while order is PENDING and restores finite stock', async () => {
    const productUpdateMany = jest.fn().mockResolvedValue({ count: 1 });
    const historyCreate = jest.fn().mockResolvedValue({});
    const tx: any = {
      order: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'ord-1',
          customerId: 'cust-1',
          status: OrderStatus.PENDING,
          items: [{ productId: 'prod-1', quantity: 2 }],
        }),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
        findUnique: jest.fn().mockResolvedValue({ id: 'ord-1', status: OrderStatus.CANCELLED }),
      },
      product: { updateMany: productUpdateMany },
      deliveryOffer: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
      orderStatusHistory: { create: historyCreate },
    };
    prisma.$transaction.mockImplementation(async (cb: (t: any) => unknown) => cb(tx));

    const cancelled = await service.cancelByCustomer('cust-1', 'ord-1', 'تغيير العنوان');
    expect(cancelled?.status).toBe(OrderStatus.CANCELLED);
    expect(productUpdateMany).toHaveBeenCalledWith({
      where: { id: 'prod-1', stockQty: { not: null } },
      data: { stockQty: { increment: 2 } },
    });
    expect(historyCreate).toHaveBeenCalledWith({
      data: { orderId: 'ord-1', status: OrderStatus.CANCELLED, changedBy: 'cust-1' },
    });
  });

  it('rejects customer cancellation once order is ACCEPTED or further along', async () => {
    const tx: any = {
      order: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'ord-2',
          customerId: 'cust-1',
          status: OrderStatus.PREPARING,
          items: [],
        }),
      },
    };
    prisma.$transaction.mockImplementation(async (cb: (t: any) => unknown) => cb(tx));

    await expect(service.cancelByCustomer('cust-1', 'ord-2')).rejects.toBeInstanceOf(BadRequestException);
  });

  it('calculates order delivery fee and subtotal estimate accurately', async () => {
    prisma.address.findFirst.mockResolvedValue({ id: 'addr-1' });
    prisma.city.findFirst.mockResolvedValue({ id: 'city-1', defaultCurrency: 'SYP' });
    prisma.vendor.findFirst.mockResolvedValue({ id: 'v-1', isOpen: true });
    prisma.deliveryZone.findUnique.mockResolvedValue({ feeBase: 5000, feePerKm: 1500 });
    prisma.$queryRaw.mockResolvedValue([{ distanceKm: 2.3 }]);
    prisma.product.findMany.mockResolvedValue([
      { id: 'p-1', basePrice: 12000, currency: 'SYP', stockQty: 10 },
    ]);

    const estimate = await service.estimate('cust-1', {
      cityId: 'city-1',
      addressId: 'addr-1',
      vendorId: 'v-1',
      items: [{ productId: 'p-1', quantity: 2 }],
    });

    expect(estimate).toEqual({
      currency: 'SYP',
      subtotal: 24000,
      deliveryFee: 9500, // 5000 + ceil(2.3)*1500
      total: 33500,
      distanceKm: 2.3,
      vendorOpen: true,
    });
  });
});
