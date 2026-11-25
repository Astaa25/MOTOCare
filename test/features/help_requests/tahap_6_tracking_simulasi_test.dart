import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/core/theme/app_theme.dart';
import 'package:motocare/features/help_requests/data/mock_help_request_repository.dart';
import 'package:motocare/features/help_requests/domain/mechanic.dart';
import 'package:motocare/features/help_requests/domain/request_status.dart';
import 'package:motocare/features/help_requests/domain/service_request.dart';
import 'package:motocare/features/help_requests/presentation/help_request_detail_screen.dart';
import 'package:motocare/features/help_requests/presentation/help_requests_providers.dart';
import 'package:motocare/features/help_requests/presentation/widgets/simulated_mechanic_tracking_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget createWidget({
    required Widget child,
    MockHelpRequestRepository? repository,
  }) {
    return ProviderScope(
      overrides: [
        if (repository != null)
          helpRequestRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  final testMechanic = Mechanic(
    id: 'mech-01',
    profileId: 'prof-mech-01',
    name: 'Bang Rudi Pratama',
    phone: '081269009988',
    workshopName: 'Bengkel Resmi Samudera Motor',
    createdAt: DateTime(2026, 10, 1),
  );

  final testRequestOtw = ServiceRequest(
    id: 'req-otw-01',
    userId: 'user-01',
    issueCategory: 'Ban Bocor',
    issueDescription: 'Ban kempes kena paku',
    addressText: 'Jl. Merdeka Barat No. 88, Banda Sakti, Kota Lhokseumawe',
    cityRegency: 'Kota Lhokseumawe',
    latitude: 5.1801,
    longitude: 97.1402,
    contactPhone: '081234567890',
    status: RequestStatus.onTheWay,
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    mechanicId: 'mech-01',
    mechanic: testMechanic,
    isDemo: true,
  );

  group('Tahap 6 — Tracking Montir (Opsi A: Simulasi)', () {
    testWidgets('SimulatedMechanicTrackingCard menampilkan badge kejujuran data simulasi dan metrik',
        (tester) async {
      await tester.pumpWidget(
        createWidget(
          child: SimulatedMechanicTrackingCard(
            request: testRequestOtw,
            initialDistanceKm: 1.5,
            initialEtaMinutes: 5,
          ),
        ),
      );
      await tester.pump();

      // 1. Banner live GPS tracking (tanpa label simulasi di mode produksi)
      expect(find.byKey(const Key('tracking_simulation_badge')), findsOneWidget);
      expect(
        find.text('Live GPS Tracking Aktif • Mengikuti Rute Jalan'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('interactive_live_osm_map')), findsOneWidget);
      expect(find.text('Buka Live Tracking Peta Penuh (Mode Gojek)'), findsNothing);

      // 2. Metrik Jarak Tersisa & ETA (diperbarui secara dinamis dari stream lokasi)
      final distanceFinder = find.byKey(const Key('tracking_remaining_distance'));
      expect(distanceFinder, findsOneWidget);
      expect(tester.widget<Text>(distanceFinder).data, contains('km'));

      final etaFinder = find.byKey(const Key('tracking_eta_time'));
      expect(etaFinder, findsOneWidget);
      expect(tester.widget<Text>(etaFinder).data, contains('menit'));

      // 3. Status waktu pembaruan
      expect(find.byKey(const Key('tracking_update_time')), findsOneWidget);
      expect(find.textContaining('Diperbarui: Baru saja'), findsOneWidget);
    });

    testWidgets('SimulatedMechanicTrackingCard menangani kondisi Figma 09.07 (Lokasi belum diperbarui)',
        (tester) async {
      await tester.pumpWidget(
        createWidget(
          child: SimulatedMechanicTrackingCard(
            request: testRequestOtw,
            isForceStale: true,
          ),
        ),
      );
      await tester.pump();

      // Banner Figma 09.07
      expect(find.byKey(const Key('tracking_stale_location_banner')), findsOneWidget);
      expect(find.text('Lokasi belum diperbarui'), findsOneWidget);
      expect(find.text('Menampilkan posisi terakhir yang tercatat'), findsOneWidget);

      // Tekan tombol Perbarui
      expect(find.byKey(const Key('tracking_retry_refresh_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('tracking_retry_refresh_button')));
      await tester.pump();

      // Banner stale hilang setelah diperbarui
      expect(find.byKey(const Key('tracking_stale_location_banner')), findsNothing);
    });

    testWidgets('HelpRequestDetailScreen menampilkan tracking saat status onTheWay (Figma 03.08 & 03.09)',
        (tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = MockHelpRequestRepository(initialRequests: [testRequestOtw]);

      await tester.pumpWidget(
        createWidget(
          child: const HelpRequestDetailScreen(requestId: 'req-otw-01'),
          repository: repo,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tampil kartu tracking real-time terintegrasi langsung tanpa tombol ekstra
      expect(find.byKey(const Key('simulated_mechanic_tracking_card')), findsOneWidget);
      expect(
        find.text('Live GPS Tracking Aktif • Mengikuti Rute Jalan'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('interactive_live_osm_map')), findsOneWidget);
      expect(find.text('Bang Rudi Pratama'), findsAtLeastNWidgets(1));
    });

    testWidgets('HelpRequestDetailScreen menampilkan kartu Montir Sudah Tiba saat inProgress (Figma 03.10)',
        (tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final reqInProgress = testRequestOtw.copyWith(
        id: 'req-inp-01',
        status: RequestStatus.inProgress,
      );
      final repo = MockHelpRequestRepository(initialRequests: [reqInProgress]);

      await tester.pumpWidget(
        createWidget(
          child: const HelpRequestDetailScreen(requestId: 'req-inp-01'),
          repository: repo,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tampil kartu arrived Figma 03.10
      expect(find.byKey(const Key('mechanic_arrived_status_card')), findsOneWidget);
      expect(find.text('Montir Sudah Tiba di Lokasi'), findsWidgets);
      expect(find.text('0 km (Tiba)'), findsOneWidget);
      expect(find.text('Sudah Tiba'), findsOneWidget);
    });

    testWidgets('HelpRequestDetailScreen menampilkan tombol Kembali ke Aktivitas saat completed (Figma 03.11)',
        (tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final reqCompleted = testRequestOtw.copyWith(
        id: 'req-comp-01',
        status: RequestStatus.completed,
      );
      final repo = MockHelpRequestRepository(initialRequests: [reqCompleted]);

      await tester.pumpWidget(
        createWidget(
          child: const HelpRequestDetailScreen(requestId: 'req-comp-01'),
          repository: repo,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tampil tombol Kembali ke Aktivitas (Figma 03.11)
      expect(find.byKey(const Key('back_to_activity_button')), findsOneWidget);
      expect(find.text('Kembali ke Aktivitas'), findsOneWidget);
    });
  });
}
