import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
@Injectable()
export class DriverLocationService {
  constructor(private readonly prisma: PrismaService) {}
  async update(userId: string, latitude: number, longitude: number) {
    const driver = await this.prisma.driver.findUnique({ where: { userId }, select: { id: true, status: true, isOnline: true } });
    if (!driver || driver.status !== 'APPROVED' || !driver.isOnline) throw new BadRequestException('يجب اعتماد السائق وتفعيل الاتصال قبل مشاركة الموقع');
    await this.prisma.$executeRaw`INSERT INTO "DriverLocation" ("driverId", "point", "updatedAt") VALUES (${driver.id}, ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography, NOW()) ON CONFLICT ("driverId") DO UPDATE SET "point" = EXCLUDED."point", "updatedAt" = NOW()`;
    return { success: true };
  }
}
