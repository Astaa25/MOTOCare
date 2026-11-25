import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_effects.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/motorcycle_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../domain/motorcycle.dart';
import 'motorcycle_providers.dart';

/// Layar daftar sepeda motor pengguna sesuai PRD M3 & Rute `/motors`
class MotorcyclesScreen extends ConsumerWidget {
  const MotorcyclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // Proteksi Hak Akses (RBAC): Garasi motor hanya untuk Pelanggan/Pengguna
    if (user != null && (user.isMechanic || user.isAdmin)) {
      final isMech = user.isMechanic;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(isMech ? 'Garasi Tidak Tersedia' : 'Akses Dibatasi'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isMech ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMech ? Icons.engineering_rounded : Icons.admin_panel_settings_rounded,
                    size: 42,
                    color: isMech ? AppColors.warning : AppColors.error,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isMech
                      ? 'Fitur Khusus Pelanggan / Pengguna Motor'
                      : 'Akses Khusus Administrator',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  isMech
                      ? 'Sebagai Mekanik Mitra MotoCare, tugas Anda adalah menerima dan menangani order servis darurat dari pengendara, bukan mendaftarkan motor pribadi.'
                      : 'Halaman garasi kendaraan hanya diperuntukkan bagi akun bertipe pelanggan untuk melacak servis berkala.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: isMech ? 'Buka Tugas Montir' : 'Buka Dashboard Admin',
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final motorcyclesAsync = ref.watch(motorcyclesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Motor Saya',
          style: TextStyle(
            color: AppColors.deepTeal,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          if (AppEnv.showDemoFeatures)
            Container(
              margin: const EdgeInsets.only(right: 6),
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.deepTeal),
            tooltip: 'Segarkan data',
            onPressed: () => ref.read(motorcyclesProvider.notifier).loadMotorcycles(),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: motorcyclesAsync.when(
          loading: () => LoadingSkeleton.motorcycleList(),
          error: (error, _) => ErrorState(
            title: 'Gagal Memuat Data Motor',
            message: error.toString(),
            onRetry: () => ref.read(motorcyclesProvider.notifier).loadMotorcycles(),
          ),
          data: (List<Motorcycle> motors) {
            if (motors.isEmpty) {
              return EmptyState(
                key: const Key('empty_motorcycles_state'),
                icon: Icons.two_wheeler_rounded,
                title: 'Belum Ada Sepeda Motor',
                message:
                    'Tambahkan motor Anda untuk mulai memantau servis berkala, pengingat kilometer, dan memanggil bantuan montir.',
                actionLabel: 'Tambah Motor Sekarang',
                onAction: () => context.push('/motors/new'),
              );
            }

            return RefreshIndicator(
              color: AppColors.action,
              onRefresh: () => ref.read(motorcyclesProvider.notifier).loadMotorcycles(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, AppTokens.tabContentBottomPadding),
                children: <Widget>[
                  const Text(
                    'Kenali motor, rawat lebih mudah.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...motors.asMap().entries.map((entry) {
                    final index = entry.key;
                    final motor = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AnimatedEntrance(
                        index: index,
                        child: MotorcycleCard(
                          key: Key('motor_card_${motor.id}'),
                          brand: motor.brand,
                          model: motor.model,
                          productionYear: motor.productionYear,
                          licensePlate: motor.licensePlate,
                          currentMileage: motor.currentMileage,
                          mileageUpdatedAt: motor.mileageUpdatedAt,
                          heroTag: motor.id,
                          color: motor.resolvedColor,
                          category: motor.resolvedCategory,
                          engineCc: motor.resolvedEngineCc,
                          transmission: motor.resolvedTransmission,
                          photoUrl: motor.resolvedPhotoPath,
                          statusBadge: motor.isMileageStale
                              ? const StatusChip(
                                  label: 'KM Perlu Update',
                                  icon: Icons.history_toggle_off_rounded,
                                  textColor: AppColors.warning,
                                  backgroundColor: Color(0xFFFFF4E5),
                                  borderColor: AppColors.peach,
                                )
                              : null,
                          onTap: () => context.push('/motors/${motor.id}'),
                          onUpdateMileage: () => context.push('/motors/${motor.id}/mileage'),
                          onViewServices: () => context.push('/motors/${motor.id}/services'),
                          onViewReminders: () => context.push('/motors/${motor.id}/reminders'),
                        ),
                      ),
                    );
                  }),
                  if (motors.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    const Text(
                      'Perawatan motor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepTeal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMaintenanceActionCard(
                      context: context,
                      title: 'Riwayat servis',
                      subtitle: 'Catatan pekerjaan dan biaya',
                      icon: Icons.history_rounded,
                      iconBg: AppColors.softButter,
                      onTap: () => context.push('/motors/${motors.first.id}/services'),
                    ),
                    const SizedBox(height: 10),
                    _buildMaintenanceActionCard(
                      context: context,
                      title: 'Pengingat servis',
                      subtitle: 'Jadwal berdasarkan tanggal atau km',
                      icon: Icons.event_note_rounded,
                      iconBg: AppColors.softButter,
                      onTap: () => context.push('/motors/${motors.first.id}/reminders'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_motorcycle_fab'),
        onPressed: () => context.push('/motors/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Motor Baru',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildMaintenanceActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0EAE1)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
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
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
