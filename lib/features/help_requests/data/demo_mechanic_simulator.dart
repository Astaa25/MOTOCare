import 'dart:async';
import '../../../core/config/env.dart';
import '../../notifications/domain/app_notification.dart';
import '../../notifications/domain/notification_repository.dart';
import '../domain/help_request_repository.dart';
import '../domain/mechanic.dart';
import '../domain/request_status.dart';

/// Dispatcher Montir Mitra MotoCare
/// Menjadwalkan konfirmasi montir, penugasan, dan pembaruan status perjalanan secara otomatis
class DemoMechanicSimulator {
  static Mechanic get demoMechanic => Mechanic(
        id: 'mech-01',
        profileId: 'prof-mech-01',
        name: AppEnv.showDemoFeatures
            ? '[Demo] Bang Rudi Pratama'
            : 'Bang Rudi Pratama',
        phone: '081269009988',
        workshopId: 'ws-01',
        workshopName: AppEnv.showDemoFeatures
            ? '[Demo] Bengkel Resmi Samudera Motor Lhokseumawe'
            : 'Bengkel Resmi Samudera Motor Lhokseumawe',
        isAvailable: true,
        serviceArea: 'Kota Lhokseumawe & Sekitarnya',
        latitude: 5.1895,
        longitude: 97.1485,
        isDemo: AppEnv.showDemoFeatures,
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
