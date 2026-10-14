import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/core/errors/app_exception.dart';
import 'package:motocare/core/theme/app_theme.dart';
import 'package:motocare/core/theme/motion.dart';
import 'package:motocare/core/utils/network_guard.dart';
import 'package:motocare/core/widgets/app_icon_button.dart';
import 'package:motocare/core/widgets/error_state.dart';
import 'package:motocare/core/widgets/loading_skeleton.dart';
import 'package:motocare/core/widgets/primary_button.dart';
import 'package:motocare/features/home/presentation/home_screen.dart';
import 'package:motocare/features/motorcycles/data/mock_motorcycle_repository.dart';
import 'package:motocare/features/motorcycles/presentation/motorcycle_providers.dart';
import 'package:motocare/features/motorcycles/presentation/motorcycles_screen.dart';
import 'package:motocare/features/profile/presentation/profile_screen.dart';
import 'package:motocare/features/tutorials/data/mock_tutorial_repository.dart';
import 'package:motocare/features/tutorials/presentation/tutorials_providers.dart';
import 'package:motocare/features/tutorials/presentation/tutorials_screen.dart';
import 'package:motocare/features/workshops/data/mock_workshop_repository.dart';
import 'package:motocare/features/workshops/presentation/workshops_providers.dart';
import 'package:motocare/features/workshops/presentation/workshops_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('NetworkGuard Unit Tests (PRD M8: Timeout 15s & 1x Retry)', () {
    test('safeRead: Berhasil mengembalikan nilai saat panggilan normal tanpa kendala', () async {
      final result = await NetworkGuard.safeRead(() async {
        return 'data-sukses';
      });
      expect(result, 'data-sukses');
    });

    test('safeRead: Melakukan retry 1x saat terjadi timeout/network issue lalu berhasil pada percobaan kedua', () async {
      int attempts = 0;
      final result = await NetworkGuard.safeRead(() async {
        attempts++;
        if (attempts == 1) {
          throw TimeoutException('Koneksi timeout');
        }
        return 'sukses-setelah-retry';
      });

      expect(attempts, 2);
      expect(result, 'sukses-setelah-retry');
    });

    test('safeRead: Melemparkan NetworkException dengan pesan ramah saat retry habis', () async {
      int attempts = 0;
      await expectLater(
        () => NetworkGuard.safeRead(() async {
          attempts++;
          throw const NetworkException();
        }),
        throwsA(isA<NetworkException>().having(
          (e) => e.message,
          'message',
          contains('Koneksi internet bermasalah'),
        )),
      );
      expect(attempts, 2); // 1 initial + 1 retry
    });
  });

  group('Aksesibilitas & Ketahanan Jaringan (Milestone M8 / TC-14, TC-15, TC-16, TC-24)', () {
    testWidgets('TC-14: Jaringan lambat menampilkan LoadingSkeleton dan UI tidak membeku',
        (WidgetTester tester) async {
      final completer = Completer<String>();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: FutureBuilder<String>(
              future: completer.future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: LoadingSkeleton(
                      key: Key('loading_skeleton_test'),
                      height: 120,
                      borderRadius: 16,
                    ),
                  );
                }
                return const Text('Data Selesai Dimuat');
              },
            ),
          ),
        ),
      );

      // Pastikan skeleton langsung tampil saat menunggu respon jaringan
      await tester.pump();
      expect(find.byKey(const Key('loading_skeleton_test')), findsOneWidget);

      // Selesaikan panggilan jaringan
      completer.complete('selesai');
      await tester.pumpAndSettle();

      expect(find.text('Data Selesai Dimuat'), findsOneWidget);
    });

    testWidgets('TC-15: API gagal menampilkan ErrorState dengan tombol Coba lagi',
        (WidgetTester tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ErrorState(
              title: 'Gagal Memuat Data',
              message: 'Koneksi internet bermasalah. Periksa koneksi Anda dan coba lagi.',
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Data'), findsOneWidget);
      expect(find.text('Koneksi internet bermasalah. Periksa koneksi Anda dan coba lagi.'), findsOneWidget);
      expect(find.byKey(const Key('error_state_retry_button')), findsOneWidget);

      // Tekan tombol coba lagi
      await tester.tap(find.byKey(const Key('error_state_retry_button')));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });

    testWidgets('TC-16: Pengaturan kurangi gerakan (disableAnimations) menonaktifkan animasi dekoratif',
        (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) {
                    final shouldDisable = AppMotion.shouldDisableAnimation(context);
                    final duration = AppMotion.getDuration(context, const Duration(milliseconds: 300));

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('DisableAnim: $shouldDisable'),
                        Text('DurationMs: ${duration.inMilliseconds}'),
                        PrimaryButton(
                          key: const Key('test_reduced_motion_button'),
                          label: 'Tombol Uji',
                          onPressed: () => buttonPressed = true,
                        ),
                        AppIconButton(
                          key: const Key('test_icon_button'),
                          icon: Icons.refresh,
                          semanticLabel: 'Segarkan',
                          onPressed: () {},
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('DisableAnim: true'), findsOneWidget);
      expect(find.text('DurationMs: 0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('test_reduced_motion_button')));
      expect(buttonPressed, isTrue);
    });

    testWidgets('TC-24: Skala font sistem 130% tidak memicu layout overflow pada HomeScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockMotorRepo = MockMotorcycleRepository(populateDemoData: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            motorcycleRepositoryProvider.overrideWithValue(mockMotorRepo),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const HomeScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'HomeScreen tidak boleh mengalami RenderFlex overflow pada skala teks 130%');
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('TC-24: Skala font sistem 130% tidak memicu overflow pada MotorcyclesScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockMotorRepo = MockMotorcycleRepository(populateDemoData: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            motorcycleRepositoryProvider.overrideWithValue(mockMotorRepo),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const MotorcyclesScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'MotorcyclesScreen tidak boleh mengalami overflow pada skala teks 130%');
    });

    testWidgets('TC-24: Skala font sistem 130% tidak memicu overflow pada ProfileScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const ProfileScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'ProfileScreen tidak boleh mengalami overflow pada skala teks 130%');
    });

    testWidgets('TC-24: Skala font sistem 130% tidak memicu overflow pada WorkshopsScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockWorkshopRepo = MockWorkshopRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workshopRepositoryProvider.overrideWithValue(mockWorkshopRepo),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const WorkshopsScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'WorkshopsScreen tidak boleh mengalami overflow pada skala teks 130%');
    });

    testWidgets('TC-24: Skala font sistem 130% tidak memicu overflow pada TutorialsScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockTutorialRepo = MockTutorialRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tutorialRepositoryProvider.overrideWithValue(mockTutorialRepo),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const TutorialsScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'TutorialsScreen tidak boleh mengalami overflow pada skala teks 130%');
    });
  });
}
