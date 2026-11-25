import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_state_provider.dart';
import '../../features/notifications/presentation/notifications_providers.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';

class _NavItem {
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool hasBadge;

  const _NavItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.hasBadge = false,
  });
}

/// Floating Bottom Navigation Bar terpusat MotoCare (N-03)
/// Desain melayang berkarakter "Bengkel yang Ramah" selaras Figma:
/// - Margin horizontal 16, bawah 12 + SafeArea
/// - Tinggi 64, radius sudut 28 (AppTokens.radiusNav)
/// - Latar Charcoal Hijau Otomotif (#243830), bayangan hangat lembut (AppShadows.high)
/// - Border 1 px tint charcoal gelap (#1B2B25)
/// - Item aktif: Pil Krem Kertas (#FFF7EC) dengan ikon & label Terakota (#B84A28)
/// - Item tidak aktif: Ikon outline & label krem pucat (#D9CEC1)
/// - Otomatis tersembunyi saat keyboard virtual terbuka
/// - Bebas overflow pada font accessibility 130%-150% (FittedBox & Flexible)
/// - Konfigurasi tab dinamis per peran (Pelanggan, Mekanik, Admin)
class AppBottomNav extends ConsumerWidget {
  final int? currentIndex;
  final String? currentLocation;
  final ValueChanged<int>? onTap;
  final int unreadNotificationsCount;

  const AppBottomNav({
    super.key,
    this.currentIndex,
    this.currentLocation,
    this.onTap,
    this.unreadNotificationsCount = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Sembunyikan otomatis jika keyboard virtual sedang terbuka (N-03)
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight > 0) {
      return const SizedBox.shrink();
    }

    final user = ref.watch(currentUserProvider);
    final isMechanic = user?.isMechanic ?? false;
    final isAdmin = user?.isAdmin ?? false;

    // Ambil jumlah notifikasi belum dibaca jika tidak dipassing eksplisit
    final int notifCount = unreadNotificationsCount > 0
        ? unreadNotificationsCount
        : ref.watch(unreadNotificationCountProvider);

    // 2. Daftar navigasi modular berbasis peran
    final List<_NavItem> items;
    if (isMechanic) {
      // Peran Mekanik Mitra: 4 Tab
      items = <_NavItem>[
        const _NavItem(
          route: '/home',
          label: 'Tugas',
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_rounded,
        ),
        const _NavItem(
          route: '/workshops',
          label: 'Bengkel',
          icon: Icons.storefront_outlined,
          activeIcon: Icons.storefront_rounded,
        ),
        const _NavItem(
          route: '/tutorials',
          label: 'Panduan',
          icon: Icons.play_circle_outline_rounded,
          activeIcon: Icons.play_circle_rounded,
        ),
        const _NavItem(
          route: '/profile',
          label: 'Profil',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
        ),
      ];
    } else if (isAdmin) {
      // Peran Administrator: 4 Tab
      items = const <_NavItem>[
        _NavItem(
          route: '/home',
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
        ),
        _NavItem(
          route: '/workshops',
          label: 'Bengkel',
          icon: Icons.storefront_outlined,
          activeIcon: Icons.storefront_rounded,
        ),
        _NavItem(
          route: '/tutorials',
          label: 'Edukasi',
          icon: Icons.play_circle_outline_rounded,
          activeIcon: Icons.play_circle_rounded,
        ),
        _NavItem(
          route: '/profile',
          label: 'Profil',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
        ),
      ];
    } else {
      // Peran Pelanggan / Pengguna Motor (Opsi A Figma: 4 Tab)
      items = <_NavItem>[
        const _NavItem(
          route: '/home',
          label: 'Beranda',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
        ),
        _NavItem(
          route: '/help',
          label: 'Aktivitas',
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long_rounded,
          hasBadge: notifCount > 0,
        ),
        const _NavItem(
          route: '/motors',
          label: 'Motor',
          icon: Icons.two_wheeler_outlined,
          activeIcon: Icons.two_wheeler_rounded,
        ),
        const _NavItem(
          route: '/profile',
          label: 'Akun',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
        ),
      ];
    }

    String? path = currentLocation;
    if (path == null) {
      try {
        path = GoRouterState.of(context).matchedLocation;
      } catch (_) {
        path = null;
      }
    }

    final bool reduceMotion = AppMotion.shouldDisableAnimation(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final bool isSelected = path != null
                  ? (path == item.route ||
                      (item.route != '/home' && path.startsWith(item.route)))
                  : (currentIndex == index);

              return Expanded(
                child: _buildNavItem(
                  context,
                  index: index,
                  item: item,
                  isSelected: isSelected,
                  reduceMotion: reduceMotion,
                  badgeCount: item.hasBadge ? notifCount : 0,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required _NavItem item,
    required bool isSelected,
    required bool reduceMotion,
    required int badgeCount,
  }) {
    final Duration duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Semantics(
      selected: isSelected,
      button: true,
      label: 'Tab ${item.label}',
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (onTap != null) {
            onTap!(index);
          } else {
            context.go(item.route);
          }
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.peach.withValues(alpha: 0.3),
        highlightColor: Colors.transparent,
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  AnimatedScale(
                    scale: isSelected ? 1.05 : 1.0,
                    duration: duration,
                    curve: Curves.easeOutBack,
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      size: 24,
                      color: isSelected
                          ? AppColors.action
                          : AppColors.navInactive,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -3,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.action,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.action
                          : AppColors.navInactive,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
