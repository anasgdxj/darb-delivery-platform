import { Global, Module } from '@nestjs/common';
import { MapsProvider } from './maps.provider';
import { MapsService } from './maps.service';

@Global()
@Module({
  providers: [
    MapsService,
    { provide: MapsProvider, useExisting: MapsService },
  ],
  exports: [MapsService, MapsProvider],
})
export class MapsModule {}
