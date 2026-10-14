import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/config/env.dart';
import '../data/mock_workshop_repository.dart';
import '../data/supabase_workshop_repository.dart';
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
  return SupabaseWorkshopRepository();
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

  return repository.getWorkshops(
    cityOrRegency: city,
    query: query,
  );
});

/// Provider detail bengkel berdasarkan ID
final workshopDetailProvider =
    FutureProvider.family<Workshop?, String>((ref, id) async {
  final repository = ref.watch(workshopRepositoryProvider);
  return repository.getWorkshopById(id);
});
