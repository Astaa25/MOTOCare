import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/env.dart';
import '../../notifications/presentation/notifications_providers.dart';
import '../data/demo_mechanic_simulator.dart';
import '../data/mock_help_request_repository.dart';
import '../data/supabase_help_request_repository.dart';
import '../domain/help_request_repository.dart';
import '../domain/mechanic.dart';
import '../domain/request_status.dart';
import '../domain/service_request.dart';

/// Provider repositori bantuan mekanik
final helpRequestRepositoryProvider = Provider<HelpRequestRepository>((ref) {
  if (AppEnv.useMock) {
    return MockHelpRequestRepository();
  }
  return SupabaseHelpRequestRepository();
});

/// Provider simulator montir demo untuk mode mock (PRD 6.6)
final demoMechanicSimulatorProvider = Provider<DemoMechanicSimulator>((ref) {
  final sim = DemoMechanicSimulator();
  ref.onDispose(() => sim.dispose());
  return sim;
});

/// Provider daftar semua riwayat permintaan pengguna
final myHelpRequestsProvider =
    FutureProvider.autoDispose<List<ServiceRequest>>((ref) async {
  final repo = ref.watch(helpRequestRepositoryProvider);
  return repo.getMyRequests();
});

/// Provider permintaan aktif pengguna saat ini (pending, accepted, on_the_way, in_progress)
final activeHelpRequestProvider =
    FutureProvider.autoDispose<ServiceRequest?>((ref) async {
  final repo = ref.watch(helpRequestRepositoryProvider);
  return repo.getActiveRequest();
});

/// Provider detail permintaan berdasarkan ID
final helpRequestDetailProvider =
    FutureProvider.autoDispose.family<ServiceRequest?, String>((ref, id) async {
  final repo = ref.watch(helpRequestRepositoryProvider);
  return repo.getRequestById(id);
});

/// State untuk aksi permintaan bantuan mekanik
class HelpRequestActionState {
  final bool isLoading;
  final String? errorMessage;
  final ServiceRequest? lastCreatedRequest;

  const HelpRequestActionState({
    this.isLoading = false,
    this.errorMessage,
    this.lastCreatedRequest,
  });

  HelpRequestActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    ServiceRequest? lastCreatedRequest,
  }) {
    return HelpRequestActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastCreatedRequest: lastCreatedRequest ?? this.lastCreatedRequest,
    );
  }
}

/// Notifier pengelola aksi bantuan mekanik (Create, Cancel, Advance)
class HelpRequestActionNotifier extends StateNotifier<HelpRequestActionState> {
  final Ref _ref;
  final Map<String, ServiceRequest> _idempotentCache = <String, ServiceRequest>{};

  HelpRequestActionNotifier(this._ref) : super(const HelpRequestActionState());

  HelpRequestRepository get _repo => _ref.read(helpRequestRepositoryProvider);

  /// Membuat permintaan bantuan mekanik baru dengan proteksi idempotency key
  Future<ServiceRequest?> createRequest(ServiceRequest request) async {
    // Idempotency check: jika key yang sama terkirim berulang kali (akibat retry), kembalikan hasil yang sama
    if (request.idempotencyKey != null &&
        _idempotentCache.containsKey(request.idempotencyKey!)) {
      return _idempotentCache[request.idempotencyKey!];
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final created = await _repo.createRequest(request);

      if (request.idempotencyKey != null) {
        _idempotentCache[request.idempotencyKey!] = created;
      }

      // Jika dalam mode mock, jadwalkan simulasi mekanik otomatis
      if (AppEnv.useMock) {
        final notifRepo = _ref.read(notificationRepositoryProvider);
        _ref.read(demoMechanicSimulatorProvider).scheduleAutoAdvance(
              requestId: created.id,
              repository: _repo,
              notificationRepository: notifRepo,
            );
      }

      state = state.copyWith(
        isLoading: false,
        lastCreatedRequest: created,
      );

      _ref.invalidate(myHelpRequestsProvider);
      _ref.invalidate(activeHelpRequestProvider);

      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  /// Membatalkan permintaan bantuan mekanik
  Future<bool> cancelRequest(String requestId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repo.cancelRequest(requestId);
      state = state.copyWith(isLoading: false);

      _ref.invalidate(myHelpRequestsProvider);
      _ref.invalidate(activeHelpRequestProvider);
      _ref.invalidate(helpRequestDetailProvider(requestId));

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Memajukan status permintaan (RPC advance_request)
  Future<bool> advanceRequest(
    String requestId,
    RequestStatus nextStatus, {
    Mechanic? assignedMechanic,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repo.advanceRequest(
        requestId,
        nextStatus,
        assignedMechanic: assignedMechanic,
      );
      state = state.copyWith(isLoading: false);

      _ref.invalidate(myHelpRequestsProvider);
      _ref.invalidate(activeHelpRequestProvider);
      _ref.invalidate(helpRequestDetailProvider(requestId));

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final helpRequestActionNotifierProvider = StateNotifierProvider<
    HelpRequestActionNotifier, HelpRequestActionState>((ref) {
  return HelpRequestActionNotifier(ref);
});
