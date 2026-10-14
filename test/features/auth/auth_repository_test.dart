import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/errors/app_exception.dart';
import 'package:motocare/features/auth/data/mock_auth_repository.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  group('TC-01 & TC-02: Unit Tests AuthRepository (Mock)', () {
    test('TC-01: Login dengan kredensial valid berhasil mengembalikan UserProfile', () async {
      final result = await repository.signIn(
        email: MockAuthRepository.demoEmail,
        password: MockAuthRepository.demoPassword,
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNotNull);
      expect(result.dataOrNull!.email, MockAuthRepository.demoEmail);
      expect(result.dataOrNull!.fullName, 'Abrar Pengguna Demo');
      expect(result.dataOrNull!.role, 'user');
    });

    test('TC-02: Login dengan kata sandi salah mengembalikan pesan error umum (SEC-13)', () async {
      final result = await repository.signIn(
        email: MockAuthRepository.demoEmail,
        password: 'SalahPassword123',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<UnauthorizedException>());
      // Pesan error umum, tidak membocorkan detail akun
      expect(
        result.exceptionOrNull!.message,
        'Email atau kata sandi yang Anda masukkan salah.',
      );
    });

    test('TC-02: Login dengan email yang belum terdaftar tetap mengembalikan pesan umum (SEC-13)', () async {
      final result = await repository.signIn(
        email: 'bukan.siapa@domain.com',
        password: 'Password123',
      );

      expect(result.isFailure, isTrue);
      expect(
        result.exceptionOrNull!.message,
        'Email atau kata sandi yang Anda masukkan salah.',
      );
    });

    test('Registrasi akun baru berhasil dan memperbarui sesi pengguna', () async {
      final result = await repository.signUp(
        email: 'pengguna.baru@motocare.id',
        password: 'PasswordBaru123',
        fullName: 'Budi Santoso',
        phone: '081234567890',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.fullName, 'Budi Santoso');
      expect(result.dataOrNull!.email, 'pengguna.baru@motocare.id');
      expect(result.dataOrNull!.phone, '081234567890');
      expect(result.dataOrNull!.role, 'user');

      // Ambil user terkini
      final current = await repository.getCurrentUser();
      expect(current.dataOrNull?.email, 'pengguna.baru@motocare.id');
    });

    test('Update profil memperbarui nama dan nomor telepon', () async {
      // Login terlebih dahulu
      await repository.signIn(
        email: MockAuthRepository.demoEmail,
        password: MockAuthRepository.demoPassword,
      );

      final updateResult = await repository.updateProfile(
        fullName: 'Abrar Astafaraiz Update',
        phone: '089999999999',
      );

      expect(updateResult.isSuccess, isTrue);
      expect(updateResult.dataOrNull!.fullName, 'Abrar Astafaraiz Update');
      expect(updateResult.dataOrNull!.phone, '089999999999');
    });

    test('SignOut membersihkan sesi pengguna', () async {
      await repository.signIn(
        email: MockAuthRepository.demoEmail,
        password: MockAuthRepository.demoPassword,
      );

      final signOutResult = await repository.signOut();
      expect(signOutResult.isSuccess, isTrue);

      final currentUser = await repository.getCurrentUser();
      expect(currentUser.dataOrNull, isNull);
    });

    test('sendPasswordResetEmail mengembalikan sukses umum tanpa kebocoran akun', () async {
      final result = await repository.sendPasswordResetEmail('bebas@domain.com');
      expect(result.isSuccess, isTrue);
    });
  });
}
