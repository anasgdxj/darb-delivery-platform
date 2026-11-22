import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { VendorApplicationDto } from './vendor-application.dto';
import { VendorsService } from './vendors.service';
@Controller('vendors/apply') @UseGuards(JwtAuthGuard, RolesGuard) @Roles(UserRole.CUSTOMER)
export class VendorApplicationController {
  constructor(private readonly vendors: VendorsService) {}
  @Post() apply(@CurrentUser() user:{id:string}, @Body() dto:VendorApplicationDto) { return this.vendors.apply(user.id,dto); }
}
