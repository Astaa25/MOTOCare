import 'dart:async';
import 'dart:math';

/// Entri cache in-memory dengan waktu kedaluwarsa (TTL)
class MapsCacheEntry<T> {
  MapsCacheEntry({
    required this.data,
    required this.expiresAt,
  });

  final T data;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache memori sementara jangka pendek untuk Google Maps Platform
/// Kepatuhan Google: Data Places (nama, alamat, koordinat) tidak boleh disimpan
/// secara permanen (hanya place_id yang boleh disimpan permanen).
/// Cache ini hanya hidup di memori RAM selama sesi aplikasi berlangsung.
class MapsMemoryCache {
  MapsMemoryCache({this.defaultTtl = const Duration(minutes: 10)});

  final Duration defaultTtl;
  final Map<String, MapsCacheEntry<dynamic>> _cache = <String, MapsCacheEntry<dynamic>>{};

  /// Ambil data dari cache jika ada dan belum kedaluwarsa
  T? get<T>(String key) {
    final MapsCacheEntry<dynamic>? entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  /// Simpan data ke cache dengan masa berlaku tertentu
  void set<T>(String key, T data, {Duration? ttl}) {
    final Duration duration = ttl ?? defaultTtl;
    _cache[key] = MapsCacheEntry<T>(
      data: data,
      expiresAt: DateTime.now().add(duration),
    );
  }

  /// Hapus cache tertentu
  void remove(String key) {
    _cache.remove(key);
  }

  /// Bersihkan seluruh cache memori
  void clear() {
    _cache.clear();
  }

  /// Jumlah entri aktif dalam cache
  int get activeCount {
    _cache.removeWhere((_, entry) => entry.isExpired);
    return _cache.length;
  }
}

/// Manajer Session Token untuk Places Autocomplete (New)
/// Sesuai kebijakan Google: Satu sesi autocomplete mencakup pengetikan hingga pemilihan tempat.
/// Memakai session token memangkas biaya hingga 80% karena seluruh keystroke dihitung sebagai 1 sesi.
class MapsSessionTokenManager {
  String? _currentToken;
  DateTime? _tokenCreatedAt;
  static const Duration _sessionTimeout = Duration(minutes: 3);

  /// Dapatkan session token saat ini atau buat baru jika belum ada / sudah kedaluwarsa
  String getOrCreateToken() {
    final DateTime now = DateTime.now();
    if (_currentToken == null ||
        _tokenCreatedAt == null ||
        now.difference(_tokenCreatedAt!) > _sessionTimeout) {
      _currentToken = generateUuidV4();
      _tokenCreatedAt = now;
    }
    return _currentToken!;
  }

  /// Reset session token setelah pengguna memilih sebuah tempat (Place Details dipanggil)
  void consumeToken() {
    _currentToken = null;
    _tokenCreatedAt = null;
  }

  /// UUID v4 generator sederhana tanpa dependensi luar
  static String generateUuidV4() {
    final Random random = Random();
    final List<int> bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Versi 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Varian RFC4122
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) sb.write('-');
      sb.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}

/// Pengontrol debounce dan pemanggilan tunggal (single-flight)
class MapsDebouncer {
  MapsDebouncer({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;
  Timer? _timer;

  /// Jalankan aksi setelah jeda debounce tercapai
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Batalkan aksi debounce yang sedang berjalan
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isWaiting => _timer?.isActive ?? false;
}

/// Kontroler Biaya Terpadu untuk Google Maps Platform MotoCare
class MapsCostController {
  MapsCostController({
    Duration debounceDelay = const Duration(milliseconds: 400),
    Duration cacheTtl = const Duration(minutes: 10),
  })  : debouncer = MapsDebouncer(delay: debounceDelay),
        cache = MapsMemoryCache(defaultTtl: cacheTtl),
        sessionTokenManager = MapsSessionTokenManager();

  final MapsDebouncer debouncer;
  final MapsMemoryCache cache;
  final MapsSessionTokenManager sessionTokenManager;

  /// Batas maksimal saran hasil Places Autocomplete
  static const int maxAutocompleteResults = 5;

  /// Batas maksimal hasil pencarian bengkel
  static const int maxWorkshopResults = 20;

  /// Batas minimal karakter sebelum autocomplete dipanggil
  static const int minQueryLength = 2;

  /// Lepaskan semua timer dan cache saat ditutup
  void dispose() {
    debouncer.cancel();
    cache.clear();
    sessionTokenManager.consumeToken();
  }
}

