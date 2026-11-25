import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Pemisah seksi bertema marka jalan putus-putus ala otomotif (PRD 6 & Motif Khas Motor)
/// Menggantikan garis lurus abu generik dengan estetika aspal jalanan.
class DashedRoadDivider extends StatelessWidget {
  final double height;
  final double dashWidth;
  final double dashSpace;
  final double thickness;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const DashedRoadDivider({
    super.key,
    this.height = 16.0,
    this.dashWidth = 8.0,
    this.dashSpace = 5.0,
    this.thickness = 1.5,
    this.color,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? AppColors.border;

    return Padding(
      padding: padding,
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boxWidth = constraints.constrainWidth();
            if (boxWidth <= 0 || boxWidth.isInfinite) {
              return const SizedBox.shrink();
            }

            final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();

            return CustomPaint(
              size: Size(boxWidth, height),
              painter: _DashedLinePainter(
                dashWidth: dashWidth,
                dashSpace: dashSpace,
                dashCount: dashCount,
                thickness: thickness,
                color: dividerColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final double dashWidth;
  final double dashSpace;
  final int dashCount;
  final double thickness;
  final Color color;

  const _DashedLinePainter({
    required this.dashWidth,
    required this.dashSpace,
    required this.dashCount,
    required this.thickness,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    double startX = (size.width - (dashCount * dashWidth + (dashCount - 1) * dashSpace)) / 2;
    if (startX < 0) startX = 0;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(startX + dashWidth, centerY),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}

