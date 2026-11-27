import { BadRequestException, Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { User } from '@prisma/client';
import { createHash, randomUUID } from 'crypto';
import type Redis from 'ioredis';
import { normalizeSyrianPhone } from '../../common/validators/syrian-phone';
import { PrismaService } from '../../prisma/prisma.service';
import { REDIS } from '../../redis/redis.module';
import { OtpService, OTP_TTL_SECONDS } from './otp.service';
import { VerifyOtpDto } from './dto/verify-otp.dto';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

const REFRESH_TTL_SECONDS = 30 * 24 * 60 * 60;

const ROTATE_REFRESH_SCRIPT = `
local current = redis.call('GET', KEYS[1])
if not current or current ~= ARGV[1] then return 0 end
redis.call('DEL', KEYS[1])
redis.call('SET', KEYS[2], ARGV[2], 'EX', tonumber(ARGV[3]))
return 1
`;

const REVOKE_REFRESH_SCRIPT = `
local current = redis.call('GET', KEYS[1])
if not current or current ~= ARGV[1] then return 0 end
return redis.call('DEL', KEYS[1])
`;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otp: OtpService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    @Inject(REDIS) private readonly redis: Redis,
  ) {}

  async requestOtp(rawPhone: string) {
    const phone = this.requireSyrianPhone(rawPhone);
    await this.otp.issue(phone);
    return { sent: true, expiresInSeconds: OTP_TTL_SECONDS };
  }

  async verifyOtp(dto: VerifyOtpDto) {
    const phone = this.requireSyrianPhone(dto.phone);
    await this.otp.verify(phone, dto.code);
    const user = await this.prisma.user.upsert({
      where: { phone },
      create: { phone, name: dto.name, locale: dto.locale ?? 'ar' },
      update: dto.name ? { name: dto.name } : {},
    });
    return { user: this.publicUser(user), tokens: await this.issueTokens(user) };
  }

  async refresh(refreshToken: string): Promise<TokenPair> {
    const payload = await this.verifyRefreshToken(refreshToken);
    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user) throw new UnauthorizedException();

    const pair = await this.createTokenPair(user);
    const consumed = await this.redis.eval(
      ROTATE_REFRESH_SCRIPT,
      2,
      this.refreshKey(payload.jti),
      this.refreshKey(pair.refreshJti),
      this.tokenHash(refreshToken),
      this.tokenHash(pair.refreshToken),
      REFRESH_TTL_SECONDS,
    );
    if (Number(consumed) !== 1) {
      throw new UnauthorizedException('Refresh token already used or revoked');
    }
    return { accessToken: pair.accessToken, refreshToken: pair.refreshToken };
  }

  async logout(refreshToken: string) {
    const payload = await this.verifyRefreshToken(refreshToken);
    await this.redis.eval(
      REVOKE_REFRESH_SCRIPT,
      1,
      this.refreshKey(payload.jti),
      this.tokenHash(refreshToken),
    );
    return { loggedOut: true };
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new UnauthorizedException();
    return this.publicUser(user);
  }

  private async issueTokens(user: User): Promise<TokenPair> {
    const pair = await this.createTokenPair(user);
    await this.redis.set(this.refreshKey(pair.refreshJti), this.tokenHash(pair.refreshToken), 'EX', REFRESH_TTL_SECONDS);
    return { accessToken: pair.accessToken, refreshToken: pair.refreshToken };
  }

  private async createTokenPair(user: User) {
    const accessToken = await this.jwt.signAsync(
      { sub: user.id, role: user.role, type: 'access' },
      { secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'), expiresIn: '15m' },
    );
    const refreshJti = randomUUID();
    const refreshToken = await this.jwt.signAsync(
      { sub: user.id, type: 'refresh', jti: refreshJti },
      { secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'), expiresIn: '30d' },
    );
    return { accessToken, refreshToken, refreshJti };
  }

  private async verifyRefreshToken(token: string): Promise<{ sub: string; jti: string }> {
    try {
      const payload = await this.jwt.verifyAsync<{ sub: string; type?: string; jti?: string }>(token, {
        secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
      });
      if (payload.type !== 'refresh' || !payload.sub || !payload.jti) {
        throw new UnauthorizedException('Refresh token غير صالح');
      }
      return { sub: payload.sub, jti: payload.jti };
    } catch {
      throw new UnauthorizedException('Refresh token غير صالح أو منتهي الصلاحية');
    }
  }

  private refreshKey(jti: string) {
    return `auth:refresh:${jti}`;
  }

  private tokenHash(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }

  private requireSyrianPhone(raw: string): string {
    const phone = normalizeSyrianPhone(raw);
    if (!phone) throw new BadRequestException('رقم الهاتف غير صالح. يجب أن يكون رقماً سورياً مثل +9639XXXXXXXX');
    return phone;
  }

  private publicUser(user: User) {
    return { id: user.id, phone: user.phone, name: user.name, role: user.role, locale: user.locale };
  }
}