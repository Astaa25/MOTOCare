import 'dart:async';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../domain/maintenance_reminder.dart';
import '../domain/maintenance_reminder_repository.dart';
import '../domain/reminder_rules.dart';
import '../domain/reminder_status.dart';

/// Implementasi mock in-memory untuk MaintenanceReminderRepository (PRD Bagian 7 M5)
class MockMaintenanceReminderRepository implements MaintenanceReminderRepository {
  final List<MaintenanceReminder> _reminders = <MaintenanceReminder>[];
  final StreamController<List<MaintenanceReminder>> _streamController =
      StreamController<List<MaintenanceReminder>>.broadcast();

  final bool simulateDelay;

  MockMaintenanceReminderRepository({
    this.simulateDelay = true,
    bool populateDemoData = true,
  }) {
    if (populateDemoData) {
      _seedDemoData();
    }
  }

  void _seedDemoData() {
    final DateTime now = DateTime.now();
    _reminders.addAll(<MaintenanceReminder>[
      MaintenanceReminder(
        id: 'demo-reminder-1',
        motorcycleId: 'demo-motor-1',
        userId: 'demo-user-1',
        title: 'Ganti Oli Mesin',
        serviceType: 'Ganti oli',
        reminderDate: now.add(const Duration(days: 35)),
        targetMileage: 15000,
        intervalKm: 3000,
        intervalMonths: 3,
        status: StoredReminderStatus.active,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      MaintenanceReminder(
        id: 'demo-reminder-2',
        motorcycleId: 'demo-motor-1',
        userId: 'demo-user-1',
        title: 'Cek Rem & Kampas',
        serviceType: 'Rem',
        reminderDate: now.subtract(const Duration(days: 2)), // Overdue demo
        intervalMonths: 1,
        status: StoredReminderStatus.active,
        createdAt: now.subtract(const Duration(days: 35)),
      ),
      MaintenanceReminder(
        id: 'demo-reminder-3',
        motorcycleId: 'demo-motor-1',
        userId: 'demo-user-1',
        title: 'Cek Tekanan Ban',
        serviceType: 'Ban',
        reminderDate: now.add(const Duration(days: 4)), // Near demo
        intervalMonths: 1,
        status: StoredReminderStatus.active,
        createdAt: now.subtract(const Duration(days: 26)),
      ),
      MaintenanceReminder(
        id: 'demo-reminder-4',
        motorcycleId: 'demo-motor-1',
        userId: 'demo-user-1',
        title: 'Ganti Filter Udara',
        serviceType: 'Filter udara',
        targetMileage: 20000,
        intervalKm: 10000,
        status: StoredReminderStatus.active,
        createdAt: now.subtract(const Duration(days: 90)),
      ),
    ]);
  }

  Future<void> _maybeDelay() async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  void _notify() {
    _streamController.add(List<MaintenanceReminder>.unmodifiable(_reminders));
  }

  @override
  Future<Result<List<MaintenanceReminder>>> getRemindersByMotorcycle(
    String motorcycleId,
  ) async {
    await _maybeDelay();
    try {
      final List<MaintenanceReminder> list = _reminders
          .where((r) => r.motorcycleId == motorcycleId)
          .toList();
      return Result<List<MaintenanceReminder>>.success(list);
    } catch (e) {
      return Result<List<MaintenanceReminder>>.failure(
        ServerException('Gagal memuat pengingat servis.', e),
      );
    }
  }

  @override
  Future<Result<MaintenanceReminder>> getReminderById(String id) async {
    await _maybeDelay();
    try {
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index == -1) {
        return const Result<MaintenanceReminder>.failure(
          NotFoundException('Pengingat servis tidak ditemukan.'),
        );
      }
      return Result<MaintenanceReminder>.success(_reminders[index]);
    } catch (e) {
      return Result<MaintenanceReminder>.failure(
        ServerException('Gagal memuat detail pengingat.', e),
      );
    }
  }

