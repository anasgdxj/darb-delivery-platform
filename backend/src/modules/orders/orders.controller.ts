import { Body, Controller, Get, Param, ParseUUIDPipe, Patch, Post, UseGuards } from '@nestjs/common';
import { IsArray, IsEnum, IsInt, IsLatitude, IsLongitude, IsNumber, IsOptional, IsString, IsUUID, IsUrl, IsBoolean, Max, MaxLength, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { OrderStatus, UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { OrdersService } from './orders.service';
import { NotificationsService } from '../notifications/notifications.service';

class OrderLineDto {
  @IsUUID() productId!: string;
  @Type(() => Number) @IsInt() @Min(1) @Max(50) quantity!: number;
}

class CreatePeerDeliveryDto {
  @IsUUID() cityId!: string;
  @IsUUID() addressId!: string;
  @IsString() pickupAddress!: string;
  @Type(() => Number) @IsLatitude() pickupLatitude!: number;
  @Type(() => Number) @IsLongitude() pickupLongitude!: number;
  @IsOptional() @IsString() notes?: string;
}

class CreateShoppingRequestDto {
  @IsUUID() cityId!: string;
  @IsUUID() addressId!: string;
  @IsString() @MaxLength(180) itemName!: string;
  @IsString() @MaxLength(3000) description!: string;
  @IsOptional() @IsString() @MaxLength(180) storeName?: string;
  @IsOptional() @IsString() @MaxLength(1000) storeAddress?: string;
  @IsOptional() @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0.01) @Max(1000000000) maxPurchaseBudget?: number;
}

class CreateShoppingQuoteDto {
  @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0.01) @Max(1000000000) amount!: number;
  @IsString() @MaxLength(2000) details!: string;
}

class ApproveShoppingQuoteDto {
  @IsOptional() @IsBoolean() allowBudgetOverride?: boolean;
}

class ShoppingPurchaseProofDto {
  @IsString() @MaxLength(180) receiptReference!: string;
  @IsOptional() @IsString() @MaxLength(2000) proofNote?: string;
  @IsOptional() @IsUrl({ require_protocol: true, protocols: ['https'] }) @MaxLength(2048) proofUrl?: string;
}
class CreateOrderDto {
  @IsUUID() cityId!: string;
  @IsUUID() addressId!: string;
  @IsUUID() vendorId!: string;
  @IsArray() @ValidateNested({ each: true }) @Type(() => OrderLineDto) items!: OrderLineDto[];
  @IsOptional() @IsString() notes?: string;
}

class EstimateOrderDto {
  @IsUUID() cityId!: string;
  @IsUUID() addressId!: string;
  @IsUUID() vendorId!: string;
  @IsArray() @ValidateNested({ each: true }) @Type(() => OrderLineDto) items!: OrderLineDto[];
}

class CancelOrderDto {
  @IsOptional() @IsString() @MaxLength(240) reason?: string;
}

class UpdateStatusDto {
  @IsEnum(OrderStatus) status!: OrderStatus;
}

class CreateDeliveryOfferDto {
  @Type(() => Number) @IsNumber({ maxDecimalPlaces: 2 }) @Min(1) @Max(10000000) amount!: number;
}

class CreateReviewDto {
  @Type(() => Number) @IsInt() @Min(1) @Max(5) rating!: number;
  @IsOptional() @IsString() @MaxLength(500) comment?: string;
}

