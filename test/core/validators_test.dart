import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/utils/validators.dart';

void main() {
  group('AppValidators Unit Tests', () {
    test('Validasi Email - Kasus Valid dan Tidak Valid', () {
      // Valid
      expect(AppValidators.validateEmail('user@motocare.id'), isNull);
      expect(AppValidators.validateEmail('budi.santoso@gmail.com'), isNull);

      // Tidak valid
      expect(AppValidators.validateEmail(null), isNotNull);
      expect(AppValidators.validateEmail(''), isNotNull);
      expect(AppValidators.validateEmail('   '), isNotNull);
      expect(AppValidators.validateEmail('bukan-email'), isNotNull);
      expect(AppValidators.validateEmail('user@'), isNotNull);
      expect(AppValidators.validateEmail('@domain.com'), isNotNull);
    });

    test('Validasi Kata Sandi - Minimal 8 Karakter Kombinasi Huruf dan Angka', () {
      // Valid
      expect(AppValidators.validatePassword('rahasia123'), isNull);
      expect(AppValidators.validatePassword('MotoCare2026'), isNull);

      // Tidak valid
      expect(AppValidators.validatePassword(null), isNotNull);
      expect(AppValidators.validatePassword(''), isNotNull);
      expect(AppValidators.validatePassword('pendek1'), isNotNull); // < 8
      expect(AppValidators.validatePassword('hanyahurufsaja'), isNotNull); // tanpa angka
      expect(AppValidators.validatePassword('123456789'), isNotNull); // tanpa huruf
    });

    test('Validasi Nama Lengkap - Panjang 2 sampai 80 Karakter', () {
      // Valid
      expect(AppValidators.validateFullName('Abrar'), isNull);
      expect(AppValidators.validateFullName('Muhammad Ali'), isNull);

      // Tidak valid
      expect(AppValidators.validateFullName(null), isNotNull);
      expect(AppValidators.validateFullName(''), isNotNull);
      expect(AppValidators.validateFullName('A'), isNotNull); // < 2
      expect(AppValidators.validateFullName('A' * 81), isNotNull); // > 80
    });

    test('Validasi Telepon & Sanitasi Nomor', () {
      // Sanitasi
      expect(AppValidators.sanitizePhone('+62 812-3456-7890'), '+6281234567890');
      expect(AppValidators.sanitizePhone('(0812) 9999 1234'), '081299991234');

      // Valid
      expect(AppValidators.validatePhone('08123456789'), isNull);
      expect(AppValidators.validatePhone('+6281234567890'), isNull);

      // Tidak valid
      expect(AppValidators.validatePhone(null), isNotNull);
      expect(AppValidators.validatePhone(''), isNotNull);
      expect(AppValidators.validatePhone('1234567'), isNotNull); // < 8 digit
      expect(AppValidators.validatePhone('1234567890123456'), isNotNull); // > 15 digit
      expect(AppValidators.validatePhone('0812abc345'), isNotNull);
    });

    test('Validasi Merek dan Model Motor', () {
      expect(AppValidators.validateBrandOrModel('Honda', 'Merek'), isNull);
      expect(AppValidators.validateBrandOrModel('Vario 160', 'Model'), isNull);
      expect(AppValidators.validateBrandOrModel('', 'Merek'), isNotNull);
      expect(AppValidators.validateBrandOrModel('A' * 41, 'Merek'), isNotNull);
    });

    test('Validasi Tahun Produksi Motor (1980 .. Tahun Berjalan + 1)', () {
      final int maxYear = DateTime.now().year + 1;
      expect(AppValidators.validateProductionYear('1980'), isNull);
      expect(AppValidators.validateProductionYear('2020'), isNull);
      expect(AppValidators.validateProductionYear('$maxYear'), isNull);

      // Tidak valid
      expect(AppValidators.validateProductionYear(null), isNotNull);
      expect(AppValidators.validateProductionYear('1979'), isNotNull);
      expect(AppValidators.validateProductionYear('${maxYear + 1}'), isNotNull);
      expect(AppValidators.validateProductionYear('bukan-tahun'), isNotNull);
    });

    test('Validasi Plat Nomor Motor', () {
      expect(AppValidators.validateLicensePlate(null), isNull); // Opsional
      expect(AppValidators.validateLicensePlate(''), isNull);
      expect(AppValidators.validateLicensePlate('BL 1234 AB'), isNull);
      expect(AppValidators.validateLicensePlate('BL 123456789012'), isNotNull); // > 12
    });

    test('Validasi Tanggal Servis - Tidak di Masa Depan', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      expect(AppValidators.validateServiceDate(today), isNull);
      expect(AppValidators.validateServiceDate(yesterday), isNull);
      expect(AppValidators.validateServiceDate(tomorrow), isNotNull);
      expect(AppValidators.validateServiceDate(null), isNotNull);
    });

    test('Validasi Biaya Servis - Minimal 0', () {
      expect(AppValidators.validateCost('0'), isNull);
      expect(AppValidators.validateCost('150000'), isNull);
      expect(AppValidators.validateCost('Rp 150.000'), isNull);
      expect(AppValidators.validateCost(''), isNotNull);
      expect(AppValidators.validateCost(null), isNotNull);
    });

    test('Validasi Deskripsi Masalah Bantuan Mekanik (10..500 Karakter)', () {
      expect(AppValidators.validateIssueDescription('Ban motor bocor di dekat simpang'), isNull);
      expect(AppValidators.validateIssueDescription('pendek'), isNotNull); // < 10
      expect(AppValidators.validateIssueDescription('A' * 501), isNotNull); // > 500
      expect(AppValidators.validateIssueDescription(null), isNotNull);
    });

    test('Validasi Alamat (Minimal 5 Karakter)', () {
      expect(AppValidators.validateAddress('Jl. Merdeka No. 5'), isNull);
      expect(AppValidators.validateAddress('Jl.'), isNotNull);
      expect(AppValidators.validateAddress(null), isNotNull);
    });

    test('Validasi Kilometer Sesuai Tabel PRD Bagian 6.2 Lengkap', () {
      // 1. current=12000, input=12000 -> ok
      expect(
        AppValidators.validateMileage(12000, '12000'),
        MileageValidationResult.ok,
      );

      // 2. current=12000, input=11990 -> confirmDecrease
      expect(
        AppValidators.validateMileage(12000, '11990'),
        MileageValidationResult.confirmDecrease,
      );

      // 3. current=12000, input=17000 (selisih tepat 5000) -> ok
      expect(
        AppValidators.validateMileage(12000, '17000'),
        MileageValidationResult.ok,
      );

      // 4. current=12000, input=17001 (selisih 5001 > 5000) -> confirmBigJump
      expect(
        AppValidators.validateMileage(12000, '17001'),
        MileageValidationResult.confirmBigJump,
      );

      // 5. current=5000, input=-1 -> invalid
      expect(
        AppValidators.validateMileage(5000, '-1'),
        MileageValidationResult.invalid,
      );

      // 6. current=0, input=1000000 -> invalid (> 999999)
      expect(
        AppValidators.validateMileage(0, '1000000'),
        MileageValidationResult.invalid,
      );

      // 7. current=100, input=abc -> invalid
      expect(
        AppValidators.validateMileage(100, 'abc'),
        MileageValidationResult.invalid,
      );
    });
  });
}
