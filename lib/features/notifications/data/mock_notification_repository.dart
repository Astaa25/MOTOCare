import 'dart:async';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../domain/app_notification.dart';
import '../domain/notification_repository.dart';

/// Implementasi mock in-memory untuk NotificationRepository (PRD Bagian 7 M5)
class MockNotificationRepository implements NotificationRepository {
  final List<AppNotification> _notifications = <AppNotification>[];
  final StreamController<List<AppNotification>> _streamController =
      StreamController<List<AppNotification>>.broadcast();

  final bool simulateDelay;

  MockNotificationRepository({
    this.simulateDelay = true,
    bool populateDemoData = true,
  }) {
    if (populateDemoData) {
      _seedDemoData();
    }
  }

  void _seedDemoData() {
    final DateTime now = DateTime.now();
    _notifications.addAll(<AppNotification>[
      AppNotification(
        id: 'demo-notif-1',
        userId: 'demo-user-1',
        title: 'Jadwal Servis: Cek Rem & Kampas Terlambat',
        body: 'Pengingat servis cek rem Anda sudah melewati batas waktu. Segera lakukan pengecekan demi keselamatan berkendara.',
        type: NotificationType.reminder,
        isRead: false,
        relatedId: 'demo-reminder-2',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      AppNotification(
        id: 'demo-notif-2',
        userId: 'demo-user-1',
        title: 'Segera Servis: Cek Tekanan Ban',
        body: 'Pemeriksaan tekanan ban Anda jatuh tempo dalam 4 hari ke depan.',
        type: NotificationType.reminder,
        isRead: false,
        relatedId: 'demo-reminder-3',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: 'demo-notif-3',
        userId: 'demo-user-1',
        title: 'Selamat Datang di MotoCare!',
        body: 'Aplikasi pendamping perawatan motor Anda di Lhokseumawe & Aceh Utara. Catat servis dan pantau kondisi motor dengan mudah.',
        type: NotificationType.system,
        isRead: true,
        relatedId: null,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ]);
  }

  Future<void> _maybeDelay() async {
    if (simulateDelay) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  void _notify() {
    _streamController.add(List<AppNotification>.unmodifiable(_notifications));
  }

  @override
  Future<Result<List<AppNotification>>> getNotifications() async {
    await _maybeDelay();
    try {
      final list = List<AppNotification>.from(_notifications)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Result<List<AppNotification>>.success(list);
    } catch (e) {
      return Result<List<AppNotification>>.failure(
        ServerException('Gagal memuat notifikasi.', e),
      );
    }
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    await _maybeDelay();
    try {
      final count = _notifications.where((n) => !n.isRead).length;
      return Result<int>.success(count);
    } catch (e) {
      return Result<int>.failure(
        ServerException('Gagal menghitung notifikasi belum dibaca.', e),
      );
    }
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    await _maybeDelay();
    try {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _notify();
      }
      return const Result<void>.success(null);
    } catch (e) {
      return Result<void>.failure(
        ServerException('Gagal menandai notifikasi telah dibaca.', e),
      );
    }
  }

  @override
  Future<Result<void>> markAllAsRead() async {
    await _maybeDelay();
    try {
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      _notify();
      return const Result<void>.success(null);
    } catch (e) {
      return Result<void>.failure(
        ServerException('Gagal menandai semua notifikasi telah dibaca.', e),
      );
    }
  }

  @override
  Future<Result<AppNotification>> addNotification(
    AppNotification notification,
  ) async {
    await _maybeDelay();
    try {
      final String id = notification.id.isEmpty
          ? 'notif_${DateTime.now().millisecondsSinceEpoch}'
          : notification.id;

      final item = notification.copyWith(id: id);
      _notifications.insert(0, item);
      _notify();
      return Result<AppNotification>.success(item);
    } catch (e) {
      return Result<AppNotification>.failure(
        ServerException('Gagal menambahkan notifikasi.', e),
      );
    }
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    return _streamController.stream.map(
      (list) => List<AppNotification>.from(list)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  void dispose() {
    _streamController.close();
  }
}
