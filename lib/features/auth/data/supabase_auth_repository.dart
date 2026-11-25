import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../profile/domain/user_profile.dart';
import '../domain/auth_repository.dart';

/// Implementasi SupabaseAuthRepository dengan client Supabase resmi sesuai PRD 2.1 & M2
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  @override
  Stream<UserProfile?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user == null) return null;
      final profileResult = await _fetchProfile(user.id, user.email);
      return profileResult.dataOrNull;
    });
  }

  Future<Result<UserProfile>> _fetchProfile(String userId, String? email) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return const Result.failure(NotFoundException('Profil tidak ditemukan.'));
      }

      final profile = UserProfile.fromJson(response, email: email);
      return Result.success(profile);
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<UserProfile>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        return const Result.failure(
          UnauthorizedException('Email atau kata sandi yang Anda masukkan salah.'),
        );
      }

      return await _fetchProfile(user.id, user.email);
    } on AuthException catch (_) {
      // Pesan login gagal harus umum agar tidak mengungkap keberadaan akun (PRD 13.1)
      return const Result.failure(
        UnauthorizedException('Email atau kata sandi yang Anda masukkan salah.'),
      );
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<UserProfile>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      final authResponse = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{
          'full_name': fullName.trim(),
          'phone': phone.trim(),
        },
      );

      final user = authResponse.user;
      if (user == null) {
        return const Result.failure(ServerException('Gagal membuat akun pengguna.'));
      }

      // Update profil nomor telepon jika diperlukan (dukung kolom phone_number & phone)
      if (phone.isNotEmpty) {
        try {
          await _client.from('profiles').update(<String, dynamic>{
            'phone_number': phone.trim(),
          }).eq('id', user.id);
        } catch (_) {
          await _client.from('profiles').update(<String, dynamic>{
            'phone': phone.trim(),
          }).eq('id', user.id);
        }
      }

      return await _fetchProfile(user.id, user.email);
    } on AuthException catch (e) {
      return Result.failure(ValidationException(e.message));
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
      );
      return const Result.success(null);
    } catch (_) {
      // Selalu kembalikan respon sukses umum agar tidak mengungkap email (PRD 13.1)
      return const Result.success(null);
    }
  }

  @override
  Future<Result<UserProfile>> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const Result.failure(
          UnauthorizedException('Sesi Anda telah berakhir. Silakan masuk kembali.'),
        );
      }

      try {
        await _client.from('profiles').update(<String, dynamic>{
          'full_name': fullName.trim(),
          if (phone != null) 'phone_number': phone.trim(),
        }).eq('id', user.id);
      } catch (_) {
        await _client.from('profiles').update(<String, dynamic>{
          'full_name': fullName.trim(),
          if (phone != null) 'phone': phone.trim(),
        }).eq('id', user.id);
      }

      return await _fetchProfile(user.id, user.email);
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<UserProfile?>> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return const Result.success(null);
      final profileResult = await _fetchProfile(user.id, user.email);
      return Result.success(profileResult.dataOrNull);
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }
}
