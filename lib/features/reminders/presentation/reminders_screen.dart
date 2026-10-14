import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../../motorcycles/presentation/motorcycle_providers.dart';
import '../domain/maintenance_reminder.dart';
import '../domain/reminder_status.dart';
import 'reminders_providers.dart';

/// Layar Daftar Pengingat Servis per Sepeda Motor (`/motors/:id/reminders`)
class RemindersScreen extends ConsumerWidget {
  final String motorcycleId;

  const RemindersScreen({
    super.key,
    required this.motorcycleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motorAsync = ref.watch(motorcycleDetailProvider(motorcycleId));
    final sortedRemindersAsync = ref.watch(sortedRemindersProvider(motorcycleId));

    final motor = motorAsync.valueOrNull;
    final int currentKm = motor?.currentMileage ?? 0;
    final String motorTitle = motor != null ? '${motor.brand} ${motor.model}' : 'Sepeda Motor';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Pengingat Servis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$motorTitle • ${AppFormatters.formatKilometer(currentKm)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_reminder_fab'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Pengingat',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => context.push('/reminders/new?motorId=$motorcycleId'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(remindersProvider(motorcycleId));
            ref.invalidate(motorcycleDetailProvider(motorcycleId));
          },
          child: sortedRemindersAsync.when(
            loading: () => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => const LoadingSkeleton(height: 110, borderRadius: 16),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorState(
                  title: 'Gagal Memuat Pengingat',
                  message: err.toString(),
                  onRetry: () => ref.invalidate(remindersProvider(motorcycleId)),
                ),
              ),
            ),
            data: (List<MaintenanceReminder> reminders) {
              if (reminders.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: <Widget>[
                    const SizedBox(height: 60),
                    EmptyState(
                      key: const Key('reminders_empty_state'),
                      icon: Icons.alarm_rounded,
                      title: 'Belum Ada Pengingat Servis',
                      message:
                          'Atur jadwal ganti oli, cek rem, atau filter udara agar sepeda motor $motorTitle Anda selalu dalam kondisi prima.',
                      actionLabel: 'Buat Pengingat Pertama',
                      onAction: () => context.push('/reminders/new?motorId=$motorcycleId'),
                    ),
                  ],
                );
              }

              final activeCount = reminders.where((r) => !r.isCompleted).length;
              final overdueCount = reminders
                  .where((r) => r.computeStatus(currentKm) == ReminderStatus.overdue)
                  .length;

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                itemCount: reminders.length + 1,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _SummaryBanner(
                      activeCount: activeCount,
                      overdueCount: overdueCount,
                    );
                  }

                  final reminder = reminders[index - 1];
                  final status = reminder.computeStatus(currentKm);

                  return _ReminderCard(
                    key: Key('reminder_card_${reminder.id}'),
                    reminder: reminder,
                    status: status,
                    currentKm: currentKm,
                    onTap: () => context.push('/reminders/${reminder.id}'),
                    onRecordService: () {
                      context.push(
                        '/motors/$motorcycleId/services/new'
                        '?prefilledType=${Uri.encodeComponent(reminder.serviceType ?? reminder.title)}'
                        '&prefilledMileage=${reminder.targetMileage ?? currentKm}'
                        '&reminderId=${reminder.id}',
                      );
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

class _SummaryBanner extends StatelessWidget {
  final int activeCount;
  final int overdueCount;

  const _SummaryBanner({
    required this.activeCount,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: overdueCount > 0 ? const Color(0xFFFFEBEE) : AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: overdueCount > 0 ? const Color(0xFFFFCDD2) : AppColors.peach,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            overdueCount > 0 ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: overdueCount > 0 ? AppColors.error : AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              overdueCount > 0
                  ? '$overdueCount pengingat telah terlambat! Segera lakukan servis.'
                  : '$activeCount pengingat aktif dipantau secara otomatis.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: overdueCount > 0 ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final MaintenanceReminder reminder;
  final ReminderStatus status;
  final int currentKm;
  final VoidCallback onTap;
  final VoidCallback onRecordService;

  const _ReminderCard({
    super.key,
    required this.reminder,
    required this.status,
    required this.currentKm,
    required this.onTap,
    required this.onRecordService,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = reminder.isCompleted;

    // Hitung sisa hari & kilometer
    String targetInfo = '';
    if (reminder.reminderDate != null && reminder.targetMileage != null) {
      targetInfo =
          '${AppFormatters.formatDate(reminder.reminderDate!)} atau ${AppFormatters.formatKilometer(reminder.targetMileage!)}';
    } else if (reminder.reminderDate != null) {
      targetInfo = AppFormatters.formatDate(reminder.reminderDate!);
    } else if (reminder.targetMileage != null) {
      targetInfo = AppFormatters.formatKilometer(reminder.targetMileage!);
    }

    String differenceText = '';
    if (!isCompleted) {
      final List<String> diffParts = <String>[];
      if (reminder.reminderDate != null) {
        final int diffDays = reminder.reminderDate!
            .difference(DateTime.now())
            .inDays;
        if (diffDays < 0) {
          diffParts.add('Lewat ${diffDays.abs()} hari');
        } else if (diffDays == 0) {
          diffParts.add('Jatuh tempo hari ini');
        } else {
          diffParts.add('$diffDays hari lagi');
        }
      }

      if (reminder.targetMileage != null) {
        final int diffKm = reminder.targetMileage! - currentKm;
        if (diffKm < 0) {
          diffParts.add('Lewat ${AppFormatters.formatKilometer(diffKm.abs())}');
        } else if (diffKm == 0) {
          diffParts.add('KM tercapai');
        } else {
          diffParts.add('Sisa ${AppFormatters.formatKilometer(diffKm)}');
        }
      }
      differenceText = diffParts.join(' • ');
    }

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: status == ReminderStatus.overdue
              ? const Color(0xFFFFCDD2)
              : AppColors.border,
          width: status == ReminderStatus.overdue ? 1.5 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target: $targetInfo',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(
                    label: status.label,
                    icon: status.icon,
                    textColor: status.color,
                    backgroundColor: status.backgroundColor,
                    borderColor: status.borderColor,
                  ),
                ],
              ),
              if (differenceText.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == ReminderStatus.overdue
                        ? const Color(0xFFFFEBEE)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    differenceText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: status == ReminderStatus.overdue
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              if (!isCompleted) ...<Widget>[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton.icon(
                      onPressed: onRecordService,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text(
                        'Catat Servis',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
