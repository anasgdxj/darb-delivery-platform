import { BadRequestException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AdminService } from './admin.service';

describe('AdminService', () => {
  const prisma: any = {
    user: { count: jest.fn(), findUnique: jest.fn(), update: jest.fn() },
    vendor: { count: jest.fn() },
    driver: { count: jest.fn() },
    city: { count: jest.fn(), findUnique: jest.fn(), create: jest.fn() },
    order: { count: jest.fn(), aggregate: jest.fn() },
    auditLog: { create: jest.fn().mockResolvedValue({}) },
    platformSetting: { findMany: jest.fn(), upsert: jest.fn() },
    $transaction: jest.fn(),
  };
  let service: AdminService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new AdminService(prisma);
  });

  it('prevents an admin from stripping their own admin role', async () => {
    await expect(service.setUserRole('admin-1', 'admin-1', UserRole.CUSTOMER)).rejects.toBeInstanceOf(BadRequestException);
  });

  it('aggregates platform KPI stats cleanly', async () => {
    prisma.user.count.mockResolvedValue(120);
    prisma.vendor.count.mockResolvedValueOnce(15).mockResolvedValueOnce(3);
    prisma.driver.count.mockResolvedValueOnce(28).mockResolvedValueOnce(4).mockResolvedValueOnce(11);
    prisma.city.count.mockResolvedValue(5);
    prisma.order.count
      .mockResolvedValueOnce(310)
      .mockResolvedValueOnce(12)
      .mockResolvedValueOnce(8)
      .mockResolvedValueOnce(270)
      .mockResolvedValueOnce(20);
    prisma.order.aggregate.mockResolvedValue({ _sum: { total: 4250000, deliveryFee: 450000 } });

    const stats = await service.stats();
    expect(stats.usersTotal).toBe(120);
    expect(stats.driversOnline).toBe(11);
    expect(stats.deliveredGrossTotal).toBe(4250000);
    expect(stats.deliveredDeliveryFees).toBe(450000);
  });

  it('validates lowercase city codes on city creation', async () => {
    await expect(service.createCity('admin-1', { code: 'Aleppo City!', nameAr: 'حلب' })).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });
});
