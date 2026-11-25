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
import '../data/motorcycle_catalog.dart';
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
                      // Showcase Foto Studio Kendaraan
                      Container(
                        width: double.infinity,
                        height: 175,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAF6F0),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Hero(
                                  tag: 'motor_icon_${motor.id}',
                                  child: MotorcycleImage(
                                    brand: motor.brand,
                                    model: motor.model,
                                    photoUrl: motor.resolvedPhotoPath,
                                    fit: BoxFit.contain,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: MotorcycleCatalog.resolveSwatchColor(motor.resolvedColor),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.charcoalGreen, width: 0.8),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      motor.resolvedColor,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepTeal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.deepTeal,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${motor.resolvedEngineCc} cc',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Banner gradien header info utama
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          gradient: AppColors.vehicleCardGradient,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    motor.name,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tahun ${motor.productionYear} • ${motor.resolvedCategory}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFD5E5E3),
                                      fontWeight: FontWeight.w600,
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
                const SizedBox(height: 16),

                // Kartu Spesifikasi & Detail Kendaraan
                Container(
                  key: const Key('motorcycle_specs_card'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Detail & Spesifikasi Kendaraan',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.deepTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SpecDetailRow(
                        label: 'Warna Body',
                        value: motor.resolvedColor,
                        leadingDotColor: MotorcycleCatalog.resolveSwatchColor(motor.resolvedColor),
                      ),
                      const Divider(height: 16),
                      _SpecDetailRow(label: 'Kategori', value: motor.resolvedCategory),
                      const Divider(height: 16),
                      _SpecDetailRow(label: 'Kapasitas Mesin', value: '${motor.resolvedEngineCc} cc'),
                      const Divider(height: 16),
                      _SpecDetailRow(label: 'Transmisi', value: motor.resolvedTransmission),
                      const Divider(height: 16),
                      _SpecDetailRow(label: 'Rekomendasi BBM', value: motor.resolvedFuelType),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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

class _SpecDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? leadingDotColor;

  const _SpecDetailRow({
    required this.label,
    required this.value,
    this.leadingDotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (leadingDotColor != null) ...<Widget>[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: leadingDotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.charcoalGreen, width: 0.9),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
