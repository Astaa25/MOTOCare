import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// Tombol sekunder MotoCare dengan garis tepi lembut dan micro-animation
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final String? semanticLabel;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.height = 48.0,
    this.semanticLabel,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;
    final bool disableAnim = AppMotion.shouldDisableAnimation(context);

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.semanticLabel ?? widget.label,
      child: AnimatedScale(
        scale: (!disableAnim && _isPressed && isEnabled) ? 0.97 : 1.0,
        duration: AppMotion.buttonPress,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: OutlinedButton(
            onPressed: isEnabled ? widget.onPressed : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              disabledForegroundColor: AppColors.textSecondary.withValues(alpha: 0.5),
              side: const BorderSide(color: AppColors.border, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Listener(
              onPointerDown: (_) {
                if (isEnabled) setState(() => _isPressed = true);
              },
              onPointerUp: (_) {
                if (_isPressed) setState(() => _isPressed = false);
              },
              onPointerCancel: (_) {
                if (_isPressed) setState(() => _isPressed = false);
              },
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (widget.icon != null) ...<Widget>[
                          Icon(widget.icon, size: 18, color: AppColors.textPrimary),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
