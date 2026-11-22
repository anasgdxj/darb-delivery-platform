import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
@Injectable()
export class CitiesService {
  constructor(private readonly prisma: PrismaService) {}
  list() {
    return this.prisma.city.findMany({ where: { isActive: true }, orderBy: { code: 'asc' },
      select: { id: true, code: true, defaultCurrency: true, supportedLocales: true,
        names: { select: { locale: true, name: true } } } });
  }
  async getByCode(code: string) {
    const city = await this.prisma.city.findFirst({ where: { code, isActive: true },
      select: { id: true, code: true, defaultCurrency: true, supportedLocales: true,
        names: { select: { locale: true, name: true } } } });
    if (!city) throw new NotFoundException('المدينة غير متاحة');
    return city;
  }
}
