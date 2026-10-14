import 'dart:math' as math;

/// Aturan batas cakupan wilayah dan kalkulasi jarak bengkel sesuai PRD Bagian 2.2, 6, dan 7 (M6)
class WorkshopRules {
  const WorkshopRules._();

  /// Teks resmi kalimat cakupan wilayah permanen sesuai PRD 2.2 & 7 M6
  static const String permanentCoverageNotice =
      'Layanan dan bengkel terverifikasi saat ini hanya tersedia di Kota Lhokseumawe dan Kabupaten Aceh Utara.';

  /// Daftar nama wilayah populer di luar jangkauan operasional MotoCare
  /// (sesuai contoh pemeriksaan PRD 619: Banda Aceh, Medan, Jakarta, dll)
  static const List<String> outOfCoverageKeywords = <String>[
    'banda aceh',
    'medan',
    'jakarta',
    'surabaya',
    'bandung',
    'semarang',
    'yogyakarta',
    'jogja',
    'makassar',
    'palembang',
    'padang',
    'pekanbaru',
    'batam',
    'bireuen',
    'sigli',
    'pidie',
    'meulaboh',
    'aceh barat',
    'aceh timur',
    'aceh selatan',
    'aceh tengah',
    'takengon',
    'langsa',
    'subulussalam',
    'sabang',
    'kutacane',
  ];

  /// Memeriksa apakah kata kunci pencarian menunjuk ke wilayah di luar cakupan
  /// Mengembalikan true bila query menyebut kota/kabupaten di luar cakupan
  /// dan tidak menyebutkan wilayah operasional resmi.
  static bool isOutOfCoverageQuery(String query) {
    if (query.trim().isEmpty) return false;
    final clean = query.trim().toLowerCase();

    // Jika secara spesifik menyebutkan wilayah cakupan resmi, bukan out of coverage
    if (clean.contains('lhokseumawe') || clean.contains('aceh utara')) {
      return false;
    }

    // Periksa apakah cocok dengan salah satu kata kunci luar wilayah
    for (final keyword in outOfCoverageKeywords) {
      if (clean.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Menghitung jarak antara dua koordinat geografis dalam kilometer menggunakan Haversine Formula
  static double calculateHaversineDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degree) => degree * math.pi / 180.0;

  /// Memformat jarak untuk tampilan antarmuka
  /// Mengembalikan null bila koordinat bengkel atau pengguna tidak tersedia (Pencegahan Jarak Palsu)
  static String? formatDistance({
    required double? workshopLat,
    required double? workshopLon,
    required double? userLat,
    required double? userLon,
  }) {
    if (workshopLat == null ||
        workshopLon == null ||
        userLat == null ||
        userLon == null) {
      return null;
    }

    final double distanceKm = calculateHaversineDistanceKm(
      lat1: userLat,
      lon1: userLon,
      lat2: workshopLat,
      lon2: workshopLon,
    );

    if (distanceKm < 1.0) {
      final int meters = (distanceKm * 1000).round();
      return '$meters m';
    }

    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
