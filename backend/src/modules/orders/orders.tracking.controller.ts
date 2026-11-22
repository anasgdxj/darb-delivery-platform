import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { OrderTrackingService } from './orders.tracking.service';
@Controller('orders') @UseGuards(JwtAuthGuard, RolesGuard) @Roles(UserRole.CUSTOMER)
export class OrderTrackingController {
  constructor(private readonly tracking: OrderTrackingService) {}
  @Get(':id/driver-location') location(@CurrentUser() user: { id: string }, @Param('id') id: string) { return this.tracking.driverLocation(user.id, id); }
}
