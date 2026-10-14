import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/motorcycle_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../../motorcycles/domain/motorcycle.dart';
import '../../motorcycles/presentation/motorcycle_providers.dart';
import '../../notifications/presentation/notifications_providers.dart';
import '../../reminders/domain/maintenance_reminder.dart';
import '../../reminders/presentation/reminders_providers.dart';
import '../../service_history/domain/service_history.dart';
import '../../service_history/presentation/service_history_providers.dart';

/// Layar Beranda Utama MotoCare sesuai PRD Bagian 7 (M3 & M5) & Rute `/home`
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final activeMotorAsync = ref.watch(activeMotorcycleProvider);
    final unreadNotifCount = ref.watch(unreadNotificationCountProvider);

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
            icon: Badge(
              isLabelVisible: unreadNotifCount > 0,
              label: Text('$unreadNotifCount'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Pusat Notifikasi',
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
          onRefresh: () async {
            await ref.read(motorcyclesProvider.notifier).loadMotorcycles();
            await ref.read(notificationsNotifierProvider.notifier).syncWithReminders();
          },
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
                  const Expanded(
                    child: Text(
                      'Sepeda Motor Aktif',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
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
                    return Column(
                      children: <Widget>[
                        Container(
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
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          key: const Key('home_request_mechanic_button'),
                          label: 'Butuh Bantuan Mekanik? Panggil Montir',
                          icon: Icons.build_circle_rounded,
                          onPressed: () => context.push('/help/new'),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Saran Pembaruan Kilometer Jika Stale > 30 Hari (PRD 6.5 #5)
                      if (motor.isMileageStale) ...<Widget>[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.peach),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.info_rounded, color: AppColors.warning, size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Kilometer belum diperbarui > 30 hari. Perbarui agar jadwal servis akurat.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push('/motors/${motor.id}/mileage'),
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: const Text(
                                  'Update',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      MotorcycleCard(
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
                      ),

                      const SizedBox(height: 16),

                      // Tombol Utama: Butuh Bantuan Mekanik / Panggil Montir sesuai PRD 7 M3
                      PrimaryButton(
                        key: const Key('home_request_mechanic_button'),
                        label: 'Butuh Bantuan Mekanik? Panggil Montir',
                        icon: Icons.build_circle_rounded,
                        onPressed: () => context.push('/help/new'),
                      ),

                      const SizedBox(height: 20),

                      // Ringkasan Pengingat Servis Terdekat (PRD Bagian 7 M5)
                      _NearestReminderSection(motorcycle: motor),

                      const SizedBox(height: 16),

                      // Ringkasan Servis Terakhir (PRD Bagian 7 M5)
                      _LastServiceSection(motorcycle: motor),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
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
                childAspectRatio: 1.15,
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
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        unreadNotificationsCount: unreadNotifCount,
        onTap: (index) {
          switch (index) {
            case 0:
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
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}

/// Bagian Pengingat Servis Terdekat pada Beranda
class _NearestReminderSection extends ConsumerWidget {
  final Motorcycle motorcycle;

  const _NearestReminderSection({required this.motorcycle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderAsync = ref.watch(nearestReminderProvider(motorcycle.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Expanded(
              child: Text(
                'Pengingat Servis Terdekat',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.push('/motors/${motorcycle.id}/reminders'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryText,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
              ),
              child: const Text(
                'Lihat Semua',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        reminderAsync.when(
          loading: () => const LoadingSkeleton(height: 80, borderRadius: 14),
          error: (err, stack) => const SizedBox.shrink(),
          data: (MaintenanceReminder? reminder) {
            if (reminder == null) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.alarm_off_rounded, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Semua jadwal servis aman terkendali.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push('/reminders/new?motorId=${motorcycle.id}'),
                      child: const Text('Buat Pengingat', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            }

            final status = reminder.computeStatus(motorcycle.currentMileage);

            return Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: status.borderColor,
                  width: 1.2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/reminders/${reminder.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: status.backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(status.icon, color: status.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              reminder.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reminder.reminderDate != null
                                  ? 'Target: ${AppFormatters.formatDate(reminder.reminderDate!)}'
                                  : 'Target: ${AppFormatters.formatKilometer(reminder.targetMileage ?? 0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: status.label,
                        icon: status.icon,
                        textColor: status.color,
                        backgroundColor: status.backgroundColor,
                        borderColor: status.borderColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Bagian Ringkasan Servis Terakhir pada Beranda
class _LastServiceSection extends ConsumerWidget {
  final Motorcycle motorcycle;

  const _LastServiceSection({required this.motorcycle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceHistoriesProvider(motorcycle.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Expanded(
              child: Text(
                'Servis Terakhir',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.push('/motors/${motorcycle.id}/services'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryText,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
              ),
              child: const Text(
                'Semua Riwayat',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        servicesAsync.when(
          loading: () => const LoadingSkeleton(height: 75, borderRadius: 14),
          error: (err, stack) => const SizedBox.shrink(),
          data: (List<ServiceHistory> services) {
            if (services.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.history_toggle_off_rounded,
                        color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Belum ada riwayat servis tercatat.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push('/motors/${motorcycle.id}/services/new'),
                      child: const Text('Catat Servis', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            }

            final latest = services.first;

            return Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/services/${latest.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.build_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              latest.serviceType,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${AppFormatters.formatDate(latest.serviceDate)} • ${AppFormatters.formatKilometer(latest.mileage)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        AppFormatters.formatRupiah(latest.cost),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }
}
