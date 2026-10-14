import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:motocare/core/theme/app_theme.dart';
import 'package:motocare/features/auth/presentation/splash_screen.dart';

void main() {
  Widget createTestWidget({
    Future<bool> Function()? customInitializer,
    Duration? minDuration,
    Duration? maxDuration,
    List<RouteBase>? routes,
  }) {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: routes ??
          <RouteBase>[
            GoRoute(
              path: '/splash',
              builder: (context, state) => SplashScreen(
                customInitializer: customInitializer,
                minDuration: minDuration,
                maxDuration: maxDuration,
              ),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) => const Scaffold(
                body: Text('Halaman Login Target'),
              ),
            ),
          ],
    );

    return ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  group('TC-25: Pengujian Splash Screen MotoCare', () {
    testWidgets('Menampilkan logo, teks MotoCare, dan indikator loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          customInitializer: () async {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            return true;
          },
          minDuration: const Duration(milliseconds: 3000),
        ),
      );

      // Verifikasi komponen awal
      expect(find.text('MOTO'), findsOneWidget);
      expect(find.text('CARE'), findsOneWidget);
      expect(find.text('Menyiapkan MotoCare...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets(
        'Inisialisasi cepat: Tidak navigasi sebelum durasi minimum tercapai',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          customInitializer: () async {
            // Selesai dalam 200 ms (sangat cepat)
            await Future<void>.delayed(const Duration(milliseconds: 200));
            return true;
          },
          minDuration: const Duration(milliseconds: 3000),
        ),
      );

      // Pada 500 ms (inisialisasi selesai tapi durasi min belum lewat)
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Halaman Login Target'), findsNothing);
      expect(find.text('Siap!'), findsOneWidget);

      // Pada 2000 ms (masih di bawah 3000 ms)
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('Halaman Login Target'), findsNothing);

      // Majukan hingga 3000 ms tercapai
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      // Sekarang sudah navigasi ke login
      expect(find.text('Halaman Login Target'), findsOneWidget);
    });

    testWidgets('Inisialisasi lambat: Menampilkan pesan progres informatif',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          customInitializer: () async {
            // Berjalan lambat melewati maxDuration
            await Future<void>.delayed(const Duration(milliseconds: 6000));
            return true;
          },
          minDuration: const Duration(milliseconds: 3000),
          maxDuration: const Duration(milliseconds: 5000),
        ),
      );

      // Sebelum 5000 ms
      await tester.pump(const Duration(milliseconds: 2000));
      expect(find.text('Menyiapkan MotoCare...'), findsOneWidget);

      // Lewati 5000 ms
      await tester.pump(const Duration(milliseconds: 3500));
      expect(
        find.text('Inisialisasi memakan waktu lebih lama dari biasanya...'),
        findsOneWidget,
      );

      // Selesaikan sisa timer
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Inisialisasi gagal: Menampilkan pesan error dan tombol Coba Lagi',
        (WidgetTester tester) async {
      int initAttempts = 0;

      await tester.pumpWidget(
        createTestWidget(
          customInitializer: () async {
            initAttempts++;
            if (initAttempts == 1) {
              return false; // Gagal pada percobaan pertama
            }
            return true; // Sukses pada percobaan kedua
          },
          minDuration: const Duration(milliseconds: 500),
        ),
      );

      // Biarkan inisialisasi pertama selesai dan gagal
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verifikasi pesan error dan tombol retry tampil
      expect(find.text('Gagal menginisialisasi aplikasi.'), findsOneWidget);
      expect(find.byKey(const Key('splash_retry_button')), findsOneWidget);

      // Ketuk tombol Coba Lagi
      await tester.tap(find.byKey(const Key('splash_retry_button')));
      await tester.pump();

      // Biarkan percobaan kedua berjalan hingga selesai
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verifikasi sukses navigasi ke login setelah dicoba lagi
      expect(find.text('Halaman Login Target'), findsOneWidget);
    });
  });
}
