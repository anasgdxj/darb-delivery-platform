import { Body, Controller, Get, Param, Post, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { IsOptional, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AiOrderAssistantService } from './ai-order-assistant.service';

class DraftInputDto {
  @IsUUID() cityId!: string;
  @IsOptional() @IsUUID() vendorId?: string;
  @IsOptional() @IsString() @MaxLength(80) idempotencyKey?: string;
}
class TextDraftDto extends DraftInputDto {
  @IsString() @MinLength(5) @MaxLength(3000) text!: string;
}

@Controller('ai/order-assistant')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.CUSTOMER)
export class AiOrderAssistantController {
  constructor(private readonly assistant: AiOrderAssistantService) {}

  @Post('drafts/text')
  createText(@CurrentUser() user: { id: string }, @Body() dto: TextDraftDto) {
    return this.assistant.createTextDraft(user.id, dto);
  }

  @Post('drafts/voice')
  @UseInterceptors(FileInterceptor('audio', { limits: { fileSize: 8 * 1024 * 1024 } }))
  createVoice(
    @CurrentUser() user: { id: string },
    @Body() dto: DraftInputDto,
    @UploadedFile() file?: { buffer: Buffer; mimetype: string; size: number },
  ) {
    return this.assistant.createVoiceDraft(user.id, dto, file);
  }

  @Get('drafts/:id')
  getDraft(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.assistant.getDraft(user.id, id);
  }
}
