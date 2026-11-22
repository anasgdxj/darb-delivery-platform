export type GeoPoint = {
  latitude: number;
  longitude: number;
};

export type RouteEstimate = {
  distanceKm: number;
  durationMinutes: number;
  provider: string;
};

export type GeocodeCandidate = {
  displayName: string;
  latitude: number;
  longitude: number;
  provider: string;
};

export abstract class MapsProvider {
  abstract readonly name: string;
  abstract estimateRoute(origin: GeoPoint, destination: GeoPoint): Promise<RouteEstimate>;
  abstract reverseGeocode(point: GeoPoint, locale?: string): Promise<GeocodeCandidate | null>;
}
