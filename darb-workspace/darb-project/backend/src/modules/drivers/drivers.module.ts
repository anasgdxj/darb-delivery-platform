import { Module } from '@nestjs/common';
import { DriversController } from './drivers.controller';
import { DriversService } from './drivers.service';
import { DriverStatusController } from './driver-status.controller';
import { DriverLocationController } from './driver-location.controller';
import { DriverLocationService } from './driver-location.service';
@Module({controllers:[DriversController,DriverStatusController,DriverLocationController],providers:[DriversService,DriverLocationService]})
export class DriversModule {}
