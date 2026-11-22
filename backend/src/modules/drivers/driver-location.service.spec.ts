import { DriverLocationService } from './driver-location.service';
describe('DriverLocationService', () => {
  const prisma: any = { driver: { findUnique: jest.fn() }, $executeRaw: jest.fn() };
  const service = new DriverLocationService(prisma);
  beforeEach(() => jest.clearAllMocks());
  it('rejects location updates from unapproved or offline drivers', async () => {
    prisma.driver.findUnique.mockResolvedValue({ id: 'd1', status: 'PENDING', isOnline: false });
    await expect(service.update('u1', 33.5, 36.3)).rejects.toThrow('اعتماد السائق');
    expect(prisma.$executeRaw).not.toHaveBeenCalled();
  });
  it('stores the latest point for an approved online driver', async () => {
    prisma.driver.findUnique.mockResolvedValue({ id: 'd1', status: 'APPROVED', isOnline: true });
    prisma.$executeRaw.mockResolvedValue(1);
    await expect(service.update('u1', 33.5, 36.3)).resolves.toEqual({ success: true });
    expect(prisma.$executeRaw).toHaveBeenCalledTimes(1);
  });
});
