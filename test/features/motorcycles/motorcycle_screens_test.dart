import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/core/theme/app_theme.dart';
import 'package:motocare/features/home/presentation/home_screen.dart';
import 'package:motocare/features/motorcycles/data/mock_motorcycle_repository.dart';
import 'package:motocare/features/motorcycles/presentation/add_edit_motorcycle_screen.dart';
import 'package:motocare/features/motorcycles/presentation/motorcycle_detail_screen.dart';
import 'package:motocare/features/motorcycles/presentation/motorcycle_providers.dart';
import 'package:motocare/features/motorcycles/presentation/motorcycles_screen.dart';
import 'package:motocare/features/motorcycles/presentation/update_mileage_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });
  Widget createTestWidget({
    required Widget child,
    required MockMotorcycleRepository repository,
  }) {
    return ProviderScope(
      overrides: [
        motorcycleRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Widget Tests Manajemen Motor & Kilometer (M3)', () {
    testWidgets('MotorcyclesScreen: Tampilkan EmptyState jika belum ada motor terdaftar',
        (WidgetTester tester) async {
      final mockRepo = MockMotorcycleRepository(populateDemoData: false);

      await tester.pumpWidget(
        createTestWidget(
          child: const MotorcyclesScreen(),
          repository: mockRepo,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty_motorcycles_state')), findsOneWidget);
      expect(find.text('Belum Ada Sepeda Motor'), findsOneWidget);
      expect(find.text('Tambah Motor Sekarang'), findsOneWidget);
    });

    testWidgets('TC-03: Tambah motor baru dengan form valid berhasil tersimpan',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockMotorcycleRepository(populateDemoData: false);

      await tester.pumpWidget(
        createTestWidget(
          child: const AddEditMotorcycleScreen(),
          repository: mockRepo,
        ),
      );

      await tester.pumpAndSettle();

      // Isi form pendaftaran motor
      final brandField = find.widgetWithText(TextFormField, 'Contoh: Honda, Yamaha, Suzuki');
      final modelField = find.widgetWithText(TextFormField, 'Contoh: Vario 160, NMAX 155, Beat');
      final yearField = find.widgetWithText(TextFormField, 'Contoh: 2022');
      final plateField = find.widgetWithText(TextFormField, 'Contoh: BL 1234 AB');
      final kmField = find.widgetWithText(TextFormField, 'Contoh: 12500');

      await tester.enterText(brandField, 'Honda');
      await tester.enterText(modelField, 'Vario 160');
      await tester.enterText(yearField, '2023');
      await tester.enterText(plateField, 'BL 1234 AA');
      await tester.enterText(kmField, '15000');

      // Tekan tombol submit
      await tester.ensureVisible(find.byKey(const Key('submit_motorcycle_button')));
      await tester.tap(find.byKey(const Key('submit_motorcycle_button')));
      await tester.pumpAndSettle();

      // Verifikasi SuccessDialog muncul
      expect(find.text('Motor Berhasil Ditambahkan'), findsOneWidget);
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      // Verifikasi di repository
      final list = await mockRepo.getMotorcycles(userId: 'demo-user-id');
      expect(list.dataOrNull!.length, 1);
      expect(list.dataOrNull!.first.brand, 'Honda');
      expect(list.dataOrNull!.first.model, 'Vario 160');
      expect(list.dataOrNull!.first.currentMileage, 15000);
    });

    testWidgets('TC-04: Pembaruan kilometer lebih kecil memicu ConfirmationDialog penurunan KM',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockMotorcycleRepository(populateDemoData: false);
      // Tambah motor awal dengan 12.000 km
      final motor = (await mockRepo.addMotorcycle(
        userId: 'demo-user-id',
        brand: 'Honda',
        model: 'Vario 160',
        productionYear: 2023,
        currentMileage: 12000,
      )).dataOrNull!;

      await tester.pumpWidget(
        createTestWidget(
          child: UpdateMileageScreen(motorcycleId: motor.id),
          repository: mockRepo,
        ),
      );

      await tester.pumpAndSettle();

      // Masukkan kilometer 11.990 (lebih kecil dari 12.000)
      final kmField = find.byType(TextFormField);
      await tester.enterText(kmField, '11990');

      // Tekan tombol simpan
      await tester.ensureVisible(find.byKey(const Key('save_mileage_button')));
      await tester.tap(find.byKey(const Key('save_mileage_button')));
      await tester.pumpAndSettle();

      // Verifikasi ConfirmationDialog muncul
      expect(find.text('Koreksi Penurunan Kilometer?'), findsOneWidget);
      expect(find.text('Ya, Koreksi'), findsOneWidget);

      // Konfirmasi koreksi
      await tester.tap(find.text('Ya, Koreksi'));
      await tester.pumpAndSettle();

      // Verifikasi dialog sukses muncul
      expect(find.text('Kilometer Diperbarui'), findsOneWidget);
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      // Verifikasi kilometer di repository telah terupdate
      final updated = (await mockRepo.getMotorcycleById(motor.id)).dataOrNull!;
      expect(updated.currentMileage, 11990);
    });

    testWidgets('Pembaruan kilometer melonjak > 5000 km memicu ConfirmationDialog lonjakan',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockMotorcycleRepository(populateDemoData: false);
      final motor = (await mockRepo.addMotorcycle(
        userId: 'demo-user-id',
        brand: 'Yamaha',
        model: 'NMAX',
        productionYear: 2022,
        currentMileage: 10000,
      )).dataOrNull!;

      await tester.pumpWidget(
        createTestWidget(
          child: UpdateMileageScreen(motorcycleId: motor.id),
          repository: mockRepo,
        ),
      );

      await tester.pumpAndSettle();

      // Masukkan lonjakan 16.000 km (> 5000 km jump)
      final kmField = find.byType(TextFormField);
      await tester.enterText(kmField, '16000');

      // Tekan simpan
      await tester.ensureVisible(find.byKey(const Key('save_mileage_button')));
      await tester.tap(find.byKey(const Key('save_mileage_button')));
      await tester.pumpAndSettle();

      // Verifikasi konfirmasi lonjakan
      expect(find.text('Konfirmasi Kenaikan Kilometer'), findsOneWidget);
      expect(find.text('Lanjutkan Simpan'), findsOneWidget);

      // Lanjutkan simpan
      await tester.tap(find.text('Lanjutkan Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Kilometer Diperbarui'), findsOneWidget);
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
    });

    testWidgets('MotorcycleDetailScreen: Dialog konfirmasi hapus menyebutkan CASCADE servis dan pengingat',
        (WidgetTester tester) async {
      final mockRepo = MockMotorcycleRepository(populateDemoData: false);
      final motor = (await mockRepo.addMotorcycle(
        userId: 'demo-user-id',
        brand: 'Honda',
        model: 'Beat Street',
        productionYear: 2021,
        currentMileage: 5000,
      )).dataOrNull!;

      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestWidget(
          child: MotorcycleDetailScreen(motorcycleId: motor.id),
          repository: mockRepo,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Honda Beat Street'), findsOneWidget);

      // Scroll ke tombol hapus motor
      await tester.ensureVisible(find.byKey(const Key('delete_motorcycle_button')));
      await tester.tap(find.byKey(const Key('delete_motorcycle_button')));
      await tester.pumpAndSettle();

      // Verifikasi teks peringatan konfirmasi penghapusan sesuai PRD
      expect(find.text('Hapus Sepeda Motor?'), findsOneWidget);
      expect(
        find.textContaining('juga akan menghapus seluruh riwayat servis dan jadwal pengingat'),
        findsOneWidget,
      );
      expect(find.text('Ya, Hapus Motor'), findsOneWidget);

      // Eksekusi hapus
      await tester.tap(find.text('Ya, Hapus Motor'));
      await tester.pumpAndSettle();

      expect(find.text('Motor Dihapus'), findsOneWidget);
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      // Verifikasi motor terhapus dari repo
      final list = await mockRepo.getMotorcycles(userId: 'demo-user-id');
      expect(list.dataOrNull, isEmpty);
    });

    testWidgets('HomeScreen: Menampilkan kartu motor aktif dan tombol bantuan mekanik',
        (WidgetTester tester) async {
      final mockRepo = MockMotorcycleRepository(populateDemoData: true);

      await tester.pumpWidget(
        createTestWidget(
          child: const HomeScreen(),
          repository: mockRepo,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sepeda Motor Aktif'), findsOneWidget);
      expect(find.text('Honda Vario 160 CBS'), findsOneWidget);
      expect(find.byKey(const Key('home_request_mechanic_button')), findsOneWidget);
      expect(find.text('Cakupan Layanan: Kota Lhokseumawe & Kab. Aceh Utara'), findsOneWidget);
    });
  });
}
