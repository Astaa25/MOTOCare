import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/workshops/data/mock_workshop_repository.dart';
import 'package:motocare/features/workshops/domain/workshop.dart';
import 'package:motocare/features/workshops/domain/workshop_rules.dart';

void main() {
  group('WorkshopRules Unit Tests (M6)', () {
    test('Kalimat cakupan permanen sesuai teks resmi PRD 2.2', () {
      expect(
        WorkshopRules.permanentCoverageNotice,
        contains('Kota Lhokseumawe'),
      );
      expect(
        WorkshopRules.permanentCoverageNotice,
        contains('Kabupaten Aceh Utara'),
      );
    });

    test('isOutOfCoverageQuery mendeteksi wilayah di luar cakupan (PRD 619)', () {
      expect(WorkshopRules.isOutOfCoverageQuery('Banda Aceh'), isTrue);
      expect(WorkshopRules.isOutOfCoverageQuery('bengkel di Medan'), isTrue);
      expect(WorkshopRules.isOutOfCoverageQuery('Jakarta'), isTrue);
      expect(WorkshopRules.isOutOfCoverageQuery('Surabaya'), isTrue);
      expect(WorkshopRules.isOutOfCoverageQuery('Bireuen'), isTrue);
      expect(WorkshopRules.isOutOfCoverageQuery('Takengon'), isTrue);

      // Wilayah dalam cakupan resmi
      expect(WorkshopRules.isOutOfCoverageQuery('Lhokseumawe'), isFalse);
      expect(WorkshopRules.isOutOfCoverageQuery('Aceh Utara'), isFalse);
      expect(WorkshopRules.isOutOfCoverageQuery('Cunda'), isFalse);
      expect(WorkshopRules.isOutOfCoverageQuery('Lhoksukon'), isFalse);
      expect(WorkshopRules.isOutOfCoverageQuery('Samudera'), isFalse);

      // Jika menyebutkan kata luar wilayah tapi juga menyebut wilayah cakupan
      expect(
        WorkshopRules.isOutOfCoverageQuery('bengkel medan di lhokseumawe'),
        isFalse,
      );
    });

    test('Kalkulasi jarak Haversine akurat dan memformat dengan benar', () {
      // Jarak antara 2 titik dekat (< 1 km): 5.1800, 97.1400 ke 5.1830, 97.1430
      final distKm = WorkshopRules.calculateHaversineDistanceKm(
        lat1: 5.1800,
        lon1: 97.1400,
        lat2: 5.1830,
        lon2: 97.1430,
      );
      expect(distKm, lessThan(1.0));

      final formattedNear = WorkshopRules.formatDistance(
        workshopLat: 5.1830,
        workshopLon: 97.1430,
        userLat: 5.1800,
        userLon: 97.1400,
      );
      expect(formattedNear, endsWith('m'));

      // Jarak antara Lhokseumawe (5.1801, 97.1405) dan Lhoksukon (5.0450, 97.3180) (~25 km)
      final formattedFar = WorkshopRules.formatDistance(
        workshopLat: 5.0450,
        workshopLon: 97.3180,
        userLat: 5.1801,
        userLon: 97.1405,
      );
      expect(formattedFar, contains('km'));
    });

    test('Pencegahan Jarak Palsu: Koordinat null menghasilkan jarak null', () {
      expect(
        WorkshopRules.formatDistance(
          workshopLat: null,
          workshopLon: 97.1400,
          userLat: 5.1800,
          userLon: 97.1400,
        ),
        isNull,
      );

      expect(
        WorkshopRules.formatDistance(
          workshopLat: 5.1800,
          workshopLon: 97.1400,
          userLat: null,
          userLon: null,
        ),
        isNull,
      );
    });
  });

  group('MockWorkshopRepository Unit Tests (M6)', () {
    late MockWorkshopRepository repository;

    setUp(() {
      repository = MockWorkshopRepository();
    });

    test('Memuat minimal 6 bengkel terverifikasi demo sesuai PRD 5.5', () async {
      final workshops = await repository.getWorkshops();
      expect(workshops.length, greaterThanOrEqualTo(6));

      final lhokseumaweList = workshops
          .where((w) => w.cityOrRegency == WorkshopCoverageAreas.lhokseumawe)
          .toList();
      final acehUtaraList = workshops
          .where((w) => w.cityOrRegency == WorkshopCoverageAreas.acehUtara)
          .toList();

      expect(lhokseumaweList.length, greaterThanOrEqualTo(3));
      expect(acehUtaraList.length, greaterThanOrEqualTo(3));

      for (final ws in workshops) {
        expect(ws.isDemo, isFalse);
        expect(ws.name, isNot(startsWith('[Demo]')));
        expect(ws.isVerified, isTrue);
      }
    });

    test('Filter kota/kabupaten mengembalikan bengkel di wilayah tersebut', () async {
      final lhokseumaweOnly = await repository.getWorkshops(
        cityOrRegency: WorkshopCoverageAreas.lhokseumawe,
      );
      for (final ws in lhokseumaweOnly) {
        expect(ws.cityOrRegency, equals(WorkshopCoverageAreas.lhokseumawe));
      }

      final acehUtaraOnly = await repository.getWorkshops(
        cityOrRegency: WorkshopCoverageAreas.acehUtara,
      );
      for (final ws in acehUtaraOnly) {
        expect(ws.cityOrRegency, equals(WorkshopCoverageAreas.acehUtara));
      }
    });

    test('Filter query pencarian cocok pada nama atau alamat', () async {
      final results = await repository.getWorkshops(query: 'Lhoksukon');
      expect(results, isNotEmpty);
      expect(results.first.address, contains('Lhoksukon'));

      final nonExistent = await repository.getWorkshops(
        query: 'bengkelkhayalantidakada',
      );
      expect(nonExistent, isEmpty);
    });

    test('getWorkshopById mengembalikan bengkel yang sesuai atau null', () async {
      final ws = await repository.getWorkshopById('ws-01');
      expect(ws, isNotNull);
      expect(ws!.id, equals('ws-01'));

      final missing = await repository.getWorkshopById('ws-tidak-ada');
      expect(missing, isNull);
    });
  });
}
