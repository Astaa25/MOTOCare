import 'package:intl/intl.dart';

/// Formatter tampilan data MotoCare sesuai PRD M1 (Rupiah, Tanggal id_ID, Kilometer)
abstract class AppFormatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormat = NumberFormat.decimalPattern('id_ID');

  /// Memformat angka ke format Rupiah (contoh: Rp 1.250.000)
  static String rupiah(num amount) {
    return _currencyFormat.format(amount).trim();
  }

  /// Memformat angka kilometer dengan pemisah ribuan dan akhiran km (contoh: 12.500 km)
  static String mileage(int km) {
    return '${_numberFormat.format(km)} km';
  }

  /// Memformat tanggal ke format Indonesia singkat (contoh: 14 Okt 2026)
  static String dateShort(DateTime date) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  /// Memformat tanggal dan waktu (contoh: 14 Okt 2026, 08:30)
  static String dateTime(DateTime date) {
    try {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('d MMM yyyy, HH:mm').format(date);
    }
  }

  /// Memformat plat nomor menjadi huruf kapital rapi (contoh: BL 1234 AB)
  static String licensePlate(String plate) {
    return plate.trim().toUpperCase();
  }

  /// Alias pembantu untuk konsistensi penamaan
  static String formatKilometer(int km) => mileage(km);
  static String formatDate(DateTime date) => dateShort(date);
  static String formatRupiah(num amount) => rupiah(amount);
}
