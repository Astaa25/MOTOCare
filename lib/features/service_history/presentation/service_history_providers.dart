import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/env.dart';
import '../../../core/utils/result.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../../motorcycles/presentation/motorcycle_providers.dart';
import '../data/mock_service_history_repository.dart';
import '../data/supabase_service_history_repository.dart';
import '../domain/service_history.dart';
import '../domain/service_history_repository.dart';

/// Singleton mock repositori riwayat servis untuk sesi lokal dan pengujian
final mockServiceHistoryRepository = MockServiceHistoryRepository(
  motorcycleRepository: mockMotorcycleRepository,
);

/// Provider repositori riwayat servis MotoCare
final serviceHistoryRepositoryProvider = Provider<ServiceHistoryRepository>((ref) {
  if (AppEnv.useMock) {
    return mockServiceHistoryRepository;
  }
  try {
    return SupabaseServiceHistoryRepository();
  } catch (_) {
    return mockServiceHistoryRepository;
  }
});

/// Provider filter jenis servis terpilih per motor (null atau 'Semua' = tanpa filter)
final serviceHistoryFilterProvider =
    StateProvider.family<String?, String>((ref, motorcycleId) => null);

/// State notifier untuk riwayat servis per sepeda motor (dengan pagination)
class ServiceHistoriesNotifier extends StateNotifier<AsyncValue<List<ServiceHistory>>> {
  final ServiceHistoryRepository _repository;
  final String _motorcycleId;
  final Ref _ref;

  static const int _pageSize = 20;
  int _currentOffset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  ServiceHistoriesNotifier(this._repository, this._motorcycleId, this._ref)
      : super(const AsyncValue.loading()) {
    loadServiceHistories();
  }

  Future<void> loadServiceHistories({String? serviceType}) async {
    state = const AsyncValue.loading();
    _currentOffset = 0;
    _hasMore = true;

    final result = await _repository.getServiceHistories(
      motorcycleId: _motorcycleId,
      serviceType: serviceType,
      limit: _pageSize,
      offset: 0,
    );

    result.when(
      onSuccess: (list) {
        _hasMore = list.length >= _pageSize;
        _currentOffset = list.length;
        state = AsyncValue.data(list);
      },
      onFailure: (err) {
        state = AsyncValue.error(err, StackTrace.current);
      },
    );
  }

  Future<void> loadMore({String? serviceType}) async {
    if (!_hasMore || _isLoadingMore || state.isLoading) return;

    _isLoadingMore = true;
    final currentList = state.valueOrNull ?? <ServiceHistory>[];

    final result = await _repository.getServiceHistories(
      motorcycleId: _motorcycleId,
      serviceType: serviceType,
      limit: _pageSize,
      offset: _currentOffset,
    );

    result.when(
      onSuccess: (newList) {
        _hasMore = newList.length >= _pageSize;
        _currentOffset += newList.length;
        state = AsyncValue.data(<ServiceHistory>[...currentList, ...newList]);
      },
      onFailure: (_) {
        // Abaikan kegagalan load more, tetap simpan list lama
      },
    );

    _isLoadingMore = false;
  }

  Future<Result<ServiceHistory>> addServiceHistory({
    required DateTime serviceDate,
    required int mileage,
    required String serviceType,
    String? description,
    required int cost,
    String? workshopId,
    String? workshopName,
  }) async {
    final user = _ref.read(currentUserProvider);
    final userId = user?.id ?? 'demo-user-id';

    final result = await _repository.addServiceHistory(
      motorcycleId: _motorcycleId,
      userId: userId,
      serviceDate: serviceDate,
      mileage: mileage,
      serviceType: serviceType,
      description: description,
      cost: cost,
      workshopId: workshopId,
      workshopName: workshopName,
    );

    if (result.isSuccess) {
      await loadServiceHistories();
      // Perbarui state motor jika kilometer motor terupdate
      _ref.read(motorcyclesProvider.notifier).loadMotorcycles();
      _ref.invalidate(motorcycleDetailProvider(_motorcycleId));
    }

    return result;
  }

  Future<Result<ServiceHistory>> updateServiceHistory(ServiceHistory serviceHistory) async {
    final result = await _repository.updateServiceHistory(serviceHistory);
    if (result.isSuccess) {
      await loadServiceHistories();
      _ref.read(motorcyclesProvider.notifier).loadMotorcycles();
      _ref.invalidate(motorcycleDetailProvider(_motorcycleId));
    }
    return result;
  }

  Future<Result<void>> deleteServiceHistory(String id) async {
    final result = await _repository.deleteServiceHistory(id);
    if (result.isSuccess) {
      await loadServiceHistories();
    }
    return result;
  }
}

/// Provider daftar riwayat servis untuk motor tertentu
final serviceHistoriesProvider = StateNotifierProvider.family<
    ServiceHistoriesNotifier, AsyncValue<List<ServiceHistory>>, String>((ref, motorcycleId) {
  final repository = ref.watch(serviceHistoryRepositoryProvider);
  return ServiceHistoriesNotifier(repository, motorcycleId, ref);
});

/// Provider daftar riwayat servis yang terfilter sesuai pilihan chip
final filteredServiceHistoriesProvider =
    Provider.family<AsyncValue<List<ServiceHistory>>, String>((ref, motorcycleId) {
  final asyncList = ref.watch(serviceHistoriesProvider(motorcycleId));
  final selectedFilter = ref.watch(serviceHistoryFilterProvider(motorcycleId));

  return asyncList.whenData((list) {
    if (selectedFilter == null ||
        selectedFilter.trim().isEmpty ||
        selectedFilter == 'Semua') {
      return list;
    }
    return list
        .where((s) => s.serviceType.toLowerCase() == selectedFilter.toLowerCase())
        .toList();
  });
});

/// Provider total akumulasi biaya servis yang sedang terfilter sesuai PRD 7 M4
final filteredTotalCostProvider =
    Provider.family<int, String>((ref, motorcycleId) {
  final asyncList = ref.watch(filteredServiceHistoriesProvider(motorcycleId));
  return asyncList.maybeWhen(
    data: (list) => list.fold<int>(0, (sum, item) => sum + item.cost),
    orElse: () => 0,
  );
});

/// Provider detail satu catatan servis berdasarkan ID
final serviceHistoryDetailProvider =
    FutureProvider.family<ServiceHistory, String>((ref, serviceId) async {
  final repository = ref.watch(serviceHistoryRepositoryProvider);
  final result = await repository.getServiceHistoryById(serviceId);
  return result.when(
    onSuccess: (record) => record,
    onFailure: (err) => throw err,
  );
});
