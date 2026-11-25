import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/config/env.dart';
import 'package:motocare/core/services/maps_cost_controller.dart';
import 'package:motocare/core/utils/maps_feature_guard.dart';

void main() {
  group('MapsMemoryCache', () {
    test('menyimpan dan mengambil data yang belum expired', () {
      final cache = MapsMemoryCache(defaultTtl: const Duration(minutes: 5));
      cache.set('key1', {'name': 'Bengkel Honda'});

      final data = cache.get<Map<String, dynamic>>('key1');
      expect(data, isNotNull);
      expect(data?['name'], 'Bengkel Honda');
      expect(cache.activeCount, 1);
    });

    test('mengembalikan null jika data sudah kedaluwarsa', () async {
      final cache = MapsMemoryCache(defaultTtl: const Duration(milliseconds: 10));
      cache.set('key_short', 'nilai_sementara');

      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(cache.get<String>('key_short'), isNull);
      expect(cache.activeCount, 0);
    });

    test('dapat membersihkan seluruh cache', () {
      final cache = MapsMemoryCache();
      cache.set('k1', 1);
      cache.set('k2', 2);
      expect(cache.activeCount, 2);

      cache.clear();
      expect(cache.activeCount, 0);
      expect(cache.get('k1'), isNull);
    });
  });

  group('MapsSessionTokenManager', () {
    test('menghasilkan UUID v4 yang konsisten dalam 1 sesi', () {
      final manager = MapsSessionTokenManager();
      final token1 = manager.getOrCreateToken();
      final token2 = manager.getOrCreateToken();

      expect(token1.length, 36);
      expect(token1, equals(token2));
    });

    test('mereset token baru setelah consumeToken dipanggil', () {
      final manager = MapsSessionTokenManager();
      final token1 = manager.getOrCreateToken();
      manager.consumeToken();

      final token2 = manager.getOrCreateToken();
      expect(token2.length, 36);
      expect(token1, isNot(equals(token2)));
    });
  });

  group('MapsDebouncer', () {
    test('menunda eksekusi dan membatalkan panggilan ganda', () async {
      final debouncer = MapsDebouncer(delay: const Duration(milliseconds: 50));
      int callCount = 0;

      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);
      debouncer.run(() => callCount++);

      expect(debouncer.isWaiting, isTrue);
      expect(callCount, 0);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(callCount, 1);
      expect(debouncer.isWaiting, isFalse);
    });
  });

  group('MapsCostController & FeatureGuard', () {
    test('memiliki batas hasil aman sesuai PRD & handoff', () {
      expect(MapsCostController.maxAutocompleteResults, 5);
      expect(MapsCostController.maxWorkshopResults, 20);
      expect(MapsCostController.minQueryLength, 2);
    });

    test('AppEnv.mapsEnabled bernilai boolean default true', () {
      expect(AppEnv.mapsEnabled, isTrue);
    });

    test('MapsFeatureGuard mengecek ketersediaan SDK maps', () {
      expect(MapsFeatureGuard.isMapsSdkEnabled, isA<bool>());
    });
  });
}

