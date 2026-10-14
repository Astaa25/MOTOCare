import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/utils/result.dart';
import '../../motorcycles/presentation/motorcycle_providers.dart';
import '../../notifications/presentation/notifications_providers.dart';
import '../data/mock_maintenance_reminder_repository.dart';
import '../data/supabase_maintenance_reminder_repository.dart';
import '../domain/maintenance_reminder.dart';
import '../domain/maintenance_reminder_repository.dart';

/// Singleton mock repository agar data konsisten antar navigasi
final MockMaintenanceReminderRepository _mockReminderRepo =
    MockMaintenanceReminderRepository(populateDemoData: true);

/// Provider repositori pengingat servis
final reminderRepositoryProvider = Provider<MaintenanceReminderRepository>((ref) {
  if (AppEnv.useMock) {
    return _mockReminderRepo;
  }
  try {
    if (Supabase.instance.client.auth.currentSession != null) {
      return SupabaseMaintenanceReminderRepository();
    }
  } catch (_) {}
  return _mockReminderRepo;
});

/// Provider daftar mentah pengingat per motor
final remindersProvider = FutureProvider.family<List<MaintenanceReminder>, String>(
  (ref, motorcycleId) async {
    final repo = ref.watch(reminderRepositoryProvider);
    final res = await repo.getRemindersByMotorcycle(motorcycleId);

    if (res.isFailure) {
      throw res.exceptionOrNull!;
    }
    return res.dataOrNull ?? <MaintenanceReminder>[];
  },
);

/// Provider daftar pengingat terurut berdasarkan keparahan (PRD Bagian 7 M5):
/// Urutan: Overdue (0) -> Segera Servis/Near (1) -> Terjadwal/Scheduled (2) -> Selesai/Completed (3)
final sortedRemindersProvider =
    Provider.family<AsyncValue<List<MaintenanceReminder>>, String>(
  (ref, motorcycleId) {
    final remindersAsync = ref.watch(remindersProvider(motorcycleId));
    final motorAsync = ref.watch(motorcycleDetailProvider(motorcycleId));

    final int currentMileage = motorAsync.valueOrNull?.currentMileage ?? 0;
    final DateTime today = DateTime.now();

    return remindersAsync.whenData((list) {
      final sortedList = List<MaintenanceReminder>.from(list);
      sortedList.sort((a, b) {
        final statusA = a.computeStatus(currentMileage, today);
        final statusB = b.computeStatus(currentMileage, today);

        final int compareSeverity = statusA.severityOrder.compareTo(statusB.severityOrder);
        if (compareSeverity != 0) return compareSeverity;

        // Jika status keparahan sama, urutkan berdasarkan tanggal terdekat atau KM terendah
        if (a.reminderDate != null && b.reminderDate != null) {
          return a.reminderDate!.compareTo(b.reminderDate!);
        }
        if (a.targetMileage != null && b.targetMileage != null) {
          return a.targetMileage!.compareTo(b.targetMileage!);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return sortedList;
    });
  },
);

/// Provider pengingat servis terdekat / paling mendesak untuk kartu Beranda
final nearestReminderProvider =
    Provider.family<AsyncValue<MaintenanceReminder?>, String>(
  (ref, motorcycleId) {
    final sortedAsync = ref.watch(sortedRemindersProvider(motorcycleId));
    return sortedAsync.whenData((list) {
      // Ambil yang belum selesai dengan prioritas teratas
      final activeList = list.where((r) => !r.isCompleted).toList();
      return activeList.isNotEmpty ? activeList.first : null;
    });
  },
);

/// Provider detail satu pengingat
final reminderDetailProvider =
    FutureProvider.family<MaintenanceReminder, String>((ref, id) async {
  final repo = ref.watch(reminderRepositoryProvider);
  final res = await repo.getReminderById(id);
  if (res.isFailure) {
    throw res.exceptionOrNull!;
  }
  return res.dataOrNull!;
});

/// Notifier aksi CRUD & Selesai Pengingat
class RemindersNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  RemindersNotifier(this._ref) : super(const AsyncValue<void>.data(null));

  Future<Result<MaintenanceReminder>> addReminder(MaintenanceReminder reminder) async {
    state = const AsyncValue<void>.loading();
    final repo = _ref.read(reminderRepositoryProvider);
    final res = await repo.addReminder(reminder);

    if (res.isSuccess) {
      final notifService = _ref.read(notificationServiceProvider);
      await notifService.scheduleLocalReminder(res.dataOrNull!);

      _ref.invalidate(remindersProvider(reminder.motorcycleId));
      state = const AsyncValue<void>.data(null);
    } else {
      state = AsyncValue<void>.error(res.exceptionOrNull!, StackTrace.current);
    }
    return res;
  }

  Future<Result<MaintenanceReminder>> updateReminder(MaintenanceReminder reminder) async {
    state = const AsyncValue<void>.loading();
    final repo = _ref.read(reminderRepositoryProvider);
    final res = await repo.updateReminder(reminder);

    if (res.isSuccess) {
      final notifService = _ref.read(notificationServiceProvider);
      await notifService.cancelLocalReminder(reminder.id);
      await notifService.scheduleLocalReminder(res.dataOrNull!);

      _ref.invalidate(remindersProvider(reminder.motorcycleId));
      _ref.invalidate(reminderDetailProvider(reminder.id));
      state = const AsyncValue<void>.data(null);
    } else {
      state = AsyncValue<void>.error(res.exceptionOrNull!, StackTrace.current);
    }
    return res;
  }

  Future<Result<void>> deleteReminder(String id, String motorcycleId) async {
    state = const AsyncValue<void>.loading();
    final repo = _ref.read(reminderRepositoryProvider);
    final res = await repo.deleteReminder(id);

    if (res.isSuccess) {
      final notifService = _ref.read(notificationServiceProvider);
      await notifService.cancelLocalReminder(id);

      _ref.invalidate(remindersProvider(motorcycleId));
      state = const AsyncValue<void>.data(null);
    } else {
      state = AsyncValue<void>.error(res.exceptionOrNull!, StackTrace.current);
    }
    return res;
  }

  Future<Result<MaintenanceReminder>> completeReminder(
    String id,
    String motorcycleId, {
    required int serviceMileage,
    required DateTime serviceDate,
  }) async {
    state = const AsyncValue<void>.loading();
    final repo = _ref.read(reminderRepositoryProvider);
    final res = await repo.completeReminder(
      id,
      serviceMileage: serviceMileage,
      serviceDate: serviceDate,
    );

    if (res.isSuccess) {
      final notifService = _ref.read(notificationServiceProvider);
      await notifService.cancelLocalReminder(id);

      _ref.invalidate(remindersProvider(motorcycleId));
      _ref.invalidate(reminderDetailProvider(id));
      state = const AsyncValue<void>.data(null);
    } else {
      state = AsyncValue<void>.error(res.exceptionOrNull!, StackTrace.current);
    }
    return res;
  }
}

final remindersNotifierProvider =
    StateNotifierProvider<RemindersNotifier, AsyncValue<void>>(
  RemindersNotifier.new,
);