@Controller('orders')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OrdersController {
  constructor(private readonly orders: OrdersService, private readonly notifications: NotificationsService) {}

  @Post('estimate')
  @Roles(UserRole.CUSTOMER)
  estimate(@CurrentUser() user: { id: string }, @Body() dto: EstimateOrderDto) {
    return this.orders.estimate(user.id, dto);
  }

  @Post()
  @Roles(UserRole.CUSTOMER)
  async create(@CurrentUser() user: { id: string }, @Body() dto: CreateOrderDto) {
    const order = await this.orders.create(user.id, dto);
    await this.notifications.notifyVendor(dto.vendorId, 'طلب جديد', 'لديك طلب جديد بانتظار المراجعة', { type: 'ORDER_CREATED', orderId: order.id });
    return order;
  }

  @Post('peer-delivery')
  @Roles(UserRole.CUSTOMER)
  async createPeerDelivery(@CurrentUser() user: { id: string }, @Body() dto: CreatePeerDeliveryDto) {
    const order = await this.orders.createPeerDelivery(user.id, dto);
    await this.notifications.notifyDriversInCity(dto.cityId, 'طلب توصيل جديد', 'يوجد طلب توصيل مستقل متاح في مدينتك', { type: 'PEER_DELIVERY_AVAILABLE', orderId: order.id });
    return order;
  }

  @Post('shopping')
  @Roles(UserRole.CUSTOMER)
  async createShoppingRequest(@CurrentUser() user: { id: string }, @Body() dto: CreateShoppingRequestDto) {
    const order = await this.orders.createShoppingRequest(user.id, dto);
    await this.notifications.notifyDriversInCity(dto.cityId, 'طلب شراء وتوصيل جديد', 'توجد مهمة شراء غرض وتوصيله في مدينتك', { type: 'SHOPPING_DELIVERY_AVAILABLE', orderId: order.id });
    return order;
  }

  @Get(':id/shopping-quotes')
  @Roles(UserRole.CUSTOMER)
  shoppingQuotes(@CurrentUser() user: { id: string }, @Param('id', new ParseUUIDPipe()) id: string) {
    return this.orders.shoppingQuotesForCustomer(user.id, id);
  }

  @Post(':id/shopping-quote')
  @Roles(UserRole.DRIVER)
  async submitShoppingQuote(@CurrentUser() user: { id: string }, @Param('id', new ParseUUIDPipe()) id: string, @Body() dto: CreateShoppingQuoteDto) {
    const quote = await this.orders.submitShoppingPurchaseQuote(user.id, id, dto.amount, dto.details);
    const driverOrders = await this.orders.driverMine(user.id);
    const assigned = driverOrders.find((order) => order.id === id);
    if (assigned?.customer?.id) await this.notifications.notifyCustomer(assigned.customer.id, 'تكلفة الشراء جاهزة للموافقة', 'راجع تكلفة المشتريات التي أرسلها السائق قبل أن يبدأ الشراء', { type: 'SHOPPING_QUOTE_PENDING', orderId: id, quoteId: quote.id });
    return quote;
  }

  @Post(':id/shopping-quotes/:quoteId/approve')
  @Roles(UserRole.CUSTOMER)
  async approveShoppingQuote(@CurrentUser() user: { id: string }, @Param('id', new ParseUUIDPipe()) id: string, @Param('quoteId', new ParseUUIDPipe()) quoteId: string, @Body() dto: ApproveShoppingQuoteDto) {
    const quote = await this.orders.approveShoppingPurchaseQuote(user.id, id, quoteId, dto.allowBudgetOverride === true);
    await this.notifications.notifyDriver(quote.driverId, 'وافق العميل على تكلفة الشراء', 'يمكنك الآن تنفيذ الشراء وفق المبلغ المعتمد', { type: 'SHOPPING_QUOTE_APPROVED', orderId: id, quoteId });
    return quote;
  }

  @Post(':id/shopping-quotes/:quoteId/reject')
  @Roles(UserRole.CUSTOMER)
  rejectShoppingQuote(@CurrentUser() user: { id: string }, @Param('id', new ParseUUIDPipe()) id: string, @Param('quoteId', new ParseUUIDPipe()) quoteId: string) {
    return this.orders.rejectShoppingPurchaseQuote(user.id, id, quoteId);
  }

  @Post(':id/purchase-proof')
  @Roles(UserRole.DRIVER)
  async purchaseProof(@CurrentUser() user: { id: string }, @Param('id', new ParseUUIDPipe()) id: string, @Body() dto: ShoppingPurchaseProofDto) {
    const proof = await this.orders.recordShoppingPurchaseProof(user.id, id, dto);
    const driverOrders = await this.orders.driverMine(user.id);
    const assigned = driverOrders.find((order) => order.id === id);
    if (assigned?.customer?.id) await this.notifications.notifyCustomer(assigned.customer.id, 'تم تسجيل إثبات الشراء', 'أكمل السائق الشراء ويجري تجهيز طلبك للتوصيل', { type: 'SHOPPING_PURCHASED', orderId: id });
    return proof;
  }
  @Get('mine')
  @Roles(UserRole.CUSTOMER)
  mine(@CurrentUser() user: { id: string }) {
    return this.orders.mine(user.id);
  }

  @Post(':id/cancel')
  @Roles(UserRole.CUSTOMER)
  async cancelByCustomer(
    @CurrentUser() user: { id: string },
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body() dto: CancelOrderDto,
  ) {
    const order = await this.orders.cancelByCustomer(user.id, id, dto?.reason);
    if (order?.vendorId) {
      await this.notifications.notifyVendor(order.vendorId, 'إلغاء طلب', `ألغى العميل الطلب ${order.orderNumber}`, { type: 'ORDER_CANCELLED', orderId: id });
    }
    return order;
  }

  @Post(':id/review')
  @Roles(UserRole.CUSTOMER)
  createReview(
    @CurrentUser() user: { id: string },
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body() dto: CreateReviewDto,
  ) {
    return this.orders.createReview(user.id, id, dto);
  }

  @Get('vendor')
  @Roles(UserRole.VENDOR)
  vendorOrders(@CurrentUser() user: { id: string }) {
    return this.orders.vendorOrders(user.id);
  }

  @Get('driver/available')
  @Roles(UserRole.DRIVER)
  available(@CurrentUser() user: { id: string }) {
    return this.orders.availableForDriver(user.id);
  }

  @Get('driver/mine')
  @Roles(UserRole.DRIVER)
  driverMine(@CurrentUser() user: { id: string }) {
    return this.orders.driverMine(user.id);
  }

  @Post(':id/dismiss')
  @Roles(UserRole.DRIVER)
  dismissOrder(@CurrentUser() user: { id: string }, @Param('id', new ParseUUIDPipe()) id: string) {
    return this.orders.dismissOrder(user.id, id);
  }

  @Post(':id/offers')
  @Roles(UserRole.DRIVER)
  submitDeliveryOffer(
    @CurrentUser() user: { id: string },
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body() dto: CreateDeliveryOfferDto,
  ) {
    return this.orders.submitDeliveryOffer(user.id, id, dto.amount);
  }

  @Post(':id/offers/withdraw')
  @Roles(UserRole.DRIVER)
  withdrawDeliveryOffer(@CurrentUser() user: { id: string }, @Param('id', new ParseUUIDPipe()) id: string) {
    return this.orders.withdrawDeliveryOffer(user.id, id);
  }

  @Get(':id/offers')
  @Roles(UserRole.CUSTOMER)
  deliveryOffers(@CurrentUser() user: { id: string }, @Param('id', new ParseUUIDPipe()) id: string) {
    return this.orders.deliveryOffersForCustomer(user.id, id);
  }

  @Post(':id/offers/:offerId/select')
  @Roles(UserRole.CUSTOMER)
  async selectDeliveryOffer(
    @CurrentUser() user: { id: string },
    @Param('id', new ParseUUIDPipe()) id: string,
    @Param('offerId', new ParseUUIDPipe()) offerId: string,
  ) {
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

  @Post(':id/claim')
  @Roles(UserRole.DRIVER)
  async claim(@CurrentUser() user: { id: string }, @Param('id', new ParseUUIDPipe()) id: string) {
    const order = await this.orders.claim(user.id, id);
    if (order) {
      await this.notifications.notifyCustomer(order.customerId, 'تم تعيين سائق لطلبك', 'بدأ السائق استلام طلبك', {
        type: 'ORDER_ASSIGNED',
        orderId: id,
      });
    }
    return order;
  }

  @Patch(':id/status')
  @Roles(UserRole.VENDOR, UserRole.DRIVER)
  async status(
    @CurrentUser() user: { id: string; role: UserRole },
    @Param('id', new ParseUUIDPipe()) id: string,
    @Body() dto: UpdateStatusDto,
  ) {
    const order = await this.orders.updateStatus(user.id, user.role, id, dto.status);
    if (order) {
      await this.notifications.notifyCustomer(order.customerId, 'تحديث حالة الطلب', `تم تحديث حالة طلبك إلى ${dto.status}`, {
        type: 'ORDER_STATUS',
        orderId: id,
        status: dto.status,
      });
    }
    return order;
  }
}
