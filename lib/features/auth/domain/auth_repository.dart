import '../../../core/utils/result.dart';
import '../../profile/domain/user_profile.dart';

/// Kontrak repository autentikasi MotoCare sesuai PRD 2.1 & M2
abstract class AuthRepository {
  /// Masuk dengan email dan kata sandi
  Future<Result<UserProfile>> signIn({
    required String email,
    required String password,
  });

  /// Pendaftaran akun baru
  Future<Result<UserProfile>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  });

  /// Kirim tautan reset kata sandi
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Pembaruan profil nama dan telepon milik sendiri
  Future<Result<UserProfile>> updateProfile({
    required String fullName,
    String? phone,
  });

  /// Keluar dari sesi
  Future<Result<void>> signOut();

  /// Mengambil data profil pengguna yang sedang aktif
  Future<Result<UserProfile?>> getCurrentUser();

  /// Stream perubahan status autentikasi
  Stream<UserProfile?> get authStateChanges;
}
