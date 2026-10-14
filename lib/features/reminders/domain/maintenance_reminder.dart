import 'reminder_rules.dart';
import 'reminder_status.dart';

/// Entitas domain pengingat servis (Maintenance Reminder) sesuai PRD Bagian 5 & 6
class MaintenanceReminder {
  final String id;
  final String motorcycleId;
  final String userId;
  final String title;
  final String? serviceType;
  final DateTime? reminderDate;
  final int? targetMileage;
  final int? intervalKm;
  final int? intervalMonths;
  final StoredReminderStatus status;
  final DateTime? completedAt;
  final DateTime createdAt;

  const MaintenanceReminder({
    required this.id,
    required this.motorcycleId,
    required this.userId,
    required this.title,
    this.serviceType,
    this.reminderDate,
    this.targetMileage,
    this.intervalKm,
    this.intervalMonths,
    this.status = StoredReminderStatus.active,
    this.completedAt,
    required this.createdAt,
  });

  /// Status dinamis berdasarkan kilometer motor saat ini dan tanggal hari ini
  ReminderStatus computeStatus(int currentMileage, [DateTime? today]) {
    return computeReminderStatus(
      status: status,
      reminderDate: reminderDate,
      targetMileage: targetMileage,
      currentMileage: currentMileage,
      today: today ?? DateTime.now(),
    );
  }

  /// Apakah pengingat ini sudah selesai
  bool get isCompleted => status == StoredReminderStatus.completed;

  MaintenanceReminder copyWith({
    String? id,
    String? motorcycleId,
    String? userId,
    String? title,
    String? serviceType,
    DateTime? reminderDate,
    int? targetMileage,
    int? intervalKm,
    int? intervalMonths,
    StoredReminderStatus? status,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return MaintenanceReminder(
      id: id ?? this.id,
      motorcycleId: motorcycleId ?? this.motorcycleId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      serviceType: serviceType ?? this.serviceType,
      reminderDate: reminderDate ?? this.reminderDate,
      targetMileage: targetMileage ?? this.targetMileage,
      intervalKm: intervalKm ?? this.intervalKm,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'motorcycle_id': motorcycleId,
      'user_id': userId,
      'title': title,
      if (serviceType != null) 'service_type': serviceType,
      if (reminderDate != null)
        'reminder_date':
            '${reminderDate!.year.toString().padLeft(4, '0')}-${reminderDate!.month.toString().padLeft(2, '0')}-${reminderDate!.day.toString().padLeft(2, '0')}',
      if (targetMileage != null) 'target_mileage': targetMileage,
      if (intervalKm != null) 'interval_km': intervalKm,
      if (intervalMonths != null) 'interval_months': intervalMonths,
      'status': status.dbValue,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MaintenanceReminder.fromJson(Map<String, dynamic> json) {
    return MaintenanceReminder(
      id: json['id'] as String,
      motorcycleId: (json['motorcycle_id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      serviceType: json['service_type'] as String?,
      reminderDate: json['reminder_date'] != null
          ? DateTime.parse(json['reminder_date'] as String)
          : null,
      targetMileage: json['target_mileage'] as int?,
      intervalKm: json['interval_km'] as int?,
      intervalMonths: json['interval_months'] as int?,
      status: StoredReminderStatus.fromString((json['status'] ?? 'active') as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceReminder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          motorcycleId == other.motorcycleId &&
          title == other.title &&
          status == other.status &&
          targetMileage == other.targetMileage &&
          reminderDate == other.reminderDate;

  @override
  int get hashCode =>
      id.hashCode ^
      motorcycleId.hashCode ^
      title.hashCode ^
      status.hashCode ^
      targetMileage.hashCode ^
      reminderDate.hashCode;
}
