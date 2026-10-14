import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/env.dart';
import '../../../core/utils/result.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../../motorcycles/presentation/motorcycle_providers.dart';
import '../../reminders/presentation/reminders_providers.dart';
import '../data/mock_notification_repository.dart';
import '../data/supabase_notification_repository.dart';
import '../domain/app_notification.dart';
import '../domain/notification_repository.dart';
import '../services/notification_service.dart';

/// Singleton mock notification repository untuk data konsisten
final MockNotificationRepository _mockNotificationRepo =
    MockNotificationRepository(populateDemoData: true);

/// Provider repositori notifikasi
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (AppEnv.useMock) {
    return _mockNotificationRepo;
  }
  try {
    if (Supabase.instance.client.auth.currentSession != null) {
      return SupabaseNotificationRepository();
    }
  } catch (_) {}
  return _mockNotificationRepo;
});

/// Provider layanan notifikasi (lokal & sinkronisasi)
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = AppNotificationService();
  service.initialize();
  return service;
});

/// Provider daftar notifikasi
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  final res = await repo.getNotifications();
  if (res.isFailure) {
    throw res.exceptionOrNull!;
  }
  return res.dataOrNull ?? <AppNotification>[];
});

/// Provider jumlah notifikasi belum dibaca (badge)
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifsAsync = ref.watch(notificationsProvider);
  return notifsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

/// Notifier aksi notifikasi (baca, baca semua, sinkronisasi pengingat)
class NotificationsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  NotificationsNotifier(this._ref) : super(const AsyncValue<void>.data(null));

  Future<Result<void>> markAsRead(String id) async {
    final repo = _ref.read(notificationRepositoryProvider);
    final res = await repo.markAsRead(id);
    if (res.isSuccess) {
      _ref.invalidate(notificationsProvider);
    }
    return res;
  }

  Future<Result<void>> markAllAsRead() async {
    final repo = _ref.read(notificationRepositoryProvider);
    final res = await repo.markAllAsRead();
    if (res.isSuccess) {
      _ref.invalidate(notificationsProvider);
    }
    return res;
  }

  /// Sinkronisasi pengingat motor aktif ke pusat notifikasi in-app
  Future<void> syncWithReminders() async {
    try {
      final activeMotor = _ref.read(activeMotorcycleProvider).valueOrNull;
      if (activeMotor == null) return;

      final remindersAsync = _ref.read(remindersProvider(activeMotor.id));
      final reminders = remindersAsync.valueOrNull;
      if (reminders == null || reminders.isEmpty) return;

      final user = _ref.read(currentUserProvider);
      final userId = user?.id ?? 'demo-user-1';

      final service = _ref.read(notificationServiceProvider);
      final repo = _ref.read(notificationRepositoryProvider);

      await service.syncReminderNotifications(
        reminders: reminders,
        currentMileage: activeMotor.currentMileage,
        notificationRepository: repo,
        currentUserId: userId,
      );

      _ref.invalidate(notificationsProvider);
    } catch (_) {}
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<void>>(
  NotificationsNotifier.new,
);
