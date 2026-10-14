import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// StatusChip MotoCare: selalu memuat teks dan ikon sesuai PRD 4.3 & 4.4
class StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final String? semanticLabel;

  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    this.backgroundColor = AppColors.cream,
    this.textColor = AppColors.textPrimary,
    this.borderColor,
    this.semanticLabel,
  });

  /// Factory untuk status pengingat: Terjadwal
  factory StatusChip.scheduled() => const StatusChip(
        label: 'Terjadwal',
        icon: Icons.calendar_today_rounded,
        backgroundColor: AppColors.cream,
        textColor: AppColors.textPrimary,
        borderColor: AppColors.peach,
        semanticLabel: 'Status pengingat terjadwal',
      );

  /// Factory untuk status pengingat: Segera Servis (Mendekati)
  factory StatusChip.near() => const StatusChip(
        label: 'Segera servis',
        icon: Icons.warning_amber_rounded,
        backgroundColor: Color(0xFFFFF4E5),
        textColor: AppColors.warning,
        borderColor: AppColors.warning,
        semanticLabel: 'Peringatan segera servis',
      );

  /// Factory untuk status pengingat: Terlambat
  factory StatusChip.overdue() => const StatusChip(
        label: 'Terlambat',
        icon: Icons.error_outline_rounded,
        backgroundColor: Color(0xFFFFEBEE),
        textColor: AppColors.error,
        borderColor: AppColors.error,
        semanticLabel: 'Peringatan servis terlambat',
      );

  /// Factory untuk status: Selesai
  factory StatusChip.completed() => const StatusChip(
        label: 'Selesai',
        icon: Icons.check_circle_outline_rounded,
        backgroundColor: Color(0xFFE8F5E9),
        textColor: AppColors.success,
        borderColor: AppColors.success,
        semanticLabel: 'Status telah selesai',
      );

  /// Factory untuk lencana Demo / Simulasi sesuai PRD 5.5
  factory StatusChip.demo() => const StatusChip(
        label: 'Demo/Simulasi',
        icon: Icons.science_outlined,
        backgroundColor: AppColors.cream,
        textColor: AppColors.primaryText,
        borderColor: AppColors.peach,
        semanticLabel: 'Lencana data demo simulasi',
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: borderColor ?? textColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
