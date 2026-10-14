import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Navigasi bar bawah MotoCare 5 tab sesuai PRD 4.3 & Bagian 8
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadNotificationsCount;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadNotificationsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Beranda',
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Icons.two_wheeler_outlined,
                activeIcon: Icons.two_wheeler_rounded,
                label: 'Motor',
              ),
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.build_outlined,
                activeIcon: Icons.build_rounded,
                label: 'Bengkel',
              ),
              _buildNavItem(
                context,
                index: 3,
                icon: Icons.play_circle_outline_rounded,
                activeIcon: Icons.play_circle_rounded,
                label: 'Tutorial',
              ),
              _buildNavItem(
                context,
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;
    final Color itemColor = isSelected ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        label: 'Tab $label',
        child: InkWell(
          onTap: () => onTap(index),
          splashColor: AppColors.cream,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: itemColor,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: itemColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
