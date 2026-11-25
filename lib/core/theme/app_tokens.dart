import 'package:flutter/material.dart';

/// Design tokens terpusat MotoCare (Radius, Bayangan Hangat, Spacing, Navigasi)
/// Sesuai PRD V-01 dan V-05
abstract class AppTokens {
  // Radius konsisten
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusNav = 28.0;
  static const double radiusFull = 999.0;

  // BorderRadius helpers
  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusNav = BorderRadius.circular(radiusNav);
  static final BorderRadius borderRadiusFull = BorderRadius.circular(radiusFull);

  // Spacing
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;

  // Tinggi tombol & interaksi standar
  static const double buttonHeight = 52.0;
  static const double minTouchTarget = 48.0;

  // Dimensi Navigasi Melayang (Floating Bottom Nav)
  static const double navHeight = 64.0;
  static const double navMarginHorizontal = 16.0;
  static const double navMarginBottom = 12.0;
  /// Padding bawah aman untuk seluruh daftar/layar tab agar konten terbawah tidak tertutup nav
  static const double tabContentBottomPadding = 96.0;
}

/// Token bayangan hangat (Warm Shadows) MotoCare
/// Menghindari bayangan hitam pekat dengan memberi rona oranye/amber transparan
abstract class AppShadows {
  /// Tingkat rendah: untuk kartu konten, list tile, dan banner
  static final List<BoxShadow> low = <BoxShadow>[
    BoxShadow(
      color: const Color(0xFF6B3E14).withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Tingkat tinggi: untuk floating bottom nav, modal popup, dan hero button
  static final List<BoxShadow> high = <BoxShadow>[
    BoxShadow(
      color: const Color(0xFF6B2D08).withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: const Color(0xFF6B3E14).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Halus: untuk status badge atau kartu sekunder
  static final List<BoxShadow> subtle = <BoxShadow>[
    BoxShadow(
      color: const Color(0xFF452207).withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

