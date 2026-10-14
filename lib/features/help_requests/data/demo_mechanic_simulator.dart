import 'dart:async';
import '../../notifications/domain/app_notification.dart';
import '../../notifications/domain/notification_repository.dart';
import '../domain/help_request_repository.dart';
import '../domain/mechanic.dart';
import '../domain/request_status.dart';

/// Simulator Montir Demo sesuai PRD Bagian 6.6 & 7 (M7)
/// Mensimulasikan konfirmasi montir, penugasan, dan perubahan status real-time dalam mode mock
class DemoMechanicSimulator {
  static final Mechanic demoMechanic = Mechanic(
    id: 'mech-demo-01',
    profileId: 'prof-mech-01',
    name: '[Demo] Bang Rudi Pratama',
    phone: '081269009988',
    workshopId: 'ws-01',
    workshopName: '[Demo] Bengkel Resmi Samudera Motor Lhokseumawe',
    isAvailable: true,
    serviceArea: 'Kota Lhokseumawe & Sekitarnya',
    isDemo: true,
    createdAt: DateTime(2026, 10, 1),
  );

  final List<Timer> _activeTimers = <Timer>[];

  void dispose() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
  }

  /// Menjadwalkan transisi status otomatis untuk demonstrasi alur penuh bantuan mekanik
  void scheduleAutoAdvance({
    required String requestId,
    required HelpRequestRepository repository,
    NotificationRepository? notificationRepository,
    Duration initialDelay = const Duration(seconds: 4),
  }) {
    final timer1 = Timer(initialDelay, () async {
      final req = await repository.getRequestById(requestId);
      if (req == null || req.status != RequestStatus.pending) return;

      await repository.advanceRequest(
        requestId,
        RequestStatus.accepted,
        assignedMechanic: demoMechanic,
      );

      // TC-12: Memicu notifikasi in-app saat status berubah
      if (notificationRepository != null) {
        await notificationRepository.addNotification(
          AppNotification(
            id: 'notif-mech-${DateTime.now().millisecondsSinceEpoch}',
            userId: req.userId,
            title: 'Mekanik Ditemukan! 🛵',
            body:
                '${demoMechanic.name} telah menerima panggilan Anda dan bersiap menuju lokasi.',
            type: NotificationType.requestStatus,
            relatedId: requestId,
            createdAt: DateTime.now(),
          ),
        );
      }

      // Lanjut ke on_the_way
      final timer2 = Timer(const Duration(seconds: 6), () async {
        final currentReq = await repository.getRequestById(requestId);
        if (currentReq == null ||
            currentReq.status != RequestStatus.accepted) {
          return;
        }

        await repository.advanceRequest(
          requestId,
          RequestStatus.onTheWay,
        );

        if (notificationRepository != null) {
          await notificationRepository.addNotification(
            AppNotification(
              id: 'notif-mech-otw-${DateTime.now().millisecondsSinceEpoch}',
              userId: currentReq.userId,
              title: 'Mekanik Dalam Perjalanan 📍',
              body:
                  '${demoMechanic.name} sedang berkendara menuju titik penjemputan Anda.',
              type: NotificationType.requestStatus,
              relatedId: requestId,
              createdAt: DateTime.now(),
            ),
          );
        }
      });
      _activeTimers.add(timer2);
    });
    _activeTimers.add(timer1);
  }
}
