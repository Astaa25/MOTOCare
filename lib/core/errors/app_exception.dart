/// Kategori dan hierarki exception aplikasi MotoCare sesuai PRD 3.1 & M1
/// Menyediakan pesan ramah dalam Bahasa Indonesia tanpa membocorkan detail teknis internal.
sealed class AppException implements Exception {
  final String message;
  final dynamic cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() => message;

  /// Memetakan error umum atau dinamis ke AppException dengan pesan ramah
  factory AppException.fromError(dynamic error) {
    if (error is AppException) return error;

    final String errStr = error.toString().toLowerCase();
    if (errStr.contains('socket') ||
        errStr.contains('connection') ||
        errStr.contains('timeout') ||
        errStr.contains('network') ||
        errStr.contains('offline')) {
      return const NetworkException();
    }
    if (errStr.contains('unauthorized') ||
        errStr.contains('jwt') ||
        errStr.contains('auth')) {
      return const UnauthorizedException();
    }
    if (errStr.contains('not found') || errStr.contains('404')) {
      return const NotFoundException();
    }
    if (errStr.contains('permission') || errStr.contains('denied')) {
      return const PermissionException();
    }

    return const UnknownException();
  }
}

/// Kesalahan koneksi jaringan atau timeout
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Koneksi internet bermasalah. Periksa koneksi Anda dan coba lagi.',
    super.cause,
  ]);
}

/// Sesi kedaluwarsa atau tidak berizin
class UnauthorizedException extends AppException {
  const UnauthorizedException([
    super.message = 'Sesi Anda telah berakhir. Silakan masuk kembali.',
    super.cause,
  ]);
}

/// Data yang diminta tidak ditemukan
class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'Data yang dicari tidak ditemukan.',
    super.cause,
  ]);
}

/// Izin sistem ditolak (lokasi, notifikasi, dll)
class PermissionException extends AppException {
  const PermissionException([
    super.message = 'Izin akses diperlukan untuk menjalankan fitur ini.',
    super.cause,
  ]);
}

/// Validasi input bisnis gagal
class ValidationException extends AppException {
  const ValidationException([
    super.message = 'Data yang dimasukkan tidak valid.',
    super.cause,
  ]);
}

/// Kesalahan server atau RPC database
class ServerException extends AppException {
  const ServerException([
    super.message = 'Terjadi kendala pada server. Mohon tunggu beberapa saat.',
    super.cause,
  ]);
}

/// Kesalahan yang tidak teridentifikasi
class UnknownException extends AppException {
  const UnknownException([
    super.message = 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.',
    super.cause,
  ]);
}
