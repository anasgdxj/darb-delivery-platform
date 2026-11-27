import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { DriverStatus, VendorStatus, UserRole, OrderStatus, OrderType } from '@prisma/client';
import { IsEnum, IsInt, IsNumber, IsOptional, IsString, IsUUID, Max, MaxLength, Min } from 'class-validator';
import { BadRequestException } from '@nestjs/common';
import { Type } from 'class-transformer';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { PrismaService } from '../../prisma/prisma.service';
class VendorStatusDto { @IsEnum(VendorStatus) status!: VendorStatus; }
class AdminOrdersQueryDto {
  @IsOptional() @IsEnum(OrderStatus) status?: OrderStatus;
  @IsOptional() @IsEnum(OrderType) type?: OrderType;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page = 1;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(50) limit = 20;
}

class DriverStatusDto { @IsEnum(DriverStatus) status!: DriverStatus; }

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

@Controller('admin') @UseGuards(JwtAuthGuard, RolesGuard) @Roles(UserRole.ADMIN)
export class AdminController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('orders') async orders(@Query() query: AdminOrdersQueryDto) {
    const where = {
      ...(query.status ? { status: query.status } : {}),
      ...(query.type ? { type: query.type } : {}),
    };
    const page = query.page || 1;
    const limit = query.limit || 20;
    const [items, total] = await this.prisma.$transaction([
      this.prisma.order.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
        include: {
          city: { select: { code: true, names: true } },
          customer: { select: { name: true, phone: true, email: true } },
          vendor: { include: { translations: true } },
          driver: { include: { user: { select: { name: true, phone: true } } } },
          payment: true,
        },
      }),
      this.prisma.order.count({ where }),
    ]);
    return { items, total, page, limit, pages: Math.ceil(total / limit) };
  }
  @Get('delivery-zones') deliveryZones() {
    return this.prisma.deliveryZone.findMany({ orderBy: [{ cityId: 'asc' }, { name: 'asc' }], include: { city: { select: { id: true, code: true, names: true } } } });
  }
  @Post('delivery-zones') async createDeliveryZone(@Body() dto: CreateDeliveryZoneDto) {
    const city = await this.prisma.city.findFirst({ where: { id: dto.cityId, isActive: true }, select: { id: true } });
    if (!city) throw new BadRequestException('المدينة غير متاحة');
    if (await this.prisma.deliveryZone.findUnique({ where: { cityId: dto.cityId } })) throw new BadRequestException('تم إعداد رسوم هذه المدينة مسبقاً؛ عدّل الإعداد الموجود');
    return this.prisma.deliveryZone.create({ data: dto });
  }
  @Patch('delivery-zones/:id') updateDeliveryZone(@Param('id') id: string, @Body() dto: UpdateDeliveryZoneDto) {
    return this.prisma.deliveryZone.update({ where: { id }, data: dto });
  }
  @Get('vendors/pending') pendingVendors() {
    return this.prisma.vendor.findMany({ where: { status: VendorStatus.PENDING }, orderBy: { createdAt: 'asc' },
      include: { user: { select: { id: true, name: true, phone: true, email: true } }, translations: true, cities: { include: { city: { select: { id: true, code: true, names: true } } } }, location: true } });
  }
  @Patch('vendors/:id/status') async setVendorStatus(@Param('id') id: string, @Body() dto: VendorStatusDto) {
    return this.prisma.$transaction(async tx => {
      const vendor = await tx.vendor.update({ where: { id }, data: { status: dto.status } });
      if (dto.status === VendorStatus.APPROVED) await tx.user.update({ where: { id: vendor.userId }, data: { role: UserRole.VENDOR } });
      else await tx.user.updateMany({ where: { id: vendor.userId, role: UserRole.VENDOR }, data: { role: UserRole.CUSTOMER } });
      return vendor;
    });
  }
  @Get('drivers/pending') pendingDrivers() {
    return this.prisma.driver.findMany({ where: { status: DriverStatus.PENDING }, orderBy: { createdAt: 'asc' },
      include: { user: { select: { id: true, name: true, phone: true, email: true } }, city: { select: { id: true, code: true, names: true } } } });
  }
  @Patch('drivers/:id/status') async setDriverStatus(@Param('id') id: string, @Body() dto: DriverStatusDto) {
    return this.prisma.$transaction(async tx => {
      const driver = await tx.driver.update({ where: { id }, data: { status: dto.status, ...(dto.status === DriverStatus.APPROVED ? {} : { isOnline: false }) } });
      if (dto.status === DriverStatus.APPROVED) await tx.user.update({ where: { id: driver.userId }, data: { role: UserRole.DRIVER } });
      else await tx.user.updateMany({ where: { id: driver.userId, role: UserRole.DRIVER }, data: { role: UserRole.CUSTOMER } });
      return driver;
    });
  }
}
