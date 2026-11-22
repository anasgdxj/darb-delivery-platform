import { BadRequestException } from '@nestjs/common';
import { DriversService, normalizeVehicleType } from './drivers.service';

describe('DriversService', () => {
  const prisma: any = {
    driver: { findUnique: jest.fn(), update: jest.fn() },
    order: { aggregate: jest.fn(), count: jest.fn() },
    deliveryOffer: { count: jest.fn() },
  };
  let service: DriversService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new DriversService(prisma);
  });

  it('normalizes Arabic, English, and Turkish vehicle names into canonical enums', () => {
    expect(normalizeVehicleType('دراجة هوائية')).toBe('BICYCLE');
    expect(normalizeVehicleType('bicycle')).toBe('BICYCLE');
    expect(normalizeVehicleType('دراجة نارية')).toBe('MOTORCYCLE');
    expect(normalizeVehicleType('motosiklet')).toBe('MOTORCYCLE');
    expect(normalizeVehicleType('سيارة')).toBe('CAR');
    expect(normalizeVehicleType('car')).toBe('CAR');
    expect(() => normalizeVehicleType('طائرة')).toThrow(BadRequestException);
  });

  it('computes driver trip and delivery fee earnings stats', async () => {
    prisma.driver.findUnique.mockResolvedValue({
      id: 'drv-1',
      status: 'APPROVED',
      isOnline: true,
      vehicleType: 'CAR',
      cityId: 'city-1',
    });
    prisma.order.aggregate.mockResolvedValue({ _count: { id: 14 }, _sum: { deliveryFee: 84000 } });
    prisma.order.count.mockResolvedValue(2);
    prisma.deliveryOffer.count.mockResolvedValue(1);

    const stats = await service.stats('user-1');
    expect(stats).toEqual({
      driverId: 'drv-1',
      vehicleType: 'CAR',
      isOnline: true,
      completedTrips: 14,
      activeTrips: 2,
      pendingOffers: 1,
      totalEarnings: 84000,
    });
  });
});
