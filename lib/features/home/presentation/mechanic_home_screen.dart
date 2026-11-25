import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/env.dart';
import '../../../core/services/live_tracking_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_effects.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../../help_requests/domain/request_status.dart';
import '../../help_requests/domain/service_request.dart';
import '../../help_requests/presentation/widgets/mini_map_picker_preview.dart';

/// Provider status ketersediaan mekanik (Online / Siaga vs Offline / Istirahat)
final mechanicIsOnlineProvider = StateProvider<bool>((ref) => true);

/// Dashboard Khusus Peran Mekanik Mitra MotoCare (Sesuai UC-03 & Sequence Diagram)
class MechanicHomeScreen extends ConsumerStatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  ConsumerState<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends ConsumerState<MechanicHomeScreen> {
  // Simulasi order darurat aktif yang ditugaskan ke mekanik ini
  ServiceRequest? _activeOrder;
  bool _isSharingGps = true;

  @override
  void initState() {
    super.initState();
    _loadSampleOrder();
  }

  void _loadSampleOrder() {
    _activeOrder = ServiceRequest(
      id: 'req-live-demo-01',
      userId: 'user-001',
      motorcycleId: 'motor-001',
      motorcycleName: 'Honda Vario 160 (2023)',
      issueCategory: 'Mesin Mogok',
      issueDescription:
          'Motor tiba-tiba mati mendadak saat melintas di dekat Simpang Elak. Tidak bisa distarter elektrik maupun engkol.',
      latitude: 5.1782,
      longitude: 97.1390,
      addressText: 'Jl. Merdeka Barat No. 45, Simpang Elak, Banda Sakti, Kota Lhokseumawe',
      cityRegency: 'Kota Lhokseumawe',
      landmark: 'Dekat Tugu Simpang Elak, samping toko kelontong',
      contactPhone: '081269112233',
      status: RequestStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      expiresAt: DateTime.now().add(const Duration(minutes: 12)),
      isDemo: true,
    );
  }

