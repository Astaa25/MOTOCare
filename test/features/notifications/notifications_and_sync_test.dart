import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/notifications/data/mock_notification_repository.dart';
import 'package:motocare/features/notifications/domain/app_notification.dart';
import 'package:motocare/features/notifications/services/notification_service.dart';
import 'package:motocare/features/reminders/domain/maintenance_reminder.dart';
import 'package:motocare/features/reminders/domain/reminder_status.dart';

void main() {
  group('TC-06 & TC-07: Notifications & Sync Unit Tests', () {
    late MockNotificationRepository notifRepo;
    late AppNotificationService notifService;

    setUp(() {
      notifRepo = MockNotificationRepository(
        simulateDelay: false,
        populateDemoData: false,
      );
      notifService = AppNotificationService();
    });

    test('TC-07: Menandai notifikasi dibaca dan unread count berkurang', () async {
      await notifRepo.addNotification(
        AppNotification(
          id: 'n1',
          userId: 'u1',
          title: 'Notifikasi 1',
          body: 'Isi notifikasi 1',
          type: NotificationType.system,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      await notifRepo.addNotification(
        AppNotification(
          id: 'n2',
          userId: 'u1',
          title: 'Notifikasi 2',
          body: 'Isi notifikasi 2',
          type: NotificationType.reminder,
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      int count = (await notifRepo.getUnreadCount()).dataOrNull!;
      expect(count, equals(2));

      // Tandai satu dibaca
      final markRes = await notifRepo.markAsRead('n1');
      expect(markRes.isSuccess, isTrue);

      count = (await notifRepo.getUnreadCount()).dataOrNull!;
      expect(count, equals(1));

      // Tandai semua dibaca
      final markAllRes = await notifRepo.markAllAsRead();
      expect(markAllRes.isSuccess, isTrue);

      count = (await notifRepo.getUnreadCount()).dataOrNull!;
      expect(count, equals(0));
    });

    test('TC-06: Status near/overdue menghasilkan notifikasi in-app dan tidak ada duplikasi', () async {
      final now = DateTime.now();

      final reminderNear = MaintenanceReminder(
        id: 'rem-near-1',
        motorcycleId: 'm1',
        userId: 'u1',
        title: 'Cek Rem Depan',
        reminderDate: now.add(const Duration(days: 3)), // Near (<= 7 hari)
        status: StoredReminderStatus.active,
        createdAt: now.subtract(const Duration(days: 20)),
      );

      final reminderScheduled = MaintenanceReminder(
        id: 'rem-sched-1',
        motorcycleId: 'm1',
        userId: 'u1',
        title: 'Ganti Ban Belakang',
        reminderDate: now.add(const Duration(days: 30)), // Scheduled (> 7 hari)
        status: StoredReminderStatus.active,
        createdAt: now.subtract(const Duration(days: 10)),
      );

      // Sinkronisasi pertama
      await notifService.syncReminderNotifications(
        reminders: <MaintenanceReminder>[reminderNear, reminderScheduled],
        currentMileage: 10000,
        notificationRepository: notifRepo,
        currentUserId: 'u1',
      );

      var notifs = (await notifRepo.getNotifications()).dataOrNull!;
      // Hanya reminderNear yang menghasilkan notifikasi
      expect(notifs.length, equals(1));
      expect(notifs.first.title, contains('Segera Servis: Cek Rem Depan'));
      expect(notifs.first.relatedId, equals('rem-near-1'));

      // Sinkronisasi ulang kedua (PRD 6.5 #2: Tidak boleh ada notifikasi ganda)
      await notifService.syncReminderNotifications(
        reminders: <MaintenanceReminder>[reminderNear, reminderScheduled],
        currentMileage: 10000,
        notificationRepository: notifRepo,
        currentUserId: 'u1',
      );

      notifs = (await notifRepo.getNotifications()).dataOrNull!;
      expect(notifs.length, equals(1)); // Tetap 1, tidak ada duplikat!
    });

    test('Serialisasi toJson dan deserialisasi fromJson AppNotification konsisten', () {
      final notif = AppNotification(
        id: 'notif-123',
        userId: 'user-456',
        title: 'Panggilan Montir Selesai',
        body: 'Mekanik telah menyelesaikan perbaikan.',
        type: NotificationType.requestStatus,
        isRead: true,
        relatedId: 'req-789',
        createdAt: DateTime(2026, 10, 14, 10, 30),
      );

      final json = notif.toJson();
      final parsed = AppNotification.fromJson(json);

      expect(parsed.id, equals(notif.id));
      expect(parsed.userId, equals(notif.userId));
      expect(parsed.title, equals(notif.title));
      expect(parsed.body, equals(notif.body));
      expect(parsed.type, equals(NotificationType.requestStatus));
      expect(parsed.isRead, isTrue);
      expect(parsed.relatedId, equals(notif.relatedId));
    });
  });
}
