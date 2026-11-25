import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './modules/auth/auth.module';
import { CitiesModule } from './modules/cities/cities.module';
import { VendorsModule } from './modules/vendors/vendors.module';
import { CatalogModule } from './modules/catalog/catalog.module';
import { OrdersModule } from './modules/orders/orders.module';
import { AiOrderAssistantModule } from './modules/ai-order-assistant/ai-order-assistant.module';
import { AiRoleAssistantModule } from './modules/ai-role-assistant/ai-role-assistant.module';
import { DriversModule } from './modules/drivers/drivers.module';
import { AddressesModule } from './modules/addresses/addresses.module';
import { AdminModule } from './modules/admin/admin.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { HealthModule } from './modules/health/health.module';
import { MapsModule } from './modules/maps/maps.module';
import { PrismaModule } from './prisma/prisma.module';
import { RedisModule } from './redis/redis.module';
import { TelegramAdminModule } from './modules/telegram-admin/telegram-admin.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    RedisModule,
    MapsModule,
    HealthModule,
    AuthModule,
    CitiesModule,
    VendorsModule,
    CatalogModule,
    OrdersModule,
    AiOrderAssistantModule,
    AiRoleAssistantModule,
    DriversModule,
    AddressesModule,
    AdminModule,
    NotificationsModule,
    TelegramAdminModule,
  ],
})
export class AppModule {}
