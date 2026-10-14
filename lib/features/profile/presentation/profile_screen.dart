import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/presentation/auth_state_provider.dart';

/// Layar Profil Pengguna MotoCare sesuai PRD M2
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    final String displayName = user?.fullName ?? 'Pengguna MotoCare';
    final String email = user?.email ?? 'pengguna@motocare.id';
    final String phone = user?.phone ?? 'Belum diatur';
    final String role = user?.role == 'admin'
        ? 'Admin'
        : (user?.role == 'mechanic' ? 'Mekanik' : 'Pengguna');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/motors');
              break;
            case 2:
              context.go('/workshops');
              break;
            case 3:
              context.go('/tutorials');
              break;
            case 4:
              break;
          }
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          // Header profil dengan avatar inisial
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.vehicleCardGradient,
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                StatusChip(
                  label: role,
                  icon: Icons.shield_outlined,
                  backgroundColor: AppColors.cream,
                  textColor: AppColors.primaryText,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Informasi Akun Detail
          Material(
            color: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  title: const Text('Nama Lengkap', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  subtitle: Text(displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                  title: const Text('Nomor Telepon', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  subtitle: Text(phone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.location_city_rounded, color: AppColors.primary),
                  title: Text('Cakupan Wilayah Layanan', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  subtitle: Text(
                    'Kota Lhokseumawe & Kab. Aceh Utara',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu Aksi
          Material(
            color: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                ListTile(
                  key: const Key('profile_edit_button'),
                  leading: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
                  title: const Text('Ubah Profil', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/profile/edit'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: AppColors.textPrimary),
                  title: const Text('Katalog Komponen UI (Debug)', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/catalog'),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('profile_logout_button'),
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text(
                    'Keluar dari Akun',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
                  ),
                  onTap: () async {
                    final confirm = await ConfirmationDialog.show(
                      context,
                      title: 'Keluar dari Akun?',
                      message: 'Sesi Anda akan dihentikan dan Anda perlu masuk kembali.',
                      confirmLabel: 'Ya, Keluar',
                      cancelLabel: 'Batal',
                      isDestructive: true,
                    );

                    if (confirm == true) {
                      await ref.read(authStateProvider.notifier).signOut();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
