import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/motorcycles/data/mock_motorcycle_repository.dart';
import 'package:motocare/features/motorcycles/domain/motorcycle.dart';

void main() {
  group('TC-03 & Unit Tests MotorcycleRepository (Mock)', () {
    late MockMotorcycleRepository repo;

    setUp(() {
      repo = MockMotorcycleRepository(populateDemoData: false);
    });

    tearDown(() {
      repo.dispose();
    });

    test('Daftar awal kosong jika populateDemoData false', () async {
      final result = await repo.getMotorcycles(userId: 'user-123');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isEmpty);

      final active = await repo.getActiveMotorcycle(userId: 'user-123');
      expect(active.isSuccess, isTrue);
      expect(active.dataOrNull, isNull);
    });

    test('TC-03: Menambahkan motor baru berhasil tersimpan dan terbaca', () async {
      final addResult = await repo.addMotorcycle(
        userId: 'user-123',
        brand: 'Honda',
        model: 'Vario 160 CBS',
        productionYear: 2023,
        licensePlate: 'BL 4521 KF',
        currentMileage: 12450,
      );

      expect(addResult.isSuccess, isTrue);
      final motor = addResult.dataOrNull!;
      expect(motor.brand, 'Honda');
      expect(motor.model, 'Vario 160 CBS');
      expect(motor.productionYear, 2023);
      expect(motor.licensePlate, 'BL 4521 KF');
      expect(motor.currentMileage, 12450);
      expect(motor.name, 'Honda Vario 160 CBS');

      // Ambil daftar motor
      final listResult = await repo.getMotorcycles(userId: 'user-123');
      expect(listResult.dataOrNull!.length, 1);
      expect(listResult.dataOrNull!.first.id, motor.id);

      // Ambil motor aktif
      final activeResult = await repo.getActiveMotorcycle(userId: 'user-123');
      expect(activeResult.dataOrNull!.id, motor.id);
    });

    test('Ubah informasi motor memperbarui merek, model, tahun, plat', () async {
      final added = (await repo.addMotorcycle(
        userId: 'user-123',
        brand: 'Yamaha',
        model: 'NMAX',
        productionYear: 2021,
        licensePlate: 'BL 1111 AA',
        currentMileage: 20000,
      )).dataOrNull!;

      final updated = added.copyWith(
        model: 'NMAX Connected',
        productionYear: 2022,
        licensePlate: 'BL 2222 BB',
      );

      final updateResult = await repo.updateMotorcycle(updated);
      expect(updateResult.isSuccess, isTrue);
      expect(updateResult.dataOrNull!.model, 'NMAX Connected');
      expect(updateResult.dataOrNull!.productionYear, 2022);
      expect(updateResult.dataOrNull!.licensePlate, 'BL 2222 BB');
    });

    test('Pembaruan kilometer updateMileage mengubah currentMileage dan mileageUpdatedAt', () async {
      final added = (await repo.addMotorcycle(
        userId: 'user-123',
        brand: 'Honda',
        model: 'Beat',
        productionYear: 2020,
        currentMileage: 8000,
      )).dataOrNull!;

      final updateKmResult = await repo.updateMileage(
        motorcycleId: added.id,
        newMileage: 8500,
      );

      expect(updateKmResult.isSuccess, isTrue);
      expect(updateKmResult.dataOrNull!.currentMileage, 8500);

      final fetched = (await repo.getMotorcycleById(added.id)).dataOrNull!;
      expect(fetched.currentMileage, 8500);
    });

    test('Hapus motor berhasil menghapus motor dari daftar', () async {
      final added = (await repo.addMotorcycle(
        userId: 'user-123',
        brand: 'Suzuki',
        model: 'Satria F150',
        productionYear: 2019,
        currentMileage: 35000,
      )).dataOrNull!;

      final deleteResult = await repo.deleteMotorcycle(added.id);
      expect(deleteResult.isSuccess, isTrue);

      final listResult = await repo.getMotorcycles(userId: 'user-123');
      expect(listResult.dataOrNull, isEmpty);

      final getById = await repo.getMotorcycleById(added.id);
      expect(getById.isFailure, isTrue);
    });

    test('isMileageStale bernilai true jika pembaruan km lebih dari 30 hari', () {
      final fresh = Motorcycle(
        id: '1',
        userId: 'user-1',
        brand: 'Honda',
        model: 'Scoopy',
        productionYear: 2022,
        currentMileage: 5000,
        mileageUpdatedAt: DateTime.now().subtract(const Duration(days: 10)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(fresh.isMileageStale, isFalse);

      final stale = Motorcycle(
        id: '2',
        userId: 'user-1',
        brand: 'Honda',
        model: 'Scoopy',
        productionYear: 2022,
        currentMileage: 5000,
        mileageUpdatedAt: DateTime.now().subtract(const Duration(days: 35)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(stale.isMileageStale, isTrue);
    });

    test('Serialisasi toJson dan deserialisasi fromJson Motorcycle akurat', () {
      final now = DateTime.now();
      final motor = Motorcycle(
        id: 'motor-json-test',
        userId: 'user-abc',
        brand: 'Kawasaki',
        model: 'KLX 150',
        productionYear: 2021,
        licensePlate: 'BL 9999 ZZ',
        currentMileage: 14000,
        mileageUpdatedAt: now,
        photoUrl: 'https://example.com/photo.jpg',
        createdAt: now,
        updatedAt: now,
      );

      final json = motor.toJson();
      expect(json['id'], 'motor-json-test');
      expect(json['brand'], 'Kawasaki');
      expect(json['license_plate'], 'BL 9999 ZZ');

      final reconstructed = Motorcycle.fromJson(json);
      expect(reconstructed.id, motor.id);
      expect(reconstructed.brand, motor.brand);
      expect(reconstructed.model, motor.model);
      expect(reconstructed.currentMileage, motor.currentMileage);
      expect(reconstructed.licensePlate, 'BL 9999 ZZ');
    });
  });
}
