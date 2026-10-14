/// Konstanta aplikasi MotoCare sesuai PRD bagian 6.1
abstract class AppConstants {
  static const int mileageMax = 999999;
  static const int mileageJumpConfirmKm = 5000;
  static const int reminderNearDays = 7;
  static const int reminderNearKm = 200;
  static const int mileageStaleDays = 30;
  static const int requestTimeoutMinutes = 15;
  static const int pageSize = 20;

  /// Batas waktu timeout permintaan jaringan (15 detik) sesuai PRD M8
  static const Duration networkTimeout = Duration(seconds: 15);

  /// Rentang durasi animasi splash screen (3000 - 5000 ms)
  static const int splashMinMs = 3000;
  static const int splashMaxMs = 5000;

  /// Wilayah layanan yang didukung pada MVP
  static const List<String> supportedRegions = <String>[
    'Kota Lhokseumawe',
    'Kabupaten Aceh Utara',
  ];

  /// Jenis servis resmi sesuai PRD 6.7
  static const List<String> serviceTypes = <String>[
    'Ganti oli',
    'Servis berkala',
    'Rem',
    'Rantai',
    'Ban',
    'Aki',
    'Busi',
    'Filter udara',
    'Lainnya',
  ];

  /// Kontak darurat resmi (kosong secara default, tidak boleh dikarang)
  static const List<String> emergencyContacts = <String>[];
}
