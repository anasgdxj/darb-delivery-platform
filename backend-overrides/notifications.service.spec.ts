import { NotFoundException } from '@nestjs/common';
import { NotificationsService } from './notifications.service';

describe('NotificationsService', () => {
  const prisma: any = {
    userDevice: {
      upsert: jest.fn().mockResolvedValue({ id: 'device-1' }),
      deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      findMany: jest.fn().mockResolvedValue([]),
    },
    userNotification: {
      createMany: jest.fn().mockResolvedValue({ count: 0 }),
      create: jest.fn().mockResolvedValue({ id: 'notif-1' }),
      findMany: jest.fn().mockResolvedValue([{ id: 'notif-1', title: 'Order', body: 'Updated', type: 'ORDER_STATUS', readAt: null }]),
      count: jest.fn().mockResolvedValue(1),
      findFirst: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn().mockResolvedValue({ count: 1 }),
    },
    vendor: { findUnique: jest.fn() },
    driver: { findMany: jest.fn().mockResolvedValue([]), findUnique: jest.fn() },
  };
  const config: any = { get: jest.fn().mockReturnValue(undefined) };
  let service: NotificationsService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new NotificationsService(prisma, config);
  });

  it('reports whether Firebase Admin messaging is configured', () => {
    expect(service.isMessagingConfigured()).toBe(false);
    (service as any).messaging = { sendEachForMulticast: jest.fn() };
    expect(service.isMessagingConfigured()).toBe(true);
  });

  it('registers an FCM token for the authenticated user', async () => {
    await expect(service.register('user-1', 'fcm-token-long-enough', 'android')).resolves.toEqual({ id: 'device-1' });
    expect(prisma.userDevice.upsert).toHaveBeenCalled();
  });

  it('allows users to unregister only their own token', async () => {
    await expect(service.unregister('user-1', 'fcm-token-long-enough')).resolves.toEqual({ success: true });
    expect(prisma.userDevice.deleteMany).toHaveBeenCalledWith({ where: { userId: 'user-1', token: 'fcm-token-long-enough' } });
  });

  it('persists an in-app notification even when Firebase credentials are absent', async () => {
    await expect(service.notifyCustomer('user-1', 'Order', 'Updated', { type: 'ORDER_STATUS', orderId: 'o-1' })).resolves.toBeUndefined();
    expect(prisma.userNotification.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        userId: 'user-1',
        title: 'Order',
        body: 'Updated',
        type: 'ORDER_STATUS',
      }),
    });
    expect(prisma.userDevice.findMany).not.toHaveBeenCalled();
  });

  it('lists inbox items and marks notifications read for the owning user', async () => {
    const inbox = await service.listMine('user-1');
    expect(inbox.unreadCount).toBe(1);
    expect(inbox.items).toHaveLength(1);

    prisma.userNotification.findFirst.mockResolvedValueOnce(null);
    await expect(service.markRead('user-1', 'missing')).rejects.toBeInstanceOf(NotFoundException);

    prisma.userNotification.findFirst.mockResolvedValueOnce({ id: 'notif-1', readAt: null });
    prisma.userNotification.update.mockResolvedValueOnce({ id: 'notif-1', readAt: new Date() });
    const marked = await service.markRead('user-1', 'notif-1');
    expect(marked.id).toBe('notif-1');

    const all = await service.markAllRead('user-1');
    expect(all).toEqual({ updated: 1 });
  });

  it('does not fail peer delivery when driver lookup for push notifications fails', async () => {
    prisma.driver.findMany.mockRejectedValueOnce(new Error('database unavailable'));
    await expect(
      service.notifyDriversInCity('city-1', 'New delivery', 'Available', { type: 'PEER_DELIVERY_AVAILABLE' }),
    ).resolves.toEqual({ targetedDrivers: 0, failed: 0, skipped: true });
  });

  it('notifies the driver assigned to a peer-delivery order', async () => {
    prisma.driver.findUnique.mockResolvedValue({ userId: 'driver-user-1' });
    await expect(
      service.notifyDriver('driver-1', 'تم اختيار عرضك', 'تم إسناد الطلب إليك', {
        type: 'DELIVERY_OFFER_SELECTED',
        orderId: 'order-1',
      }),
    ).resolves.toBeUndefined();
    expect(prisma.driver.findUnique).toHaveBeenCalledWith({
      where: { id: 'driver-1' },
      select: { userId: true },
    });
  });

  it('keeps order selection successful when assigned-driver lookup fails', async () => {
    prisma.driver.findUnique.mockRejectedValueOnce(new Error('database unavailable'));
    await expect(
      service.notifyDriver('driver-1', 'Order assigned', 'Selected', {
        type: 'DELIVERY_OFFER_SELECTED',
        orderId: 'order-1',
      }),
    ).resolves.toBeUndefined();
  });

  it('sends large device audiences in Firebase multicast batches of at most 500', async () => {
    const tokens = Array.from({ length: 501 }, (_, index) => `token-${index}`);
    prisma.userDevice.findMany.mockResolvedValueOnce(tokens.map((token) => ({ token })));
    const sendEachForMulticast = jest.fn()
      .mockResolvedValueOnce({
        responses: Array.from({ length: 500 }, () => ({ success: true })),
      })
      .mockResolvedValueOnce({
        responses: [{ success: false, error: { code: 'messaging/invalid-registration-token' } }],
      });
    (service as any).messaging = { sendEachForMulticast };

    await service.notifyCustomer('user-1', 'Order', 'Updated', { type: 'ORDER_STATUS' });

    expect(sendEachForMulticast).toHaveBeenCalledTimes(2);
    expect(sendEachForMulticast.mock.calls[0][0].tokens).toHaveLength(500);
    expect(sendEachForMulticast.mock.calls[1][0].tokens).toEqual(['token-500']);
    expect(prisma.userDevice.deleteMany).toHaveBeenCalledWith({
      where: { token: { in: ['token-500'] } },
    });
  });

  it('keeps customer order updates successful when device lookup fails', async () => {
    (service as any).messaging = { sendEachForMulticast: jest.fn() };
    prisma.userDevice.findMany.mockRejectedValueOnce(new Error('database unavailable'));
    await expect(service.notifyCustomer('user-1', 'Order', 'Updated', { type: 'ORDER_STATUS' })).resolves.toBeUndefined();
  });


  it('stores and broadcasts a published release to every registered device', async () => {
    prisma.userDevice.findMany.mockResolvedValueOnce([
      { userId: 'user-1', token: 'token-1' },
      { userId: 'user-1', token: 'token-2' },
      { userId: 'user-2', token: 'token-3' },
    ]);

    const result = await service.broadcastRelease({
      releaseTag: 'latest',
      versionCode: 1400,
      versionName: '1.0.1400',
      apkUrl: 'https://github.com/anasgdxj/darb-delivery-platform/releases/download/latest/app-release.apk',
      releaseNotes: 'تحسينات وإصلاحات',
    });

    expect(prisma.userNotification.createMany).toHaveBeenCalledWith({
      data: expect.arrayContaining([
        expect.objectContaining({ userId: 'user-1', type: 'APP_UPDATE' }),
        expect.objectContaining({ userId: 'user-2', type: 'APP_UPDATE' }),
      ]),
    });
    expect(result).toEqual({
      targetedUsers: 2,
      targetedDevices: 3,
      pushSent: 0,
      pushFailed: 0,
      pushSkipped: true,
    });
  });

  it('sends release announcements to devices in FCM-safe batches', async () => {
    prisma.userDevice.findMany.mockResolvedValueOnce(
      Array.from({ length: 501 }, (_, index) => ({ userId: `user-${index}`, token: `token-${index}` })),
    );
    const sendEachForMulticast = jest.fn()
      .mockResolvedValueOnce({ successCount: 500, failureCount: 0, responses: Array.from({ length: 500 }, () => ({ success: true })) })
      .mockResolvedValueOnce({ successCount: 1, failureCount: 0, responses: [{ success: true }] });
    (service as any).messaging = { sendEachForMulticast };

    const result = await service.broadcastRelease({
      releaseTag: 'latest',
      versionCode: 1401,
      versionName: '1.0.1401',
      apkUrl: 'https://github.com/anasgdxj/darb-delivery-platform/releases/download/latest/app-release.apk',
    });

    expect(sendEachForMulticast).toHaveBeenCalledTimes(2);
    expect(sendEachForMulticast.mock.calls[0][0].tokens).toHaveLength(500);
    expect(sendEachForMulticast.mock.calls[1][0].tokens).toHaveLength(1);
    expect(result.pushSent).toBe(501);
  });

  it('prunes invalid release tokens and reports other FCM delivery failures', async () => {
    prisma.userDevice.findMany.mockResolvedValueOnce([
      { userId: 'user-1', token: 'token-valid' },
      { userId: 'user-2', token: 'token-invalid' },
      { userId: 'user-3', token: 'token-temporary-failure' },
    ]);
    const sendEachForMulticast = jest.fn().mockResolvedValueOnce({
      successCount: 1,
      failureCount: 2,
      responses: [
        { success: true },
        { success: false, error: { code: 'messaging/registration-token-not-registered' } },
        { success: false, error: { code: 'messaging/internal-error' } },
      ],
    });
    (service as any).messaging = { sendEachForMulticast };

    const result = await service.broadcastRelease({
      releaseTag: 'latest',
      versionCode: 1402,
      versionName: '1.0.1402',
      apkUrl: 'https://github.com/anasgdxj/darb-delivery-platform/releases/download/latest/app-release.apk',
    });

    expect(result.pushSent).toBe(1);
    expect(result.pushFailed).toBe(1);
    expect(prisma.userDevice.deleteMany).toHaveBeenCalledWith({
      where: { token: { in: ['token-invalid'] } },
    });
  });

  it('keeps vendor order creation successful when vendor notification lookup fails', async () => {
    prisma.vendor.findUnique.mockRejectedValueOnce(new Error('database unavailable'));
    await expect(service.notifyVendor('vendor-1', 'Order', 'New', { type: 'ORDER_CREATED' })).resolves.toBeUndefined();
  });
});
