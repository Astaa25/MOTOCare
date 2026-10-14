import 'tutorial.dart';

/// Kontrak repositori tutorial mandiri sesuai PRD Bagian 6 & 7 (M6)
abstract class TutorialRepository {
  /// Mengambil daftar tutorial aktif, dapat difilter berdasarkan topik dan kata kunci pencarian
  Future<List<Tutorial>> getTutorials({
    String? topic,
    String? query,
  });

  /// Mengambil detail tutorial berdasarkan id
  Future<Tutorial?> getTutorialById(String id);
}
