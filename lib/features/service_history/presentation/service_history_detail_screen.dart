import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/secondary_button.dart';
import '../domain/service_history.dart';
import 'add_edit_service_history_screen.dart';
import 'service_history_providers.dart';

/// Layar Detail Catatan Servis sesuai PRD 7 M4 & Rute `/services/:id`
class ServiceHistoryDetailScreen extends ConsumerWidget {
  final String serviceId;

  const ServiceHistoryDetailScreen({
    super.key,
    required this.serviceId,
  });

  IconData _getServiceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'ganti oli':
        return Icons.opacity_rounded;
      case 'servis berkala':
        return Icons.build_circle_rounded;
      case 'rem':
        return Icons.do_not_disturb_on_rounded;
      case 'rantai':
        return Icons.link_rounded;
      case 'ban':
        return Icons.adjust_rounded;
      case 'aki':
        return Icons.battery_charging_full_rounded;
      case 'busi':
        return Icons.flash_on_rounded;
      case 'filter udara':
        return Icons.air_rounded;
      default:
        return Icons.handyman_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceHistoryDetailProvider(serviceId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Catatan Servis'),
      ),
      body: SafeArea(
        child: serviceAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(20),
            children: const <Widget>[
              LoadingSkeleton(height: 180, borderRadius: 16),
              SizedBox(height: 16),
              LoadingSkeleton(height: 140, borderRadius: 16),
            ],
          ),
          error: (err, _) => ErrorState(
            title: 'Gagal Memuat Detail Servis',
            message: err.toString(),
            onRetry: () => ref.refresh(serviceHistoryDetailProvider(serviceId)),
          ),
          data: (ServiceHistory service) {
            final icon = _getServiceIcon(service.serviceType);

            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                // Kartu Utama Servis & Biaya
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1.2),
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
                      // Banner gradien
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: AppColors.vehicleCardGradient,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.peach),
                              ),
                              child: Icon(icon, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    service.serviceType,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppFormatters.dateShort(service.serviceDate),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Biaya & Kilometer
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Biaya Servis',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppFormatters.rupiah(service.cost),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.border,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Kilometer Servis',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppFormatters.mileage(service.mileage),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Informasi Tambahan (Bengkel & Catatan)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Informasi Tambahan',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(Icons.storefront_rounded, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text('Bengkel / Tempat Servis', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  service.workshopName ?? 'Tidak dicantumkan',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(Icons.notes_rounded, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text('Catatan Perawatan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  service.description ?? 'Tidak ada catatan.',
                                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Tombol Aksi Ubah
                SecondaryButton(
                  key: const Key('edit_service_button'),
                  label: 'Ubah Catatan Servis',
                  icon: Icons.edit_outlined,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AddEditServiceHistoryScreen(
                          motorcycleId: service.motorcycleId,
                          existingService: service,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Tombol Hapus Servis
                OutlinedButton.icon(
                  key: const Key('delete_service_button'),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  label: const Text(
                    'Hapus Catatan Servis',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final confirm = await ConfirmationDialog.show(
                      context,
                      title: 'Hapus Catatan Servis?',
                      message: 'Catatan servis ini akan dihapus secara permanen.\n\nTindakan ini tidak dapat dibatalkan.',
                      confirmLabel: 'Ya, Hapus Servis',
                      cancelLabel: 'Batal',
                      isDestructive: true,
                    );

                    if (confirm == true) {
                      final result = await ref
                          .read(serviceHistoriesProvider(service.motorcycleId).notifier)
                          .deleteServiceHistory(service.id);

                      if (context.mounted) {
                        result.when(
                          onSuccess: (_) async {
                            await SuccessDialog.show(
                              context,
                              title: 'Catatan Dihapus',
                              message: 'Catatan servis telah berhasil dihapus.',
                            );
                            if (context.mounted && Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          onFailure: (err) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal menghapus servis: ${err.message}')),
                            );
                          },
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
