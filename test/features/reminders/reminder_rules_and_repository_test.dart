import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/reminders/data/mock_maintenance_reminder_repository.dart';
import 'package:motocare/features/reminders/domain/default_templates.dart';
import 'package:motocare/features/reminders/domain/maintenance_reminder.dart';
import 'package:motocare/features/reminders/domain/reminder_rules.dart';
import 'package:motocare/features/reminders/domain/reminder_status.dart';

void main() {
  group('PRD Bagian 6.3: computeReminderStatus Unit Tests', () {
    // 1. Tanggal 2026-11-01, hari ini 2026-10-20 (12 hari) -> scheduled
    test('Tabel 6.3 Kasus 1: Tanggal 12 hari ke depan menghasilkan scheduled', () {
      final status = computeReminderStatus(
        status: StoredReminderStatus.active,
        reminderDate: DateTime(2026, 11, 1),
        targetMileage: null,
        currentMileage: 10000,
        today: DateTime(2026, 10, 20),
      );
      expect(status, ReminderStatus.scheduled);
    });

    // 2. Tanggal 2026-11-01, hari ini 2026-10-25 (7 hari) -> near
    test('Tabel 6.3 Kasus 2: Tanggal 7 hari ke depan menghasilkan near', () {
      final status = computeReminderStatus(
        status: StoredReminderStatus.active,
        reminderDate: DateTime(2026, 11, 1),
        targetMileage: null,
        currentMileage: 10000,
        today: DateTime(2026, 10, 25),
      );
      expect(status, ReminderStatus.near);
    });

    // 3. Tanggal 2026-11-01, hari ini 2026-11-01 -> near
    test('Tabel 6.3 Kasus 3: Tanggal hari ini (jatuh tempo) menghasilkan near', () {
      final status = computeReminderStatus(
        status: StoredReminderStatus.active,
        reminderDate: DateTime(2026, 11, 1),
        targetMileage: null,
        currentMileage: 10000,
        today: DateTime(2026, 11, 1),
      );
      expect(status, ReminderStatus.near);
    });

    // 4. Tanggal 2026-11-01, hari ini 2026-11-02 -> overdue
    test('Tabel 6.3 Kasus 4: Tanggal lewat 1 hari menghasilkan overdue', () {
      final status = computeReminderStatus(
        status: StoredReminderStatus.active,
        reminderDate: DateTime(2026, 11, 1),
        targetMileage: null,
        currentMileage: 10000,
        today: DateTime(2026, 11, 2),
      );
      expect(status, ReminderStatus.overdue);
    });

    // 5. Target 15000, kilometer 14700 (sisa 300) -> scheduled
    test('Tabel 6.3 Kasus 5: Target 15000, KM 14700 (sisa 300) menghasilkan scheduled', () {
      final status = computeReminderStatus(
        status: StoredReminderStatus.active,
        reminderDate: null,
        targetMileage: 15000,
        currentMileage: 14700,
        today: DateTime(2026, 10, 20),
      );
      expect(status, ReminderStatus.scheduled);
    });

    // 6. Target 15000, kilometer 14800 (sisa 200) -> near
    test('Tabel 6.3 Kasus 6: Target 15000, KM 14800 (sisa 200) menghasilkan near', () {
      final status = computeReminderStatus(
        status: StoredReminderStatus.active,
        reminderDate: null,
        targetMileage: 15000,
        currentMileage: 14800,
        today: DateTime(2026, 10, 20),
      );
      expect(status, ReminderStatus.near);
    });

    // 7. Target 15000, kilometer 15000 -> near
    test('Tabel 6.3 Kasus 7: Target 15000, KM tepat 15000 menghasilkan near', () {
      final status = computeReminderStatus(
        status: StoredReminderStatus.active,
        reminderDate: null,
        targetMileage: 15000,
        currentMileage: 15000,
        today: DateTime(2026, 10, 20),
      );
      expect(status, ReminderStatus.near);
    });

    // 8. Target 15000, kilometer 15001 -> overdue
    test('Tabel 6.3 Kasus 8: Target 15000, KM 15001 menghasilkan overdue', () {
      final status = computeReminderStatus(
        status: StoredReminderStatus.active,
        reminderDate: null,
        targetMileage: 15000,
        currentMileage: 15001,
        today: DateTime(2026, 10, 20),
      );
      expect(status, ReminderStatus.overdue);
    });

    // 9. Tanggal belum jatuh tempo, kilometer 15001 melewati target 15000 -> overdue
    test('Tabel 6.3 Kasus 9: Tanggal scheduled tapi KM overdue menghasilkan overdue (ambil paling parah)', () {
      final status = computeReminderStatus(
        status: StoredReminderStatus.active,
        reminderDate: DateTime(2026, 11, 1),
        targetMileage: 15000,
        currentMileage: 15001,
        today: DateTime(2026, 10, 20),
      );
      expect(status, ReminderStatus.overdue);
    });

    // 10. status == completed -> completed
    test('Tabel 6.3 Kasus 10: status == completed menghasilkan completed tanpa melihat tanggal/KM', () {
      final status = computeReminderStatus(
        status: StoredReminderStatus.completed,
        reminderDate: DateTime(2026, 10, 1), // Lewat
        targetMileage: 15000,
        currentMileage: 20000, // Lewat
        today: DateTime(2026, 10, 20),
      );
      expect(status, ReminderStatus.completed);
    });
  });

  group('PRD Bagian 6.4: createNextReminder & Selesai Servis', () {
    test('Uji Oli mesin: servis di 12000 km pada 2026-10-14 menghasilkan target 15000 km dan tanggal 2027-01-14', () {
      final reminder = MaintenanceReminder(
        id: 'rem-oil-1',
        motorcycleId: 'motor-1',
        userId: 'user-1',
        title: DefaultReminderTemplates.engineOil.title,
        serviceType: DefaultReminderTemplates.engineOil.serviceType,
        reminderDate: DateTime(2026, 10, 14),
        targetMileage: 12000,
        intervalKm: 3000,
        intervalMonths: 3,
        status: StoredReminderStatus.active,
        createdAt: DateTime(2026, 7, 14),
      );

      final nextReminder = createNextReminder(
        currentReminder: reminder,
        serviceMileage: 12000,
        serviceDate: DateTime(2026, 10, 14),
        newId: 'rem-oil-2',
      );

      expect(nextReminder.targetMileage, equals(15000));
      expect(nextReminder.reminderDate, equals(DateTime(2027, 1, 14)));
      expect(nextReminder.status, equals(StoredReminderStatus.active));
      expect(nextReminder.title, equals('Ganti Oli Mesin'));
    });

    test('addMonths aman terhadap batas akhir bulan (31 Jan + 1 bulan -> 28 Feb)', () {
      final jan31 = DateTime(2026, 1, 31);
      final feb = addMonths(jan31, 1);
      expect(feb.year, 2026);
      expect(feb.month, 2);
      expect(feb.day, 28);
    });
  });

  group('MockMaintenanceReminderRepository Tests', () {
    late MockMaintenanceReminderRepository repo;

    setUp(() {
      repo = MockMaintenanceReminderRepository(
        simulateDelay: false,
        populateDemoData: false,
      );
    });

    test('Menambah pengingat tanpa tanggal dan tanpa KM ditolak validasi', () async {
      final reminder = MaintenanceReminder(
        id: '',
        motorcycleId: 'm1',
        userId: 'u1',
        title: 'Pengingat Kosong',
        createdAt: DateTime.now(),
      );

      final res = await repo.addReminder(reminder);
      expect(res.isFailure, isTrue);
    });

    test('Menambah pengingat valid berhasil tersimpan', () async {
      final reminder = MaintenanceReminder(
        id: '',
        motorcycleId: 'm1',
        userId: 'u1',
        title: 'Ganti Oli',
        targetMileage: 10000,
        createdAt: DateTime.now(),
      );

      final res = await repo.addReminder(reminder);
      expect(res.isSuccess, isTrue);
      expect(res.dataOrNull!.id, isNotEmpty);

      final getRes = await repo.getRemindersByMotorcycle('m1');
      expect(getRes.dataOrNull!.length, equals(1));
    });

    test('completeReminder menandai selesai dan otomatis membuat pengingat siklus berikutnya', () async {
      final reminder = MaintenanceReminder(
        id: 'rem-1',
        motorcycleId: 'm1',
        userId: 'u1',
        title: 'Ganti Oli Mesin',
        intervalKm: 3000,
        intervalMonths: 3,
        targetMileage: 12000,
        reminderDate: DateTime(2026, 10, 14),
        createdAt: DateTime.now(),
      );

      await repo.addReminder(reminder);

      final compRes = await repo.completeReminder(
        'rem-1',
        serviceMileage: 12000,
        serviceDate: DateTime(2026, 10, 14),
      );

      expect(compRes.isSuccess, isTrue);
      expect(compRes.dataOrNull!.status, equals(StoredReminderStatus.completed));

      final allRes = await repo.getRemindersByMotorcycle('m1');
      final list = allRes.dataOrNull!;
      expect(list.length, equals(2));

      final next = list.firstWhere((r) => r.id != 'rem-1');
      expect(next.targetMileage, equals(15000));
      expect(next.reminderDate, equals(DateTime(2027, 1, 14)));
      expect(next.status, equals(StoredReminderStatus.active));
    });

    test('Hapus pengingat berhasil menghapus data', () async {
      final reminder = MaintenanceReminder(
        id: 'rem-del-1',
        motorcycleId: 'm1',
        userId: 'u1',
        title: 'Hapus Saya',
        targetMileage: 5000,
        createdAt: DateTime.now(),
      );

      await repo.addReminder(reminder);
      final delRes = await repo.deleteReminder('rem-del-1');
      expect(delRes.isSuccess, isTrue);

      final getRes = await repo.getReminderById('rem-del-1');
      expect(getRes.isFailure, isTrue);
    });
  });
}
