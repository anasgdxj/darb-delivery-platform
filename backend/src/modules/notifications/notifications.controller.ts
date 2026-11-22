import { Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post, UseGuards } from '@nestjs/common';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { NotificationsService } from './notifications.service';

class DeviceTokenDto {
  @IsString() @MinLength(20) @MaxLength(4096) token!: string;
  @IsOptional() @IsIn(['android', 'ios', 'web']) platform?: string;
}

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  listMine(@CurrentUser() user: { id: string }) {
    return this.notifications.listMine(user.id);
  }

  @Patch('read-all')
  markAllRead(@CurrentUser() user: { id: string }) {
    return this.notifications.markAllRead(user.id);
  }

  @Patch(':id/read')
  markRead(@CurrentUser() user: { id: string }, @Param('id', new ParseUUIDPipe()) id: string) {
    return this.notifications.markRead(user.id, id);
  }

  @Post('device')
  register(@CurrentUser() user: { id: string }, @Body() dto: DeviceTokenDto) {
    return this.notifications.register(user.id, dto.token, dto.platform);
  }

  @Delete('device')
  unregister(@CurrentUser() user: { id: string }, @Body() dto: DeviceTokenDto) {
    return this.notifications.unregister(user.id, dto.token);
  }
}
