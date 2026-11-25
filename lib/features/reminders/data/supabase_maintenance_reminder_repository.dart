import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../domain/maintenance_reminder.dart';
import '../domain/maintenance_reminder_repository.dart';
import '../domain/reminder_rules.dart';

/// Implementasi Supabase PostgreSQL untuk MaintenanceReminderRepository
/// Mendukung tabel `service_reminders` (live Supabase) dan fallback ke `maintenance_reminders`
class SupabaseMaintenanceReminderRepository implements MaintenanceReminderRepository {
  final SupabaseClient _client;

  SupabaseMaintenanceReminderRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<Result<List<MaintenanceReminder>>> getRemindersByMotorcycle(
    String motorcycleId,
  ) async {
    try {
      List<dynamic> response;
      try {
        response = await _client
            .from('service_reminders')
            .select()
            .eq('vehicle_id', motorcycleId)
            .order('created_at', ascending: false);
      } catch (_) {
        response = await _client
            .from('maintenance_reminders')
            .select()
            .eq('motorcycle_id', motorcycleId)
            .order('created_at', ascending: false);
      }

      final List<MaintenanceReminder> list = response
          .map((json) => MaintenanceReminder.fromJson(json as Map<String, dynamic>))
          .toList();

      return Result<List<MaintenanceReminder>>.success(list);
    } catch (e) {
      return Result<List<MaintenanceReminder>>.failure(
        ServerException('Gagal memuat pengingat servis dari server.', e),
      );
    }
  }

  @override
  Future<Result<MaintenanceReminder>> getReminderById(String id) async {
    try {
      Map<String, dynamic>? response;
      try {
        response = await _client
            .from('service_reminders')
            .select()
            .eq('id', id)
            .maybeSingle();
      } catch (_) {
        response = await _client
            .from('maintenance_reminders')
            .select()
            .eq('id', id)
            .maybeSingle();
      }

      if (response == null) {
        return const Result<MaintenanceReminder>.failure(
          NotFoundException('Pengingat servis tidak ditemukan.'),
        );
      }

      return Result<MaintenanceReminder>.success(
        MaintenanceReminder.fromJson(response),
      );
    } catch (e) {
      return Result<MaintenanceReminder>.failure(
        ServerException('Gagal memuat detail pengingat.', e),
      );
    }
  }

