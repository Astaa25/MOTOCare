import 'dart:async';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../motorcycles/domain/motorcycle_repository.dart';
import '../domain/service_history.dart';
import '../domain/service_history_repository.dart';

/// Implementasi MockServiceHistoryRepository untuk testing dan mode offline demo
class MockServiceHistoryRepository implements ServiceHistoryRepository {
  final List<ServiceHistory> _records = <ServiceHistory>[];
  final StreamController<List<ServiceHistory>> _streamController =
      StreamController<List<ServiceHistory>>.broadcast();
  final MotorcycleRepository? motorcycleRepository;
  final bool simulateDelay;

  MockServiceHistoryRepository({
    this.motorcycleRepository,
    bool populateDemoData = true,
    this.simulateDelay = false,
  }) {
    if (populateDemoData) {
      _records.addAll(<ServiceHistory>[
        ServiceHistory(
          id: 'demo-service-2',
          motorcycleId: 'demo-motor-1',
          userId: 'demo-user-id',
          serviceDate: DateTime(2026, 9, 20),
          mileage: 12000,
          serviceType: 'Servis berkala',
          description: 'Servis CVT, pembersihan injektor, dan pemeriksaan kelistrikan (Demo/Simulasi)',
          cost: 150000,
          workshopName: 'Bengkel Resmi Honda Lhokseumawe (Demo)',
          createdAt: DateTime(2026, 9, 20, 14, 30),
        ),
        ServiceHistory(
          id: 'demo-service-1',
          motorcycleId: 'demo-motor-1',
          userId: 'demo-user-id',
          serviceDate: DateTime(2026, 8, 15),
          mileage: 10000,
          serviceType: 'Ganti oli',
          description: 'Ganti oli mesin MPX2 dan pembersihan saringan udara (Demo/Simulasi)',
          cost: 85000,
          workshopName: 'AHASS Surya Motor Lhokseumawe (Demo)',
          createdAt: DateTime(2026, 8, 15, 10, 0),
        ),
      ]);
    }
  }

  void _notify() {
    if (!_streamController.isClosed) {
      _streamController.add(List<ServiceHistory>.unmodifiable(_records));
    }
  }

  @override
  Future<Result<List<ServiceHistory>>> getServiceHistories({
    required String motorcycleId,
    String? serviceType,
    int limit = 20,
    int offset = 0,
  }) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    var list = _records.where((s) => s.motorcycleId == motorcycleId).toList();

    if (serviceType != null && serviceType.trim().isNotEmpty && serviceType != 'Semua') {
      list = list.where((s) => s.serviceType.toLowerCase() == serviceType.toLowerCase()).toList();
    }

    // Urutkan terbaru dahulu sesuai PRD 7 M4
    list.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

