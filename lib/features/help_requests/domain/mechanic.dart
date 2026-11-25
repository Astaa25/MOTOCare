/// Entitas Mekanik sesuai PRD Bagian 5.1 (Tabel mechanics)
class Mechanic {
  final String id;
  final String profileId;
  final String name;
  final String? phone;
  final String? workshopId;
  final String? workshopName;
  final bool isAvailable;
  final String? serviceArea;
  final double? latitude;
  final double? longitude;
  final double? ratingAvg;
  final bool isDemo;
  final DateTime createdAt;

  const Mechanic({
    required this.id,
    required this.profileId,
    required this.name,
    this.phone,
    this.workshopId,
    this.workshopName,
    this.isAvailable = true,
    this.serviceArea,
    this.latitude,
    this.longitude,
    this.ratingAvg,
    this.isDemo = false,
    required this.createdAt,
  });

  factory Mechanic.fromJson(Map<String, dynamic> json) {
    final profileMap = json['profile'] as Map<String, dynamic>?;
    return Mechanic(
      id: (json['id'] ?? '') as String,
      profileId: (json['user_id'] ?? json['profile_id'] ?? '') as String,
      name: (json['full_name'] ??
              json['name'] ??
              profileMap?['full_name'] ??
              'Mekanik MotoCare') as String,
      phone: (json['phone_number'] ??
          json['phone'] ??
          profileMap?['phone_number'] ??
          profileMap?['phone']) as String?,
      workshopId: json['workshop_id'] as String?,
      workshopName: json['workshop_name'] as String?,
      isAvailable: (json['is_available'] as bool?) ?? false,
      serviceArea: json['service_area'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
      isDemo: (json['is_simulation'] ?? json['is_demo'] ?? false) as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'profile_id': profileId,
      'name': name,
      'phone': phone,
      'workshop_id': workshopId,
      'workshop_name': workshopName,
      'is_available': isAvailable,
      'service_area': serviceArea,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (ratingAvg != null) 'rating_avg': ratingAvg,
      'is_demo': isDemo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Mechanic copyWith({
    String? id,
    String? profileId,
    String? name,
    String? phone,
    String? workshopId,
    String? workshopName,
    bool? isAvailable,
    String? serviceArea,
    double? latitude,
    double? longitude,
    double? ratingAvg,
    bool? isDemo,
    DateTime? createdAt,
  }) {
    return Mechanic(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      workshopId: workshopId ?? this.workshopId,
      workshopName: workshopName ?? this.workshopName,
      isAvailable: isAvailable ?? this.isAvailable,
      serviceArea: serviceArea ?? this.serviceArea,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      isDemo: isDemo ?? this.isDemo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
