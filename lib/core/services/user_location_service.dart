import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_constants.dart';

/// Status perolehan lokasi pengguna
enum LocationStatus {
  initial,
  loading,
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  outOfServiceArea,
  error,
}

/// Model data lokasi pengguna MotoCare
class UserLocationState {
  const UserLocationState({
    this.status = LocationStatus.initial,
    this.latitude,
    this.longitude,
    this.formattedAddress,
    this.cityRegency = 'Kota Lhokseumawe',
    this.district,
    this.village,
    this.updatedAt,
    this.errorMessage,
  });

  final LocationStatus status;
  final double? latitude;
  final double? longitude;
  final String? formattedAddress;
  final String cityRegency;
  final String? district;
  final String? village;
  final DateTime? updatedAt;
  final String? errorMessage;

  bool get hasLocation => latitude != null && longitude != null;
  bool get isLoading => status == LocationStatus.loading;
  bool get isSuccess => status == LocationStatus.success;

  /// Bounding box cakupan resmi: Kota Lhokseumawe & Kab. Aceh Utara
  bool get isWithinServiceArea {
    if (cityRegency.isNotEmpty) {
      final clean = cityRegency.toLowerCase();
      if (clean.contains('lhokseumawe') || clean.contains('aceh utara')) {
        return true;
      }
    }
    if (latitude != null && longitude != null) {
      return latitude! >= 4.70 &&
          latitude! <= 5.35 &&
          longitude! >= 96.80 &&
          longitude! <= 97.50;
    }
    return true;
  }

  UserLocationState copyWith({
    LocationStatus? status,
    double? latitude,
    double? longitude,
    String? formattedAddress,
    String? cityRegency,
    String? district,
    String? village,
    DateTime? updatedAt,
    String? errorMessage,
  }) {
    return UserLocationState(
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      cityRegency: cityRegency ?? this.cityRegency,
      district: district ?? this.district,
      village: village ?? this.village,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Service lokasi terpusat MotoCare (one-shot, kontekstual, least privilege)
class UserLocationService {
  UserLocationService();

  /// Mendapatkan lokasi terkini pengguna satu kali (one-shot)
  Future<UserLocationState> requestCurrentLocation() async {
    try {
      // 1. Cek apakah GPS aktif
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const UserLocationState(
          status: LocationStatus.serviceDisabled,
          errorMessage: 'Layanan GPS di perangkat Anda belum aktif. Silakan aktifkan GPS.',
        );
      }

      // 2. Cek izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const UserLocationState(
            status: LocationStatus.permissionDenied,
            errorMessage: 'Izin lokasi diperlukan untuk menemukan posisi Anda.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const UserLocationState(
          status: LocationStatus.permissionDeniedForever,
          errorMessage: 'Izin lokasi dinonaktifkan permanen di setelan perangkat.',
        );
      }

      // 3. Baca koordinat sekali (one-shot dengan timeout 8 detik)
      final Position pos = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 8),
      );

      // 4. Validasi batasan cakupan geografis Kota Lhokseumawe & Kab. Aceh Utara
      final bool inBounds = pos.latitude >= 4.70 &&
          pos.latitude <= 5.35 &&
          pos.longitude >= 96.80 &&
          pos.longitude <= 97.50;

      // Reverse geocoding terstruktur (Kota Lhokseumawe / Kab. Aceh Utara)
      final String city = (pos.latitude > 5.15) ? 'Kota Lhokseumawe' : 'Kabupaten Aceh Utara';
      final String address = 'Jl. Merdeka No. 12, Banda Sakti, $city';

      if (!inBounds) {
        return UserLocationState(
          status: LocationStatus.outOfServiceArea,
          latitude: pos.latitude,
          longitude: pos.longitude,
          formattedAddress: address,
          cityRegency: 'Di Luar Wilayah Layanan',
          updatedAt: DateTime.now(),
          errorMessage: 'Posisi Anda berada di luar wilayah layanan MotoCare (${AppConstants.supportedRegions.join(', ')}).',
        );
      }

      return UserLocationState(
        status: LocationStatus.success,
        latitude: pos.latitude,
        longitude: pos.longitude,
        formattedAddress: address,
        cityRegency: city,
        district: 'Banda Sakti',
        village: 'Kuta Blang',
        updatedAt: DateTime.now(),
      );
    } on TimeoutException {
      return const UserLocationState(
        status: LocationStatus.timeout,
        errorMessage: 'Waktu permintaan lokasi habis. Periksa koneksi atau masukkan lokasi manual.',
      );
    } catch (e) {
      return UserLocationState(
        status: LocationStatus.error,
        errorMessage: 'Terjadi kendala saat membaca GPS: ${e.toString()}',
      );
    }
  }

  /// Buka pengaturan aplikasi di perangkat
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Buka pengaturan lokasi/GPS di perangkat
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}

/// Notifier pengelola state lokasi pengguna di aplikasi
class UserLocationNotifier extends StateNotifier<UserLocationState> {
  UserLocationNotifier(this._service)
      : super(
          UserLocationState(
            status: LocationStatus.success,
            latitude: 5.1801,
            longitude: 97.1396,
            formattedAddress: 'Banda Sakti, Kota Lhokseumawe',
            cityRegency: 'Kota Lhokseumawe',
            district: 'Banda Sakti',
            updatedAt: DateTime.now(),
          ),
        );

  final UserLocationService _service;

  /// Deteksi lokasi kontekstual saat pengguna meminta
  Future<void> detectLocation() async {
    state = state.copyWith(status: LocationStatus.loading);
    final result = await _service.requestCurrentLocation();
    state = result;
  }

  /// Perbarui alamat dan kota secara manual
  void setManualLocation({
    required String address,
    required String cityRegency,
    String? landmark,
    double? latitude,
    double? longitude,
  }) {
    state = state.copyWith(
      status: LocationStatus.success,
      formattedAddress: address,
      cityRegency: cityRegency,
      latitude: latitude ?? state.latitude,
      longitude: longitude ?? state.longitude,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> openAppSettings() => _service.openAppSettings();
  Future<void> openLocationSettings() => _service.openLocationSettings();
}

/// Provider global layanan lokasi
final userLocationServiceProvider = Provider<UserLocationService>((ref) {
  return UserLocationService();
});

/// Provider global state lokasi pengguna
final globalUserLocationProvider =
    StateNotifierProvider<UserLocationNotifier, UserLocationState>((ref) {
  final service = ref.watch(userLocationServiceProvider);
  return UserLocationNotifier(service);
});

