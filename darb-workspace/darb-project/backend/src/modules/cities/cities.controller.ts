import { Controller, Get, Param } from '@nestjs/common';
import { CitiesService } from './cities.service';
@Controller('cities')
export class CitiesController {
  constructor(private readonly cities: CitiesService) {}
  @Get() list() { return this.cities.list(); }
  @Get(':code') get(@Param('code') code: string) { return this.cities.getByCode(code); }
}
