import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Dialog konfirmasi untuk aksi merusak / penting sesuai PRD 4.3 & 4.4
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Ya, Lanjutkan',
    this.cancelLabel = 'Batal',
    this.isDestructive = false,
    required this.onConfirm,
  });

  /// Helper untuk menampilkan ConfirmationDialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Ya, Lanjutkan',
    String cancelLabel = 'Batal',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.background,
      elevation: 4,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDestructive ? const Color(0xFFFFEBEE) : AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDestructive ? Icons.delete_outline_rounded : Icons.help_outline_rounded,
                size: 28,
                color: isDestructive ? AppColors.error : AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
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
            Row(
              children: <Widget>[
                Expanded(
                  child: SecondaryButton(
                    key: const Key('confirmation_dialog_cancel_button'),
                    label: cancelLabel,
                    height: 44,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    key: const Key('confirmation_dialog_confirm_button'),
                    label: confirmLabel,
                    height: 44,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog sukses dengan centang dan animasi halus sesuai PRD 4.5
class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onDismiss;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonLabel = 'Selesai',
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Selesai',
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => SuccessDialog(
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.background,
      elevation: 4,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 36,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
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
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              key: const Key('success_dialog_button'),
              label: buttonLabel,
              height: 44,
              onPressed: onDismiss ?? () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper notifikasi toast / snackbar ramah pengguna
abstract class AppToast {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
