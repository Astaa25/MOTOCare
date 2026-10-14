import 'dart:async';
import '../../../core/errors/app_exception.dart';
import '../domain/help_request_repository.dart';
import '../domain/help_request_rules.dart';
import '../domain/mechanic.dart';
import '../domain/request_status.dart';
import '../domain/service_request.dart';

/// Implementasi mock repositori permintaan bantuan mekanik sesuai PRD Bagian 5.4, 6.6, dan 7 (M7)
class MockHelpRequestRepository implements HelpRequestRepository {
  final List<ServiceRequest> _requests = <ServiceRequest>[];
  final StreamController<List<ServiceRequest>> _streamController =
      StreamController<List<ServiceRequest>>.broadcast();

  MockHelpRequestRepository({List<ServiceRequest>? initialRequests}) {
    if (initialRequests != null) {
      _requests.addAll(initialRequests);
    }
  }

  void _notify() {
    if (!_streamController.isClosed) {
      _streamController.add(List<ServiceRequest>.unmodifiable(_requests));
    }
  }

  @override
  Future<List<ServiceRequest>> getMyRequests({bool? activeOnly}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await expireStaleRequests();

    if (activeOnly == true) {
      return _requests.where((r) => r.status.isActive).toList();
    }

    // Urutkan dari yang terbaru
    final sorted = List<ServiceRequest>.from(_requests);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<ServiceRequest?> getActiveRequest() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await expireStaleRequests();

    try {
      return _requests.firstWhere((r) => r.status.isActive);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ServiceRequest?> getRequestById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await expireStaleRequests();

    try {
      return _requests.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ServiceRequest> createRequest(ServiceRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await expireStaleRequests();

    // Penegakan indeks unik satu permintaan aktif per pengguna (PRD 5.1 & 6.6 TC-21)
    final bool hasActive = _requests.any((r) => r.status.isActive);
    if (hasActive) {
      throw const ValidationException(
        'Anda masih memiliki permintaan aktif yang sedang diproses.',
      );
    }

    // Validasi aturan PRD 6.7
    final descErr = HelpRequestRules.validateIssueDescription(request.issueDescription);
    if (descErr != null) {
      throw ValidationException(descErr);
    }

    final phoneErr = HelpRequestRules.validateContactPhone(request.contactPhone);
    if (phoneErr != null) {
      throw ValidationException(phoneErr);
    }

    final newReq = request.copyWith(
      id: request.id.isNotEmpty
          ? request.id
          : 'req-${DateTime.now().millisecondsSinceEpoch}',
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      isDemo: true,
    );

    _requests.insert(0, newReq);
    _notify();
    return newReq;
  }

  @override
  Future<ServiceRequest> cancelRequest(String requestId) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));

    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      throw const NotFoundException('Permintaan bantuan tidak ditemukan.');
    }

    final current = _requests[index];
    if (!HelpRequestRules.canCancel(current.status)) {
      throw ValidationException(
        'Permintaan berstatus "${current.status.label}" tidak dapat dibatalkan.',
      );
    }

    final updated = current.copyWith(status: RequestStatus.cancelled);
    _requests[index] = updated;
    _notify();
    return updated;
  }

  @override
  Future<ServiceRequest> advanceRequest(
    String requestId,
    RequestStatus nextStatus, {
    Mechanic? assignedMechanic,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) {
      throw const NotFoundException('Permintaan bantuan tidak ditemukan.');
    }

    final current = _requests[index];
    if (!HelpRequestRules.isValidStatusAdvance(current.status, nextStatus)) {
      throw ValidationException(
        'Transisi status dari ${current.status.name} ke ${nextStatus.name} tidak sah.',
      );
    }

    DateTime? acceptedAt = current.acceptedAt;
    if (nextStatus == RequestStatus.accepted && acceptedAt == null) {
      acceptedAt = DateTime.now();
    }

    DateTime? completedAt = current.completedAt;
    if (nextStatus == RequestStatus.completed && completedAt == null) {
      completedAt = DateTime.now();
    }

    final updated = current.copyWith(
      status: nextStatus,
      acceptedAt: acceptedAt,
      completedAt: completedAt,
      mechanicId: assignedMechanic?.id ?? current.mechanicId,
      mechanic: assignedMechanic ?? current.mechanic,
    );

    _requests[index] = updated;
    _notify();
    return updated;
  }

  @override
  Future<void> expireStaleRequests() async {
    final now = DateTime.now();
    bool changed = false;

    for (int i = 0; i < _requests.length; i++) {
      final req = _requests[i];
      if (req.status == RequestStatus.pending && now.isAfter(req.expiresAt)) {
        _requests[i] = req.copyWith(status: RequestStatus.expired);
        changed = true;
      }
    }

    if (changed) {
      _notify();
    }
  }

  @override
  Stream<ServiceRequest?> watchRequest(String requestId) {
    return _streamController.stream.map((list) {
      try {
        return list.firstWhere((r) => r.id == requestId);
      } catch (_) {
        return null;
      }
    });
  }

  void dispose() {
    _streamController.close();
  }
}
