import 'dart:async';
import '../config/app_constants.dart';
import '../errors/app_exception.dart';

/// Utilitas penanganan pembacaan data aman dengan batas waktu timeout (15 detik)
/// dan satu kali retry otomatis sesuai spesifikasi PRD Milestone M8 (Tugas 1 & TC-14, TC-15).
class NetworkGuard {
  const NetworkGuard._();

  /// Menjalankan permintaan pembacaan data secara aman.
  /// - Membatasi waktu eksekusi dengan [timeout] (default: 15 detik).
  /// - Melakukan pengulangan otomatis ([maxRetries], default: 1x) jika terjadi timeout atau gangguan jaringan.
  /// - Menangkap kegagalan dan memetakannya menjadi [AppException] dengan pesan ramah berbahasa Indonesia.
  static Future<T> safeRead<T>(
    Future<T> Function() action, {
    Duration timeout = AppConstants.networkTimeout,
    int maxRetries = 1,
    Duration retryDelay = const Duration(milliseconds: 250),
  }) async {
    int attempt = 0;

    while (true) {
      attempt++;
      try {
        return await action().timeout(timeout);
      } catch (e) {
        final bool isNetworkIssue = e is TimeoutException ||
            e is NetworkException ||
            e.toString().toLowerCase().contains('socket') ||
            e.toString().toLowerCase().contains('timeout') ||
            e.toString().toLowerCase().contains('connection') ||
            e.toString().toLowerCase().contains('network') ||
            e.toString().toLowerCase().contains('offline');

        if (attempt <= maxRetries && isNetworkIssue) {
          // Jeda singkat sebelum retry otomatis
          if (retryDelay > Duration.zero) {
            await Future<void>.delayed(retryDelay);
          }
          continue;
        }

        throw AppException.fromError(e);
      }
    }
  }
}
