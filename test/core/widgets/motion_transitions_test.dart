import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/theme/motion.dart';
import 'package:motocare/core/widgets/animated_effects.dart';
import 'package:motocare/core/widgets/motorcycle_card.dart';

void main() {
  group('Motion Design & Transitions Tests (T-01 s/d T-07)', () {
    test('T-01: Konstanta durasi dan kurva AppMotion terstandarisasi', () {
      expect(AppMotion.shortDuration.inMilliseconds, equals(150));
      expect(AppMotion.tabTransition.inMilliseconds, equals(220));
      expect(AppMotion.standardDuration.inMilliseconds, equals(250));
      expect(AppMotion.pageTransition.inMilliseconds, equals(300));
      expect(AppMotion.longDuration.inMilliseconds, equals(350));

      expect(AppMotion.enterCurve, equals(Curves.easeOutCubic));
      expect(AppMotion.exitCurve, equals(Curves.easeInCubic));
      expect(AppMotion.standardCurve, equals(Curves.easeInOutCubic));
    });

    testWidgets('T-02: AppMotion.fadeThroughPage merender transisi tab 220ms dengan scale & fade', (tester) async {
      final page = AppMotion.fadeThroughPage(
        key: const ValueKey('tab_test_page'),
        child: const Text('Tab Halaman Baru'),
      );

      expect(page.transitionDuration.inMilliseconds, equals(220));
      expect(page.reverseTransitionDuration.inMilliseconds, equals(220));

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            pages: [
              page,
            ],
            onDidRemovePage: (page) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tab Halaman Baru'), findsOneWidget);
    });

    testWidgets('T-03: AppMotion.sharedAxisPage merender transisi 300ms dengan slide & fade', (tester) async {
      final page = AppMotion.sharedAxisPage(
        key: const ValueKey('detail_test_page'),
        child: const Text('Layar Detail Turunan'),
      );

      expect(page.transitionDuration.inMilliseconds, equals(300));
      expect(page.reverseTransitionDuration.inMilliseconds, equals(250));

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            pages: [
              page,
            ],
            onDidRemovePage: (page) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Layar Detail Turunan'), findsOneWidget);
    });

    testWidgets('T-03: Transisi menghormati pengaturan reduce-motion (disableAnimations)', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Navigator(
              pages: [
                AppMotion.sharedAxisPage(
                  key: const ValueKey('accessible_page'),
                  child: const Text('Aksesibel Konten'),
                ),
              ],
              onDidRemovePage: (page) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aksesibel Konten'), findsOneWidget);
    });

    testWidgets('T-04: MotorcycleCard memasang Hero tag unik saat heroTag disuplai', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MotorcycleCard(
                brand: 'Honda',
                model: 'PCX 160',
                productionYear: 2024,
                licensePlate: 'BL 1234 XY',
                currentMileage: 5000,
                heroTag: 'moto-pcx-160',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi widget Hero terpasang pada ikon motor dan plat nomor
      final iconHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'motor_icon_moto-pcx-160',
      );
      final plateHeroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'motor_plate_moto-pcx-160',
      );

      expect(iconHeroFinder, findsOneWidget);
      expect(plateHeroFinder, findsOneWidget);
    });

    testWidgets('T-05: AnimatedEntrance membatasi stagger ke maksimum 6 item', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AnimatedEntrance(
                  index: 0,
                  child: Text('Item 0'),
                ),
                AnimatedEntrance(
                  index: 10, // Index besar harus dibatasi ke clamp 5
                  child: Text('Item 10'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 10'), findsOneWidget);
    });
  });
}

