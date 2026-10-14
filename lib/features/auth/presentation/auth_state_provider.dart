import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State autentikasi sederhana untuk M0 (akan disempurnakan di M2 dengan Supabase/Mock repo)
class AuthState {
  final bool isAuthenticated;
  final bool isInitialized;
  final String? userId;
  final String? userEmail;

  const AuthState({
    this.isAuthenticated = false,
    this.isInitialized = false,
    this.userId,
    this.userEmail,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isInitialized,
    String? userId,
    String? userEmail,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInitialized: isInitialized ?? this.isInitialized,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  void setAuthenticated({required String userId, required String email}) {
    state = state.copyWith(
      isAuthenticated: true,
      userId: userId,
      userEmail: email,
    );
  }

  void setUnauthenticated() {
    state = const AuthState(
      isAuthenticated: false,
      isInitialized: true,
    );
  }

  void markInitialized() {
    state = state.copyWith(isInitialized: true);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
