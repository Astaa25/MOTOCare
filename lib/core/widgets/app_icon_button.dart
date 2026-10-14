import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// Tombol ikon MotoCare dengan target sentuh minimal 48x48 dp dan micro-animation
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? tooltip;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.tooltip,
    this.iconColor,
    this.backgroundColor,
    this.size = 22.0,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null;
    final bool disableAnim = AppMotion.shouldDisableAnimation(context);

    Widget button = InkWell(
      onTap: widget.onPressed,
      borderRadius: BorderRadius.circular(12),
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
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.icon,
            size: widget.size,
            color: isEnabled
                ? (widget.iconColor ?? AppColors.textPrimary)
                : AppColors.textSecondary.withValues(alpha: 0.5),
            semanticLabel: widget.semanticLabel,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: (!disableAnim && _isPressed && isEnabled) ? 0.92 : 1.0,
        duration: AppMotion.buttonPress,
        child: button,
      ),
    );
  }
}
