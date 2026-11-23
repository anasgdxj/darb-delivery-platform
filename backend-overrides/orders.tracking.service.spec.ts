import { OrderTrackingService } from './orders.tracking.service';

describe('OrderTrackingService', () => {
  const prisma: any = { order: { findFirst: jest.fn() }, $queryRaw: jest.fn() };
  const service = new OrderTrackingService(prisma);

  beforeEach(() => jest.clearAllMocks());

  it('does not reveal a driver location to a user who does not own the order', async () => {
    prisma.order.findFirst.mockResolvedValue(null);
    await expect(service.driverLocation('intruder', 'order-1')).rejects.toThrow('الطلب غير موجود');
    expect(prisma.$queryRaw).not.toHaveBeenCalled();
  });

  it('returns unavailable before assignment or outside the active delivery statuses', async () => {
    prisma.order.findFirst.mockResolvedValue({ driverId: null, status: 'READY' });
    await expect(service.driverLocation('customer-1', 'order-1')).resolves.toEqual({ available: false });
    expect(prisma.$queryRaw).not.toHaveBeenCalled();
  });

  it('returns unavailable when the latest driver location is stale', async () => {
    prisma.order.findFirst.mockResolvedValue({ driverId: 'driver-1', status: 'PICKED_UP' });
    prisma.$queryRaw.mockResolvedValue([{
      latitude: 33.5,
      longitude: 36.3,
      updatedAt: new Date(Date.now() - 3 * 60 * 1000),
    }]);

    await expect(service.driverLocation('customer-1', 'order-1')).resolves.toEqual({
      available: false,
      reason: 'STALE',
    });
  });

  it('returns only a fresh latest location for the owning customer during delivery', async () => {
    const point = { latitude: 33.5, longitude: 36.3, updatedAt: new Date() };
    prisma.order.findFirst.mockResolvedValue({ driverId: 'driver-1', status: 'PICKED_UP' });
    prisma.$queryRaw.mockResolvedValue([point]);

    await expect(service.driverLocation('customer-1', 'order-1')).resolves.toEqual({
      available: true,
      ...point,
    });
    const locationQuery = prisma.$queryRaw.mock.calls[0][0].join(' ');
    expect(locationQuery).toContain('ORDER BY "updatedAt" DESC');
    expect(locationQuery).toContain('LIMIT 1');
  });
});
