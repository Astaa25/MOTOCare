import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Kartu tutorial perawatan mandiri sesuai PRD 4.3 & M6
class TutorialCard extends StatelessWidget {
  final String title;
  final String topic;
  final String? description;
  final String? thumbnailUrl;
  final VoidCallback onWatchYouTube;
  final VoidCallback? onTap;

  const TutorialCard({
    super.key,
    required this.title,
    required this.topic,
    this.description,
    this.thumbnailUrl,
    required this.onWatchYouTube,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? onWatchYouTube,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Area thumbnail dengan overlay play icon
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    height: 140,
                    color: AppColors.cream,
                    child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.motorcycle_rounded,
                                size: 48,
                                color: AppColors.peach,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.motorcycle_rounded,
                              size: 48,
                              color: AppColors.peach,
                            ),
                          ),
                  ),
                  // Tombol play YouTube bergaya elegan
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                      semanticLabel: 'Tonton Video',
                    ),
                  ),
                  // Tag topik di pojok kiri atas
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        topic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Konten teks
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description != null && description!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'YouTube',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onWatchYouTube,
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text('Buka Video'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryText,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
    );
  }
}
