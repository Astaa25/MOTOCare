import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// Komponen Shimmer Loading Skeleton MotoCare dengan animasi sweep gradien halus
/// Berfungsi sebagai placeholder visual saat halaman memuat atau jaringan lambat (lag)
class LoadingSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const LoadingSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.shape = BoxShape.rectangle,
  });

  /// Factory untuk avatar / ikon lingkaran
  factory LoadingSkeleton.circle({required double size}) => LoadingSkeleton(
        width: size,
        height: size,
        shape: BoxShape.circle,
      );

  /// Factory untuk baris kartu skeleton
  static Widget cardList({int count = 3}) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                LoadingSkeleton(width: 44, height: 44, borderRadius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      LoadingSkeleton(width: 140, height: 16),
                      SizedBox(height: 6),
                      LoadingSkeleton(width: 90, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            LoadingSkeleton(height: 14),
            SizedBox(height: 8),
            LoadingSkeleton(width: 180, height: 14),
          ],
        ),
      ),
    );
  }

  /// Skeleton Lengkap untuk Halaman Beranda (Home Screen)
  static Widget homePage() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        // Banner Wilayah
        const LoadingSkeleton(height: 44, borderRadius: 12),
        const SizedBox(height: 16),

        // Section Title: Motor Aktif
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            LoadingSkeleton(width: 150, height: 20),
            LoadingSkeleton(width: 80, height: 16),
          ],
        ),
        const SizedBox(height: 8),

        // Kartu Motor Skeleton
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  LoadingSkeleton(width: 50, height: 50, borderRadius: 12),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        LoadingSkeleton(width: 160, height: 18),
                        SizedBox(height: 6),
                        LoadingSkeleton(width: 100, height: 13),
                      ],
                    ),
                  ),
                  LoadingSkeleton(width: 60, height: 24, borderRadius: 8),
                ],
              ),
              SizedBox(height: 16),
              LoadingSkeleton(height: 14),
              SizedBox(height: 8),
              LoadingSkeleton(width: 200, height: 14),
              SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(child: LoadingSkeleton(height: 36, borderRadius: 8)),
                  SizedBox(width: 8),
                  Expanded(child: LoadingSkeleton(height: 36, borderRadius: 8)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tombol Panggil Montir Skeleton
        const LoadingSkeleton(height: 52, borderRadius: 14),
        const SizedBox(height: 20),

        // Pengingat Terdekat Skeleton
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            LoadingSkeleton(width: 180, height: 18),
            LoadingSkeleton(width: 70, height: 14),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: <Widget>[
              LoadingSkeleton(width: 36, height: 36, borderRadius: 8),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    LoadingSkeleton(width: 140, height: 15),
                    SizedBox(height: 6),
                    LoadingSkeleton(width: 100, height: 12),
                  ],
                ),
              ),
              LoadingSkeleton(width: 50, height: 22, borderRadius: 6),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Grid Menu Layanan Skeleton
        const LoadingSkeleton(width: 170, height: 20),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: List.generate(
            4,
            (_) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  LoadingSkeleton(width: 36, height: 36, borderRadius: 10),
                  Spacer(),
                  LoadingSkeleton(width: 110, height: 14),
                  SizedBox(height: 6),
                  LoadingSkeleton(width: 75, height: 11),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Skeleton Lengkap untuk Katalog Bengkel
  static Widget workshopList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Foto Bengkel Placeholder
            LoadingSkeleton(height: 130, borderRadius: 16),
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      LoadingSkeleton(width: 160, height: 16),
                      LoadingSkeleton(width: 55, height: 20, borderRadius: 6),
                    ],
                  ),
                  SizedBox(height: 8),
                  LoadingSkeleton(width: 220, height: 12),
                  SizedBox(height: 6),
                  LoadingSkeleton(width: 140, height: 12),
                  SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      LoadingSkeleton(width: 80, height: 24, borderRadius: 8),
                      SizedBox(width: 8),
                      LoadingSkeleton(width: 110, height: 24, borderRadius: 8),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton Lengkap untuk Halaman Motor Saya
  static Widget motorcycleList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                LoadingSkeleton(width: 54, height: 54, borderRadius: 14),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      LoadingSkeleton(width: 160, height: 18),
                      SizedBox(height: 6),
                      LoadingSkeleton(width: 110, height: 13),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                LoadingSkeleton(width: 100, height: 14),
                LoadingSkeleton(width: 80, height: 14),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(child: LoadingSkeleton(height: 38, borderRadius: 10)),
                SizedBox(width: 10),
                Expanded(child: LoadingSkeleton(height: 38, borderRadius: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton Lengkap untuk Riwayat Servis
  static Widget serviceHistoryList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        // Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LoadingSkeleton(width: 130, height: 14),
              SizedBox(height: 10),
              LoadingSkeleton(width: 190, height: 26),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  LoadingSkeleton(width: 100, height: 12),
                  LoadingSkeleton(width: 80, height: 12),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const LoadingSkeleton(width: 140, height: 18),
        const SizedBox(height: 12),

        // List Servis Items
        ...List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    LoadingSkeleton(width: 130, height: 16),
                    LoadingSkeleton(width: 90, height: 16),
                  ],
                ),
                SizedBox(height: 8),
                LoadingSkeleton(width: 220, height: 13),
                SizedBox(height: 6),
                LoadingSkeleton(width: 120, height: 11),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Skeleton Lengkap untuk Daftar Pengingat Servis
  static Widget reminderList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                LoadingSkeleton(width: 40, height: 40, borderRadius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      LoadingSkeleton(width: 150, height: 16),
                      SizedBox(height: 6),
                      LoadingSkeleton(width: 110, height: 12),
                    ],
                  ),
                ),
                LoadingSkeleton(width: 70, height: 24, borderRadius: 8),
              ],
            ),
            SizedBox(height: 14),
            LoadingSkeleton(height: 8, borderRadius: 4),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                LoadingSkeleton(width: 100, height: 11),
                LoadingSkeleton(width: 80, height: 11),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton Lengkap untuk Katalog Tutorial Video
  static Widget tutorialGrid() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LoadingSkeleton(height: 170, borderRadius: 16),
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      LoadingSkeleton(width: 70, height: 20, borderRadius: 6),
                      SizedBox(width: 8),
                      LoadingSkeleton(width: 60, height: 20, borderRadius: 6),
                    ],
                  ),
                  SizedBox(height: 10),
                  LoadingSkeleton(height: 16),
                  SizedBox(height: 6),
                  LoadingSkeleton(width: 180, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton Lengkap untuk Pusat Notifikasi
  static Widget notificationList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LoadingSkeleton(width: 38, height: 38, borderRadius: 10),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  LoadingSkeleton(width: 150, height: 15),
                  SizedBox(height: 6),
                  LoadingSkeleton(height: 12),
                  SizedBox(height: 4),
                  LoadingSkeleton(width: 110, height: 12),
                  SizedBox(height: 8),
                  LoadingSkeleton(width: 70, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton Lengkap untuk Detail Panggilan Montir
  static Widget helpRequestDetail() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        // Status Banner
        const LoadingSkeleton(height: 84, borderRadius: 16),
        const SizedBox(height: 16),

        // Stepper Progress
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            children: <Widget>[
              LoadingSkeleton(height: 18),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  LoadingSkeleton(width: 70, height: 12),
                  LoadingSkeleton(width: 70, height: 12),
                  LoadingSkeleton(width: 70, height: 12),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Profil Mekanik Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: <Widget>[
              LoadingSkeleton(width: 50, height: 50, borderRadius: 12),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    LoadingSkeleton(width: 140, height: 16),
                    SizedBox(height: 6),
                    LoadingSkeleton(width: 180, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Detail Kerusakan & Lokasi Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LoadingSkeleton(width: 120, height: 16),
              SizedBox(height: 10),
              LoadingSkeleton(height: 14),
              SizedBox(height: 6),
              LoadingSkeleton(width: 200, height: 14),
              SizedBox(height: 14),
              LoadingSkeleton(width: 120, height: 16),
              SizedBox(height: 10),
              LoadingSkeleton(height: 14),
            ],
          ),
        ),
      ],
    );
  }

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (!AppMotion.isTestEnvironment) {
      _controller.repeat(reverse: true);
    }

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.shouldDisableAnimation(context)) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else if (!_controller.isAnimating && !AppMotion.isTestEnvironment) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnim = AppMotion.shouldDisableAnimation(context);

    if (disableAnim) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          shape: widget.shape,
          color: AppColors.border.withValues(alpha: 0.5),
          borderRadius: widget.shape == BoxShape.rectangle
              ? BorderRadius.circular(widget.borderRadius)
              : null,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            color: AppColors.border.withValues(alpha: _animation.value),
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(widget.borderRadius)
                : null,
          ),
        );
      },
    );
  }
}
