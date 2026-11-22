import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AiRoleAssistantController } from './ai-role-assistant.controller';
import { AiRoleAssistantService } from './ai-role-assistant.service';
import { AiTextProvider } from './ai-text-provider';
import { GeminiAiTextProvider } from './gemini-ai-text-provider';

@Module({
  imports: [ConfigModule],
  controllers: [AiRoleAssistantController],
  providers: [
    AiRoleAssistantService,
    { provide: AiTextProvider, useClass: GeminiAiTextProvider },
  ],
})
export class AiRoleAssistantModule {}
