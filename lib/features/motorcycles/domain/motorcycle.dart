import '../../../core/config/app_constants.dart';
import '../data/motorcycle_catalog.dart';

/// Model data sepeda motor sesuai skema tabel `vehicles` / `motorcycles` di PRD bagian 5.1 & M3
class Motorcycle {
  final String id;
  final String userId;
  final String brand;
  final String model;
  final int productionYear;
  final String? licensePlate;
  final int currentMileage;
  final DateTime mileageUpdatedAt;
  final String? color;
  final String? category;
  final int? engineCc;
  final String? transmission;
  final String? fuelType;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Motorcycle({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.productionYear,
    this.licensePlate,
    required this.currentMileage,
    required this.mileageUpdatedAt,
    this.color,
    this.category,
    this.engineCc,
    this.transmission,
    this.fuelType,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Nama lengkap gabungan merek dan model (contoh: "Honda Vario 160")
  String get name => '$brand $model';

  /// Spesifikasi katalog terotomasi bila atribut detail belum diisi manual
  MotorcycleCatalogSpec get catalogSpec => MotorcycleCatalog.findSpec(brand, model);

  String get resolvedPhotoPath =>
      (photoUrl != null && photoUrl!.trim().isNotEmpty)
          ? photoUrl!.trim()
          : catalogSpec.assetPath;

  String get resolvedColor =>
      (color != null && color!.trim().isNotEmpty)
          ? color!.trim()
          : catalogSpec.defaultColor;

  String get resolvedCategory =>
      (category != null && category!.trim().isNotEmpty)
          ? category!.trim()
          : catalogSpec.category;

  int get resolvedEngineCc =>
      (engineCc != null && engineCc! > 0) ? engineCc! : catalogSpec.engineCc;

  String get resolvedTransmission =>
      (transmission != null && transmission!.trim().isNotEmpty)
          ? transmission!.trim()
          : catalogSpec.transmission;

  String get resolvedFuelType =>
      (fuelType != null && fuelType!.trim().isNotEmpty)
          ? fuelType!.trim()
          : catalogSpec.fuelType;

  /// Apakah pembaruan kilometer sudah usang (> 30 hari) sesuai PRD 6.1 & 6.5
  bool get isMileageStale {
    final diff = DateTime.now().difference(mileageUpdatedAt);
    return diff.inDays >= AppConstants.mileageStaleDays;
  }

  Motorcycle copyWith({
    String? id,
    String? userId,
    String? brand,
    String? model,
    int? productionYear,
    String? licensePlate,
    int? currentMileage,
    DateTime? mileageUpdatedAt,
    String? color,
    String? category,
    int? engineCc,
    String? transmission,
    String? fuelType,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Motorcycle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      productionYear: productionYear ?? this.productionYear,
      licensePlate: licensePlate ?? this.licensePlate,
      currentMileage: currentMileage ?? this.currentMileage,
      mileageUpdatedAt: mileageUpdatedAt ?? this.mileageUpdatedAt,
      color: color ?? this.color,
      category: category ?? this.category,
      engineCc: engineCc ?? this.engineCc,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'brand': brand,
      'model': model,
      'production_year': productionYear,
      'license_plate': licensePlate?.toUpperCase().trim(),
      'current_mileage': currentMileage,
      'mileage_updated_at': mileageUpdatedAt.toIso8601String(),
      'color': color,
      'category': category,
      'engine_cc': engineCc,
      'transmission': transmission,
      'fuel_type': fuelType,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Motorcycle.fromJson(Map<String, dynamic> json) {
    final rawCc = json['engine_cc'] ?? json['engineCc'];
    return Motorcycle(
      id: json['id'] as String,
      userId: (json['owner_id'] ?? json['user_id'] ?? json['userId']) as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      productionYear: (json['production_year'] ?? json['productionYear']) as int,
      licensePlate: (json['license_plate'] ?? json['licensePlate']) as String?,
      currentMileage:
          (json['current_km'] ?? json['current_mileage'] ?? json['currentMileage'] ?? 0) as int,
      mileageUpdatedAt: json['mileage_updated_at'] != null
          ? DateTime.parse(json['mileage_updated_at'] as String)
          : (json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : DateTime.now()),
      color: json['color'] as String?,
      category: json['category'] as String?,
      engineCc: rawCc is num ? rawCc.toInt() : int.tryParse('${rawCc ?? ''}'),
      transmission: json['transmission'] as String?,
      fuelType: (json['fuel_type'] ?? json['fuelType']) as String?,
      photoUrl: (json['photo_url'] ?? json['photoUrl']) as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
