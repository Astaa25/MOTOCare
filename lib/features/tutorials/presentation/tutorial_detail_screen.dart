import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
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
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // Card Media Preview dengan Tombol Play YouTube
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[AppColors.cream, AppColors.peach],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.peach, width: 1.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x33F97316),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Video Panduan Perawatan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.ondemand_video_rounded,
                                size: 14,
                                color: Colors.red,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'YouTube Video',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Topik Chip
                Row(
                  children: <Widget>[
                    StatusChip(
                      label: tutorial.topic,
                      icon: Icons.play_lesson_rounded,
                      backgroundColor: AppColors.cream,
                      textColor: AppColors.primaryText,
                      borderColor: AppColors.peach,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Judul
                Text(
                  tutorial.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Deskripsi
                if (tutorial.description != null &&
                    tutorial.description!.isNotEmpty) ...<Widget>[
                  const Text(
                    'Langkah dan Panduan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      tutorial.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Tombol Aksi Tonton di YouTube
                PrimaryButton(
                  key: const Key('watch_on_youtube_button'),
                  label: _isLaunching ? 'Membuka YouTube...' : 'Tonton di YouTube',
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
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
