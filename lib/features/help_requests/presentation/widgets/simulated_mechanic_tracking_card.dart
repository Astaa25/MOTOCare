import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/env.dart';
import '../../../../core/services/live_tracking_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/motocare_osm_map.dart';
import '../../domain/request_status.dart';
import '../../domain/service_request.dart';

/// Kartu Pelacakan Montir Real-Time (Gojek / Grab Live Map Embedded)
/// Menampilkan peta OpenStreetMap interaktif, jalur OSRM, motor bergerak real-time,
/// serta jarak tersisa dan perkiraan waktu tiba (ETA) secara langsung tanpa perlu tombol ekstra.
class SimulatedMechanicTrackingCard extends ConsumerStatefulWidget {
  const SimulatedMechanicTrackingCard({
    super.key,
    required this.request,
    this.initialDistanceKm = 1.6,
    this.initialEtaMinutes = 5,
    this.isForceStale = false,
  });

  final ServiceRequest request;
  final double initialDistanceKm;
  final int initialEtaMinutes;
  final bool isForceStale;

  @override
  ConsumerState<SimulatedMechanicTrackingCard> createState() =>
      _SimulatedMechanicTrackingCardState();
}

class _SimulatedMechanicTrackingCardState
    extends ConsumerState<SimulatedMechanicTrackingCard>
    with SingleTickerProviderStateMixin {
  late String _updateStatusText;
  bool _isStale = false;
  Timer? _staleTimer;
  late AnimationController _pulseController;

  bool get _isWidgetTestEnv =>
      WidgetsBinding.instance.toString().contains('TestWidgetsFlutterBinding');

  @override
  void initState() {
    super.initState();
    _updateStatusText = 'Baru saja';
    _isStale = widget.isForceStale;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (!_isWidgetTestEnv) {
      _pulseController.repeat(reverse: true);
    }

    if (widget.request.status == RequestStatus.onTheWay && !_isWidgetTestEnv) {
      _staleTimer = Timer(const Duration(seconds: 60), () {
        if (mounted && widget.request.status == RequestStatus.onTheWay) {
          setState(() {
            _updateStatusText = 'Baru saja';
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant SimulatedMechanicTrackingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isForceStale != oldWidget.isForceStale) {
      setState(() => _isStale = widget.isForceStale);
    }
  }

  @override
  void dispose() {
    _staleTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _retryRefreshLocation() {
    setState(() {
      _isStale = false;
      _updateStatusText = 'Baru saja';
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.request.status;
    final isArrived = status == RequestStatus.inProgress ||
        status == RequestStatus.completed;
    final destLat = widget.request.latitude ?? 5.1801;
    final destLng = widget.request.longitude ?? 97.1402;
    final rawMechName = widget.request.mechanic?.name ?? 'Bang Rudi Pratama';
    final cleanMechName = AppEnv.showDemoFeatures
        ? rawMechName
        : rawMechName.replaceFirst('[Demo] ', '').trim();
    final mechPhone = widget.request.mechanic?.phone ?? '081269112201';

    final liveStream = ref.watch(
      mechanicLiveLocationStreamProvider((
        requestId: widget.request.id,
        destLat: destLat,
        destLng: destLng,
        mechanicName: cleanMechName,
        mechanicPhone: mechPhone,
      )),
    );

    final liveUpdate = liveStream.valueOrNull;
    final double displayDistanceKm = isArrived
        ? 0.0
        : (liveUpdate?.distanceKm ?? widget.initialDistanceKm);
    final int displayEtaMinutes = isArrived
        ? 0
        : (liveUpdate?.etaMinutes ?? widget.initialEtaMinutes);
    final double mechLat = isArrived
        ? destLat
        : (liveUpdate?.latitude ?? (destLat + 0.0085));
    final double mechLng = isArrived
        ? destLng
        : (liveUpdate?.longitude ?? (destLng + 0.0075));
    final double heading = liveUpdate?.heading ?? 215.0;
    final List<List<double>> routeWaypoints =
        liveUpdate?.routeWaypoints ?? const <List<double>>[];

    return Container(
      key: const Key('simulated_mechanic_tracking_card'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.peach, width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. Header Informasi Pelacakan Real-Time
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.peach),
                  ),
                  child: const Icon(
                    Icons.directions_bike_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isArrived
                            ? 'Montir Telah Tiba di Lokasi'
                            : 'Montir Menuju Lokasi Anda',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          FadeTransition(
                            opacity: _pulseController,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isArrived
                                    ? AppColors.success
                                    : AppColors.emerald,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              key: const Key('tracking_update_time'),
                              isArrived
                                  ? 'Status: Siap Ditangani'
                                  : 'Live GPS • Diperbarui: $_updateStatusText',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Banner Status Live / Mode Demo (hanya tampil label simulasi jika showDemoFeatures aktif)
          if (AppEnv.showDemoFeatures)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                key: const Key('tracking_simulation_badge'),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3DD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF4B63F).withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: Color(0xFF8A5A00),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Simulasi dipercepat - bukan GPS nyata',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A5A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                key: const Key('tracking_simulation_badge'),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.emerald.withValues(alpha: 0.45),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.gps_fixed_rounded,
                      size: 15,
                      color: AppColors.emerald,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArrived
                            ? 'Montir Sudah di Titik Penjemputan'
                            : 'Live GPS Tracking Aktif • Mengikuti Rute Jalan',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Fallback Figma 09.07: Lokasi Belum Diperbarui
          if (_isStale) ...<Widget>[
            Container(
              key: const Key('tracking_stale_location_banner'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFFEF2F2),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.signal_cellular_connected_no_internet_0_bar_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Lokasi belum diperbarui',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          'Menampilkan posisi terakhir yang tercatat',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('tracking_retry_refresh_button'),
                    onPressed: _retryRefreshLocation,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      'Perbarui',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 4. Peta Live OpenStreetMap Terintegrasi Langsung (Gerak Real-Time Ala Gojek/Grab)
          SizedBox(
            height: 290,
            width: double.infinity,
            child: MotocareLiveOsmMap(
              key: const Key('interactive_live_osm_map'),
              userLat: destLat,
              userLng: destLng,
              mechLat: mechLat,
              mechLng: mechLng,
              heading: heading,
              isArrived: isArrived,
              mechanicName: cleanMechName,
              routeWaypoints: routeWaypoints,
              followMechanic: true,
              showRecenterButton: true,
            ),
          ),

          // 5. Metrik Jarak Tersisa & Perkiraan Tiba (ETA) Live
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.peach),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppEnv.showDemoFeatures
                              ? 'Jarak Tersisa (Simulasi)'
                              : 'Jarak Tersisa',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          key: const Key('tracking_remaining_distance'),
                          isArrived || (liveUpdate?.isArrived ?? false)
                              ? '0 km (Tiba)'
                              : '${displayDistanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.peach),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppEnv.showDemoFeatures
                              ? 'Perkiraan Tiba (Simulasi)'
                              : 'Perkiraan Tiba',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          key: const Key('tracking_eta_time'),
                          isArrived || (liveUpdate?.isArrived ?? false)
                              ? 'Sudah Tiba'
                              : '$displayEtaMinutes menit',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isArrived || (liveUpdate?.isArrived ?? false)
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
