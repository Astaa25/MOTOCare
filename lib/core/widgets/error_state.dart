import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'primary_button.dart';

/// Komponen keadaan error MotoCare dengan pesan ramah dan tombol Coba lagi sesuai PRD 4.3 & M1
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String title;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Terjadi Kendala',
    this.icon = Icons.error_outline_rounded,
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
                color: const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Icon(
                icon,
                size: 38,
                color: AppColors.error,
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
            const SizedBox(height: 24),
            PrimaryButton(
              key: const Key('error_state_retry_button'),
              label: 'Coba lagi',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
              width: 180,
            ),
          ],
        ),
      ),
    );
  }
}
