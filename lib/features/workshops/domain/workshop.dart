/// Wilayah cakupan operasional resmi MotoCare sesuai PRD Bagian 2.2 & 5.1
class WorkshopCoverageAreas {
  const WorkshopCoverageAreas._();

  static const String lhokseumawe = 'Kota Lhokseumawe';
  static const String acehUtara = 'Kabupaten Aceh Utara';

  static const List<String> supportedAreas = <String>[
    lhokseumawe,
    acehUtara,
  ];

  static bool isSupportedArea(String area) {
    return supportedAreas.contains(area);
  }
}

/// Entitas Bengkel Terverifikasi sesuai PRD Bagian 5.1 (Tabel workshops)
class Workshop {
  final String id;
  final String name;
  final String address;
  final String cityOrRegency;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? openingHours;
  final double? rating;
  final bool? openNow;
  final List<String> services;
  final bool isActive;
  final String source;
  final DateTime? verifiedAt;
  final bool isDemo;
  final DateTime createdAt;

  const Workshop({
    required this.id,
    required this.name,
    required this.address,
    required this.cityOrRegency,
    this.latitude,
    this.longitude,
    this.phone,
    this.openingHours,
    this.rating,
    this.openNow,
    this.services = const <String>[],
    this.isActive = true,
    required this.source,
    this.verifiedAt,
    this.isDemo = false,
    required this.createdAt,
  });

  /// Bengkel terverifikasi bila verifiedAt tidak null atau berstatus demo sesuai RLS
  bool get isVerified => verifiedAt != null || isDemo;

  factory Workshop.fromJson(Map<String, dynamic> json) {
    final servicesRaw = json['services_offered'] ?? json['services'];
    return Workshop(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      cityOrRegency: (json['service_region'] ?? json['city_or_regency'] ?? 'Kota Lhokseumawe') as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: (json['phone_number'] ?? json['phone']) as String?,
      openingHours: (json['operating_hours'] ?? json['opening_hours']) as String?,
      rating: ((json['google_rating'] ?? json['rating']) as num?)?.toDouble(),
      openNow: json['open_now'] as bool?,
      services: servicesRaw != null
          ? List<String>.from(servicesRaw as List<dynamic>)
          : const <String>[],
      isActive: (json['is_active'] as bool?) ?? true,
      source: (json['source'] as String?) ?? 'Data Resmi',
      verifiedAt: json['is_verified_partner'] == true
          ? DateTime.now()
          : (json['verified_at'] != null
              ? DateTime.parse(json['verified_at'] as String)
              : null),
      isDemo: (json['is_simulation'] ?? json['is_demo'] ?? false) as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'address': address,
      'city_or_regency': cityOrRegency,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'opening_hours': openingHours,
      'rating': rating,
      'open_now': openNow,
      'services': services,
      'is_active': isActive,
      'source': source,
      'verified_at': verifiedAt?.toIso8601String(),
      'is_demo': isDemo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Workshop copyWith({
    String? id,
    String? name,
    String? address,
    String? cityOrRegency,
    double? latitude,
    double? longitude,
    String? phone,
    String? openingHours,
    double? rating,
    bool? openNow,
    List<String>? services,
    bool? isActive,
    String? source,
    DateTime? verifiedAt,
    bool? isDemo,
    DateTime? createdAt,
  }) {
    return Workshop(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      cityOrRegency: cityOrRegency ?? this.cityOrRegency,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      openingHours: openingHours ?? this.openingHours,
      rating: rating ?? this.rating,
      openNow: openNow ?? this.openNow,
      services: services ?? this.services,
      isActive: isActive ?? this.isActive,
      source: source ?? this.source,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      isDemo: isDemo ?? this.isDemo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
