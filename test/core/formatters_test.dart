import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/core/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('AppFormatters Unit Tests', () {
    test('Format Rupiah', () {
      expect(AppFormatters.rupiah(1250000), 'Rp 1.250.000');
      expect(AppFormatters.rupiah(0), 'Rp 0');
      expect(AppFormatters.rupiah(50000), 'Rp 50.000');
    });

    test('Format Kilometer', () {
      expect(AppFormatters.mileage(12500), '12.500 km');
      expect(AppFormatters.mileage(0), '0 km');
      expect(AppFormatters.mileage(999999), '999.999 km');
    });

    test('Format Tanggal Indonesia (id_ID)', () {
      final date = DateTime(2026, 10, 14, 8, 30);
      expect(AppFormatters.dateShort(date), '14 Okt 2026');
      expect(AppFormatters.dateTime(date), '14 Okt 2026, 08:30');
    });

    test('Format Plat Nomor', () {
      expect(AppFormatters.licensePlate('bl 1234 ab'), 'BL 1234 AB');
      expect(AppFormatters.licensePlate('  b 5678 cd  '), 'B 5678 CD');
    });
  });
}
