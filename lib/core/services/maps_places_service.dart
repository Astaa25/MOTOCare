import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/workshops/data/mock_workshop_repository.dart';
import '../../features/workshops/domain/workshop.dart';
import '../config/env.dart';
import 'maps_cost_controller.dart';

/// Model saran tempat dari Places Autocomplete (New)
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    this.fullText,
    this.latitude,
    this.longitude,
    this.cityRegency = 'Kota Lhokseumawe',
  });

  final String placeId;
  final String mainText;
  final String secondaryText;
  final String? fullText;
  final double? latitude;
  final double? longitude;
  final String cityRegency;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      placeId: (json['placeId'] as String?) ?? (json['id'] as String?) ?? '',
      mainText: (json['mainText'] as String?) ?? (json['name'] as String?) ?? '',
      secondaryText: (json['secondaryText'] as String?) ??
          (json['formattedAddress'] as String?) ??
          '',
      fullText: json['text'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      cityRegency: (json['cityRegency'] as String?) ?? 'Kota Lhokseumawe',
    );
  }
}

/// Detail tempat lengkap dari Place Details
class PlaceDetailResult {
  const PlaceDetailResult({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.cityRegency,
    required this.latitude,
    required this.longitude,
    this.landmark,
    this.phoneNumber,
    this.rating,
    this.openNow,
    this.openingHours,
  });

  final String placeId;
  final String name;
  final String formattedAddress;
  final String cityRegency;
  final double latitude;
  final double longitude;
  final String? landmark;
  final String? phoneNumber;
  final double? rating;
  final bool? openNow;
  final String? openingHours;

