import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/motorcycles/data/mock_motorcycle_repository.dart';
import 'package:motocare/features/service_history/data/mock_service_history_repository.dart';
import 'package:motocare/features/service_history/domain/service_history.dart';

void main() {
  group('TC-05 & TC-22: Unit Tests ServiceHistoryRepository (Mock)', () {
    late MockMotorcycleRepository mockMotorRepo;
    late MockServiceHistoryRepository mockServiceRepo;

    setUp(() {
      mockMotorRepo = MockMotorcycleRepository(populateDemoData: false);
      mockServiceRepo = MockServiceHistoryRepository(
        motorcycleRepository: mockMotorRepo,
        populateDemoData: false,
      );
    });

    test('Daftar awal kosong jika populateDemoData false', () async {
      final res = await mockServiceRepo.getServiceHistories(motorcycleId: 'motor-1');
      expect(res.isSuccess, isTrue);
      expect(res.dataOrNull, isEmpty);
    });

    test('Data demo terisi jika populateDemoData true', () {
      final repoWithDemo = MockServiceHistoryRepository(populateDemoData: true);
      expect(repoWithDemo.getTotalCost(motorcycleId: 'demo-motor-1'), completes);
    });

    test('TC-05: Menambahkan servis dengan kilometer lebih besar memperbarui kilometer motor', () async {
      // Buat motor dengan KM 10.000
      final motorRes = await mockMotorRepo.addMotorcycle(
        userId: 'user-1',
        brand: 'Honda',
        model: 'Vario 160',
        productionYear: 2023,
        currentMileage: 10000,
      );
      final motorId = motorRes.dataOrNull!.id;

      // Tambahkan riwayat servis di 12.500 km
      final serviceRes = await mockServiceRepo.addServiceHistory(
        motorcycleId: motorId,
        userId: 'user-1',
        serviceDate: DateTime.now().subtract(const Duration(days: 2)),
        mileage: 12500,
        serviceType: 'Ganti oli',
        cost: 85000,
        workshopName: 'AHASS Lhokseumawe',
        description: 'Ganti oli mesin dan gardan',
      );

      expect(serviceRes.isSuccess, isTrue);
      final service = serviceRes.dataOrNull!;
      expect(service.mileage, 12500);
      expect(service.cost, 85000);
      expect(service.serviceType, 'Ganti oli');

      // Verifikasi kilometer motor otomatis naik ke 12.500 km
      final updatedMotor = (await mockMotorRepo.getMotorcycleById(motorId)).dataOrNull!;
      expect(updatedMotor.currentMileage, 12500);
    });

    test('Menambahkan servis dengan kilometer lebih kecil tidak menurunkan kilometer motor', () async {
      // Motor dengan KM 15.000
      final motorRes = await mockMotorRepo.addMotorcycle(
        userId: 'user-1',
        brand: 'Yamaha',
        model: 'NMAX',
        productionYear: 2022,
        currentMileage: 15000,
      );
      final motorId = motorRes.dataOrNull!.id;

      // Catat servis masa lalu di 12.000 km
      await mockServiceRepo.addServiceHistory(
        motorcycleId: motorId,
        userId: 'user-1',
        serviceDate: DateTime.now().subtract(const Duration(days: 30)),
        mileage: 12000,
        serviceType: 'Rem',
        cost: 60000,
      );

      final currentMotor = (await mockMotorRepo.getMotorcycleById(motorId)).dataOrNull!;
      expect(currentMotor.currentMileage, 15000);
    });

    test('TC-22: Menambahkan servis dengan tanggal di masa depan ditolak', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final res = await mockServiceRepo.addServiceHistory(
        motorcycleId: 'motor-1',
        userId: 'user-1',
        serviceDate: tomorrow,
        mileage: 10000,
        serviceType: 'Ganti oli',
        cost: 50000,
      );

      expect(res.isFailure, isTrue);
      expect(res.exceptionOrNull?.message, contains('tidak boleh di masa depan'));
    });

    test('TC-22: Menambahkan servis dengan biaya negatif ditolak', () async {
      final res = await mockServiceRepo.addServiceHistory(
        motorcycleId: 'motor-1',
        userId: 'user-1',
        serviceDate: DateTime.now(),
        mileage: 10000,
        serviceType: 'Ganti oli',
        cost: -5000,
      );

      expect(res.isFailure, isTrue);
      expect(res.exceptionOrNull?.message, contains('tidak boleh negatif'));
    });

    test('Menambahkan servis dengan kilometer di luar batas ditolak', () async {
      final res = await mockServiceRepo.addServiceHistory(
        motorcycleId: 'motor-1',
        userId: 'user-1',
        serviceDate: DateTime.now(),
        mileage: -10,
        serviceType: 'Ganti oli',
        cost: 50000,
      );

      expect(res.isFailure, isTrue);
    });

    test('Perhitungan total biaya (getTotalCost) akurat dengan dan tanpa filter', () async {
      final today = DateTime.now();

      await mockServiceRepo.addServiceHistory(
        motorcycleId: 'motor-cost-test',
        userId: 'user-1',
        serviceDate: today.subtract(const Duration(days: 10)),
        mileage: 5000,
        serviceType: 'Ganti oli',
        cost: 80000,
      );

      await mockServiceRepo.addServiceHistory(
        motorcycleId: 'motor-cost-test',
        userId: 'user-1',
        serviceDate: today.subtract(const Duration(days: 5)),
        mileage: 6000,
        serviceType: 'Ganti oli',
        cost: 85000,
      );

      await mockServiceRepo.addServiceHistory(
        motorcycleId: 'motor-cost-test',
        userId: 'user-1',
        serviceDate: today.subtract(const Duration(days: 2)),
        mileage: 7000,
        serviceType: 'Rem',
        cost: 120000,
      );

      // Total keseluruhan (80.000 + 85.000 + 120.000 = 285.000)
      final totalAll = await mockServiceRepo.getTotalCost(motorcycleId: 'motor-cost-test');
      expect(totalAll.dataOrNull, 285000);

      // Total filter 'Ganti oli' (80.000 + 85.000 = 165.000)
      final totalOli = await mockServiceRepo.getTotalCost(
        motorcycleId: 'motor-cost-test',
        serviceType: 'Ganti oli',
      );
      expect(totalOli.dataOrNull, 165000);

      // Total filter 'Rem' (120.000)
      final totalRem = await mockServiceRepo.getTotalCost(
        motorcycleId: 'motor-cost-test',
        serviceType: 'Rem',
      );
      expect(totalRem.dataOrNull, 120000);
    });

    test('Ubah catatan servis berhasil memperbarui data', () async {
      final addRes = await mockServiceRepo.addServiceHistory(
        motorcycleId: 'motor-1',
        userId: 'user-1',
        serviceDate: DateTime.now().subtract(const Duration(days: 3)),
        mileage: 8000,
        serviceType: 'Busi',
        cost: 35000,
        workshopName: 'Bengkel A',
      );
      final original = addRes.dataOrNull!;

      final updated = original.copyWith(
        cost: 40000,
        description: 'Busi iridium baru',
        workshopName: 'Bengkel B',
      );

      final updateRes = await mockServiceRepo.updateServiceHistory(updated);
      expect(updateRes.isSuccess, isTrue);

      final fetched = (await mockServiceRepo.getServiceHistoryById(original.id)).dataOrNull!;
      expect(fetched.cost, 40000);
      expect(fetched.description, 'Busi iridium baru');
      expect(fetched.workshopName, 'Bengkel B');
    });

    test('Hapus catatan servis berhasil menghapus dari repository', () async {
      final addRes = await mockServiceRepo.addServiceHistory(
        motorcycleId: 'motor-1',
        userId: 'user-1',
        serviceDate: DateTime.now(),
        mileage: 5000,
        serviceType: 'Ban',
        cost: 250000,
      );
      final serviceId = addRes.dataOrNull!.id;

      final delRes = await mockServiceRepo.deleteServiceHistory(serviceId);
      expect(delRes.isSuccess, isTrue);

      final fetchRes = await mockServiceRepo.getServiceHistoryById(serviceId);
      expect(fetchRes.isFailure, isTrue);
    });

    test('Serialisasi toJson dan deserialisasi fromJson ServiceHistory konsisten', () {
      final now = DateTime.now();
      final item = ServiceHistory(
        id: 'test-uuid-1',
        motorcycleId: 'motor-uuid-1',
        userId: 'user-uuid-1',
        serviceDate: DateTime(2026, 10, 14),
        mileage: 12000,
        serviceType: 'Servis berkala',
        description: 'Cek CVT & Oli',
        cost: 150000,
        workshopId: 'ws-1',
        workshopName: 'Bengkel Sentosa',
        createdAt: now,
      );

      final json = item.toJson();
      expect(json['id'], 'test-uuid-1');
      expect(json['motorcycle_id'], 'motor-uuid-1');
      expect(json['cost'], 150000);
      expect(json['service_type'], 'Servis berkala');

      final reconstructed = ServiceHistory.fromJson(json);
      expect(reconstructed.id, item.id);
      expect(reconstructed.motorcycleId, item.motorcycleId);
      expect(reconstructed.cost, item.cost);
      expect(reconstructed.serviceType, item.serviceType);
      expect(reconstructed.workshopName, item.workshopName);
    });
  });
}
