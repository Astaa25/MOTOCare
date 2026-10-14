import 'request_status.dart';

/// Aturan bisnis dan validasi permintaan bantuan mekanik sesuai PRD Bagian 5.4, 6.6, dan 6.7
class HelpRequestRules {
  const HelpRequestRules._();

  /// Pernyataan batas layanan wajib sesuai PRD 6.6 (503)
  static const String disclaimerText =
      'MotoCare menghubungkan Anda dengan montir terdekat dan tidak menjamin ketersediaan seketika. '
      'MotoCare bukan merupakan layanan darurat medis atau kepolisian.';

  /// Validasi deskripsi masalah: 10 sampai 500 karakter (PRD 5.1 & 6.7)
  static String? validateIssueDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Deskripsi masalah wajib diisi.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 10) {
      return 'Deskripsi masalah minimal 10 karakter (saat ini ${trimmed.length}).';
    }
    if (trimmed.length > 500) {
      return 'Deskripsi masalah maksimal 500 karakter (saat ini ${trimmed.length}).';
    }
    return null;
  }

  /// Validasi alamat atau lokasi: minimal 5 karakter atau GPS tersedia (PRD 6.7)
  static String? validateAddress({
    required String? addressText,
    required double? latitude,
    required double? longitude,
  }) {
    final hasGps = latitude != null && longitude != null;
    final trimmed = addressText?.trim() ?? '';

    if (!hasGps && trimmed.length < 5) {
      return 'Alamat lokasi penjemputan minimal 5 karakter atau aktifkan GPS.';
    }
    return null;
  }

  /// Validasi nomor kontak: format ^\+?[0-9]{8,15}$ (PRD 6.7)
  static String? validateContactPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor kontak telepon wajib diisi.';
    }
    final clean = value.replaceAll(RegExp(r'[\s-]'), '');
    final regex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!regex.hasMatch(clean)) {
      return 'Nomor kontak harus berupa 8 sampai 15 digit angka yang valid.';
    }
    return null;
  }

  /// Memeriksa apakah status saat ini diizinkan untuk dibatalkan pembuat permintaan (PRD 5.4 & 6.6)
  static bool canCancel(RequestStatus status) {
    return status.canCancel;
  }

  /// Memeriksa apakah pembatalan memerlukan dialog konfirmasi peringatan (PRD 6.6: on_the_way)
  static bool requiresCancelWarning(RequestStatus status) {
    return status.requiresCancelWarning;
  }

  /// Memeriksa apakah transisi status sah sesuai RPC advance_request (PRD 5.4)
  static bool isValidStatusAdvance(RequestStatus current, RequestStatus next) {
    switch (current) {
      case RequestStatus.pending:
        return next == RequestStatus.accepted || next == RequestStatus.rejected;
      case RequestStatus.accepted:
        return next == RequestStatus.onTheWay;
      case RequestStatus.onTheWay:
        return next == RequestStatus.inProgress;
      case RequestStatus.inProgress:
        return next == RequestStatus.completed;
      case RequestStatus.rejected:
      case RequestStatus.completed:
      case RequestStatus.cancelled:
      case RequestStatus.expired:
        return false;
    }
  }
}