  factory PlaceDetailResult.fromJson(Map<String, dynamic> json) {
    String? openHours;
    if (json['weekdayDescriptions'] is List) {
      openHours = (json['weekdayDescriptions'] as List).join(', ');
    } else if (json['openingHours'] is String) {
      openHours = json['openingHours'] as String;
    }

    return PlaceDetailResult(
      placeId: (json['id'] as String?) ?? (json['placeId'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Lokasi Terpilih',
      formattedAddress: (json['formattedAddress'] as String?) ?? '',
      cityRegency: (json['cityRegency'] as String?) ?? 'Kota Lhokseumawe',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 5.1801,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 97.1396,
      landmark: json['landmark'] as String?,
      phoneNumber: (json['phoneNumber'] as String?) ??
          (json['nationalPhoneNumber'] as String?),
      rating: (json['rating'] as num?)?.toDouble(),
      openNow: json['openNow'] as bool?,
      openingHours: openHours,
    );
  }
}

/// Service klien Google Maps Places (Autocomplete & Details) dengan proteksi biaya
class MapsPlacesService {
  MapsPlacesService({
    required this.costController,
    SupabaseClient? supabaseClient,
  }) : _supabase = supabaseClient;

  final MapsCostController costController;
  final SupabaseClient? _supabase;

  /// Daftar tempat representatif Kota Lhokseumawe & Kab. Aceh Utara (fallback offline/demo)
  static const List<PlaceDetailResult> _demoPlaces = <PlaceDetailResult>[
    PlaceDetailResult(
      placeId: 'demo-place-1',
      name: 'Masjid Agung Islamic Center Lhokseumawe',
      formattedAddress: 'Jl. Merdeka No. 1, Simpang Empat, Banda Sakti, Kota Lhokseumawe',
      cityRegency: 'Kota Lhokseumawe',
      latitude: 5.1804,
      longitude: 97.1432,
      landmark: 'Depan gerbang utama Islamic Center',
    ),
    PlaceDetailResult(
      placeId: 'demo-place-2',
      name: 'Taman Riyadhah Lhokseumawe',
      formattedAddress: 'Jl. Merdeka Barat, Kuta Blang, Banda Sakti, Kota Lhokseumawe',
      cityRegency: 'Kota Lhokseumawe',
      latitude: 5.1788,
      longitude: 97.1402,
      landmark: 'Samping lapangan Hiraq',
    ),
    PlaceDetailResult(
      placeId: 'demo-place-3',
      name: 'Waduk Jeulikat Lhokseumawe',
      formattedAddress: 'Gampong Jeulikat, Blang Mangat, Kota Lhokseumawe',
      cityRegency: 'Kota Lhokseumawe',
      latitude: 5.1482,
      longitude: 97.1350,
      landmark: 'Area parkir wisata waduk',
    ),
    PlaceDetailResult(
      placeId: 'demo-place-4',
      name: 'Simpang Cunda Plaza',
      formattedAddress: 'Jl. Medan - Banda Aceh, Cunda, Muara Dua, Kota Lhokseumawe',
      cityRegency: 'Kota Lhokseumawe',
      latitude: 5.1672,
      longitude: 97.1338,
      landmark: 'Dekat jembatan Cunda & SPBU',
    ),
    PlaceDetailResult(
      placeId: 'demo-place-5',
      name: 'Simpang Pupuk Iskandar Muda (PIM)',
      formattedAddress: 'Krueng Geukueh, Dewantara, Kabupaten Aceh Utara',
      cityRegency: 'Kabupaten Aceh Utara',
      latitude: 5.2420,
      longitude: 97.0210,
      landmark: 'Pintu gerbang PT PIM',
    ),
    PlaceDetailResult(
      placeId: 'demo-place-6',
      name: 'Pusat Pasar Lhoksukon',
      formattedAddress: 'Jl. Perdagangan, Kota Lhoksukon, Kabupaten Aceh Utara',
      cityRegency: 'Kabupaten Aceh Utara',
      latitude: 5.0450,
      longitude: 97.3180,
      landmark: 'Depan Masjid Agung Baiturrahim Lhoksukon',
    ),
    PlaceDetailResult(
      placeId: 'demo-place-7',
      name: 'Pantai Ujong Blang',
      formattedAddress: 'Gampong Ujong Blang, Banda Sakti, Kota Lhokseumawe',
      cityRegency: 'Kota Lhokseumawe',
      latitude: 5.1910,
      longitude: 97.1610,
      landmark: 'Pondok wisata pinggir pantai',
    ),
  ];

  /// Mencari saran lokasi otomatis dengan debounce, session token, dan cache
  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final String clean = query.trim();
    if (clean.length < MapsCostController.minQueryLength) {
      return <PlaceSuggestion>[];
    }

    // 1. Cek Memory Cache jangka pendek (hemat kuota & tanggap offline)
    final String cacheKey = 'autocomplete_${clean.toLowerCase()}';
    final cached = costController.cache.get<List<PlaceSuggestion>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    final String sessionToken = costController.sessionTokenManager.getOrCreateToken();

    // 2. Jika backend Supabase siap dan tidak dalam mode mock murni, panggil Edge Function proxy
    if (AppEnv.isSupabaseConfigured && _supabase != null) {
      try {
        final res = await _supabase.functions.invoke(
          'maps-proxy',
          body: <String, dynamic>{
            'action': 'autocomplete',
            'input': clean,
            'sessionToken': sessionToken,
          },
        );

        if (res.status == 200 && res.data != null) {
          final data = (res.data is String) ? jsonDecode(res.data as String) : res.data;
          final List<dynamic> list = (data['suggestions'] as List<dynamic>?) ?? <dynamic>[];
          final suggestions = list
              .take(MapsCostController.maxAutocompleteResults)
              .map((s) => PlaceSuggestion.fromJson(s as Map<String, dynamic>))
              .toList();

          costController.cache.set(cacheKey, suggestions);
          return suggestions;
        }
      } catch (_) {
        // Fallback otomatis ke data representatif lokal saat offline / proxy gagal
      }
    }

    // 3. Fallback cerdas representatif wilayah Lhokseumawe & Aceh Utara
    final filtered = _demoPlaces.where((p) {
      final q = clean.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.formattedAddress.toLowerCase().contains(q) ||
          p.cityRegency.toLowerCase().contains(q);
    }).take(MapsCostController.maxAutocompleteResults).map((p) {
      return PlaceSuggestion(
        placeId: p.placeId,
        mainText: p.name,
        secondaryText: p.formattedAddress,
        cityRegency: p.cityRegency,
        latitude: p.latitude,
        longitude: p.longitude,
      );
    }).toList();

    costController.cache.set(cacheKey, filtered);
    return filtered;
  }

  /// Mengambil rincian detail tempat berdasarkan placeId
  Future<PlaceDetailResult?> getPlaceDetails(String placeId) async {
    // 1. Cek cache
    final String cacheKey = 'details_$placeId';
    final cached = costController.cache.get<PlaceDetailResult>(cacheKey);
    if (cached != null) {
      costController.sessionTokenManager.consumeToken();
      return cached;
    }

    final String sessionToken = costController.sessionTokenManager.getOrCreateToken();

    // 2. Panggil proxy jika Supabase aktif
    if (AppEnv.isSupabaseConfigured && _supabase != null) {
      try {
        final res = await _supabase.functions.invoke(
          'maps-proxy',
          body: <String, dynamic>{
            'action': 'place-details',
            'placeId': placeId,
            'sessionToken': sessionToken,
          },
        );

        if (res.status == 200 && res.data != null) {
          final data = (res.data is String) ? jsonDecode(res.data as String) : res.data;
          final placeMap = data['place'] as Map<String, dynamic>?;
          if (placeMap != null) {
            final result = PlaceDetailResult.fromJson(placeMap);
            costController.cache.set(cacheKey, result);
            costController.sessionTokenManager.consumeToken();
            return result;
          }
        }
      } catch (_) {
        // Fallback ke daftar demo
      }
    }

    // 3. Fallback demo data
    try {
      final found = _demoPlaces.firstWhere((p) => p.placeId == placeId);
      costController.cache.set(cacheKey, found);
      costController.sessionTokenManager.consumeToken();
      return found;
    } catch (_) {
      costController.sessionTokenManager.consumeToken();
      return null;
    }
  }

  /// Mencari bengkel motor via Google Places API (New) dengan batas wilayah Kota Lhokseumawe & Kab. Aceh Utara
  Future<List<Workshop>> searchWorkshops({
    String? query,
    String? cityOrRegency,
    double? latitude,
    double? longitude,
  }) async {
    final String clean = (query ?? '').trim();
    final String city = (cityOrRegency ?? 'Semua').trim();

    // 1. Cek cache memori (TTL 10 menit untuk perlindungan kuota)
    final String cacheKey =
        'workshops_${clean.toLowerCase()}_${city.toLowerCase()}_${latitude?.toStringAsFixed(2)}_${longitude?.toStringAsFixed(2)}';
    final cached = costController.cache.get<List<Workshop>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    // 2. Jika Supabase aktif, panggil Edge Function proxy
    if (AppEnv.isSupabaseConfigured && _supabase != null) {
      try {
        final res = await _supabase.functions.invoke(
          'maps-proxy',
          body: <String, dynamic>{
            'action': 'search-workshops',
            'query': clean.isNotEmpty ? clean : 'bengkel motor',
            'latitude': latitude,
            'longitude': longitude,
          },
        );

        if (res.status == 200 && res.data != null) {
          final data = (res.data is String) ? jsonDecode(res.data as String) : res.data;
          final List<dynamic> places = (data['places'] as List<dynamic>?) ?? <dynamic>[];

          final List<Workshop> results = <Workshop>[];
          for (final p in places) {
            final map = p as Map<String, dynamic>;
            final double? lat = (map['latitude'] as num?)?.toDouble();
            final double? lng = (map['longitude'] as num?)?.toDouble();

            // Batasi ke wilayah cakupan Lhokseumawe & Aceh Utara
            if (lat != null && lng != null) {
              if (lat < 4.70 || lat > 5.35 || lng < 96.80 || lng > 97.50) {
                continue;
              }
            }

            final String addr = (map['formattedAddress'] as String?) ?? 'Lhokseumawe & Aceh Utara';
            final String assignedCity = addr.toLowerCase().contains('aceh utara')
                ? WorkshopCoverageAreas.acehUtara
                : WorkshopCoverageAreas.lhokseumawe;

            if (city != 'Semua' && city != 'Semua Wilayah') {
              if (city == WorkshopCoverageAreas.acehUtara && assignedCity != WorkshopCoverageAreas.acehUtara) {
                continue;
              }
              if (city == WorkshopCoverageAreas.lhokseumawe && assignedCity != WorkshopCoverageAreas.lhokseumawe) {
                continue;
              }
            }

            results.add(
              Workshop(
                id: (map['id'] as String?) ?? '',
                name: (map['name'] as String?) ?? 'Bengkel Motor',
                address: addr,
                cityOrRegency: assignedCity,
                latitude: lat,
                longitude: lng,
                phone: map['phoneNumber'] as String?,
                openingHours: map['openNow'] == true
                    ? 'Buka Sekarang'
                    : (map['openNow'] == false ? 'Tutup' : null),
                rating: (map['rating'] as num?)?.toDouble(),
                openNow: map['openNow'] as bool?,
                services: const <String>[
                  'Servis Rutin',
                  'Ganti Oli',
                  'Tune Up',
                  'Tambal Ban',
                ],
                isActive: true,
                source: 'Google Maps Platform',
                verifiedAt: null, // Tanpa klaim palsu verifikasi untuk data Places
                isDemo: false,
                createdAt: DateTime.now(),
              ),
            );
          }

          if (results.isNotEmpty) {
            costController.cache.set(cacheKey, results, ttl: const Duration(minutes: 10));
            return results;
          }
        }
      } catch (_) {
        // Fallback otomatis ke data demo jika offline / proxy bermasalah
      }
    }

    // 3. Fallback ke data demo berlabel MotoCare
    final fallbackList = await MockWorkshopRepository().getWorkshops(
      query: clean,
      cityOrRegency: city,
    );
    costController.cache.set(cacheKey, fallbackList, ttl: const Duration(minutes: 10));
    return fallbackList;
  }

  /// Mengambil rincian detail bengkel dari Place Details
  Future<Workshop?> getWorkshopDetails(String placeId) async {
    final detail = await getPlaceDetails(placeId);
    if (detail == null) return null;

    return Workshop(
      id: detail.placeId,
      name: detail.name,
      address: detail.formattedAddress,
      cityOrRegency: detail.cityRegency,
      latitude: detail.latitude,
      longitude: detail.longitude,
      phone: detail.phoneNumber,
      openingHours: detail.openingHours,
      rating: detail.rating,
      openNow: detail.openNow,
      services: const <String>[
        'Servis Berkala',
        'Ganti Oli & Sparepart',
        'Tune Up & Injeksi',
        'Perbaikan Rem & Rantai',
      ],
      isActive: true,
      source: 'Google Maps Platform',
      verifiedAt: null,
      isDemo: false,
      createdAt: DateTime.now(),
    );
  }
}

/// Provider MapsCostController terpusat
final mapsCostControllerProvider = Provider<MapsCostController>((ref) {
  final controller = MapsCostController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

/// Provider MapsPlacesService
final mapsPlacesServiceProvider = Provider<MapsPlacesService>((ref) {
  final controller = ref.watch(mapsCostControllerProvider);
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    client = null;
  }
  return MapsPlacesService(
    costController: controller,
    supabaseClient: client,
  );
});

