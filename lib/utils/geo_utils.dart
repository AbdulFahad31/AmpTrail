import 'dart:math' show cos, sqrt, asin;

/// Geographical and distance calculation utilities for AmpTrail.
class GeoUtils {
  GeoUtils._();

  /// Calculates the great-circle distance between two points on the Earth's surface
  /// using the Haversine formula. Returns distance in kilometers (km).
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // Earth radius * 2 = 12742 km
  }

  /// Formats a distance in kilometers into a user-friendly string (e.g. "450 m" or "3.2 km").
  static String formatDistance(double km) {
    if (km < 0) return '0 m';
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}
