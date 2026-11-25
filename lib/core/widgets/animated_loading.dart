import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// Indikator Loading Khas MotoCare dengan animasi rotasi gradien,
/// denyut halo oranye (Warm Coral), dan ikon roda/kunci pas berputar.
class MotoCareLoadingIndicator extends StatefulWidget {
  final double size;
  final String? message;
  final Color? color;
  final bool showIcon;

  const MotoCareLoadingIndicator({
    super.key,
    this.size = 56.0,
    this.message,
    this.color,
    this.showIcon = true,
  });

  /// Factory untuk ukuran kecil (misalnya di dalam tombol atau chip)
  factory MotoCareLoadingIndicator.small({Color? color}) =>
      MotoCareLoadingIndicator(
        size: 22.0,
        color: color ?? Colors.white,
        showIcon: false,
      );

  /// Factory untuk ukuran medium (di dalam kartu atau widget loading)
  factory MotoCareLoadingIndicator.medium({String? message, Color? color}) =>
      MotoCareLoadingIndicator(
        size: 48.0,
        message: message,
        color: color,
        showIcon: true,
      );

  /// Factory untuk ukuran besar (layar penuh)
  factory MotoCareLoadingIndicator.large({String? message, Color? color}) =>
      MotoCareLoadingIndicator(
        size: 72.0,
        message: message,
        color: color,
        showIcon: true,
      );

  @override
  State<MotoCareLoadingIndicator> createState() =>
      _MotoCareLoadingIndicatorState();
}

class _MotoCareLoadingIndicatorState extends State<MotoCareLoadingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    if (!AppMotion.isTestEnvironment) {
      _spinController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.shouldDisableAnimation(context)) {
      _spinController.stop();
      _pulseController.stop();
    } else if (!_spinController.isAnimating && !AppMotion.isTestEnvironment) {
      _spinController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.primary;
    final bool disableAnim = AppMotion.shouldDisableAnimation(context);

    Widget indicator = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Halo glow di belakang
          if (widget.size >= 40 && !disableAnim)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: widget.size * 0.9,
                    height: widget.size * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: effectiveColor.withValues(alpha: 0.25),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Track lingkaran latar belakang (elegan tanpa membuat duplikasi widget CircularProgressIndicator)
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: effectiveColor.withValues(alpha: 0.15),
                width: widget.size < 30 ? 2.5 : 3.5,
              ),
            ),
          ),

          // Busur loading berputar
          if (disableAnim)
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                strokeWidth: widget.size < 30 ? 2.5 : 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
              ),
            )
          else
            RotationTransition(
              turns: _spinController,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _GradientArcPainter(
                    color: effectiveColor,
                    strokeWidth: widget.size < 30 ? 2.5 : 3.5,
                  ),
                ),
              ),
            ),

          // Ikon di tengah (hanya untuk ukuran sedang & besar)
          if (widget.showIcon && widget.size >= 40)
            Icon(
              Icons.two_wheeler_rounded,
              size: widget.size * 0.42,
              color: effectiveColor,
            ),
        ],
      ),
    );

    if (widget.message == null) {
      return indicator;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        indicator,
        const SizedBox(height: 14),
        Text(
          widget.message!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Custom Painter untuk busur lingkar bergradasi halus
class _GradientArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _GradientArcPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final sweepGradient = SweepGradient(
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: <Color>[
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.3),
        color.withValues(alpha: 0.7),
        color,
      ],
      stops: const <double>[0.0, 0.4, 0.75, 1.0],
    );

    final paint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Gambar busur ~ 280 derajat
    canvas.drawArc(rect, 0, math.pi * 1.55, false, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientArcPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Layar Loading Penuh MotoCare dengan latar belakang elegan dan tips ramah
class MotoCareLoadingScreen extends StatelessWidget {
  final String title;
  final String? subtitle;

  const MotoCareLoadingScreen({
    super.key,
    this.title = 'Memuat Data MotoCare...',
    this.subtitle = 'Menghubungkan ke layanan Lhokseumawe & Aceh Utara',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MotoCareLoadingIndicator.large(),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper Dialog Loading Animasi MotoCare
abstract class MotoCareLoadingDialog {
  static void show(
    BuildContext context, {
    String message = 'Mohon tunggu sebentar...',
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                MotoCareLoadingIndicator.medium(),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

