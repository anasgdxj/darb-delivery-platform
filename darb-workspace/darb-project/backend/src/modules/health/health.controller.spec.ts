import { ServiceUnavailableException } from '@nestjs/common';
import { HealthController } from './health.controller';

describe('HealthController', () => {
  const prisma = {
    $queryRaw: jest.fn(),
  };
  const redis = {
    ping: jest.fn(),
  };
  let controller: HealthController;

  beforeEach(() => {
    jest.clearAllMocks();
    controller = new HealthController(prisma as any, redis as any);
  });

  it('returns a successful liveness response without probing dependencies', () => {
    expect(controller.liveness()).toEqual({ status: 'ok' });
    expect(prisma.$queryRaw).not.toHaveBeenCalled();
    expect(redis.ping).not.toHaveBeenCalled();
  });

  it('reports ready when the database schema and Redis are available', async () => {
    prisma.$queryRaw.mockResolvedValue([{ users_table: 'User' }]);
    redis.ping.mockResolvedValue('PONG');

    await expect(controller.readiness()).resolves.toEqual({
      status: 'ok',
      checks: { database: 'ok', redis: 'ok' },
    });
  });

  it('returns HTTP 503 when the database schema is missing', async () => {
    prisma.$queryRaw.mockResolvedValue([{ users_table: null }]);
    redis.ping.mockResolvedValue('PONG');

    await expect(controller.readiness()).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it('returns HTTP 503 when Redis is unavailable', async () => {
    prisma.$queryRaw.mockResolvedValue([{ users_table: 'User' }]);
    redis.ping.mockRejectedValue(new Error('Redis unavailable'));

    await expect(controller.readiness()).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });
});
