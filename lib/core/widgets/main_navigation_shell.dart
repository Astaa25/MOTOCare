import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_bottom_nav.dart';

/// Shell Navigasi Terpusat MotoCare (N-02)
/// Membungkus tab utama dalam AppBackground dan Floating Bottom Nav tunggal
class MainNavigationShell extends StatelessWidget {
  final Widget child;
  final String currentLocation;

  const MainNavigationShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: AppBottomNav(
        currentLocation: currentLocation,
      ),
    );
  }
}

