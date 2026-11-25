import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/motion.dart';
import 'animated_loading.dart';

/// Tombol utama MotoCare dengan animasi hover, press tactile bounce, warm glow, dan loading kustom
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
    this.height = AppTokens.buttonHeight,
    this.semanticLabel,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
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
                ? 1.012
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: isEnabled
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: _isHovered ? 0.34 : 0.20,
                        ),
                        blurRadius: _isHovered ? 16 : 10,
                        offset: Offset(0, _isHovered ? 5 : 3),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: ElevatedButton(
              onPressed: isEnabled
                  ? () {
                      HapticFeedback.selectionClick();
                      widget.onPressed?.call();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isHovered && isEnabled
                    ? const Color(0xFFB53B2B)
                    : AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.peach.withValues(alpha: 0.55),
                disabledForegroundColor:
                    AppColors.textSecondary.withValues(alpha: 0.6),
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: widget.isLoading
                      ? MotoCareLoadingIndicator.small(color: AppColors.onPrimary)
                      : Row(
                          key: ValueKey<String>(widget.label),
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
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimary,
                                  letterSpacing: 0.15,
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
