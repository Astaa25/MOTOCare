import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/errors/app_exception.dart';
import 'package:motocare/features/help_requests/data/mock_help_request_repository.dart';
import 'package:motocare/features/help_requests/domain/help_request_rules.dart';
import 'package:motocare/features/help_requests/domain/mechanic.dart';
import 'package:motocare/features/help_requests/domain/request_status.dart';
import 'package:motocare/features/help_requests/domain/service_request.dart';

void main() {
  group('HelpRequestRules Unit Tests (PRD 5.1, 5.4, 6.6, 6.7)', () {
    group('validateIssueDescription (TC-11)', () {
      test('mengembalikan error jika deskripsi kosong atau null', () {
        expect(
          HelpRequestRules.validateIssueDescription(null),
          'Deskripsi masalah wajib diisi.',
        );
        expect(
          HelpRequestRules.validateIssueDescription('   '),
          'Deskripsi masalah wajib diisi.',
        );
      });

      test('mengembalikan error jika deskripsi kurang dari 10 karakter', () {
        final result = HelpRequestRules.validateIssueDescription('Mogok');
        expect(result, contains('minimal 10 karakter'));
      });

      test('mengembalikan error jika deskripsi lebih dari 500 karakter', () {
        final longDesc = 'A' * 501;
        final result = HelpRequestRules.validateIssueDescription(longDesc);
        expect(result, contains('maksimal 500 karakter'));
      });

      test('mengembalikan null jika deskripsi valid antara 10 - 500 karakter', () {
        expect(
          HelpRequestRules.validateIssueDescription('Ban bocor di depan pom bensin.'),
          isNull,
        );
        expect(
          HelpRequestRules.validateIssueDescription('A' * 500),
          isNull,
        );
      });
    });

    group('validateAddress (TC-11)', () {
      test('mengembalikan error jika tanpa koordinat GPS dan alamat kurang dari 5 karakter', () {
        expect(
          HelpRequestRules.validateAddress(
            addressText: 'Jl.',
            latitude: null,
            longitude: null,
          ),
          'Alamat lokasi penjemputan minimal 5 karakter atau aktifkan GPS.',
        );
      });

      test('mengembalikan null jika alamat >= 5 karakter walau tanpa GPS', () {
        expect(
          HelpRequestRules.validateAddress(
            addressText: 'Jalan Merdeka No. 10',
            latitude: null,
            longitude: null,
          ),
          isNull,
        );
      });

      test('mengembalikan null jika koordinat GPS tersedia walau alamat teks kosong', () {
        expect(
          HelpRequestRules.validateAddress(
            addressText: '',
            latitude: -6.200000,
            longitude: 106.816666,
          ),
          isNull,
        );
      });
    });

    group('validateContactPhone (TC-11)', () {
      test('mengembalikan error jika nomor kontak null atau kosong', () {
        expect(
          HelpRequestRules.validateContactPhone(null),
          'Nomor kontak telepon wajib diisi.',
        );
        expect(
          HelpRequestRules.validateContactPhone('   '),
          'Nomor kontak telepon wajib diisi.',
        );
      });

      test('mengembalikan error jika format bukan angka 8-15 digit', () {
        expect(
          HelpRequestRules.validateContactPhone('12345'),
          contains('8 sampai 15 digit'),
        );
        expect(
          HelpRequestRules.validateContactPhone('081234567890123456'),
          contains('8 sampai 15 digit'),
        );
        expect(
          HelpRequestRules.validateContactPhone('0812abc3456'),
          contains('8 sampai 15 digit'),
        );
      });

      test('mengembalikan null jika format nomor telepon valid', () {
        expect(HelpRequestRules.validateContactPhone('08123456789'), isNull);
        expect(HelpRequestRules.validateContactPhone('+6281234567890'), isNull);
        expect(HelpRequestRules.validateContactPhone('0812-3456-7890'), isNull);
      });
    });

    group('canCancel & requiresCancelWarning (TC-20)', () {
      test('status yang diizinkan batal: pending, accepted, onTheWay', () {
        expect(HelpRequestRules.canCancel(RequestStatus.pending), isTrue);
        expect(HelpRequestRules.canCancel(RequestStatus.accepted), isTrue);
        expect(HelpRequestRules.canCancel(RequestStatus.onTheWay), isTrue);
      });

      test('status yang TIDAK diizinkan batal: inProgress, completed, cancelled, expired, rejected', () {
        expect(HelpRequestRules.canCancel(RequestStatus.inProgress), isFalse);
        expect(HelpRequestRules.canCancel(RequestStatus.completed), isFalse);
        expect(HelpRequestRules.canCancel(RequestStatus.cancelled), isFalse);
        expect(HelpRequestRules.canCancel(RequestStatus.expired), isFalse);
        expect(HelpRequestRules.canCancel(RequestStatus.rejected), isFalse);
      });

      test('hanya status onTheWay yang membutuhkan dialog peringatan khusus', () {
        expect(HelpRequestRules.requiresCancelWarning(RequestStatus.onTheWay), isTrue);
        expect(HelpRequestRules.requiresCancelWarning(RequestStatus.pending), isFalse);
        expect(HelpRequestRules.requiresCancelWarning(RequestStatus.accepted), isFalse);
        expect(HelpRequestRules.requiresCancelWarning(RequestStatus.inProgress), isFalse);
      });
    });

    group('isValidStatusAdvance', () {
      test('transisi yang sah', () {
        expect(
          HelpRequestRules.isValidStatusAdvance(RequestStatus.pending, RequestStatus.accepted),
          isTrue,
        );
        expect(
          HelpRequestRules.isValidStatusAdvance(RequestStatus.pending, RequestStatus.rejected),
          isTrue,
        );
        expect(
          HelpRequestRules.isValidStatusAdvance(RequestStatus.accepted, RequestStatus.onTheWay),
          isTrue,
        );
        expect(
          HelpRequestRules.isValidStatusAdvance(RequestStatus.onTheWay, RequestStatus.inProgress),
          isTrue,
        );
        expect(
          HelpRequestRules.isValidStatusAdvance(RequestStatus.inProgress, RequestStatus.completed),
          isTrue,
        );
      });

      test('transisi yang tidak sah ditolak', () {
        expect(
          HelpRequestRules.isValidStatusAdvance(RequestStatus.pending, RequestStatus.completed),
          isFalse,
        );
        expect(
          HelpRequestRules.isValidStatusAdvance(RequestStatus.completed, RequestStatus.inProgress),
          isFalse,
        );
        expect(
          HelpRequestRules.isValidStatusAdvance(RequestStatus.cancelled, RequestStatus.accepted),
          isFalse,
        );
      });
    });
  });

  group('MockHelpRequestRepository Unit Tests (PRD 5.4, 6.6, 7)', () {
    late MockHelpRequestRepository repository;

    setUp(() {
      repository = MockHelpRequestRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    final testRequest = ServiceRequest(
      id: 'req-001',
      userId: 'user-001',
      issueCategory: CommonIssues.banBocor,
      issueDescription: 'Ban belakang bocor tertusuk paku di jalan Diponegoro.',
      addressText: 'Jl. Diponegoro No. 12',
      contactPhone: '081234567890',
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );

    test('createRequest berhasil menyimpan permintaan berstatus pending dengan batas kedaluwarsa 15 menit', () async {
      final created = await repository.createRequest(testRequest);

      expect(created.id, isNotEmpty);
      expect(created.status, RequestStatus.pending);
      expect(created.isDemo, isTrue);
      expect(created.expiresAt.isAfter(DateTime.now()), isTrue);

      final fetched = await repository.getRequestById(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.issueCategory, CommonIssues.banBocor);
    });

    test('TC-21: Menolak createRequest jika pengguna sudah memiliki permintaan aktif', () async {
      await repository.createRequest(testRequest);

      // Coba buat permintaan kedua saat yang pertama masih pending
      final secondRequest = testRequest.copyWith(
        id: 'req-002',
        issueDescription: 'Rantai motor putus tiba-tiba di jalan.',
      );

      expect(
        () => repository.createRequest(secondRequest),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('masih memiliki permintaan aktif'),
        )),
      );
    });

    test('TC-20: cancelRequest berhasil membatalkan permintaan berstatus pending/accepted/onTheWay', () async {
      final created = await repository.createRequest(testRequest);
      expect(created.status, RequestStatus.pending);

      final cancelled = await repository.cancelRequest(created.id);
      expect(cancelled.status, RequestStatus.cancelled);

      final active = await repository.getActiveRequest();
      expect(active, isNull);
    });

    test('TC-20: cancelRequest gagal jika status tidak dapat dibatalkan (misal: inProgress)', () async {
      final created = await repository.createRequest(testRequest);

      // Majukan ke accepted -> onTheWay -> inProgress
      await repository.advanceRequest(created.id, RequestStatus.accepted);
      await repository.advanceRequest(created.id, RequestStatus.onTheWay);
      await repository.advanceRequest(created.id, RequestStatus.inProgress);

      expect(
        () => repository.cancelRequest(created.id),
        throwsA(isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('tidak dapat dibatalkan'),
        )),
      );
    });

    test('advanceRequest mengubah status secara bertahap dan merekam mekanik', () async {
      final created = await repository.createRequest(testRequest);

      final mockMechanic = Mechanic(
        id: 'mech-001',
        profileId: 'prof-mech-001',
        name: 'Budi Santoso',
        phone: '081298765432',
        workshopName: 'AHASS MotorCare',
        createdAt: DateTime.now(),
      );

      final accepted = await repository.advanceRequest(
        created.id,
        RequestStatus.accepted,
        assignedMechanic: mockMechanic,
      );
      expect(accepted.status, RequestStatus.accepted);
      expect(accepted.mechanicId, 'mech-001');
      expect(accepted.mechanic?.name, 'Budi Santoso');
      expect(accepted.acceptedAt, isNotNull);

      final onTheWay = await repository.advanceRequest(created.id, RequestStatus.onTheWay);
      expect(onTheWay.status, RequestStatus.onTheWay);

      final inProgress = await repository.advanceRequest(created.id, RequestStatus.inProgress);
      expect(inProgress.status, RequestStatus.inProgress);

      final completed = await repository.advanceRequest(created.id, RequestStatus.completed);
      expect(completed.status, RequestStatus.completed);
      expect(completed.completedAt, isNotNull);
    });

    test('TC-19: expireStaleRequests otomatis mengubah status permintaan pending yang lewat 15 menit menjadi expired', () async {
      // Buat permintaan dengan expiresAt di masa lalu (misal 20 menit lalu)
      final staleRequest = ServiceRequest(
        id: 'req-stale',
        userId: 'user-001',
        issueCategory: CommonIssues.mesinMogok,
        issueDescription: 'Mesin mogok tidak bisa distarter sama sekali.',
        addressText: 'Jl. Sudirman Kav. 5',
        contactPhone: '081234567890',
        status: RequestStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final repoWithStale = MockHelpRequestRepository(initialRequests: [staleRequest]);

      // Sebelum expireStaleRequests dipanggil, permintaan masih ada
      final fetched = await repoWithStale.getRequestById('req-stale');
      // getRequestById memanggil expireStaleRequests internal
      expect(fetched!.status, RequestStatus.expired);

      final active = await repoWithStale.getActiveRequest();
      expect(active, isNull);
    });
  });
}
