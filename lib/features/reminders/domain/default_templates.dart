/// Model templat pengingat bawaan sesuai PRD Bagian 6.4 (Tabel 6.4)
/// Nilai interval adalah titik awal yang dapat diubah dan wajib diverifikasi pengguna
class ReminderTemplate {
  final String title;
  final String serviceType;
  final int? intervalKm;
  final int? intervalMonths;
  final String description;

  const ReminderTemplate({
    required this.title,
    required this.serviceType,
    this.intervalKm,
    this.intervalMonths,
    required this.description,
  });
}

/// Daftar templat pengingat resmi sesuai PRD Tabel 6.4
abstract class DefaultReminderTemplates {
  static const ReminderTemplate engineOil = ReminderTemplate(
    title: 'Ganti Oli Mesin',
    serviceType: 'Ganti oli',
    intervalKm: 3000,
    intervalMonths: 3,
    description: 'Interval standar ganti oli mesin motor (setiap 3.000 km atau 3 bulan).',
  );

  static const ReminderTemplate airFilter = ReminderTemplate(
    title: 'Ganti Filter Udara',
    serviceType: 'Filter udara',
    intervalKm: 10000,
    intervalMonths: null,
    description: 'Pembersihan atau penggantian saringan udara (setiap 10.000 km).',
  );

  static const ReminderTemplate sparkPlug = ReminderTemplate(
    title: 'Ganti Busi',
    serviceType: 'Busi',
    intervalKm: 10000,
    intervalMonths: null,
    description: 'Pemeriksaan dan penggantian busi berkala (setiap 10.000 km).',
  );

  static const ReminderTemplate brakes = ReminderTemplate(
    title: 'Cek Rem',
    serviceType: 'Rem',
    intervalKm: null,
    intervalMonths: 1,
    description: 'Pemeriksaan kampas rem depan/belakang dan minyak rem (setiap 1 bulan).',
  );

  static const ReminderTemplate chain = ReminderTemplate(
    title: 'Cek Rantai & Pelumasan',
    serviceType: 'Rantai',
    intervalKm: null,
    intervalMonths: 1,
    description: 'Pengecekan ketegangan rantai dan pemberian pelumas (setiap 1 bulan).',
  );

  static const ReminderTemplate tirePressure = ReminderTemplate(
    title: 'Cek Tekanan Ban',
    serviceType: 'Ban',
    intervalKm: null,
    intervalMonths: 1,
    description: 'Pemeriksaan tekanan angin dan kondisi alur ban (setiap 1 bulan).',
  );

  static const ReminderTemplate battery = ReminderTemplate(
    title: 'Pemeriksaan Aki',
    serviceType: 'Aki',
    intervalKm: null,
    intervalMonths: null,
    description: 'Pemeriksaan tegangan dan kondisi aki/accu (kustom sesuai kebutuhan).',
  );

  /// Semua templat bawaan untuk UI pemilih
  static const List<ReminderTemplate> all = <ReminderTemplate>[
    engineOil,
    airFilter,
    sparkPlug,
    brakes,
    chain,
    tirePressure,
    battery,
  ];
}
