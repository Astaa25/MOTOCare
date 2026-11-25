import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/widgets/motorcycle_card.dart';
import 'package:motocare/core/widgets/primary_button.dart';
import 'package:motocare/core/widgets/secondary_button.dart';
import 'package:motocare/core/widgets/tertiary_button.dart';

void main() {
  group('T-02: Visual Components Tests', () {
    testWidgets('TertiaryButton render text and responds to tap', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TertiaryButton(
                key: const Key('test_tertiary_btn'),
                label: 'Lihat Semua',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Lihat Semua'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      await tester.tap(find.byKey(const Key('test_tertiary_btn')));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('PrimaryButton renders with label and icon at 52px height', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PrimaryButton(
                key: const Key('test_primary_btn'),
                label: 'Panggil Montir Sekarang',
                icon: Icons.build_circle_rounded,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Panggil Montir Sekarang'), findsOneWidget);
      expect(find.byIcon(Icons.build_circle_rounded), findsOneWidget);

      final buttonFinder = find.byKey(const Key('test_primary_btn'));
      final buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.height, equals(52.0));

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('SecondaryButton renders with outline and 52px height', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SecondaryButton(
                key: const Key('test_secondary_btn'),
                label: 'Batal',
                icon: Icons.close_rounded,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Batal'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      final buttonFinder = find.byKey(const Key('test_secondary_btn'));
      final buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.height, equals(52.0));

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('MotorcycleCard renders license plate and tabular mileage properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MotorcycleCard(
                brand: 'Honda',
                model: 'Vario 160',
                productionYear: 2023,
                licensePlate: 'BL 4521 KF',
                currentMileage: 14500,
                mileageUpdatedAt: DateTime(2026, 3, 1),
                onUpdateMileage: () {},
                onViewServices: () {},
                onViewReminders: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Honda Vario 160'), findsOneWidget);
      expect(find.text('Tahun 2023'), findsOneWidget);
      expect(find.text('BL 4521 KF'), findsOneWidget);
      expect(find.text('14.500 km'), findsOneWidget);
      expect(find.text('Update KM'), findsOneWidget);
      expect(find.text('Riwayat Servis'), findsOneWidget);
      expect(find.text('Pengingat'), findsOneWidget);
    });
  });
}
