import { Module } from '@nestjs/common';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrderTrackingController } from './orders.tracking.controller';
import { OrderTrackingService } from './orders.tracking.service';
@Module({controllers:[OrdersController,OrderTrackingController],providers:[OrdersService,OrderTrackingService]})
export class OrdersModule {}
