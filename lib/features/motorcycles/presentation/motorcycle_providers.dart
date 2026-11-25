import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/env.dart';
import '../../../core/utils/result.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../data/mock_motorcycle_repository.dart';
import '../data/supabase_motorcycle_repository.dart';
import '../domain/motorcycle.dart';
import '../domain/motorcycle_repository.dart';

/// Singleton mock repository agar data tetap persisten selama sesi running
final mockMotorcycleRepository = MockMotorcycleRepository();

/// Provider repositori sepeda motor
final motorcycleRepositoryProvider = Provider<MotorcycleRepository>((ref) {
  if (AppEnv.useMock) {
    return mockMotorcycleRepository;
  }
  try {
    return SupabaseMotorcycleRepository();
  } catch (_) {
    return mockMotorcycleRepository;
  }
});

/// State notifier untuk daftar sepeda motor milik pengguna aktif
class MotorcyclesNotifier extends StateNotifier<AsyncValue<List<Motorcycle>>> {
  final MotorcycleRepository _repository;
  final String? _userId;

  MotorcyclesNotifier(this._repository, this._userId)
      : super(const AsyncValue.loading()) {
    loadMotorcycles();
  }

  Future<void> loadMotorcycles() async {
    final uid = _userId ?? 'demo-user-id';
    state = const AsyncValue.loading();
    final result = await _repository.getMotorcycles(userId: uid);
    state = result.when(
      onSuccess: (list) => AsyncValue.data(list),
      onFailure: (err) => AsyncValue.error(err, StackTrace.current),
    );
  }

  Future<Result<Motorcycle>> addMotorcycle({
    required String brand,
    required String model,
    required int productionYear,
    String? licensePlate,
    required int currentMileage,
    String? color,
    String? category,
    int? engineCc,
    String? transmission,
    String? fuelType,
    String? photoUrl,
  }) async {
    final uid = _userId ?? 'demo-user-id';
    final result = await _repository.addMotorcycle(
      userId: uid,
      brand: brand,
      model: model,
      productionYear: productionYear,
      licensePlate: licensePlate,
      currentMileage: currentMileage,
      color: color,
      category: category,
      engineCc: engineCc,
      transmission: transmission,
      fuelType: fuelType,
      photoUrl: photoUrl,
    );

    if (result.isSuccess) {
      await loadMotorcycles();
    }
    return result;
  }

  Future<Result<Motorcycle>> updateMotorcycle(Motorcycle motorcycle) async {
    final result = await _repository.updateMotorcycle(motorcycle);
    if (result.isSuccess) {
      await loadMotorcycles();
    }
    return result;
  }

  Future<Result<Motorcycle>> updateMileage({
    required String motorcycleId,
    required int newMileage,
  }) async {
    final result = await _repository.updateMileage(
      motorcycleId: motorcycleId,
      newMileage: newMileage,
    );
    if (result.isSuccess) {
      await loadMotorcycles();
    }
    return result;
  }

  Future<Result<void>> deleteMotorcycle(String id) async {
    final result = await _repository.deleteMotorcycle(id);
    if (result.isSuccess) {
      await loadMotorcycles();
    }
    return result;
  }
}

/// Provider daftar sepeda motor pengguna
final motorcyclesProvider =
    StateNotifierProvider<MotorcyclesNotifier, AsyncValue<List<Motorcycle>>>((ref) {
  final repository = ref.watch(motorcycleRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return MotorcyclesNotifier(repository, user?.id);
});

/// Provider sepeda motor aktif utama (MVP: motor pertama yang dimiliki pengguna)
final activeMotorcycleProvider = Provider<AsyncValue<Motorcycle?>>((ref) {
  final asyncList = ref.watch(motorcyclesProvider);
  return asyncList.whenData((list) => list.isNotEmpty ? list.first : null);
});

/// Provider detail sepeda motor berdasarkan ID
final motorcycleDetailProvider =
    FutureProvider.family<Motorcycle, String>((ref, id) async {
  final repository = ref.watch(motorcycleRepositoryProvider);
  final result = await repository.getMotorcycleById(id);
  return result.when(
    onSuccess: (motor) => motor,
    onFailure: (err) => throw err,
  );
});
