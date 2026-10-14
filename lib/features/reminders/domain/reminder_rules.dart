import '../../../core/config/app_constants.dart';
import 'maintenance_reminder.dart';
import 'reminder_status.dart';

/// Aturan bisnis murni untuk sistem pengingat servis MotoCare (PRD Bagian 6.3 & 6.4)
/// Tidak mengimpor Flutter UI agar dapat diuji murni secara unit test.

/// Fungsi kalkulasi status pengingat sesuai PRD 6.3
ReminderStatus computeReminderStatus({
  required StoredReminderStatus status,
  required DateTime? reminderDate,
  required int? targetMileage,
  required int currentMileage,
  required DateTime today,
}) {
  // Jika pengingat sudah ditandai selesai
  if (status == StoredReminderStatus.completed) {
    return ReminderStatus.completed;
  }

  // Normalisasi tanggal tanpa jam (00:00:00)
  final DateTime todayNormalized = DateTime(today.year, today.month, today.day);

  ReminderStatus? dateStatus;
  if (reminderDate != null) {
    final DateTime targetDateNormalized = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
    );

    if (todayNormalized.isAfter(targetDateNormalized)) {
      dateStatus = ReminderStatus.overdue;
    } else {
      final int diffDays = targetDateNormalized.difference(todayNormalized).inDays;
      if (diffDays <= AppConstants.reminderNearDays) {
        dateStatus = ReminderStatus.near;
      } else {
        dateStatus = ReminderStatus.scheduled;
      }
    }
  }

  ReminderStatus? mileageStatus;
  if (targetMileage != null) {
    if (currentMileage > targetMileage) {
      mileageStatus = ReminderStatus.overdue;
    } else {
      final int diffKm = targetMileage - currentMileage;
      if (diffKm <= AppConstants.reminderNearKm) {
        mileageStatus = ReminderStatus.near;
      } else {
        mileageStatus = ReminderStatus.scheduled;
      }
    }
  }

  // Jika kedua pemicu ada, ambil yang paling parah: overdue > near > scheduled
  if (dateStatus != null && mileageStatus != null) {
    if (dateStatus == ReminderStatus.overdue || mileageStatus == ReminderStatus.overdue) {
      return ReminderStatus.overdue;
    }
    if (dateStatus == ReminderStatus.near || mileageStatus == ReminderStatus.near) {
      return ReminderStatus.near;
    }
    return ReminderStatus.scheduled;
  }

  if (dateStatus != null) {
    return dateStatus;
  }

  if (mileageStatus != null) {
    return mileageStatus;
  }

  return ReminderStatus.scheduled;
}

/// Menambahkan jumlah bulan ke tanggal dengan penanganan aman tanggal akhir bulan
DateTime addMonths(DateTime date, int months) {
  int newYear = date.year;
  int newMonth = date.month + months;

  while (newMonth > 12) {
    newYear++;
    newMonth -= 12;
  }
  while (newMonth < 1) {
    newYear--;
    newMonth += 12;
  }

  final int daysInTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
  final int newDay = date.day > daysInTargetMonth ? daysInTargetMonth : date.day;

  return DateTime(newYear, newMonth, newDay, date.hour, date.minute, date.second);
}

/// Membuat pengingat berikutnya secara otomatis saat servis dicatat (PRD Bagian 6.4)
MaintenanceReminder createNextReminder({
  required MaintenanceReminder currentReminder,
  required int serviceMileage,
  required DateTime serviceDate,
  required String newId,
}) {
  final int? nextTargetMileage = currentReminder.intervalKm != null
      ? serviceMileage + currentReminder.intervalKm!
      : null;

  final DateTime? nextReminderDate = currentReminder.intervalMonths != null
      ? addMonths(serviceDate, currentReminder.intervalMonths!)
      : null;

  return MaintenanceReminder(
    id: newId,
    motorcycleId: currentReminder.motorcycleId,
    userId: currentReminder.userId,
    title: currentReminder.title,
    serviceType: currentReminder.serviceType,
    reminderDate: nextReminderDate,
    targetMileage: nextTargetMileage,
    intervalKm: currentReminder.intervalKm,
    intervalMonths: currentReminder.intervalMonths,
    status: StoredReminderStatus.active,
    createdAt: DateTime.now(),
  );
}
