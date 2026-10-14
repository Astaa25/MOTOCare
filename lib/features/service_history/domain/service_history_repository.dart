import '../../../core/utils/result.dart';
import 'service_history.dart';

/// Kontrak repositori riwayat servis dan pencatatan biaya sesuai PRD 5.1 & M4
abstract class ServiceHistoryRepository {
  /// Mengambil daftar riwayat servis untuk sepeda motor tertentu dengan pagination dan filter opsional
  Future<Result<List<ServiceHistory>>> getServiceHistories({
    required String motorcycleId,
    String? serviceType,
    int limit = 20,
    int offset = 0,
  });

  /// Mengambil detail satu catatan riwayat servis berdasarkan ID
  Future<Result<ServiceHistory>> getServiceHistoryById(String id);

  /// Menambahkan catatan servis baru
  /// Catatan bisnis PRD 7 M4: Setelah simpan, perbarui kilometer motor bila kilometer servis lebih besar
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
  });

  /// Memperbarui catatan riwayat servis
  Future<Result<ServiceHistory>> updateServiceHistory(ServiceHistory serviceHistory);

  /// Menghapus catatan riwayat servis
  Future<Result<void>> deleteServiceHistory(String id);

  /// Menghitung total akumulasi biaya servis (dengan filter jenis servis opsional)
  Future<Result<int>> getTotalCost({
    required String motorcycleId,
    String? serviceType,
  });

  /// Stream reaktif pembaruan riwayat servis untuk motor tertentu
  Stream<List<ServiceHistory>> watchServiceHistories({required String motorcycleId});
}
