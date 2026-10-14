import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../motorcycles/presentation/motorcycle_providers.dart';
import '../domain/maintenance_reminder.dart';
import '../domain/reminder_status.dart';
import 'reminders_providers.dart';

/// Layar Detail Pengingat Servis (`/reminders/:id`)
class ReminderDetailScreen extends ConsumerWidget {
  final String reminderId;

  const ReminderDetailScreen({
    super.key,
    required this.reminderId,
  });

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    MaintenanceReminder reminder,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Hapus Pengingat Servis?',
      message:
          'Pengingat ini akan dihapus secara permanen dan jadwal notifikasinya akan dibatalkan.',
      confirmLabel: 'Ya, Hapus',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final res = await ref.read(remindersNotifierProvider.notifier).deleteReminder(
            reminder.id,
            reminder.motorcycleId,
          );

      if (context.mounted) {
        if (res.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengingat servis berhasil dihapus.'),
              backgroundColor: AppColors.textPrimary,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.exceptionOrNull?.message ?? 'Gagal menghapus pengingat.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleMarkCompleted(
    BuildContext context,
    WidgetRef ref,
    MaintenanceReminder reminder,
    int currentKm,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Tandai Pengingat Selesai?',
      message:
          'Pengingat ini akan ditandai selesai. Jika memiliki interval berulang, jadwal pengingat berikutnya akan otomatis dibuat.',
      confirmLabel: 'Tandai Selesai',
    );

    if (confirmed == true && context.mounted) {
      final res = await ref.read(remindersNotifierProvider.notifier).completeReminder(
            reminder.id,
            reminder.motorcycleId,
            serviceMileage: currentKm,
            serviceDate: DateTime.now(),
          );

      if (context.mounted) {
        if (res.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengingat berhasil ditandai selesai.'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.exceptionOrNull?.message ?? 'Gagal menandai selesai.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderAsync = ref.watch(reminderDetailProvider(reminderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Detail Pengingat Servis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: <Widget>[
          reminderAsync.maybeWhen(
            data: (reminder) => IconButton(
              key: const Key('edit_reminder_button'),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Ubah Pengingat',
              onPressed: () => context.push('/reminders/${reminder.id}/edit'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          reminderAsync.maybeWhen(
            data: (reminder) => IconButton(
              key: const Key('delete_reminder_button'),
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              tooltip: 'Hapus Pengingat',
              onPressed: () => _handleDelete(context, ref, reminder),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: reminderAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: LoadingSkeleton(height: 300, borderRadius: 16),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorState(
                title: 'Gagal Memuat Pengingat',
                message: err.toString(),
                onRetry: () => ref.invalidate(reminderDetailProvider(reminderId)),
              ),
            ),
          ),
          data: (MaintenanceReminder reminder) {
            final motorAsync = ref.watch(motorcycleDetailProvider(reminder.motorcycleId));
            final int currentKm = motorAsync.valueOrNull?.currentMileage ?? 0;
            final ReminderStatus status = reminder.computeStatus(currentKm);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // Kartu Utama Status Pengingat
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFFFFF0E3), Color(0xFFFFD0A6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              reminder.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          StatusChip(
                            label: status.label,
                            icon: status.icon,
                            textColor: status.color,
                            backgroundColor: status.backgroundColor,
                            borderColor: status.borderColor,
                          ),
                        ],
                      ),
                      if (reminder.serviceType != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          'Kategori Servis: ${reminder.serviceType}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Info Target Pemicu
                const Text(
                  'Kondisi Pemicu Pengingat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Target Tanggal
                _DetailRowItem(
                  icon: Icons.calendar_month_rounded,
                  title: 'Tanggal Jatuh Tempo',
                  value: reminder.reminderDate != null
                      ? AppFormatters.formatDate(reminder.reminderDate!)
                      : 'Tidak diatur',
                  subtitle: reminder.reminderDate != null && !reminder.isCompleted
                      ? () {
                          final diff = reminder.reminderDate!.difference(DateTime.now()).inDays;
                          if (diff < 0) return 'Terlambat ${diff.abs()} hari yang lalu';
                          if (diff == 0) return 'Jatuh tempo hari ini';
                          return '$diff hari lagi';
                        }()
                      : null,
                ),
                const SizedBox(height: 8),

                // Target Kilometer
                _DetailRowItem(
                  icon: Icons.speed_rounded,
                  title: 'Target Kilometer',
                  value: reminder.targetMileage != null
                      ? AppFormatters.formatKilometer(reminder.targetMileage!)
                      : 'Tidak diatur',
                  subtitle: reminder.targetMileage != null && !reminder.isCompleted
                      ? () {
                          final diff = reminder.targetMileage! - currentKm;
                          if (diff < 0) {
                            return 'Melewati target sebesar ${AppFormatters.formatKilometer(diff.abs())}';
                          }
                          if (diff == 0) return 'Target kilometer tercapai saat ini';
                          return 'Sisa ${AppFormatters.formatKilometer(diff)} dari posisi saat ini';
                        }()
                      : null,
                ),
                const SizedBox(height: 8),

                // Interval Berulang
                _DetailRowItem(
                  icon: Icons.replay_rounded,
                  title: 'Siklus Berulang',
                  value: () {
                    final parts = <String>[];
                    if (reminder.intervalKm != null) {
                      parts.add('Setiap ${AppFormatters.formatKilometer(reminder.intervalKm!)}');
                    }
                    if (reminder.intervalMonths != null) {
                      parts.add('Setiap ${reminder.intervalMonths} bulan');
                    }
                    return parts.isNotEmpty ? parts.join(' atau ') : 'Sekali saja (Tidak berulang)';
                  }(),
                ),
                const SizedBox(height: 32),

                // Tombol Aksi
                if (!reminder.isCompleted) ...<Widget>[
                  PrimaryButton(
                    key: const Key('record_service_from_reminder_button'),
                    label: 'Catat Servis Sekarang',
                    icon: Icons.build_rounded,
                    onPressed: () {
                      context.push(
                        '/motors/${reminder.motorcycleId}/services/new'
                        '?prefilledType=${Uri.encodeComponent(reminder.serviceType ?? reminder.title)}'
                        '&prefilledMileage=${reminder.targetMileage ?? currentKm}'
                        '&reminderId=${reminder.id}',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      key: const Key('mark_completed_button'),
                      icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
                      label: const Text(
                        'Tandai Selesai Tanpa Catat Servis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onPressed: () => _handleMarkCompleted(context, ref, reminder, currentKm),
                    ),
                  ),
                ] else ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.check_circle_rounded, color: AppColors.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            reminder.completedAt != null
                                ? 'Pengingat ini telah selesai pada ${AppFormatters.formatDate(reminder.completedAt!)}.'
                                : 'Pengingat ini telah ditandai selesai.',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailRowItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  const _DetailRowItem({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
