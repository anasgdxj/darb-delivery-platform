import { ConfigService } from '@nestjs/config';
import { MapsService, haversineDistanceKm } from './maps.service';

describe('MapsService', () => {
  const damascus = { latitude: 33.5138, longitude: 36.2765 };
  const aleppo = { latitude: 36.2021, longitude: 37.1343 };

  it('computes accurate Haversine distance between Damascus and Aleppo', () => {
    const km = haversineDistanceKm(damascus, aleppo);
    expect(km).toBeGreaterThan(300);
    expect(km).toBeLessThan(325);
  });

  it('estimates route distance and duration deterministically via Haversine-OSM fallback', async () => {
    const config = { get: jest.fn(() => undefined) } as unknown as ConfigService;
    const service = new MapsService(config);

    const route = await service.estimateRoute(
      { latitude: 33.5138, longitude: 36.2765 },
      { latitude: 33.5238, longitude: 36.2865 },
    );

    expect(route.provider).toBe('haversine-osm');
    expect(route.distanceKm).toBeGreaterThan(1);
    expect(route.durationMinutes).toBeGreaterThanOrEqual(3);
  });

  it('skips external reverse geocode calls unless explicitly enabled', async () => {
    const config = { get: jest.fn(() => 'false') } as unknown as ConfigService;
    const service = new MapsService(config);
    const result = await service.reverseGeocode(damascus);
    expect(result).toBeNull();
  });
});
