import { NotificationsService } from './notifications.service';
describe('NotificationsService', () => {
  const prisma: any = { userDevice: { upsert: jest.fn().mockResolvedValue({ id: 'device-1' }), deleteMany: jest.fn().mockResolvedValue({ count: 1 }), findMany: jest.fn().mockResolvedValue([]) }, vendor: { findUnique: jest.fn() }, driver: { findMany: jest.fn().mockResolvedValue([]), findUnique: jest.fn() } };
  const config: any = { get: jest.fn().mockReturnValue(undefined) };
  let service: NotificationsService;
  beforeEach(() => { jest.clearAllMocks(); service = new NotificationsService(prisma, config); });
  it('registers an FCM token for the authenticated user', async () => {
    await expect(service.register('user-1', 'fcm-token-long-enough', 'android')).resolves.toEqual({ id: 'device-1' });
    expect(prisma.userDevice.upsert).toHaveBeenCalled();
  });
  it('allows users to unregister only their own token', async () => {
    await expect(service.unregister('user-1', 'fcm-token-long-enough')).resolves.toEqual({ success: true });
    expect(prisma.userDevice.deleteMany).toHaveBeenCalledWith({ where: { userId: 'user-1', token: 'fcm-token-long-enough' } });
  });
  it('does not fail peer delivery when driver lookup for push notifications fails', async () => {
    prisma.driver.findMany.mockRejectedValueOnce(new Error('database unavailable'));
    await expect(service.notifyDriversInCity('city-1', 'New delivery', 'Available', { type: 'PEER_DELIVERY_AVAILABLE' }))
      .resolves.toEqual({ targetedDrivers: 0, failed: 0, skipped: true });
  });
  it('notifies the driver assigned to a peer-delivery order', async () => {
    prisma.driver.findUnique.mockResolvedValue({ userId: 'driver-user-1' });
    await expect(service.notifyDriver('driver-1', 'تم اختيار عرضك', 'تم إسناد الطلب إليك', {
      type: 'DELIVERY_OFFER_SELECTED', orderId: 'order-1',
    })).resolves.toBeUndefined();
    expect(prisma.driver.findUnique).toHaveBeenCalledWith({
      where: { id: 'driver-1' }, select: { userId: true },
    });
  });
  it('keeps order selection successful when assigned-driver lookup fails', async () => {
    prisma.driver.findUnique.mockRejectedValueOnce(new Error('database unavailable'));
    await expect(service.notifyDriver('driver-1', 'Order assigned', 'Selected', {
      type: 'DELIVERY_OFFER_SELECTED', orderId: 'order-1',
    })).resolves.toBeUndefined();
  });
  it('keeps customer order updates successful when device lookup fails', async () => {
    (service as any).messaging = { sendEachForMulticast: jest.fn() };
    prisma.userDevice.findMany.mockRejectedValueOnce(new Error('database unavailable'));
    await expect(service.notifyCustomer('user-1', 'Order', 'Updated', { type: 'ORDER_STATUS' })).resolves.toBeUndefined();
  });
  it('keeps vendor order creation successful when vendor notification lookup fails', async () => {
    prisma.vendor.findUnique.mockRejectedValueOnce(new Error('database unavailable'));
    await expect(service.notifyVendor('vendor-1', 'Order', 'New', { type: 'ORDER_CREATED' })).resolves.toBeUndefined();
  });
  it('keeps order workflows independent when Firebase credentials are absent', async () => {
    await expect(service.notifyCustomer('user-1', 'Order', 'Updated', { type: 'ORDER_STATUS' })).resolves.toBeUndefined();
    expect(prisma.userDevice.findMany).not.toHaveBeenCalled();
  });
});
