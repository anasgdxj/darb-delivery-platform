import { Body, Controller, Patch, UseGuards } from '@nestjs/common';
import { Type } from 'class-transformer';
import { IsLatitude, IsLongitude } from 'class-validator';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { DriverLocationService } from './driver-location.service';
class DriverLocationDto { @Type(() => Number) @IsLatitude() latitude!: number; @Type(() => Number) @IsLongitude() longitude!: number; }
@Controller('drivers') @UseGuards(JwtAuthGuard, RolesGuard) @Roles(UserRole.DRIVER)
export class DriverLocationController {
  constructor(private readonly locations: DriverLocationService) {}
  @Patch('location') update(@CurrentUser() user: { id: string }, @Body() dto: DriverLocationDto) { return this.locations.update(user.id, dto.latitude, dto.longitude); }
}
