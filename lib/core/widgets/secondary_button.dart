import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/motion.dart';
import 'animated_loading.dart';

/// Tombol sekunder MotoCare dengan hover glow, tepi lembut, dan micro-animation
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
    this.height = AppTokens.buttonHeight,
    this.semanticLabel,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;
    final bool disableAnim = AppMotion.shouldDisableAnimation(context);
    final double targetScale = disableAnim
        ? 1.0
        : (_isPressed && isEnabled)
            ? 0.965
            : (_isHovered && isEnabled)
                ? 1.01
                : 1.0;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.semanticLabel ?? widget.label,
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          if (isEnabled && !_isHovered) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (_isHovered) setState(() => _isHovered = false);
        },
        child: AnimatedScale(
          scale: targetScale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: OutlinedButton(
              onPressed: isEnabled
                  ? () {
                      HapticFeedback.selectionClick();
                      widget.onPressed?.call();
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                backgroundColor: _isHovered && isEnabled
                    ? AppColors.cream
                    : AppColors.surfaceBright,
                foregroundColor: AppColors.textPrimary,
                disabledForegroundColor:
                    AppColors.textSecondary.withValues(alpha: 0.5),
                side: BorderSide(
                  color: _isHovered && isEnabled
                      ? AppColors.primary.withValues(alpha: 0.55)
                      : AppColors.border,
                  width: 1.5,
                ),
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: widget.isLoading
                      ? MotoCareLoadingIndicator.small(color: AppColors.primary)
                      : Row(
                          key: ValueKey<String>(widget.label),
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
        ),
      ),
    );
  }
}
