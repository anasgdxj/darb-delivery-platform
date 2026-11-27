import { UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';

describe('AuthService refresh-token rotation', () => {
  const user = { id: 'user-1', phone: '+963912345678', name: 'Test', role: 'CUSTOMER', locale: 'ar' };
  const prisma = { user: { findUnique: jest.fn() } };
  const otp = {};
  const jwt = { verifyAsync: jest.fn(), signAsync: jest.fn() };
  const config = { getOrThrow: jest.fn((key: string) => key) };
  const redis = { eval: jest.fn(), set: jest.fn() };
  let service: AuthService;

  beforeEach(() => {
    jest.clearAllMocks();
    jwt.signAsync.mockReset().mockResolvedValueOnce('new-access').mockResolvedValueOnce('new-refresh');
    service = new AuthService(prisma as any, otp as any, jwt as any, config as any, redis as any);
    prisma.user.findUnique.mockResolvedValue(user);
    jwt.verifyAsync.mockResolvedValue({ sub: user.id, type: 'refresh', jti: 'old-jti' });
  });

  it('rotates a refresh token exactly once', async () => {
    redis.eval.mockResolvedValue(1);
    await expect(service.refresh('old-refresh')).resolves.toEqual({ accessToken: 'new-access', refreshToken: 'new-refresh' });
    expect(redis.eval).toHaveBeenCalledTimes(1);
    expect(redis.eval.mock.calls[0][1]).toBe(2);
  });
  it('rejects a replayed or revoked refresh token', async () => {
    redis.eval.mockResolvedValue(0);
    await expect(service.refresh('old-refresh')).rejects.toBeInstanceOf(UnauthorizedException);
  });
  it('rejects legacy refresh tokens without a token identifier', async () => {
    jwt.verifyAsync.mockResolvedValue({ sub: user.id, type: 'refresh' });
    await expect(service.refresh('legacy-refresh')).rejects.toBeInstanceOf(UnauthorizedException);
  });
  it('revokes a refresh token on logout', async () => {
    redis.eval.mockResolvedValue(1);
    await expect(service.logout('old-refresh')).resolves.toEqual({ loggedOut: true });
    expect(redis.eval).toHaveBeenCalledTimes(1);
  });
});