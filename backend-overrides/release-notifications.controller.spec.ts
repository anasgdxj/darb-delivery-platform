import {
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ReleaseNotificationsController } from './release-notifications.controller';

describe('ReleaseNotificationsController', () => {
  const token = 'darb-release-webhook-test-token-0123456789abcdef';
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

  it('rejects readiness checks when the configured webhook token is too short', () => {
    config.get.mockReturnValueOnce('short');
    expect(() => controller.readiness(`Bearer ${token}`)).toThrow(ServiceUnavailableException);
  });

  it('rejects readiness checks without the matching bearer token', () => {
    expect(() => controller.readiness('Bearer wrong-token')).toThrow(UnauthorizedException);
  });

  it('does not report ready when Firebase Admin is unavailable', () => {
    expect(() => controller.readiness(`Bearer ${token}`)).toThrow(ServiceUnavailableException);
    expect(notifications.isMessagingConfigured).toHaveBeenCalledTimes(1);
  });

  it('reports ready only when the webhook token and Firebase Admin are valid', () => {
    notifications.isMessagingConfigured.mockReturnValue(true);
    expect(controller.readiness(`Bearer ${token}`)).toEqual({ ready: true });
  });
});
