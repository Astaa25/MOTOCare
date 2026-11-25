import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/workshops/data/mock_workshop_repository.dart';
import 'package:motocare/features/workshops/domain/workshop_rules.dart';
import 'package:motocare/features/workshops/presentation/workshop_detail_screen.dart';
import 'package:motocare/features/workshops/presentation/workshops_providers.dart';
import 'package:motocare/features/workshops/presentation/workshops_screen.dart';

Widget _buildTestApp({
  required Widget child,
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: <Override>[
      workshopRepositoryProvider.overrideWithValue(MockWorkshopRepository()),
      ...overrides,
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('Widget Tests Katalog Bengkel Terverifikasi (Milestone M6)', () {
    testWidgets(
        'WorkshopsScreen: Menampilkan kalimat cakupan permanen dan lencana demo',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const WorkshopsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Bengkel Terverifikasi'), findsOneWidget);

      // Verifikasi kalimat cakupan permanen sesuai PRD 2.2 & 7 M6
      expect(find.byKey(const Key('permanent_coverage_notice')), findsOneWidget);
      expect(find.text(WorkshopRules.permanentCoverageNotice), findsOneWidget);

      // Verifikasi mode produksi tidak menampilkan lencana Demo/Simulasi
      expect(find.byKey(const Key('demo_workshop_badge')), findsNothing);

      // Verifikasi daftar bengkel awal tanpa prefiks [Demo]
      expect(
        find.text('Bengkel Resmi Samudera Motor Lhokseumawe'),
        findsOneWidget,
      );
    });

    testWidgets(
        'TC-09: Cari bengkel di area cakupan hanya menampilkan data repository yang cocok',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const WorkshopsScreen()));
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('workshop_search_field'));
      await tester.enterText(searchField, 'Lhoksukon');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Bengkel Barokah Motor Lhoksukon harus tampil
      expect(
        find.text('Bengkel Barokah Motor Lhoksukon'),
        findsOneWidget,
      );
      // Bengkel lain di Lhokseumawe tidak boleh tampil
      expect(
        find.text('Bengkel Resmi Samudera Motor Lhokseumawe'),
        findsNothing,
      );
    });

    testWidgets(
        'TC-10: Cari bengkel di luar wilayah menampilkan pesan batas wilayah khusus',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const WorkshopsScreen()));
      await tester.pumpAndSettle();

      // Cari wilayah di luar cakupan operasional (contoh PRD: Medan)
      final searchField = find.byKey(const Key('workshop_search_field'));
      await tester.enterText(searchField, 'Medan');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Harus menampilkan OutOfCoverageState khusus, bukan EmptyState biasa
      expect(find.byKey(const Key('out_of_coverage_state')), findsOneWidget);
      expect(find.text('Wilayah di Luar Jangkauan Layanan'), findsOneWidget);
      expect(
        find.text(
          'Saat ini MotoCare hanya melayani wilayah Kota Lhokseumawe dan Kabupaten Aceh Utara. Kami belum dapat menampilkan bengkel di "Medan".',
        ),
        findsOneWidget,
      );

      // Mengetuk tombol aksi mereset pencarian
      final resetBtn = find.text('Lihat Bengkel Area Layanan');
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Kembali menampilkan daftar bengkel area layanan
      expect(
        find.text('Bengkel Resmi Samudera Motor Lhokseumawe'),
        findsOneWidget,
      );
    });

    testWidgets('WorkshopDetailScreen: Tampilkan detail, buka peta, dan tombol mekanik',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkshopDetailScreen(workshopId: 'ws-01'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detail Bengkel'), findsOneWidget);
      expect(
        find.text('Bengkel Resmi Samudera Motor Lhokseumawe'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('detail_demo_badge')), findsNothing);
      expect(find.text('Jam Operasional'), findsOneWidget);
      expect(find.text('08:00 - 17:00 WIB'), findsOneWidget);
      expect(find.byKey(const Key('call_workshop_button')), findsOneWidget);
      expect(find.byKey(const Key('open_workshop_map_button')), findsOneWidget);
      expect(
        find.byKey(const Key('request_mechanic_from_workshop_button')),
        findsOneWidget,
      );

      // Uji tombol salin alamat bengkel
      final copyAddressBtn = find.byKey(const Key('copy_workshop_address_button'));
      expect(copyAddressBtn, findsOneWidget);
      await tester.ensureVisible(copyAddressBtn);
      await tester.tap(copyAddressBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Alamat bengkel berhasil disalin ke papan klip.'),
        findsOneWidget,
      );
    });
  });
}
