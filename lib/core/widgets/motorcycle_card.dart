import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Kartu tampilan informasi motor aktif sesuai PRD 4.3 & M3
class MotorcycleCard extends StatelessWidget {
  final String brand;
  final String model;
  final int productionYear;
  final String? licensePlate;
  final int currentMileage;
  final DateTime? mileageUpdatedAt;
  final Widget? statusBadge;
  final VoidCallback? onUpdateMileage;
  final VoidCallback? onViewServices;
  final VoidCallback? onViewReminders;
  final VoidCallback? onTap;

  const MotorcycleCard({
    super.key,
    required this.brand,
    required this.model,
    required this.productionYear,
    this.licensePlate,
    required this.currentMileage,
    this.mileageUpdatedAt,
    this.statusBadge,
    this.onUpdateMileage,
    this.onViewServices,
    this.onViewReminders,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header kartu dengan gradien #FFF0E3 → #FFD0A6 (Soft Cream → Peach Orange)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppColors.vehicleCardGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.peach),
                    ),
                    child: const Icon(
                      Icons.two_wheeler_rounded,
                      color: AppColors.primary,
                      size: 26,
                      semanticLabel: 'Ikon Motor',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '$brand $model',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            Text(
                              'Tahun $productionYear',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (licensePlate != null && licensePlate!.isNotEmpty) ...<Widget>[
                              const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  AppFormatters.licensePlate(licensePlate!),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  ?statusBadge,
                ],
              ),
            ),

            // Informasi kilometer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Kilometer Terkini',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.mileage(currentMileage),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                      if (onUpdateMileage != null)
                        OutlinedButton.icon(
                          onPressed: onUpdateMileage,
                          icon: const Icon(Icons.edit_road_rounded, size: 16),
                          label: const Text('Perbarui KM'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.orangeSoft),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 36),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  if (mileageUpdatedAt != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      'Diperbarui: ${AppFormatters.dateShort(mileageUpdatedAt!)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Aksi tombol cepat di bagian bawah kartu
            if (onViewServices != null || onViewReminders != null) ...<Widget>[
              const Divider(height: 1),
              Row(
                children: <Widget>[
                  if (onViewServices != null)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onViewServices,
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: const Text('Riwayat Servis'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (onViewServices != null && onViewReminders != null)
                    Container(width: 1, height: 24, color: AppColors.border),
                  if (onViewReminders != null)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onViewReminders,
                        icon: const Icon(Icons.alarm_rounded, size: 16),
                        label: const Text('Pengingat'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryText,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
