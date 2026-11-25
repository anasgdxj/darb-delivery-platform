import { Module } from '@nestjs/common';
import { TelegramAdminController } from './telegram-admin.controller';
import { TelegramAdminService } from './telegram-admin.service';

@Module({
  controllers: [TelegramAdminController],
  providers: [TelegramAdminService],
})
export class TelegramAdminModule {}
