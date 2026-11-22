import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Query, UseGuards } from '@nestjs/common';
import { Type } from 'class-transformer';
import { IsBoolean, IsLatitude, IsLongitude, IsOptional, IsString, MaxLength, MinLength, ValidateIf } from 'class-validator';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { VendorsService } from './vendors.service';

class UpdateMyVendorDto {
  @IsOptional() @IsString() @MinLength(2) @MaxLength(120) name?: string;
  @IsOptional() @IsString() @MaxLength(500) description?: string;
  @IsOptional() @IsString() @MaxLength(60) type?: string;
  @IsOptional() @IsString() @MaxLength(240) address?: string;
  @IsOptional() @IsBoolean() isOpen?: boolean;
  @ValidateIf((o) => o.longitude !== undefined) @Type(() => Number) @IsLatitude() latitude?: number;
  @ValidateIf((o) => o.latitude !== undefined) @Type(() => Number) @IsLongitude() longitude?: number;
}

@Controller('vendors')
export class VendorsController {
  constructor(private readonly vendors: VendorsService) {}

  @Get('mine')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  mine(@CurrentUser() user: { id: string }) {
    return this.vendors.mine(user.id);
  }

  @Get('mine/stats')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  stats(@CurrentUser() user: { id: string }) {
    return this.vendors.stats(user.id);
  }

  @Patch('mine')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  updateMine(@CurrentUser() user: { id: string }, @Body() dto: UpdateMyVendorDto) {
    return this.vendors.updateMine(user.id, dto);
  }

  @Get()
  list(
    @Query('cityId') cityId?: string,
    @Query('locale') locale = 'ar',
    @Query('type') type?: string,
    @Query('q') q?: string,
  ) {
    return this.vendors.list(cityId, locale, { type, q });
  }

  @Get(':id/reviews')
  reviews(@Param('id', new ParseUUIDPipe()) id: string) {
    return this.vendors.reviews(id);
  }

  @Get(':id')
  get(@Param('id', new ParseUUIDPipe()) id: string, @Query('locale') locale = 'ar') {
    return this.vendors.get(id, locale);
  }
}
