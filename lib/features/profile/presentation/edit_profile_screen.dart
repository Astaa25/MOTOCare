import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Profil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Email (Readonly)
                AppTextField(
                  label: 'Alamat Email',
                  controller: TextEditingController(text: user?.email ?? ''),
                  enabled: false,
                  readOnly: true,
                  prefixIcon: Icons.email_outlined,
                  helperText: 'Alamat email akun tidak dapat diubah.',
                ),
                const SizedBox(height: 16),

                // Nama Lengkap
                AppTextField(
                  key: const Key('edit_profile_name_field'),
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama lengkap',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: AppValidators.validateFullName,
                ),
                const SizedBox(height: 16),

                // Nomor Telepon
                AppTextField(
                  key: const Key('edit_profile_phone_field'),
                  controller: _phoneController,
                  label: 'Nomor Telepon',
                  hint: 'Contoh: 081234567890',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: AppValidators.validatePhone,
                ),
                const SizedBox(height: 16),

                // Peran Akun (Non-editable demi keamanan PRD 5.3 & SEC-03)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.peach),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Peran Akun: ${user?.role == 'admin' ? 'Administrator' : 'Pengguna Biasa'} (Terkunci oleh sistem keamanan RLS)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                PrimaryButton(
                  key: const Key('edit_profile_save_button'),
                  label: 'Simpan Perubahan',
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
