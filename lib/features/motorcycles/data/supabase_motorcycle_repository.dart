import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../domain/motorcycle.dart';
import '../domain/motorcycle_repository.dart';

/// Implementasi SupabaseMotorcycleRepository menggunakan client Supabase sesuai PRD M3
class SupabaseMotorcycleRepository implements MotorcycleRepository {
  final SupabaseClient _client;

  SupabaseMotorcycleRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  @override
  Future<Result<List<Motorcycle>>> getMotorcycles({required String userId}) async {
    try {
      final List<Map<String, dynamic>> response = await _client
          .from('motorcycles')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final motorcycles = response.map(Motorcycle.fromJson).toList();
      return Result.success(motorcycles);
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<Motorcycle?>> getActiveMotorcycle({required String userId}) async {
    try {
      final response = await _client
          .from('motorcycles')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return const Result.success(null);
      }

      return Result.success(Motorcycle.fromJson(response));
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<Motorcycle>> getMotorcycleById(String id) async {
    try {
      final response = await _client
          .from('motorcycles')
          .select()
          .eq('id', id)
          .single();

      return Result.success(Motorcycle.fromJson(response));
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<Motorcycle>> addMotorcycle({
    required String userId,
    required String brand,
    required String model,
    required int productionYear,
    String? licensePlate,
    required int currentMileage,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from('motorcycles')
          .insert(<String, dynamic>{
            'user_id': userId,
            'brand': brand.trim(),
            'model': model.trim(),
            'production_year': productionYear,
            'license_plate': licensePlate?.trim().toUpperCase(),
            'current_mileage': currentMileage,
            'mileage_updated_at': now,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      return Result.success(Motorcycle.fromJson(response));
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<Motorcycle>> updateMotorcycle(Motorcycle motorcycle) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from('motorcycles')
          .update(<String, dynamic>{
            'brand': motorcycle.brand.trim(),
            'model': motorcycle.model.trim(),
            'production_year': motorcycle.productionYear,
            'license_plate': motorcycle.licensePlate?.trim().toUpperCase(),
            'updated_at': now,
          })
          .eq('id', motorcycle.id)
          .select()
          .single();

      return Result.success(Motorcycle.fromJson(response));
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<Motorcycle>> updateMileage({
    required String motorcycleId,
    required int newMileage,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from('motorcycles')
          .update(<String, dynamic>{
            'current_mileage': newMileage,
            'mileage_updated_at': now,
            'updated_at': now,
          })
          .eq('id', motorcycleId)
          .select()
          .single();

      return Result.success(Motorcycle.fromJson(response));
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<void>> deleteMotorcycle(String id) async {
    try {
      await _client.from('motorcycles').delete().eq('id', id);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Stream<List<Motorcycle>> watchMotorcycles({required String userId}) {
    return _client
        .from('motorcycles')
        .stream(primaryKey: <String>['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((list) => list.map(Motorcycle.fromJson).toList());
  }
}
