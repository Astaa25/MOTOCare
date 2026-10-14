import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/utils/validators.dart';

void main() {
  group('PRD 6.2 Validasi Kilometer Sesuai Tabel Spesifikasi Lengkap', () {
    test('Baris 1: current = 12000, input = "12000" -> ok', () {
      final res = AppValidators.validateMileage(12000, '12000');
      expect(res, MileageValidationResult.ok);
    });

    test('Baris 2: current = 12000, input = "11990" -> confirmDecrease', () {
      final res = AppValidators.validateMileage(12000, '11990');
      expect(res, MileageValidationResult.confirmDecrease);
    });

    test('Baris 3: current = 12000, input = "17000" (selisih tepat 5000) -> ok', () {
      final res = AppValidators.validateMileage(12000, '17000');
      expect(res, MileageValidationResult.ok);
    });

    test('Baris 4: current = 12000, input = "17001" (selisih 5001) -> confirmBigJump', () {
      final res = AppValidators.validateMileage(12000, '17001');
      expect(res, MileageValidationResult.confirmBigJump);
    });

    test('Baris 5: current = 5000, input = "-1" -> invalid', () {
      final res = AppValidators.validateMileage(5000, '-1');
      expect(res, MileageValidationResult.invalid);
    });

    test('Baris 6: current = 0, input = "1000000" (> 999999) -> invalid', () {
      final res = AppValidators.validateMileage(0, '1000000');
      expect(res, MileageValidationResult.invalid);
    });

    test('Baris 7: current = 100, input = "abc" -> invalid', () {
      final res = AppValidators.validateMileage(100, 'abc');
      expect(res, MileageValidationResult.invalid);
    });

    test('Kasus batas: 0 vs 0 -> ok', () {
      final res = AppValidators.validateMileage(0, '0');
      expect(res, MileageValidationResult.ok);
    });

    test('Kasus batas: 0 vs 5000 -> ok', () {
      final res = AppValidators.validateMileage(0, '5000');
      expect(res, MileageValidationResult.ok);
    });

    test('Kasus batas: 0 vs 5001 -> confirmBigJump', () {
      final res = AppValidators.validateMileage(0, '5001');
      expect(res, MileageValidationResult.confirmBigJump);
    });

    test('Kasus batas: 999999 vs 999999 -> ok', () {
      final res = AppValidators.validateMileage(999999, '999999');
      expect(res, MileageValidationResult.ok);
    });

    test('Input dengan spasi ditrim secara aman: "  12500  " -> ok', () {
      final res = AppValidators.validateMileage(12000, '  12500  ');
      expect(res, MileageValidationResult.ok);
    });

    test('Input desimal atau karakter khusus -> invalid', () {
      expect(AppValidators.validateMileage(1000, '1000.5'), MileageValidationResult.invalid);
      expect(AppValidators.validateMileage(1000, '1,000'), MileageValidationResult.invalid);
      expect(AppValidators.validateMileage(1000, ''), MileageValidationResult.invalid);
    });
  });
}
