import '../../../core/utils/result.dart';
import 'maintenance_reminder.dart';

/// Antarmuka repositori pengingat servis (Maintenance Reminder)
abstract class MaintenanceReminderRepository {
  /// Mengambil daftar pengingat untuk motor tertentu
  Future<Result<List<MaintenanceReminder>>> getRemindersByMotorcycle(
    String motorcycleId,
  );

  /// Mengambil detail satu pengingat berdasarkan ID
  Future<Result<MaintenanceReminder>> getReminderById(String id);

  /// Menambahkan pengingat baru
  Future<Result<MaintenanceReminder>> addReminder(MaintenanceReminder reminder);

  /// Memperbarui pengingat yang ada
  Future<Result<MaintenanceReminder>> updateReminder(
    MaintenanceReminder reminder,
  );

  /// Menghapus pengingat
  Future<Result<void>> deleteReminder(String id);

  /// Menandai pengingat selesai dan otomatis membuat pengingat siklus berikutnya jika interval tersedia (PRD 6.4)
  Future<Result<MaintenanceReminder>> completeReminder(
    String id, {
    required int serviceMileage,
    required DateTime serviceDate,
  });

  /// Aliran data reaktif untuk pengingat motor
  Stream<List<MaintenanceReminder>> watchReminders(String motorcycleId);
}
