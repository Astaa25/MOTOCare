import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_effects.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../auth/presentation/auth_state_provider.dart';

/// Layar Akun / Profil Pengguna MotoCare sesuai Figma 06.04 (Arah Visual Baru)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    final String displayName = user?.fullName ?? 'Pengguna MotoCare';
    final String email = user?.email ?? 'pengguna@motocare.id';
    final String roleDescription = user?.role == 'admin'
        ? 'Administrator'
        : (user?.role == 'mechanic' ? 'Mekanik mitra' : 'Pemilik kendaraan');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Akun saya',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.deepTeal,
          ),
        ),
        automaticallyImplyLeading: false,
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
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, AppTokens.tabContentBottomPadding),
          children: <Widget>[
            // --- KARTU PROFIL UTAMA (FIGMA 06.04) ---
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.softMint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFCDE5DE)),
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.deepTeal,
                    child: Text(
                      _getInitials(displayName),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepTeal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          roleDescription,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // --- MENU PILIHAN (FIGMA 06.04) ---
            _buildMenuItem(
              key: const Key('profile_edit_button'),
              icon: Icons.person_outline_rounded,
              title: 'Edit profil',
              subtitle: 'Nama, email, dan nomor HP',
              onTap: () => context.push('/profile/edit'),
            ),
            const Divider(height: 1, color: Color(0xFFF0EAE1)),

            _buildMenuItem(
              icon: Icons.two_wheeler_rounded,
              title: 'Motor saya',
              subtitle: 'Data kendaraan dan perawatan',
              onTap: () => context.push('/motors'),
            ),
            const Divider(height: 1, color: Color(0xFFF0EAE1)),

            _buildMenuItem(
              icon: Icons.notifications_none_rounded,
              title: 'Pengaturan notifikasi',
              subtitle: 'Status bantuan dan jadwal servis',
              onTap: () => context.push('/notifications/settings'),
            ),
            const Divider(height: 1, color: Color(0xFFF0EAE1)),

            _buildMenuItem(
              icon: Icons.menu_book_rounded,
              title: 'Tutorial perawatan',
              subtitle: 'Panduan motor sehari-hari',
              onTap: () => context.push('/tutorials'),
            ),
            const Divider(height: 1, color: Color(0xFFF0EAE1)),

            const SizedBox(height: 16),

            // --- KELUAR DARI AKUN (FIGMA 06.04) ---
            InkWell(
              key: const Key('profile_logout_button'),
              borderRadius: BorderRadius.circular(8),
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
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Keluar dari akun',
                  style: TextStyle(
                    color: AppColors.action,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // --- JELAJAHI PERAN DEMO (FIGMA 06.04) ---
            if (AppEnv.showDemoFeatures) ...<Widget>[
              const SizedBox(height: 16),
              const Text(
                'Jelajahi peran demo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: <Widget>[
                  InkWell(
                    onTap: () => context.push('/home'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Area mekanik',
                        style: TextStyle(
                          color: AppColors.action,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push('/admin'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Area admin',
                        style: TextStyle(
                          color: AppColors.action,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return BouncingWidget(
      onTap: onTap,
      scaleFactor: 0.985,
      hoverScale: 1.01,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.softPeach,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.coral.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(icon, color: AppColors.deepTeal, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepTeal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
