import 'mechanic.dart';
import 'request_status.dart';

/// Kategori masalah umum sepeda motor untuk panggilan montir
class CommonIssues {
  const CommonIssues._();

  static const String mesinMogok = 'Mesin Mogok';
  static const String banBocor = 'Ban Bocor / Kempes';
  static const String rantaiPutus = 'Rantai Putus / Lepas';
  static const String remBermasalah = 'Rem Blong / Macet';
  static const String kelistrikanAki = 'Kelistrikan / Aki Mati';
  static const String kunciStang = 'Kunci Kontak / Stang Macet';
  static const String lainnya = 'Masalah Lainnya';

  static const List<String> list = <String>[
    mesinMogok,
    banBocor,
    rantaiPutus,
    remBermasalah,
    kelistrikanAki,
    kunciStang,
    lainnya,
  ];
}

/// Entitas Permintaan Bantuan Mekanik sesuai PRD Bagian 5.1 (Tabel service_requests)
class ServiceRequest {
  final String id;
  final String userId;
  final String? mechanicId;
  final Mechanic? mechanic;
  final String? motorcycleId;
  final String? motorcycleName;
  final String issueCategory;
  final String issueDescription;
  final double? latitude;
  final double? longitude;
  final String addressText;
  final String cityRegency;
  final String? landmark;
  final String contactPhone;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime expiresAt;
  final bool isDemo;
  final String? idempotencyKey;

  const ServiceRequest({
    required this.id,
    required this.userId,
    this.mechanicId,
    this.mechanic,
    this.motorcycleId,
    this.motorcycleName,
    required this.issueCategory,
    required this.issueDescription,
    this.latitude,
    this.longitude,
    required this.addressText,
    this.cityRegency = 'Kota Lhokseumawe',
    this.landmark,
    required this.contactPhone,
    this.status = RequestStatus.pending,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    required this.expiresAt,
    this.isDemo = false,
    this.idempotencyKey,
  });

  /// Permintaan kedaluwarsa bila masih pending dan telah melewati batas expiresAt
  bool get isExpired {
    return status == RequestStatus.pending &&
        DateTime.now().isAfter(expiresAt);
  }

  /// Sisa waktu sebelum permintaan kedaluwarsa
  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      mechanicId: json['mechanic_id'] as String?,
      mechanic: json['mechanic'] != null
          ? Mechanic.fromJson(json['mechanic'] as Map<String, dynamic>)
          : null,
      motorcycleId: (json['vehicle_id'] ?? json['motorcycle_id']) as String?,
      motorcycleName: json['motorcycle_name'] as String?,
      issueCategory: (json['issue_category'] as String?) ?? CommonIssues.lainnya,
      issueDescription: (json['issue_description'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      addressText: (json['manual_address'] ?? json['address_text'] ?? '') as String,
      cityRegency: (json['city_regency'] as String?) ?? 'Kota Lhokseumawe',
      landmark: json['landmark'] as String?,
      contactPhone: (json['contact_phone'] ?? '') as String,
      status: RequestStatus.fromString((json['status'] as String?) ?? 'pending'),
      createdAt: json['requested_at'] != null
          ? DateTime.parse(json['requested_at'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(minutes: 15)),
      isDemo: (json['is_simulation'] ?? json['is_demo'] ?? false) as bool,
      idempotencyKey: json['idempotency_key'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'mechanic_id': mechanicId,
      if (mechanic != null) 'mechanic': mechanic!.toJson(),
      'motorcycle_id': motorcycleId,
      'motorcycle_name': motorcycleName,
      'issue_category': issueCategory,
      'issue_description': issueDescription,
      'latitude': latitude,
      'longitude': longitude,
      'address_text': addressText,
      'city_regency': cityRegency,
      if (landmark != null) 'landmark': landmark,
      'contact_phone': contactPhone,
      'status': status.dbValue,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_demo': isDemo,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
    };
  }

  ServiceRequest copyWith({
    String? id,
    String? userId,
    String? mechanicId,
    Mechanic? mechanic,
    String? motorcycleId,
    String? motorcycleName,
    String? issueCategory,
    String? issueDescription,
    double? latitude,
    double? longitude,
    String? addressText,
    String? cityRegency,
    String? landmark,
    String? contactPhone,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    bool? isDemo,
    String? idempotencyKey,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mechanicId: mechanicId ?? this.mechanicId,
      mechanic: mechanic ?? this.mechanic,
      motorcycleId: motorcycleId ?? this.motorcycleId,
      motorcycleName: motorcycleName ?? this.motorcycleName,
      issueCategory: issueCategory ?? this.issueCategory,
      issueDescription: issueDescription ?? this.issueDescription,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressText: addressText ?? this.addressText,
      cityRegency: cityRegency ?? this.cityRegency,
      landmark: landmark ?? this.landmark,
      contactPhone: contactPhone ?? this.contactPhone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isDemo: isDemo ?? this.isDemo,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    );
  }
}
