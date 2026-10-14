import 'package:flutter/material.dart';

/// Design tokens warna MotoCare sesuai PRD bagian 4.1
/// Kontras telah dihitung untuk memenuhi standar WCAG (minimal 4.5:1 untuk teks normal).
abstract class AppColors {
  /// Latar layar
  static const Color background = Color(0xFFFFFFFF);

  /// Panel lembut
  static const Color cream = Color(0xFFFFF0E3);

  /// Kartu dan sorotan
  static const Color peach = Color(0xFFFFD0A6);

  /// Aksen dan gradasi
  static const Color orangeSoft = Color(0xFFFF9B54);

  /// Isi tombol utama, elemen aktif, ikon aktif
  static const Color primary = Color(0xFFF47721);

  /// Label dan ikon di atas primary (~5.9:1 kontras)
  static const Color onPrimary = Color(0xFF1F1F1F);

  /// Teks atau tautan oranye di atas putih (~5.3:1 kontras)
  static const Color primaryText = Color(0xFFB34D00);

  /// Teks utama (~11.6:1 kontras di atas putih)
  static const Color textPrimary = Color(0xFF343434);

  /// Teks sekunder (~5.8:1 kontras di atas putih)
  static const Color textSecondary = Color(0xFF6C625B);

  /// Status sukses (~5.1:1 kontras)
  static const Color success = Color(0xFF1B7F3B);

  /// Error dan servis terlambat (~5.6:1 kontras)
  static const Color error = Color(0xFFC62828);

  /// Status mendekati jatuh tempo (~6.2:1 kontras)
  static const Color warning = Color(0xFF8A5A00);

  /// Border kartu dan input
  static const Color border = Color(0xFFF0E3D6);

  /// Background surface kartu abu-abu netral tipis
  static const Color surfaceLight = Color(0xFFFAFAFA);

  /// Gradasi header: #FFF7F0, #FFE2C7, #FFB875 (atas ke bawah)
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFFFFF7F0),
      Color(0xFFFFE2C7),
      Color(0xFFFFB875),
    ],
  );

  /// Gradasi aksen tombol atau badge
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFFF9B54),
      Color(0xFFF47721),
    ],
  );
}
