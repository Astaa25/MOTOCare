import 'package:flutter/material.dart';

/// Design tokens warna MotoCare "Arah Visual Baru" & Figma Official
/// Terinspirasi dari aplikasi delivery/on-demand modern:
/// Coral (#FF7966), Action Red-Coral (#C74635), Deep Teal (#173C3B), Off-White (#FFFCF9).
/// Pastel categoricals: Peach (#FDE8E1), Mint (#E2F1ED), Butter (#FFF4D4).
abstract class AppColors {
  // --- FIGMA OFFICIAL TOKENS (Arah Visual Baru) ---
  /// Coral (#FF7966) - Header atas Beranda & Login top wave
  static const Color coral = Color(0xFFFF7966);
  static const Color headerCoral = Color(0xFFFF7966);

  /// Action (#C74635) - Tombol utama, aksi aktif, aksen darurat
  static const Color action = Color(0xFFC74635);
  static const Color actionPrimary = Color(0xFFC74635);

  /// Deep Teal (#173C3B) - Tipografi utama, kartu gelap Motor Saya & Ruang Montir
  static const Color deepTeal = Color(0xFF173C3B);
  static const Color darkTeal = Color(0xFF173C3B);

  /// Off-white (#FFFCF9) - Background scaffold bersih
  static const Color offWhite = Color(0xFFFFFCF9);

  /// Soft Categorical Tints:
  /// Peach (#FDE8E1) - Hero card "Ada kendala di jalan?", category chips
  static const Color softPeach = Color(0xFFFDE8E1);
  static const Color cardPeach = Color(0xFFFDE8E1);

  /// Mint (#E2F1ED) - Kartu motor utama, badge sukses/terverifikasi
  static const Color softMint = Color(0xFFE2F1ED);
  static const Color cardMint = Color(0xFFE2F1ED);

  /// Butter (#FFF4D4) - Badge riwayat, pengingat, pending tag
  static const Color softButter = Color(0xFFFFF4D4);
  static const Color cardButter = Color(0xFFFFF4D4);

  /// Teal Muted (#657976) - Teks sekunder elegan
  static const Color tealMuted = Color(0xFF657976);

  // --- PALET DASAR ---
  /// Latar dasar: Off-white (#FFFCF9)
  static const Color background = Color(0xFFFFFCF9);
  static const Color creamPaper = Color(0xFFFFFCF9);

  /// Permukaan sekunder / kartu: Putih bersih (#FFFFFF) & Off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFAF6);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFFFF4EA);

  /// Putih hangat untuk panel bersih & plat nomor (#FFFFFF)
  static const Color warmWhite = Color(0xFFFFFFFF);

  /// Sorotan lembut / chip: Peach tint (#FDE8E1)
  static const Color peach = Color(0xFFFDE8E1);
  static const Color peachTint = Color(0xFFFDE8E1);

  /// Mint & Butter aliases
  static const Color mint = Color(0xFFE2F1ED);
  static const Color butter = Color(0xFFFFF4D4);

  /// Border garis & pemisah (#F0EAE1)
  static const Color border = Color(0xFFF0EAE1);
  static const Color navBorder = Color(0xFFF0EAE1);

  // --- AKSI & UTAMA ---
  /// Tombol primer & elemen aktif: Action (#C74635)
  static const Color primary = Color(0xFFC74635);
  static const Color terracotta = Color(0xFFC74635);

  /// Action saat tombol ditekan (#A83627)
  static const Color primaryPressed = Color(0xFFA83627);

  /// Teks aksi (#C74635)
  static const Color primaryText = Color(0xFFC74635);

  /// Label dan ikon di atas primary (#FFFFFF)
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Aksen oranye halus (#FF7966)
  static const Color orangeSoft = Color(0xFFFF7966);

  // --- TEAL & CHARCOAL ---
  /// Deep Teal otomotif & teks tegas (#173C3B)
  static const Color charcoal = Color(0xFF173C3B);
  static const Color charcoalGreen = Color(0xFF173C3B);
  static const Color charcoalDark = Color(0xFF0F2726);
  static const Color deepSlate = Color(0xFF173C3B);

  // --- AKSEN DEKORATIF & AMBER ---
  static const Color headlightAmber = Color(0xFFF4B63F);
  static const Color amber = Color(0xFFF4B63F);

  // --- TIPOGRAFI & TEKS ---
  /// Teks utama: Deep Teal (#173C3B)
  static const Color textPrimary = Color(0xFF173C3B);

  /// Teks sekunder: Teal Muted (#657976)
  static const Color textSecondary = Color(0xFF657976);

  // --- NAVIGASI ---
  static const Color navIndicator = Color(0xFFFDE8E1);
  static const Color navInactive = Color(0xFF8F9E9D);

  // --- STATUS SISTEM ---
  static const Color success = Color(0xFF2E7D5B);
  static const Color error = Color(0xFFC74635);
  static const Color warning = Color(0xFF8A5A00);
  static const Color emerald = Color(0xFF2E7D5B);
  static const Color skyBlue = Color(0xFF1D6F93);

  // --- GRADIEN TERPUSAT ---
  static const LinearGradient darkHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFF173C3B),
      Color(0xFF0F2726),
    ],
  );

  static const LinearGradient heroRescueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFC74635),
      Color(0xFFA83627),
    ],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFFFF7966),
      Color(0xFFFF8B7A),
    ],
  );

  static const LinearGradient vehicleCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF173C3B),
      Color(0xFF133231),
    ],
  );

  static const LinearGradient heroCareGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFFDE8E1),
      Color(0xFFFFEFE9),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFC74635),
      Color(0xFFA83627),
    ],
  );
}
