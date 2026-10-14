import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'primary_button.dart';

/// Komponen keadaan kosong MotoCare sesuai PRD 4.3 & 7 M1
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Widget? extraContent;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.peach, width: 1.5),
              ),
              child: Icon(
                icon,
                size: 38,
                color: AppColors.primary,
                semanticLabel: title,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 24),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                width: 220,
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...<Widget>[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(
                  secondaryActionLabel!,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (extraContent != null) ...<Widget>[
              const SizedBox(height: 20),
              extraContent!,
            ],
          ],
        ),
      ),
    );
  }
}
