import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../domain/app_notification.dart';
import '../domain/notification_repository.dart';

/// Implementasi Supabase PostgreSQL untuk NotificationRepository
class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient _client;

  SupabaseNotificationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<Result<List<AppNotification>>> getNotifications() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const Result<List<AppNotification>>.failure(
          UnauthorizedException('Sesi kedaluwarsa. Silakan masuk kembali.'),
        );
      }

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<AppNotification> list = (response as List<dynamic>)
          .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
          .toList();

      return Result<List<AppNotification>>.success(list);
    } catch (e) {
      return Result<List<AppNotification>>.failure(
        ServerException('Gagal memuat notifikasi dari server.', e),
      );
    }
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const Result<int>.success(0);
      }

      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);

      final count = (response as List<dynamic>).length;
      return Result<int>.success(count);
    } catch (e) {
      return Result<int>.failure(
        ServerException('Gagal menghitung notifikasi belum dibaca.', e),
      );
    }
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    try {
      await _client
          .from('notifications')
          .update(<String, dynamic>{'is_read': true})
          .eq('id', id);

      return const Result<void>.success(null);
    } catch (e) {
      return Result<void>.failure(
        ServerException('Gagal menandai notifikasi dibaca.', e),
      );
    }
  }

  @override
  Future<Result<void>> markAllAsRead() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const Result<void>.success(null);
      }

      await _client
          .from('notifications')
          .update(<String, dynamic>{'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      return const Result<void>.success(null);
    } catch (e) {
      return Result<void>.failure(
        ServerException('Gagal menandai semua notifikasi dibaca.', e),
      );
    }
  }

  @override
  Future<Result<AppNotification>> addNotification(
    AppNotification notification,
  ) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const Result<AppNotification>.failure(
          UnauthorizedException('Sesi kedaluwarsa.'),
        );
      }

      final payload = <String, dynamic>{
        'user_id': user.id,
        'title': notification.title,
        'body': notification.body,
        'type': notification.type.dbValue,
        'is_read': notification.isRead,
        if (notification.relatedId != null) 'related_id': notification.relatedId,
      };

      final response = await _client
          .from('notifications')
          .insert(payload)
          .select()
          .single();

      return Result<AppNotification>.success(
        AppNotification.fromJson(response),
      );
    } catch (e) {
      return Result<AppNotification>.failure(
        ServerException('Gagal menambahkan notifikasi.', e),
      );
    }
  }

  @override
  Stream<List<AppNotification>> watchNotifications() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const Stream<List<AppNotification>>.empty();
    }

    return _client
        .from('notifications')
        .stream(primaryKey: <String>['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((records) => records.map(AppNotification.fromJson).toList());
  }
}
