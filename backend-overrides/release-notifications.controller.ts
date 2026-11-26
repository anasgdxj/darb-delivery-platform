import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  Post,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IsInt, IsOptional, IsString, IsUrl, MaxLength, Min } from 'class-validator';
import { timingSafeEqual } from 'node:crypto';
import { NotificationsService } from './notifications.service';

class ReleaseAnnouncementDto {
  @IsString() @MaxLength(80) releaseTag!: string;
  @IsInt() @Min(1) versionCode!: number;
  @IsString() @MaxLength(40) versionName!: string;
  @IsUrl({ protocols: ['https'], require_protocol: true }) @MaxLength(2048) apkUrl!: string;
  @IsOptional() @IsString() @MaxLength(1000) releaseNotes?: string;
}

@Controller('internal/release-notifications')
export class ReleaseNotificationsController {
  constructor(
    private readonly notifications: NotificationsService,
    private readonly config: ConfigService,
  ) {}

  @Get('readiness')
  readiness(@Headers('authorization') authorization: string | undefined) {
    this.assertAuthorized(authorization);
    if (!this.notifications.isMessagingConfigured()) {
      throw new ServiceUnavailableException('Firebase Cloud Messaging is not configured.');
    }
    return { ready: true };
  }

  @Post('publish')
  async publish(
    @Headers('authorization') authorization: string | undefined,
    @Body() body: ReleaseAnnouncementDto,
  ) {
    this.assertAuthorized(authorization);

    const officialApkUrl = 'https://github.com/anasgdxj/darb-delivery-platform/releases/download/latest/app-release.apk';
    if (body.apkUrl !== officialApkUrl) {
      throw new BadRequestException('APK URL must point to the official DAZREVO latest release asset.');
    }

    return this.notifications.broadcastRelease(body);
  }

  private assertAuthorized(authorization: string | undefined): void {
    const expected = this.config.get<string>('DARB_RELEASE_WEBHOOK_TOKEN') ?? '';
    const tokenPattern = /^[A-Za-z0-9_-]{32,128}$/;
    if (!tokenPattern.test(expected)) {
      throw new ServiceUnavailableException('Release notification webhook is not configured with a valid single-line token.');
    }

    const supplied = authorization?.startsWith('Bearer ')
      ? authorization.slice('Bearer '.length)
      : '';
    if (!tokenPattern.test(supplied)) {
      throw new UnauthorizedException();
    }

    const expectedBuffer = Buffer.from(expected);
    const suppliedBuffer = Buffer.from(supplied);
    if (
      suppliedBuffer.length !== expectedBuffer.length ||
      !timingSafeEqual(suppliedBuffer, expectedBuffer)
    ) {
      throw new UnauthorizedException();
    }
  }
}
