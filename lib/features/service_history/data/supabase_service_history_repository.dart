import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../domain/service_history.dart';
import '../domain/service_history_repository.dart';

/// Implementasi SupabaseServiceHistoryRepository menggunakan Supabase client sesuai PRD 5.1 & M4
class SupabaseServiceHistoryRepository implements ServiceHistoryRepository {
  final SupabaseClient _client;

  SupabaseServiceHistoryRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  @override
  Future<Result<List<ServiceHistory>>> getServiceHistories({
    required String motorcycleId,
    String? serviceType,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      dynamic query = _client
          .from('service_histories')
          .select()
          .eq('motorcycle_id', motorcycleId);

      if (serviceType != null && serviceType.trim().isNotEmpty && serviceType != 'Semua') {
        query = query.eq('service_type', serviceType.trim());
      }

      final List<Map<String, dynamic>> response = await query
          .order('service_date', ascending: false)
          .range(offset, offset + limit - 1);

      final list = response.map(ServiceHistory.fromJson).toList();
      return Result.success(list);
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<ServiceHistory>> getServiceHistoryById(String id) async {
    try {
      final response = await _client
          .from('service_histories')
          .select()
          .eq('id', id)
          .single();

      return Result.success(ServiceHistory.fromJson(response));
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<ServiceHistory>> addServiceHistory({
    required String motorcycleId,
    required String userId,
    required DateTime serviceDate,
    required int mileage,
    required String serviceType,
    String? description,
    required int cost,
    String? workshopId,
    String? workshopName,
  }) async {
    try {
      final payload = <String, dynamic>{
        'motorcycle_id': motorcycleId,
        'user_id': userId,
        'service_date': serviceDate.toIso8601String().split('T').first,
        'mileage': mileage,
        'service_type': serviceType.trim(),
        'description': description?.trim(),
        'cost': cost,
        'workshop_id': workshopId,
        'workshop_name': workshopName?.trim(),
      };

      final response = await _client
          .from('service_histories')
          .insert(payload)
          .select()
          .single();

      final newService = ServiceHistory.fromJson(response);

      // Aturan bisnis PRD 7 M4: Perbarui kilometer motor bila kilometer servis lebih besar
      try {
        final motorData = await _client
            .from('motorcycles')
            .select('current_mileage')
            .eq('id', motorcycleId)
            .single();

        final currentKm = motorData['current_mileage'] as int? ?? 0;
        if (mileage > currentKm) {
          await _client.from('motorcycles').update(<String, dynamic>{
            'current_mileage': mileage,
            'mileage_updated_at': DateTime.now().toIso8601String(),
          }).eq('id', motorcycleId);
        }
      } catch (_) {
        // Abaikan kegagalan secondary update jika ada
      }

      return Result.success(newService);
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<ServiceHistory>> updateServiceHistory(ServiceHistory serviceHistory) async {
    try {
      final payload = <String, dynamic>{
        'service_date': serviceHistory.serviceDate.toIso8601String().split('T').first,
        'mileage': serviceHistory.mileage,
        'service_type': serviceHistory.serviceType.trim(),
        'description': serviceHistory.description?.trim(),
        'cost': serviceHistory.cost,
        'workshop_id': serviceHistory.workshopId,
        'workshop_name': serviceHistory.workshopName?.trim(),
      };

      final response = await _client
          .from('service_histories')
          .update(payload)
          .eq('id', serviceHistory.id)
          .select()
          .single();

      final updated = ServiceHistory.fromJson(response);

      // Periksa apakah kilometer lebih besar dari motor saat ini
      try {
        final motorData = await _client
            .from('motorcycles')
            .select('current_mileage')
            .eq('id', serviceHistory.motorcycleId)
            .single();

        final currentKm = motorData['current_mileage'] as int? ?? 0;
        if (serviceHistory.mileage > currentKm) {
          await _client.from('motorcycles').update(<String, dynamic>{
            'current_mileage': serviceHistory.mileage,
            'mileage_updated_at': DateTime.now().toIso8601String(),
          }).eq('id', serviceHistory.motorcycleId);
        }
      } catch (_) {
        // Abaikan
      }

      return Result.success(updated);
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<void>> deleteServiceHistory(String id) async {
    try {
      await _client.from('service_histories').delete().eq('id', id);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<int>> getTotalCost({
    required String motorcycleId,
    String? serviceType,
  }) async {
    try {
      dynamic query = _client
          .from('service_histories')
          .select('cost')
          .eq('motorcycle_id', motorcycleId);

      if (serviceType != null && serviceType.trim().isNotEmpty && serviceType != 'Semua') {
        query = query.eq('service_type', serviceType.trim());
      }

      final List<Map<String, dynamic>> response = await query;
      final int total = response.fold<int>(0, (sum, item) {
        final rawCost = item['cost'];
        if (rawCost is num) return sum + rawCost.toInt();
        if (rawCost is String) return sum + (int.tryParse(rawCost) ?? 0);
        return sum;
      });

      return Result.success(total);
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Stream<List<ServiceHistory>> watchServiceHistories({required String motorcycleId}) {
    return _client
        .from('service_histories')
        .stream(primaryKey: <String>['id'])
        .eq('motorcycle_id', motorcycleId)
        .order('service_date', ascending: false)
        .map((list) => list.map(ServiceHistory.fromJson).toList());
  }
}
