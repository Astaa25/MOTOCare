import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/help_request_rules.dart';
import '../domain/request_status.dart';
import '../domain/service_request.dart';
import 'help_requests_providers.dart';

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
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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
      backgroundColor: AppColors.background,
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
      body: SafeArea(
        child: requestAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: const <Widget>[
              LoadingSkeleton(height: 140, borderRadius: 16),
              SizedBox(height: 16),
              LoadingSkeleton(height: 180, borderRadius: 16),
            ],
          ),
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
                // Header Status Card
                Container(
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
                          if (request.isDemo)
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
                            const Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Batas konfirmasi mekanik: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              countdownStr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Kartu Info Mekanik Ditugaskan (jika ada)
                if (request.mechanic != null) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                            Text(
                              'Mekanik yang Ditugaskan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
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

                // Rincian Masalah & Lokasi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
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
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (request.motorcycleName != null) ...<Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                const Text(
                                  'Sepeda Motor',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  request.motorcycleName!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
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
                          onPressed: () => context.push('/workshops'),
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
    );
  }
}
