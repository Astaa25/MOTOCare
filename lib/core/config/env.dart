/// Konfigurasi environment dari --dart-define
abstract class AppEnv {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Mode Mock aktif jika USE_MOCK disetel 'true' atau jika kredensial kosong
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );

  /// Feature flag integrasi Google Maps Platform
  /// Jika false, peta interaktif dinonaktifkan dan aplikasi otomatis beralih
  /// ke navigasi eksternal (url_launcher) serta formulir lokasi manual.
  static const bool mapsEnabled = bool.fromEnvironment(
    'MAPS_ENABLED',
    defaultValue: true,
  );

  /// Mode Finishing (Produksi): Secara default true agar aplikasi langsung siap
  /// produksi tanpa label/lencana/shortcut demo atau simulasi.
  static bool _finishingModeOverride = false;
  static bool _forceDemoModeOverride = false;
  static bool get isFinishingMode {
    if (_forceDemoModeOverride) return false;
    return const bool.fromEnvironment('FINISHING_MODE', defaultValue: true) ||
        _finishingModeOverride;
  }

  static set isFinishingMode(bool value) {
    _finishingModeOverride = value;
    _forceDemoModeOverride = !value;
  }

  /// Helper untuk mengecek apakah fitur demo / simulasi harus ditampilkan
  static bool get showDemoFeatures => !isFinishingMode;

  /// Helper untuk mengecek apakah backend Supabase siap digunakan
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !useMock;
}
