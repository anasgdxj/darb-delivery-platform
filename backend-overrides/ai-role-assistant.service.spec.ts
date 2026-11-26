import { UserRole } from '@prisma/client';
import { AiRoleAssistantService } from './ai-role-assistant.service';
import { AiTextProvider } from './ai-text-provider';

describe('AiRoleAssistantService role isolation', () => {
  const prisma: any = {
    driver: { findUnique: jest.fn(), count: jest.fn() },
    vendor: { findUnique: jest.fn(), count: jest.fn() },
    order: { count: jest.fn(), aggregate: jest.fn() },
    product: { count: jest.fn() },
    city: { count: jest.fn(), findMany: jest.fn() },
  };
  const aiProvider = { generate: jest.fn().mockResolvedValue('إجابة آمنة') } as unknown as AiTextProvider;
  let service: AiRoleAssistantService;

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.order.count.mockResolvedValue(0);
    prisma.driver.count.mockResolvedValue(0);
    prisma.vendor.count.mockResolvedValue(0);
    prisma.city.count.mockResolvedValue(0);
    prisma.order.aggregate.mockResolvedValue({ _sum: { total: null, deliveryFee: null } });
    prisma.city.findMany.mockResolvedValue([]);
    service = new AiRoleAssistantService(prisma, aiProvider);
  });

  it('builds driver context only from the authenticated driver profile and city', async () => {
    prisma.driver.findUnique.mockResolvedValue({ id: 'driver-1', cityId: 'city-1', status: 'APPROVED', isOnline: true, vehicleType: 'MOTORCYCLE' });
    prisma.order.count.mockResolvedValue(2);
    const context = await (service as any).buildContext({ id: 'user-1', role: UserRole.DRIVER });
    expect(prisma.driver.findUnique).toHaveBeenCalledWith(expect.objectContaining({ where: { userId: 'user-1' } }));
    expect(context).toEqual(expect.objectContaining({ activeOrders: 2, availableStoreOrders: 2, availablePeerDeliveries: 2 }));
    expect(prisma.vendor.findUnique).not.toHaveBeenCalled();
  });

  it('limits vendor context to the vendor owned by the authenticated user', async () => {
    prisma.vendor.findUnique.mockResolvedValue({ id: 'vendor-1', status: 'APPROVED', ratingAvg: 4.5 });
    prisma.order.count.mockResolvedValue(1);
    prisma.product.count.mockResolvedValue(3);
    const context = await (service as any).buildContext({ id: 'user-vendor', role: UserRole.VENDOR });
    expect(prisma.vendor.findUnique).toHaveBeenCalledWith(expect.objectContaining({ where: { userId: 'user-vendor' } }));
    expect(context).toEqual(expect.objectContaining({ pendingOrders: 1, availableProducts: 3 }));
    expect(prisma.driver.findUnique).not.toHaveBeenCalled();
  });

  it('provides administrators with daily aggregate operations and city coverage without customer records', async () => {
    prisma.driver.count.mockResolvedValue(3);
    prisma.vendor.count.mockResolvedValue(2);
    prisma.order.count.mockResolvedValue(4);
    prisma.city.count.mockResolvedValue(1);
    prisma.order.aggregate.mockResolvedValue({ _sum: { total: { toString: () => '125000' }, deliveryFee: { toString: () => '15000' } } });
    prisma.city.findMany.mockResolvedValue([{
      code: 'aleppo',
      names: [{ locale: 'ar', name: 'حلب' }],
      _count: { orders: 21, drivers: 8, vendors: 5 },
    }]);

    const context = await (service as any).buildContext({ id: 'admin-1', role: UserRole.ADMIN });

    expect(context).toEqual(expect.objectContaining({
      scope: 'AGGREGATED_ADMIN_OPERATIONS_ONLY',
      businessTimezone: 'UTC+03:00',
      pendingDrivers: 3,
      pendingVendors: 2,
      pendingOrders: 4,
      activeOrders: 4,
      activeCities: 1,
      onlineDrivers: 3,
      ordersToday: 4,
      deliveredToday: 4,
      delayedOrders: 4,
      deliveredGrossToday: 125000,
      deliveredFeesToday: 15000,
      cities: [{ code: 'aleppo', name: 'حلب', ordersTotal: 21, driversTotal: 8, vendorsTotal: 5 }],
    }));
    expect(prisma.order.findMany).toBeUndefined();
    expect(prisma.user).toBeUndefined();
  });

  it('sends the role-scoped context and question to the configured provider', async () => {
    prisma.order.count.mockResolvedValue(3);
    const result = await service.ask({ id: 'customer-1', role: UserRole.CUSTOMER }, 'كم طلباً لدي؟');
    expect(aiProvider.generate).toHaveBeenCalledWith(expect.objectContaining({
      context: { activeOrders: 3, deliveredOrders: 3 },
      message: 'كم طلباً لدي؟',
    }));
    expect(result).toEqual(expect.objectContaining({
      role: UserRole.CUSTOMER,
      answer: 'إجابة آمنة',
      mode: 'READ_ONLY_ASSISTANT',
    }));
    expect(result.contextUpdatedAt).toEqual(expect.any(String));
  });

  it('instructs the admin assistant to prioritize insights and never claim execution', async () => {
    await service.ask({ id: 'admin-1', role: UserRole.ADMIN }, 'ما أهم مشكلة الآن؟');
    const request = (aiProvider.generate as jest.Mock).mock.calls[0][0];
    expect(request.systemPrompt).toContain('شريك تشغيل وتحليل');
    expect(request.systemPrompt).toContain('لا تملك أدوات تعديل');
    expect(request.systemPrompt).toContain('UTC+03:00');
  });
});
