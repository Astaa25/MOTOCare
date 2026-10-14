import 'workshop.dart';

/// Kontrak repositori bengkel terverifikasi sesuai PRD Bagian 6 & 7 (M6)
abstract class WorkshopRepository {
  /// Mengambil daftar bengkel terverifikasi aktif dengan filter pencarian dan wilayah
  Future<List<Workshop>> getWorkshops({
    String? query,
    String? cityOrRegency,
    int page = 1,
    int limit = 20,
  });

  /// Mengambil detail satu bengkel berdasarkan id
  Future<Workshop?> getWorkshopById(String id);
}
