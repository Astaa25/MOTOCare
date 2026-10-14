import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Konstanta durasi dan kurva animasi MotoCare sesuai PRD bagian 4.5
abstract class AppMotion {
  // Durasi Splash
  static const Duration splashMinDuration = Duration(milliseconds: 3000);
  static const Duration splashMaxDuration = Duration(milliseconds: 5000);

  // Micro-interactions
  static const Duration buttonPress = Duration(milliseconds: 140);
  static const Duration cardEntrance = Duration(milliseconds: 320);
  static const Duration dialog = Duration(milliseconds: 220);
  static const Duration successFeedback = Duration(milliseconds: 600);
  static const Duration reminderPulse = Duration(milliseconds: 700);

  // Kurva animasi
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve snappyCurve = Curves.easeOutBack;
  static const Curve smoothCurve = Curves.easeInOutCubic;

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
}
