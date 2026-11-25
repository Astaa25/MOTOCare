import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/motion.dart';

/// Tombol tersier MotoCare (text-only) dengan min tap target 48dp dan haptic feedback
class TertiaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;

  const TertiaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.textColor = AppColors.primary,
    this.fontSize = 13.0,
    this.fontWeight = FontWeight.w600,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
  });

  @override
  State<TertiaryButton> createState() => _TertiaryButtonState();
}

class _TertiaryButtonState extends State<TertiaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;
    final bool disableAnim = AppMotion.shouldDisableAnimation(context);

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.label,
      child: AnimatedScale(
        scale: (!disableAnim && _isPressed && isEnabled) ? 0.96 : 1.0,
        duration: AppMotion.buttonPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: AppTokens.minTouchTarget,
          ),
          child: TextButton(
            onPressed: isEnabled
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onPressed?.call();
                  }
                : null,
            style: TextButton.styleFrom(
              foregroundColor: widget.textColor,
              disabledForegroundColor: AppColors.textSecondary.withValues(alpha: 0.5),
              padding: widget.padding,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (widget.icon != null) ...<Widget>[
                    Icon(widget.icon, size: 16, color: widget.textColor),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: widget.fontWeight,
                      color: isEnabled ? widget.textColor : AppColors.textSecondary,
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
