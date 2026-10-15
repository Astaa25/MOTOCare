import 'dart:async';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../domain/motorcycle.dart';
import '../domain/motorcycle_repository.dart';

/// Implementasi Mock MotorcycleRepository untuk testing dan mode offline demo
class MockMotorcycleRepository implements MotorcycleRepository {
  final List<Motorcycle> _motorcycles = <Motorcycle>[];
  final StreamController<List<Motorcycle>> _streamController =
      StreamController<List<Motorcycle>>.broadcast();
  final bool simulateDelay;

  MockMotorcycleRepository({
    bool populateDemoData = true,
    this.simulateDelay = false,
  }) {
    if (populateDemoData) {
      _motorcycles.addAll(<Motorcycle>[
        Motorcycle(
          id: 'demo-motor-1',
          userId: 'demo-user-id',
          brand: 'Honda',
          model: 'Vario 160 CBS',
          productionYear: 2023,
          licensePlate: 'BL 4521 KF',
          currentMileage: 12450,
          mileageUpdatedAt: DateTime.now().subtract(const Duration(days: 5)),
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Motorcycle(
          id: 'demo-motor-2',
          userId: 'demo-user-id',
          brand: 'Yamaha',
          model: 'NMAX 155 Connected',
          productionYear: 2022,
          licensePlate: 'BL 6812 KP',
          currentMileage: 24100,
          mileageUpdatedAt: DateTime.now().subtract(const Duration(days: 3)),
          createdAt: DateTime.now().subtract(const Duration(days: 120)),
          updatedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Motorcycle(
          id: 'demo-motor-3',
          userId: 'demo-user-id',
          brand: 'Honda',
          model: 'BeAT Deluxe eSP',
          productionYear: 2021,
          licensePlate: 'BL 3190 QA',
          currentMileage: 31800,
          mileageUpdatedAt: DateTime.now().subtract(const Duration(days: 35)),
          createdAt: DateTime.now().subtract(const Duration(days: 200)),
          updatedAt: DateTime.now().subtract(const Duration(days: 35)),
        ),
        Motorcycle(
          id: 'demo-motor-4',
          userId: 'demo-user-id',
          brand: 'Yamaha',
          model: 'Aerox 155 CyberCity',
          productionYear: 2023,
          licensePlate: 'BL 5542 AB',
          currentMileage: 8200,
          mileageUpdatedAt: DateTime.now().subtract(const Duration(days: 8)),
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          updatedAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
        Motorcycle(
          id: 'demo-motor-5',
          userId: 'demo-user-id',
          brand: 'Honda',
          model: 'Scoopy Prestige',
          productionYear: 2022,
          licensePlate: 'BL 2981 LM',
          currentMileage: 16500,
          mileageUpdatedAt: DateTime.now().subtract(const Duration(days: 12)),
          createdAt: DateTime.now().subtract(const Duration(days: 150)),
          updatedAt: DateTime.now().subtract(const Duration(days: 12)),
        ),
      ]);
    }
  }

  void _notify() {
    if (!_streamController.isClosed) {
      _streamController.add(List<Motorcycle>.unmodifiable(_motorcycles));
    }
  }

  @override
  Future<Result<List<Motorcycle>>> getMotorcycles({required String userId}) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final userMotors = _motorcycles.where((m) => m.userId == userId || userId == 'demo-user-id').toList();
    return Result.success(userMotors);
  }

  @override
  Future<Result<Motorcycle?>> getActiveMotorcycle({required String userId}) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    final userMotors = _motorcycles.where((m) => m.userId == userId || userId == 'demo-user-id').toList();
    if (userMotors.isEmpty) {
      return const Result.success(null);
    }
    return Result.success(userMotors.first);
  }

  @override
  Future<Result<Motorcycle>> getMotorcycleById(String id) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    try {
      final motor = _motorcycles.firstWhere((m) => m.id == id);
      return Result.success(motor);
    } catch (_) {
      return const Result.failure(NotFoundException('Sepeda motor tidak ditemukan'));
    }
  }

  @override
  Future<Result<Motorcycle>> addMotorcycle({
    required String userId,
    required String brand,
    required String model,
    required int productionYear,
    String? licensePlate,
    required int currentMileage,
  }) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    final now = DateTime.now();
    final newMotor = Motorcycle(
      id: 'motor-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      brand: brand.trim(),
      model: model.trim(),
      productionYear: productionYear,
      licensePlate: licensePlate?.trim().toUpperCase(),
      currentMileage: currentMileage,
      mileageUpdatedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    _motorcycles.insert(0, newMotor);
    _notify();
    return Result.success(newMotor);
  }

  @override
  Future<Result<Motorcycle>> updateMotorcycle(Motorcycle motorcycle) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    final index = _motorcycles.indexWhere((m) => m.id == motorcycle.id);
    if (index == -1) {
      return const Result.failure(NotFoundException('Sepeda motor tidak ditemukan'));
    }

    final updated = motorcycle.copyWith(
      updatedAt: DateTime.now(),
    );
    _motorcycles[index] = updated;
    _notify();
    return Result.success(updated);
  }

  @override
  Future<Result<Motorcycle>> updateMileage({
    required String motorcycleId,
    required int newMileage,
  }) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    final index = _motorcycles.indexWhere((m) => m.id == motorcycleId);
    if (index == -1) {
      return const Result.failure(NotFoundException('Sepeda motor tidak ditemukan'));
    }

    final existing = _motorcycles[index];
    final updated = existing.copyWith(
      currentMileage: newMileage,
      mileageUpdatedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _motorcycles[index] = updated;
    _notify();
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteMotorcycle(String id) async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    final index = _motorcycles.indexWhere((m) => m.id == id);
    if (index == -1) {
      return const Result.failure(NotFoundException('Sepeda motor tidak ditemukan'));
    }

    _motorcycles.removeAt(index);
    _notify();
    return const Result.success(null);
  }

  @override
  Stream<List<Motorcycle>> watchMotorcycles({required String userId}) async* {
    yield _motorcycles.where((m) => m.userId == userId || userId == 'demo-user-id').toList();
    yield* _streamController.stream.map(
      (list) => list.where((m) => m.userId == userId || userId == 'demo-user-id').toList(),
    );
  }

  /// Helper untuk reset state mock pada unit test
  void clear() {
    _motorcycles.clear();
    _notify();
  }

  void dispose() {
    _streamController.close();
  }
}
