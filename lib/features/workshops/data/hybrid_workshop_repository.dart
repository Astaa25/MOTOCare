import '../../../core/config/env.dart';
import '../../../core/services/maps_places_service.dart';
import '../domain/workshop.dart';
import '../domain/workshop_repository.dart';
import 'mock_workshop_repository.dart';
import 'supabase_workshop_repository.dart';

/// Implementasi repositori bengkel terintegrasi (Google Places API + Supabase / Mock Fallback)
/// sesuai panduan integrasi Google Maps Platform Tahap 4
class HybridWorkshopRepository implements WorkshopRepository {
  final MapsPlacesService placesService;
  final WorkshopRepository _fallbackRepository;

  HybridWorkshopRepository({
    required this.placesService,
    WorkshopRepository? fallbackRepository,
    MockWorkshopRepository? mockRepository,
  }) : _fallbackRepository = fallbackRepository ??
            mockRepository ??
            (AppEnv.useMock
                ? MockWorkshopRepository()
                : SupabaseWorkshopRepository());

  @override
  Future<List<Workshop>> getWorkshops({
    String? query,
    String? cityOrRegency,
    int page = 1,
    int limit = 20,
    double? latitude,
    double? longitude,
  }) async {
    // Mode mock murni: langsung delegasi ke fallback repository
    if (AppEnv.useMock) {
      return _fallbackRepository.getWorkshops(
        query: query,
        cityOrRegency: cityOrRegency,
        page: page,
        limit: limit,
      );
    }

    try {
      final results = await placesService.searchWorkshops(
        query: query,
        cityOrRegency: cityOrRegency,
        latitude: latitude,
        longitude: longitude,
      );

      if (results.isNotEmpty) {
        final startIndex = (page - 1) * limit;
        if (startIndex >= results.length) {
          return <Workshop>[];
        }
        final endIndex = (startIndex + limit).clamp(0, results.length);
        return results.sublist(startIndex, endIndex);
      }
    } catch (_) {
      // Fallback ke repository data bila gagal
    }

    return _fallbackRepository.getWorkshops(
      query: query,
      cityOrRegency: cityOrRegency,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<Workshop?> getWorkshopById(String id) async {
    if (id.startsWith('ws-') || AppEnv.useMock) {
      return _fallbackRepository.getWorkshopById(id);
    }

    try {
      final workshop = await placesService.getWorkshopDetails(id);
      if (workshop != null) return workshop;
    } catch (_) {}

    return _fallbackRepository.getWorkshopById(id);
  }
}
