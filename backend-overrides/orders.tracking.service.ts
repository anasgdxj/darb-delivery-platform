import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

const LOCATION_MAX_AGE_MS = 2 * 60 * 1000;

@Injectable()
export class OrderTrackingService {
  constructor(private readonly prisma: PrismaService) {}

  async driverLocation(userId: string, orderId: string) {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, customerId: userId },
      select: { driverId: true, status: true },
    });

    if (!order) throw new NotFoundException('الطلب غير موجود');
    if (!order.driverId || !['ASSIGNED', 'PICKED_UP'].includes(order.status)) {
      return { available: false };
    }

    const rows = await this.prisma.$queryRaw<Array<{
      latitude: number;
      longitude: number;
      updatedAt: Date;
    }>>`SELECT ST_Y("point"::geometry) AS latitude, ST_X("point"::geometry) AS longitude, "updatedAt"
       FROM "DriverLocation"
       WHERE "driverId" = ${order.driverId} AND "point" IS NOT NULL
       ORDER BY "updatedAt" DESC
       LIMIT 1`;

    const latest = rows[0];
    if (!latest) return { available: false };

    const ageMs = Date.now() - new Date(latest.updatedAt).getTime();
    if (!Number.isFinite(ageMs) || ageMs < 0 || ageMs > LOCATION_MAX_AGE_MS) {
      return { available: false, reason: 'STALE' };
    }

    return { available: true, ...latest };
  }
}
