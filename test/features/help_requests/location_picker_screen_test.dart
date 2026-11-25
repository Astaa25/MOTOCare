import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/help_requests/presentation/location_picker_screen.dart';

void main() {
  Widget buildTestWidget({LocationDraft? draft}) {
    return ProviderScope(
      child: MaterialApp(
        home: LocationPickerScreen(initialDraft: draft),
      ),
    );
  }

  group('LocationPickerScreen Widget Tests (Figma 03.02 / Tahap 3)', () {
    testWidgets('Menampilkan judul "Di mana kamu menunggu?" dan input utama', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Di mana kamu menunggu?'), findsOneWidget);
      expect(find.byKey(const Key('places_autocomplete_search_field')), findsOneWidget);
      expect(find.byKey(const Key('picker_address_field')), findsOneWidget);
      expect(find.byKey(const Key('picker_landmark_field')), findsOneWidget);
      expect(find.byKey(const Key('picker_chip_lhokseumawe')), findsOneWidget);
      expect(find.byKey(const Key('picker_chip_aceh_utara')), findsOneWidget);
      expect(find.byKey(const Key('btn_confirm_location_picker')), findsOneWidget);
    });

    testWidgets('Tombol "Gunakan lokasi ini" dinonaktifkan jika alamat kosong / < 5 karakter', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          draft: const LocationDraft(
            addressText: 'Jl.',
            cityRegency: 'Kota Lhokseumawe',
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const Key('btn_confirm_location_picker')),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Alamat lokasi minimal 5 karakter.'), findsOneWidget);
    });

    testWidgets('Memilih chip wilayah mengubah pilihan kota/kabupaten', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byKey(const Key('picker_chip_aceh_utara')));
      await tester.pumpAndSettle();

      final chipAcehUtara = tester.widget<ChoiceChip>(find.byKey(const Key('picker_chip_aceh_utara')));
      expect(chipAcehUtara.selected, isTrue);
    });

    testWidgets('Mengetik alamat valid mengaktifkan tombol konfirmasi', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());

      await tester.enterText(
        find.byKey(const Key('picker_address_field')),
        'Jl. Merdeka No. 45, Banda Sakti, Kota Lhokseumawe',
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const Key('btn_confirm_location_picker')),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
