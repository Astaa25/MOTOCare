import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/widgets/app_background.dart';
import 'package:motocare/core/widgets/app_bottom_nav.dart';
import 'package:motocare/features/auth/presentation/auth_state_provider.dart';
import 'package:motocare/features/profile/domain/user_profile.dart';

void main() {
  group('Floating Bottom Navigation Bar Widget Tests (N-03 & U-01)', () {
    Widget buildNavHarness({
      UserProfile? user,
      int? currentIndex,
      String? currentLocation,
      ValueChanged<int>? onTap,
      int unreadNotificationsCount = 0,
      double textScaleFactor = 1.0,
      double screenWidth = 360,
      double screenHeight = 800,
      double bottomViewInsets = 0,
    }) {
      return ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(user),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(screenWidth, screenHeight),
              textScaler: TextScaler.linear(textScaleFactor),
              viewInsets: EdgeInsets.only(bottom: bottomViewInsets),
            ),
            child: Scaffold(
              body: const Center(child: Text('Konten Layar')),
              bottomNavigationBar: AppBottomNav(
                currentIndex: currentIndex,
                currentLocation: currentLocation,
                onTap: onTap,
                unreadNotificationsCount: unreadNotificationsCount,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Pelanggan: menampilkan 4 tab (Beranda, Aktivitas, Motor, Akun)', (tester) async {
      await tester.pumpWidget(buildNavHarness(
        user: UserProfile(
          id: 'u1',
          fullName: 'Budi Santoso',
          email: 'budi@test.com',
          role: 'owner',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        currentIndex: 0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Aktivitas'), findsOneWidget);
      expect(find.text('Motor'), findsOneWidget);
      expect(find.text('Akun'), findsOneWidget);
    });

    testWidgets('Mekanik: menampilkan 4 tab tugas mekanik (Tugas, Bengkel, Panduan, Profil)', (tester) async {
      await tester.pumpWidget(buildNavHarness(
        user: UserProfile(
          id: 'm1',
          fullName: 'Pak Teuku Montir',
          email: 'teuku@test.com',
          role: 'mechanic',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        currentIndex: 0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tugas'), findsOneWidget);
      expect(find.text('Bengkel'), findsOneWidget);
      expect(find.text('Panduan'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('Admin: menampilkan 4 tab dashboard admin (Dashboard, Bengkel, Edukasi, Profil)', (tester) async {
      await tester.pumpWidget(buildNavHarness(
        user: UserProfile(
          id: 'a1',
          fullName: 'Admin Utama',
          email: 'admin@test.com',
          role: 'admin',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        currentIndex: 0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Bengkel'), findsOneWidget);
      expect(find.text('Edukasi'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('Aksesibilitas: tidak ada RenderFlex overflow pada skala font 130% dan 150%', (tester) async {
      // Uji pada skala 1.3
      await tester.pumpWidget(buildNavHarness(
        textScaleFactor: 1.3,
        screenWidth: 360,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Uji pada skala 1.5
      await tester.pumpWidget(buildNavHarness(
        textScaleFactor: 1.5,
        screenWidth: 360,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Responsif layar: bekerja mulus pada lebar sempit (360 px) dan lebar (430 px)', (tester) async {
      await tester.pumpWidget(buildNavHarness(
        screenWidth: 360,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNav), findsOneWidget);

      await tester.pumpWidget(buildNavHarness(
        screenWidth: 430,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomNav), findsOneWidget);
    });

    testWidgets('Keyboard virtual: nav tersembunyi saat keyboard terbuka', (tester) async {
      await tester.pumpWidget(buildNavHarness(
        bottomViewInsets: 280, // Keyboard terbuka 280 px
      ));
      await tester.pumpAndSettle();

      // Saat keyboard muncul, AppBottomNav menghasilkan SizedBox.shrink()
      expect(find.text('Beranda'), findsNothing);
    });

    testWidgets('Tapping tab memicu callback onTap dengan index yang tepat', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(buildNavHarness(
        currentIndex: 0,
        onTap: (index) => tappedIndex = index,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Motor'));
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(2));
    });

    testWidgets('Badge notifikasi tampil saat unreadNotificationsCount > 0', (tester) async {
      await tester.pumpWidget(buildNavHarness(
        unreadNotificationsCount: 3,
      ));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('AppBackground menyajikan gradasi hangat tanpa error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Text('Warm Background'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Warm Background'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.gradient, equals(AppBackground.warmGradient));
    });
  });
}
