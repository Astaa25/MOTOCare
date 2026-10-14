import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/tutorials/data/mock_tutorial_repository.dart';
import 'package:motocare/features/tutorials/presentation/tutorial_detail_screen.dart';
import 'package:motocare/features/tutorials/presentation/tutorials_providers.dart';
import 'package:motocare/features/tutorials/presentation/tutorials_screen.dart';

Widget _buildTestApp({
  required Widget child,
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: <Override>[
      tutorialRepositoryProvider.overrideWithValue(MockTutorialRepository()),
      ...overrides,
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('Widget Tests Tutorial Perawatan Mandiri (Milestone M6)', () {
    testWidgets('TutorialsScreen: Menampilkan judul, search bar, dan chip topik',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const TutorialsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Tutorial Perawatan'), findsOneWidget);
      expect(find.byKey(const Key('tutorial_search_field')), findsOneWidget);
      expect(find.byKey(const Key('topic_chip_Semua')), findsOneWidget);
      expect(find.byKey(const Key('topic_chip_Ganti_Oli')), findsOneWidget);
      expect(find.byKey(const Key('topic_chip_Rem')), findsOneWidget);

      // Daftar tutorial awal terisi
      expect(find.text('Cara Mengganti Oli Mesin Motor Sendiri di Rumah'), findsOneWidget);
    });

    testWidgets('TutorialsScreen: Memilih chip topik menyaring daftar tutorial',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const TutorialsScreen()));
      await tester.pumpAndSettle();

      // Pilih chip topik 'Rem'
      final remChip = find.byKey(const Key('topic_chip_Rem'));
      await tester.tap(remChip);
      await tester.pumpAndSettle();

      // Tutorial kampas rem harus tampil
      expect(
        find.text('Panduan Lengkap Mengganti Kampas Rem Cakram Depan'),
        findsOneWidget,
      );
    });

    testWidgets(
        'TC-08: Cari tutorial tanpa hasil menampilkan EmptyState dengan saran topik',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const TutorialsScreen()));
      await tester.pumpAndSettle();

      // Masukkan pencarian acak tanpa hasil
      final searchField = find.byKey(const Key('tutorial_search_field'));
      await tester.enterText(searchField, 'xyzcaritutorialkhayalan');
      // Tunggu debounce 300ms
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Memverifikasi EmptyState TC-08 dengan saran topik
      expect(find.byKey(const Key('empty_tutorials_state')), findsOneWidget);
      expect(find.text('Tutorial Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Saran Topik Perawatan Populer:'), findsOneWidget);
      expect(find.byKey(const Key('suggested_topic_Ganti_Oli')), findsOneWidget);
      expect(find.byKey(const Key('suggested_topic_Rem')), findsOneWidget);

      // Mengetuk salah satu saran topik mereset pencarian dan memilih topik tersebut
      final suggestedOli = find.byKey(const Key('suggested_topic_Ganti_Oli'));
      await tester.tap(suggestedOli);
      await tester.pumpAndSettle();

      // Hasil tutorial ganti oli tampil kembali
      expect(
        find.text('Cara Mengganti Oli Mesin Motor Sendiri di Rumah'),
        findsOneWidget,
      );
    });

    testWidgets(
        'TutorialDetailScreen & TC-23: Tampilkan detail dan aksi salin tautan video',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const TutorialDetailScreen(tutorialId: 'tut-01'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detail Tutorial'), findsOneWidget);
      expect(
        find.text('Cara Mengganti Oli Mesin Motor Sendiri di Rumah'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('watch_on_youtube_button')), findsOneWidget);

      // TC-23: Uji aksi salin tautan cepat
      final quickCopyButton = find.byKey(const Key('quick_copy_link_button'));
      expect(quickCopyButton, findsOneWidget);

      await tester.ensureVisible(quickCopyButton);
      await tester.tap(quickCopyButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Tautan video berhasil disalin ke papan klip.'),
        findsOneWidget,
      );
    });
  });
}
