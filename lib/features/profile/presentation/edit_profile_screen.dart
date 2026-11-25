import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_state_provider.dart';

/// Layar Ubah Profil Pengguna MotoCare sesuai PRD M2
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authStateProvider.notifier).updateProfile(
          fullName: _nameController.text,
          phone: _phoneController.text,
        );

    if (success && mounted) {
      AppToast.showSuccess(context, 'Profil berhasil diperbarui.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final displayName = user?.fullName ?? '';

    String getInitials(String name) {
      if (name.trim().isEmpty) return 'U';
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit profil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.deepTeal,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          if (AppEnv.showDemoFeatures)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.softPeach,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Simulasi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.action,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Header Avatar & Info Akun (Figma 06.05)
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.softMint,
                      child: Text(
                        getInitials(displayName),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Informasi akunmu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deepTeal,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pastikan kontak masih aktif.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nama Lengkap
                AppTextField(
                  key: const Key('edit_profile_name_field'),
                  controller: _nameController,
                  label: 'Nama lengkap',
                  hint: 'Masukkan nama lengkap',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: AppValidators.validateFullName,
                ),
                const SizedBox(height: 16),

                // Email (Readonly)
                AppTextField(
                  label: 'Email',
                  controller: TextEditingController(text: user?.email ?? ''),
                  enabled: false,
                  readOnly: true,
                  prefixIcon: Icons.email_outlined,
                  helperText: 'Alamat email akun tidak dapat diubah.',
                ),
                const SizedBox(height: 16),

                // Nomor HP
                AppTextField(
                  key: const Key('edit_profile_phone_field'),
                  controller: _phoneController,
                  label: 'Nomor HP',
                  hint: '0812 3456 7890',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: AppValidators.validatePhone,
                ),
                const SizedBox(height: 20),

                // Catatan Keamanan & Privasi (Figma 06.05)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.softMint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCDE5DE)),
                  ),
                  child: const Text(
                    'Nomor HP digunakan untuk menghubungimu saat ada permintaan bantuan.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.deepTeal,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                PrimaryButton(
                  key: const Key('edit_profile_save_button'),
                  label: 'Simpan perubahan',
                  isLoading: authState.isLoading,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