    final paged = list.skip(offset).take(limit).toList();
    return Result.success(paged);
  }

  @override
  Future<Result<ServiceHistory>> getServiceHistoryById(String id) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }

    try {
      final record = _records.firstWhere((s) => s.id == id);
      return Result.success(record);
    } catch (_) {
      return const Result.failure(NotFoundException('Catatan servis tidak ditemukan'));
    }
  }

  @override
  Future<Result<ServiceHistory>> addServiceHistory({
    required String motorcycleId,
    required String userId,
    required DateTime serviceDate,
    required int mileage,
    required String serviceType,
    String? description,
    required int cost,
    String? workshopId,
    String? workshopName,
  }) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    // Validasi aturan PRD: Tanggal tidak di masa depan
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(serviceDate.year, serviceDate.month, serviceDate.day);
    if (targetDate.isAfter(today)) {
      return const Result.failure(ValidationException('Tanggal servis tidak boleh di masa depan'));
    }

    // Validasi aturan PRD: Biaya minimal 0
    if (cost < 0) {
      return const Result.failure(ValidationException('Biaya servis tidak boleh negatif'));
    }

    // Validasi aturan PRD: Kilometer 0 - 999.999
    if (mileage < 0 || mileage > 999999) {
      return const Result.failure(ValidationException('Kilometer harus antara 0 dan 999.999 km'));
    }

    final newRecord = ServiceHistory(
      id: 'service-${DateTime.now().millisecondsSinceEpoch}',
      motorcycleId: motorcycleId,
      userId: userId,
      serviceDate: serviceDate,
      mileage: mileage,
      serviceType: serviceType.trim(),
      description: description?.trim(),
      cost: cost,
      workshopId: workshopId,
      workshopName: workshopName?.trim(),
      createdAt: DateTime.now(),
    );

    _records.insert(0, newRecord);
    _notify();

    // Aturan bisnis PRD 7 M4: Setelah simpan, perbarui kilometer motor bila lebih besar
    if (motorcycleRepository != null) {
      final motorRes = await motorcycleRepository!.getMotorcycleById(motorcycleId);
      if (motorRes.isSuccess) {
        final currentMotor = motorRes.dataOrNull!;
        if (mileage > currentMotor.currentMileage) {
          await motorcycleRepository!.updateMileage(
            motorcycleId: motorcycleId,
            newMileage: mileage,
          );
        }
      }
    }

    return Result.success(newRecord);
  }

  @override
  Future<Result<ServiceHistory>> updateServiceHistory(ServiceHistory serviceHistory) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(serviceHistory.serviceDate.year, serviceHistory.serviceDate.month, serviceHistory.serviceDate.day);
    if (targetDate.isAfter(today)) {
      return const Result.failure(ValidationException('Tanggal servis tidak boleh di masa depan'));
    }

    if (serviceHistory.cost < 0) {
      return const Result.failure(ValidationException('Biaya servis tidak boleh negatif'));
    }

    if (serviceHistory.mileage < 0 || serviceHistory.mileage > 999999) {
      return const Result.failure(ValidationException('Kilometer harus antara 0 dan 999.999 km'));
    }

    final index = _records.indexWhere((s) => s.id == serviceHistory.id);
    if (index == -1) {
      return const Result.failure(NotFoundException('Catatan servis tidak ditemukan'));
    }

    _records[index] = serviceHistory;
    _notify();

    // Perbarui kilometer motor jika lebih besar
    if (motorcycleRepository != null) {
      final motorRes = await motorcycleRepository!.getMotorcycleById(serviceHistory.motorcycleId);
      if (motorRes.isSuccess) {
        final currentMotor = motorRes.dataOrNull!;
        if (serviceHistory.mileage > currentMotor.currentMileage) {
          await motorcycleRepository!.updateMileage(
            motorcycleId: serviceHistory.motorcycleId,
            newMileage: serviceHistory.mileage,
          );
        }
      }
    }

    return Result.success(serviceHistory);
  }

  @override
  Future<Result<void>> deleteServiceHistory(String id) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    final index = _records.indexWhere((s) => s.id == id);
    if (index == -1) {
      return const Result.failure(NotFoundException('Catatan servis tidak ditemukan'));
    }

    _records.removeAt(index);
    _notify();
    return const Result.success(null);
  }

  @override
  Future<Result<int>> getTotalCost({
    required String motorcycleId,
    String? serviceType,
  }) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }

    var list = _records.where((s) => s.motorcycleId == motorcycleId).toList();
    if (serviceType != null && serviceType.trim().isNotEmpty && serviceType != 'Semua') {
      list = list.where((s) => s.serviceType.toLowerCase() == serviceType.toLowerCase()).toList();
    }

    final total = list.fold<int>(0, (sum, item) => sum + item.cost);
    return Result.success(total);
  }

  @override
  Stream<List<ServiceHistory>> watchServiceHistories({required String motorcycleId}) async* {
    yield _records.where((s) => s.motorcycleId == motorcycleId).toList();
    yield* _streamController.stream.map(
      (list) => list.where((s) => s.motorcycleId == motorcycleId).toList(),
    );
  }

  void clear() {
    _records.clear();
    _notify();
  }

  void dispose() {
    _streamController.close();
  }
}
