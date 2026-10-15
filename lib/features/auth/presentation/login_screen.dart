import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'auth_state_provider.dart';

/// Layar Masuk MotoCare sesuai PRD M2 & Kebijakan Keamanan 13.1
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Logo dan Judul
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.two_wheeler_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Masuk ke MotoCare',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kelola perawatan motor Anda dengan mudah dan tepat waktu.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Banner error jika login gagal
                  if (authState.errorMessage != null) ...<Widget>[
                    Container(
                      key: const Key('login_error_banner'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form Fields
                  AppTextField(
                    key: const Key('login_email_field'),
                    controller: _emailController,
                    label: 'Alamat Email',
                    hint: 'nama@domain.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: AppValidators.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    key: const Key('login_password_field'),
                    controller: _passwordController,
                    label: 'Kata Sandi',
                    hint: 'Masukkan kata sandi',
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.lock_outline_rounded,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Kata sandi wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Lupa Kata Sandi
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('login_forgot_password_button'),
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text(
                        'Lupa Kata Sandi?',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tombol Masuk
                  PrimaryButton(
                    key: const Key('login_submit_button'),
                    label: 'Masuk',
                    isLoading: authState.isLoading,
                    onPressed: _handleLogin,
                  ),

                  const SizedBox(height: 24),

                  // Tautan Daftar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Belum memiliki akun? ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      GestureDetector(
                        key: const Key('login_register_link'),
                        onTap: () => context.push('/register'),
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
