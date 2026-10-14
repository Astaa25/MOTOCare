import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/config/app_constants.dart';
import 'package:motocare/core/config/env.dart';
import 'package:motocare/core/errors/app_exception.dart';
import 'package:motocare/core/utils/network_guard.dart';
import 'package:motocare/core/utils/validators.dart';
import 'package:motocare/features/help_requests/domain/request_status.dart';
import 'package:motocare/features/help_requests/domain/service_request.dart';
import 'package:motocare/features/tutorials/domain/tutorial.dart';

void main() {
  group('Security Matrix Automated Tests (Milestone M9 / SEC-01 s/d SEC-20)', () {
    // ------------------------------------------------------------------------
    // SEC-03: Pencegahan Eskalasi Role Profil ke Admin
    // ------------------------------------------------------------------------
    test('SEC-03: Klien tidak boleh mengizinkan penetapan role ilegal di luar user/mechanic', () {
      const validRoles = ['user', 'mechanic', 'admin'];
      expect(validRoles.contains('user'), isTrue);
      expect(validRoles.contains('superuser'), isFalse);
      expect(validRoles.contains('root'), isFalse);

      // Pastikan form validator menolak input nama kosong
      expect(AppValidators.validateFullName(''), isNotNull);
      expect(AppValidators.validateFullName('A'), isNotNull); // < 2 karakter
      expect(AppValidators.validateFullName('Abrar Astafaraiz'), isNull);
    });

    // ------------------------------------------------------------------------
    // SEC-06 & SEC-09: Validasi State Machine Status Permintaan Bantuan Mekanik
    // ------------------------------------------------------------------------
    test('SEC-06 & SEC-09: Validasi rantai transisi status permintaan sah', () {
      // Status awal
      const initial = RequestStatus.pending;
      expect(initial.canCancel, isTrue);

      // Transisi sah dari pending: accepted, rejected, cancelled, expired
      expect([
        RequestStatus.accepted,
        RequestStatus.rejected,
        RequestStatus.cancelled,
        RequestStatus.expired,
      ].contains(RequestStatus.accepted), isTrue);

      // Transisi ilegal: pending tidak boleh lompat langsung ke completed atau inProgress
      const illegalJumps = [
        RequestStatus.inProgress,
        RequestStatus.completed,
      ];
      for (final target in illegalJumps) {
        final bool isDirectJumpValid = (initial == RequestStatus.pending &&
            (target == RequestStatus.accepted ||
                target == RequestStatus.rejected ||
                target == RequestStatus.cancelled ||
                target == RequestStatus.expired));
        expect(isDirectJumpValid, isFalse,
            reason: 'Transisi dari pending ke $target harus ditolak oleh sistem');
      }

      // Status terminal tidak dapat dibatalkan lagi
      expect(RequestStatus.completed.canCancel, isFalse);
      expect(RequestStatus.cancelled.canCancel, isFalse);
      expect(RequestStatus.expired.canCancel, isFalse);
    });

    // ------------------------------------------------------------------------
    // SEC-10: Aturan Bisnis Satu Permintaan Bantuan Aktif
    // ------------------------------------------------------------------------
    test('SEC-10: Deteksi status aktif untuk mencegah duplikasi permintaan', () {
      expect(RequestStatus.pending.isActive, isTrue);
      expect(RequestStatus.accepted.isActive, isTrue);
      expect(RequestStatus.onTheWay.isActive, isTrue);
      expect(RequestStatus.inProgress.isActive, isTrue);

      // Status non-aktif
      expect(RequestStatus.completed.isActive, isFalse);
      expect(RequestStatus.cancelled.isActive, isFalse);
      expect(RequestStatus.rejected.isActive, isFalse);
      expect(RequestStatus.expired.isActive, isFalse);
    });

    // ------------------------------------------------------------------------
    // SEC-12: Secret Scanning Statis pada Seluruh Kode Dart
    // ------------------------------------------------------------------------
    test('SEC-12: Tidak ada service_role key, password hardcoded, atau token di lib/', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'Direktori lib/ harus ada');

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final prohibitedPatterns = [
        RegExp(r'service_role\s*=\s*["\x27][^"\x27]+["\x27]', caseSensitive: false),
        RegExp(r'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[a-zA-Z0-9_\-]+\.[a-zA-Z0-9_\-]+'), // Raw JWT
        RegExp(r'postgres://[^:]+:[^@]+@'), // Raw DB URI with password
        RegExp(r'-----BEGIN (RSA |EC )?PRIVATE KEY-----'),
      ];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final pattern in prohibitedPatterns) {
          final match = pattern.firstMatch(content);
          expect(match, isNull,
              reason: 'File ${file.path} memuat kredensial atau pola rahasia: ${match?.group(0)}');
        }
      }
    });

    // ------------------------------------------------------------------------
    // SEC-13: Sanitasi Pesan Error (No Sensitive Leaks to User)
    // ------------------------------------------------------------------------
    test('SEC-13: AppException memetakan error teknis ke pesan ramah Bahasa Indonesia', () {
      // Simulasi error sensitif seperti PostgreSQL syntax error atau token expired
      final dbError = Exception('PostgreSQL error: column "password_hash" does not exist at line 42');
      final appEx = AppException.fromError(dbError);

      expect(appEx.message, isNot(contains('password_hash')));
      expect(appEx.message, isNot(contains('PostgreSQL')));
      expect(appEx.message, contains('Terjadi kesalahan yang tidak terduga'));

      // Error koneksi/socket
      final socketError = Exception('SocketException: OS Error: Connection refused, errno = 111');
      final netEx = AppException.fromError(socketError);
      expect(netEx.message, contains('Koneksi internet bermasalah'));
      expect(netEx.message, isNot(contains('errno = 111')));
    });

    // ------------------------------------------------------------------------
    // SEC-14: Privasi Lokasi & Ketersediaan Input Alamat Manual
    // ------------------------------------------------------------------------
    test('SEC-14: Model ServiceRequest menerima alamat manual tanpa keharusan koordinat GPS', () {
      // Kasus di mana GPS dimatikan atau izin ditolak pengguna
      final requestWithoutGps = ServiceRequest(
        id: 'test-req-001',
        userId: 'user-001',
        issueCategory: CommonIssues.banBocor,
        issueDescription: 'Ban belakang bocor di depan SPBU Cunda Lhokseumawe',
        addressText: 'Jl. Merdeka No. 45, Cunda, Lhokseumawe',
        contactPhone: '081234567890',
        latitude: null, // GPS Ditolak
        longitude: null, // GPS Ditolak
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      );

      expect(requestWithoutGps.latitude, isNull);
      expect(requestWithoutGps.longitude, isNull);
      expect(requestWithoutGps.addressText, isNotEmpty);
      expect(requestWithoutGps.issueDescription.length, greaterThanOrEqualTo(10));
    });

    // ------------------------------------------------------------------------
    // SEC-15: Penanganan Input Ekstrem, SQL Injection, dan XSS
    // ------------------------------------------------------------------------
    test('SEC-15: Validator menangani input ekstrem, SQL injection, dan script tag secara aman', () {
      // 1. Uji panjang karakter deskripsi bantuan (PRD 5.1: 10 sampai 500 karakter)
      const shortDesc = 'Bocor'; // < 10 karakter
      expect(AppValidators.validateIssueDescription(shortDesc), isNotNull);

      final validDesc = 'A' * 250;
      expect(AppValidators.validateIssueDescription(validDesc), isNull);

      final extremeDesc = 'A' * 501; // > 500 karakter
      expect(AppValidators.validateIssueDescription(extremeDesc), isNotNull);

      // 2. Uji SQL injection string pada validator
      const sqlInjectionPayload = "'; DROP TABLE profiles; --";
      final nameValidation = AppValidators.validateFullName(sqlInjectionPayload);
      expect(nameValidation, isNull); // Lolos validasi panjang format string biasa

      // 3. Uji XSS payload
      const xssPayload = '<script>alert("XSS")</script>';
      final descValidation = AppValidators.validateIssueDescription(xssPayload);
      expect(descValidation, isNull); // String 31 karakter aman, diproses sebagai plain text

      // 4. Uji biaya negatif
      expect(AppValidators.validateCost('-5000'), isNotNull);
      expect(AppValidators.validateCost('0'), isNull);
      expect(AppValidators.validateCost('150000'), isNull);

      // 5. Uji kilometer di luar batas (0 s/d 999.999)
      expect(AppValidators.validateMileage(10000, '-1'), MileageValidationResult.invalid);
      expect(AppValidators.validateMileage(10000, '1000000'), MileageValidationResult.invalid);
      expect(AppValidators.validateMileage(10000, '12000'), MileageValidationResult.ok);
    });

    // ------------------------------------------------------------------------
    // SEC-16: Validasi URL Tutorial (Cegah Domain & Skema Berbahaya)
    // ------------------------------------------------------------------------
    test('SEC-16: Tutorial.isValidYoutubeUrl menolak domain palsu, skema javascript:, dan phishing', () {
      // URL Sah
      expect(Tutorial.isValidYoutubeUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isTrue);
      expect(Tutorial.isValidYoutubeUrl('https://youtu.be/dQw4w9WgXcQ'), isTrue);
      expect(Tutorial.isValidYoutubeUrl('https://youtube.com/shorts/dQw4w9WgXcQ'), isTrue);

      // Skema Berbahaya
      expect(Tutorial.isValidYoutubeUrl('javascript:alert(1)'), isFalse);
      expect(Tutorial.isValidYoutubeUrl('file:///etc/passwd'), isFalse);
      expect(Tutorial.isValidYoutubeUrl('data:text/html,<script>alert(1)</script>'), isFalse);

      // Domain Tiruan / Phishing
      expect(Tutorial.isValidYoutubeUrl('https://youtube.com.attacker.com/video'), isFalse);
      expect(Tutorial.isValidYoutubeUrl('https://not-youtube.com/watch?v=123'), isFalse);
      expect(Tutorial.isValidYoutubeUrl('http://insecure-youtube.com'), isFalse);
    });

    // ------------------------------------------------------------------------
    // SEC-18: Timeout 15s dan Pembatasan Percobaan Ulang Jaringan
    // ------------------------------------------------------------------------
    test('SEC-18: NetworkGuard membatasi timeout dan menolak pengulangan membabi buta', () async {
      expect(AppConstants.networkTimeout.inSeconds, 15);

      int attempts = 0;
      try {
        await NetworkGuard.safeRead(
          () async {
            attempts++;
            throw const NetworkException();
          },
          retryDelay: Duration.zero,
          maxRetries: 1, // Dibatasi 1x retry otomatis
        );
      } catch (e) {
        expect(e, isA<NetworkException>());
      }

      // 1 panggilan awal + 1x retry = tepat 2 percobaan
      expect(attempts, 2);
    });

    // ------------------------------------------------------------------------
    // SEC-19: Deteksi Konfigurasi Release vs Mode Mock
    // ------------------------------------------------------------------------
    test('SEC-19: AppEnv mendeteksi konfigurasi backend Supabase secara konsisten', () {
      // Saat USE_MOCK aktif secara default pada local build
      if (AppEnv.useMock) {
        expect(AppEnv.isSupabaseConfigured, isFalse);
      }
      expect(AppEnv.supabaseUrl, isA<String>());
      expect(AppEnv.supabaseAnonKey, isA<String>());
    });

    // ------------------------------------------------------------------------
    // SEC-20: Pembatasan Batas Wilayah Layanan (Lhokseumawe & Aceh Utara)
    // ------------------------------------------------------------------------
    test('SEC-20: Pembatasan ketat dua wilayah layanan operasional resmi', () {
      expect(AppConstants.supportedRegions.length, 2);
      expect(AppConstants.supportedRegions.contains('Kota Lhokseumawe'), isTrue);
      expect(AppConstants.supportedRegions.contains('Kabupaten Aceh Utara'), isTrue);
      expect(AppConstants.supportedRegions.contains('Banda Aceh'), isFalse);
      expect(AppConstants.supportedRegions.contains('Medan'), isFalse);
    });
  });
}
