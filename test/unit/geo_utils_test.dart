import 'package:flutter_test/flutter_test.dart';
import 'package:amptrail_mini/utils/geo_utils.dart';

void main() {
  group('GeoUtils Unit Tests', () {
    test('calculateDistanceKm returns 0 for identical coordinates', () {
      final dist = GeoUtils.calculateDistanceKm(
        12.9716,
        77.5946,
        12.9716,
        77.5946,
      );
      expect(dist, closeTo(0.0, 0.001));
    });

    test(
      'calculateDistanceKm returns accurate distance between Bangalore and Chennai (~290 km)',
      () {
        // Bangalore: 12.9716° N, 77.5946° E
        // Chennai: 13.0827° N, 80.2707° E
        final dist = GeoUtils.calculateDistanceKm(
          12.9716,
          77.5946,
          13.0827,
          80.2707,
        );
        expect(dist, greaterThan(280.0));
        expect(dist, lessThan(310.0));
      },
    );

    test('formatDistance returns meters for distances under 1 km', () {
      expect(GeoUtils.formatDistance(0.45), equals('450 m'));
      expect(GeoUtils.formatDistance(0.05), equals('50 m'));
      expect(GeoUtils.formatDistance(0.001), equals('1 m'));
    });

    test('formatDistance returns kilometers for distances >= 1 km', () {
      expect(GeoUtils.formatDistance(1.0), equals('1.0 km'));
      expect(GeoUtils.formatDistance(12.46), equals('12.5 km'));
      expect(GeoUtils.formatDistance(290.12), equals('290.1 km'));
    });

    test('formatDistance handles 0 and negative inputs safely', () {
      expect(GeoUtils.formatDistance(0), equals('0 m'));
      expect(GeoUtils.formatDistance(-5), equals('0 m'));
    });
  });
}
