import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// Komponen Shimmer Loading Skeleton MotoCare sesuai PRD 4.3 & 4.5
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
                LoadingSkeleton(width: 40, height: 40, borderRadius: 10),
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
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
