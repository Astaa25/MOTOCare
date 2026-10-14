import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/env.dart';
import '../data/mock_tutorial_repository.dart';
import '../data/supabase_tutorial_repository.dart';
import '../domain/tutorial.dart';
import '../domain/tutorial_repository.dart';

/// Provider repositori tutorial
final tutorialRepositoryProvider = Provider<TutorialRepository>((ref) {
  if (AppEnv.useMock) {
    return MockTutorialRepository();
  }
  return SupabaseTutorialRepository();
});

/// Topik yang dipilih pengguna pada chip (default 'Semua')
final selectedTutorialTopicProvider = StateProvider<String>((ref) {
  return TutorialTopics.all;
});

/// Query pencarian tutorial
final tutorialSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// Daftar tutorial terfilter sesuai topik dan pencarian
final tutorialsListProvider = FutureProvider<List<Tutorial>>((ref) async {
  final repository = ref.watch(tutorialRepositoryProvider);
  final topic = ref.watch(selectedTutorialTopicProvider);
  final query = ref.watch(tutorialSearchQueryProvider);

  return repository.getTutorials(
    topic: topic,
    query: query,
  );
});

/// Detail tutorial berdasarkan ID
final tutorialDetailProvider =
    FutureProvider.family<Tutorial?, String>((ref, id) async {
  final repository = ref.watch(tutorialRepositoryProvider);
  return repository.getTutorialById(id);
});
