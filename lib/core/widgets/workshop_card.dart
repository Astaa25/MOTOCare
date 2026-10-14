import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'status_chip.dart';

/// Kartu bengkel terverifikasi MotoCare sesuai PRD 4.3 & M6
class WorkshopCard extends StatelessWidget {
  final String name;
  final String address;
  final String cityOrRegency;
  final String? openingHours;
  final String? phone;
  final List<String> services;
  final bool isDemo;
  final double? distanceKm;
  final VoidCallback? onOpenMap;
  final VoidCallback? onRequestHelp;
  final VoidCallback? onTap;

  const WorkshopCard({
    super.key,
    required this.name,
    required this.address,
    required this.cityOrRegency,
    this.openingHours,
    this.phone,
    this.services = const <String>[],
    this.isDemo = false,
    this.distanceKm,
    this.onOpenMap,
    this.onRequestHelp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Nama bengkel dan badge terverifikasi / demo
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cityOrRegency,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDemo)
                  StatusChip.demo()
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.verified_rounded, size: 13, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Terverifikasi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Alamat bengkel
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),

            // Jam operasional jika tersedia
            if (openingHours != null && openingHours!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.access_time_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    openingHours!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            // Jarak hanya jika izin lokasi diberikan (PRD 6.3)
            if (distanceKm != null) ...<Widget>[
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.near_me_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sekitar ${distanceKm!.toStringAsFixed(1)} km dari Anda',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ],

            // Tag layanan jika ada
            if (services.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: services.take(3).map((service) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.peach, width: 0.8),
                    ),
                    child: Text(
                      service,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Tombol aksi
            if (onOpenMap != null || onRequestHelp != null) ...<Widget>[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  if (onOpenMap != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onOpenMap,
                        icon: const Icon(Icons.map_outlined, size: 15),
                        label: const Text('Buka di Peta'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (onOpenMap != null && onRequestHelp != null)
                    const SizedBox(width: 8),
                  if (onRequestHelp != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onRequestHelp,
                        icon: const Icon(Icons.sos_rounded, size: 15),
                        label: const Text('Minta Bantuan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
