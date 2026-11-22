import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export type CanonicalVehicleType = 'BICYCLE' | 'MOTORCYCLE' | 'CAR';

const VEHICLE_ALIASES: Record<string, CanonicalVehicleType> = {
  bicycle: 'BICYCLE',
  bike: 'BICYCLE',
  دراجة: 'BICYCLE',
  'دراجة هوائية': 'BICYCLE',
  هوائية: 'BICYCLE',
  bisiklet: 'BICYCLE',
  motorcycle: 'MOTORCYCLE',
  motorbike: 'MOTORCYCLE',
  moto: 'MOTORCYCLE',
  scooter: 'MOTORCYCLE',
  دراجة_نارية: 'MOTORCYCLE',
  'دراجة نارية': 'MOTORCYCLE',
  نارية: 'MOTORCYCLE',
  موتور: 'MOTORCYCLE',
  موتوسيكل: 'MOTORCYCLE',
  motosiklet: 'MOTORCYCLE',
  car: 'CAR',
  auto: 'CAR',
  sedan: 'CAR',
  سيارة: 'CAR',
  araba: 'CAR',
  otomobil: 'CAR',
};

export function normalizeVehicleType(raw?: string | null): CanonicalVehicleType {
  if (!raw || !raw.trim()) return 'MOTORCYCLE';
  const cleaned = raw.trim().toLowerCase();
  const mapped = VEHICLE_ALIASES[cleaned];
  if (!mapped) {
    throw new BadRequestException('نوع المركبة يجب أن يكون دراجة هوائية أو دراجة نارية أو سيارة');
  }
  return mapped;
}

@Injectable()
export class DriversService {
  constructor(private readonly prisma: PrismaService) {}

  async me(userId: string) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId },
      select: { id: true, status: true, isOnline: true, cityId: true, vehicleType: true },
    });
    if (!driver) throw new BadRequestException('لا يوجد ملف سائق لهذا الحساب');
    return driver;
  }

  async stats(userId: string) {
    const driver = await this.prisma.driver.findUnique({
      where: { userId },
      select: {
        id: true,
        status: true,
        isOnline: true,
        vehicleType: true,
        cityId: true,
        city: { select: { defaultCurrency: true } },
      },
    });
    if (!driver) throw new BadRequestException('لا يوجد ملف سائق لهذا الحساب');

    const now = new Date();
    const todayStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

    const [deliveredAgg, todayAgg, activeCount, peerOffersCount] = await Promise.all([
      this.prisma.order.aggregate({
        where: { driverId: driver.id, status: 'DELIVERED' },
        _count: { id: true },
        _sum: { deliveryFee: true },
      }),
      this.prisma.order.aggregate({
        where: { driverId: driver.id, status: 'DELIVERED', updatedAt: { gte: todayStart } },
        _count: { id: true },
        _sum: { deliveryFee: true },
      }),
      this.prisma.order.count({
        where: { driverId: driver.id, status: { in: ['ASSIGNED', 'PICKED_UP'] } },
      }),
      this.prisma.deliveryOffer.count({
        where: { driverId: driver.id, status: 'PENDING' },
      }),
    ]);

    return {
      driverId: driver.id,
      vehicleType: driver.vehicleType ?? 'MOTORCYCLE',
      isOnline: driver.isOnline,
      completedTrips: deliveredAgg._count.id,
      todayTrips: todayAgg._count.id,
      activeTrips: activeCount,
      pendingOffers: peerOffersCount,
      totalEarnings: Number(deliveredAgg._sum.deliveryFee ?? 0),
      todayEarnings: Number(todayAgg._sum.deliveryFee ?? 0),
      currency: driver.city?.defaultCurrency ?? 'SYP',
    };
  }

  async setOnline(userId: string, isOnline: boolean) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver || driver.status !== 'APPROVED') throw new BadRequestException('حساب السائق غير معتمد');
    return this.prisma.driver.update({ where: { userId }, data: { isOnline } });
  }

  async updateVehicle(userId: string, vehicleType: string) {
    const driver = await this.prisma.driver.findUnique({ where: { userId } });
    if (!driver) throw new BadRequestException('لا يوجد ملف سائق لهذا الحساب');
    const canonical = normalizeVehicleType(vehicleType);
    return this.prisma.driver.update({
      where: { userId },
      data: { vehicleType: canonical },
      select: { id: true, status: true, isOnline: true, cityId: true, vehicleType: true },
    });
  }

  async apply(userId: string, dto: { cityId: string; vehicleType?: string }) {
    const canonicalVehicle = normalizeVehicleType(dto.vehicleType);
    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.findUnique({ where: { id: userId } });
      if (!user || user.role !== 'CUSTOMER') throw new BadRequestException('الحساب غير مؤهل لتقديم طلب سائق');
      const city = await tx.city.findFirst({ where: { id: dto.cityId, isActive: true }, select: { id: true } });
      if (!city) throw new BadRequestException('المدينة غير متاحة');
      if (await tx.driver.findUnique({ where: { userId } })) throw new BadRequestException('يوجد طلب سائق لهذا الحساب');
      if (await tx.vendor.findUnique({ where: { userId } })) throw new BadRequestException('لديك طلب متجر قائم بالفعل');
      const driver = await tx.driver.create({
        data: { userId, cityId: dto.cityId, vehicleType: canonicalVehicle, status: 'PENDING' },
      });
      return { id: driver.id, status: driver.status, vehicleType: canonicalVehicle, message: 'تم استلام طلبك وسيتم مراجعته قبل تفعيل الحساب' };
    });
  }
}
