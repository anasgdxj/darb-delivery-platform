import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { IsArray, IsInt, IsOptional, IsEnum, IsString, IsUUID, IsLatitude, IsLongitude, IsNumber, Max, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { OrderStatus, UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { OrdersService } from './orders.service';
import { NotificationsService } from '../notifications/notifications.service';
class OrderLineDto { @IsUUID() productId!: string; @Type(() => Number) @IsInt() @Min(1) @Max(50) quantity!: number; }
class CreatePeerDeliveryDto {
  @IsUUID() cityId!: string;
  @IsUUID() addressId!: string;
  @IsString() pickupAddress!: string;
  @Type(() => Number) @IsLatitude() pickupLatitude!: number;
  @Type(() => Number) @IsLongitude() pickupLongitude!: number;
  @IsOptional() @IsString() notes?: string;
}
class CreateOrderDto {
  @IsUUID() cityId!: string; @IsUUID() addressId!: string; @IsUUID() vendorId!: string;
  @IsArray() @ValidateNested({ each: true }) @Type(() => OrderLineDto) items!: OrderLineDto[];
  @IsOptional() @IsString() notes?: string;
}
class UpdateStatusDto { @IsEnum(OrderStatus) status!: OrderStatus; }
class CreateDeliveryOfferDto { @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(1) @Max(10000000) amount!: number; }
@Controller('orders') @UseGuards(JwtAuthGuard, RolesGuard)
export class OrdersController {
  constructor(private readonly orders: OrdersService, private readonly notifications: NotificationsService) {}
  @Post() @Roles(UserRole.CUSTOMER)
  async create(@CurrentUser() user: {id:string}, @Body() dto: CreateOrderDto) {
    const order = await this.orders.create(user.id, dto);
    await this.notifications.notifyVendor(dto.vendorId, 'طلب جديد', 'لديك طلب جديد بانتظار المراجعة', { type: 'ORDER_CREATED', orderId: order.id });
    return order;
  }
  @Post('peer-delivery') @Roles(UserRole.CUSTOMER)
  async createPeerDelivery(@CurrentUser() user: {id:string}, @Body() dto: CreatePeerDeliveryDto) {
    const order = await this.orders.createPeerDelivery(user.id, dto);
    await this.notifications.notifyDriversInCity(dto.cityId, 'طلب توصيل جديد', 'يوجد طلب توصيل مستقل متاح في مدينتك', { type: 'PEER_DELIVERY_AVAILABLE', orderId: order.id });
    return order;
  }
  @Get('mine') @Roles(UserRole.CUSTOMER) mine(@CurrentUser() user: {id:string}) { return this.orders.mine(user.id); }
  @Get('vendor') @Roles(UserRole.VENDOR) vendorOrders(@CurrentUser() user: {id:string}) { return this.orders.vendorOrders(user.id); }
  @Get('driver/available') @Roles(UserRole.DRIVER) available(@CurrentUser() user: {id:string}) { return this.orders.availableForDriver(user.id); }
  @Get('driver/mine') @Roles(UserRole.DRIVER) driverMine(@CurrentUser() user: {id:string}) { return this.orders.driverMine(user.id); }
  @Post(':id/offers') @Roles(UserRole.DRIVER)
  submitDeliveryOffer(@CurrentUser() user: {id:string}, @Param('id') id: string, @Body() dto: CreateDeliveryOfferDto) {
    return this.orders.submitDeliveryOffer(user.id, id, dto.amount);
  }
  @Get(':id/offers') @Roles(UserRole.CUSTOMER)
  deliveryOffers(@CurrentUser() user: {id:string}, @Param('id') id: string) {
    return this.orders.deliveryOffersForCustomer(user.id, id);
  }
  @Post(':id/offers/:offerId/select') @Roles(UserRole.CUSTOMER)
  async selectDeliveryOffer(@CurrentUser() user: {id:string}, @Param('id') id: string, @Param('offerId') offerId: string) {
    const order = await this.orders.selectDeliveryOffer(user.id, id, offerId);
    if (order?.driverId) {
      await this.notifications.notifyDriver(
        order.driverId,
        'تم اختيار عرضك',
        'اختار العميل عرضك وأُسند إليك طلب التوصيل',
        { type: 'DELIVERY_OFFER_SELECTED', orderId: id },
      );
    }
    return order;
  }
  @Post(':id/claim') @Roles(UserRole.DRIVER)
  async claim(@CurrentUser() user: {id:string}, @Param('id') id: string) {
    const order = await this.orders.claim(user.id, id);
    if (order) await this.notifications.notifyCustomer(order.customerId, 'تم تعيين سائق لطلبك', 'بدأ السائق استلام طلبك', { type: 'ORDER_ASSIGNED', orderId: id });
    return order;
  }
  @Patch(':id/status') @Roles(UserRole.VENDOR, UserRole.DRIVER)
  async status(@CurrentUser() user: {id:string;role:UserRole}, @Param('id') id:string, @Body() dto:UpdateStatusDto) {
    const order = await this.orders.updateStatus(user.id, user.role, id, dto.status);
    if (order) await this.notifications.notifyCustomer(order.customerId, 'تحديث حالة الطلب', `تم تحديث حالة طلبك إلى ${dto.status}`, { type: 'ORDER_STATUS', orderId: id, status: dto.status });
    return order;
  }
}
