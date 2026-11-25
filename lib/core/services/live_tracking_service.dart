import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Model pembaruan lokasi montir secara real-time (Gojek / Grab Live Tracking)
class MechanicLocationUpdate {
  const MechanicLocationUpdate({
    required this.requestId,
    required this.mechanicId,
    required this.mechanicName,
    this.mechanicPhone = '081269112201',
    this.motorcyclePlate = 'BL 4821 KAA',
    this.motorcycleModel = 'Honda Vario 160 Hitam',
    this.rating = 4.9,
    this.totalReviews = 142,
    this.workshopName = 'Bengkel Resmi Samudera Motor',
    required this.latitude,
    required this.longitude,
    required this.heading,
    this.speedKmh = 36.5,
    required this.distanceKm,
    required this.etaMinutes,
    required this.timestamp,
    this.statusMessage = 'Montir sedang bergerak menuju lokasi Anda',
    this.isBroadcasting = true,
    this.routeWaypoints = const <List<double>>[],
  });

  final String requestId;
  final String mechanicId;
  final String mechanicName;
  final String? mechanicPhone;
  final String motorcyclePlate;
  final String motorcycleModel;
  final double rating;
  final int totalReviews;
  final String workshopName;
  final double latitude;
  final double longitude;
  final double heading; // 0.0 .. 360.0 derajat
  final double speedKmh;
  final double distanceKm;
  final int etaMinutes;
  final DateTime timestamp;
  final String statusMessage;
  final bool isBroadcasting;
  final List<List<double>> routeWaypoints;

  bool get isArrived => distanceKm <= 0.05 || etaMinutes <= 0;

  MechanicLocationUpdate copyWith({
    String? requestId,
    String? mechanicId,
    String? mechanicName,
    String? mechanicPhone,
    String? motorcyclePlate,
    String? motorcycleModel,
    double? rating,
    int? totalReviews,
    String? workshopName,
    double? latitude,
    double? longitude,
    double? heading,
    double? speedKmh,
    double? distanceKm,
    int? etaMinutes,
    DateTime? timestamp,
    String? statusMessage,
    bool? isBroadcasting,
    List<List<double>>? routeWaypoints,
  }) {
    return MechanicLocationUpdate(
      requestId: requestId ?? this.requestId,
      mechanicId: mechanicId ?? this.mechanicId,
      mechanicName: mechanicName ?? this.mechanicName,
      mechanicPhone: mechanicPhone ?? this.mechanicPhone,
      motorcyclePlate: motorcyclePlate ?? this.motorcyclePlate,
      motorcycleModel: motorcycleModel ?? this.motorcycleModel,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      workshopName: workshopName ?? this.workshopName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speedKmh: speedKmh ?? this.speedKmh,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      timestamp: timestamp ?? this.timestamp,
      statusMessage: statusMessage ?? this.statusMessage,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      routeWaypoints: routeWaypoints ?? this.routeWaypoints,
    );
  }
}

/// Service Pelacakan Real-Time Montir dengan Rute Jalan OSRM (OpenStreetMap)
class LiveTrackingService {
  LiveTrackingService();

  final Map<String, MechanicLocationUpdate> _latestUpdates = <String, MechanicLocationUpdate>{};
  final Map<String, StreamController<MechanicLocationUpdate>> _controllers =
      <String, StreamController<MechanicLocationUpdate>>{};
  final Map<String, Timer> _activeTimers = <String, Timer>{};
  final Set<String> _broadcastingMechanics = <String>{};

  static bool get _isTestEnv {
    try {
      return WidgetsBinding.instance
          .toString()
          .contains('TestWidgetsFlutterBinding');
    } catch (_) {
      // Di pure Dart unit test tanpa runApp/TestWidgetsFlutterBinding,
      // hindari panggilan HTTP OSRM eksternal.
      return true;
    }
  }

  /// Menghitung sudut arah (bearing/heading) dalam derajat (0-360) dari titik A ke titik B
  static double calculateBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final double phi1 = lat1 * (pi / 180.0);
    final double phi2 = lat2 * (pi / 180.0);
    final double deltaLambda = (lon2 - lon1) * (pi / 180.0);

