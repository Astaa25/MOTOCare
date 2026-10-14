import '../config/app_constants.dart';

/// Hasil validasi kilometer sesuai PRD 6.2
enum MileageValidationResult {
  ok,
  invalid,
  confirmDecrease,
  confirmBigJump,
}

/// Validator input formulir dan aturan bisnis MotoCare sesuai PRD 6.2 & 6.7
abstract class AppValidators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');

  /// Validasi Email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    final trimmed = value.trim();
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Validasi Kata Sandi: minimal 8 karakter, ada huruf dan angka
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi wajib diisi';
    }
    if (value.length < 8) {
      return 'Kata sandi minimal 8 karakter';
    }
    final bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final bool hasDigit = RegExp(r'[0-9]').hasMatch(value);
    if (!hasLetter || !hasDigit) {
      return 'Kata sandi harus mengandung kombinasi huruf dan angka';
    }
    return null;
  }

  /// Validasi Nama Lengkap: 2 sampai 80 karakter
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap wajib diisi';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2 || trimmed.length > 80) {
      return 'Nama lengkap harus antara 2 hingga 80 karakter';
    }
    return null;
  }

  /// Normalisasi nomor telepon: hapus spasi, tanda hubung, kurung
  static String sanitizePhone(String value) {
    return value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  /// Validasi Telepon: 8 sampai 15 digit angka (opsional awalan +)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor telepon wajib diisi';
    }
    final sanitized = sanitizePhone(value.trim());
    if (!_phoneRegex.hasMatch(sanitized)) {
      return 'Nomor telepon harus berupa 8 hingga 15 digit angka';
    }
    return null;
  }

  /// Validasi Merek atau Model: Wajib, maksimal 40 karakter
  static String? validateBrandOrModel(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    final trimmed = value.trim();
    if (trimmed.length > 40) {
      return '$fieldName maksimal 40 karakter';
    }
    return null;
  }

  /// Validasi Tahun Produksi: 1980 sampai tahun berjalan + 1
  static String? validateProductionYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tahun produksi wajib diisi';
    }
    final int? year = int.tryParse(value.trim());
    final int maxYear = DateTime.now().year + 1;
    if (year == null || year < 1980 || year > maxYear) {
      return 'Tahun produksi harus antara 1980 dan $maxYear';
    }
    return null;
  }

  /// Validasi Plat Nomor: Opsional, maksimal 12 karakter
  static String? validateLicensePlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Opsional
    }
    final trimmed = value.trim();
    if (trimmed.length > 12) {
      return 'Plat nomor maksimal 12 karakter';
    }
    return null;
  }

  /// Validasi Tanggal Servis: Tidak boleh di masa depan
  static String? validateServiceDate(DateTime? date) {
    if (date == null) {
      return 'Tanggal servis wajib diisi';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    if (selected.isAfter(today)) {
      return 'Tanggal servis tidak boleh di masa depan';
    }
    return null;
  }

  /// Validasi Biaya: Bilangan bulat Rupiah, minimal 0
  static String? validateCost(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Biaya wajib diisi';
    }
    // Bersihkan karakter selain angka
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    final num? amount = num.tryParse(cleanValue);
    if (amount == null || amount < 0) {
      return 'Biaya servis tidak boleh negatif';
    }
    return null;
  }

  /// Validasi Deskripsi Masalah Bantuan Mekanik: 10 sampai 500 karakter
  static String? validateIssueDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Deskripsi masalah wajib diisi';
    }
    final trimmed = value.trim();
    if (trimmed.length < 10) {
      return 'Jelaskan masalah minimal 10 karakter';
    }
    if (trimmed.length > 500) {
      return 'Deskripsi masalah maksimal 500 karakter';
    }
    return null;
  }

  /// Validasi Alamat / Lokasi Manual: Wajib, minimal 5 karakter
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Alamat penjemputan wajib diisi';
    }
    final trimmed = value.trim();
    if (trimmed.length < 5) {
      return 'Alamat terlalu singkat (minimal 5 karakter)';
    }
    return null;
  }

  /// Validasi Kilometer sesuai tabel PRD bagian 6.2
  static MileageValidationResult validateMileage(int current, String rawInput) {
    final trimmed = rawInput.trim();
    // Hanya angka bulat positif tanpa tanda minus atau desimal
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
      return MileageValidationResult.invalid;
    }

    final int? inputKm = int.tryParse(trimmed);
    if (inputKm == null || inputKm < 0 || inputKm > AppConstants.mileageMax) {
      return MileageValidationResult.invalid;
    }

    if (inputKm < current) {
      return MileageValidationResult.confirmDecrease;
    }

    if (inputKm - current > AppConstants.mileageJumpConfirmKm) {
      return MileageValidationResult.confirmBigJump;
    }

    return MileageValidationResult.ok;
  }
}
