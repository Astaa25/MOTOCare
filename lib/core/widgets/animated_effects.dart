import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import 'primary_button.dart';

/// Tombol Darurat "Panggil Montir" dengan Efek Denyut (Pulsing Glow & Scale)
/// Menarik perhatian pengguna dalam kondisi darurat tanpa mengganggu kenyamanan.
class PulsingEmergencyButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  const PulsingEmergencyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.build_circle_rounded,
  });

  @override
  State<PulsingEmergencyButton> createState() => _PulsingEmergencyButtonState();
}

class _PulsingEmergencyButtonState extends State<PulsingEmergencyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    _glowAnimation = Tween<double>(begin: 4.0, end: 14.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    if (!AppMotion.isTestEnvironment) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.shouldDisableAnimation(context)) {
      _pulseController.stop();
    } else if (!_pulseController.isAnimating && !AppMotion.isTestEnvironment) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnim = AppMotion.shouldDisableAnimation(context);

    if (disableAnim) {
      return PrimaryButton(
        label: widget.label,
        icon: widget.icon,
        onPressed: widget.onPressed,
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: _glowAnimation.value,
                  spreadRadius: _glowAnimation.value * 0.2,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: PrimaryButton(
        label: widget.label,
        icon: widget.icon,
        onPressed: widget.onPressed,
      ),
    );
  }
}

/// Widget pembungkus dengan efek hover lift + tactile bouncing saat disentuh (Micro-interaction)
class BouncingWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final double hoverScale;

  const BouncingWidget({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
    this.hoverScale = 1.02,
  });

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null && !AppMotion.isTestEnvironment) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      HapticFeedback.selectionClick();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null || AppMotion.shouldDisableAnimation(context)) {
      return GestureDetector(
        onTap: widget.onTap,
        child: widget.child,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_isHovered) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: AnimatedScale(
        scale: _isHovered ? widget.hoverScale : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Kartu interaktif berkarakter dengan animasi hover elevation, perbatasan coral halus, dan tactile bounce.
class InteractiveHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Color borderColor;
  final Color hoverBorderColor;
  final EdgeInsetsGeometry? padding;

  const InteractiveHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.backgroundColor,
    this.borderColor = AppColors.border,
    this.hoverBorderColor = AppColors.coral,
    this.padding,
  });

  @override
  State<InteractiveHoverCard> createState() => _InteractiveHoverCardState();
}

class _InteractiveHoverCardState extends State<InteractiveHoverCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool interactive = widget.onTap != null;
    final bool disableAnim = AppMotion.shouldDisableAnimation(context);
    final double scale = disableAnim
        ? 1.0
        : (_isPressed && interactive)
            ? 0.98
            : (_isHovered && interactive)
                ? 1.012
                : 1.0;

    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (interactive && !_isHovered) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: Listener(
        onPointerDown: (_) {
          if (interactive) setState(() => _isPressed = true);
        },
        onPointerUp: (_) {
          if (_isPressed) setState(() => _isPressed = false);
        },
        onPointerCancel: (_) {
          if (_isPressed) setState(() => _isPressed = false);
        },
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? AppColors.surfaceBright,
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: (_isHovered && interactive)
                    ? widget.hoverBorderColor.withValues(alpha: 0.75)
                    : widget.borderColor,
                width: (_isHovered && interactive) ? 1.5 : 1.1,
              ),
              boxShadow: (_isHovered && interactive)
                  ? <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF6B3E14).withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: interactive
                    ? () {
                        HapticFeedback.selectionClick();
                        widget.onTap?.call();
                      }
                    : null,
                borderRadius: widget.borderRadius,
                splashColor: AppColors.softPeach.withValues(alpha: 0.6),
                highlightColor: AppColors.cream.withValues(alpha: 0.4),
                child: widget.padding != null
                    ? Padding(padding: widget.padding!, child: widget.child)
                    : widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animasi Kemunculan Bertahap (Staggered Fade & Slide Transition, T-05 B)
