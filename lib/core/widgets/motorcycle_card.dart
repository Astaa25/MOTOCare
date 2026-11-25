import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/motorcycles/data/motorcycle_catalog.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../utils/formatters.dart';
import 'animated_effects.dart';

/// Kartu Informasi Sepeda Motor Digital Garage berkarakter "Bengkel yang Ramah"
/// Menampilkan:
/// 1. Plat nomor fisik Indonesia autentik (latar putih, border charcoal tegas #243830, tabular figures)
/// 2. Odometer instrumen otomotif dengan angka tebal tabular
/// 3. Busur speedometer servis (SpeedometerArcPainter) menggantikan progress bar lurus;
///    hanya aktif jika ada dasar data servis/pengingat, atau menampilkan keadaan kosong jujur.
class MotorcycleCard extends StatelessWidget {
  final String brand;
  final String model;
  final int productionYear;
  final String? licensePlate;
  final int currentMileage;
  final DateTime? mileageUpdatedAt;
  final Widget? statusBadge;
  final double? serviceCycleProgress;
  final String? serviceStatusText;
  final String? heroTag;
  final String? color;
  final String? category;
  final int? engineCc;
  final String? transmission;
  final String? photoUrl;
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
    this.serviceCycleProgress,
    this.serviceStatusText,
    this.heroTag,
    this.color,
    this.category,
    this.engineCc,
    this.transmission,
    this.photoUrl,
    this.onUpdateMileage,
    this.onViewServices,
    this.onViewReminders,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveHoverCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      backgroundColor: AppColors.warmWhite,
      borderColor: AppColors.border,
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header Kartu Digital Garage dengan Aksen Gradien Krem-Hangat
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: AppColors.vehicleCardGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
                ),
                child: Row(
                  children: <Widget>[
                    heroTag != null && heroTag!.isNotEmpty
                        ? Hero(
                            tag: 'motor_icon_$heroTag',
                            child: _buildMotorIcon(),
                          )
                        : _buildMotorIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '$brand $model',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: <Widget>[
                              Text(
                                'Tahun $productionYear',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFD5E5E3),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (licensePlate != null && licensePlate!.isNotEmpty) ...<Widget>[
                                const Text('•', style: TextStyle(color: Color(0xFFD5E5E3), fontSize: 10)),
                                // Plat nomor fisik Indonesia: latar putih bersih, garis tepi charcoal tegas (#243830), font tebal khas plat
                                heroTag != null && heroTag!.isNotEmpty
                                    ? Hero(
                                        tag: 'motor_plate_$heroTag',
                                        child: _buildLicensePlateBadge(licensePlate!),
                                      )
                                    : _buildLicensePlateBadge(licensePlate!),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: <Widget>[
                              _buildDarkSpecPill(
                                label: color ?? MotorcycleCatalog.findSpec(brand, model).defaultColor,
                                dotColor: MotorcycleCatalog.resolveSwatchColor(
                                  color ?? MotorcycleCatalog.findSpec(brand, model).defaultColor,
                                ),
                              ),
                              _buildDarkSpecPill(
                                label: '${engineCc ?? MotorcycleCatalog.findSpec(brand, model).engineCc} cc',
                              ),
                              if (category != null && category!.isNotEmpty)
                                _buildDarkSpecPill(label: category!),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (statusBadge != null) ...<Widget>[
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 130),
                        child: statusBadge!,
                      ),
                    ],
                  ],
                ),
              ),

              // Bagian Odometer & Busur Speedometer Servis
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(Icons.speed_rounded, size: 14, color: AppColors.textSecondary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Odometer Terkini',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  AppFormatters.mileage(currentMileage),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryText,
                                    letterSpacing: -0.5,
                                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onUpdateMileage != null) ...<Widget>[
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                onUpdateMileage?.call();
                              },
                              icon: const Icon(Icons.edit_note_rounded, size: 16),
                              label: const Text('Update KM'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.terracotta,
                                side: const BorderSide(color: AppColors.border, width: 1.2),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Indikator Siklus Servis: Busur Speedometer vs Keadaan Kosong Jujur
                    if (serviceCycleProgress != null && serviceCycleProgress! > 0) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 64,
                              height: 38,
                              child: CustomPaint(
                                painter: SpeedometerArcPainter(
                                  progress: serviceCycleProgress!.clamp(0.0, 1.0),
                                  trackColor: AppColors.border,
                                  progressColor: serviceCycleProgress! > 0.85
                                      ? AppColors.warning
                                      : AppColors.terracotta,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    serviceStatusText ?? 'Siklus Servis Berkala',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${(serviceCycleProgress! * 100).toInt()}% menuju jadwal perawatan',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...<Widget>[
                      // Keadaan Kosong yang Jujur (Tidak ada data pengingat servis yang diada-adakan)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                currentMileage == 0
                                    ? 'Belum ada data jarak tempuh & target servis.'
                                    : (mileageUpdatedAt != null
                                        ? 'Diperbarui: ${AppFormatters.dateShort(mileageUpdatedAt!)}'
                                        : 'Siap untuk pemantauan perawatan berkala.'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
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

              // Aksi Tombol Cepat di Bagian Bawah Kartu
              if (onViewServices != null || onViewReminders != null) ...<Widget>[
                const Divider(height: 1, color: AppColors.border),
                Row(
                  children: <Widget>[
                    if (onViewServices != null)
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            onViewServices?.call();
                          },
                          icon: const Icon(Icons.history_rounded, size: 16),
                          label: const Text('Riwayat Servis'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    if (onViewServices != null && onViewReminders != null)
                      Container(width: 1, height: 24, color: AppColors.border),
                    if (onViewReminders != null)
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            onViewReminders?.call();
                          },
                          icon: const Icon(Icons.alarm_rounded, size: 16),
                          label: const Text('Pengingat'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryText,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
    );
  }

  Widget _buildMotorIcon() {
    return Container(
      width: 64,
      height: 54,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.peach, width: 1.2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: MotorcycleImage(
        brand: brand,
        model: model,
        photoUrl: photoUrl,
        fit: BoxFit.contain,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildDarkSpecPill({
    required String label,
    Color? dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (dotColor != null) ...<Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 0.9),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicensePlateBadge(String plate) {
    return Container(
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
        AppFormatters.licensePlate(plate),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.charcoalDark,
          letterSpacing: 0.8,
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// CustomPainter untuk menggambar busur speedometer instrumen servis motor (PRD 6)
class SpeedometerArcPainter extends CustomPainter {
  final double progress; // 0.0 sampai 1.0
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const SpeedometerArcPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 5.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Busur latar belakang (180 derajat / pi radian, dari kiri ke kanan)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, trackPaint);

    // Busur nilai aktif proporsional
    if (progress > 0.0) {
      final activePaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(rect, math.pi, sweepAngle, false, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SpeedometerArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
