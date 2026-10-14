import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../reminders/domain/maintenance_reminder.dart';
import '../../reminders/domain/reminder_rules.dart';
import '../../reminders/domain/reminder_status.dart';
import '../domain/app_notification.dart';
import '../domain/notification_repository.dart';

/// Kontrak layanan notifikasi (Lokal & In-App) sesuai PRD Bagian 6.5 & 7 (M5)
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> scheduleLocalReminder(MaintenanceReminder reminder);
  Future<void> cancelLocalReminder(String reminderId);
  Future<void> syncReminderNotifications({
    required List<MaintenanceReminder> reminders,
    required int currentMileage,
    required NotificationRepository notificationRepository,
    required String currentUserId,
  });
}

/// Implementasi nyata NotificationService menggunakan flutter_local_notifications dan timezone
class AppNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _localPlugin;
  bool _isInitialized = false;

  AppNotificationService({FlutterLocalNotificationsPlugin? localPlugin})
      : _localPlugin = localPlugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inisialisasi basis data zona waktu
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {
        // Fallback jika zona waktu Asia/Jakarta belum termuat
      }

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _localPlugin.initialize(initSettings);
      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error (graceful): $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final androidPlatform = _localPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final bool? granted =
            await androidPlatform.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      // Graceful fallback sesuai PRD 6.5
      debugPrint('Notification permission error (graceful): $e');
      return false;
    }
  }

  @override
  Future<void> scheduleLocalReminder(MaintenanceReminder reminder) async {
    if (reminder.reminderDate == null || reminder.isCompleted) return;

    try {
      final DateTime targetDate = reminder.reminderDate!;
      final tz.Location location = tz.local;

      // 1. Jadwalkan pada H-7 pukul 08:00 WIB
      final DateTime d7 = targetDate.subtract(const Duration(days: 7));
      final tz.TZDateTime scheduledD7 = tz.TZDateTime(
        location,
        d7.year,
        d7.month,
        d7.day,
        8,
        0,
      );

      final int idH7 = (reminder.id.hashCode & 0x7FFFFFFF) % 100000;

      if (scheduledD7.isAfter(tz.TZDateTime.now(location))) {
        await _localPlugin.zonedSchedule(
          idH7,
          'Pengingat Servis MotoCare',
          '${reminder.title}: Jatuh tempo dalam 7 hari lagi.',
          scheduledD7,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'motocare_reminders',
              'Pengingat Servis',
              channelDescription: 'Pengingat jadwal perawatan berkala motor Anda',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // 2. Jadwalkan pada Hari H pukul 08:00 WIB
      final tz.TZDateTime scheduledDay = tz.TZDateTime(
        location,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        8,
        0,
      );

      final int idDay = ((reminder.id.hashCode + 1) & 0x7FFFFFFF) % 100000;

      if (scheduledDay.isAfter(tz.TZDateTime.now(location))) {
        await _localPlugin.zonedSchedule(
          idDay,
          'Waktunya Servis Hari Ini!',
          '${reminder.title}: Hari ini adalah jadwal servis yang telah direncanakan.',
          scheduledDay,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'motocare_reminders',
              'Pengingat Servis',
              channelDescription: 'Pengingat jadwal perawatan berkala motor Anda',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      // Penolakan atau kegagalan penjadwalan tidak menimbulkan error bagi pengguna
      debugPrint('Schedule local notification failed (graceful): $e');
    }
  }

  @override
  Future<void> cancelLocalReminder(String reminderId) async {
    try {
      final int idH7 = (reminderId.hashCode & 0x7FFFFFFF) % 100000;
      final int idDay = ((reminderId.hashCode + 1) & 0x7FFFFFFF) % 100000;
      await _localPlugin.cancel(idH7);
      await _localPlugin.cancel(idDay);
    } catch (e) {
      debugPrint('Cancel local reminder failed: $e');
    }
  }

  @override
  Future<void> syncReminderNotifications({
    required List<MaintenanceReminder> reminders,
    required int currentMileage,
    required NotificationRepository notificationRepository,
    required String currentUserId,
  }) async {
    final notifsRes = await notificationRepository.getNotifications();
    final existingNotifs = notifsRes.dataOrNull ?? <AppNotification>[];

    final DateTime today = DateTime.now();

    for (final reminder in reminders) {
      if (reminder.isCompleted) continue;

      final ReminderStatus status = computeReminderStatus(
        status: reminder.status,
        reminderDate: reminder.reminderDate,
        targetMileage: reminder.targetMileage,
        currentMileage: currentMileage,
        today: today,
      );

      // Hanya status near atau overdue yang memicu notifikasi in-app
      if (status == ReminderStatus.near || status == ReminderStatus.overdue) {
        final String expectedTitle = status == ReminderStatus.overdue
            ? 'Jadwal Servis Terlambat: ${reminder.title}'
            : 'Segera Servis: ${reminder.title}';

        // PRD 6.5 Aturan #2: Cegah notifikasi ganda untuk perubahan status yang sama
        final bool alreadyExists = existingNotifs.any(
          (n) => n.relatedId == reminder.id && n.title == expectedTitle,
        );

        if (!alreadyExists) {
          final String body = status == ReminderStatus.overdue
              ? 'Pengingat ${reminder.title} sudah melampaui batas yang ditentukan. Segera jadwalkan perawatan motor Anda.'
              : 'Pengingat ${reminder.title} mendekati batas waktu atau kilometer yang ditargetkan.';

          await notificationRepository.addNotification(
            AppNotification(
              id: '',
              userId: currentUserId,
              title: expectedTitle,
              body: body,
              type: NotificationType.reminder,
              isRead: false,
              relatedId: reminder.id,
              createdAt: DateTime.now(),
            ),
          );
        }
      }
    }
  }
}

/// Implementasi Mock NotificationService untuk pengujian tanpa dependensi native channel
class MockNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleLocalReminder(MaintenanceReminder reminder) async {}

  @override
  Future<void> cancelLocalReminder(String reminderId) async {}

  @override
  Future<void> syncReminderNotifications({
    required List<MaintenanceReminder> reminders,
    required int currentMileage,
    required NotificationRepository notificationRepository,
    required String currentUserId,
  }) async {}
}
