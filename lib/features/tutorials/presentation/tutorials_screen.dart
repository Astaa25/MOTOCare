import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_effects.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/tutorial.dart';
import 'tutorials_providers.dart';

/// Layar Daftar Tutorial Perawatan Motor Mandiri sesuai PRD Bagian 7 (M6)
class TutorialsScreen extends ConsumerStatefulWidget {
  const TutorialsScreen({super.key});

  @override
  ConsumerState<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends ConsumerState<TutorialsScreen> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(tutorialSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(tutorialSearchQueryProvider.notifier).state = value;
      }
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    ref.read(tutorialSearchQueryProvider.notifier).state = '';
  }

  void _selectTopic(String topic) {
    ref.read(selectedTutorialTopicProvider.notifier).state = topic;
  }

  @override
  Widget build(BuildContext context) {
    final selectedTopic = ref.watch(selectedTutorialTopicProvider);
    final tutorialsAsync = ref.watch(tutorialsListProvider);
    final currentQuery = ref.watch(tutorialSearchQueryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Tutorial Perawatan',
          style: TextStyle(
            color: AppColors.deepTeal,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.deepTeal),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: <Widget>[
          if (AppEnv.showDemoFeatures)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.softPeach,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Simulasi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.action,
                ),
              ),
            ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
          children: <Widget>[
            // Kolom Pencarian dengan Debounce 300ms
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                key: const Key('tutorial_search_field'),
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari panduan servis (misal: oli, rem, busi)...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: currentQuery.isNotEmpty
                      ? IconButton(
                          key: const Key('clear_tutorial_search_button'),
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // Chips Topik Horizontal
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: TutorialTopics.list.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final topic = TutorialTopics.list[index];
                  final isSelected = selectedTopic.toLowerCase() == topic.toLowerCase();

                  return ChoiceChip(
                    key: Key('topic_chip_${topic.replaceAll(' ', '_')}'),
                    label: Text(topic),
                    selected: isSelected,
                    showCheckmark: isSelected,
                    checkmarkColor: AppColors.primary,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      _selectTopic(topic);
                    },
                    selectedColor: AppColors.navIndicator,
                    backgroundColor: AppColors.surfaceBright,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryText : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.4 : 1.0,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Daftar Tutorial
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(tutorialsListProvider);
                },
                child: tutorialsAsync.when(
                  loading: () => LoadingSkeleton.tutorialGrid(),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ErrorState(
                        title: 'Gagal Memuat Tutorial',
                        message: error.toString(),
                        onRetry: () => ref.invalidate(tutorialsListProvider),
                      ),
                    ),
                  ),
                  data: (List<Tutorial> tutorials) {
                    // TC-08: Cari tutorial tanpa hasil -> EmptyState dengan saran topik
                    if (tutorials.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(24),
                        children: <Widget>[
                          const SizedBox(height: 32),
                          EmptyState(
                            key: const Key('empty_tutorials_state'),
                            icon: Icons.search_off_rounded,
                            title: 'Tutorial Tidak Ditemukan',
                            message: currentQuery.isNotEmpty
                                ? 'Tidak ada tutorial untuk pencarian "$currentQuery". Silakan pilih topik saran perawatan di bawah:'
                                : 'Belum ada tutorial untuk topik "$selectedTopic". Coba pilih topik lain:',
                            actionLabel: currentQuery.isNotEmpty ? 'Reset Pencarian' : null,
                            onAction: currentQuery.isNotEmpty ? _clearSearch : null,
                            extraContent: Column(
                              children: <Widget>[
                                const Text(
                                  'Saran Topik Perawatan Populer:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: <Widget>[
                                    _buildTopicSuggestionChip(TutorialTopics.gantiOli),
                                    _buildTopicSuggestionChip(TutorialTopics.rem),
                                    _buildTopicSuggestionChip(TutorialTopics.rantai),
                                    _buildTopicSuggestionChip(TutorialTopics.busi),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, AppTokens.tabContentBottomPadding),
                      itemCount: tutorials.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final tutorial = tutorials[index];
                        return AnimatedEntrance(
                          index: index,
                          child: _TutorialCard(
                            tutorial: tutorial,
                            onTap: () => context.push('/tutorials/${tutorial.id}'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildTopicSuggestionChip(String topic) {
    return ActionChip(
      key: Key('suggested_topic_${topic.replaceAll(' ', '_')}'),
      label: Text(topic),
      avatar: const Icon(
        Icons.check_circle_outline_rounded,
        size: 16,
        color: AppColors.primary,
      ),
      backgroundColor: AppColors.cream,
      labelStyle: const TextStyle(
        color: AppColors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.peach),
      ),
      onPressed: () {
        _clearSearch();
        _selectTopic(topic);
      },
    );
  }
}

/// Kartu Tutorial dengan Estetika Premium MotoCare
class _TutorialCard extends StatelessWidget {
  final Tutorial tutorial;
  final VoidCallback onTap;

  const _TutorialCard({
    required this.tutorial,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveHoverCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFF0EAE1),
      padding: const EdgeInsets.all(14),
      child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Ikon dalam squircle Soft Peach (Figma 06.01)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.softPeach,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 22,
                  color: AppColors.deepTeal,
                ),
              ),
              const SizedBox(width: 14),

              // Detail Tutorial
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: StatusChip(
                            label: tutorial.topic,
                            icon: Icons.play_lesson_rounded,
                            backgroundColor: AppColors.softButter,
                            textColor: AppColors.deepTeal,
                            borderColor: const Color(0xFFF0EAE1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'YouTube',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tutorial.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepTeal,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tutorial.description != null &&
                        tutorial.description!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        tutorial.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
    );
  }
}
