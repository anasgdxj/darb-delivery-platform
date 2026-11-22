import { Module } from '@nestjs/common';
import { VendorsController } from './vendors.controller';
import { VendorsService } from './vendors.service';
import { VendorApplicationController } from './vendor-application.controller';
@Module({ controllers: [VendorsController, VendorApplicationController], providers: [VendorsService], exports: [VendorsService] })
export class VendorsModule {}
