import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/motorcycle_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../../motorcycles/domain/motorcycle.dart';
import '../../motorcycles/presentation/motorcycle_providers.dart';

/// Layar Beranda Utama MotoCare sesuai PRD 7 (M3) & Rute `/home`
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final activeMotorAsync = ref.watch(activeMotorcycleProvider);

    final displayName = user?.fullName ?? 'Pengguna';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Halo, $displayName 👋',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Care for Every Ride',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            key: const Key('home_notifications_button'),
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifikasi',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            key: const Key('home_profile_button'),
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profil Saya',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(motorcyclesProvider.notifier).loadMotorcycles(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: <Widget>[
              // Banner Wilayah Layanan Permanen sesuai PRD 2.3
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.peach),
                ),
                child: const Row(
                  children: <Widget>[
                    Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cakupan Layanan: Kota Lhokseumawe & Kab. Aceh Utara',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bagian Motor Aktif
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Sepeda Motor Aktif',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/motors'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryText,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text(
                      'Kelola Motor',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              activeMotorAsync.when(
                loading: () => const LoadingSkeleton(height: 190, borderRadius: 16),
                error: (err, _) => ErrorState(
                  title: 'Gagal Memuat Motor',
                  message: err.toString(),
                  onRetry: () => ref.read(motorcyclesProvider.notifier).loadMotorcycles(),
                ),
                data: (Motorcycle? motor) {
                  if (motor == null) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: EmptyState(
                        key: const Key('home_empty_motor_card'),
                        icon: Icons.two_wheeler_rounded,
                        title: 'Belum Ada Sepeda Motor',
                        message:
                            'Daftarkan motor Anda untuk mengaktifkan pengingat servis otomatis dan pencatatan kilometer.',
                        actionLabel: 'Tambah Motor Sekarang',
                        onAction: () => context.push('/motors/new'),
                      ),
                    );
                  }

                  return MotorcycleCard(
                    key: Key('home_motor_card_${motor.id}'),
                    brand: motor.brand,
                    model: motor.model,
                    productionYear: motor.productionYear,
                    licensePlate: motor.licensePlate,
                    currentMileage: motor.currentMileage,
                    mileageUpdatedAt: motor.mileageUpdatedAt,
                    statusBadge: motor.isMileageStale
                        ? const StatusChip(
                            label: 'KM Perlu Update',
                            icon: Icons.warning_amber_rounded,
                            textColor: AppColors.warning,
                            backgroundColor: Color(0xFFFFF4E5),
                            borderColor: AppColors.peach,
                          )
                        : null,
                    onTap: () => context.push('/motors/${motor.id}'),
                    onUpdateMileage: () => context.push('/motors/${motor.id}/mileage'),
                    onViewServices: () => context.push('/motors/${motor.id}/services'),
                    onViewReminders: () => context.push('/motors/${motor.id}/reminders'),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Tombol Utama: Butuh Bantuan Mekanik / Panggil Montir sesuai PRD 7 M3
              PrimaryButton(
                key: const Key('home_request_mechanic_button'),
                label: 'Butuh Bantuan Mekanik? Panggil Montir',
                icon: Icons.build_circle_rounded,
                onPressed: () => context.push('/help/new'),
              ),
              const SizedBox(height: 24),

              // Menu Cepat Akses Layanan Lainnya
              const Text(
                'Layanan & Fitur MotoCare',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: <Widget>[
                  _QuickActionCard(
                    title: 'Bengkel Terverifikasi',
                    subtitle: 'Cari bengkel resmi & tepercaya',
                    icon: Icons.storefront_rounded,
                    onTap: () => context.push('/workshops'),
                  ),
                  _QuickActionCard(
                    title: 'Tutorial Perawatan',
                    subtitle: 'Panduan servis mandiri',
                    icon: Icons.ondemand_video_rounded,
                    onTap: () => context.push('/tutorials'),
                  ),
                  _QuickActionCard(
                    title: 'Bantuan Montir',
                    subtitle: 'Status permintaan aktif',
                    icon: Icons.sos_rounded,
                    onTap: () => context.push('/help'),
                  ),
                  _QuickActionCard(
                    title: 'Motor Saya',
                    subtitle: 'Daftar motor terdaftar',
                    icon: Icons.motorcycle_rounded,
                    onTap: () => context.push('/motors'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
