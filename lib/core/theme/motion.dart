import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Konfigurasi gerak terpusat MotoCare (T-01)
/// Menstandarisasi durasi, kurva, dan transition builders di seluruh aplikasi.
/// Menghormati prinsip "ramah aksesibilitas" (reduce-motion) dan performa GPU raster.
abstract class AppMotion {
  // --- DURASI TERSTANDARISASI (T-01) ---
  /// Durasi mikro-interaksi cepat (tombol tekan, chip pilih): 150 ms
  static const Duration shortDuration = Duration(milliseconds: 150);
  static const Duration buttonPress = Duration(milliseconds: 140);

  /// Durasi transisi antar tab (fade-through): 220 ms
  static const Duration tabTransition = Duration(milliseconds: 220);

  /// Durasi standar (modal, bottom sheet, status switch): 250 ms
  static const Duration standardDuration = Duration(milliseconds: 250);
  static const Duration dialog = Duration(milliseconds: 220);

  /// Durasi transisi halaman turunan (shared axis): 300 ms
  static const Duration pageTransition = Duration(milliseconds: 300);

  /// Durasi panjang (animasi masuk kartu awal): 350 ms
  static const Duration longDuration = Duration(milliseconds: 350);
  static const Duration cardEntrance = Duration(milliseconds: 320);

  // Durasi Splash
  static const Duration splashMinDuration = Duration(milliseconds: 3000);
  static const Duration splashMaxDuration = Duration(milliseconds: 5000);

  // Durasi feedback aksi
  static const Duration successFeedback = Duration(milliseconds: 500);
  static const Duration reminderPulse = Duration(milliseconds: 700);

  // --- KURVA ANIMASI TERSTANDARISASI (T-01) ---
  /// Kurva elemen masuk layar (cepat di awal, lembut di akhir)
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve defaultCurve = Curves.easeOutCubic;

  /// Kurva elemen keluar layar
  static const Curve exitCurve = Curves.easeInCubic;

  /// Kurva perpindahan setara / simetris
  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve smoothCurve = Curves.easeInOutCubic;

  /// Kurva snappy (hanya untuk seleksi ikon aktif)
  static const Curve snappyCurve = Curves.easeOutBack;

  /// Memeriksa apakah saat ini berjalan di lingkungan automated test
  static bool get isTestEnvironment {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa apakah animasi dinonaktifkan oleh pengguna (aksesibilitas) atau automated test
  static bool shouldDisableAnimation([BuildContext? context]) {
    if (isTestEnvironment) {
      return true;
    }
    if (context != null) {
      return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    }
    return false;
  }

  /// Mengembalikan durasi yang disesuaikan jika aksesibilitas mematikan animasi
  static Duration getDuration(BuildContext context, Duration standardDuration) {
    if (shouldDisableAnimation(context)) {
      return Duration.zero;
    }
    return standardDuration;
  }

  // --- PAGE TRANSITION BUILDERS TERPUSAT (T-02 & T-03) ---

  /// Transisi Shared Axis Horizontal untuk Layar Turunan (T-03):
  /// - Layar baru masuk dari kanan (~30px offset) sambil memudar masuk (fade in)
  /// - Layar lama bergeser ke kiri dan memudar keluar
  /// - Durasi: 300 ms (easeOutCubic masuk, easeInCubic keluar)
  /// - Menghormati reduce-motion (cross-fade instan)
  static CustomTransitionPage<T> sharedAxisPage<T>({
    required Widget child,
    required LocalKey key,
    String? name,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: child,
      transitionDuration: pageTransition,
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (shouldDisableAnimation(context)) {
          return child;
        }

        // Animasi masuk layar ini (masuk dari kanan ~30px + fade in)
        final slideIn = Tween<Offset>(
          begin: const Offset(0.08, 0.0), // ~30px pada layar mobile 390px
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: enterCurve,
          reverseCurve: exitCurve,
        ));

        final fadeIn = CurvedAnimation(
          parent: animation,
          curve: enterCurve,
          reverseCurve: exitCurve,
        );

        // Animasi keluar saat layar turunan berikutnya menimpa di atasnya
        final slideOut = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.04, 0.0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: exitCurve,
        ));

        final fadeOut = Tween<double>(
          begin: 1.0,
          end: 0.85,
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: exitCurve,
        ));

        return SlideTransition(
          position: slideOut,
          child: FadeTransition(
            opacity: fadeOut,
            child: SlideTransition(
              position: slideIn,
              child: FadeTransition(
                opacity: fadeIn,
                child: RepaintBoundary(child: child),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Transisi Fade-Through untuk Perpindahan Tab Setara (T-02):
  /// - Layar lama memudar keluar
  /// - Layar baru muncul dengan skala 0.98 -> 1.0 + fade in
  /// - Durasi: 220 ms (easeOutCubic)
  /// - Tanpa slide horizontal antar tab setara
  static CustomTransitionPage<T> fadeThroughPage<T>({
    required Widget child,
    required LocalKey key,
    String? name,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: child,
      transitionDuration: tabTransition,
      reverseTransitionDuration: tabTransition,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (shouldDisableAnimation(context)) {
          return child;
        }

        final fadeIn = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.2, 1.0, curve: enterCurve),
        );

        final scaleIn = Tween<double>(begin: 0.98, end: 1.0).animate(CurvedAnimation(
          parent: animation,
          curve: enterCurve,
        ));

        final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.0, 0.4, curve: exitCurve),
        ));

        return FadeTransition(
          opacity: fadeOut,
          child: ScaleTransition(
            scale: scaleIn,
            child: FadeTransition(
              opacity: fadeIn,
              child: RepaintBoundary(child: child),
            ),
          ),
        );
      },
    );
  }

  /// Transisi Naik dari Bawah untuk Modal / Bottom Sheet (T-03):
  /// - Muncul dari bawah 250 ms, tutup lebih cepat (200 ms)
  static CustomTransitionPage<T> modalPage<T>({
    required Widget child,
    required LocalKey key,
    String? name,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: child,
      transitionDuration: standardDuration,
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (shouldDisableAnimation(context)) {
          return child;
        }

        final slideUp = Tween<Offset>(
          begin: const Offset(0.0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: enterCurve,
          reverseCurve: exitCurve,
        ));

        final fadeIn = CurvedAnimation(
          parent: animation,
          curve: enterCurve,
          reverseCurve: exitCurve,
        );

        return SlideTransition(
          position: slideUp,
          child: FadeTransition(
            opacity: fadeIn,
            child: child,
          ),
        );
      },
    );
  }
}
