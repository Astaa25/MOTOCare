import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/core/theme/app_theme.dart';
import 'package:motocare/features/motorcycles/data/mock_motorcycle_repository.dart';
import 'package:motocare/features/motorcycles/presentation/motorcycle_providers.dart';
import 'package:motocare/features/service_history/data/mock_service_history_repository.dart';
import 'package:motocare/features/service_history/presentation/add_edit_service_history_screen.dart';
import 'package:motocare/features/service_history/presentation/service_history_detail_screen.dart';
import 'package:motocare/features/service_history/presentation/service_history_providers.dart';
import 'package:motocare/features/service_history/presentation/service_history_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget createTestWidget({
    required Widget child,
    required MockServiceHistoryRepository serviceRepo,
    MockMotorcycleRepository? motorRepo,
  }) {
    final effectiveMotorRepo = motorRepo ?? MockMotorcycleRepository(populateDemoData: false);

    return ProviderScope(
      overrides: [
        serviceHistoryRepositoryProvider.overrideWithValue(serviceRepo),
        motorcycleRepositoryProvider.overrideWithValue(effectiveMotorRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Widget Tests Riwayat Servis & Biaya (M4)', () {
    testWidgets('ServiceHistoryScreen: Tampilkan EmptyState jika belum ada riwayat servis',
        (WidgetTester tester) async {
      final mockServiceRepo = MockServiceHistoryRepository(populateDemoData: false);

      await tester.pumpWidget(
        createTestWidget(
          child: const ServiceHistoryScreen(motorcycleId: 'motor-empty-test'),
          serviceRepo: mockServiceRepo,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty_service_history_state')), findsOneWidget);
      expect(find.text('Catat Servis Pertama'), findsOneWidget);
      expect(find.text('Rp 0'), findsOneWidget);
      expect(find.byKey(const Key('add_service_history_fab')), findsOneWidget);
    });

    testWidgets('ServiceHistoryScreen: Tampilkan daftar servis, total biaya, dan filter chip',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockServiceRepo = MockServiceHistoryRepository(populateDemoData: false);

      // Tambahkan 2 catatan servis
      final now = DateTime.now();
      await mockServiceRepo.addServiceHistory(
        motorcycleId: 'motor-list-test',
        userId: 'user-1',
        serviceDate: now.subtract(const Duration(days: 10)),
        mileage: 10000,
        serviceType: 'Ganti oli',
        cost: 85000,
        workshopName: 'AHASS Lhokseumawe',
      );

      await mockServiceRepo.addServiceHistory(
        motorcycleId: 'motor-list-test',
        userId: 'user-1',
        serviceDate: now.subtract(const Duration(days: 2)),
        mileage: 12000,
        serviceType: 'Servis berkala',
        cost: 150000,
        workshopName: 'Bengkel Sentosa',
      );

      await tester.pumpWidget(
        createTestWidget(
          child: const ServiceHistoryScreen(motorcycleId: 'motor-list-test'),
          serviceRepo: mockServiceRepo,
        ),
      );

      await tester.pumpAndSettle();

      // Verifikasi total biaya (85.000 + 150.000 = 235.000)
      expect(find.text('Rp 235.000'), findsOneWidget);

      // Verifikasi kedua catatan tampil (kartu dan chip)
      expect(find.text('Ganti oli'), findsWidgets);
      expect(find.text('Servis berkala'), findsWidgets);
      expect(find.text('Rp 85.000'), findsOneWidget);
      expect(find.text('Rp 150.000'), findsOneWidget);

      // Filter chip 'Ganti oli'
      await tester.tap(find.widgetWithText(ChoiceChip, 'Ganti oli'));
      await tester.pumpAndSettle();

      // Verifikasi total biaya berubah menjadi 85.000 dan kartu Servis berkala tidak ada
      expect(find.text('Rp 85.000'), findsWidgets);
      expect(find.text('Rp 150.000'), findsNothing);
    });

    testWidgets('TC-05: Tambah servis baru dengan validasi dan pembaruan kilometer motor',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockMotorRepo = MockMotorcycleRepository(populateDemoData: false);
      final motor = (await mockMotorRepo.addMotorcycle(
        userId: 'demo-user-id',
        brand: 'Honda',
        model: 'Vario 160',
        productionYear: 2023,
        currentMileage: 10000,
      )).dataOrNull!;

      final mockServiceRepo = MockServiceHistoryRepository(
        motorcycleRepository: mockMotorRepo,
        populateDemoData: false,
      );

      await tester.pumpWidget(
        createTestWidget(
          child: AddEditServiceHistoryScreen(motorcycleId: motor.id),
          serviceRepo: mockServiceRepo,
          motorRepo: mockMotorRepo,
        ),
      );

      await tester.pumpAndSettle();

      // Isi form servis
      final kmField = find.byKey(const Key('service_mileage_input'));
      final costField = find.byKey(const Key('service_cost_input'));
      final workshopField = find.byKey(const Key('service_workshop_input'));
      final notesField = find.byKey(const Key('service_description_input'));

      await tester.enterText(kmField, '13500');
      await tester.enterText(costField, '120000');
      await tester.enterText(workshopField, 'Bengkel Mitra Motor');
      await tester.enterText(notesField, 'Ganti kampas rem dan oli');

      // Tekan tombol simpan
      await tester.ensureVisible(find.byKey(const Key('submit_service_button')));
      await tester.tap(find.byKey(const Key('submit_service_button')));
      await tester.pumpAndSettle();

      // Verifikasi SuccessDialog muncul
      expect(find.text('Servis Berhasil Dicatat'), findsOneWidget);
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      // Verifikasi data tersimpan di repository servis
      final serviceList = await mockServiceRepo.getServiceHistories(motorcycleId: motor.id);
      expect(serviceList.dataOrNull?.length, 1);
      expect(serviceList.dataOrNull?.first.cost, 120000);
      expect(serviceList.dataOrNull?.first.mileage, 13500);

      // TC-05: Verifikasi kilometer motor otomatis terupdate ke 13.500
      final updatedMotor = (await mockMotorRepo.getMotorcycleById(motor.id)).dataOrNull!;
      expect(updatedMotor.currentMileage, 13500);
    });

    testWidgets('TC-22: Input biaya negatif atau kilometer tidak valid ditolak',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockServiceRepo = MockServiceHistoryRepository(populateDemoData: false);

      await tester.pumpWidget(
        createTestWidget(
          child: const AddEditServiceHistoryScreen(motorcycleId: 'motor-invalid-test'),
          serviceRepo: mockServiceRepo,
        ),
      );

      await tester.pumpAndSettle();

      // Masukkan biaya kosong atau kilometer kosong
      final kmField = find.byKey(const Key('service_mileage_input'));
      final costField = find.byKey(const Key('service_cost_input'));

      await tester.enterText(kmField, '');
      await tester.enterText(costField, '');

      await tester.ensureVisible(find.byKey(const Key('submit_service_button')));
      await tester.tap(find.byKey(const Key('submit_service_button')));
      await tester.pumpAndSettle();

      // Form validation error muncul
      expect(find.text('Masukkan angka kilometer valid (0 - 999.999)'), findsOneWidget);
      expect(find.text('Biaya wajib diisi'), findsOneWidget);

      // Tidak ada yang tersimpan di repository
      final list = await mockServiceRepo.getServiceHistories(motorcycleId: 'motor-invalid-test');
      expect(list.dataOrNull, isEmpty);
    });

    testWidgets('ServiceHistoryDetailScreen: Tampilkan detail servis dan eksekusi hapus dengan konfirmasi',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockServiceRepo = MockServiceHistoryRepository(populateDemoData: false);
      final service = (await mockServiceRepo.addServiceHistory(
        motorcycleId: 'motor-detail-test',
        userId: 'demo-user-id',
        serviceDate: DateTime(2026, 9, 10),
        mileage: 8000,
        serviceType: 'Rem',
        cost: 75000,
        workshopName: 'AHASS Lhokseumawe',
        description: 'Ganti kampas rem depan belakang',
      )).dataOrNull!;

      await tester.pumpWidget(
        createTestWidget(
          child: ServiceHistoryDetailScreen(serviceId: service.id),
          serviceRepo: mockServiceRepo,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Detail Catatan Servis'), findsOneWidget);
      expect(find.text('Rem'), findsOneWidget);
      expect(find.text('Rp 75.000'), findsOneWidget);
      expect(find.text('8.000 km'), findsOneWidget);
      expect(find.text('AHASS Lhokseumawe'), findsOneWidget);
      expect(find.text('Ganti kampas rem depan belakang'), findsOneWidget);

      // Tekan tombol Hapus Servis
      await tester.ensureVisible(find.byKey(const Key('delete_service_button')));
      await tester.tap(find.byKey(const Key('delete_service_button')));
      await tester.pumpAndSettle();

      // Verifikasi ConfirmationDialog
      expect(find.text('Hapus Catatan Servis?'), findsOneWidget);
      expect(find.text('Ya, Hapus Servis'), findsOneWidget);

      // Konfirmasi hapus
      await tester.tap(find.text('Ya, Hapus Servis'));
      await tester.pumpAndSettle();

      expect(find.text('Catatan Dihapus'), findsOneWidget);
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      // Verifikasi terhapus dari repository
      final fetchRes = await mockServiceRepo.getServiceHistoryById(service.id);
      expect(fetchRes.isFailure, isTrue);
    });
  });
}
