import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/app.dart';
import 'package:motocare/core/theme/app_theme.dart';
import 'package:motocare/features/auth/data/mock_auth_repository.dart';
import 'package:motocare/features/auth/domain/auth_repository.dart';
import 'package:motocare/features/auth/presentation/auth_state_provider.dart';
import 'package:motocare/features/auth/presentation/login_screen.dart';
import 'package:motocare/features/auth/presentation/register_screen.dart';
import 'package:motocare/features/profile/presentation/profile_screen.dart';

void main() {
  Widget createTestApp({
    AuthRepository? repository,
    Widget? home,
  }) {
    final mockRepo = repository ?? MockAuthRepository();

    if (home != null) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: home,
        ),
      );
    }

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MotoCareApp(),
    );
  }

  group('Widget Tests Layar Autentikasi & Profil (M2)', () {
    testWidgets('LoginScreen: Validasi isian kosong dan format email salah',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(home: const LoginScreen()),
      );

      // Tekan tombol Masuk tanpa mengisi form
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      // Verifikasi pesan validasi muncul
      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);

      // Masukkan format email yang salah
      await tester.enterText(
        find.byKey(const Key('login_email_field')).descendant(find.byType(TextFormField)),
        'bukan-email',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      expect(find.text('Format email tidak valid'), findsOneWidget);
    });

    testWidgets('LoginScreen: Menampilkan banner error saat kata sandi salah',
        (WidgetTester tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        createTestApp(
          repository: mockRepo,
          home: const LoginScreen(),
        ),
      );

      // Isi email benar tapi password salah
      await tester.enterText(
        find.byKey(const Key('login_email_field')).descendant(find.byType(TextFormField)),
        MockAuthRepository.demoEmail,
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')).descendant(find.byType(TextFormField)),
        'PasswordSalah99',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verifikasi banner error ramah tampil
      expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
      expect(
        find.text('Email atau kata sandi yang Anda masukkan salah.'),
        findsOneWidget,
      );
    });

    testWidgets('RegisterScreen: Validasi field pendaftaran lengkap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(home: const RegisterScreen()),
      );

      // Tekan daftar tanpa isi
      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pump();

      expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
      expect(find.text('Nomor telepon wajib diisi'), findsOneWidget);
      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    });

    testWidgets('TC-18: ProfileScreen menampilkan profil dan konfirmasi logout',
        (WidgetTester tester) async {
      final mockRepo = MockAuthRepository(startAuthenticated: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfileScreen(),
          ),
        ),
      );

      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Inisialisasi sesi profil
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi komponen profil tampil (Figma 06.04)
      expect(find.text('Akun saya'), findsOneWidget);
      expect(find.text('Abrar Pengguna Demo'), findsWidgets);
      expect(find.text(MockAuthRepository.demoEmail), findsOneWidget);

      // Ketuk tombol logout
      await tester.scrollUntilVisible(find.byKey(const Key('profile_logout_button')), 100);
      expect(find.text('Keluar dari akun'), findsOneWidget);
      await tester.tap(find.byKey(const Key('profile_logout_button')));
      await tester.pumpAndSettle();

      // Verifikasi ConfirmationDialog muncul
      expect(find.text('Keluar dari Akun?'), findsOneWidget);
      expect(find.text('Ya, Keluar'), findsOneWidget);

      // Konfirmasi keluar
      await tester.tap(find.text('Ya, Keluar'));
      await tester.pumpAndSettle();

      // User session sekarang null
      final current = await mockRepo.getCurrentUser();
      expect(current.dataOrNull, isNull);
    });
  });
}

extension on Finder {
  Finder descendant(Finder matching) {
    return find.descendant(of: this, matching: matching);
  }
}
