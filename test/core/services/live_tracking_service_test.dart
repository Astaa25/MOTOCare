import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/services/live_tracking_service.dart';

void main() {
  group('LiveTrackingService Unit Tests (Gojek / Grab Real-Time Tracking)', () {
    late LiveTrackingService service;

    setUp(() {
      service = LiveTrackingService();
    });

    tearDown(() {
      service.dispose();
    });

    test('calculateBearing menghitung arah kompas sudut secara akurat', () {
      // Menuju Utara (Latitude bertambah, Longitude tetap)
      final northBearing = LiveTrackingService.calculateBearing(
        lat1: 5.1800,
        lon1: 97.1400,
        lat2: 5.1900,
        lon2: 97.1400,
      );
      expect(northBearing, closeTo(0.0, 1.0));

      // Menuju Timur (Latitude tetap, Longitude bertambah)
      final eastBearing = LiveTrackingService.calculateBearing(
        lat1: 5.1800,
        lon1: 97.1400,
        lat2: 5.1800,
        lon2: 97.1500,
      );
      expect(eastBearing, closeTo(90.0, 1.0));

      // Menuju Selatan (Latitude berkurang, Longitude tetap)
      final southBearing = LiveTrackingService.calculateBearing(
        lat1: 5.1800,
        lon1: 97.1400,
        lat2: 5.1700,
        lon2: 97.1400,
      );
      expect(southBearing, closeTo(180.0, 1.0));

      // Menuju Barat (Latitude tetap, Longitude berkurang)
      final westBearing = LiveTrackingService.calculateBearing(
        lat1: 5.1800,
        lon1: 97.1400,
        lat2: 5.1800,
        lon2: 97.1300,
      );
      expect(westBearing, closeTo(270.0, 1.0));
    });

    test('calculateDistanceKm menghitung jarak Haversine antar koordinat', () {
      // Jarak 2 titik di Lhokseumawe (~1.5 km)
      final distance = LiveTrackingService.calculateDistanceKm(
        lat1: 5.1801,
        lon1: 97.1405,
        lat2: 5.1672,
        lon2: 97.1320,
      );
      expect(distance, greaterThan(1.0));
      expect(distance, lessThan(3.0));
    });

    test('generateRoadWaypoints menghasilkan jalur koordinat bertahap', () {
      final points = LiveTrackingService.generateRoadWaypoints(
        startLat: 5.1900,
        startLng: 97.1500,
        destLat: 5.1800,
        destLng: 97.1400,
        steps: 10,
      );

      expect(points.length, equals(11));
      expect(points.first[0], equals(5.1900));
      expect(points.first[1], equals(97.1500));
      expect(points.last[0], equals(5.1800));
      expect(points.last[1], equals(97.1400));
    });

    test('watchMechanicLocation memancarkan update stream lokasi pertama segera', () async {
      final stream = service.watchMechanicLocation(
        requestId: 'req-test-99',
        destLat: 5.1801,
        destLng: 97.1402,
        mechanicName: 'Bang Rudi Pratama',
      );

      final firstUpdate = await stream.first;
      expect(firstUpdate.requestId, equals('req-test-99'));
      expect(firstUpdate.mechanicName, equals('Bang Rudi Pratama'));
      expect(firstUpdate.distanceKm, greaterThan(0));
      expect(firstUpdate.etaMinutes, greaterThan(0));
      expect(firstUpdate.motorcyclePlate, isNotEmpty);
    });

    test('startBroadcastingLocation dan stopBroadcastingLocation mengelola status montir', () async {
      expect(service.isBroadcasting('req-test-01'), isFalse);

      await service.startBroadcastingLocation(
        requestId: 'req-test-01',
        mechanicId: 'mech-01',
      );
      expect(service.isBroadcasting('req-test-01'), isTrue);

      service.stopBroadcastingLocation('req-test-01');
      expect(service.isBroadcasting('req-test-01'), isFalse);
    });
  });
}
