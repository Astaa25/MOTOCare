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
    this.isDemo = false,
    required this.createdAt,
  });

  factory Mechanic.fromJson(Map<String, dynamic> json) {
    return Mechanic(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      name: (json['name'] as String?) ??
          (json['profile'] != null
              ? (json['profile']['full_name'] as String?) ?? 'Mekanik'
              : 'Mekanik MotoCare'),
      phone: (json['phone'] as String?) ??
          (json['profile'] != null
              ? json['profile']['phone'] as String?
              : null),
      workshopId: json['workshop_id'] as String?,
      workshopName: json['workshop_name'] as String?,
      isAvailable: (json['is_available'] as bool?) ?? false,
      serviceArea: json['service_area'] as String?,
      isDemo: (json['is_demo'] as bool?) ?? false,
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
      isDemo: isDemo ?? this.isDemo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
