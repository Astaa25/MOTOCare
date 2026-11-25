import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/live_tracking_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_loading.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/motocare_osm_map.dart';
import '../domain/service_request.dart';
import 'help_requests_providers.dart';

/// Layar Pelacakan Montir Real-Time Interaktif Mirip Gojek & Grab (Live GPS Tracking)
/// Mengintegrasikan:
/// - Peta Google Maps interaktif dengan marker motor berputar sesuai arah (heading/bearing)
/// - Stream lokasi real-time dari montir dengan pembaruan ETA dan jarak tersisa
/// - Floating Bottom Sheet bergaya Gojek/Grab dengan profil montir, plat motor, dan kontak cepat (Telepon & WA)
/// - Fallback ilustrasi peta beresolusi tinggi saat Google Play Services / SDK dinonaktifkan
class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({
    super.key,
    required this.requestId,
  });

  final String requestId;

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  final fm.MapController _mapController = fm.MapController();
  late AnimationController _pulseController;
  bool _followMechanic = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (!kDebugMode ||
        !WidgetsBinding.instance.toString().contains('TestWidgetsFlutterBinding')) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _recenterToMechanic(double lat, double lng) {
    setState(() => _followMechanic = true);
    try {
      _mapController.move(ll.LatLng(lat, lng), 16.0);
    } catch (_) {}
  }

  void _recenterToUser(double lat, double lng) {
    setState(() => _followMechanic = false);
    try {
      _mapController.move(ll.LatLng(lat, lng), 16.0);
    } catch (_) {}
  }

  void _fitRouteBounds(double mechLat, double mechLng, double userLat, double userLng) {
    setState(() => _followMechanic = false);
    try {
      final bounds = fm.LatLngBounds.fromPoints(<ll.LatLng>[
        ll.LatLng(mechLat, mechLng),
        ll.LatLng(userLat, userLng),
      ]);
      _mapController.fitCamera(
        fm.CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(60),
          maxZoom: 16.5,
        ),
      );
    } catch (_) {}
  }

  Future<void> _callMechanic(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: phone));
    if (mounted) {
      AppToast.showSuccess(context, 'Nomor telepon disalin: $phone');
    }
  }

  Future<void> _openWhatsApp(String? phone, String mechanicName, String address) async {
    final cleanPhone = (phone ?? '081269112201')
        .replaceAll(RegExp(r'\D'), '')
        .replaceFirst(RegExp(r'^0'), '62');

    final message = Uri.encodeComponent(
      'Halo Bang $mechanicName, saya pemesan servis darurat MotoCare di $address. Posisi sudah sampai mana ya bang?',
    );
    final waUri = Uri.parse('https://wa.me/$cleanPhone?text=$message');

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    await Clipboard.setData(ClipboardData(text: phone ?? '081269112201'));
    if (mounted) {
      AppToast.showSuccess(context, 'Nomor WhatsApp disalin: $phone');
    }
  }

  Future<void> _openExternalGoogleMaps(double lat, double lng) async {
    final navUri = Uri.parse('google.navigation:q=$lat,$lng');
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      if (await canLaunchUrl(navUri)) {
        await launchUrl(navUri, mode: LaunchMode.externalApplication);
        return;
      } else if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(helpRequestDetailProvider(widget.requestId));

    return requestAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: MotoCareLoadingIndicator.medium(
            message: 'Memuat peta pelacakan langsung...',
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Live Tracking')),
        body: Center(child: Text('Gagal memuat pelacakan: $err')),
      ),
      data: (request) {
        if (request == null) {
          return const Scaffold(
            body: Center(child: Text('Permintaan tidak ditemukan')),
          );
        }

        final userLat = request.latitude ?? 5.1801;
        final userLng = request.longitude ?? 97.1402;
        final mechName = request.mechanic?.name ?? 'Bang Rudi Pratama';
        final mechPhone = request.mechanic?.phone ?? '081269112201';

        final liveStream = ref.watch(
          mechanicLiveLocationStreamProvider((
            requestId: widget.requestId,
            destLat: userLat,
            destLng: userLng,
            mechanicName: mechName,
            mechanicPhone: mechPhone,
          )),
        );

        final update = liveStream.value ??
            MechanicLocationUpdate(
              requestId: widget.requestId,
              mechanicId: request.mechanicId ?? 'mech-01',
              mechanicName: mechName,
              mechanicPhone: mechPhone,
              latitude: userLat + 0.0085,
              longitude: userLng + 0.0075,
              heading: 45.0,
              distanceKm: 1.4,
              etaMinutes: 4,
              timestamp: DateTime.now(),
            );

        return Scaffold(
          body: Stack(
            children: <Widget>[
              // 1. Peta OpenStreetMap Layar Penuh (Web, Android, iOS, Desktop)
              Positioned.fill(
                child: MotocareLiveOsmMap(
                  userLat: userLat,
                  userLng: userLng,
                  mechLat: update.latitude,
                  mechLng: update.longitude,
                  heading: update.heading,
                  isArrived: update.isArrived,
                  mechanicName: update.mechanicName,
                  routeWaypoints: update.routeWaypoints,
                  mapController: _mapController,
                  followMechanic: _followMechanic,
                  showRecenterButton: false,
                ),
              ),

              // 2. Header Mengambang: Tombol Kembali & Indikator LIVE GPS
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: <Widget>[
                      // Tombol Kembali
                      InkWell(
                        key: const Key('live_tracking_back_button'),
                        onTap: () => context.pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.peach, width: 1.2),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Indikator Live GPS Gojek/Grab
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.peach, width: 1.2),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              FadeTransition(
                                opacity: _pulseController,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.emerald,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Text(
                                      'LIVE TRACKING MONTIR',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.emerald,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      update.isArrived
                                          ? 'Montir Telah Tiba di Lokasi'
                                          : 'Berbagi Lokasi Real-Time (GPS)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Tombol Kontrol Peta Mengambang (Kanan)
              Positioned(
                right: 16,
                top: 130,
                child: Column(
                  children: <Widget>[
                    _buildFloatingMapButton(
                      key: const Key('recenter_mechanic_button'),
                      icon: Icons.two_wheeler_rounded,
                      tooltip: 'Pusatkan ke Montir',
                      isActive: _followMechanic,
                      onPressed: () => _recenterToMechanic(update.latitude, update.longitude),
                    ),
                    const SizedBox(height: 10),
                    _buildFloatingMapButton(
                      key: const Key('recenter_user_button'),
                      icon: Icons.my_location_rounded,
                      tooltip: 'Pusatkan ke Lokasi Saya',
                      onPressed: () => _recenterToUser(userLat, userLng),
                    ),
                    const SizedBox(height: 10),
                    _buildFloatingMapButton(
                      key: const Key('fit_route_bounds_button'),
                      icon: Icons.alt_route_rounded,
                      tooltip: 'Lihat Seluruh Rute',
                      onPressed: () => _fitRouteBounds(
                        update.latitude,
                        update.longitude,
                        userLat,
                        userLng,
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Floating Draggable Card Bergaya Gojek / Grab
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildGojekStyleBottomSheet(
                  context,
                  request: request,
                  update: update,
                  userLat: userLat,
                  userLng: userLng,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingMapButton({
    Key? key,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.peach,
          width: 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        key: key,
        tooltip: tooltip,
        icon: Icon(
          icon,
          color: isActive ? Colors.white : AppColors.primary,
          size: 22,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildGojekStyleBottomSheet(
    BuildContext context, {
    required ServiceRequest request,
    required MechanicLocationUpdate update,
    required double userLat,
    required double userLng,
  }) {
    final bool isArrived = update.isArrived;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.peach, width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Bar Pegangan Sheet (Drag Handle)
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 1. Banner Estimasi Tiba (ETA) & Jarak Real-Time (Gojek / Grab Style)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isArrived
                        ? <Color>[const Color(0xFFE8F7EE), const Color(0xFFD1FAE5)]
                        : <Color>[AppColors.cream, const Color(0xFFFFF7ED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isArrived ? AppColors.emerald : AppColors.peach,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isArrived ? AppColors.emerald : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isArrived ? Icons.check_circle_rounded : Icons.two_wheeler_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            isArrived
                                ? 'Montir Sudah Tiba di Lokasi!'
                                : 'Perkiraan Tiba (ETA):',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            key: const Key('live_tracking_eta_display'),
                            isArrived ? 'Siap Ditangani' : '~${update.etaMinutes} Menit',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isArrived ? AppColors.emerald : AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          const Text(
                            'Jarak Tersisa',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            key: const Key('live_tracking_distance_display'),
                            isArrived ? '0 km (Tiba)' : '${update.distanceKm} km',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Profil Montir & Identitas Kendaraan Sepeda Motor
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    // Avatar Montir
                    Stack(
                      children: <Widget>[
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.cream,
                          child: Icon(
                            Icons.person_rounded,
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.emerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            update.mechanicName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            update.workshopName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Badge Plat Nomor Motor Bergaya Gojek / Grab
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  update.motorcyclePlate,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Text(
                                update.motorcycleModel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Rating Montir
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFFB45309),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${update.rating}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${update.totalReviews} ulasan',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Tombol Komunikasi Gojek/Grab: Telepon & Chat WhatsApp
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('live_call_mechanic_button'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      label: const Text(
                        'Telepon',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      onPressed: () => _callMechanic(update.mechanicPhone),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      key: const Key('live_whatsapp_mechanic_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                      label: const Text(
                        'WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      onPressed: () => _openWhatsApp(
                        update.mechanicPhone,
                        update.mechanicName,
                        request.addressText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Tombol Navigasi Eksternal Google Maps
                  IconButton.filledTonal(
                    key: const Key('live_open_google_maps_button'),
                    tooltip: 'Buka di Google Maps',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.cream,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.peach),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.near_me_rounded),
                    onPressed: () => _openExternalGoogleMaps(userLat, userLng),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
