import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/tutorial.dart';
import 'tutorials_providers.dart';

/// Layar Detail Tutorial Perawatan Motor sesuai PRD Bagian 7 (M6)
class TutorialDetailScreen extends ConsumerStatefulWidget {
  final String tutorialId;

  const TutorialDetailScreen({
    super.key,
    required this.tutorialId,
  });

  @override
  ConsumerState<TutorialDetailScreen> createState() =>
      _TutorialDetailScreenState();
}

class _TutorialDetailScreenState extends ConsumerState<TutorialDetailScreen> {
  bool _isLaunching = false;

  Future<void> _launchYouTube(String rawUrl) async {
    setState(() => _isLaunching = true);
    final Uri uri = Uri.parse(rawUrl);

    try {
      final bool canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        final bool launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && mounted) {
          _handleLaunchFailure(rawUrl);
        }
      } else {
        if (mounted) {
          _handleLaunchFailure(rawUrl);
        }
      }
    } catch (_) {
      if (mounted) {
        _handleLaunchFailure(rawUrl);
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunching = false);
      }
    }
  }

  /// Penanganan TC-23: Pesan peringatan dan opsi salin tautan saat gagal membuka YouTube
  void _handleLaunchFailure(String rawUrl) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('youtube_error_dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'Gagal Membuka Video',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Aplikasi tidak dapat membuka aplikasi YouTube atau browser eksternal di perangkat Anda.',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.peach),
              ),
              child: SelectableText(
                rawUrl,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryText,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            key: const Key('copy_youtube_link_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Salin Tautan'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: rawUrl));
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tautan YouTube berhasil disalin ke papan klip.'),
                    backgroundColor: AppColors.charcoal,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tutorialAsync = ref.watch(tutorialDetailProvider(widget.tutorialId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Tutorial'),
      ),
      body: SafeArea(
        child: tutorialAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: const <Widget>[
              LoadingSkeleton(height: 200, borderRadius: 16),
              SizedBox(height: 16),
              LoadingSkeleton(height: 32, borderRadius: 8),
              SizedBox(height: 12),
              LoadingSkeleton(height: 120, borderRadius: 12),
            ],
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorState(
                title: 'Gagal Memuat Detail Tutorial',
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(tutorialDetailProvider(widget.tutorialId)),
              ),
            ),
          ),
          data: (Tutorial? tutorial) {
            if (tutorial == null) {
              return const Center(
                child: Text(
                  'Tutorial tidak ditemukan.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: <Widget>[
                // Ikon Topik Soft Butter (Figma 06.02)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.softButter,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.two_wheeler_rounded,
                      color: AppColors.deepTeal,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Judul Panduan
                Text(
                  tutorial.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepTeal,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle / Keterangan Ringan (Figma 06.02)
                Text(
                  tutorial.description ?? 'Pemeriksaan ringan saat motor berhenti di tempat yang aman.',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Langkah Pemeriksaan Bernomor (Figma 06.02)
                _buildNumberedStep(
                  number: '1',
                  title: 'Periksa fisik dan baut',
                  description: 'Lihat apakah komponen terpasang kencang dan tidak ada kebocoran cairan.',
                ),
                const SizedBox(height: 16),
                _buildNumberedStep(
                  number: '2',
                  title: 'Coba fungsi dan kinerja',
                  description: 'Pastikan komponen merespons dengan normal sesuai petunjuk pemakaian.',
                ),
                const SizedBox(height: 16),
                _buildNumberedStep(
                  number: '3',
                  title: 'Dengarkan perubahan',
                  description: 'Bila muncul suara atau getaran yang tidak biasa, segera periksa lebih lanjut.',
                ),
                const SizedBox(height: 28),

                // Tombol Aksi Tonton di YouTube (Figma 06.02: Cari video di YouTube)
                PrimaryButton(
                  key: const Key('watch_on_youtube_button'),
                  label: _isLaunching ? 'Membuka YouTube...' : 'Cari video di YouTube',
                  icon: Icons.play_arrow_rounded,
                  isLoading: _isLaunching,
                  onPressed: () => _launchYouTube(tutorial.youtubeUrl),
                ),
                const SizedBox(height: 12),

                // Opsi Salin Tautan Cepat
                Center(
                  child: TextButton.icon(
                    key: const Key('quick_copy_link_button'),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Salin Tautan Video'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryText,
                    ),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: tutorial.youtubeUrl),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tautan video berhasil disalin ke papan klip.',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNumberedStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.softMint,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.deepTeal,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepTeal,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
