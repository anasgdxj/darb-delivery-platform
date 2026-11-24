import {
  Body,
  Controller,
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

  @Post('publish')
  async publish(
    @Headers('authorization') authorization: string | undefined,
    @Body() body: ReleaseAnnouncementDto,
  ) {
    const expected = this.config.get<string>('DARB_RELEASE_WEBHOOK_TOKEN') ?? '';
    if (expected.length < 32) {
      throw new ServiceUnavailableException('Release notification webhook is not configured.');
    }

    const supplied = authorization?.startsWith('Bearer ')
      ? authorization.slice('Bearer '.length)
      : '';
    const expectedBuffer = Buffer.from(expected);
    const suppliedBuffer = Buffer.from(supplied);
    if (
      suppliedBuffer.length !== expectedBuffer.length ||
      !timingSafeEqual(suppliedBuffer, expectedBuffer)
    ) {
      throw new UnauthorizedException();
    }

    return this.notifications.broadcastRelease(body);
  }
}
