/// Model riwayat servis dan pencatatan biaya MotoCare sesuai PRD bagian 5.1 & M4
class ServiceHistory {
  final String id;
  final String motorcycleId;
  final String userId;
  final DateTime serviceDate;
  final int mileage;
  final String serviceType;
  final String? description;
  final int cost;
  final String? workshopId;
  final String? workshopName;
  final DateTime createdAt;

  const ServiceHistory({
    required this.id,
    required this.motorcycleId,
    required this.userId,
    required this.serviceDate,
    required this.mileage,
    required this.serviceType,
    this.description,
    this.cost = 0,
    this.workshopId,
    this.workshopName,
    required this.createdAt,
  });

  ServiceHistory copyWith({
    String? id,
    String? motorcycleId,
    String? userId,
    DateTime? serviceDate,
    int? mileage,
    String? serviceType,
    String? description,
    int? cost,
    String? workshopId,
    String? workshopName,
    DateTime? createdAt,
  }) {
    return ServiceHistory(
      id: id ?? this.id,
      motorcycleId: motorcycleId ?? this.motorcycleId,
      userId: userId ?? this.userId,
      serviceDate: serviceDate ?? this.serviceDate,
      mileage: mileage ?? this.mileage,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      workshopId: workshopId ?? this.workshopId,
      workshopName: workshopName ?? this.workshopName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'motorcycle_id': motorcycleId,
      'user_id': userId,
      'service_date': serviceDate.toIso8601String().split('T').first,
      'mileage': mileage,
      'service_type': serviceType,
      'description': description,
      'cost': cost,
      'workshop_id': workshopId,
      'workshop_name': workshopName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ServiceHistory.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final dynamic rawDate = json['service_date'];
    if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else {
      parsedDate = DateTime.now();
    }

    DateTime parsedCreated;
    final dynamic rawCreated = json['created_at'];
    if (rawCreated is String) {
      parsedCreated = DateTime.parse(rawCreated);
    } else if (rawCreated is DateTime) {
      parsedCreated = rawCreated;
    } else {
      parsedCreated = DateTime.now();
    }

    final dynamic rawCost = json['total_cost'] ?? json['cost'];
    int parsedCost = 0;
    if (rawCost is num) {
      parsedCost = rawCost.toInt();
    } else if (rawCost is String) {
      parsedCost = int.tryParse(rawCost) ?? 0;
    }

    final dynamic rawMileage = json['km_at_service'] ?? json['mileage'];
    int parsedMileage = 0;
    if (rawMileage is num) {
      parsedMileage = rawMileage.toInt();
    } else if (rawMileage is String) {
      parsedMileage = int.tryParse(rawMileage) ?? 0;
    }

    return ServiceHistory(
      id: (json['id'] ?? '') as String,
      motorcycleId: (json['vehicle_id'] ?? json['motorcycle_id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      serviceDate: parsedDate,
      mileage: parsedMileage,
      serviceType: (json['service_type'] ?? 'Servis Berkala') as String,
      description: (json['work_description'] ?? json['description']) as String?,
      cost: parsedCost,
      workshopId: json['workshop_id'] as String?,
      workshopName: (json['custom_workshop_name'] ?? json['workshop_name']) as String?,
      createdAt: parsedCreated,
    );
  }
}
