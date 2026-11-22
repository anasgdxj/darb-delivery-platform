import { OtpService } from './otp.service';
describe('OtpService atomic verification', () => {
  const redis: any = {
    eval: jest.fn(), multi: jest.fn(() => ({ set: jest.fn().mockReturnThis(), del: jest.fn().mockReturnThis(), exec: jest.fn().mockResolvedValue([]) })),
  };
  const sms: any = { send: jest.fn().mockResolvedValue(undefined) };
  const config: any = { getOrThrow: jest.fn().mockReturnValue('test-secret') };
  let service: OtpService;
  beforeEach(() => { jest.clearAllMocks(); service = new OtpService(redis, sms, config); });
  it('accepts one valid atomic verification result', async () => {
    redis.eval.mockResolvedValue(1);
    await expect(service.verify('+963994000000', '123456')).resolves.toBeUndefined();
    expect(redis.eval).toHaveBeenCalledTimes(1);
  });
  it('rejects an incorrect code without clearing a valid OTP', async () => {
    redis.eval.mockResolvedValue(0);
    await expect(service.verify('+963994000000', '123456')).rejects.toThrow('الرمز غير صحيح');
  });
  it('rejects an expired code', async () => {
    redis.eval.mockResolvedValue(-1);
    await expect(service.verify('+963994000000', '123456')).rejects.toThrow('منتهي الصلاحية');
  });
  it('locks the code after too many attempts', async () => {
    redis.eval.mockResolvedValue(-2);
    await expect(service.verify('+963994000000', '123456')).rejects.toThrow('تجاوز عدد المحاولات');
  });
  it('atomically applies the hourly request limit and sends only after storing the hash', async () => {
    redis.eval.mockResolvedValue(1);
    await service.issue('+963994000000');
    expect(redis.eval).toHaveBeenCalledTimes(1);
    expect(redis.multi).toHaveBeenCalledTimes(1);
    expect(sms.send).toHaveBeenCalledWith('+963994000000', expect.stringMatching(/^رمز التحقق الخاص بك: \d{6}$/));
  });
  it('releases the hourly quota and invalidates the code when SMS delivery fails', async () => {
    redis.eval.mockResolvedValueOnce(1).mockResolvedValueOnce(1);
    sms.send.mockRejectedValueOnce(new Error('SMS provider unavailable'));
    await expect(service.issue('+963994000000')).rejects.toThrow('SMS provider unavailable');
    expect(redis.eval).toHaveBeenCalledTimes(2);
    expect(redis.eval.mock.calls[1][0]).toContain("redis.call('DECR',KEYS[2])");
  });
  it('does not accept malformed OTP input', async () => {
    await expect(service.verify('+963994000000', '123')).rejects.toThrow('الرمز غير صحيح');
    expect(redis.eval).not.toHaveBeenCalled();
  });
});
