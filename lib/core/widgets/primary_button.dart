import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// Tombol utama MotoCare dengan micro-animation, target sentuh 48dp, dan indikator loading
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final String? semanticLabel;

  const PrimaryButton({
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
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
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
          child: ElevatedButton(
            onPressed: isEnabled
                ? () {
                    widget.onPressed?.call();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              disabledBackgroundColor: AppColors.peach.withValues(alpha: 0.5),
              disabledForegroundColor: AppColors.textSecondary.withValues(alpha: 0.6),
              elevation: 0,
              minimumSize: Size(widget.width ?? 0, widget.height),
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
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (widget.icon != null) ...<Widget>[
                          Icon(widget.icon, size: 18, color: AppColors.onPrimary),
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
                              color: AppColors.onPrimary,
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
