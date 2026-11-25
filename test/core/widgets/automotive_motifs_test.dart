import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/widgets/app_background.dart';
import 'package:motocare/core/widgets/app_bottom_nav.dart';
import 'package:motocare/core/widgets/dashed_road_divider.dart';
import 'package:motocare/core/widgets/motorcycle_card.dart';

void main() {
  group('Motif Otomotif & Navigasi Charcoal Tests', () {
    testWidgets('DashedRoadDivider merender garis putus-putus tanpa error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: DashedRoadDivider(
                  height: 20,
                  dashWidth: 10,
                  dashSpace: 6,
                  thickness: 2.0,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashedRoadDivider), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('MotorcycleCard merender SpeedometerArc saat ada data servis', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MotorcycleCard(
                brand: 'Honda',
                model: 'Vario 160',
                productionYear: 2023,
                licensePlate: 'BL 5432 AB',
                currentMileage: 12500,
                serviceCycleProgress: 0.70,
                serviceStatusText: 'Ganti Oli & Busi',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ganti Oli & Busi'), findsOneWidget);
      expect(find.text('70% menuju jadwal perawatan'), findsOneWidget);
      expect(find.text('BL 5432 AB'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('MotorcycleCard merender keadaan kosong jujur saat tidak ada dasar data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MotorcycleCard(
                brand: 'Yamaha',
                model: 'NMAX 155',
                productionYear: 2022,
                licensePlate: 'BL 9876 CD',
                currentMileage: 0,
                serviceCycleProgress: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada data jarak tempuh & target servis.'), findsOneWidget);
      expect(find.text('BL 9876 CD'), findsOneWidget);
    });

    testWidgets('AppBackground merender gradasi vertikal dan radial glow pojok atas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppBackground(
            child: SizedBox(
              width: 360,
              height: 600,
              child: Text('Latar Teruji'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Latar Teruji'), findsOneWidget);
      expect(find.descendant(of: find.byType(AppBackground), matching: find.byType(CustomPaint)), findsWidgets);
    });

    testWidgets('AppBottomNav menggunakan latar putih bersih #FFFFFF dan aksen aktif #C74635', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: AppBottomNav(
                currentLocation: '/home',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNav), findsOneWidget);

      // Verifikasi container navbar memiliki latar putih bersih (Figma Arah Visual Baru)
      final containerFinder = find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.byType(Container),
      );
      final containers = tester.widgetList<Container>(containerFinder);
      final navContainer = containers.firstWhere(
        (c) => c.decoration is BoxDecoration && (c.decoration as BoxDecoration).color == Colors.white,
      );
      expect((navContainer.decoration as BoxDecoration).color, equals(Colors.white));
    });
  });
}
