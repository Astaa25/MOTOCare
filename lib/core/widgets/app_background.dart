import 'package:flutter/material.dart';

/// Latar belakang berlapis bernuansa bengkel modern & editorial MotoCare.
/// Menghilangkan kesan polos dengan perpaduan gradasi krem hangat,
/// cahaya atmosfer dual-tone (coral & mint), serta kontur garis jalan halus.
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool enableWarmGlow;

  const AppBackground({
    super.key,
    required this.child,
    this.enableWarmGlow = true,
  });

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: <double>[0.0, 0.45, 1.0],
    colors: <Color>[
      Color(0xFFFFF5EB), // Krem hangat bengkel di sudut atas
      Color(0xFFFFFAF4), // Transisi lembut tengah
      Color(0xFFFFFCF9), // Off-white bersih di bawah
    ],
  );

  static const BoxDecoration decoration = BoxDecoration(
    color: Color(0xFFFFFCF9),
    gradient: warmGradient,
  );

  @override
  Widget build(BuildContext context) {
    if (!enableWarmGlow) {
      return Container(
        decoration: decoration,
        child: child,
      );
    }

    return Container(
      decoration: decoration,
      child: CustomPaint(
        painter: const _AtelierContourPainter(),
        child: child,
      ),
    );
  }
}

/// Painter atmosfer hangat + kontur lintasan halus agar latar tidak datar/polos.
class _AtelierContourPainter extends CustomPainter {
  const _AtelierContourPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Cahaya radial Coral hangat di pojok kanan atas
    final coralGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.9, -0.85),
        radius: 0.95,
        colors: <Color>[
          const Color(0xFFFF7966).withValues(alpha: 0.10),
          const Color(0xFFFDE8E1).withValues(alpha: 0.05),
          const Color(0xFFFFFCF9).withValues(alpha: 0.0),
        ],
        stops: const <double>[0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), coralGlow);

    // 2. Cahaya radial Mint lembut di pojok kiri bawah
    final mintGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.95, 0.85),
        radius: 0.85,
        colors: <Color>[
          const Color(0xFF173C3B).withValues(alpha: 0.045),
          const Color(0xFFE2F1ED).withValues(alpha: 0.06),
          const Color(0xFFFFFCF9).withValues(alpha: 0.0),
        ],
        stops: const <double>[0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), mintGlow);

    // 3. Garis kontur busur jalan otomotif yang sangat halus sebagai karakter visual
    final arcPaint = Paint()
      ..color = const Color(0xFFC74635).withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final tealArcPaint = Paint()
      ..color = const Color(0xFF173C3B).withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final topRightPath = Path()
      ..moveTo(size.width * 0.42, 0)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.14, size.width, size.height * 0.24);
    canvas.drawPath(topRightPath, arcPaint);

    final topRightPath2 = Path()
      ..moveTo(size.width * 0.56, 0)
      ..quadraticBezierTo(size.width * 0.80, size.height * 0.10, size.width, size.height * 0.17);
    canvas.drawPath(topRightPath2, tealArcPaint);

    final bottomLeftPath = Path()
      ..moveTo(0, size.height * 0.74)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.86, size.width * 0.52, size.height);
    canvas.drawPath(bottomLeftPath, tealArcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
