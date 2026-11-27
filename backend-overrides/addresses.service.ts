import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
@Injectable()
export class AddressesService {
  constructor(private readonly prisma: PrismaService) {}
  async list(userId: string) {
    const addresses = await this.prisma.address.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    const locations = await this.prisma.$queryRaw<Array<{ id: string; hasLocation: boolean }>>`
      SELECT "id", "point" IS NOT NULL AS "hasLocation"
      FROM "Address"
      WHERE "userId" = ${userId}
    `;
    const locationById = new Map(locations.map((item) => [item.id, item.hasLocation]));
    return addresses.map((address) => ({
      ...address,
      hasLocation: locationById.get(address.id) === true,
    }));
  }
  async create(userId: string, dto: { label?: string; details: string; latitude?: number; longitude?: number }) {
    if ((dto.latitude === undefined) !== (dto.longitude === undefined)) throw new BadRequestException('يجب إرسال خط العرض والطول معاً');
    return this.prisma.$transaction(async (tx) => {
      const address = await tx.address.create({
        data: { userId, label: dto.label, details: dto.details },
      });
      if (dto.latitude !== undefined && dto.longitude !== undefined) {
        await tx.$executeRaw`UPDATE "Address"
          SET "point" = ST_SetSRID(ST_MakePoint(${dto.longitude}, ${dto.latitude}), 4326)::geography
          WHERE "id" = ${address.id} AND "userId" = ${userId}`;
      }
      return tx.address.findUnique({ where: { id: address.id } });
    });
  }
}
