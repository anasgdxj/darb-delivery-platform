import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { IsBoolean, IsInt, IsNumber, IsOptional, IsString, Max, MaxLength, Min, MinLength } from 'class-validator';
import { Type } from 'class-transformer';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { CatalogService } from './catalog.service';

class CreateProductDto {
  @IsString() @MinLength(2) @MaxLength(120) name!: string;
  @IsOptional() @IsString() @MaxLength(500) description?: string;
  @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) @Max(100000000) price!: number;
  @IsOptional() @IsString() @MaxLength(3) currency?: string;
  @IsOptional() @IsString() @MaxLength(80) category?: string;
  @IsOptional() @IsString() @MaxLength(500) imageUrl?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) stockQty?: number;
  @IsOptional() @IsBoolean() isAvailable?: boolean;
}

class UpdateProductDto {
  @IsOptional() @IsString() @MinLength(2) @MaxLength(120) name?: string;
  @IsOptional() @IsString() @MaxLength(500) description?: string;
  @IsOptional() @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) @Max(100000000) price?: number;
  @IsOptional() @IsString() @MaxLength(80) category?: string;
  @IsOptional() @IsString() @MaxLength(500) imageUrl?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) stockQty?: number;
  @IsOptional() @IsBoolean() isAvailable?: boolean;
}

@Controller()
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  @Get('vendors/:vendorId/products')
  list(
    @Param('vendorId') vendorId: string,
    @Query('locale') locale = 'ar',
    @Query('category') category?: string,
    @Query('q') q?: string,
  ) {
    return this.catalog.list(vendorId, locale, { category, q });
  }

  @Get('vendor/products')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  mine(@CurrentUser() user: { id: string }, @Query('q') q?: string) {
    return this.catalog.listMine(user.id, q);
  }

  @Post('vendor/products')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  create(@CurrentUser() user: { id: string }, @Body() dto: CreateProductDto) {
    return this.catalog.create(user.id, dto);
  }

  @Patch('vendor/products/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  update(@CurrentUser() user: { id: string }, @Param('id') id: string, @Body() dto: UpdateProductDto) {
    return this.catalog.update(user.id, id, dto);
  }

  @Delete('vendor/products/:id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.VENDOR)
  remove(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.catalog.remove(user.id, id);
  }
}
