import '../domain/workshop.dart';
import '../domain/workshop_repository.dart';

/// Implementasi mock repositori bengkel terverifikasi dengan data demo sesuai PRD Bagian 5.5
class MockWorkshopRepository implements WorkshopRepository {
  final List<Workshop> _workshops = <Workshop>[
    // 3 Bengkel di Kota Lhokseumawe
    Workshop(
      id: 'ws-01',
      name: '[Demo] Bengkel Resmi Samudera Motor Lhokseumawe',
      address: 'Jl. Merdeka Barat No. 12, Banda Sakti, Kota Lhokseumawe',
      cityOrRegency: WorkshopCoverageAreas.lhokseumawe,
      latitude: 5.1801,
      longitude: 97.1405,
      phone: '081269000111',
      openingHours: '08:00 - 17:00 WIB',
      services: const <String>[
        'Servis Rutin',
        'Ganti Oli',
        'Tune Up',
        'Ganti Ban',
        'Kelistrikan',
      ],
      isActive: true,
      source: 'Data Simulasi MotoCare',
      verifiedAt: DateTime(2026, 10, 1),
      isDemo: true,
      createdAt: DateTime(2026, 10, 1),
    ),
    Workshop(
      id: 'ws-02',
      name: '[Demo] Bengkel Cipta Karya Motor Muara Dua',
      address: 'Jl. Medan - Banda Aceh Km. 274, Cunda, Kota Lhokseumawe',
      cityOrRegency: WorkshopCoverageAreas.lhokseumawe,
      latitude: 5.1672,
      longitude: 97.1320,
      phone: '081269000222',
      openingHours: '08:30 - 18:00 WIB',
      services: const <String>[
        'Servis Rutin',
        'Ganti Oli',
        'Servis Rem',
        'Cek Aki',
      ],
      isActive: true,
      source: 'Data Simulasi MotoCare',
      verifiedAt: DateTime(2026, 10, 1),
      isDemo: true,
      createdAt: DateTime(2026, 10, 1),
    ),
    Workshop(
      id: 'ws-03',
      name: '[Demo] Bengkel Presisi Motor Blang Mangat',
      address: 'Jl. Elak Simpang Kandang, Blang Mangat, Kota Lhokseumawe',
      cityOrRegency: WorkshopCoverageAreas.lhokseumawe,
      latitude: 5.1420,
      longitude: 97.1210,
      phone: '081269000333',
      openingHours: '08:00 - 17:30 WIB',
      services: const <String>[
        'Ganti Oli',
        'Servis Rantai',
        'Ganti Busi',
        'Tune Up',
      ],
      isActive: true,
      source: 'Data Simulasi MotoCare',
      verifiedAt: DateTime(2026, 10, 1),
      isDemo: true,
      createdAt: DateTime(2026, 10, 1),
    ),

    // 3 Bengkel di Kabupaten Aceh Utara
    Workshop(
      id: 'ws-04',
      name: '[Demo] Bengkel Barokah Motor Lhoksukon',
      address: 'Jl. Teuku Umar No. 45, Kota Lhoksukon, Kabupaten Aceh Utara',
      cityOrRegency: WorkshopCoverageAreas.acehUtara,
      latitude: 5.0450,
      longitude: 97.3180,
      phone: '081269000444',
      openingHours: '08:00 - 17:00 WIB',
      services: const <String>[
        'Servis Rutin',
        'Ganti Oli',
        'Bongkar Mesin',
        'Ganti Kampas Rem',
      ],
      isActive: true,
      source: 'Data Simulasi MotoCare',
      verifiedAt: DateTime(2026, 10, 1),
      isDemo: true,
      createdAt: DateTime(2026, 10, 1),
    ),
    Workshop(
      id: 'ws-05',
      name: '[Demo] Bengkel Panton Labu Mandiri Jaya',
      address:
          'Jl. Pasar Baru No. 18, Panton Labu, Tanah Jambo Aye, Kabupaten Aceh Utara',
      cityOrRegency: WorkshopCoverageAreas.acehUtara,
      latitude: 5.0120,
      longitude: 97.4850,
      phone: '081269000555',
      openingHours: '08:30 - 17:30 WIB',
      services: const <String>[
        'Servis Rutin',
        'Ganti Oli',
        'Servis Injeksi',
        'Ganti Ban',
      ],
      isActive: true,
      source: 'Data Simulasi MotoCare',
      verifiedAt: DateTime(2026, 10, 1),
      isDemo: true,
      createdAt: DateTime(2026, 10, 1),
    ),
    Workshop(
      id: 'ws-06',
      name: '[Demo] Bengkel Dewantara Prima Motor',
      address:
          'Jl. Pelabuhan Krueng Geukueh, Dewantara, Kabupaten Aceh Utara',
      cityOrRegency: WorkshopCoverageAreas.acehUtara,
      latitude: 5.2410,
      longitude: 97.0250,
      phone: '081269000666',
      openingHours: '08:00 - 18:00 WIB',
      services: const <String>[
        'Servis Rutin',
        'Ganti Oli',
        'Cek Kelistrikan',
        'Servis Rem & Rantai',
      ],
      isActive: true,
      source: 'Data Simulasi MotoCare',
      verifiedAt: DateTime(2026, 10, 1),
      isDemo: true,
      createdAt: DateTime(2026, 10, 1),
    ),
  ];

  @override
  Future<List<Workshop>> getWorkshops({
    String? query,
    String? cityOrRegency,
    int page = 1,
    int limit = 20,
  }) async {
    // Simulasi latensi ringan
    await Future<void>.delayed(const Duration(milliseconds: 60));

    // Filter RLS: hanya bengkel aktif dan terverifikasi/demo
    var results = _workshops.where((w) => w.isActive && w.isVerified).toList();

    // Filter wilayah
    if (cityOrRegency != null &&
        cityOrRegency.isNotEmpty &&
        cityOrRegency.toLowerCase() != 'semua') {
      results = results
          .where((w) =>
              w.cityOrRegency.toLowerCase() == cityOrRegency.toLowerCase())
          .toList();
    }

    // Filter query pencarian (nama atau alamat)
    if (query != null && query.trim().isNotEmpty) {
      final clean = query.trim().toLowerCase();
      results = results.where((w) {
        final nameMatch = w.name.toLowerCase().contains(clean);
        final addrMatch = w.address.toLowerCase().contains(clean);
        final cityMatch = w.cityOrRegency.toLowerCase().contains(clean);
        return nameMatch || addrMatch || cityMatch;
      }).toList();
    }

    // Pagination
    final startIndex = (page - 1) * limit;
    if (startIndex >= results.length) {
      return <Workshop>[];
    }
    final endIndex = (startIndex + limit).clamp(0, results.length);
    return results.sublist(startIndex, endIndex);
  }

  @override
  Future<Workshop?> getWorkshopById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    try {
      return _workshops.firstWhere((w) => w.id == id && w.isActive && w.isVerified);
    } catch (_) {
      return null;
    }
  }
}
