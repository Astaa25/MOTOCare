import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/motocare_osm_map.dart';

/// Widget pratinjau titik peta kecil interaktif berbasis OpenStreetMap (Figma 03.02)
class MiniMapPickerPreview extends StatelessWidget {
  const MiniMapPickerPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.isWithinServiceArea,
    this.height = 180,
    this.onLocationChanged,
  });

  final double latitude;
  final double longitude;
  final String address;
  final bool isWithinServiceArea;
  final double height;
  final void Function(double newLat, double newLng)? onLocationChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWithinServiceArea ? AppColors.peach : AppColors.error,
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          MotocarePickerOsmMap(
            latitude: latitude,
            longitude: longitude,
            onLocationChanged: onLocationChanged,
          ),

          // Lencana Status Cakupan Wilayah (Atas Kiri)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isWithinServiceArea
                    ? AppColors.emerald.withValues(alpha: 0.95)
                    : AppColors.error.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    isWithinServiceArea ? Icons.check_circle_rounded : Icons.warning_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isWithinServiceArea
                        ? 'Wilayah Terjangkau'
                        : 'Di Luar Jangkauan Layanan',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Label Koordinat (Bawah Kanan)
          Positioned(
            bottom: 8,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
