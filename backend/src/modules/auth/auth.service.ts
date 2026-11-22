import { BadRequestException, ConflictException, Injectable, Inject, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Locale, User, UserRole } from '@prisma/client';
import { OAuth2Client } from 'google-auth-library';
import { randomUUID } from 'crypto';
import type Redis from 'ioredis';
import { normalizeSyrianPhone } from '../../common/validators/syrian-phone';
import { PrismaService } from '../../prisma/prisma.service';
import { REDIS } from '../../redis/redis.module';
import { OtpService, OTP_TTL_SECONDS } from './otp.service';
import { VerifyOtpDto } from './dto/verify-otp.dto';
export interface TokenPair { accessToken: string; refreshToken: string; }
const REFRESH_TTL_SECONDS = 30 * 24 * 60 * 60;
@Injectable()
export class AuthService {
  private readonly google = new OAuth2Client();
  constructor(private readonly prisma: PrismaService, private readonly otp: OtpService, private readonly jwt: JwtService, private readonly config: ConfigService, @Inject(REDIS) private readonly redis: Redis) {}
  async requestOtp(rawPhone: string) { const phone = this.requireSyrianPhone(rawPhone); await this.otp.issue(phone); return { sent: true, expiresInSeconds: OTP_TTL_SECONDS }; }
  async verifyOtp(dto: VerifyOtpDto) {
    const phone = this.requireSyrianPhone(dto.phone); await this.otp.verify(phone, dto.code);
    const user = await this.prisma.user.upsert({ where: { phone }, create: { phone, name: dto.name, locale: (dto.locale as Locale) ?? Locale.ar }, update: dto.name ? { name: dto.name } : {} });
    return { user: this.publicUser(user), tokens: await this.issueTokens(user) };
  }
  async googleSignIn(idToken: string, locale?: string) {
    const clientId = this.config.get<string>('GOOGLE_SERVER_CLIENT_ID');
    if (!clientId) throw new ServiceUnavailableException('Google sign-in is not configured');
    let payload;
    try { payload = (await this.google.verifyIdToken({ idToken, audience: clientId })).getPayload(); }
    catch { throw new UnauthorizedException('Invalid Google ID token'); }
    if (!payload?.sub || !payload.email || payload.email_verified !== true) {
      throw new UnauthorizedException('Google account email is not verified');
    }
    const email = payload.email.trim().toLowerCase();
    const adminEmails = (this.config.get<string>('ADMIN_EMAILS') ?? '')
      .split(',').map(value => value.trim().toLowerCase()).filter(Boolean);
    const isConfiguredAdmin = adminEmails.includes(email);
    let user = await this.prisma.user.findUnique({ where: { googleId: payload.sub } });
    if (!user) {
      const existingEmail = await this.prisma.user.findUnique({ where: { email } });
      if (existingEmail) throw new ConflictException('This email is already linked to another sign-in method');
      user = await this.prisma.user.create({ data: {
        googleId: payload.sub, email, phone: null,
        name: payload.name?.slice(0, 120) ?? null,
        locale: (['ar','en','tr'].includes(locale ?? '') ? locale : 'ar') as Locale,
        role: isConfiguredAdmin ? UserRole.ADMIN : UserRole.CUSTOMER,
      } });
    } else {
      user = await this.prisma.user.update({ where: { id: user.id }, data: {
        email,
        ...(user.name ? {} : { name: payload.name?.slice(0, 120) ?? null }),
        ...(isConfiguredAdmin ? { role: UserRole.ADMIN } : user.role === UserRole.ADMIN ? { role: UserRole.CUSTOMER } : {}),
      } });
    }
    return { user: this.publicUser(user), tokens: await this.issueTokens(user) };
  }
  async refresh(refreshToken: string): Promise<TokenPair> {
    let payload: { sub: string; type?: string; jti?: string };
    try { payload = await this.jwt.verifyAsync(refreshToken, { secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET') }); }
    catch { throw new UnauthorizedException('Refresh token غير صالح'); }
    if (payload.type !== 'refresh' || !payload.jti) throw new UnauthorizedException('Refresh token غير صالح');
    const rotated = await this.redis.eval("if redis.call('GET',KEYS[1]) == ARGV[1] then redis.call('DEL',KEYS[1]); return 1 else return 0 end", 1, `auth:refresh:${payload.jti}`, payload.sub);
    if (Number(rotated) !== 1) throw new UnauthorizedException('Refresh token was already used or revoked');
    const user = await this.prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user) throw new UnauthorizedException();
    return this.issueTokens(user);
  }
  async logout(refreshToken?: string) {
    if (refreshToken) try {
      const payload = await this.jwt.verifyAsync<{ jti?: string; sub?: string }>(refreshToken, { secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'), ignoreExpiration: true });
      if (payload.jti && payload.sub) await this.redis.eval("if redis.call('GET',KEYS[1]) == ARGV[1] then return redis.call('DEL',KEYS[1]) else return 0 end", 1, `auth:refresh:${payload.jti}`, payload.sub);
    } catch { /* idempotent logout */ }
    return { success: true };
  }
  async me(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, include: { vendor: { select: { status: true } }, driver: { select: { status: true } } } });
    if (!user) throw new UnauthorizedException();
    return { ...this.publicUser(user), vendorApplication: user.vendor?.status ?? null, driverApplication: user.driver?.status ?? null };
  }
  async updateProfile(userId: string, dto: { name?: string; locale?: Locale }) {
    if (dto.name !== undefined && !dto.name.trim()) throw new BadRequestException('الاسم لا يمكن أن يكون فارغاً');
    const user = await this.prisma.user.update({ where: { id: userId }, data: { ...(dto.name !== undefined ? { name: dto.name.trim().slice(0,120) } : {}), ...(dto.locale ? { locale: dto.locale } : {}) } });
    return this.publicUser(user);
  }
  private async issueTokens(user: User): Promise<TokenPair> {
    const jti = randomUUID();
    const accessToken = await this.jwt.signAsync({ sub: user.id, role: user.role, type: 'access' }, { secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'), expiresIn: '15m' });
    const refreshToken = await this.jwt.signAsync({ sub: user.id, type: 'refresh', jti }, { secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'), expiresIn: '30d' });
    await this.redis.set(`auth:refresh:${jti}`, user.id, 'EX', REFRESH_TTL_SECONDS);
    return { accessToken, refreshToken };
  }
  private requireSyrianPhone(raw: string): string {
    const phone = normalizeSyrianPhone(raw);
    if (!phone) throw new BadRequestException('رقم الهاتف غير صالح. يجب أن يكون رقماً سورياً مثل +9639XXXXXXXX');
    return phone;
  }
  private publicUser(user: User) { return { id: user.id, phone: user.phone, email: user.email, name: user.name, role: user.role, locale: user.locale }; }
}
