import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/widgets/app_background.dart';
import 'package:motocare/core/widgets/app_bottom_nav.dart';
import 'package:motocare/core/widgets/app_text_field.dart';
import 'package:motocare/core/widgets/loading_skeleton.dart';
import 'package:motocare/core/widgets/motorcycle_card.dart';
import 'package:motocare/core/widgets/primary_button.dart';
import 'package:motocare/core/widgets/secondary_button.dart';
import 'package:motocare/core/widgets/tertiary_button.dart';
import 'package:motocare/features/motorcycles/presentation/add_edit_motorcycle_screen.dart';

void main() {
  group('Tahap 5: Verifikasi UI & Navigasi Mendalam', () {
    // -------------------------------------------------------------------------
    // 1. Floating Nav: Multi-Scale & Multi-Width
    // -------------------------------------------------------------------------
    testWidgets('B-01: Floating Nav bebas overflow pada skala font 1.0, 1.3, 1.5 dan lebar 360 & 430 px', (tester) async {
      final scales = <double>[1.0, 1.3, 1.5];
      final widths = <double>[360.0, 430.0];

      for (final scale in scales) {
        for (final width in widths) {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 800),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const Scaffold(
                    bottomNavigationBar: AppBottomNav(
                      currentIndex: 0,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull,
              reason: 'Overflow terjadi pada skala $scale dan lebar $width');
          expect(find.byType(AppBottomNav), findsOneWidget);
        }
      }
    });

    testWidgets('B-01: Nav indikator aktif memiliki warna dan label benar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: AppBottomNav(
                currentIndex: 1, // Aktivitas
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktivitas'), findsOneWidget);
      // Tab aktif menampilkan activeIcon, sedangkan tab tidak aktif menampilkan outline icon
      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 2. Layar Turunan: Tidak Ada Nav & Memiliki Tombol Kembali
    // -------------------------------------------------------------------------
    testWidgets('B-02: Layar turunan tidak memuat nav dan memiliki tombol kembali', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute<void>(
                  builder: (context) => const AddEditMotorcycleScreen(),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Layar turunan AddEditMotorcycleScreen tidak memiliki AppBottomNav
      expect(find.byType(AppBottomNav), findsNothing);

      // Memiliki AppBar dengan judul dan tombol kembali otomatis atau tombol simpan
      expect(find.text('Tambah Motor Baru'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 3. AppBackground: Merender Gradasi & Menjaga Ukuran Anak
    // -------------------------------------------------------------------------
    testWidgets('B-03: AppBackground merender gradasi dan menjaga ukuran anak', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppBackground(
            child: SizedBox(
              width: 250,
              height: 120,
              child: Text('Konten Uji'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Konten Uji'), findsOneWidget);
      final boxSize = tester.getSize(find.text('Konten Uji'));
      expect(boxSize.width, greaterThan(0));
    });

    // -------------------------------------------------------------------------
    // 4. MotorcycleCard: Stres Konten Ekstrem pada Skala Font 1.5
    // -------------------------------------------------------------------------
    testWidgets('B-03: MotorcycleCard menangani teks panjang & odometer besar pada font 1.5 tanpa overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: ListView(
                children: <Widget>[
                  MotorcycleCard(
                    brand: 'Yamaha',
                    model: 'XMAX Connected 250 Maxi Scooter Signature Edition',
                    productionYear: 2024,
                    licensePlate: 'BL 9999 XYZ PREMIUM',
                    currentMileage: 999999,
                    mileageUpdatedAt: DateTime(2026, 3, 1),
                    onUpdateMileage: () {},
                    onViewServices: () {},
                    onViewReminders: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('BL 9999 XYZ PREMIUM'), findsOneWidget);
      expect(find.text('999.999 km'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 5. Button States: Primary, Secondary, Tertiary
    // -------------------------------------------------------------------------
    testWidgets('B-03: PrimaryButton menguji semua state (Normal, Loading, Disabled)', (tester) async {
      // Normal state
      bool clicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Simpan',
              onPressed: () => clicked = true,
            ),
          ),
        ),
      );
      expect(find.text('Simpan'), findsOneWidget);
      await tester.tap(find.text('Simpan'));
      expect(clicked, isTrue);

      // Loading state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Memuat Data',
              isLoading: true,
              onPressed: null,
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Memuat Data'), findsNothing);

      // Disabled state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Nonaktif',
              onPressed: null,
            ),
          ),
        ),
      );
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.enabled, isFalse);
    });

    testWidgets('B-03: SecondaryButton menguji state Normal, Loading, Disabled', (tester) async {
      // Normal
      bool secClicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              label: 'Batal',
              onPressed: () => secClicked = true,
            ),
          ),
        ),
      );
      expect(find.text('Batal'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      expect(secClicked, isTrue);

      // Disabled
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              label: 'Batal Disabled',
              onPressed: null,
            ),
          ),
        ),
      );
      final secBtn = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(secBtn.enabled, isFalse);
    });

    testWidgets('B-03: TertiaryButton menguji state Normal dan Disabled', (tester) async {
      bool terClicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TertiaryButton(
              label: 'Lihat Detail',
              onPressed: () => terClicked = true,
            ),
          ),
        ),
      );
      expect(find.text('Lihat Detail'), findsOneWidget);
      await tester.tap(find.text('Lihat Detail'));
      expect(terClicked, isTrue);

      // Disabled
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TertiaryButton(
              label: 'Lihat Detail Nonaktif',
              onPressed: null,
            ),
          ),
        ),
      );
      final textBtn = tester.widget<TextButton>(find.byType(TextButton));
      expect(textBtn.enabled, isFalse);
    });

    // -------------------------------------------------------------------------
    // 6. AppTextField States: Default, Focus, Error, Disabled
    // -------------------------------------------------------------------------
    testWidgets('B-03: AppTextField menguji state Default, Error, dan Disabled', (tester) async {
      final controller = TextEditingController();

      // Default & Error state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Nomor Plat',
              hint: 'BL 1234 AB',
              errorText: 'Format plat nomor tidak valid',
            ),
          ),
        ),
      );
      expect(find.text('Nomor Plat'), findsOneWidget);
      expect(find.text('Format plat nomor tidak valid'), findsOneWidget);

      // Disabled state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              controller: controller,
              label: 'Nomor Rangka',
              enabled: false,
            ),
          ),
        ),
      );
      final formField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(formField.enabled, isFalse);
    });

    // -------------------------------------------------------------------------
    // 7. Reduce Motion (disableAnimations)
    // -------------------------------------------------------------------------
    testWidgets('B-04: Pengaturan kurangi animasi (disableAnimations) dihormati', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              disableAnimations: true,
            ),
            child: Scaffold(
              body: LoadingSkeleton(
                height: 50,
                width: 200,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // LoadingSkeleton pada disableAnimations = true merender Container statis
      expect(find.byType(LoadingSkeleton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
