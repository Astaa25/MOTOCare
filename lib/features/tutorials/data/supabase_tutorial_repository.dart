import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/tutorial.dart';
import '../domain/tutorial_repository.dart';

/// Implementasi Supabase untuk TutorialRepository sesuai PRD Bagian 5.1 & 5.3
class SupabaseTutorialRepository implements TutorialRepository {
  final SupabaseClient _client;

  SupabaseTutorialRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<Tutorial>> getTutorials({
    String? topic,
    String? query,
  }) async {
    try {
      // 1. Coba kueri tabel tutorials tanpa dependensi kolom is_active
      try {
        var dbQuery = _client.from('tutorials').select();

        if (topic != null &&
            topic.isNotEmpty &&
            topic.toLowerCase() != TutorialTopics.all.toLowerCase()) {
          dbQuery = dbQuery.ilike('category', topic);
        }

        if (query != null && query.trim().isNotEmpty) {
          final clean = query.trim();
          dbQuery = dbQuery.or('title.ilike.%$clean%,description.ilike.%$clean%');
        }

        final response = await dbQuery.order('created_at', ascending: false);
        final List<dynamic> data = response as List<dynamic>;

        return data
            .map((json) => Tutorial.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // 2. Fallback jika memakai kolom topic & is_active
        var dbQuery = _client.from('tutorials').select();

        if (topic != null &&
            topic.isNotEmpty &&
            topic.toLowerCase() != TutorialTopics.all.toLowerCase()) {
          dbQuery = dbQuery.ilike('topic', topic);
        }

        if (query != null && query.trim().isNotEmpty) {
          final clean = query.trim();
          dbQuery = dbQuery.or('title.ilike.%$clean%,description.ilike.%$clean%');
        }

        final response = await dbQuery.order('created_at', ascending: false);
        final List<dynamic> data = response as List<dynamic>;

        return data
            .map((json) => Tutorial.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      return <Tutorial>[];
    }
  }

  @override
  Future<Tutorial?> getTutorialById(String id) async {
    try {
      final response = await _client
          .from('tutorials')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Tutorial.fromJson(response);
    } catch (_) {
      return null;
    }
  }
}
