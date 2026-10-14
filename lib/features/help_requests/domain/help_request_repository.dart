import 'mechanic.dart';
import 'request_status.dart';
import 'service_request.dart';

/// Kontrak repositori permintaan bantuan mekanik sesuai PRD Bagian 5.4, 6.6, dan 7 (M7)
abstract class HelpRequestRepository {
  /// Mengambil riwayat permintaan pengguna saat ini
  Future<List<ServiceRequest>> getMyRequests({bool? activeOnly});

  /// Mengambil permintaan aktif pengguna jika ada (pending, accepted, on_the_way, in_progress)
  Future<ServiceRequest?> getActiveRequest();

  /// Mengambil detail satu permintaan berdasarkan id
  Future<ServiceRequest?> getRequestById(String id);

  /// Membuat permintaan bantuan mekanik baru
  Future<ServiceRequest> createRequest(ServiceRequest request);

  /// Membatalkan permintaan sesuai RPC cancel_request (PRD 5.4)
  Future<ServiceRequest> cancelRequest(String requestId);

  /// Memajukan status permintaan sesuai RPC advance_request (PRD 5.4)
  Future<ServiceRequest> advanceRequest(
    String requestId,
    RequestStatus nextStatus, {
    Mechanic? assignedMechanic,
  });

  /// Menandai permintaan pending yang telah melewati batas 15 menit menjadi expired
  Future<void> expireStaleRequests();

  /// Memantau perubahan status permintaan secara real-time
  Stream<ServiceRequest?> watchRequest(String requestId);
}
