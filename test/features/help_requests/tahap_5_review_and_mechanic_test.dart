import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/auth/presentation/auth_state_provider.dart';
import 'package:motocare/features/help_requests/data/mock_help_request_repository.dart';
import 'package:motocare/features/help_requests/presentation/create_help_request_screen.dart';
import 'package:motocare/features/help_requests/presentation/help_requests_providers.dart';
import 'package:motocare/features/help_requests/presentation/widgets/mini_map_picker_preview.dart';
import 'package:motocare/features/home/presentation/mechanic_home_screen.dart';
import 'package:motocare/features/motorcycles/data/mock_motorcycle_repository.dart';
import 'package:motocare/features/motorcycles/presentation/motorcycle_providers.dart';
import 'package:motocare/features/profile/domain/user_profile.dart';

Widget _buildTestApp({
  required Widget child,
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: <Override>[
      currentUserProvider.overrideWith(
        (ref) => UserProfile(
          id: 'user-001',
          email: 'pengendara@motocare.id',
          fullName: 'Budi Darsono',
          role: 'user',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ),
      helpRequestRepositoryProvider.overrideWithValue(MockHelpRequestRepository()),
      motorcycleRepositoryProvider.overrideWithValue(
        MockMotorcycleRepository(populateDemoData: true),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('Tahap 5 Widget Tests: Peta pada Alur Pelanggan dan Mekanik (Figma 03.04, 07.02)', () {
    testWidgets('CreateHelpRequestScreen: Menampilkan Layar Tinjau Permintaan (Figma 03.04)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(child: const CreateHelpRequestScreen()));
      await tester.pumpAndSettle();

      // Isi data form
      await tester.enterText(
        find.byKey(const Key('issue_description_field')),
        'Motor mogok mendadak di jalan raya dekat masjid',
      );
      await tester.enterText(
        find.byKey(const Key('help_address_field')),
        'Jl. Merdeka Barat No. 88, Banda Sakti',
      );
      await tester.enterText(
        find.byKey(const Key('help_landmark_field')),
        'Samping Indomaret Simpang Kandang',
      );
      await tester.enterText(
        find.byKey(const Key('contact_phone_field')),
        '081234567890',
      );
      await tester.pumpAndSettle();

      // Tekan tombol submit
      await tester.tap(find.byKey(const Key('submit_help_request_button')));
      await tester.pumpAndSettle();

      // Verifikasi Tinjau Permintaan (Figma 03.04)
      expect(find.text('Konfirmasi Panggilan Montir'), findsOneWidget);
      expect(find.text('Lokasi Penjemputan'), findsOneWidget);
      expect(find.text('Jl. Merdeka Barat No. 88, Banda Sakti'), findsWidgets);
      expect(find.text('Patokan: Samping Indomaret Simpang Kandang'), findsOneWidget);
      expect(find.text('Kontak: 081234567890'), findsOneWidget);
      expect(
        find.text('Mekanik terdekat akan segera dihubungi. Permintaan aktif selama 15 menit.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('confirmation_dialog_confirm_button')), findsOneWidget);
      expect(find.byKey(const Key('confirmation_dialog_cancel_button')), findsOneWidget);

      // Mengetuk tombol periksa kembali menutup modal
      await tester.tap(find.byKey(const Key('confirmation_dialog_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Panggilan Montir'), findsNothing);
    });

    testWidgets('MechanicHomeScreen: Menjaga privasi kontak saat status pending (Figma 07.02)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestApp(
          overrides: <Override>[
            currentUserProvider.overrideWith(
              (ref) => UserProfile(
                id: 'mech-001',
                email: 'mekanik@motocare.id',
                fullName: 'Mekanik Samudera',
                role: 'mechanic',
                createdAt: DateTime(2026, 1, 1),
                updatedAt: DateTime(2026, 1, 1),
              ),
            ),
          ],
          child: const MechanicHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Saat pending: Tombol telepon TIDAK boleh tampil
      expect(find.byKey(const Key('call_customer_button')), findsNothing);

      // Saat pending: Notice privasi WAJIB tampil
      expect(find.byKey(const Key('mechanic_privacy_notice')), findsOneWidget);
      expect(
        find.text('Kontak telepon dan rute navigasi akan terbuka setelah panggilan diterima demi privasi pengguna.'),
        findsOneWidget,
      );

      // Patokan lokasi dan mini peta tampil
      expect(find.byKey(const Key('mechanic_order_landmark')), findsOneWidget);
      expect(find.textContaining('Patokan: Dekat Tugu Simpang Elak'), findsOneWidget);
      expect(find.byType(MiniMapPickerPreview), findsOneWidget);

      // Tombol aksi mekanik tersedia
      expect(find.text('Terima Panggilan'), findsOneWidget);
      expect(find.text('Tolak'), findsOneWidget);
    });

    testWidgets('MechanicHomeScreen: Membuka kontak dan navigasi setelah panggilan diterima',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _buildTestApp(
          overrides: <Override>[
            currentUserProvider.overrideWith(
              (ref) => UserProfile(
                id: 'mech-001',
                email: 'mekanik@motocare.id',
                fullName: 'Mekanik Samudera',
                role: 'mechanic',
                createdAt: DateTime(2026, 1, 1),
                updatedAt: DateTime(2026, 1, 1),
              ),
            ),
          ],
          child: const MechanicHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tekan tombol Terima Panggilan
      await tester.tap(find.text('Terima Panggilan'));
      await tester.pumpAndSettle();

      // Konfirmasi dialog penerimaan
      expect(find.text('Konfirmasi Terima'), findsOneWidget);
      await tester.tap(find.text('Konfirmasi Terima'));
      await tester.pumpAndSettle();

      // Setelah diterima: Notice privasi hilang
      expect(find.byKey(const Key('mechanic_privacy_notice')), findsNothing);

      // Tombol telepon dan rute sekarang AKTIF
      expect(find.byKey(const Key('call_customer_button')), findsOneWidget);
      expect(find.byKey(const Key('open_mechanic_route_button')), findsOneWidget);

      // Langkah berikutnya: Mulai Berangkat ke Lokasi (OTW)
      expect(find.text('Mulai Berangkat ke Lokasi (OTW)'), findsOneWidget);
    });
  });
}
