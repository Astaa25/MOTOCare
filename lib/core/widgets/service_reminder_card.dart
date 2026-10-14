import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'status_chip.dart';

/// Kartu pengingat servis MotoCare sesuai PRD 4.3 & M5
class ServiceReminderCard extends StatelessWidget {
  final String title;
  final String? motorcycleName;
  final DateTime? reminderDate;
  final int? targetMileage;
  final String status; // 'scheduled', 'near', 'overdue', 'completed'
  final VoidCallback? onComplete;
  final VoidCallback? onRecordService;
  final VoidCallback? onTap;

  const ServiceReminderCard({
    super.key,
    required this.title,
    this.motorcycleName,
    this.reminderDate,
    this.targetMileage,
    required this.status,
    this.onComplete,
    this.onRecordService,
    this.onTap,
  });

  Widget _buildStatusChip() {
    switch (status) {
      case 'near':
        return StatusChip.near();
      case 'overdue':
        return StatusChip.overdue();
      case 'completed':
        return StatusChip.completed();
      case 'scheduled':
      default:
        return StatusChip.scheduled();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSevere = status == 'near' || status == 'overdue';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: status == 'overdue'
              ? const Color(0xFFFFF2F2) // Latar merah lembut untuk terlambat
              : (status == 'near'
                  ? const Color(0xFFFFF7F0) // Latar krem-oranye untuk mendekati
                  : AppColors.background),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: status == 'overdue'
                ? AppColors.error
                : (status == 'near' ? AppColors.orangeSoft : AppColors.border),
            width: isSevere ? 1.5 : 1.0,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isSevere
                  ? (status == 'overdue'
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.primary.withValues(alpha: 0.08))
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Judul dan status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (motorcycleName != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          motorcycleName!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 12),

            // Pemicu tanggal dan kilometer
            Row(
              children: <Widget>[
                if (reminderDate != null) ...<Widget>[
                  const Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppFormatters.dateShort(reminderDate!),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                if (reminderDate != null && targetMileage != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('•', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                if (targetMileage != null) ...<Widget>[
                  const Icon(
                    Icons.speed_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppFormatters.mileage(targetMileage!),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),

            // Tombol aksi jika pengingat belum selesai
            if (status != 'completed' && (onComplete != null || onRecordService != null)) ...<Widget>[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (onComplete != null)
                    TextButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Tandai Selesai'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (onRecordService != null) ...<Widget>[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onRecordService,
                      icon: const Icon(Icons.build_rounded, size: 14),
                      label: const Text('Catat Servis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
