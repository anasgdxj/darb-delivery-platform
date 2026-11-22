import { BadRequestException, NotFoundException } from '@nestjs/common';
import { AddressesService } from './addresses.service';

describe('AddressesService', () => {
  const prisma: any = {
    address: { findMany: jest.fn(), findFirst: jest.fn(), delete: jest.fn(), update: jest.fn(), findUnique: jest.fn() },
    $queryRaw: jest.fn(),
    $transaction: jest.fn(),
  };
  let service: AddressesService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new AddressesService(prisma);
  });

  it('returns saved coordinates with each address for map editing', async () => {
    prisma.address.findMany.mockResolvedValue([
      { id: 'addr-1', label: 'المنزل', details: 'حي الشهباء' },
    ]);
    prisma.$queryRaw.mockResolvedValue([
      { id: 'addr-1', hasLocation: true, latitude: 36.2021, longitude: 37.1343 },
    ]);

    await expect(service.list('u-1')).resolves.toEqual([
      {
        id: 'addr-1',
        label: 'المنزل',
        details: 'حي الشهباء',
        hasLocation: true,
        latitude: 36.2021,
        longitude: 37.1343,
      },
    ]);
  });

  it('rejects partial coordinates on update', async () => {
    await expect(service.update('u-1', 'addr-1', { latitude: 33.5 })).rejects.toBeInstanceOf(BadRequestException);
  });

  it('prevents removing another user address', async () => {
    prisma.address.findFirst.mockResolvedValue(null);
    await expect(service.remove('u-1', 'addr-other')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('prevents removing an address tied to historical orders', async () => {
    prisma.address.findFirst.mockResolvedValue({ id: 'addr-1', _count: { orders: 2 } });
    await expect(service.remove('u-1', 'addr-1')).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.address.delete).not.toHaveBeenCalled();
  });

  it('deletes an unused customer address safely', async () => {
    prisma.address.findFirst.mockResolvedValue({ id: 'addr-2', _count: { orders: 0 } });
    prisma.address.delete.mockResolvedValue({ id: 'addr-2' });
    const res = await service.remove('u-1', 'addr-2');
    expect(res).toEqual({ id: 'addr-2', deleted: true });
  });
});
