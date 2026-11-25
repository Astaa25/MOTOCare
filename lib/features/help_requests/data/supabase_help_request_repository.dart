import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/help_request_repository.dart';
import '../domain/mechanic.dart';
import '../domain/request_status.dart';
import '../domain/service_request.dart';

/// Implementasi Supabase PostgreSQL dengan dukungan tabel `assistance_requests`
/// (database produksi Supabase) serta fallback ke `service_requests` (pengujian lokal)
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

      // 1. Coba dari tabel assistance_requests (skema Supabase live)
      try {
        var dbQuery = _client
            .from('assistance_requests')
            .select('*, mechanic:mechanics(*)')
            .eq('user_id', currentUserId);

        if (activeOnly == true) {
          dbQuery = dbQuery.inFilter(
            'status',
            const <String>[
              'MENUNGGU',
              'DITERIMA',
              'SEDANG_DITANGANI',
              'pending',
              'accepted',
              'on_the_way',
              'in_progress',
            ],
          );
        }

        final response = await dbQuery.order('requested_at', ascending: false);
        final List<dynamic> list = response as List<dynamic>;

        return list
            .map((json) => ServiceRequest.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // 2. Fallback ke service_requests jika skema lama
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
      }
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

      try {
        final response = await _client
            .from('assistance_requests')
            .select('*, mechanic:mechanics(*)')
            .eq('user_id', currentUserId)
            .inFilter(
              'status',
              const <String>[
                'MENUNGGU',
                'DITERIMA',
                'SEDANG_DITANGANI',
                'pending',
                'accepted',
                'on_the_way',
                'in_progress',
              ],
            )
            .maybeSingle();

        if (response != null) {
          return ServiceRequest.fromJson(response);
        }
      } catch (_) {
        final response = await _client
            .from('service_requests')
            .select('*, mechanic:mechanics(*, profile:profiles(*))')
            .eq('user_id', currentUserId)
            .inFilter(
              'status',
              const <String>['pending', 'accepted', 'on_the_way', 'in_progress'],
            )
            .maybeSingle();

        if (response != null) {
          return ServiceRequest.fromJson(response);
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ServiceRequest?> getRequestById(String id) async {
    try {
      await expireStaleRequests();

      try {
        final response = await _client
            .from('assistance_requests')
            .select('*, mechanic:mechanics(*)')
            .eq('id', id)
            .maybeSingle();

        if (response != null) {
          return ServiceRequest.fromJson(response);
        }
      } catch (_) {
        final response = await _client
            .from('service_requests')
            .select('*, mechanic:mechanics(*, profile:profiles(*))')
            .eq('id', id)
            .maybeSingle();

        if (response != null) {
          return ServiceRequest.fromJson(response);
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ServiceRequest> createRequest(ServiceRequest request) async {
    try {
      final currentUserId = _client.auth.currentUser?.id ?? request.userId;

      // Coba insert ke assistance_requests terlebih dahulu
      try {
        final livePayload = <String, dynamic>{
          'user_id': currentUserId,
          if (request.motorcycleId != null && request.motorcycleId!.isNotEmpty)
            'vehicle_id': request.motorcycleId,
          'issue_category': request.issueCategory,
          'issue_description': request.issueDescription,
          'latitude': request.latitude ?? 5.1801,
          'longitude': request.longitude ?? 97.1402,
          'manual_address': request.addressText,
          'status': request.status.toLiveDbValue,
          'is_simulation': request.isDemo,
        };

        final response = await _client
            .from('assistance_requests')
            .insert(livePayload)
            .select()
            .single();

        return ServiceRequest.fromJson(response);
      } catch (_) {
        final payload = request.toJson();
        payload['user_id'] = currentUserId;
        payload.remove('id');
        payload.remove('mechanic');

        final response = await _client
            .from('service_requests')
            .insert(payload)
            .select('*, mechanic:mechanics(*, profile:profiles(*))')
            .single();

        return ServiceRequest.fromJson(response);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
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
      try {
        await _client.rpc(
          'cancel_request',
          params: <String, dynamic>{'p_id': requestId},
        );
      } catch (_) {
        // Fallback update langsung jika RPC tidak ada
        try {
          await _client.from('assistance_requests').update(<String, dynamic>{
            'status': 'DIBATALKAN',
          }).eq('id', requestId);
        } catch (_) {
          await _client.from('service_requests').update(<String, dynamic>{
            'status': 'cancelled',
          }).eq('id', requestId);
        }
      }

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
      try {
        await _client.rpc(
          'advance_request',
          params: <String, dynamic>{
            'p_id': requestId,
            'p_new': nextStatus.dbValue,
          },
        );
      } catch (_) {
        // Fallback update status langsung
        try {
          await _client.from('assistance_requests').update(<String, dynamic>{
            'status': nextStatus.toLiveDbValue,
          }).eq('id', requestId);
        } catch (_) {
          await _client.from('service_requests').update(<String, dynamic>{
            'status': nextStatus.dbValue,
          }).eq('id', requestId);
        }
      }

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
      await _client.rpc('expire_stale_requests');
    } catch (_) {
      // Non-fatal background call
    }
  }

  @override
  Stream<ServiceRequest?> watchRequest(String requestId) {
    try {
      return _client
          .from('assistance_requests')
          .stream(primaryKey: const <String>['id'])
          .eq('id', requestId)
          .map((list) {
            if (list.isEmpty) return null;
            return ServiceRequest.fromJson(list.first);
          });
    } catch (_) {
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
}
