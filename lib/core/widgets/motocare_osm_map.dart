import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';

/// TileProvider ringan transparan khusus lingkungan widget test agar tidak memicu HTTP error.
class _TestSafeTileProvider extends TileProvider {
  // 1x1 transparent PNG bytes
  static final Uint8List _transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_transparentPng);
  }
}

bool get _isWidgetTestEnv =>
    WidgetsBinding.instance.toString().contains('TestWidgetsFlutterBinding');

/// Peta OpenStreetMap Real-Time ala Gojek/Grab (bekerja penuh di Web, Android, iOS, Desktop tanpa API key berbayar).
class MotocareLiveOsmMap extends StatefulWidget {
  const MotocareLiveOsmMap({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.mechLat,
    required this.mechLng,
    required this.heading,
    required this.isArrived,
    required this.mechanicName,
    this.routeWaypoints = const <List<double>>[],
    this.mapController,
    this.followMechanic = true,
    this.showRecenterButton = true,
    this.showPickupLabel = true,
  });

  final double userLat;
  final double userLng;
  final double mechLat;
  final double mechLng;
  final double heading;
  final bool isArrived;
  final String mechanicName;
  final List<List<double>> routeWaypoints;
  final MapController? mapController;
  final bool followMechanic;
  final bool showRecenterButton;
  final bool showPickupLabel;

  @override
  State<MotocareLiveOsmMap> createState() => _MotocareLiveOsmMapState();
}

class _MotocareLiveOsmMapState extends State<MotocareLiveOsmMap>
    with SingleTickerProviderStateMixin {
  late final MapController _internalController;
  late final AnimationController _pulseController;
  bool _userPanned = false;

  MapController get _controller => widget.mapController ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (!_isWidgetTestEnv) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MotocareLiveOsmMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.followMechanic &&
        !_userPanned &&
        (oldWidget.mechLat != widget.mechLat ||
            oldWidget.mechLng != widget.mechLng)) {
      final midLat = (widget.mechLat + widget.userLat) / 2;
      final midLng = (widget.mechLng + widget.userLng) / 2;
      try {
        _controller.move(LatLng(midLat, midLng), _controller.camera.zoom);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (widget.mapController == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _fitRoute() {
    setState(() => _userPanned = false);
    final userPt = LatLng(widget.userLat, widget.userLng);
    final mechPt = LatLng(widget.mechLat, widget.mechLng);
    try {
      final bounds = LatLngBounds.fromPoints(<LatLng>[userPt, mechPt]);
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(52),
          maxZoom: 16.5,
        ),
      );
    } catch (_) {
      try {
        _controller.move(userPt, 15.0);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final userPt = LatLng(widget.userLat, widget.userLng);
    final mechPt = LatLng(widget.mechLat, widget.mechLng);
    final initialCenter = widget.isArrived
        ? userPt
        : LatLng((widget.userLat + widget.mechLat) / 2, (widget.userLng + widget.mechLng) / 2);

    final List<LatLng> polylinePts = widget.routeWaypoints.isNotEmpty
        ? widget.routeWaypoints
            .map((p) => LatLng(p[0], p[1]))
            .toList(growable: false)
        : <LatLng>[mechPt, userPt];

    return Stack(
      children: <Widget>[
        Container(
          color: const Color(0xFFEAF2EE),
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14.5,
              minZoom: 10,
              maxZoom: 18.5,
              onPositionChanged: (_, hasGesture) {
                if (hasGesture && !_userPanned) {
                  setState(() => _userPanned = true);
                }
              },
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.motocare.app',
                tileProvider: _isWidgetTestEnv ? _TestSafeTileProvider() : null,
              ),
              if (!widget.isArrived && polylinePts.length >= 2)
                PolylineLayer(
                  polylines: <Polyline>[
                    Polyline(
                      points: polylinePts,
                      strokeWidth: 7.0,
                      color: AppColors.deepTeal.withValues(alpha: 0.25),
                    ),
                    Polyline(
                      points: polylinePts,
                      strokeWidth: 4.5,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: <Marker>[
                  // Pin Titik Penjemputan (Pengguna)
                  Marker(
                    point: userPt,
                    width: 140,
                    height: 82,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (widget.showPickupLabel)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.deepTeal, width: 1),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Titik Jemput',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.deepTeal,
                              ),
                            ),
                          ),
                        const SizedBox(height: 3),
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                            CurvedAnimation(
                              parent: _pulseController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.deepTeal,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.2),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.deepTeal.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Marker Motor Montir Real-Time (Bergerak & Berputar Mengikuti Arah Jalan)
                  if (!widget.isArrived)
                    Marker(
                      point: mechPt,
                      width: 170,
                      height: 84,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Transform.rotate(
                              angle: (widget.heading - 90) * (math.pi / 180) * 0.15,
                              child: const Icon(
                                Icons.two_wheeler_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              widget.mechanicName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (widget.showRecenterButton)
          Positioned(
            right: 10,
            top: 10,
            child: Material(
              color: Colors.white.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _fitRoute,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.center_focus_strong_rounded,
                    size: 18,
                    color: AppColors.deepTeal,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Pratinjau Peta Interaktif Pemilih Lokasi berbasis OpenStreetMap (`flutter_map`).
class MotocarePickerOsmMap extends StatefulWidget {
  const MotocarePickerOsmMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.onLocationChanged,
  });

  final double latitude;
  final double longitude;
  final void Function(double newLat, double newLng)? onLocationChanged;

  @override
  State<MotocarePickerOsmMap> createState() => _MotocarePickerOsmMapState();
}

class _MotocarePickerOsmMapState extends State<MotocarePickerOsmMap> {
  final MapController _controller = MapController();

  @override
  void didUpdateWidget(covariant MotocarePickerOsmMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      try {
        _controller.move(
          LatLng(widget.latitude, widget.longitude),
          _controller.camera.zoom,
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pin = LatLng(widget.latitude, widget.longitude);
    return Container(
      color: const Color(0xFFF4F1EA),
      child: FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: pin,
          initialZoom: 15.5,
          onTap: (_, latLng) {
            widget.onLocationChanged?.call(latLng.latitude, latLng.longitude);
          },
        ),
        children: <Widget>[
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.motocare.app',
            tileProvider: _isWidgetTestEnv ? _TestSafeTileProvider() : null,
          ),
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: pin,
                width: 48,
                height: 48,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
