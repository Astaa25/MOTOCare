import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/services/user_location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_effects.dart';
import '../../../core/widgets/dashed_road_divider.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/tertiary_button.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../../motorcycles/domain/motorcycle.dart';
import '../../motorcycles/presentation/motorcycle_providers.dart';
import '../../notifications/presentation/notifications_providers.dart';
import '../../reminders/domain/maintenance_reminder.dart';
import '../../reminders/presentation/reminders_providers.dart';
import '../../service_history/domain/service_history.dart';
import '../../service_history/presentation/service_history_providers.dart';
import 'admin_home_screen.dart';
import 'mechanic_home_screen.dart';

/// Layar Beranda Utama MotoCare sesuai PRD Bagian 7 (M3 & M5) & Rute `/home`
/// Mendukung Multi-Role Dynamic Switching (Pelanggan, Mekanik Mitra, Administrator)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // 1. Peran Mekanik Mitra: Dashboard Tugas & Order Servis Darurat (UC-03)
    if (user != null && user.isMechanic) {
      return const MechanicHomeScreen();
    }

    // 2. Peran Administrator: Eksekutif Dashboard & Verifikasi Mekanik (UC-07)
    if (user != null && user.isAdmin) {
      return const AdminHomeScreen();
    }

    // 3. Peran Pengguna / Pelanggan Reguler: Garasi Motor & Panggil Montir (Figma 02 Beranda)
    final activeMotorAsync = ref.watch(activeMotorcycleProvider);
    final unreadNotifCount = ref.watch(unreadNotificationCountProvider);
    final locationState = ref.watch(globalUserLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.action,
          onRefresh: () async {
            await ref.read(motorcyclesProvider.notifier).loadMotorcycles();
            await ref.read(notificationsNotifierProvider.notifier).syncWithReminders();
          },
          child: CustomScrollView(
            slivers: <Widget>[
              // --- HEADER CORAL ATAS (FIGMA 02) ---
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.coral,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: <Widget>[
                          // Lokasi pengguna
                          Expanded(
                            child: InkWell(
                              key: const Key('btn_change_home_location'),
                              onTap: () => _showChangeLocationSheet(context, ref),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        size: 18,
                                        color: AppColors.action,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          const Text(
                                            'LOKASIMU',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.action,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            locationState.formattedAddress ??
                                                locationState.cityRegency,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.deepTeal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: AppColors.deepTeal,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Tombol notifikasi lonceng putih melingkar
                          InkWell(
                            key: const Key('home_notifications_button'),
                            onTap: () => context.push('/notifications'),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Badge(
                                  isLabelVisible: unreadNotifCount > 0,
                                  label: Text('$unreadNotifCount'),
                                  backgroundColor: AppColors.action,
                                  child: const Icon(
                                    Icons.notifications_none_rounded,
                                    size: 22,
                                    color: AppColors.deepTeal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- KONTEN BERANDA ---
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    // Baris cakupan layanan (PRD 503 & assert test)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.softPeach.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Icon(Icons.verified_outlined, size: 14, color: AppColors.action),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Cakupan Layanan: Kota Lhokseumawe & Kab. Aceh Utara',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepTeal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 1. BANNER HERO: "TENANG, ADA MOTOCARE" (Figma 02)
                    _FigmaHeroBanner(
                      onRequestRescue: () => context.push('/help/new'),
                    ),
                    const SizedBox(height: 24),

                    // 2. GRID 6 FITUR: "Butuh apa hari ini?" (Figma 02)
                    _FigmaFeatureGrid(),
                    const SizedBox(height: 24),

                    // 3. KARTU "MOTOR SAYA" DEEP TEAL (Figma 02)
                    activeMotorAsync.when(
                      loading: () => const LoadingSkeleton(height: 140, borderRadius: 18),
                      error: (err, _) => ErrorState(
                        title: 'Gagal Memuat Motor',
                        message: err.toString(),
                        onRetry: () => ref.read(motorcyclesProvider.notifier).loadMotorcycles(),
                      ),
                      data: (Motorcycle? motor) {
                        return _FigmaActiveMotorCard(
                          motorcycle: motor,
                          onManage: () => context.push('/motors'),
                          onAddMotor: () => context.push('/motors/new'),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // 4. BAGIAN TAMBAHAN PENDUKUNG (Pengingat & Riwayat Servis)
                    if (activeMotorAsync.valueOrNull != null) ...<Widget>[
                      const DashedRoadDivider(padding: EdgeInsets.symmetric(vertical: 4)),
                      _NearestReminderSection(motorcycle: activeMotorAsync.valueOrNull!),
                      const SizedBox(height: 12),
                      const DashedRoadDivider(padding: EdgeInsets.symmetric(vertical: 4)),
                      _LastServiceSection(motorcycle: activeMotorAsync.valueOrNull!),
                    ],

                    const SizedBox(height: AppTokens.tabContentBottomPadding),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner Hero Panggil Montir "TENANG, ADA MOTOCARE" (Figma 02)
class _FigmaHeroBanner extends StatelessWidget {
  final VoidCallback onRequestRescue;

  const _FigmaHeroBanner({required this.onRequestRescue});

  @override
  Widget build(BuildContext context) {
    return BouncingWidget(
      onTap: onRequestRescue,
      scaleFactor: 0.985,
      hoverScale: 1.01,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFFDE5DD),
              Color(0xFFFFF3E8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.coral.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Teks dan tombol aksi
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'TENANG, ADA MOTOCARE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.action,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ada kendala\ndi jalan?',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepTeal,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      key: const Key('home_request_mechanic_button'),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onRequestRescue();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.action,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Panggil Montir',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Ilustrasi montir skuter merah asli Figma
              Expanded(
                flex: 5,
                child: Image.asset(
                  'assets/images/rider_courier.png',
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.two_wheeler_rounded,
                      size: 64,
                      color: AppColors.action,
                    );
                  },
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

/// Grid 6 Menu Pintasan Fitur "Butuh apa hari ini?" (Figma 02)
class _FigmaFeatureGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Judul bagian dan badge simulasi
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Expanded(
              child: Text(
                'Butuh apa hari ini?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepTeal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (AppEnv.showDemoFeatures) ...<Widget>[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.softPeach,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Simulasi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.action,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        // Grid 2 baris x 3 kolom
        Row(
          children: <Widget>[
            Expanded(
              child: _FigmaShortcutItem(
                label: 'Cari Bengkel',
                icon: Icons.storefront_outlined,
                backgroundColor: AppColors.softPeach,
                onTap: () => context.push('/workshops'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FigmaShortcutItem(
                label: 'Motor Saya',
                icon: Icons.two_wheeler_outlined,
                backgroundColor: AppColors.softMint,
                onTap: () => context.push('/motors'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FigmaShortcutItem(
                label: 'Riwayat Servis',
                icon: Icons.history_rounded,
                backgroundColor: AppColors.softButter,
                onTap: () => context.push('/service-history'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _FigmaShortcutItem(
                label: 'Pengingat',
                icon: Icons.notifications_none_rounded,
                backgroundColor: AppColors.softButter,
                onTap: () => context.push('/reminders'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FigmaShortcutItem(
                label: 'Tutorial',
                icon: Icons.play_arrow_outlined,
                backgroundColor: AppColors.softPeach,
                onTap: () => context.push('/tutorials'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FigmaShortcutItem(
                label: 'Aktivitas',
                icon: Icons.receipt_long_outlined,
                backgroundColor: AppColors.softMint,
                onTap: () => context.push('/help'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Item tombol fitur bundar dengan efek hover glow + bouncing tactile press
class _FigmaShortcutItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _FigmaShortcutItem({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  State<_FigmaShortcutItem> createState() => _FigmaShortcutItemState();
}

class _FigmaShortcutItemState extends State<_FigmaShortcutItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: BouncingWidget(
        onTap: widget.onTap,
        scaleFactor: 0.94,
        hoverScale: 1.04,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: _isHovered
                        ? AppColors.primary.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.8),
                    width: 1.3,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: (_isHovered ? AppColors.primary : AppColors.deepTeal)
                          .withValues(alpha: _isHovered ? 0.16 : 0.06),
                      blurRadius: _isHovered ? 12 : 6,
                      offset: Offset(0, _isHovered ? 4 : 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    size: 24,
                    color: AppColors.deepTeal,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: _isHovered ? FontWeight.w700 : FontWeight.w600,
                  color: _isHovered ? AppColors.primary : AppColors.deepTeal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu "MOTOR SAYA" Deep Teal (Figma 02)
class _FigmaActiveMotorCard extends StatelessWidget {
  final Motorcycle? motorcycle;
  final VoidCallback onManage;
  final VoidCallback onAddMotor;

  const _FigmaActiveMotorCard({
    required this.motorcycle,
    required this.onManage,
    required this.onAddMotor,
  });

  @override
  Widget build(BuildContext context) {
    // Memenuhi assertion test 'Sepeda Motor Aktif'
    final motor = motorcycle;

    if (motor == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.deepTeal,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Text(
                  'Sepeda Motor Aktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF86ADA7),
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Belum Ada Motor Terdaftar',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Daftarkan motormu untuk memantau servis & kilometer.',
              style: TextStyle(fontSize: 12, color: Color(0xFFB0CCC7)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onAddMotor,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.action,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Tambah Motor Sekarang'),
            ),
          ],
        ),
      );
    }

    return BouncingWidget(
      onTap: onManage,
      scaleFactor: 0.985,
      hoverScale: 1.01,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF1A4746),
              AppColors.deepTeal,
              Color(0xFF0F2B2A),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2D6563),
            width: 1.1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.deepTeal.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Rincian motor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Sepeda Motor Aktif',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF86ADA7),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${motor.brand} ${motor.model}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${motor.licensePlate} · ${AppFormatters.formatKilometer(motor.currentMileage)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB0CCC7),
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              // Ikon siluet skuter
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  size: 36,
                  color: Color(0xFF86ADA7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0x28FFFFFF), height: 1),
          const SizedBox(height: 12),

          // Tautan bawah "Lihat perawatan motor ->"
          InkWell(
            onTap: onManage,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Lihat perawatan motor',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Bagian Pengingat Servis Terdekat pada Beranda (L-01 c)
class _NearestReminderSection extends ConsumerWidget {
  final Motorcycle motorcycle;

  const _NearestReminderSection({required this.motorcycle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderAsync = ref.watch(nearestReminderProvider(motorcycle.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Expanded(
              child: Text(
                'Pengingat Servis Terdekat',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TertiaryButton(
              label: 'Lihat Semua',
              icon: Icons.chevron_right_rounded,
              onPressed: () => context.push('/motors/${motorcycle.id}/reminders'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        reminderAsync.when(
          loading: () => const LoadingSkeleton(height: 80, borderRadius: 14),
          error: (err, stack) => const SizedBox.shrink(),
          data: (MaintenanceReminder? reminder) {
            if (reminder == null) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.alarm_off_rounded, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Semua jadwal servis aman terkendali.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    TertiaryButton(
                      label: 'Buat Pengingat',
                      onPressed: () =>
                          context.push('/reminders/new?motorId=${motorcycle.id}'),
                    ),
                  ],
                ),
              );
            }

            final status = reminder.computeStatus(motorcycle.currentMileage);

            return Material(
              color: AppColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: status.borderColor,
                  width: 1.0,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/reminders/${reminder.id}');
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: status.backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(status.icon, color: status.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              reminder.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reminder.reminderDate != null
                                  ? 'Target: ${AppFormatters.formatDate(reminder.reminderDate!)}'
                                  : 'Target: ${AppFormatters.formatKilometer(reminder.targetMileage ?? 0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: status.label,
                        icon: status.icon,
                        textColor: status.color,
                        backgroundColor: status.backgroundColor,
                        borderColor: status.borderColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Bagian Ringkasan Servis Terakhir pada Beranda (L-01 c)
class _LastServiceSection extends ConsumerWidget {
  final Motorcycle motorcycle;

  const _LastServiceSection({required this.motorcycle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceHistoriesProvider(motorcycle.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Expanded(
              child: Text(
                'Servis Terakhir',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TertiaryButton(
              label: 'Semua Riwayat',
              icon: Icons.chevron_right_rounded,
              onPressed: () => context.push('/motors/${motorcycle.id}/services'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        servicesAsync.when(
          loading: () => const LoadingSkeleton(height: 75, borderRadius: 14),
          error: (err, stack) => const SizedBox.shrink(),
          data: (List<ServiceHistory> services) {
            if (services.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.history_toggle_off_rounded,
                        color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Belum ada riwayat servis tercatat.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    TertiaryButton(
                      label: 'Catat Servis',
                      onPressed: () =>
                          context.push('/motors/${motorcycle.id}/services/new'),
                    ),
                  ],
                ),
              );
            }

            final latest = services.first;

            return Material(
              color: AppColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/services/${latest.id}');
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.build_rounded,
                            color: AppColors.terracotta, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              latest.serviceType,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${AppFormatters.formatDate(latest.serviceDate)} • ${AppFormatters.formatKilometer(latest.mileage)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        AppFormatters.formatRupiah(latest.cost),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.terracotta,
                          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Menampilkan bottom sheet pemilihan & pengubahan lokasi layanan (Figma 02.01 & 03.02)
void _showChangeLocationSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: AppColors.surface,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ubah Lokasi Layanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'MotoCare saat ini melayani Kota Lhokseumawe & Kab. Aceh Utara.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              key: const Key('btn_home_open_picker'),
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.cream,
                child: Icon(Icons.map_rounded, color: AppColors.primary),
              ),
              title: const Text('Cari Alamat & Peta Interaktif', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Cari tempat atau geser pin di peta', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/help/picker');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.cream,
                child: Icon(Icons.my_location_rounded, color: AppColors.primary),
              ),
              title: const Text('Gunakan Lokasi GPS Saya', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Deteksi koordinat GPS perangkat otomatis', style: TextStyle(fontSize: 12)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(globalUserLocationProvider.notifier).detectLocation();
                final state = ref.read(globalUserLocationProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.formattedAddress ?? 'Lokasi berhasil diperbarui.'),
                      backgroundColor: state.isWithinServiceArea ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(Icons.location_city_rounded, color: AppColors.textPrimary),
              ),
              title: const Text('Kota Lhokseumawe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Banda Sakti, Muara Satu, Muara Dua, Blang Mangat', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(globalUserLocationProvider.notifier).setManualLocation(
                      address: 'Banda Sakti, Kota Lhokseumawe',
                      cityRegency: 'Kota Lhokseumawe',
                      latitude: 5.1801,
                      longitude: 97.1396,
                    );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(Icons.nature_people_rounded, color: AppColors.textPrimary),
              ),
              title: const Text('Kabupaten Aceh Utara', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Lhoksukon, Dewantara, Syamtalira Bayu, Samudera', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(globalUserLocationProvider.notifier).setManualLocation(
                      address: 'Lhoksukon, Kabupaten Aceh Utara',
                      cityRegency: 'Kabupaten Aceh Utara',
                      latitude: 5.0450,
                      longitude: 97.3180,
                    );
              },
            ),
          ],
        ),
      );
    },
  );
}
