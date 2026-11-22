import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AiRoleAssistantService } from './ai-role-assistant.service';

class AskAssistantDto {
  @IsString() @MinLength(2) @MaxLength(1200) message!: string;
}

@Controller('ai/assistant')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.CUSTOMER, UserRole.DRIVER, UserRole.VENDOR, UserRole.ADMIN)
export class AiRoleAssistantController {
  constructor(private readonly assistant: AiRoleAssistantService) {}

  @Post('ask')
  ask(@CurrentUser() user: { id: string; role: UserRole }, @Body() dto: AskAssistantDto) {
    return this.assistant.ask(user, dto.message);
  }
}
