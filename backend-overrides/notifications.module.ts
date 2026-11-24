import { Global, Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { ReleaseNotificationsController } from './release-notifications.controller';
import { NotificationsService } from './notifications.service';
@Global()
@Module({ controllers: [NotificationsController, ReleaseNotificationsController], providers: [NotificationsService], exports: [NotificationsService] })
export class NotificationsModule {}
