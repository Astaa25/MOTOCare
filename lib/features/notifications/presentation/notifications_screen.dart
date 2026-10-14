import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../domain/app_notification.dart';
import 'notifications_providers.dart';

/// Layar Pusat Notifikasi In-App (`/notifications`) sesuai PRD Bagian 7 M5
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pusat Notifikasi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: <Widget>[
          notifsAsync.maybeWhen(
            data: (list) {
              final hasUnread = list.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();

              return TextButton(
                key: const Key('mark_all_read_button'),
                onPressed: () =>
                    ref.read(notificationsNotifierProvider.notifier).markAllAsRead(),
                child: const Text(
                  'Tandai Dibaca',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(notificationsProvider);
          },
          child: notifsAsync.when(
            loading: () => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => const LoadingSkeleton(height: 90, borderRadius: 14),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorState(
                  title: 'Gagal Memuat Notifikasi',
                  message: err.toString(),
                  onRetry: () => ref.invalidate(notificationsProvider),
                ),
              ),
            ),
            data: (List<AppNotification> notifications) {
              if (notifications.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const <Widget>[
                    SizedBox(height: 80),
                    EmptyState(
                      key: Key('notifications_empty_state'),
                      icon: Icons.notifications_off_outlined,
                      title: 'Belum Ada Notifikasi',
                      message:
                          'Semua pemberitahuan jadwal servis dan status bantuan mekanik Anda akan muncul di sini.',
                    ),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return _NotificationCard(
                    key: Key('notification_card_${notif.id}'),
                    notification: notif,
                    onTap: () async {
                      if (!notif.isRead) {
                        await ref
                            .read(notificationsNotifierProvider.notifier)
                            .markAsRead(notif.id);
                      }

                      if (context.mounted && notif.relatedId != null) {
                        if (notif.type == NotificationType.reminder) {
                          context.push('/reminders/${notif.relatedId}');
                        } else if (notif.type == NotificationType.requestStatus) {
                          context.push('/help/${notif.relatedId}');
                        }
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.reminder:
        icon = Icons.alarm_rounded;
        iconColor = AppColors.warning;
        break;
      case NotificationType.requestStatus:
        icon = Icons.build_circle_rounded;
        iconColor = AppColors.primary;
        break;
      case NotificationType.system:
        icon = Icons.info_outline_rounded;
        iconColor = AppColors.textSecondary;
        break;
    }

    return Material(
      color: notification.isRead ? Colors.white : const Color(0xFFFFF9F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: notification.isRead ? AppColors.border : AppColors.peach,
          width: notification.isRead ? 1.0 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead) ...<Widget>[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppFormatters.formatDate(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
