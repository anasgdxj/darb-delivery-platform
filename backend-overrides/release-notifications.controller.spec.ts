import {
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ReleaseNotificationsController } from './release-notifications.controller';

describe('ReleaseNotificationsController', () => {
  const token = 'a'.repeat(64);
  const notifications: any = {
    isMessagingConfigured: jest.fn().mockReturnValue(false),
    broadcastRelease: jest.fn(),
  };
  const config: any = {
    get: jest.fn().mockReturnValue(token),
  };
  let controller: ReleaseNotificationsController;

  beforeEach(() => {
    jest.clearAllMocks();
    config.get.mockReturnValue(token);
    notifications.isMessagingConfigured.mockReturnValue(false);
    controller = new ReleaseNotificationsController(notifications, config);
  });

  it('rejects malformed configured tokens without inspecting or echoing their contents', () => {
    config.get.mockReturnValueOnce('invalid\nmultiline\nsecret');
    expect(() => controller.readiness(`Bearer ${token}`)).toThrow(ServiceUnavailableException);
  });

  it('rejects malformed bearer headers', () => {
    expect(() => controller.readiness('Bearer invalid\nheader')).toThrow(UnauthorizedException);
  });

  it('rejects readiness checks without the matching bearer token', () => {
    expect(() => controller.readiness(`Bearer ${'b'.repeat(64)}`)).toThrow(UnauthorizedException);
  });

  it('does not report ready when Firebase Admin is unavailable', () => {
    expect(() => controller.readiness(`Bearer ${token}`)).toThrow(ServiceUnavailableException);
    expect(notifications.isMessagingConfigured).toHaveBeenCalledTimes(1);
  });

  it('reports ready only when the token and Firebase Admin are valid', () => {
    notifications.isMessagingConfigured.mockReturnValue(true);
    expect(controller.readiness(`Bearer ${token}`)).toEqual({ ready: true });
  });
});
