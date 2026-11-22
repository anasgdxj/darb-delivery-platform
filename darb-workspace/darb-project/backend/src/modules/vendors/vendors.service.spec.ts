import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { VendorsService } from './vendors.service';

describe('VendorsService stats and reviews', () => {
  const prisma: any = {
    vendor: { findUnique: jest.fn(), findFirst: jest.fn() },
    order: { count: jest.fn(), aggregate: jest.fn() },
    review: { findMany: jest.fn(), count: jest.fn() },
  };
  let service: VendorsService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new VendorsService(prisma);
  });

  it('returns vendor store revenue and order breakdown stats', async () => {
    prisma.vendor.findUnique.mockResolvedValue({
      id: 'vendor-1',
      isOpen: true,
      ratingAvg: 4.75,
      cities: [{ city: { defaultCurrency: 'SYP' } }],
    });
    prisma.order.count
      .mockResolvedValueOnce(20)
      .mockResolvedValueOnce(3)
      .mockResolvedValueOnce(5)
      .mockResolvedValueOnce(4);
    prisma.order.aggregate
      .mockResolvedValueOnce({ _count: { id: 14 }, _sum: { subtotal: 420000 } })
      .mockResolvedValueOnce({ _sum: { subtotal: 95000 } });

    const stats = await service.stats('vendor-user-1');
    expect(stats).toEqual({
      vendorId: 'vendor-1',
      isOpen: true,
      ratingAvg: 4.75,
      totalOrders: 20,
      pendingOrders: 3,
      activeOrders: 5,
      deliveredOrders: 14,
      totalRevenue: 420000,
      todayOrders: 4,
      todayRevenue: 95000,
      currency: 'SYP',
    });
  });

  it('rejects vendor stats for accounts without a vendor record', async () => {
    prisma.vendor.findUnique.mockResolvedValue(null);
    await expect(service.stats('user-x')).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('returns public reviews for an approved vendor', async () => {
    prisma.vendor.findFirst.mockResolvedValue({ id: 'vendor-1', ratingAvg: 4.6 });
    prisma.review.findMany.mockResolvedValue([{ id: 'r-1', rating: 5, comment: 'سريع ومرتب' }]);
    prisma.review.count.mockResolvedValue(1);

    const res = await service.reviews('vendor-1');
    expect(res.total).toBe(1);
    expect(res.ratingAvg).toBe(4.6);
    expect(res.items).toHaveLength(1);
  });

  it('throws NotFoundException when fetching reviews for a missing or unapproved vendor', async () => {
    prisma.vendor.findFirst.mockResolvedValue(null);
    await expect(service.reviews('missing')).rejects.toBeInstanceOf(NotFoundException);
  });
});
