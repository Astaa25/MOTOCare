import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/motorcycle.dart';
import 'motorcycle_providers.dart';

/// Layar Detail Sepeda Motor sesuai PRD 7 M3
class MotorcycleDetailScreen extends ConsumerWidget {
  final String motorcycleId;

  const MotorcycleDetailScreen({
    super.key,
    required this.motorcycleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motorAsync = ref.watch(motorcycleDetailProvider(motorcycleId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Detail Sepeda Motor'),
        actions: <Widget>[
          IconButton(
            key: const Key('edit_motorcycle_appbar_button'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Ubah Motor',
            onPressed: () => context.push('/motors/$motorcycleId/edit'),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
        child: motorAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(20),
            children: const <Widget>[
              LoadingSkeleton(height: 200, borderRadius: 16),
              SizedBox(height: 20),
              LoadingSkeleton(height: 120, borderRadius: 16),
            ],
          ),
          error: (err, _) => ErrorState(
            title: 'Gagal Memuat Detail Motor',
            message: err.toString(),
            onRetry: () => ref.refresh(motorcycleDetailProvider(motorcycleId)),
          ),
          data: (Motorcycle motor) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                // Kartu Utama Motor
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.2),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      // Banner gradien
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: AppColors.vehicleCardGradient,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        child: Row(
                          children: <Widget>[
                            Hero(
                              tag: 'motor_icon_${motor.id}',
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.peach),
                                ),
                                child: const Icon(
                                  Icons.two_wheeler_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    motor.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tahun ${motor.productionYear}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (motor.licensePlate != null && motor.licensePlate!.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 4),
                                    Hero(
                                      tag: 'motor_plate_${motor.id}',
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(color: AppColors.charcoalGreen, width: 1.6),
                                          boxShadow: <BoxShadow>[
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          AppFormatters.licensePlate(motor.licensePlate!),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.charcoalDark,
                                            letterSpacing: 0.8,
                                            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (motor.isMileageStale) ...<Widget>[
                                    const SizedBox(height: 6),
                                    const StatusChip(
                                      label: 'KM Perlu Update',
                                      icon: Icons.warning_amber_rounded,
                                      textColor: AppColors.warning,
                                      backgroundColor: Color(0xFFFFF4E5),
                                      borderColor: AppColors.peach,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Statistik kilometer
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Kilometer Saat Ini',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.mileage(motor.currentMileage),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Diperbarui: ${AppFormatters.dateShort(motor.mileageUpdatedAt)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            PrimaryButton(
                              key: const Key('update_mileage_action_button'),
                              width: null,
                              label: 'Perbarui KM',
                              icon: Icons.edit_road_rounded,
                              onPressed: () => context.push('/motors/${motor.id}/mileage'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Menu Navigasi Terkait (Servis & Pengingat)
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
                        leading: const Icon(Icons.history_rounded, color: AppColors.primary),
                        title: const Text('Riwayat & Catatan Servis', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Pantau riwayat perbaikan dan biaya berkala', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/motors/${motor.id}/services'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.alarm_rounded, color: AppColors.primary),
                        title: const Text('Pengingat Servis Rutin', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Jadwal ganti oli, servis rantai, aki, dan rem', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/motors/${motor.id}/reminders'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Aksi Pengaturan Motor
                SecondaryButton(
                  key: const Key('edit_motor_button'),
                  label: 'Ubah Informasi Motor',
                  icon: Icons.edit_outlined,
                  onPressed: () => context.push('/motors/${motor.id}/edit'),
                ),
                const SizedBox(height: 12),

                // Tombol Hapus Motor (Destructive ConfirmationDialog)
                OutlinedButton.icon(
                  key: const Key('delete_motorcycle_button'),
                  onPressed: () async {
                    final confirm = await ConfirmationDialog.show(
                      context,
                      title: 'Hapus Sepeda Motor?',
                      message:
                          'Menghapus ${motor.name} juga akan menghapus seluruh riwayat servis dan jadwal pengingat yang terhubung.\n\nTindakan ini tidak dapat dibatalkan.',
                      confirmLabel: 'Ya, Hapus Motor',
                      cancelLabel: 'Batal',
                      isDestructive: true,
                    );

                    if (confirm == true) {
                      final result = await ref
                          .read(motorcyclesProvider.notifier)
                          .deleteMotorcycle(motor.id);

                      if (context.mounted) {
                        result.when(
                          onSuccess: (_) async {
                            await SuccessDialog.show(
                              context,
                              title: 'Motor Dihapus',
                              message: '${motor.name} telah berhasil dihapus dari daftar.',
                            );
                            if (context.mounted && Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          onFailure: (err) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal menghapus motor: ${err.message}')),
                            );
                          },
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  label: const Text(
                    'Hapus Sepeda Motor',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
}
