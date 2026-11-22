import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { CatalogService } from './catalog.service';

describe('CatalogService', () => {
  const prisma: any = {
    vendor: { findUnique: jest.fn(), findFirst: jest.fn() },
    product: { findMany: jest.fn(), findFirst: jest.fn(), create: jest.fn(), update: jest.fn(), delete: jest.fn() },
    $transaction: jest.fn(),
  };
  let service: CatalogService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new CatalogService(prisma);
  });

  it('prevents unapproved vendors from updating products', async () => {
    prisma.vendor.findUnique.mockResolvedValue({ id: 'v-1', status: 'PENDING' });
    await expect(service.update('user-1', 'prod-1', { price: 1500 })).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('enforces product ownership before deletion and archives products already referenced by orders', async () => {
    prisma.vendor.findUnique.mockResolvedValue({ id: 'v-1' });
    prisma.product.findFirst.mockResolvedValue({ id: 'prod-1', _count: { orderItems: 3 } });
    prisma.product.update.mockResolvedValue({ id: 'prod-1', isAvailable: false });

    const res = await service.remove('user-1', 'prod-1');
    expect(res).toEqual({ id: 'prod-1', archived: true, deleted: false });
    expect(prisma.product.delete).not.toHaveBeenCalled();
  });

  it('hard-deletes products with zero historical order items', async () => {
    prisma.vendor.findUnique.mockResolvedValue({ id: 'v-1' });
    prisma.product.findFirst.mockResolvedValue({ id: 'prod-2', _count: { orderItems: 0 } });
    prisma.product.delete.mockResolvedValue({ id: 'prod-2' });

    const res = await service.remove('user-1', 'prod-2');
    expect(res).toEqual({ id: 'prod-2', archived: false, deleted: true });
    expect(prisma.product.delete).toHaveBeenCalledWith({ where: { id: 'prod-2' } });
  });

  it('throws NotFoundException when editing another vendor product', async () => {
    prisma.vendor.findUnique.mockResolvedValue({ id: 'v-1', status: 'APPROVED' });
    prisma.product.findFirst.mockResolvedValue(null);
    await expect(service.update('user-1', 'other-prod', { price: 500 })).rejects.toBeInstanceOf(NotFoundException);
  });
});
