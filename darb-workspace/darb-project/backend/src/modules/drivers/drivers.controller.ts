import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { DriverApplicationDto } from './driver-application.dto';
import { DriversService } from './drivers.service';
@Controller('drivers/apply') @UseGuards(JwtAuthGuard, RolesGuard) @Roles(UserRole.CUSTOMER)
export class DriversController {
  constructor(private readonly drivers: DriversService) {}
  @Post() apply(@CurrentUser() user:{id:string}, @Body() dto:DriverApplicationDto) { return this.drivers.apply(user.id,dto); }
}
