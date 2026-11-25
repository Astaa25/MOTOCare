import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/theme/app_theme.dart';
import 'package:motocare/features/help_requests/domain/mechanic.dart';
import 'package:motocare/features/help_requests/domain/request_status.dart';
import 'package:motocare/features/help_requests/domain/service_request.dart';
import 'package:motocare/features/help_requests/presentation/help_requests_providers.dart';
import 'package:motocare/features/help_requests/presentation/live_tracking_screen.dart';

void main() {
  final testMechanic = Mechanic(
    id: 'mech-01',
    profileId: 'prof-mech-01',
    name: 'Bang Rudi Pratama',
    phone: '081269112201',
    workshopName: 'Bengkel Resmi Samudera Motor',
    createdAt: DateTime(2026, 10, 1),
  );

  final testRequestOtw = ServiceRequest(
    id: 'req-otw-01',
    userId: 'user-01',
    issueCategory: 'Mesin Mogok',
    issueDescription: 'Motor mati mendadak dekat Simpang Elak',
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
    isDemo: false,
  );

  Widget createWidget() {
    return ProviderScope(
      overrides: [
        helpRequestDetailProvider('req-otw-01').overrideWith(
          (ref) => Future.value(testRequestOtw),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LiveTrackingScreen(requestId: 'req-otw-01'),
      ),
    );
  }

  group('LiveTrackingScreen Widget Tests (Gojek / Grab Real-Time Maps Tracking)', () {
    testWidgets('Merender elemen utama live tracking peta, ETA, dan profil montir',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Header & Indikator Live GPS
      expect(find.byKey(const Key('live_tracking_back_button')), findsOneWidget);
      expect(find.text('LIVE TRACKING MONTIR'), findsOneWidget);

      // 2. Tombol Kontrol Peta
      expect(find.byKey(const Key('recenter_mechanic_button')), findsOneWidget);
      expect(find.byKey(const Key('recenter_user_button')), findsOneWidget);
      expect(find.byKey(const Key('fit_route_bounds_button')), findsOneWidget);

      // 3. Floating Bottom Sheet Gojek/Grab
      expect(find.byKey(const Key('live_tracking_eta_display')), findsOneWidget);
      expect(find.byKey(const Key('live_tracking_distance_display')), findsOneWidget);

      // 4. Identitas Montir & Plat Motor
      expect(find.text('Bang Rudi Pratama'), findsOneWidget);
      expect(find.text('Bengkel Resmi Samudera Motor'), findsOneWidget);
      expect(find.text('BL 4821 KAA'), findsOneWidget);

      // 5. Tombol Komunikasi Cepat Gojek/Grab
      expect(find.byKey(const Key('live_call_mechanic_button')), findsOneWidget);
      expect(find.byKey(const Key('live_whatsapp_mechanic_button')), findsOneWidget);
      expect(find.byKey(const Key('live_open_google_maps_button')), findsOneWidget);
    });

    testWidgets('Tombol kontrol peta merespons interaksi tap pengguna',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('recenter_user_button')), warnIfMissed: false);
      await tester.pump();

      await tester.tap(find.byKey(const Key('fit_route_bounds_button')), warnIfMissed: false);
      await tester.pump();

      await tester.tap(find.byKey(const Key('recenter_mechanic_button')), warnIfMissed: false);
      await tester.pump();
    });
  });
}
