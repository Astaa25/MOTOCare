import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/env.dart';
import '../../profile/domain/user_profile.dart';
import '../data/mock_auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';

/// Provider repository autentikasi berdasarkan konfigurasi environment
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppEnv.isSupabaseConfigured) {
    return SupabaseAuthRepository();
  }
  return MockAuthRepository();
});

/// State autentikasi MotoCare
class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final bool isInitialized;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;
  String? get userId => user?.id;
  String? get userEmail => user?.email;

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    bool? isInitialized,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier pengelola autentikasi dan profil pengguna
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _initSession();
  }

  Future<void> _initSession() async {
    final result = await _repository.getCurrentUser();
    result.when(
      onSuccess: (user) {
        state = state.copyWith(user: user, isInitialized: true);
      },
      onFailure: (_) {
        state = state.copyWith(isInitialized: true);
      },
    );
  }

  /// Masuk dengan email dan kata sandi
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.signIn(email: email, password: password);

    return result.when(
      onSuccess: (user) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      },
      onFailure: (err) {
        state = state.copyWith(
          errorMessage: err.message,
          isLoading: false,
        );
        return false;
      },
    );
  }

  /// Pendaftaran pengguna baru
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    return result.when(
      onSuccess: (user) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      },
      onFailure: (err) {
        state = state.copyWith(
          errorMessage: err.message,
          isLoading: false,
        );
        return false;
      },
    );
  }

  /// Kirim tautan reset kata sandi
  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.sendPasswordResetEmail(email);

    return result.when(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
      onFailure: (err) {
        state = state.copyWith(errorMessage: err.message, isLoading: false);
        return false;
      },
    );
  }

  /// Pembaruan profil (Nama & Telepon)
  Future<bool> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.updateProfile(
      fullName: fullName,
      phone: phone,
    );

    return result.when(
      onSuccess: (updated) {
        state = state.copyWith(user: updated, isLoading: false);
        return true;
      },
      onFailure: (err) {
        state = state.copyWith(errorMessage: err.message, isLoading: false);
        return false;
      },
    );
  }

  /// Keluar dari sesi
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _repository.signOut();
    state = const AuthState(isInitialized: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void markInitialized() {
    state = state.copyWith(isInitialized: true);
  }

  /// Helper untuk mock/test
  void setAuthenticated({required String userId, required String email}) {
    state = state.copyWith(
      user: UserProfile(
        id: userId,
        email: email,
        fullName: 'Pengguna Demo',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      isInitialized: true,
    );
  }

  void setUnauthenticated() {
    state = const AuthState(isInitialized: true);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Provider pengguna saat ini (UserProfile?)
final currentUserProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authStateProvider).user;
});