    final double y = sin(deltaLambda) * cos(phi2);
    final double x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);
    final double theta = atan2(y, x);
    final double bearing = (theta * (180.0 / pi) + 360.0) % 360.0;
    return bearing;
  }

  /// Menghitung jarak Haversine dalam kilometer
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusKm = 6371.0;
    final double dLat = (lat2 - lat1) * (pi / 180.0);
    final double dLon = (lon2 - lon1) * (pi / 180.0);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Membuat rute titik jalan (waypoints) fallback sepanjang jalan perkotaan
  static List<List<double>> generateRoadWaypoints({
    required double startLat,
    required double startLng,
    required double destLat,
    required double destLng,
    int steps = 14,
  }) {
    final List<List<double>> points = <List<double>>[];
    for (int i = 0; i <= steps; i++) {
      final double fraction = i / steps;
      final double curveOffset = sin(fraction * pi) * 0.0018;
      final double lat = startLat + (destLat - startLat) * fraction + (curveOffset * 0.4);
      final double lng = startLng + (destLng - startLng) * fraction + curveOffset;
      points.add(<double>[lat, lng]);
    }
    return points;
  }

  /// Mengambil rute jalan raya aktual dari OpenStreetMap OSRM API (gratis, tanpa API key)
  static Future<List<List<double>>> fetchOsrmRoadRoute({
    required double startLat,
    required double startLng,
    required double destLat,
    required double destLng,
  }) async {
    if (_isTestEnv) {
      return generateRoadWaypoints(
        startLat: startLat,
        startLng: startLng,
        destLat: destLat,
        destLng: destLng,
        steps: 36,
      );
    }

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$startLng,$startLat;$destLng,$destLat'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = decoded['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = (routes.first as Map<String, dynamic>)['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List<dynamic>?;
          if (coords != null && coords.length >= 2) {
            final rawPoints = coords
                .map((c) => <double>[(c[1] as num).toDouble(), (c[0] as num).toDouble()])
                .toList();
            return _densifyWaypoints(rawPoints, targetSteps: 48);
          }
        }
      }
    } catch (_) {
      // Fallback mulus jika offline / timeout
    }

    return generateRoadWaypoints(
      startLat: startLat,
      startLng: startLng,
      destLat: destLat,
      destLng: destLng,
      steps: 45,
    );
  }

  static List<List<double>> _densifyWaypoints(
    List<List<double>> raw, {
    int targetSteps = 48,
  }) {
    if (raw.length >= targetSteps) return raw;
    final List<List<double>> dense = <List<double>>[];
    final segments = raw.length - 1;
    final subSteps = max(1, (targetSteps / segments).ceil());
    for (int i = 0; i < segments; i++) {
      final a = raw[i];
      final b = raw[i + 1];
      for (int s = 0; s < subSteps; s++) {
        final t = s / subSteps;
        dense.add(<double>[
          a[0] + (b[0] - a[0]) * t,
          a[1] + (b[1] - a[1]) * t,
        ]);
      }
    }
    dense.add(raw.last);
    return dense;
  }

  /// Stream posisi montir secara real-time untuk pengendara (mengikuti jalan raya OSRM)
  Stream<MechanicLocationUpdate> watchMechanicLocation({
    required String requestId,
    required double destLat,
    required double destLng,
    String mechanicId = 'mech-01',
    String mechanicName = 'Bang Rudi Pratama',
    String? mechanicPhone = '081269112201',
    String motorcyclePlate = 'BL 4821 KAA',
    String motorcycleModel = 'Honda Vario 160 Hitam',
    String workshopName = 'Bengkel Resmi Samudera Motor',
    double? initialMechLat,
    double? initialMechLng,
  }) {
    if (!_controllers.containsKey(requestId) || _controllers[requestId]!.isClosed) {
      _controllers[requestId] = StreamController<MechanicLocationUpdate>.broadcast();
    }

    final controller = _controllers[requestId]!;

    final double originLat = initialMechLat ?? (destLat + 0.0115);
    final double originLng = initialMechLng ?? (destLng + 0.0095);

    List<List<double>> waypoints = generateRoadWaypoints(
      startLat: originLat,
      startLng: originLng,
      destLat: destLat,
      destLng: destLng,
      steps: 45,
    );

    int currentIndex = 0;

    void emitStep() {
      if (controller.isClosed) return;

      final safeIdx = currentIndex.clamp(0, waypoints.length - 1);
      final currentPt = waypoints[safeIdx];
      final nextPt = (safeIdx < waypoints.length - 1) ? waypoints[safeIdx + 1] : currentPt;

      final double heading = calculateBearing(
        lat1: currentPt[0],
        lon1: currentPt[1],
        lat2: nextPt[0],
        lon2: nextPt[1],
      );

      final double distance = calculateDistanceKm(
        lat1: currentPt[0],
        lon1: currentPt[1],
        lat2: destLat,
        lon2: destLng,
      );

      final int eta = max(1, (distance * 2.8).ceil());
      final bool arrived = safeIdx >= waypoints.length - 1;

      final update = MechanicLocationUpdate(
        requestId: requestId,
        mechanicId: mechanicId,
        mechanicName: mechanicName,
        mechanicPhone: mechanicPhone,
        motorcyclePlate: motorcyclePlate,
        motorcycleModel: motorcycleModel,
        workshopName: workshopName,
        latitude: currentPt[0],
        longitude: currentPt[1],
        heading: heading,
        speedKmh: arrived ? 0.0 : (32.0 + (safeIdx % 3) * 4.5),
        distanceKm: double.parse(distance.toStringAsFixed(2)),
        etaMinutes: arrived ? 0 : eta,
        timestamp: DateTime.now(),
        statusMessage: arrived
            ? 'Montir telah tiba di titik temu'
            : (distance < 0.4
                ? 'Montir sudah sangat dekat di sekitar lokasi Anda'
                : 'Montir sedang meluncur menuju titik penjemputan'),
        routeWaypoints: waypoints.sublist(safeIdx),
      );

      _latestUpdates[requestId] = update;
      controller.add(update);
    }

    // Emit posisi awal segera agar UI/listener langsung menerima titik pertama
    Future.microtask(emitStep);

    // Ambil rute jalan OSRM aktual di background dan update waypoints secara mulus
    fetchOsrmRoadRoute(
      startLat: originLat,
      startLng: originLng,
      destLat: destLat,
      destLng: destLng,
    ).then((roadPts) {
      if (!controller.isClosed && roadPts.length >= 2) {
        final double progressFraction = currentIndex / max(1, waypoints.length - 1);
        waypoints = roadPts;
        currentIndex = (progressFraction * (waypoints.length - 1)).round().clamp(0, waypoints.length - 1);
        emitStep();
      }
    });

    // Gerakkan motor mulus setiap 1 detik di sepanjang rute jalan raya
    _activeTimers[requestId]?.cancel();
    _activeTimers[requestId] = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentIndex < waypoints.length - 1) {
        currentIndex++;
        emitStep();
      } else {
        timer.cancel();
      }
    });

    return controller.stream;
  }

  /// Aktifkan siaran GPS montir (dipanggil oleh aplikasi montir)
  Future<void> startBroadcastingLocation({
    required String requestId,
    required String mechanicId,
  }) async {
    _broadcastingMechanics.add(requestId);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((position) {
            final prev = _latestUpdates[requestId];
            final heading = prev != null
                ? calculateBearing(
                    lat1: prev.latitude,
                    lon1: prev.longitude,
                    lat2: position.latitude,
                    lon2: position.longitude,
                  )
                : position.heading;

            final update = (prev ??
                    MechanicLocationUpdate(
                      requestId: requestId,
                      mechanicId: mechanicId,
                      mechanicName: 'Montir Mitra',
                      latitude: position.latitude,
                      longitude: position.longitude,
                      heading: heading,
                      distanceKm: 0.5,
                      etaMinutes: 2,
                      timestamp: DateTime.now(),
                    ))
                .copyWith(
              latitude: position.latitude,
              longitude: position.longitude,
              heading: heading,
              speedKmh: position.speed * 3.6,
              timestamp: DateTime.now(),
              isBroadcasting: true,
            );

            _latestUpdates[requestId] = update;
            if (_controllers.containsKey(requestId) && !_controllers[requestId]!.isClosed) {
              _controllers[requestId]!.add(update);
            }
          });
        }
      }
    } catch (_) {
      // Fallback ke rute perkotaan
    }
  }

  /// Hentikan siaran GPS montir
  void stopBroadcastingLocation(String requestId) {
    _broadcastingMechanics.remove(requestId);
    _activeTimers[requestId]?.cancel();
  }

  /// Status apakah montir sedang membagikan lokasi aktif
  bool isBroadcasting(String requestId) =>
      _broadcastingMechanics.contains(requestId);

  /// Dapatkan posisi terakhir yang tercatat
  MechanicLocationUpdate? getLatestLocation(String requestId) =>
      _latestUpdates[requestId];

  void dispose() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    for (final c in _controllers.values) {
      c.close();
    }
    _activeTimers.clear();
    _controllers.clear();
    _latestUpdates.clear();
  }
}

/// Provider singleton LiveTrackingService
final liveTrackingServiceProvider = Provider<LiveTrackingService>((ref) {
  final service = LiveTrackingService();
  ref.onDispose(service.dispose);
  return service;
});

/// Stream provider lokasi real-time montir berdasarkan ID permintaan
final mechanicLiveLocationStreamProvider = StreamProvider.family
    .autoDispose<MechanicLocationUpdate, ({String requestId, double destLat, double destLng, String? mechanicName, String? mechanicPhone})>(
        (ref, params) {
  final service = ref.watch(liveTrackingServiceProvider);
  return service.watchMechanicLocation(
    requestId: params.requestId,
    destLat: params.destLat,
    destLng: params.destLng,
    mechanicName: params.mechanicName ?? 'Bang Rudi Pratama',
    mechanicPhone: params.mechanicPhone ?? '081269112201',
  );
});

/// Provider status sharing GPS montir
final mechanicIsBroadcastingProvider = StateProvider.family<bool, String>((ref, requestId) {
  final service = ref.watch(liveTrackingServiceProvider);
  return service.isBroadcasting(requestId);
});
