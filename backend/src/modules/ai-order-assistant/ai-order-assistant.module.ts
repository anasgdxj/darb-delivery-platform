import { Module } from '@nestjs/common';
import { AiOrderAssistantController } from './ai-order-assistant.controller';
import { AiOrderAssistantService } from './ai-order-assistant.service';

@Module({ controllers: [AiOrderAssistantController], providers: [AiOrderAssistantService] })
export class AiOrderAssistantModule {}