  @override
  Future<Result<MaintenanceReminder>> addReminder(
    MaintenanceReminder reminder,
  ) async {
    await _maybeDelay();
    try {
      if (reminder.reminderDate == null && reminder.targetMileage == null) {
        return const Result<MaintenanceReminder>.failure(
          ValidationException(
            'Minimal satu pemicu (tanggal atau target kilometer) wajib diisi.',
          ),
        );
      }

      final String newId = reminder.id.isEmpty
          ? 'rem_${DateTime.now().millisecondsSinceEpoch}'
          : reminder.id;

      final MaintenanceReminder newReminder = reminder.copyWith(id: newId);
      _reminders.add(newReminder);
      _notify();

      return Result<MaintenanceReminder>.success(newReminder);
    } catch (e) {
      return Result<MaintenanceReminder>.failure(
        ServerException('Gagal menambahkan pengingat.', e),
      );
    }
  }

  @override
  Future<Result<MaintenanceReminder>> updateReminder(
    MaintenanceReminder reminder,
  ) async {
    await _maybeDelay();
    try {
      final int index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index == -1) {
        return const Result<MaintenanceReminder>.failure(
          NotFoundException('Pengingat servis tidak ditemukan.'),
        );
      }

      if (reminder.reminderDate == null && reminder.targetMileage == null) {
        return const Result<MaintenanceReminder>.failure(
          ValidationException(
            'Minimal satu pemicu (tanggal atau target kilometer) wajib diisi.',
          ),
        );
      }

      _reminders[index] = reminder;
      _notify();

      return Result<MaintenanceReminder>.success(reminder);
    } catch (e) {
      return Result<MaintenanceReminder>.failure(
        ServerException('Gagal memperbarui pengingat.', e),
      );
    }
  }

  @override
  Future<Result<void>> deleteReminder(String id) async {
    await _maybeDelay();
    try {
      final int initialLength = _reminders.length;
      _reminders.removeWhere((r) => r.id == id);
      if (_reminders.length == initialLength) {
        return const Result<void>.failure(
          NotFoundException('Pengingat servis tidak ditemukan.'),
        );
      }
      _notify();
      return const Result<void>.success(null);
    } catch (e) {
      return Result<void>.failure(
        ServerException('Gagal menghapus pengingat.', e),
      );
    }
  }

  @override
  Future<Result<MaintenanceReminder>> completeReminder(
    String id, {
    required int serviceMileage,
    required DateTime serviceDate,
  }) async {
    await _maybeDelay();
    try {
      final int index = _reminders.indexWhere((r) => r.id == id);
      if (index == -1) {
        return const Result<MaintenanceReminder>.failure(
          NotFoundException('Pengingat servis tidak ditemukan.'),
        );
      }

      final MaintenanceReminder current = _reminders[index];
      final MaintenanceReminder completed = current.copyWith(
        status: StoredReminderStatus.completed,
        completedAt: DateTime.now(),
      );
      _reminders[index] = completed;

      // Otomatis buat pengingat berikutnya bila ada interval (PRD 6.4)
      if (current.intervalKm != null || current.intervalMonths != null) {
        final String nextId = 'rem_${DateTime.now().millisecondsSinceEpoch}_next';
        final MaintenanceReminder nextReminder = createNextReminder(
          currentReminder: current,
          serviceMileage: serviceMileage,
          serviceDate: serviceDate,
          newId: nextId,
        );
        _reminders.add(nextReminder);
      }

      _notify();
      return Result<MaintenanceReminder>.success(completed);
    } catch (e) {
      return Result<MaintenanceReminder>.failure(
        ServerException('Gagal menandai pengingat selesai.', e),
      );
    }
  }

  @override
  Stream<List<MaintenanceReminder>> watchReminders(String motorcycleId) {
    return _streamController.stream.map(
      (list) => list.where((r) => r.motorcycleId == motorcycleId).toList(),
    );
  }

  void dispose() {
    _streamController.close();
  }
}
