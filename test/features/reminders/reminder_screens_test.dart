import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/theme/app_theme.dart';
import 'package:motocare/features/motorcycles/domain/motorcycle.dart';
import 'package:motocare/features/motorcycles/presentation/motorcycle_providers.dart';
import 'package:motocare/features/notifications/data/mock_notification_repository.dart';
import 'package:motocare/features/notifications/presentation/notifications_providers.dart';
import 'package:motocare/features/notifications/presentation/notifications_screen.dart';
import 'package:motocare/features/notifications/services/notification_service.dart';
import 'package:motocare/features/reminders/data/mock_maintenance_reminder_repository.dart';
import 'package:motocare/features/reminders/presentation/add_edit_reminder_screen.dart';
import 'package:motocare/features/reminders/presentation/reminder_detail_screen.dart';
import 'package:motocare/features/reminders/presentation/reminders_providers.dart';
import 'package:motocare/features/reminders/presentation/reminders_screen.dart';

Widget _buildTestApp({
  required Widget child,
  required MockMaintenanceReminderRepository reminderRepo,
  MockNotificationRepository? notifRepo,
  Motorcycle? testMotor,
}) {
  final motor = testMotor ??
      Motorcycle(
        id: 'test-motor-1',
        userId: 'test-user-1',
        brand: 'Honda',
        model: 'Vario 160',
        productionYear: 2023,
        currentMileage: 12000,
        mileageUpdatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  return ProviderScope(
    overrides: [
      reminderRepositoryProvider.overrideWithValue(reminderRepo),
      if (notifRepo != null)
        notificationRepositoryProvider.overrideWithValue(notifRepo),
      notificationServiceProvider.overrideWithValue(MockNotificationService()),
      motorcycleDetailProvider(motor.id).overrideWith((ref) => motor),
      activeMotorcycleProvider.overrideWithValue(AsyncValue.data(motor)),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  group('Widget Tests Pengingat & Notifikasi (Milestone M5)', () {
    testWidgets('RemindersScreen: Tampilkan EmptyState jika belum ada pengingat',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockMaintenanceReminderRepository(
        simulateDelay: false,
        populateDemoData: false,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const RemindersScreen(motorcycleId: 'test-motor-1'),
          reminderRepo: repo,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reminders_empty_state')), findsOneWidget);
      expect(find.text('Belum Ada Pengingat Servis'), findsOneWidget);
      expect(find.byKey(const Key('add_reminder_fab')), findsOneWidget);
    });

    testWidgets('RemindersScreen: Tampilkan daftar pengingat dan status chips terurut',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockMaintenanceReminderRepository(
        simulateDelay: false,
        populateDemoData: true,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const RemindersScreen(motorcycleId: 'demo-motor-1'),
          reminderRepo: repo,
          testMotor: Motorcycle(
            id: 'demo-motor-1',
            userId: 'demo-user-1',
            brand: 'Honda',
            model: 'Vario 160',
            productionYear: 2023,
            currentMileage: 12000,
            mileageUpdatedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Ganti Oli Mesin'), findsOneWidget);
      expect(find.text('Cek Rem & Kampas'), findsOneWidget);
      expect(find.text('Cek Tekanan Ban'), findsOneWidget);

      // Cek status chip
      expect(find.text('Terlambat'), findsOneWidget);
      expect(find.text('Segera servis'), findsOneWidget);
    });

    testWidgets('AddEditReminderScreen: Memilih templat mengisi form otomatis dan menolak pemicu kosong',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockMaintenanceReminderRepository(
        simulateDelay: false,
        populateDemoData: false,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const AddEditReminderScreen(motorcycleId: 'test-motor-1'),
          reminderRepo: repo,
        ),
      );

      await tester.pumpAndSettle();

      // Form default terisi dengan templat Oli Mesin
      expect(find.byKey(const Key('reminder_title_field')), findsOneWidget);
      final titleField = tester.widget<TextFormField>(
        find.byKey(const Key('reminder_title_field')),
      );
      expect(titleField.controller!.text, equals('Ganti Oli Mesin'));

      // Hapus judul dan kosongkan
      await tester.enterText(find.byKey(const Key('reminder_title_field')), '');
      await tester.tap(find.byKey(const Key('save_reminder_button')));
      await tester.pumpAndSettle();

      expect(find.text('Judul pengingat wajib diisi'), findsOneWidget);

      // Isi kembali judul dan simpan
      await tester.enterText(
        find.byKey(const Key('reminder_title_field')),
        'Ganti Busi Iridium',
      );
      await tester.enterText(
        find.byKey(const Key('reminder_target_km_field')),
        '20000',
      );

      await tester.tap(find.byKey(const Key('save_reminder_button')));
      await tester.pumpAndSettle();

      // Dialog sukses muncul
      expect(find.text('Pengingat Disimpan'), findsOneWidget);
    });

    testWidgets('ReminderDetailScreen: Tampilkan detail pengingat dan dialog hapus konfirmasi',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockMaintenanceReminderRepository(
        simulateDelay: false,
        populateDemoData: true,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const ReminderDetailScreen(reminderId: 'demo-reminder-1'),
          reminderRepo: repo,
          testMotor: Motorcycle(
            id: 'demo-motor-1',
            userId: 'demo-user-1',
            brand: 'Honda',
            model: 'Vario 160',
            productionYear: 2023,
            currentMileage: 12000,
            mileageUpdatedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Ganti Oli Mesin'), findsOneWidget);
      expect(find.byKey(const Key('record_service_from_reminder_button')), findsOneWidget);
      expect(find.byKey(const Key('mark_completed_button')), findsOneWidget);

      // Tekan tombol hapus
      await tester.tap(find.byKey(const Key('delete_reminder_button')));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Pengingat Servis?'), findsOneWidget);
      expect(find.text('Ya, Hapus'), findsOneWidget);
    });

    testWidgets('NotificationsScreen: Tampilkan daftar notifikasi dan aksi tandai dibaca (TC-07)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final reminderRepo = MockMaintenanceReminderRepository(
        simulateDelay: false,
        populateDemoData: false,
      );
      final notifRepo = MockNotificationRepository(
        simulateDelay: false,
        populateDemoData: true,
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: const NotificationsScreen(),
          reminderRepo: reminderRepo,
          notifRepo: notifRepo,
        ),
      );

      await tester.pumpAndSettle();

      // Cek list notifikasi muncul
      expect(find.text('Pusat Notifikasi'), findsOneWidget);
      expect(find.byKey(const Key('mark_all_read_button')), findsOneWidget);

      // Tekan tandai semua dibaca
      await tester.tap(find.byKey(const Key('mark_all_read_button')));
      await tester.pumpAndSettle();

      // Tombol tandai dibaca menghilang karena semua telah dibaca
      expect(find.byKey(const Key('mark_all_read_button')), findsNothing);
    });
  });
}
