import '../../../core/utils/result.dart';
import 'app_notification.dart';

/// Antarmuka repositori notifikasi aplikasi (Pusat Notifikasi In-App)
abstract class NotificationRepository {
  /// Mengambil semua notifikasi untuk pengguna aktif
  Future<Result<List<AppNotification>>> getNotifications();

  /// Mengambil jumlah notifikasi yang belum dibaca
  Future<Result<int>> getUnreadCount();

  /// Menandai satu notifikasi sebagai telah dibaca
  Future<Result<void>> markAsRead(String id);

  /// Menandai semua notifikasi sebagai telah dibaca
  Future<Result<void>> markAllAsRead();

  /// Menambahkan notifikasi baru
  Future<Result<AppNotification>> addNotification(AppNotification notification);

  /// Aliran data reaktif notifikasi
  Stream<List<AppNotification>> watchNotifications();
}
