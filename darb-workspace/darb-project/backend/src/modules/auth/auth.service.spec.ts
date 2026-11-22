import { AuthService } from './auth.service';
describe('AuthService refresh token rotation', () => {
  const user: any = { id: 'user-1', phone: '+963994000000', email: null, name: 'Test', role: 'CUSTOMER', locale: 'ar' };
  const prisma: any = { user: { findUnique: jest.fn().mockResolvedValue(user) } };
  const otp: any = {};
  const jwt: any = { verifyAsync: jest.fn().mockResolvedValue({ sub: 'user-1', type: 'refresh', jti: 'token-id' }), signAsync: jest.fn().mockResolvedValue('signed-token') };
  const config: any = { getOrThrow: jest.fn().mockReturnValue('test-secret') };
  const redis: any = { eval: jest.fn().mockResolvedValue(1), set: jest.fn().mockResolvedValue('OK') };
  let service: AuthService;
  beforeEach(() => { jest.clearAllMocks(); service = new AuthService(prisma, otp, jwt, config, redis); });
  it('rotates a refresh token and issues a new pair', async () => {
    const pair = await service.refresh('old-refresh-token');
    expect(redis.eval).toHaveBeenCalledTimes(1);
    expect(redis.set).toHaveBeenCalledWith(expect.stringMatching(/^auth:refresh:/), 'user-1', 'EX', 2592000);
    expect(pair).toEqual({ accessToken: 'signed-token', refreshToken: 'signed-token' });
  });
  it('rejects a refresh token that was already consumed', async () => {
    redis.eval.mockResolvedValue(0);
    await expect(service.refresh('replayed-refresh-token')).rejects.toThrow('already used or revoked');
    expect(redis.set).not.toHaveBeenCalled();
  });
});
