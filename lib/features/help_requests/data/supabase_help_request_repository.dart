import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/help_request_repository.dart';
import '../domain/mechanic.dart';
import '../domain/request_status.dart';
import '../domain/service_request.dart';

/// Implementasi Supabase PostgreSQL dengan RPC sesuai PRD Bagian 5.4 & 6.6
class SupabaseHelpRequestRepository implements HelpRequestRepository {
  final SupabaseClient _client;

  SupabaseHelpRequestRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<ServiceRequest>> getMyRequests({bool? activeOnly}) async {
    try {
      await expireStaleRequests();
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return <ServiceRequest>[];

      var dbQuery = _client
          .from('service_requests')
          .select('*, mechanic:mechanics(*, profile:profiles(*))')
          .eq('user_id', currentUserId);

      if (activeOnly == true) {
        dbQuery = dbQuery.inFilter(
          'status',
          const <String>['pending', 'accepted', 'on_the_way', 'in_progress'],
        );
      }

      final response = await dbQuery.order('created_at', ascending: false);
      final List<dynamic> list = response as List<dynamic>;

      return list
          .map((json) => ServiceRequest.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <ServiceRequest>[];
    }
  }

  @override
  Future<ServiceRequest?> getActiveRequest() async {
    try {
      await expireStaleRequests();
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final response = await _client
          .from('service_requests')
          .select('*, mechanic:mechanics(*, profile:profiles(*))')
          .eq('user_id', currentUserId)
          .inFilter(
            'status',
            const <String>['pending', 'accepted', 'on_the_way', 'in_progress'],
          )
          .maybeSingle();

      if (response == null) return null;
      return ServiceRequest.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ServiceRequest?> getRequestById(String id) async {
    try {
      await expireStaleRequests();

      final response = await _client
          .from('service_requests')
          .select('*, mechanic:mechanics(*, profile:profiles(*))')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return ServiceRequest.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ServiceRequest> createRequest(ServiceRequest request) async {
    try {
      final currentUserId = _client.auth.currentUser?.id ?? request.userId;

      final payload = request.toJson();
      payload['user_id'] = currentUserId;
      payload.remove('id'); // ID dibuat oleh default gen_random_uuid()
      payload.remove('mechanic');

      final response = await _client
          .from('service_requests')
          .insert(payload)
          .select('*, mechanic:mechanics(*, profile:profiles(*))')
          .single();

      return ServiceRequest.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Unique index violation on one_active_request_per_user (PRD 5.1 & 6.6)
        throw ValidationException(
          'Anda masih memiliki permintaan aktif yang sedang diproses.',
          e,
        );
      }
      throw ServerException(
        e.message.isNotEmpty ? e.message : 'Gagal membuat permintaan bantuan.',
        e,
      );
    } catch (e) {
      throw ServerException('Gagal menghubungi server.', e);
    }
  }

  @override
  Future<ServiceRequest> cancelRequest(String requestId) async {
    try {
      // Panggil RPC cancel_request sesuai PRD 5.4
      await _client.rpc(
        'cancel_request',
        params: <String, dynamic>{'p_id': requestId},
      );

      final updated = await getRequestById(requestId);
      if (updated == null) {
        throw const NotFoundException('Permintaan bantuan tidak ditemukan.');
      }
      return updated;
    } on PostgrestException catch (e) {
      throw ValidationException(e.message, e);
    } catch (e) {
      throw ServerException('Gagal membatalkan permintaan.', e);
    }
  }

  @override
  Future<ServiceRequest> advanceRequest(
    String requestId,
    RequestStatus nextStatus, {
    Mechanic? assignedMechanic,
  }) async {
    try {
      // Panggil RPC advance_request sesuai PRD 5.4
      await _client.rpc(
        'advance_request',
        params: <String, dynamic>{
          'p_id': requestId,
          'p_new': nextStatus.dbValue,
        },
      );

      final updated = await getRequestById(requestId);
      if (updated == null) {
        throw const NotFoundException('Permintaan bantuan tidak ditemukan.');
      }
      return updated;
    } on PostgrestException catch (e) {
      throw ValidationException(e.message, e);
    } catch (e) {
      throw ServerException('Gagal memperbarui status permintaan.', e);
    }
  }

  @override
  Future<void> expireStaleRequests() async {
    try {
      // Panggil RPC expire_stale_requests sesuai PRD 5.4
      await _client.rpc('expire_stale_requests');
    } catch (_) {
      // Non-fatal background call
    }
  }

  @override
  Stream<ServiceRequest?> watchRequest(String requestId) {
    return _client
        .from('service_requests')
        .stream(primaryKey: const <String>['id'])
        .eq('id', requestId)
        .map((list) {
          if (list.isEmpty) return null;
          return ServiceRequest.fromJson(list.first);
        });
  }
}
