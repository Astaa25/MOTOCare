import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/services/maps_cost_controller.dart';
import 'package:motocare/core/services/maps_places_service.dart';

void main() {
  group('MapsPlacesService Unit Tests (Tahap 3)', () {
    late MapsCostController costController;
    late MapsPlacesService service;

    setUp(() {
      costController = MapsCostController();
      service = MapsPlacesService(costController: costController);
    });

    tearDown(() {
      costController.dispose();
    });

    test('Query kurang dari 2 karakter mengembalikan daftar kosong tanpa memanggil API', () async {
      final results = await service.searchPlaces('a');
      expect(results, isEmpty);
      expect(costController.cache.activeCount, 0);
    });

    test('Mencari tempat di Lhokseumawe mengembalikan saran tempat representatif', () async {
      final results = await service.searchPlaces('Islamic Center');
      expect(results, isNotEmpty);
      expect(results.first.mainText, contains('Islamic Center'));
      expect(results.first.cityRegency, equals('Kota Lhokseumawe'));
    });

    test('Mencari tempat di Aceh Utara mengembalikan saran tempat yang sesuai', () async {
      final results = await service.searchPlaces('Lhoksukon');
      expect(results, isNotEmpty);
      expect(results.any((s) => s.cityRegency == 'Kabupaten Aceh Utara'), isTrue);
    });

    test('Pencarian berulang dengan query sama mengambil dari cache memori', () async {
      final first = await service.searchPlaces('Cunda');
      expect(costController.cache.activeCount, greaterThan(0));

      final second = await service.searchPlaces('cunda'); // case insensitive
      expect(second.length, equals(first.length));
    });

    test('getPlaceDetails mengembalikan rincian lengkap dan mereset session token', () async {
      final detail = await service.getPlaceDetails('demo-place-1');
      expect(detail, isNotNull);
      expect(detail!.name, contains('Islamic Center'));
      expect(detail.latitude, closeTo(5.18, 0.01));
      expect(detail.longitude, closeTo(97.14, 0.01));
      expect(detail.cityRegency, 'Kota Lhokseumawe');
    });

    test('getPlaceDetails untuk id tidak dikenal mengembalikan null secara aman', () async {
      final detail = await service.getPlaceDetails('id-ngawur-999');
      expect(detail, isNull);
    });
  });
}

