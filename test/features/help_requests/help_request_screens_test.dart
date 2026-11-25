import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/core/theme/app_theme.dart';
import 'package:motocare/features/help_requests/data/mock_help_request_repository.dart';
import 'package:motocare/features/help_requests/domain/mechanic.dart';
import 'package:motocare/features/help_requests/domain/request_status.dart';
import 'package:motocare/features/help_requests/domain/service_request.dart';
import 'package:motocare/features/help_requests/presentation/create_help_request_screen.dart';
import 'package:motocare/features/help_requests/presentation/help_request_detail_screen.dart';
import 'package:motocare/features/help_requests/presentation/help_requests_providers.dart';
import 'package:motocare/features/help_requests/presentation/my_help_requests_screen.dart';
import 'package:motocare/features/motorcycles/data/mock_motorcycle_repository.dart';
import 'package:motocare/features/motorcycles/presentation/motorcycle_providers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget createTestWidget({
    required Widget child,
    required MockHelpRequestRepository helpRepo,
    MockMotorcycleRepository? motorRepo,
  }) {
    return ProviderScope(
      overrides: [
        helpRequestRepositoryProvider.overrideWithValue(helpRepo),
        if (motorRepo != null)
          motorcycleRepositoryProvider.overrideWithValue(motorRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Widget Tests Bantuan Montir & Mekanik Darurat (M7)', () {
    testWidgets('MyHelpRequestsScreen: Menampilkan EmptyState jika belum ada riwayat panggilan',
        (WidgetTester tester) async {
      final mockRepo = MockHelpRequestRepository();

      await tester.pumpWidget(
        createTestWidget(
          child: const MyHelpRequestsScreen(),
          helpRepo: mockRepo,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty_help_requests_state')), findsOneWidget);
      expect(find.text('Belum Ada Panggilan Montir'), findsOneWidget);
      expect(find.text('Panggil Montir Sekarang'), findsOneWidget);
    });

    testWidgets('MyHelpRequestsScreen: Menampilkan daftar permintaan saat tersedia',
        (WidgetTester tester) async {
      final testReq = ServiceRequest(
        id: 'req-101',
        userId: 'user-001',
        issueCategory: CommonIssues.banBocor,
        issueDescription: 'Ban belakang kempes tertusuk paku',
        addressText: 'Jl. Merdeka No. 10',
        contactPhone: '081234567890',
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        isDemo: true,
      );

      final mockRepo = MockHelpRequestRepository(initialRequests: [testReq]);

      await tester.pumpWidget(
        createTestWidget(
          child: const MyHelpRequestsScreen(),
          helpRepo: mockRepo,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text(CommonIssues.banBocor), findsOneWidget);
      expect(find.text('Menunggu Konfirmasi'), findsOneWidget);
      expect(find.text('Jl. Merdeka No. 10'), findsOneWidget);
    });

    testWidgets('CreateHelpRequestScreen: Menampilkan form lengkap dan validasi error (TC-11)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockHelpRequestRepository();
      final motorRepo = MockMotorcycleRepository(populateDemoData: true);

      await tester.pumpWidget(
        createTestWidget(
          child: const CreateHelpRequestScreen(),
          helpRepo: mockRepo,
          motorRepo: motorRepo,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Cek elemen form
      expect(find.byKey(const Key('issue_description_field')), findsOneWidget);
      expect(find.byKey(const Key('help_address_field')), findsOneWidget);
      expect(find.byKey(const Key('contact_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('submit_help_request_button')), findsOneWidget);

      // Tekan tombol submit tanpa mengisi apa-apa
      await tester.tap(find.byKey(const Key('submit_help_request_button')));
      await tester.pumpAndSettle();

      // Validasi pesan error wajib tampil
      expect(find.text('Deskripsi masalah wajib diisi.'), findsOneWidget);
      expect(
        find.text('Alamat lokasi penjemputan minimal 5 karakter atau aktifkan GPS.'),
        findsOneWidget,
      );
    });

    testWidgets('CreateHelpRequestScreen: Deteksi konflik saat masih ada permintaan aktif (TC-21)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Sudah ada 1 permintaan berstatus pending
      final activeReq = ServiceRequest(
        id: 'req-active-01',
        userId: 'user-001',
        issueCategory: CommonIssues.mesinMogok,
        issueDescription: 'Mesin mogok tidak bisa jalan sama sekali',
        addressText: 'Jl. Pemuda No. 45',
        contactPhone: '081234567890',
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      final mockRepo = MockHelpRequestRepository(initialRequests: [activeReq]);

      await tester.pumpWidget(
        createTestWidget(
          child: const CreateHelpRequestScreen(),
          helpRepo: mockRepo,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Isi form dengan data valid
      await tester.enterText(
        find.byKey(const Key('issue_description_field')),
        'Rantai motor putus di tengah jalan raya.',
      );
      await tester.enterText(
        find.byKey(const Key('help_address_field')),
        'Jl. Sudirman No. 88, depan minimarket',
      );
      await tester.enterText(
        find.byKey(const Key('contact_phone_field')),
        '081234567890',
      );
      await tester.pumpAndSettle();

      // Tekan tombol submit
      await tester.tap(find.byKey(const Key('submit_help_request_button')));
      await tester.pumpAndSettle();

      // Muncul dialog konfirmasi ringkasan awal
      expect(find.text('Konfirmasi Panggilan Montir'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirmation_dialog_confirm_button')));
      await tester.pumpAndSettle();

      // Sistem menolak dan menampilkan dialog konflik permintaan aktif (TC-21)
      expect(find.byKey(const Key('active_request_conflict_dialog')), findsOneWidget);
      expect(find.text('Permintaan Masih Aktif'), findsOneWidget);
      expect(find.byKey(const Key('open_active_request_button')), findsOneWidget);
    });

    testWidgets('HelpRequestDetailScreen: Menampilkan status pending, hitung mundur, dan pembatalan (TC-20)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testReq = ServiceRequest(
        id: 'req-pending-01',
        userId: 'user-001',
        issueCategory: CommonIssues.kelistrikanAki,
        issueDescription: 'Kelistrikan motor mati total saat berkendara malam hari.',
        addressText: 'Jl. Gajah Mada No. 15',
        contactPhone: '081234567890',
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        isDemo: true,
      );

      final mockRepo = MockHelpRequestRepository(initialRequests: [testReq]);

      await tester.pumpWidget(
        createTestWidget(
          child: const HelpRequestDetailScreen(requestId: 'req-pending-01'),
          helpRepo: mockRepo,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Verifikasi status dan elemen (production mode bebas badge demo)
      expect(find.text('Menunggu Konfirmasi'), findsOneWidget);
      expect(find.text('Kelistrikan / Aki Mati'), findsOneWidget);
      expect(find.byKey(const Key('help_request_demo_badge')), findsNothing);
      expect(find.byKey(const Key('cancel_help_request_button')), findsOneWidget);

      // Tekan batalkan panggilan montir
      await tester.tap(find.byKey(const Key('cancel_help_request_button')));
      await tester.pumpAndSettle();

      // Muncul dialog konfirmasi pembatalan
      expect(
        find.text('Apakah Anda yakin ingin membatalkan panggilan montir ini?'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('confirmation_dialog_confirm_button')));
      await tester.pumpAndSettle();

      // Verifikasi status telah berubah menjadi Dibatalkan
      expect(find.text('Dibatalkan'), findsOneWidget);
      expect(find.byKey(const Key('cancel_help_request_button')), findsNothing);
    });

    testWidgets('HelpRequestDetailScreen: Menampilkan mekanik ditugaskan saat status onTheWay',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final assignedReq = ServiceRequest(
        id: 'req-assigned-01',
        userId: 'user-001',
        issueCategory: CommonIssues.mesinMogok,
        issueDescription: 'Motor mati mendadak di tanjakan.',
        addressText: 'Jl. Merak No. 20',
        contactPhone: '081234567890',
        status: RequestStatus.onTheWay,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        mechanicId: 'mech-01',
        mechanic: Mechanic(
          id: 'mech-01',
          profileId: 'prof-mech-01',
          name: 'Agus Mekanik Hebat',
          phone: '081233334444',
          workshopName: 'Bengkel Resmi Jaya',
          createdAt: DateTime.now(),
        ),
      );

      final mockRepo = MockHelpRequestRepository(initialRequests: [assignedReq]);

      await tester.pumpWidget(
        createTestWidget(
          child: const HelpRequestDetailScreen(requestId: 'req-assigned-01'),
          helpRepo: mockRepo,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Verifikasi info mekanik & live map tracking yang langsung tampil
      expect(find.text('Dalam Perjalanan'), findsOneWidget);
      expect(find.text('Mekanik yang Ditugaskan'), findsOneWidget);
      expect(find.text('Agus Mekanik Hebat'), findsAtLeastNWidgets(1));
      expect(find.text('Bengkel Resmi Jaya'), findsOneWidget);
      expect(find.byKey(const Key('call_mechanic_button')), findsOneWidget);
    });

    testWidgets('HelpRequestDetailScreen: Menampilkan opsi alternatif saat status expired (TC-19)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final expiredReq = ServiceRequest(
        id: 'req-expired-01',
        userId: 'user-001',
        issueCategory: CommonIssues.mesinMogok,
        issueDescription: 'Motor mogok tidak ada respon',
        addressText: 'Jl. Gatot Subroto No. 5',
        contactPhone: '081234567890',
        status: RequestStatus.expired,
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final mockRepo = MockHelpRequestRepository(initialRequests: [expiredReq]);

      await tester.pumpWidget(
        createTestWidget(
          child: const HelpRequestDetailScreen(requestId: 'req-expired-01'),
          helpRepo: mockRepo,
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Verifikasi tampilan expired dan tombol alternatif
      expect(find.text('Waktu Habis / Kedaluwarsa'), findsOneWidget);
      expect(find.byKey(const Key('expired_options_card')), findsOneWidget);
      expect(find.text('Mekanik Belum Tersedia'), findsOneWidget);
      expect(find.byKey(const Key('retry_help_request_button')), findsOneWidget);
      expect(find.byKey(const Key('contact_workshops_button')), findsOneWidget);
    });
  });
}
