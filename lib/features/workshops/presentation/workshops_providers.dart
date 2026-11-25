import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/config/env.dart';
import '../../../core/services/maps_places_service.dart';
import '../../../core/services/user_location_service.dart';
import '../data/hybrid_workshop_repository.dart';
import '../data/mock_workshop_repository.dart';
import '../domain/workshop.dart';
import '../domain/workshop_repository.dart';

/// Data koordinat pengguna saat ini
class UserLocation {
  final double latitude;
  final double longitude;

  const UserLocation({
    required this.latitude,
    required this.longitude,
  });
}

/// Provider repositori bengkel
final workshopRepositoryProvider = Provider<WorkshopRepository>((ref) {
  if (AppEnv.useMock) {
    return MockWorkshopRepository();
  }
  final placesService = ref.watch(mapsPlacesServiceProvider);
  return HybridWorkshopRepository(placesService: placesService);
});

/// Query pencarian nama atau alamat bengkel
final workshopSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// Filter kota/kabupaten bengkel yang dipilih (default 'Semua')
final workshopSelectedCityProvider = StateProvider<String>((ref) {
  return 'Semua';
});

/// Provider lokasi GPS pengguna (hanya bila izin aktif, tanpa memaksakan error)
final userLocationProvider = FutureProvider<UserLocation?>((ref) async {
  final globalLocation = ref.watch(globalUserLocationProvider);
  if (globalLocation.latitude != null && globalLocation.longitude != null) {
    return UserLocation(
      latitude: globalLocation.latitude!,
      longitude: globalLocation.longitude!,
    );
  }

  try {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    final LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final Position pos = await Geolocator.getCurrentPosition(
      timeLimit: const Duration(seconds: 4),
    );
    return UserLocation(latitude: pos.latitude, longitude: pos.longitude);
  } catch (_) {
    return null;
  }
});

/// Provider daftar bengkel terverifikasi aktif
final workshopsListProvider = FutureProvider<List<Workshop>>((ref) async {
  final repository = ref.watch(workshopRepositoryProvider);
  final city = ref.watch(workshopSelectedCityProvider);
  final query = ref.watch(workshopSearchQueryProvider);
  final userLoc = ref.watch(globalUserLocationProvider);

  return repository.getWorkshops(
    cityOrRegency: city,
    query: query,
    latitude: userLoc.latitude,
    longitude: userLoc.longitude,
  );
});

/// Provider detail bengkel berdasarkan ID
final workshopDetailProvider =
    FutureProvider.family<Workshop?, String>((ref, id) async {
  final repository = ref.watch(workshopRepositoryProvider);
  return repository.getWorkshopById(id);
});
