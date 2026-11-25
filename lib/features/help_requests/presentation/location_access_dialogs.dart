import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';

/// Modal dialog kondisi Figma 09.06: "Lokasi belum dapat diakses"
class LocationPermissionDialog extends StatelessWidget {
  const LocationPermissionDialog({
    super.key,
    required this.onRetry,
    required this.onManualInput,
    this.isPermanentlyDenied = false,
  });

  final VoidCallback onRetry;
  final VoidCallback onManualInput;
  final bool isPermanentlyDenied;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Ikon Terakota Lingkaran
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.peach, width: 1.5),
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Judul sesuai Figma 09.06
            const Text(
              'Lokasi belum dapat diakses',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Keterangan kontekstual
            Text(
              isPermanentlyDenied
                  ? 'Izin lokasi dinonaktifkan secara permanen di setelan HP. '
                      'Buka pengaturan untuk mengaktifkan izin agar montir dapat menemukan titik Anda.'
                  : 'Aktifkan izin lokasi agar montir mitra MotoCare dapat melihat posisi penjemputan '
                      'dan segera menuju lokasi mogok Anda.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Aksi Figma
            PrimaryButton(
              key: const Key('btn_retry_location_access'),
              label: isPermanentlyDenied ? 'Buka Pengaturan' : 'Coba akses lagi',
              icon: Icons.my_location_rounded,
              onPressed: onRetry,
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              key: const Key('btn_manual_location_input'),
              label: 'Masukkan lokasi manual',
              onPressed: onManualInput,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal dialog kondisi Figma 09.07: "Lokasi belum diperbarui"
class LocationStaleDialog extends StatelessWidget {
  const LocationStaleDialog({
    super.key,
    required this.lastAddress,
    required this.lastUpdatedText,
    required this.onRefresh,
    required this.onUseLastLocation,
  });

  final String lastAddress;
  final String lastUpdatedText;
  final VoidCallback onRefresh;
  final VoidCallback onUseLastLocation;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.peach, width: 1.5),
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 32,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Lokasi belum diperbarui',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Sinyal GPS belum memperbarui posisi terkini Anda. Posisi terakhir yang tercatat:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Kartu Lokasi Terakhir
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.place_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          lastAddress.isNotEmpty ? lastAddress : 'Lokasi sebelumnya',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pembaruan: $lastUpdatedText',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              key: const Key('btn_refresh_location'),
              label: 'Perbarui sekarang',
              icon: Icons.refresh_rounded,
              onPressed: onRefresh,
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              key: const Key('btn_use_last_location'),
              label: 'Gunakan posisi terakhir',
              onPressed: onUseLastLocation,
            ),
          ],
        ),
      ),
    );
  }
}

