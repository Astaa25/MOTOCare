import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../domain/motorcycle.dart';
import '../domain/motorcycle_repository.dart';
import 'motorcycle_catalog.dart';

/// Implementasi SupabaseMotorcycleRepository menggunakan client Supabase sesuai PRD M3
/// Mendukung tabel `vehicles` (skema Supabase produksi live) dan fallback ke `motorcycles`
class SupabaseMotorcycleRepository implements MotorcycleRepository {
  final SupabaseClient _client;

  SupabaseMotorcycleRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  @override
  Future<Result<List<Motorcycle>>> getMotorcycles({required String userId}) async {
    try {
      List<Map<String, dynamic>> response;
      try {
        response = await _client
            .from('vehicles')
            .select()
            .eq('owner_id', userId)
            .order('created_at', ascending: false);
      } catch (_) {
        response = await _client
            .from('motorcycles')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
      }

      final motorcycles = response.map(Motorcycle.fromJson).toList();
      return Result.success(motorcycles);
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<Motorcycle?>> getActiveMotorcycle({required String userId}) async {
    try {
      Map<String, dynamic>? response;
      try {
        response = await _client
            .from('vehicles')
            .select()
            .eq('owner_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
      } catch (_) {
        response = await _client
            .from('motorcycles')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
      }

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
      Map<String, dynamic> response;
      try {
        response = await _client
            .from('vehicles')
            .select()
            .eq('id', id)
            .single();
      } catch (_) {
        response = await _client
            .from('motorcycles')
            .select()
            .eq('id', id)
            .single();
      }

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
    String? color,
    String? category,
    int? engineCc,
    String? transmission,
    String? fuelType,
    String? photoUrl,
  }) async {
    final spec = MotorcycleCatalog.findSpec(brand, model);
    final resolvedColor =
        (color != null && color.trim().isNotEmpty) ? color.trim() : spec.defaultColor;
    final resolvedCategory =
        (category != null && category.trim().isNotEmpty) ? category.trim() : spec.category;
    final resolvedCc = engineCc ?? spec.engineCc;
    final resolvedTrans = (transmission != null && transmission.trim().isNotEmpty)
        ? transmission.trim()
        : spec.transmission;
    final resolvedFuel =
        (fuelType != null && fuelType.trim().isNotEmpty) ? fuelType.trim() : spec.fuelType;
    final resolvedPhoto =
        (photoUrl != null && photoUrl.trim().isNotEmpty) ? photoUrl.trim() : spec.assetPath;

    try {
      try {
        // Coba insert lengkap dengan kolom detail (jika migrasi 0006 sudah diterapkan)
        final response = await _client
            .from('vehicles')
            .insert(<String, dynamic>{
              'owner_id': userId,
              'brand': brand.trim(),
              'model': model.trim(),
              'production_year': productionYear,
              'license_plate': licensePlate?.trim().toUpperCase(),
              'current_km': currentMileage,
              'color': resolvedColor,
              'category': resolvedCategory,
              'engine_cc': resolvedCc,
              'transmission': resolvedTrans,
              'fuel_type': resolvedFuel,
              'photo_url': resolvedPhoto,
              'is_simulation': false,
            })
            .select()
            .single();
        return Result.success(Motorcycle.fromJson(response));
      } catch (_) {
        // Fallback aman bila skema Supabase live belum memiliki kolom detail 0006
        try {
          final response = await _client
              .from('vehicles')
              .insert(<String, dynamic>{
                'owner_id': userId,
                'brand': brand.trim(),
                'model': model.trim(),
                'production_year': productionYear,
                'license_plate': licensePlate?.trim().toUpperCase(),
                'current_km': currentMileage,
                'is_simulation': false,
              })
              .select()
              .single();
          return Result.success(
            Motorcycle.fromJson(response).copyWith(
              color: resolvedColor,
              category: resolvedCategory,
              engineCc: resolvedCc,
              transmission: resolvedTrans,
              fuelType: resolvedFuel,
              photoUrl: resolvedPhoto,
            ),
          );
        } catch (_) {
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
                'color': resolvedColor,
                'category': resolvedCategory,
                'engine_cc': resolvedCc,
                'transmission': resolvedTrans,
                'fuel_type': resolvedFuel,
                'photo_url': resolvedPhoto,
                'created_at': now,
                'updated_at': now,
              })
              .select()
              .single();
          return Result.success(Motorcycle.fromJson(response));
        }
      }
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<Motorcycle>> updateMotorcycle(Motorcycle motorcycle) async {
    try {
      final now = DateTime.now().toIso8601String();
      Map<String, dynamic> response;
      try {
        response = await _client
            .from('vehicles')
            .update(<String, dynamic>{
              'brand': motorcycle.brand.trim(),
              'model': motorcycle.model.trim(),
              'production_year': motorcycle.productionYear,
              'license_plate': motorcycle.licensePlate?.trim().toUpperCase(),
              'color': motorcycle.resolvedColor,
              'category': motorcycle.resolvedCategory,
              'engine_cc': motorcycle.resolvedEngineCc,
              'transmission': motorcycle.resolvedTransmission,
              'fuel_type': motorcycle.resolvedFuelType,
              'photo_url': motorcycle.resolvedPhotoPath,
              'updated_at': now,
            })
            .eq('id', motorcycle.id)
            .select()
            .single();
      } catch (_) {
        try {
          response = await _client
              .from('vehicles')
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
        } catch (_) {
          response = await _client
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
        }
      }

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
      Map<String, dynamic> response;
      try {
        response = await _client
            .from('vehicles')
            .update(<String, dynamic>{
              'current_km': newMileage,
              'updated_at': now,
            })
            .eq('id', motorcycleId)
            .select()
            .single();
      } catch (_) {
        response = await _client
            .from('motorcycles')
            .update(<String, dynamic>{
              'current_mileage': newMileage,
              'mileage_updated_at': now,
              'updated_at': now,
            })
            .eq('id', motorcycleId)
            .select()
            .single();
      }

      return Result.success(Motorcycle.fromJson(response));
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Future<Result<void>> deleteMotorcycle(String id) async {
    try {
      try {
        await _client.from('vehicles').delete().eq('id', id);
      } catch (_) {
        await _client.from('motorcycles').delete().eq('id', id);
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(AppException.fromError(e));
    }
  }

  @override
  Stream<List<Motorcycle>> watchMotorcycles({required String userId}) {
    try {
      return _client
          .from('vehicles')
          .stream(primaryKey: <String>['id'])
          .eq('owner_id', userId)
          .order('created_at', ascending: false)
          .map((list) => list.map(Motorcycle.fromJson).toList());
    } catch (_) {
      return _client
          .from('motorcycles')
          .stream(primaryKey: <String>['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .map((list) => list.map(Motorcycle.fromJson).toList());
    }
  }
}
