import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/workshop.dart';
import '../domain/workshop_rules.dart';
import 'workshops_providers.dart';

/// Layar Detail Bengkel Terverifikasi sesuai PRD Bagian 7 (M6)
class WorkshopDetailScreen extends ConsumerStatefulWidget {
  final String workshopId;

  const WorkshopDetailScreen({
    super.key,
    required this.workshopId,
  });

  @override
  ConsumerState<WorkshopDetailScreen> createState() =>
      _WorkshopDetailScreenState();
}

class _WorkshopDetailScreenState extends ConsumerState<WorkshopDetailScreen> {
  Future<void> _openMap(BuildContext context, Workshop workshop) async {
    if (workshop.latitude != null && workshop.longitude != null) {
      final double lat = workshop.latitude!;
      final double lon = workshop.longitude!;
      final Uri geoUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon');
      final Uri webUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
      );

      try {
        if (await canLaunchUrl(geoUri)) {
          final bool launched = await launchUrl(
            geoUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return;
        } else if (await canLaunchUrl(webUri)) {
          final bool launched = await launchUrl(
            webUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return;
        }
      } catch (_) {}
    }

    // Fallback sesuai PRD: salin alamat bengkel ke papan klip
    final String copyText = '${workshop.name}, ${workshop.address}';
    await Clipboard.setData(ClipboardData(text: copyText));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat bengkel berhasil disalin ke papan klip.'),
          backgroundColor: AppColors.charcoal,
        ),
      );
    }
  }

  Future<void> _callPhone(BuildContext context, String phone) async {
    final Uri phoneUri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        return;
      }
    } catch (_) {}

    await Clipboard.setData(ClipboardData(text: phone));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon bengkel disalin ke papan klip.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workshopAsync = ref.watch(workshopDetailProvider(widget.workshopId));
    final userLocationAsync = ref.watch(userLocationProvider);
    final userLocation = userLocationAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Bengkel'),
      ),
      body: SafeArea(
        child: workshopAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: const <Widget>[
              LoadingSkeleton(height: 120, borderRadius: 16),
              SizedBox(height: 16),
              LoadingSkeleton(height: 180, borderRadius: 16),
              SizedBox(height: 16),
              LoadingSkeleton(height: 100, borderRadius: 16),
            ],
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorState(
                title: 'Gagal Memuat Detail Bengkel',
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(workshopDetailProvider(widget.workshopId)),
              ),
            ),
          ),
          data: (Workshop? workshop) {
            if (workshop == null) {
              return const Center(
                child: Text(
                  'Bengkel tidak ditemukan.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            final distanceStr = WorkshopRules.formatDistance(
              workshopLat: workshop.latitude,
              workshopLon: workshop.longitude,
              userLat: userLocation?.latitude,
              userLon: userLocation?.longitude,
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // Kartu Utama Informasi Bengkel
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              workshop.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (workshop.isDemo) ...<Widget>[
                            const SizedBox(width: 8),
                            const StatusChip(
                              key: Key('detail_demo_badge'),
                              label: 'Demo/Simulasi',
                              icon: Icons.science_outlined,
                              backgroundColor: Color(0xFFF3F4F6),
                              textColor: AppColors.textSecondary,
                              borderColor: Color(0xFFE5E7EB),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Alamat
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              workshop.address,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Text(
                          workshop.cityOrRegency,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),

                      // Jarak jika lokasi tersedia
                      if (distanceStr != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 26),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cream,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.peach),
                                ),
                                child: Text(
                                  'Jarak perkiraan: $distanceStr',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Jam Operasional dan Kontak
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Jam Operasional
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Jam Operasional',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            workshop.openingHours ?? 'Belum tersedia',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Nomor Telepon & Aksi Panggil
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Nomor Kontak',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (workshop.phone != null &&
                              workshop.phone!.isNotEmpty) ...<Widget>[
                            TextButton.icon(
                              key: const Key('call_workshop_button'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryText,
                                padding: EdgeInsets.zero,
                              ),
                              icon: const Icon(Icons.call_rounded, size: 16),
                              label: Text(workshop.phone!),
                              onPressed: () =>
                                  _callPhone(context, workshop.phone!),
                            ),
                          ] else ...<Widget>[
                            const Text(
                              'Belum tersedia',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Layanan yang Disediakan
                if (workshop.services.isNotEmpty) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Layanan Servis yang Tersedia',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: workshop.services.map((service) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    service,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Tombol Buka di Peta (PRD 618: Geo URI / Maps fallback copy address)
                OutlinedButton.icon(
                  key: const Key('open_workshop_map_button'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryText,
                    side: const BorderSide(color: AppColors.peach, width: 1.5),
                    backgroundColor: AppColors.cream,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text(
                    'Buka di Peta',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  onPressed: () => _openMap(context, workshop),
                ),
                const SizedBox(height: 12),

                // Tombol Minta Bantuan Mekanik (PRD 618 & 689)
                PrimaryButton(
                  key: const Key('request_mechanic_from_workshop_button'),
                  label: 'Minta Bantuan Mekanik',
                  icon: Icons.support_agent_rounded,
                  onPressed: () => context.push('/help/new?workshopId=${workshop.id}'),
                ),
                const SizedBox(height: 12),

                // Opsi Salin Alamat Bengkel
                Center(
                  child: TextButton.icon(
                    key: const Key('copy_workshop_address_button'),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Salin Alamat Lengkap'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryText,
                    ),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: '${workshop.name}, ${workshop.address}'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Alamat bengkel berhasil disalin ke papan klip.',
                          ),
                          backgroundColor: AppColors.charcoal,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