  Future<void> _handleAccept() async {
    final costController = TextEditingController(text: '75000');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Terima Panggilan Montir',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Masukkan estimasi biaya jasa pemeriksaan & kedatangan ke lokasi (Rp):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Rp ',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Konfirmasi Terima'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && _activeOrder != null) {
      setState(() {
        _activeOrder = _activeOrder!.copyWith(status: RequestStatus.accepted);
      });
      HapticFeedback.heavyImpact();
      AppToast.showSuccess(context, 'Panggilan diterima! Bersiaplah menuju lokasi pengendara.');
    }
  }

  void _handleReject() {
    setState(() {
      _activeOrder = null;
    });
    AppToast.showError(context, 'Panggilan ditolak. Permintaan akan dialihkan ke mekanik lain.');
  }

  void _advanceToOtw() {
    setState(() {
      _activeOrder = _activeOrder!.copyWith(status: RequestStatus.onTheWay);
    });
    HapticFeedback.mediumImpact();
    AppToast.showSuccess(context, 'Status: Sedang dalam perjalanan ke titik penjemputan.');
  }

  void _advanceToWork() {
    setState(() {
      _activeOrder = _activeOrder!.copyWith(status: RequestStatus.inProgress);
    });
    HapticFeedback.mediumImpact();
    AppToast.showSuccess(context, 'Status: Tiba di lokasi & mulai memeriksa kendaraan.');
  }

  void _completeOrder() {
    setState(() {
      _activeOrder = _activeOrder!.copyWith(status: RequestStatus.completed);
    });
    HapticFeedback.heavyImpact();
    SuccessDialog.show(
      context,
      title: 'Pekerjaan Selesai! 👏',
      message: 'Layanan servis darurat telah berhasil diselesaikan. Catatan telah masuk ke riwayat servis.',
      buttonLabel: 'Selesai & Siap Terima Order Lain',
    );
  }

  Future<void> _openMaps(double? lat, double? lon, String address) async {
    if (lat != null && lon != null) {
      final Uri navUri = Uri.parse('google.navigation:q=$lat,$lon');
      final Uri geoUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon');
      final Uri webUri =
          Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
      try {
        if (await canLaunchUrl(navUri)) {
          final bool launched =
              await launchUrl(navUri, mode: LaunchMode.externalApplication);
          if (launched) return;
        } else if (await canLaunchUrl(geoUri)) {
          final bool launched =
              await launchUrl(geoUri, mode: LaunchMode.externalApplication);
          if (launched) return;
        } else if (await canLaunchUrl(webUri)) {
          final bool launched =
              await launchUrl(webUri, mode: LaunchMode.externalApplication);
          if (launched) return;
        }
      } catch (_) {}
    } else {
      final String clean = Uri.encodeComponent('$address, Lhokseumawe');
      final Uri webUri =
          Uri.parse('https://www.google.com/maps/search/?api=1&query=$clean');
      try {
        if (await canLaunchUrl(webUri)) {
          final bool launched =
              await launchUrl(webUri, mode: LaunchMode.externalApplication);
          if (launched) return;
        }
      } catch (_) {}
    }

    await Clipboard.setData(ClipboardData(text: address));
    if (mounted) {
      AppToast.showSuccess(context, 'Alamat disalin ke papan klip: $address');
    }
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        Clipboard.setData(ClipboardData(text: phone));
        AppToast.showSuccess(context, 'Nomor pelanggan disalin: $phone');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isOnline = ref.watch(mechanicIsOnlineProvider);

    final displayName = user?.fullName ?? 'Budi Santoso';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Mekanik Mitra • Lhokseumawe & Aceh Utara',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifikasi',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profil Saya',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: <Widget>[
            // Banner Saklar Status Ketersediaan (Online / Siaga vs Offline)
            AnimatedEntrance(
              index: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFFE8F7EE) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOnline ? AppColors.emerald : AppColors.border,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    LivePulsingDot(
                      color: isOnline ? AppColors.emerald : Colors.grey,
                      size: 12,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            isOnline ? 'STATUS: SIAGA (ONLINE)' : 'STATUS: ISTIRAHAT (OFFLINE)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isOnline ? AppColors.emerald : AppColors.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOnline
                                ? 'Anda siap menerima panggilan darurat terdekat'
                                : 'Aktifkan untuk mulai menerima order panggilan',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isOnline,
                      activeThumbColor: AppColors.emerald,
                      onChanged: (val) {
                        ref.read(mechanicIsOnlineProvider.notifier).state = val;
                        HapticFeedback.lightImpact();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kartu Ringkasan Kinerja Harian (3 Metrik)
            AnimatedEntrance(
              index: 1,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Order Aktif',
                      value: _activeOrder != null && _activeOrder!.status != RequestStatus.completed ? '1' : '0',
                      icon: Icons.emergency_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Selesai Hari Ini',
                      value: '4',
                      icon: Icons.verified_rounded,
                      color: AppColors.emerald,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Rating Layanan',
                      value: '⭐ 4.9',
                      icon: Icons.star_rounded,
                      color: const Color(0xFFFFB800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bagian Panggilan Bantuan Darurat Masuk (Live Dispatching)
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Tugas Panggilan Masuk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (_activeOrder == null && AppEnv.showDemoFeatures)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _loadSampleOrder());
                      AppToast.showSuccess(context, 'Simulasi panggilan darurat baru masuk!');
                    },
                    icon: const Icon(Icons.add_alert_rounded, size: 16),
                    label: const Text('Simulasi', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (_activeOrder == null)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const EmptyState(
                  icon: Icons.wifi_tethering_rounded,
                  title: 'Belum Ada Panggilan Darurat',
                  message:
                      'Sistem akan otomatis membunyikan notifikasi saat ada pengendara motor mogok di sekitar Kota Lhokseumawe & Aceh Utara.',
                ),
              )
            else
              _buildActiveDispatchCard(_activeOrder!),

            const SizedBox(height: 24),

            // Riwayat Pengerjaan Servis Terbaru
            const Text(
              'Riwayat Pengerjaan Servis Terakhir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            _buildCompletedJobTile(
              customerName: 'Zulkifli (Banda Sakti)',
              motor: 'Yamaha NMAX 155',
              issue: 'Ganti Kampas Rem & Cek Radiator',
              time: 'Hari ini, 10:15 WIB',
              cost: 'Rp 145.000',
              rating: '⭐⭐⭐⭐⭐ (5.0)',
            ),
            const SizedBox(height: 10),
            _buildCompletedJobTile(
              customerName: 'Muhammad Rizki (Muara Dua)',
              motor: 'Honda Beat Street',
              issue: 'Tambal Ban Tubeless Darurat',
              time: 'Kemarin, 16:40 WIB',
              cost: 'Rp 35.000',
              rating: '⭐⭐⭐⭐⭐ (5.0)',
            ),
            const SizedBox(height: AppTokens.tabContentBottomPadding),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDispatchCard(ServiceRequest order) {
    final status = order.status;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status == RequestStatus.pending ? AppColors.warning : AppColors.primary,
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (status == RequestStatus.pending ? AppColors.warning : AppColors.primary).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header Status Badge
          Row(
            children: <Widget>[
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(status.icon, size: 14, color: status.textColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: status.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Radius: ~1.8 km',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Detail Pengendara & Motor
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      order.motorcycleName ?? 'Sepeda Motor Pengguna',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kendala: ${order.issueCategory}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Deskripsi Kerusakan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '"${order.issueDescription}"',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 12),

          // Alamat Lokasi Kejadian
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      order.addressText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    if (order.cityRegency.isNotEmpty)
                      Text(
                        order.cityRegency,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Patokan Lokasi jika tersedia
          if (order.landmark != null && order.landmark!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Container(
              key: const Key('mechanic_order_landmark'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.peach),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.flag_rounded, size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Patokan: ${order.landmark}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Pratinjau Mini Peta jika koordinat tersedia
          if (order.latitude != null && order.longitude != null) ...<Widget>[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MiniMapPickerPreview(
                latitude: order.latitude!,
                longitude: order.longitude!,
                address: order.addressText,
                isWithinServiceArea: true,
                height: 120,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Privasi Kontak Pengendara (Figma 07.02)
          if (status == RequestStatus.pending) ...<Widget>[
            Container(
              key: const Key('mechanic_privacy_notice'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kontak telepon dan rute navigasi akan terbuka setelah panggilan diterima demi privasi pengguna.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...<Widget>[
            // Tombol Kontak & Rute Peta (Hanya setelah order diterima)
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('call_customer_button'),
                    onPressed: () => _callCustomer(order.contactPhone),
                    icon: const Icon(Icons.phone_rounded, size: 16),
                    label: const Text('Hubungi Pengendara'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  key: const Key('open_mechanic_route_button'),
                  onPressed: () => _openMaps(order.latitude, order.longitude, order.addressText),
                  icon: const Icon(Icons.directions_rounded),
                  tooltip: 'Buka Rute di Google Maps',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.cream,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Kartu Berbagi Lokasi Real-Time (GPS) seperti Gojek / Grab
            if (status == RequestStatus.onTheWay || status == RequestStatus.accepted) ...<Widget>[
              Container(
                key: const Key('mechanic_gps_broadcast_card'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.emerald, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const LivePulsingDot(color: AppColors.emerald, size: 10),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Berbagi Lokasi Real-Time (GPS)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emerald,
                            ),
                          ),
                        ),
                        Switch(
                          key: const Key('mechanic_gps_share_switch'),
                          value: _isSharingGps,
                          activeThumbColor: AppColors.emerald,
                          onChanged: (val) {
                            setState(() => _isSharingGps = val);
                            if (val) {
                              ref.read(liveTrackingServiceProvider).startBroadcastingLocation(
                                requestId: order.id,
                                mechanicId: 'mech-01',
                              );
                              AppToast.showSuccess(
                                context,
                                'Berbagi lokasi GPS aktif. Pengendara dapat melacak rute Anda secara live.',
                              );
                            } else {
                              ref.read(liveTrackingServiceProvider).stopBroadcastingLocation(order.id);
                              AppToast.showInfo(context, 'Berbagi lokasi dinonaktifkan.');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Posisi Anda dikirimkan secara berkala ke pengendara motor seperti aplikasi Gojek / Grab.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 14),

          // Tombol Alur Kerja Berdasarkan Status (Sequence Diagram UC-03)
          if (status == RequestStatus.pending) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: SecondaryButton(
                    label: 'Tolak',
                    height: 44,
                    onPressed: _handleReject,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: 'Terima Panggilan',
                    icon: Icons.check_circle_rounded,
                    height: 44,
                    onPressed: _handleAccept,
                  ),
                ),
              ],
            ),
          ] else if (status == RequestStatus.accepted) ...<Widget>[
            PrimaryButton(
              label: 'Mulai Berangkat ke Lokasi (OTW)',
              icon: Icons.directions_bike_rounded,
              height: 44,
              onPressed: _advanceToOtw,
            ),
          ] else if (status == RequestStatus.onTheWay) ...<Widget>[
            PrimaryButton(
              label: 'Tiba di Lokasi & Tangani Kerusakan',
              icon: Icons.build_circle_rounded,
              height: 44,
              onPressed: _advanceToWork,
            ),
          ] else if (status == RequestStatus.inProgress) ...<Widget>[
            PrimaryButton(
              label: 'Tandai Pekerjaan Servis Selesai',
              icon: Icons.verified_rounded,
              height: 44,
              onPressed: _completeOrder,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletedJobTile({
    required String customerName,
    required String motor,
    required String issue,
    required String time,
    required String cost,
    required String rating,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                customerName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                cost,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$motor • $issue', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(rating, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

