import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/services/maps_cost_controller.dart';
import 'package:motocare/features/help_requests/domain/help_request_repository.dart';
import 'package:motocare/features/help_requests/domain/mechanic.dart';
import 'package:motocare/features/help_requests/domain/service_request.dart';
import 'package:motocare/features/help_requests/presentation/help_requests_providers.dart';

class _FakeHelpRequestRepository implements HelpRequestRepository {
  int createCallCount = 0;
  bool shouldThrow = false;

  @override
  Future<ServiceRequest> createRequest(ServiceRequest request) async {
    if (shouldThrow) {
      throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    }
    createCallCount++;
    return request.copyWith(id: 'created-id-$createCallCount');
  }

  @override
  Future<ServiceRequest?> getActiveRequest() async => null;

  @override
  Future<List<ServiceRequest>> getMyRequests({bool? activeOnly}) async => [];

  @override
  Future<ServiceRequest?> getRequestById(String id) async => null;

  @override
  Future<ServiceRequest> cancelRequest(String requestId) async {
    throw UnimplementedError();
  }

  @override
  Future<ServiceRequest> advanceRequest(
    String requestId,
    dynamic nextStatus, {
    Mechanic? assignedMechanic,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> expireStaleRequests() async {}

  @override
  Stream<ServiceRequest?> watchRequest(String requestId) => const Stream.empty();
}

void main() {
  group('Tahap 7 - Ketangguhan dan Keamanan Integrasi Maps', () {
    test('Idempotency key mencegah pengiriman ganda pada HelpRequestActionNotifier', () async {
      final fakeRepo = _FakeHelpRequestRepository();
      final container = ProviderContainer(
        overrides: [
          helpRequestRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(helpRequestActionNotifierProvider.notifier);
      final idempotencyKey = MapsSessionTokenManager.generateUuidV4();

      final request1 = ServiceRequest(
        id: '',
        userId: 'user-1',
        motorcycleId: 'moto-1',
        motorcycleName: 'Honda Vario 160',
        issueCategory: 'Ban Bocor',
        issueDescription: 'Ban belakang bocor di dekat simpang',
        latitude: 5.1801,
        longitude: 97.1402,
        addressText: 'Jl. Merdeka Barat No. 88, Lhokseumawe',
        cityRegency: 'Kota Lhokseumawe',
        contactPhone: '081234567890',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
        isDemo: true,
        idempotencyKey: idempotencyKey,
      );

      // Panggilan pertama
      final result1 = await notifier.createRequest(request1);
      expect(result1, isNotNull);
      expect(result1?.id, 'created-id-1');
      expect(fakeRepo.createCallCount, 1);

      // Panggilan kedua dengan idempotency key yang sama (misal user tap berulang atau retry jaringan)
      final result2 = await notifier.createRequest(request1);
      expect(result2, isNotNull);
      expect(result2?.id, 'created-id-1');
      // Harus TIDAK memanggil repositori lagi
      expect(fakeRepo.createCallCount, 1);
    });

    test('Error handling menangkap exception dan mengembalikan pesan ramah pengguna', () async {
      final fakeRepo = _FakeHelpRequestRepository()..shouldThrow = true;
      final container = ProviderContainer(
        overrides: [
          helpRequestRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(helpRequestActionNotifierProvider.notifier);
      final request = ServiceRequest(
        id: '',
        userId: 'user-1',
        motorcycleId: 'moto-1',
        motorcycleName: 'Honda Beat',
        issueCategory: 'Mogok',
        issueDescription: 'Mesin mati total',
        latitude: 5.1801,
        longitude: 97.1402,
        addressText: 'Jl. Samudera',
        contactPhone: '081234567890',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      final result = await notifier.createRequest(request);
      expect(result, isNull);
      expect(container.read(helpRequestActionNotifierProvider).errorMessage,
          contains('Gagal terhubung ke server'));
    });

    test('MapsSessionTokenManager me-reset token saat sesi selesai', () {
      final manager = MapsSessionTokenManager();
      final token1 = manager.getOrCreateToken();
      expect(token1, isNotEmpty);

      // Token yang sama jika dipanggil lagi dalam waktu dekat
      final token2 = manager.getOrCreateToken();
      expect(token2, equals(token1));

      // Sesi selesai (misal setelah Place Details dipanggil)
      manager.consumeToken();

      // Token baru dibuat saat permintaan baru berikutnya
      final token3 = manager.getOrCreateToken();
      expect(token3, isNotEmpty);
      expect(token3, isNot(equals(token1)));
    });

    test('MapsMemoryCache menghormati TTL', () async {
      final cache = MapsMemoryCache(defaultTtl: const Duration(milliseconds: 50));
      cache.set<String>('query_lhokseumawe', 'Hasil Bengkel');

      expect(cache.get<String>('query_lhokseumawe'), 'Hasil Bengkel');

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(cache.get<String>('query_lhokseumawe'), isNull);
    });
  });
}
