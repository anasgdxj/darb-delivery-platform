import {
  Controller,
  Headers,
  Post,
  ServiceUnavailableException,
  UnauthorizedException,
  Body,
  Logger,
} from '@nestjs/common';
import { timingSafeEqual } from 'node:crypto';
import { TelegramAdminService, TelegramUpdate } from './telegram-admin.service';

@Controller('internal/telegram')
export class TelegramAdminController {
  private readonly logger = new Logger(TelegramAdminController.name);

  constructor(private readonly telegram: TelegramAdminService) {}

  @Post('webhook')
  async webhook(
    @Headers('x-telegram-bot-api-secret-token') suppliedSecret: string | undefined,
    @Body() update: TelegramUpdate,
  ): Promise<{ ok: true }> {
    const expected = this.telegram.webhookSecret;
    if (expected.length < 32) {
      this.logger.error('Telegram webhook request rejected because webhook configuration is unavailable.');
      throw new ServiceUnavailableException('Telegram webhook is not configured.');
    }

    const supplied = suppliedSecret ?? '';
    const expectedBuffer = Buffer.from(expected);
    const suppliedBuffer = Buffer.from(supplied);
    if (
      suppliedBuffer.length !== expectedBuffer.length ||
      !timingSafeEqual(suppliedBuffer, expectedBuffer)
    ) {
      this.logger.warn(JSON.stringify({
        event: 'telegram_webhook_rejected',
        reason: 'invalid_secret_header',
        updateId: update?.update_id ?? null,
      }));
      throw new UnauthorizedException();
    }

    const message = update?.message ?? update?.edited_message;
    this.logger.log(JSON.stringify({
      event: 'telegram_webhook_received',
      updateId: update?.update_id ?? null,
      hasMessage: Boolean(message),
      chatType: message?.chat?.type ?? null,
      hasText: typeof message?.text === 'string',
    }));

    void this.telegram.handleUpdate(update).catch((error) => {
      this.logger.error(
        'Telegram update processing failed after webhook acknowledgement.',
        error instanceof Error ? error.stack : undefined,
      );
    });
    return { ok: true };
  }
}