  @override
  Future<Result<MaintenanceReminder>> addReminder(
    MaintenanceReminder reminder,
  ) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const Result<MaintenanceReminder>.failure(
          UnauthorizedException('Sesi kedaluwarsa. Silakan masuk kembali.'),
        );
      }

      Map<String, dynamic> response;
      try {
        final dateStr = reminder.reminderDate != null
            ? '${reminder.reminderDate!.year.toString().padLeft(4, '0')}-${reminder.reminderDate!.month.toString().padLeft(2, '0')}-${reminder.reminderDate!.day.toString().padLeft(2, '0')}'
            : null;

        response = await _client
            .from('service_reminders')
            .insert(<String, dynamic>{
              'vehicle_id': reminder.motorcycleId,
              'service_type': reminder.serviceType ?? reminder.title,
              'target_date': ?dateStr,
              'target_km': ?reminder.targetMileage,
              'status': reminder.status.dbValue,
              'notes': reminder.title,
            })
            .select()
            .single();
      } catch (_) {
        final payload = <String, dynamic>{
          'motorcycle_id': reminder.motorcycleId,
          'user_id': user.id,
          'title': reminder.title,
          if (reminder.reminderDate != null)
            'reminder_date':
                '${reminder.reminderDate!.year.toString().padLeft(4, '0')}-${reminder.reminderDate!.month.toString().padLeft(2, '0')}-${reminder.reminderDate!.day.toString().padLeft(2, '0')}',
          if (reminder.targetMileage != null)
            'target_mileage': reminder.targetMileage,
          'status': reminder.status.dbValue,
        };

        response = await _client
            .from('maintenance_reminders')
            .insert(payload)
            .select()
            .single();
      }

      return Result<MaintenanceReminder>.success(
        MaintenanceReminder.fromJson(response),
      );
    } catch (e) {
      return Result<MaintenanceReminder>.failure(
        ServerException('Gagal menyimpan pengingat servis.', e),
      );
    }
  }

  @override
  Future<Result<MaintenanceReminder>> updateReminder(
    MaintenanceReminder reminder,
  ) async {
    try {
      Map<String, dynamic> response;
      try {
        final dateStr = reminder.reminderDate != null
            ? '${reminder.reminderDate!.year.toString().padLeft(4, '0')}-${reminder.reminderDate!.month.toString().padLeft(2, '0')}-${reminder.reminderDate!.day.toString().padLeft(2, '0')}'
            : null;

        response = await _client
            .from('service_reminders')
            .update(<String, dynamic>{
              'service_type': reminder.serviceType ?? reminder.title,
              'target_date': dateStr,
              'target_km': reminder.targetMileage,
              'status': reminder.status.dbValue,
              'notes': reminder.title,
            })
            .eq('id', reminder.id)
            .select()
            .single();
      } catch (_) {
        final payload = <String, dynamic>{
          'title': reminder.title,
          'reminder_date': reminder.reminderDate != null
              ? '${reminder.reminderDate!.year.toString().padLeft(4, '0')}-${reminder.reminderDate!.month.toString().padLeft(2, '0')}-${reminder.reminderDate!.day.toString().padLeft(2, '0')}'
              : null,
          'target_mileage': reminder.targetMileage,
          'status': reminder.status.dbValue,
          if (reminder.completedAt != null)
            'completed_at': reminder.completedAt!.toIso8601String(),
        };

        response = await _client
            .from('maintenance_reminders')
            .update(payload)
            .eq('id', reminder.id)
            .select()
            .single();
      }

      return Result<MaintenanceReminder>.success(
        MaintenanceReminder.fromJson(response),
      );
    } catch (e) {
      return Result<MaintenanceReminder>.failure(
        ServerException('Gagal memperbarui pengingat servis.', e),
      );
    }
  }

  @override
  Future<Result<void>> deleteReminder(String id) async {
    try {
      try {
        await _client.from('service_reminders').delete().eq('id', id);
      } catch (_) {
        await _client.from('maintenance_reminders').delete().eq('id', id);
      }
      return const Result<void>.success(null);
    } catch (e) {
      return Result<void>.failure(
        ServerException('Gagal menghapus pengingat servis.', e),
      );
    }
  }

  @override
  Future<Result<MaintenanceReminder>> completeReminder(
    String id, {
    required int serviceMileage,
    required DateTime serviceDate,
  }) async {
    try {
      final getRes = await getReminderById(id);
      if (getRes.isFailure) {
        return getRes;
      }

      final MaintenanceReminder current = getRes.dataOrNull!;
      final DateTime now = DateTime.now();

      Map<String, dynamic> updateRes;
      try {
        updateRes = await _client
            .from('service_reminders')
            .update(<String, dynamic>{
              'status': 'SELESAI',
            })
            .eq('id', id)
            .select()
            .single();
      } catch (_) {
        updateRes = await _client
            .from('maintenance_reminders')
            .update(<String, dynamic>{
              'status': 'completed',
              'completed_at': now.toIso8601String(),
            })
            .eq('id', id)
            .select()
            .single();
      }

      final MaintenanceReminder completed =
          MaintenanceReminder.fromJson(updateRes);

      // Otomatis jadwalkan pengingat berikutnya jika ada interval
      if (current.intervalKm != null || current.intervalMonths != null) {
        final MaintenanceReminder next = createNextReminder(
          currentReminder: current,
          serviceMileage: serviceMileage,
          serviceDate: serviceDate,
          newId: '',
        );
        await addReminder(next);
      }

      return Result<MaintenanceReminder>.success(completed);
    } catch (e) {
      return Result<MaintenanceReminder>.failure(
        ServerException('Gagal menyelesaikan pengingat servis.', e),
      );
    }
  }

  @override
  Stream<List<MaintenanceReminder>> watchReminders(String motorcycleId) {
    try {
      return _client
          .from('service_reminders')
          .stream(primaryKey: <String>['id'])
          .eq('vehicle_id', motorcycleId)
          .order('created_at', ascending: false)
          .map((records) => records.map(MaintenanceReminder.fromJson).toList());
    } catch (_) {
      return _client
          .from('maintenance_reminders')
          .stream(primaryKey: <String>['id'])
          .eq('motorcycle_id', motorcycleId)
          .order('created_at', ascending: false)
          .map((records) => records.map(MaintenanceReminder.fromJson).toList());
    }
  }
}
