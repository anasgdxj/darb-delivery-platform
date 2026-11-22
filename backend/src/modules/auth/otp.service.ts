import { HttpException, HttpStatus, Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, randomInt } from 'crypto';
import type Redis from 'ioredis';
import { REDIS } from '../../redis/redis.module';
import { SMS_PROVIDER, SmsProvider } from './sms/sms.provider';
export const OTP_TTL_SECONDS = 300;
const MAX_ATTEMPTS = 5, MAX_SENDS_PER_HOUR = 5, SEND_WINDOW_SECONDS = 3600;
@Injectable()
export class OtpService {
  private readonly secret: string;
  constructor(@Inject(REDIS) private readonly redis: Redis, @Inject(SMS_PROVIDER) private readonly sms: SmsProvider, config: ConfigService) { this.secret = config.getOrThrow<string>('OTP_SECRET'); }
  async issue(phone: string): Promise<void> {
    const sends = Number(await this.redis.eval("local n=redis.call('INCR',KEYS[1]); if n==1 then redis.call('EXPIRE',KEYS[1],ARGV[1]); end; return n", 1, `otp:sends:${phone}`, SEND_WINDOW_SECONDS));
    if (sends > MAX_SENDS_PER_HOUR) throw new HttpException('تم تجاوز عدد طلبات الرمز، حاول لاحقاً', HttpStatus.TOO_MANY_REQUESTS);
    const code = randomInt(0, 1_000_000).toString().padStart(6, '0');
    await this.redis.multi().set(this.codeKey(phone), this.hash(phone, code), 'EX', OTP_TTL_SECONDS).del(this.attemptsKey(phone)).exec();
    try {
      await this.sms.send(phone, `رمز التحقق الخاص بك: ${code}`);
    } catch (error) {
      // Failed delivery must not consume the hourly quota or leave a usable OTP behind.
      await this.redis.eval("redis.call('DEL',KEYS[1]); if redis.call('EXISTS',KEYS[2]) == 1 then local n=redis.call('DECR',KEYS[2]); if n<=0 then redis.call('DEL',KEYS[2]); end; end; return 1", 2, this.codeKey(phone), `otp:sends:${phone}`);
      throw error;
    }
  }
  async verify(phone: string, code: string): Promise<void> {
    if (!/^\d{6}$/.test(code)) throw new UnauthorizedException('الرمز غير صحيح');
    const result = Number(await this.redis.eval("local saved=redis.call('GET',KEYS[1]); if not saved then return -1 end; local n=redis.call('INCR',KEYS[2]); if n==1 then redis.call('EXPIRE',KEYS[2],ARGV[2]); end; if n>tonumber(ARGV[3]) then redis.call('DEL',KEYS[1],KEYS[2]); return -2 end; if saved==ARGV[1] then redis.call('DEL',KEYS[1],KEYS[2]); return 1 end; return 0", 2, this.codeKey(phone), this.attemptsKey(phone), this.hash(phone, code), OTP_TTL_SECONDS, MAX_ATTEMPTS));
    if (result === 1) return;
    if (result === -2) throw new HttpException('تم تجاوز عدد المحاولات، اطلب رمزاً جديداً', HttpStatus.TOO_MANY_REQUESTS);
    if (result === -1) throw new UnauthorizedException('الرمز منتهي الصلاحية أو غير موجود');
    throw new UnauthorizedException('الرمز غير صحيح');
  }
  private hash(phone: string, code: string) { return createHmac('sha256', this.secret).update(`${phone}:${code}`).digest('hex'); }
  private codeKey(phone: string) { return `otp:code:${phone}`; }
  private attemptsKey(phone: string) { return `otp:attempts:${phone}`; }
}
