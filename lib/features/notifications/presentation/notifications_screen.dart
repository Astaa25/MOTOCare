import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_effects.dart';
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
          'Notifikasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.deepTeal,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          if (AppEnv.showDemoFeatures)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.softPeach,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Simulasi',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.action,
                ),
              ),
            ),
          notifsAsync.maybeWhen(
            data: (list) {
              final hasUnread = list.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();

              return TextButton(
                key: const Key('mark_all_read_button'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () =>
                    ref.read(notificationsNotifierProvider.notifier).markAllAsRead(),
                child: const Text(
                  'Tandai Dibaca',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.action,
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(notificationsProvider);
          },
          child: notifsAsync.when(
            loading: () => LoadingSkeleton.notificationList(),
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
                  return AnimatedEntrance(
                    index: index,
                    child: _NotificationCard(
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
                    ),
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

    switch (notification.type) {
      case NotificationType.reminder:
        icon = Icons.alarm_rounded;
        break;
      case NotificationType.requestStatus:
        icon = Icons.build_circle_rounded;
        break;
      case NotificationType.system:
        icon = Icons.info_outline_rounded;
        break;
    }

    return Material(
      color: notification.isRead ? Colors.white : AppColors.softPeach.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notification.isRead ? const Color(0xFFF0EAE1) : AppColors.action.withValues(alpha: 0.3),
          width: 1.0,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: notification.isRead ? AppColors.softPeach : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.deepTeal, size: 22),
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepTeal,
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
                              color: AppColors.action,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
