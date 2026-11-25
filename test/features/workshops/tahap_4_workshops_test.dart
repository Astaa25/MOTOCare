import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/services/maps_cost_controller.dart';
import 'package:motocare/core/services/maps_places_service.dart';
import 'package:motocare/features/workshops/data/hybrid_workshop_repository.dart';
import 'package:motocare/features/workshops/data/mock_workshop_repository.dart';
import 'package:motocare/features/workshops/domain/workshop.dart';
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
  group('Tahap 4 Unit & Widget Tests: Pencarian & Detail Bengkel (Figma 05.01, 05.02)', () {
    test('MapsPlacesService.searchWorkshops mengembalikan daftar bengkel dan menyimpan cache', () async {
      final costController = MapsCostController();
      addTearDown(() => costController.dispose());

      final service = MapsPlacesService(costController: costController);
      final workshops = await service.searchWorkshops(
        query: 'Samudera',
        cityOrRegency: 'Kota Lhokseumawe',
      );

      expect(workshops.isNotEmpty, isTrue);
      expect(workshops.first.name, contains('Samudera'));

      // Cek cache memori
      final cachedWorkshops = await service.searchWorkshops(
        query: 'Samudera',
        cityOrRegency: 'Kota Lhokseumawe',
      );
      expect(cachedWorkshops.length, equals(workshops.length));
    });

    test('HybridWorkshopRepository mengambil detail dari mock atau places', () async {
      final costController = MapsCostController();
      addTearDown(() => costController.dispose());

      final service = MapsPlacesService(costController: costController);
      final repo = HybridWorkshopRepository(
        placesService: service,
        mockRepository: MockWorkshopRepository(),
      );

      final ws = await repo.getWorkshopById('ws-01');
      expect(ws, isNotNull);
      expect(ws!.id, equals('ws-01'));
      expect(ws.isDemo, isFalse);
    });

    testWidgets('WorkshopsScreen menampilkan Baris Lokasi Pencarian (Figma 05.01)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildTestApp(child: const WorkshopsScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('workshop_search_location_bar')), findsOneWidget);
      expect(find.text('Lokasi Pencarian'), findsOneWidget);
      expect(find.byKey(const Key('change_workshop_search_location_button')), findsOneWidget);
      expect(find.text('Ubah'), findsOneWidget);
    });

    testWidgets('WorkshopsScreen menerima initialCity dan mengaplikasikan filter awal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkshopsScreen(
            initialCity: WorkshopCoverageAreas.acehUtara,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bengkel di Aceh Utara harus tampil tanpa prefiks [Demo]
      expect(find.text('Bengkel Barokah Motor Lhoksukon'), findsOneWidget);
      // Bengkel di Lhokseumawe tidak boleh tampil
      expect(find.text('Bengkel Resmi Samudera Motor Lhokseumawe'), findsNothing);
    });

    testWidgets('WorkshopsScreen menampilkan kondisi gagal sesuai Figma 05.01 saat error', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          overrides: <Override>[
            workshopsListProvider.overrideWith((ref) => Future<List<Workshop>>.error(
                  Exception('Koneksi terputus ke server Google Maps.'),
                )),
          ],
          child: const WorkshopsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi komponen error state Figma 05.01
      expect(find.byKey(const Key('failed_workshops_state')), findsOneWidget);
      expect(find.text('Bengkel belum dapat dimuat'), findsOneWidget);
      expect(
        find.text(
          'Terjadi kendala saat memuat data bengkel di sekitar lokasi Anda. Periksa koneksi internet atau gunakan pencarian langsung di Google Maps.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('retry_workshops_button')), findsOneWidget);
      expect(find.byKey(const Key('open_external_maps_search_button')), findsOneWidget);
    });

    testWidgets('WorkshopDetailScreen menampilkan Kartu Sumber Data & Rating (Figma 05.02)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildTestApp(
          child: const WorkshopDetailScreen(workshopId: 'ws-01'),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi kartu sumber data wajib
      expect(find.byKey(const Key('workshop_data_source_card')), findsOneWidget);
      expect(
        find.text('Sumber Data: Direktori Resmi MotoCare Lhokseumawe'),
        findsOneWidget,
      );

      // Verifikasi baris rating pengguna
      expect(find.text('Rating Pengguna'), findsOneWidget);
      expect(find.text('Belum tersedia'), findsWidgets);
    });
  });
}

