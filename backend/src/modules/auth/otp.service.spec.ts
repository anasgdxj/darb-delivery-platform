import { HttpException, UnauthorizedException } from '@nestjs/common';
import { OtpService } from './otp.service';

describe('OtpService atomic verification', () => {
  const redis = { eval: jest.fn() };
  const sms = { send: jest.fn() };
  const config = { getOrThrow: jest.fn().mockReturnValue('test-secret') };
  let service: OtpService;
  beforeEach(() => {
    jest.clearAllMocks();
    service = new OtpService(redis as any, sms as any, config as any);
  });
  it('accepts a valid OTP through one atomic Redis operation', async () => {
    redis.eval.mockResolvedValue(1);
    await expect(service.verify('+963912345678', '123456')).resolves.toBeUndefined();
    expect(redis.eval).toHaveBeenCalledTimes(1);
    expect(redis.eval.mock.calls[0][1]).toBe(2);
  });
  it('rejects an invalid code', async () => {
    redis.eval.mockResolvedValue(0);
    await expect(service.verify('+963912345678', '123456')).rejects.toBeInstanceOf(UnauthorizedException);
  });
  it('rejects an expired or missing code', async () => {
    redis.eval.mockResolvedValue(-1);
    await expect(service.verify('+963912345678', '123456')).rejects.toBeInstanceOf(UnauthorizedException);
  });
  it('locks the OTP after the maximum number of attempts', async () => {
    redis.eval.mockResolvedValue(-2);
    try { await service.verify('+963912345678', '123456'); } catch (error) {
      expect(error).toBeInstanceOf(HttpException);
      expect((error as HttpException).getStatus()).toBe(429);
    }
  });
});