/// Stagger 40-50ms per item, dibatasi maksimum 6 item pertama (index 0..5)
class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration duration;
  final double slideOffset;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 45),
    this.duration = const Duration(milliseconds: 260),
    this.slideOffset = 18.0,
  });

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Stagger maksimal 6 item pertama (0..5) agar item di bawah tidak tertunda lama
    final effectiveIndex = widget.index.clamp(0, 5);
    final delay = widget.baseDelay * effectiveIndex;
    if (!AppMotion.isTestEnvironment) {
      Future<void>.delayed(delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.shouldDisableAnimation(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Titik Indikator Status Hidup dengan Animasi Denyut (Pulsing Dot)
class LivePulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const LivePulsingDot({
    super.key,
    required this.color,
    this.size = 10.0,
  });

  @override
  State<LivePulsingDot> createState() => _LivePulsingDotState();
}

class _LivePulsingDotState extends State<LivePulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _animation = Tween<double>(begin: 0.2, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (!AppMotion.isTestEnvironment) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.shouldDisableAnimation(context)) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size + 4,
          height: widget.size + 4,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _animation.value * 0.4),
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

/// Bottom Sheet Interaktif Beri Penilaian & Ulasan (Sesuai UC-03 & Sequence Diagram)
class ReviewRatingBottomSheet extends StatefulWidget {
  final String mechanicName;
  final String workshopName;
  final Future<void> Function(int rating, String comment) onSubmit;

  const ReviewRatingBottomSheet({
    super.key,
    required this.mechanicName,
    required this.workshopName,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required String mechanicName,
    required String workshopName,
    required Future<void> Function(int rating, String comment) onSubmit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReviewRatingBottomSheet(
        mechanicName: mechanicName,
        workshopName: workshopName,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<ReviewRatingBottomSheet> createState() => _ReviewRatingBottomSheetState();
}

class _ReviewRatingBottomSheetState extends State<ReviewRatingBottomSheet> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();
    try {
      await widget.onSubmit(_rating, _commentController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: <Widget>[
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Terima kasih atas ulasan & penilaian Anda! ⭐'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Penilaian Layanan Mekanik',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bagikan pengalaman Anda dengan ${widget.mechanicName} (${widget.workshopName})',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Bar Bintang Interaktif
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isSelected = starValue <= _rating;

              return BouncingWidget(
                scaleFactor: 0.8,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _rating = starValue);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: AnimatedScale(
                    scale: isSelected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 38,
                      color: isSelected ? const Color(0xFFFFB800) : AppColors.border,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _getRatingLabel(_rating),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),

          // Input Ulasan
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tuliskan ulasan atau tanggapan Anda (opsional)...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.cream.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Kirim
          PrimaryButton(
            label: _isSubmitting ? 'Mengirim...' : 'Kirim Penilaian',
            icon: Icons.send_rounded,
            isLoading: _isSubmitting,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 5:
        return 'Sangat Memuaskan! ⭐⭐⭐⭐⭐';
      case 4:
        return 'Pelayanan Baik! ⭐⭐⭐⭐';
      case 3:
        return 'Cukup Baik ⭐⭐⭐';
      case 2:
        return 'Kurang Memuaskan ⭐⭐';
      default:
        return 'Perlu Perbaikan ⭐';
    }
  }
}

/// Kartu Aksi Darurat "Panggil Montir" Bergaya Radar Rescue Beacon (UI-UX Pro-Max)
class EmergencyRescueCard extends StatefulWidget {
  final VoidCallback onTap;

  const EmergencyRescueCard({
    super.key,
    required this.onTap,
  });

  @override
  State<EmergencyRescueCard> createState() => _EmergencyRescueCardState();
}

class _EmergencyRescueCardState extends State<EmergencyRescueCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _radarAnimation = Tween<double>(begin: 0.96, end: 1.03).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    if (!AppMotion.isTestEnvironment) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnim = AppMotion.shouldDisableAnimation(context);

    return BouncingWidget(
      scaleFactor: 0.97,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = disableAnim ? 1.0 : _radarAnimation.value;
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFFF5B26),
                    Color(0xFFEA3A00),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFFFF5B26).withValues(alpha: disableAnim ? 0.25 : 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  // Beacon Radar Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.build_circle_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Keterangan & Call To Action
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'BANTUAN DARURAT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Panggil Montir Sekarang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mekanik siap datang ke lokasi Anda di Lhokseumawe & Aceh Utara',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Panah Aksi
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFEA3A00),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

