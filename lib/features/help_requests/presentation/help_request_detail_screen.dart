import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../../../core/widgets/animated_effects.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../data/demo_mechanic_simulator.dart';
import '../domain/help_request_rules.dart';
import '../domain/request_status.dart';
import '../domain/service_request.dart';
import 'help_requests_providers.dart';
import 'widgets/simulated_mechanic_tracking_card.dart';

/// Layar Detail Permintaan Bantuan Mekanik sesuai PRD Bagian 7 (M7)
class HelpRequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;

  const HelpRequestDetailScreen({
    super.key,
    required this.requestId,
  });

  @override
  ConsumerState<HelpRequestDetailScreen> createState() =>
      _HelpRequestDetailScreenState();
}

class _HelpRequestDetailScreenState
    extends ConsumerState<HelpRequestDetailScreen> {
  Timer? _countdownTimer;
  StreamSubscription<ServiceRequest?>? _requestSub;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _subscribeStatusUpdates();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _requestSub?.cancel();
    super.dispose();
  }

  void _subscribeStatusUpdates() {
    _requestSub?.cancel();
    _requestSub = ref
        .read(helpRequestRepositoryProvider)
        .watchRequest(widget.requestId)
        .listen((updated) {
      if (mounted && updated != null) {
        ref.invalidate(helpRequestDetailProvider(widget.requestId));
      }
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final reqAsync = ref.read(helpRequestDetailProvider(widget.requestId));
      final req = reqAsync.valueOrNull;

      if (req != null && req.status == RequestStatus.pending) {
        final remaining = req.remainingTime;
        if (remaining == Duration.zero) {
          timer.cancel();
          // TC-19: Kedaluwarsa otomatis saat waktu habis
          ref.read(helpRequestRepositoryProvider).expireStaleRequests();
          ref.invalidate(helpRequestDetailProvider(widget.requestId));
        } else {
          if (mounted) {
            setState(() => _remainingTime = remaining);
          }
        }
      }
    });
  }

  Future<void> _handleCancel(ServiceRequest request) async {
    final bool isWarning = HelpRequestRules.requiresCancelWarning(request.status);

    final confirmed = await ConfirmationDialog.show(
      context,
      title: isWarning ? 'Peringatan Pembatalan' : 'Batalkan Panggilan Montir',
      message: isWarning
          ? 'Mekanik saat ini sedang dalam perjalanan ke lokasi Anda. Apakah Anda yakin tetap ingin membatalkan panggilan ini?'
          : 'Apakah Anda yakin ingin membatalkan panggilan montir ini?',
      confirmLabel: 'Ya, Batalkan',
      cancelLabel: 'Kembali',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(helpRequestActionNotifierProvider.notifier)
        .cancelRequest(request.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Panggilan montir berhasil dibatalkan.'),
            backgroundColor: AppColors.charcoal,
          ),
        );
      } else {
        final err =
            ref.read(helpRequestActionNotifierProvider).errorMessage ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              err.isNotEmpty ? err : 'Gagal membatalkan permintaan.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}

    await Clipboard.setData(ClipboardData(text: phone));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon disalin ke papan klip.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(helpRequestDetailProvider(widget.requestId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Detail Panggilan Montir'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: () =>
                ref.invalidate(helpRequestDetailProvider(widget.requestId)),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
        child: requestAsync.when(
          loading: () => LoadingSkeleton.helpRequestDetail(),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorState(
                title: 'Gagal Memuat Permintaan',
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(helpRequestDetailProvider(widget.requestId)),
              ),
            ),
          ),
          data: (ServiceRequest? request) {
            if (request == null) {
              return const Center(
                child: Text(
                  'Permintaan bantuan tidak ditemukan.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            final status = request.status;
            final minutes = _remainingTime.inMinutes;
            final seconds = _remainingTime.inSeconds % 60;
            final countdownStr =
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // Header Status Card dengan Transisi Halus (T-04 B)
                AnimatedSwitcher(
                  duration: AppMotion.standardDuration,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.04),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: AppMotion.enterCurve,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey<String>('status_card_${status.name}'),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: status.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: status.borderColor, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: status.borderColor),
                              ),
                              child: Icon(status.icon, color: status.textColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    status.label,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: status.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: #${request.id.length > 8 ? request.id.substring(0, 8) : request.id}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (AppEnv.showDemoFeatures && request.isDemo)
                              const StatusChip(
                                key: Key('help_request_demo_badge'),
                                label: 'Demo/Simulasi',
                                icon: Icons.science_outlined,
                                backgroundColor: Colors.white,
                                textColor: AppColors.textSecondary,
                                borderColor: Color(0xFFE5E7EB),
                              ),
                          ],
                        ),

                        // Hitung Mundur Waktu Tunggu 15 Menit saat Status Pending
                        if (status == RequestStatus.pending) ...<Widget>[
                          const Divider(height: 24),
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: minutes <= 1 ? AppColors.error : AppColors.warning,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Batas konfirmasi mekanik: ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: minutes <= 1 ? AppColors.error : AppColors.warning,
                                ),
                                child: Text(countdownStr),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Kartu Info Mekanik Ditugaskan (jika ada)
                if (request.mechanic != null) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBright,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.peach, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Row(
                          children: <Widget>[
                            Icon(
                              Icons.two_wheeler_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mekanik yang Ditugaskan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          request.mechanic!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (request.mechanic!.workshopName != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            request.mechanic!.workshopName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (request.mechanic!.phone != null) ...<Widget>[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              key: const Key('call_mechanic_button'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryText,
                                side: const BorderSide(color: AppColors.peach),
                                backgroundColor: AppColors.cream,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.phone_rounded, size: 16),
                              label: Text(
                                'Hubungi Mekanik (${request.mechanic!.phone})',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              onPressed: () =>
                                  _callPhone(request.mechanic!.phone!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Kartu Status Tiba (Figma 03.10)
                if (status == RequestStatus.inProgress) ...<Widget>[
                  Container(
                    key: const Key('mechanic_arrived_status_card'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0284C7),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF0284C7),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Montir Sudah Tiba di Lokasi',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${request.mechanic?.name ?? 'Montir'} telah sampai di titik penjemputan dan sedang memeriksa kondisi sepeda motor Anda.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Kartu Pelacakan Montir Real-Time (Langsung bergerak ala Gojek/Grab)
                if (status == RequestStatus.accepted ||
                    status == RequestStatus.onTheWay ||
                    status == RequestStatus.inProgress) ...<Widget>[
                  SimulatedMechanicTrackingCard(
                    request: request,
                  ),
                  const SizedBox(height: 16),
                ],

                // Rincian Masalah & Lokasi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Rincian Kerusakan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.report_problem_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            request.issueCategory,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        request.issueDescription,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const Divider(height: 24),

                      // Lokasi
                      const Text(
                        'Titik Penjemputan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              request.addressText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Kontak & Motor
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Nomor Telepon Anda',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  request.contactPhone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (request.motorcycleName != null) ...<Widget>[
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  const Text(
                                    'Sepeda Motor',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    request.motorcycleName!,
                                    textAlign: TextAlign.end,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Penanganan TC-19: Opsi saat Permintaan Expired / Waktu Habis
                if (status == RequestStatus.expired) ...<Widget>[
                  Container(
                    key: const Key('expired_options_card'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Row(
                          children: <Widget>[
                            Icon(Icons.timer_off_outlined, color: AppColors.error),
                            SizedBox(width: 8),
                            Text(
                              'Mekanik Belum Tersedia',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Waktu tunggu 15 menit telah habis dan belum ada mekanik yang merespons di sekitar lokasi Anda. Silakan pilih opsi alternatif:',
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),

                        // Opsi 1: Kirim Ulang Permintaan
                        PrimaryButton(
                          key: const Key('retry_help_request_button'),
                          label: 'Kirim Ulang Permintaan',
                          icon: Icons.replay_rounded,
                          onPressed: () => context.go('/help/new'),
                        ),
                        const SizedBox(height: 10),

                        // Opsi 2: Hubungi Bengkel Terverifikasi
                        OutlinedButton.icon(
                          key: const Key('contact_workshops_button'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryText,
                            side: const BorderSide(color: AppColors.peach),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.storefront_rounded),
                          label: const Text(
                            'Cari & Hubungi Bengkel Terdekat',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            final city = request.cityRegency;
                            final lat = request.latitude;
                            final lng = request.longitude;
                            final uri = Uri(
                              path: '/workshops',
                              queryParameters: <String, String>{
                                if (city.isNotEmpty) 'city': city,
                                if (lat != null) 'lat': lat.toString(),
                                if (lng != null) 'lng': lng.toString(),
                              },
                            );
                            context.push(uri.toString());
                          },
                        ),

                        // Opsi 3: Kontak Darurat (hanya bila emergencyContacts terisi)
                        if (AppConstants.emergencyContacts.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            key: const Key('emergency_contact_button'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.emergency_rounded),
                            label: const Text('Hubungi Layanan Darurat'),
                            onPressed: () => _callPhone(
                              AppConstants.emergencyContacts.first,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Penilaian & Ulasan Layanan saat Servis Selesai (Sesuai UC-03 & Sequence Diagram)
                if (status == RequestStatus.completed) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Column(
                      children: <Widget>[
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'Servis Selesai Ditangani',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Mekanik telah selesai memperbaiki kendala motor Anda. Berikan penilaian Anda untuk membantu komunitas pengendara!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton(
                          key: const Key('give_rating_button'),
                          label: 'Beri Penilaian & Ulasan ⭐',
                          icon: Icons.star_rounded,
                          onPressed: () {
                            ReviewRatingBottomSheet.show(
                              context,
                              mechanicName: request.mechanic?.name ?? 'Bang Rudi Pratama',
                              workshopName: request.mechanic?.workshopName ?? 'Bengkel Resmi Samudera Motor',
                              onSubmit: (rating, comment) async {
                                await Future<void>.delayed(const Duration(milliseconds: 500));
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: const Key('back_to_activity_button'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryText,
                            side: const BorderSide(color: AppColors.peach),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.history_rounded),
                          label: const Text(
                            'Kembali ke Aktivitas',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/help');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Kontrol Interaktif Simulasi Alur Demo (Hanya tampil jika Demo Mode diaktifkan)
                if (AppEnv.showDemoFeatures && request.isDemo && status.isActive) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.peach),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Row(
                          children: <Widget>[
                            Icon(Icons.science_outlined, size: 18, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Kontrol Simulasi Pengujian (Demo Mode)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            if (status == RequestStatus.pending)
                              ActionChip(
                                avatar: const Icon(Icons.check, size: 16, color: AppColors.success),
                                label: const Text('Simulasi: Terima (Mekanik Ditemukan)', style: TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  await ref.read(helpRequestRepositoryProvider).advanceRequest(
                                    request.id,
                                    RequestStatus.accepted,
                                    assignedMechanic: DemoMechanicSimulator.demoMechanic,
                                  );
                                  ref.invalidate(helpRequestDetailProvider(widget.requestId));
                                },
                              ),
                            if (status == RequestStatus.accepted)
                              ActionChip(
                                avatar: const Icon(Icons.directions_bike, size: 16, color: AppColors.primary),
                                label: const Text('Simulasi: Berangkat (OTW)', style: TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  await ref.read(helpRequestRepositoryProvider).advanceRequest(
                                    request.id,
                                    RequestStatus.onTheWay,
                                  );
                                  ref.invalidate(helpRequestDetailProvider(widget.requestId));
                                },
                              ),
                            if (status == RequestStatus.onTheWay)
                              ActionChip(
                                avatar: const Icon(Icons.build, size: 16, color: Color(0xFF0284C7)),
                                label: const Text('Simulasi: Tiba & Tangani Motor', style: TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  await ref.read(helpRequestRepositoryProvider).advanceRequest(
                                    request.id,
                                    RequestStatus.inProgress,
                                  );
                                  ref.invalidate(helpRequestDetailProvider(widget.requestId));
                                },
                              ),
                            if (status == RequestStatus.inProgress)
                              ActionChip(
                                avatar: const Icon(Icons.verified, size: 16, color: AppColors.success),
                                label: const Text('Simulasi: Selesaikan Servis', style: TextStyle(fontSize: 12)),
                                onPressed: () async {
                                  await ref.read(helpRequestRepositoryProvider).advanceRequest(
                                    request.id,
                                    RequestStatus.completed,
                                  );
                                  ref.invalidate(helpRequestDetailProvider(widget.requestId));
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tombol Batalkan Permintaan (TC-20: Hanya pada pending, accepted, on_the_way)
                if (status.canCancel) ...<Widget>[
                  OutlinedButton.icon(
                    key: const Key('cancel_help_request_button'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text(
                      'Batalkan Panggilan Montir',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    onPressed: () => _handleCancel(request),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}
}
