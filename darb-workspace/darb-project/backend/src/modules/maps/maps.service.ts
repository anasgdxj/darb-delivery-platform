import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GeocodeCandidate, GeoPoint, MapsProvider, RouteEstimate } from './maps.provider';

const EARTH_RADIUS_KM = 6371;
const ROAD_TORTUOSITY_FACTOR = 1.25;
const AVG_CITY_SPEED_KMH = 26;

export function haversineDistanceKm(a: GeoPoint, b: GeoPoint): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(b.latitude - a.latitude);
  const dLng = toRad(b.longitude - a.longitude);
  const lat1 = toRad(a.latitude);
  const lat2 = toRad(b.latitude);
  const sinDLat = Math.sin(dLat / 2);
  const sinDLng = Math.sin(dLng / 2);
  const h = sinDLat * sinDLat + Math.cos(lat1) * Math.cos(lat2) * sinDLng * sinDLng;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.min(1, Math.sqrt(h)));
}

@Injectable()
export class MapsService extends MapsProvider {
  readonly name: string;

  constructor(private readonly config: ConfigService) {
    super();
    this.name = (this.config.get<string>('MAPS_PROVIDER') ?? 'osm').toLowerCase();
  }

  async estimateRoute(origin: GeoPoint, destination: GeoPoint): Promise<RouteEstimate> {
    const googleKey = this.config.get<string>('GOOGLE_MAPS_API_KEY');
    if (this.name === 'google' && googleKey) {
      try {
        const url =
          `https://maps.googleapis.com/maps/api/distancematrix/json` +
          `?origins=${origin.latitude},${origin.longitude}` +
          `&destinations=${destination.latitude},${destination.longitude}` +
          `&mode=driving&key=${encodeURIComponent(googleKey)}`;
        const response = await fetch(url, { signal: AbortSignal.timeout(8000) });
        if (response.ok) {
          const data = (await response.json()) as {
            rows?: Array<{
              elements?: Array<{
                status?: string;
                distance?: { value?: number };
                duration?: { value?: number };
              }>;
            }>;
          };
          const element = data.rows?.[0]?.elements?.[0];
          if (element?.status === 'OK' && element.distance?.value && element.duration?.value) {
            return {
              distanceKm: Number((element.distance.value / 1000).toFixed(2)),
              durationMinutes: Math.max(1, Math.ceil(element.duration.value / 60)),
              provider: 'google',
            };
          }
        }
      } catch {
        // Fallback smoothly to deterministic geodesic estimate when external provider is unreachable.
      }
    }

    const directKm = haversineDistanceKm(origin, destination);
    const roadKm = Number((directKm * ROAD_TORTUOSITY_FACTOR).toFixed(2));
    const durationMinutes = Math.max(3, Math.ceil((roadKm / AVG_CITY_SPEED_KMH) * 60));
    return {
      distanceKm: roadKm,
      durationMinutes,
      provider: 'haversine-osm',
    };
  }

  async reverseGeocode(point: GeoPoint, locale = 'ar'): Promise<GeocodeCandidate | null> {
    if (this.config.get<string>('ENABLE_NOMINATIM_GEOCODE') !== 'true') {
      return null;
    }
    try {
      const url =
        `https://nominatim.openstreetmap.org/reverse?format=jsonv2` +
        `&lat=${encodeURIComponent(String(point.latitude))}` +
        `&lon=${encodeURIComponent(String(point.longitude))}` +
        `&accept-language=${encodeURIComponent(locale)}`;
      const response = await fetch(url, {
        headers: { 'User-Agent': 'DARB-Delivery-Platform/1.0' },
        signal: AbortSignal.timeout(6000),
      });
      if (!response.ok) return null;
      const data = (await response.json()) as { display_name?: string };
      if (!data.display_name) return null;
      return {
        displayName: data.display_name,
        latitude: point.latitude,
        longitude: point.longitude,
        provider: 'nominatim-osm',
      };
    } catch {
      return null;
    }
  }
}
