import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import 'auth_state_provider.dart';

/// Layar Splash Screen MotoCare dengan animasi halus 3-5 detik,
/// inisialisasi paralel, dan penanganan timeout/retry sesuai PRD M0 & TC-25.
class SplashScreen extends ConsumerStatefulWidget {
  /// Opsi override inisialisasi untuk pengujian unit & widget (TC-25)
  final Future<bool> Function()? customInitializer;

  /// Opsi override durasi minimum untuk testing
  final Duration? minDuration;

  /// Opsi override durasi maksimum untuk testing
  final Duration? maxDuration;

  const SplashScreen({
    super.key,
    this.customInitializer,
    this.minDuration,
    this.maxDuration,
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _motorcycleSlideAnimation;

  bool _isInitCompleted = false;
  bool _isMinDurationElapsed = false;
  bool _hasError = false;
  String _statusMessage = 'Menyiapkan MotoCare...';

  Timer? _minTimer;
  Timer? _maxTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _motorcycleSlideAnimation = Tween<double>(begin: -30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();
    _startInitialization();
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    _maxTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startInitialization() {
    setState(() {
      _hasError = false;
      _isInitCompleted = false;
      _isMinDurationElapsed = false;
      _statusMessage = 'Menyiapkan MotoCare...';
    });

    final Duration effectiveMin = widget.minDuration ??
        const Duration(milliseconds: AppConstants.splashMinMs);
    final Duration effectiveMax = widget.maxDuration ??
        const Duration(milliseconds: AppConstants.splashMaxMs);

    // Timer durasi minimal 3 detik (PRD: tidak boleh menunda lebih cepat dari 3 detik)
    _minTimer?.cancel();
    _minTimer = Timer(effectiveMin, () {
      if (mounted) {
        setState(() {
          _isMinDurationElapsed = true;
        });
        _checkAndNavigate();
      }
    });

    // Timer peringatan durasi maksimal 5 detik
    _maxTimer?.cancel();
    _maxTimer = Timer(effectiveMax, () {
      if (mounted && !_isInitCompleted) {
        setState(() {
          _statusMessage = 'Inisialisasi memakan waktu lebih lama dari biasanya...';
        });
      }
    });

    // Eksekusi inisialisasi secara paralel
    _executeInitialization();
  }

  Future<void> _executeInitialization() async {
    try {
      bool success = true;
      if (widget.customInitializer != null) {
        success = await widget.customInitializer!();
      } else {
        // Inisialisasi default aplikasi (simulasi pemulihan sesi & cek mock/supabase)
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        ref.read(authStateProvider.notifier).markInitialized();
      }

      if (!mounted) return;

      if (success) {
        setState(() {
          _isInitCompleted = true;
          _statusMessage = 'Siap!';
        });
        _checkAndNavigate();
      } else {
        setState(() {
          _hasError = true;
          _statusMessage = 'Gagal menginisialisasi aplikasi.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'Terjadi kesalahan saat memuat data.';
        });
      }
    }
  }

  void _checkAndNavigate() {
    if (!mounted) return;

    // Navigasi hanya dilakukan bila durasi minimum selesai DAN inisialisasi selesai
    if (_isMinDurationElapsed && _isInitCompleted && !_hasError) {
      final authState = ref.read(authStateProvider);
      if (authState.isAuthenticated) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnim = AppMotion.shouldDisableAnimation(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFFFF7F0),
              Color(0xFFFFE8D6),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const Spacer(flex: 2),

              // Logo dan ikon animasi motor
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final double scale = disableAnim ? 1.0 : _scaleAnimation.value;
                  final double opacity = disableAnim ? 1.0 : _fadeAnimation.value;
                  final double slideX = disableAnim ? 0.0 : _motorcycleSlideAnimation.value;

                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Lingkaran oranye bercahaya dengan motor
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Transform.translate(
                              offset: Offset(slideX, 0),
                              child: const Icon(
                                Icons.two_wheeler_rounded,
                                size: 68,
                                color: Colors.white,
                                semanticLabel: 'Logo MotoCare Ikon Motor',
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Nama Aplikasi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'MOTO',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                              ),
                              Text(
                                'CARE',
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Slogan
                          Text(
                            'Rawat Motor Anda Tanpa Cemas',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 2),

              // Bagian indikator status dan progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (_hasError) ...<Widget>[
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        key: const Key('splash_retry_button'),
                        onPressed: _startInitialization,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Coba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          minimumSize: const Size(160, 44),
                        ),
                      ),
                    ] else ...<Widget>[
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _statusMessage,
                        key: const Key('splash_status_text'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Badge status demo atau versi di footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.peach, width: 0.8),
                ),
                child: const Text(
                  AppEnv.useMock
                      ? 'Mode: Demo / Simulasi'
                      : 'Koneksi: Supabase Live',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
