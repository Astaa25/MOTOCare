import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/env.dart';

/// Pengendali ketersediaan fitur Google Maps dan fallback terpadu
class MapsFeatureGuard {
  const MapsFeatureGuard._();

  /// Periksa apakah Google Maps SDK aktif dan didukung pada lingkungan saat ini
  static bool get isMapsSdkEnabled {
    if (!AppEnv.mapsEnabled) return false;
    // Maps SDK saat ini difokuskan pada mobile (Android/iOS)
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Buka pencarian bengkel/tempat di Google Maps eksternal via url_launcher
  /// Fallback elegan jika peta internal dinonaktifkan atau terjadi error koneksi
  static Future<bool> openExternalMapSearch({
    required String query,
    double? latitude,
    double? longitude,
  }) async {
    Uri uri;
    if (latitude != null && longitude != null) {
      // Menggunakan geo scheme untuk Android Maps
      uri = Uri.parse('geo:$latitude,$longitude?q=${Uri.encodeComponent(query)}');
    } else {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    }

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      // Fallback ke browser web jika geo intent tidak didukung
      final Uri webUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
      );
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Buka petunjuk arah navigasi ke titik tujuan tertentu
  static Future<bool> openExternalDirections({
    required double destinationLat,
    required double destinationLng,
    String? destinationLabel,
  }) async {
    final String label = destinationLabel != null ? '(${Uri.encodeComponent(destinationLabel)})' : '';
    final Uri geoUri = Uri.parse('google.navigation:q=$destinationLat,$destinationLng$label');
    final Uri webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng',
    );

    try {
      if (await canLaunchUrl(geoUri)) {
        return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Buka panggilan telepon darurat / bengkel
  static Future<bool> dialPhoneNumber(String rawPhoneNumber) async {
    final String sanitized = rawPhoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (sanitized.isEmpty) return false;

    final Uri phoneUri = Uri.parse('tel:$sanitized');
    try {
      if (await canLaunchUrl(phoneUri)) {
        return await launchUrl(phoneUri);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Buka tautan YouTube dengan fallback browser
  static Future<bool> openYouTubeUrl(String videoUrl) async {
    if (videoUrl.isEmpty) return false;
    final Uri uri = Uri.parse(videoUrl);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

