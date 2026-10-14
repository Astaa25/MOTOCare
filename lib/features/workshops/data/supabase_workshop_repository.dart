import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/workshop.dart';
import '../domain/workshop_repository.dart';

/// Implementasi Supabase untuk WorkshopRepository sesuai PRD Bagian 5.1 & 5.3 (RLS)
class SupabaseWorkshopRepository implements WorkshopRepository {
  final SupabaseClient _client;

  SupabaseWorkshopRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<Workshop>> getWorkshops({
    String? query,
    String? cityOrRegency,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      var dbQuery = _client.from('workshops').select();

      if (cityOrRegency != null &&
          cityOrRegency.isNotEmpty &&
          cityOrRegency.toLowerCase() != 'semua') {
        dbQuery = dbQuery.eq('city_or_regency', cityOrRegency);
      }

      if (query != null && query.trim().isNotEmpty) {
        final clean = query.trim();
        dbQuery = dbQuery.or('name.ilike.%$clean%,address.ilike.%$clean%');
      }

      final from = (page - 1) * limit;
      final to = from + limit - 1;

      final response = await dbQuery
          .order('name', ascending: true)
          .range(from, to);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => Workshop.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Workshop>[];
    }
  }

  @override
  Future<Workshop?> getWorkshopById(String id) async {
    try {
      final response = await _client
          .from('workshops')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Workshop.fromJson(response);
    } catch (_) {
      return null;
    }
  }
}
