import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { DriverStatus, OrderStatus, OrderType, UserRole, VendorStatus } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsBoolean, IsEnum, IsInt, IsNumber, IsOptional, IsString, IsUUID, Max, MaxLength, Min } from 'class-validator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { AdminService } from './admin.service';

class VendorStatusDto {
  @IsEnum(VendorStatus) status!: VendorStatus;
}

class DriverStatusDto {
  @IsEnum(DriverStatus) status!: DriverStatus;
}

class UserRoleDto {
  @IsEnum(UserRole) role!: UserRole;
}

class AdminOrdersQueryDto {
  @IsOptional() @IsEnum(OrderStatus) status?: OrderStatus;
  @IsOptional() @IsEnum(OrderType) type?: OrderType;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page = 1;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(50) limit = 20;
}

class AdminUsersQueryDto {
  @IsOptional() @IsEnum(UserRole) role?: UserRole;
  @IsOptional() @IsString() @MaxLength(80) q?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page = 1;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(50) limit = 25;
}

class CreateDeliveryZoneDto {
  @IsUUID() cityId!: string;
  @IsString() @MaxLength(80) name!: string;
  @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) feeBase!: number;
  @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) feePerKm!: number;
}

class UpdateDeliveryZoneDto {
  @IsOptional() @IsString() @MaxLength(80) name?: string;
  @IsOptional() @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) feeBase?: number;
  @IsOptional() @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) feePerKm?: number;
}

class CreateCityDto {
  @IsString() @MaxLength(24) code!: string;
  @IsString() @MaxLength(80) nameAr!: string;
  @IsOptional() @IsString() @MaxLength(80) nameEn?: string;
  @IsOptional() @IsString() @MaxLength(80) nameTr?: string;
  @IsOptional() @IsString() @MaxLength(3) defaultCurrency?: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
}

class UpdateCityDto {
  @IsOptional() @IsBoolean() isActive?: boolean;
  @IsOptional() @IsString() @MaxLength(3) defaultCurrency?: string;
  @IsOptional() @IsString() @MaxLength(80) nameAr?: string;
  @IsOptional() @IsString() @MaxLength(80) nameEn?: string;
  @IsOptional() @IsString() @MaxLength(80) nameTr?: string;
}

class UpdateSettingsDto {
  @IsOptional() @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) @Max(50) commissionPercent?: number;
  @IsOptional() @IsString() @MaxLength(3) defaultCurrency?: string;
  @IsOptional() @IsBoolean() peerDeliveryEnabled?: boolean;
  @IsOptional() @IsBoolean() aiAssistantEnabled?: boolean;
  @IsOptional() @IsBoolean() maintenanceMode?: boolean;
  @IsOptional() @IsString() @MaxLength(160) supportContact?: string;
}

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  @Get('stats')
  stats() {
    return this.admin.stats();
  }

  @Get('orders')
  orders(@Query() query: AdminOrdersQueryDto) {
    return this.admin.orders(query);
  }

  @Get('users')
  users(@Query() query: AdminUsersQueryDto) {
    return this.admin.users(query);
  }

  @Patch('users/:id/role')
  setUserRole(@CurrentUser() actor: { id: string }, @Param('id') id: string, @Body() dto: UserRoleDto) {
    return this.admin.setUserRole(actor.id, id, dto.role);
  }

  @Get('delivery-zones')
  deliveryZones() {
    return this.admin.deliveryZones();
  }

  @Post('delivery-zones')
  createDeliveryZone(@CurrentUser() actor: { id: string }, @Body() dto: CreateDeliveryZoneDto) {
    return this.admin.createDeliveryZone(actor.id, dto);
  }

  @Patch('delivery-zones/:id')
  updateDeliveryZone(@CurrentUser() actor: { id: string }, @Param('id') id: string, @Body() dto: UpdateDeliveryZoneDto) {
    return this.admin.updateDeliveryZone(actor.id, id, dto);
  }

  @Delete('delivery-zones/:id')
  removeDeliveryZone(@CurrentUser() actor: { id: string }, @Param('id') id: string) {
    return this.admin.removeDeliveryZone(actor.id, id);
  }

  @Get('vendors/pending')
  pendingVendors() {
    return this.admin.pendingVendors();
  }

  @Get('vendors')
  allVendors(@Query('status') status?: VendorStatus) {
    return this.admin.allVendors(status);
  }

  @Patch('vendors/:id/status')
  setVendorStatus(@CurrentUser() actor: { id: string }, @Param('id') id: string, @Body() dto: VendorStatusDto) {
    return this.admin.setVendorStatus(actor.id, id, dto.status);
  }

  @Get('drivers/pending')
  pendingDrivers() {
    return this.admin.pendingDrivers();
  }

  @Get('drivers')
  allDrivers(@Query('status') status?: DriverStatus) {
    return this.admin.allDrivers(status);
  }

  @Patch('drivers/:id/status')
  setDriverStatus(@CurrentUser() actor: { id: string }, @Param('id') id: string, @Body() dto: DriverStatusDto) {
    return this.admin.setDriverStatus(actor.id, id, dto.status);
  }

  @Get('cities')
  cities() {
    return this.admin.cities();
  }

  @Post('cities')
  createCity(@CurrentUser() actor: { id: string }, @Body() dto: CreateCityDto) {
    return this.admin.createCity(actor.id, dto);
  }

  @Patch('cities/:id')
  updateCity(@CurrentUser() actor: { id: string }, @Param('id') id: string, @Body() dto: UpdateCityDto) {
    return this.admin.updateCity(actor.id, id, dto);
  }

  @Get('settings')
  getSettings() {
    return this.admin.getSettings();
  }

  @Patch('settings')
  updateSettings(@CurrentUser() actor: { id: string }, @Body() dto: UpdateSettingsDto) {
    return this.admin.updateSettings(actor.id, dto);
  }

  @Get('audit-logs')
  auditLogs(@Query('limit') limit?: string) {
    return this.admin.auditLogs(Number(limit) || 50);
  }
}
