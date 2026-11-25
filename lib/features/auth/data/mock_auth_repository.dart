import 'dart:async';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../profile/domain/user_profile.dart';
import '../domain/auth_repository.dart';

/// Implementasi MockAuthRepository berlabel Demo/Simulasi sesuai PRD 2.1 & M2
class MockAuthRepository implements AuthRepository {
  UserProfile? _currentUser;
  final StreamController<UserProfile?> _authStreamController =
      StreamController<UserProfile?>.broadcast();

  // Akun bawaan demo
  static const String demoEmail = 'pengguna.demo@motocare.id';
  static const String demoPassword = 'Password123';

  // Akun mekanik mitra
  static const String mechanicEmail = 'budi.mekanik@motocare.id';

  // Akun administrator
  static const String adminEmail = 'admin@motocare.id';

  MockAuthRepository({bool startAuthenticated = false}) {
    if (startAuthenticated) {
      _currentUser = UserProfile(
        id: 'demo-user-id-001',
        email: demoEmail,
        fullName: 'Abrar Pengguna Demo',
        phone: '081234567890',
        role: 'user',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Stream<UserProfile?> get authStateChanges => _authStreamController.stream;

  @override
  Future<Result<UserProfile>> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final trimmedEmail = email.trim().toLowerCase();

    // 1. Akun Pengguna Biasa / Pelanggan (demo@motocare.id, pengguna.demo@motocare.id, userXX@motocare.id)
    if ((trimmedEmail == demoEmail ||
            trimmedEmail == 'demo@motocare.id' ||
            trimmedEmail.contains('user') ||
            trimmedEmail.contains('pelanggan')) &&
        password == demoPassword) {
      final userName = (trimmedEmail == 'demo@motocare.id' || trimmedEmail == demoEmail)
          ? 'Abrar Pengguna Demo'
          : 'Pelanggan (${trimmedEmail.split('@').first})';
      _currentUser = UserProfile(
        id: 'demo-user-id-${trimmedEmail.hashCode.abs()}',
        email: trimmedEmail,
        fullName: userName,
        phone: '081234567890',
        role: 'user',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime.now(),
      );
      _authStreamController.add(_currentUser);
      return Result.success(_currentUser!);
    }

    // 2. Akun Mekanik Mitra (budi.mekanik@motocare.id atau mekanikXX@motocare.id / 75 kuota mekanik)
    if ((trimmedEmail == mechanicEmail ||
            trimmedEmail.contains('mekanik') ||
            trimmedEmail.contains('mechanic')) &&
        password == demoPassword) {
      final numSuffix = trimmedEmail.replaceAll(RegExp(r'[^0-9]'), '');
      final mechName = trimmedEmail == mechanicEmail
          ? 'Budi Santoso (Mekanik Mitra)'
          : (numSuffix.isNotEmpty ? 'Mekanik Mitra #$numSuffix' : 'Mekanik Mitra (${trimmedEmail.split('@').first})');
      _currentUser = UserProfile(
        id: 'demo-mechanic-id-${trimmedEmail.hashCode.abs()}',
        email: trimmedEmail,
        fullName: mechName,
        phone: '081200000001',
        role: 'mechanic',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime.now(),
      );
      _authStreamController.add(_currentUser);
      return Result.success(_currentUser!);
    }

    // 3. Akun Administrator (admin@motocare.id atau adminXX@motocare.id)
    if ((trimmedEmail == adminEmail || trimmedEmail.contains('admin')) &&
        password == demoPassword) {
      _currentUser = UserProfile(
        id: 'demo-admin-id-${trimmedEmail.hashCode.abs()}',
        email: trimmedEmail,
        fullName: 'Administrator MotoCare',
        phone: '081299999999',
        role: 'admin',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime.now(),
      );
      _authStreamController.add(_currentUser);
      return Result.success(_currentUser!);
    }

    // 4. Akun yang baru didaftarkan lewat form register
    if (_currentUser != null &&
        _currentUser!.email.toLowerCase() == trimmedEmail &&
        password == demoPassword) {
      _authStreamController.add(_currentUser);
      return Result.success(_currentUser!);
    }

    // 5. Fallback akun demo jika email berakhiran @motocare.id
    if (password == demoPassword && trimmedEmail.endsWith('@motocare.id')) {
      _currentUser = UserProfile(
        id: 'mock-user-${trimmedEmail.hashCode.abs()}',
        email: trimmedEmail,
        fullName: 'Pengguna (${trimmedEmail.split('@').first})',
        phone: '081298765432',
        role: 'user',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime.now(),
      );
      _authStreamController.add(_currentUser);
      return Result.success(_currentUser!);
    }

    // Pesan login gagal harus umum dan tidak membocorkan keberadaan email (PRD 13.1)
    return const Result.failure(
      UnauthorizedException('Email atau kata sandi yang Anda masukkan salah.'),
    );
  }

  @override
  Future<Result<UserProfile>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    _currentUser = UserProfile(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim().toLowerCase(),
      fullName: fullName.trim(),
      phone: phone.trim(),
      role: 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _authStreamController.add(_currentUser);
    return Result.success(_currentUser!);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    // Jangan membocorkan apakah email terdaftar (PRD 13.1)
    return const Result.success(null);
  }

  @override
  Future<Result<UserProfile>> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (_currentUser == null) {
      return const Result.failure(
        UnauthorizedException('Sesi Anda telah berakhir. Silakan masuk kembali.'),
      );
    }

    _currentUser = _currentUser!.copyWith(
      fullName: fullName.trim(),
      phone: phone?.trim(),
      updatedAt: DateTime.now(),
    );

    _authStreamController.add(_currentUser);
    return Result.success(_currentUser!);
  }

  @override
  Future<Result<void>> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _currentUser = null;
    _authStreamController.add(null);
    return const Result.success(null);
  }

  @override
  Future<Result<UserProfile?>> getCurrentUser() async {
    return Result.success(_currentUser);
  }

  void dispose() {
    _authStreamController.close();
  }
}
