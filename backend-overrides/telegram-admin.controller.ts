import {
  Controller,
  Headers,
  Post,
  ServiceUnavailableException,
  UnauthorizedException,
  Body,
} from '@nestjs/common';
import { timingSafeEqual } from 'node:crypto';
import { TelegramAdminService } from './telegram-admin.service';

interface TelegramUpdatePayload {
  update_id?: number;
  message?: unknown;
  edited_message?: unknown;
}

@Controller('internal/telegram')
export class TelegramAdminController {
  constructor(private readonly telegram: TelegramAdminService) {}

  @Post('webhook')
  async webhook(
    @Headers('x-telegram-bot-api-secret-token') suppliedSecret: string | undefined,
    @Body() update: TelegramUpdatePayload,
  ): Promise<{ ok: true }> {
    const expected = this.telegram.webhookSecret;
    if (expected.length < 32) {
      throw new ServiceUnavailableException('Telegram webhook is not configured.');
    }
    const supplied = suppliedSecret ?? '';
    const expectedBuffer = Buffer.from(expected);
    const suppliedBuffer = Buffer.from(supplied);
    if (
      suppliedBuffer.length !== expectedBuffer.length ||
      !timingSafeEqual(suppliedBuffer, expectedBuffer)
    ) {
      throw new UnauthorizedException();
    }

    await this.telegram.handleUpdate(update);
    return { ok: true };
  }
}
