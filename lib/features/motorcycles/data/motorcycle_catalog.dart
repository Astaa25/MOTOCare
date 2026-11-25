import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Spesifikasi referensi katalog sepeda motor Indonesia.
class MotorcycleCatalogSpec {
  final String brand;
  final String model;
  final String category;
  final int engineCc;
  final String transmission;
  final String fuelType;
  final String defaultColor;
  final String assetPath;

  const MotorcycleCatalogSpec({
    required this.brand,
    required this.model,
    required this.category,
    required this.engineCc,
    required this.transmission,
    required this.fuelType,
    required this.defaultColor,
    required this.assetPath,
  });
}

/// Pilihan warna standar kendaraan beserta kode warna swatch UI.
class MotorcycleColorOption {
  final String name;
  final Color swatch;

  const MotorcycleColorOption(this.name, this.swatch);
}

/// Katalog lengkap sepeda motor populer Indonesia beserta pemetaan foto studio lokal
/// dan atribut spesifikasi otomatis (warna, cc, kategori, transmisi, BBM).
abstract class MotorcycleCatalog {
  static const String assetNmax = 'assets/images/motorcycles/nmax_155.jpg';
  static const String assetVario = 'assets/images/motorcycles/vario_160.jpg';
  static const String assetScoopy = 'assets/images/motorcycles/scoopy_prestige.jpg';

  static const List<MotorcycleColorOption> colorOptions = <MotorcycleColorOption>[
    MotorcycleColorOption('Hitam Doff', Color(0xFF1F2426)),
    MotorcycleColorOption('Biru Navy', Color(0xFF1A325B)),
    MotorcycleColorOption('Putih Mutiara', Color(0xFFF3F1EB)),
    MotorcycleColorOption('Merah Crimson', Color(0xFFB7242A)),
    MotorcycleColorOption('Abu Titanium', Color(0xFF6B7278)),
    MotorcycleColorOption('Perak Metalik', Color(0xFFC2C6C9)),
    MotorcycleColorOption('Cokelat Prestige', Color(0xFF7A5238)),
    MotorcycleColorOption('Hijau Sage', Color(0xFF4F7363)),
    MotorcycleColorOption('Kuning Cyber', Color(0xFFE0A922)),
    MotorcycleColorOption('Oranye Sporty', Color(0xFFD9582B)),
  ];

  static const List<String> categories = <String>[
    'Skutik Harian',
    'Skutik Maxi',
    'Skutik Sporty',
    'Skutik Retro',
    'Sport Naked',
    'Sport Fairing',
    'Bebek / Cub',
    'Trail / Dual Sport',
  ];

  static const List<String> transmissions = <String>[
    'Otomatis (CVT)',
    'Manual 5-Speed',
    'Manual 6-Speed',
    'Semi-Otomatis 4-Speed',
  ];

  static const List<String> fuelTypes = <String>[
    'Pertamax (RON 92)',
    'Pertalite (RON 90)',
    'Pertamax Turbo (RON 98)',
  ];

  static const List<MotorcycleCatalogSpec> popularModels = <MotorcycleCatalogSpec>[
    // --- HONDA ---
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'BeAT Deluxe',
      category: 'Skutik Harian',
      engineCc: 110,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Hitam Doff',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'BeAT Street',
      category: 'Skutik Harian',
      engineCc: 110,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Abu Titanium',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'Genio',
      category: 'Skutik Harian',
      engineCc: 110,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Merah Crimson',
      assetPath: assetScoopy,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'Scoopy Prestige',
      category: 'Skutik Retro',
      engineCc: 110,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Putih Mutiara',
      assetPath: assetScoopy,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'Vario 125',
      category: 'Skutik Harian',
      engineCc: 125,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Biru Navy',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'Vario 160',
      category: 'Skutik Sporty',
      engineCc: 160,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Hitam Doff',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'Stylo 160',
      category: 'Skutik Retro',
      engineCc: 160,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Hijau Sage',
      assetPath: assetScoopy,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'PCX 160',
      category: 'Skutik Maxi',
      engineCc: 160,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Putih Mutiara',
      assetPath: assetNmax,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'ADV 160',
      category: 'Skutik Maxi',
      engineCc: 160,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Merah Crimson',
      assetPath: assetNmax,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'Forza 250',
      category: 'Skutik Maxi',
      engineCc: 250,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax Turbo (RON 98)',
      defaultColor: 'Abu Titanium',
      assetPath: assetNmax,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'Revo X',
      category: 'Bebek / Cub',
      engineCc: 110,
      transmission: 'Semi-Otomatis 4-Speed',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Hitam Doff',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'Supra X 125',
      category: 'Bebek / Cub',
      engineCc: 125,
      transmission: 'Semi-Otomatis 4-Speed',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Hitam Doff',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'Supra GTR 150',
      category: 'Bebek / Cub',
      engineCc: 150,
      transmission: 'Manual 6-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Merah Crimson',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'Sonic 150R',
      category: 'Bebek / Cub',
      engineCc: 150,
      transmission: 'Manual 6-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Putih Mutiara',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'CB150R StreetFire',
      category: 'Sport Naked',
      engineCc: 150,
      transmission: 'Manual 6-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Merah Crimson',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'CB150X',
      category: 'Sport Naked',
      engineCc: 150,
      transmission: 'Manual 6-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Hijau Sage',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'CBR150R',
      category: 'Sport Fairing',
      engineCc: 150,
      transmission: 'Manual 6-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Merah Crimson',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Honda',
      model: 'CRF 150L',
      category: 'Trail / Dual Sport',
      engineCc: 150,
      transmission: 'Manual 5-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Merah Crimson',
      assetPath: assetVario,
    ),

    // --- YAMAHA ---
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'Mio M3',
      category: 'Skutik Harian',
      engineCc: 125,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Kuning Cyber',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'Gear 125',
      category: 'Skutik Harian',
      engineCc: 125,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Perak Metalik',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'FreeGo 125',
      category: 'Skutik Harian',
      engineCc: 125,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Biru Navy',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'Fino 125',
      category: 'Skutik Retro',
      engineCc: 125,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Cokelat Prestige',
      assetPath: assetScoopy,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'Fazzio Hybrid',
      category: 'Skutik Retro',
      engineCc: 125,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Putih Mutiara',
      assetPath: assetScoopy,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'Grand Filano',
      category: 'Skutik Retro',
      engineCc: 125,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Cokelat Prestige',
      assetPath: assetScoopy,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'Lexi LX 155',
      category: 'Skutik Maxi',
      engineCc: 155,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Abu Titanium',
      assetPath: assetNmax,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'Aerox 155',
      category: 'Skutik Sporty',
      engineCc: 155,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Hitam Doff',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'NMAX 155',
      category: 'Skutik Maxi',
      engineCc: 155,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Biru Navy',
      assetPath: assetNmax,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'NMAX Turbo',
      category: 'Skutik Maxi',
      engineCc: 155,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Abu Titanium',
      assetPath: assetNmax,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'XMAX 250',
      category: 'Skutik Maxi',
      engineCc: 250,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax Turbo (RON 98)',
      defaultColor: 'Hitam Doff',
      assetPath: assetNmax,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'Jupiter Z1',
      category: 'Bebek / Cub',
      engineCc: 115,
      transmission: 'Semi-Otomatis 4-Speed',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Biru Navy',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'MX King 150',
      category: 'Bebek / Cub',
      engineCc: 150,
      transmission: 'Manual 5-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Oranye Sporty',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'Vixion R',
      category: 'Sport Naked',
      engineCc: 155,
      transmission: 'Manual 6-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Hitam Doff',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'MT-15',
      category: 'Sport Naked',
      engineCc: 155,
      transmission: 'Manual 6-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Biru Navy',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'XSR 155',
      category: 'Sport Naked',
      engineCc: 155,
      transmission: 'Manual 6-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Perak Metalik',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'R15M',
      category: 'Sport Fairing',
      engineCc: 155,
      transmission: 'Manual 6-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Perak Metalik',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Yamaha',
      model: 'WR 155R',
      category: 'Trail / Dual Sport',
      engineCc: 155,
      transmission: 'Manual 6-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Biru Navy',
      assetPath: assetVario,
    ),

    // --- SUZUKI ---
    MotorcycleCatalogSpec(
      brand: 'Suzuki',
      model: 'Nex II',
      category: 'Skutik Harian',
      engineCc: 115,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Perak Metalik',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Suzuki',
      model: 'Address FI',
      category: 'Skutik Harian',
      engineCc: 115,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Putih Mutiara',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Suzuki',
      model: 'Burgman Street 125EX',
      category: 'Skutik Maxi',
      engineCc: 125,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Abu Titanium',
      assetPath: assetNmax,
    ),
    MotorcycleCatalogSpec(
      brand: 'Suzuki',
      model: 'Satria F150',
      category: 'Bebek / Cub',
      engineCc: 150,
      transmission: 'Manual 6-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Hitam Doff',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Suzuki',
      model: 'GSX-R150',
      category: 'Sport Fairing',
      engineCc: 150,
      transmission: 'Manual 6-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Biru Navy',
      assetPath: assetVario,
    ),

    // --- KAWASAKI & VESPA ---
    MotorcycleCatalogSpec(
      brand: 'Kawasaki',
      model: 'KLX 150',
      category: 'Trail / Dual Sport',
      engineCc: 150,
      transmission: 'Manual 5-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Hijau Sage',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Kawasaki',
      model: 'W175 SE',
      category: 'Sport Naked',
      engineCc: 177,
      transmission: 'Manual 5-Speed',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Hitam Doff',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Kawasaki',
      model: 'Ninja 250 SL',
      category: 'Sport Fairing',
      engineCc: 250,
      transmission: 'Manual 6-Speed',
      fuelType: 'Pertamax Turbo (RON 98)',
      defaultColor: 'Hijau Sage',
      assetPath: assetVario,
    ),
    MotorcycleCatalogSpec(
      brand: 'Vespa',
      model: 'LX 125',
      category: 'Skutik Retro',
      engineCc: 125,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Merah Crimson',
      assetPath: assetScoopy,
    ),
    MotorcycleCatalogSpec(
      brand: 'Vespa',
      model: 'Primavera 150',
      category: 'Skutik Retro',
      engineCc: 155,
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertamax (RON 92)',
      defaultColor: 'Hijau Sage',
      assetPath: assetScoopy,
    ),
  ];

  /// Mencari spesifikasi paling cocok berdasarkan merek dan model motor.
  static MotorcycleCatalogSpec findSpec(String brand, String model) {
    final needle = '${brand.trim()} ${model.trim()}'.toLowerCase();
    for (final spec in popularModels) {
      final full = '${spec.brand} ${spec.model}'.toLowerCase();
      if (needle.contains(spec.model.toLowerCase()) || full == needle) {
        return spec;
      }
    }

    if (needle.contains('nmax') ||
        needle.contains('pcx') ||
        needle.contains('xmax') ||
        needle.contains('adv') ||
        needle.contains('lexi') ||
        needle.contains('burgman')) {
      return MotorcycleCatalogSpec(
        brand: brand,
        model: model,
        category: 'Skutik Maxi',
        engineCc: needle.contains('250') ? 250 : 155,
        transmission: 'Otomatis (CVT)',
        fuelType: 'Pertamax (RON 92)',
        defaultColor: 'Biru Navy',
        assetPath: assetNmax,
      );
    }

    if (needle.contains('scoopy') ||
        needle.contains('fazzio') ||
        needle.contains('filano') ||
        needle.contains('stylo') ||
        needle.contains('genio') ||
        needle.contains('vespa')) {
      return MotorcycleCatalogSpec(
        brand: brand,
        model: model,
        category: 'Skutik Retro',
        engineCc: needle.contains('160') || needle.contains('150') ? 155 : 110,
        transmission: 'Otomatis (CVT)',
        fuelType: 'Pertamax (RON 92)',
        defaultColor: 'Putih Mutiara',
        assetPath: assetScoopy,
      );
    }

    if (needle.contains('cbr') ||
        needle.contains('r15') ||
        needle.contains('r25') ||
        needle.contains('ninja') ||
        needle.contains('cb150') ||
        needle.contains('vixion') ||
        needle.contains('gsx')) {
      return MotorcycleCatalogSpec(
        brand: brand,
        model: model,
        category: needle.contains('cbr') || needle.contains('r15') || needle.contains('ninja')
            ? 'Sport Fairing'
            : 'Sport Naked',
        engineCc: needle.contains('250') ? 250 : 150,
        transmission: 'Manual 6-Speed',
        fuelType: 'Pertamax (RON 92)',
        defaultColor: 'Merah Crimson',
        assetPath: assetVario,
      );
    }

    if (needle.contains('supra') ||
        needle.contains('revo') ||
        needle.contains('jupiter') ||
        needle.contains('mx') ||
        needle.contains('satria') ||
        needle.contains('sonic')) {
      return MotorcycleCatalogSpec(
        brand: brand,
        model: model,
        category: 'Bebek / Cub',
        engineCc: needle.contains('150') ? 150 : 125,
        transmission: 'Semi-Otomatis 4-Speed',
        fuelType: 'Pertalite (RON 90)',
        defaultColor: 'Hitam Doff',
        assetPath: assetVario,
      );
    }

    if (needle.contains('crf') || needle.contains('klx') || needle.contains('wr155')) {
      return MotorcycleCatalogSpec(
        brand: brand,
        model: model,
        category: 'Trail / Dual Sport',
        engineCc: 150,
        transmission: 'Manual 5-Speed',
        fuelType: 'Pertamax (RON 92)',
        defaultColor: 'Merah Crimson',
        assetPath: assetVario,
      );
    }

    return MotorcycleCatalogSpec(
      brand: brand.isEmpty ? 'Sepeda Motor' : brand,
      model: model,
      category: 'Skutik Harian',
      engineCc: needle.contains('160')
          ? 160
          : (needle.contains('155') ? 155 : (needle.contains('125') ? 125 : 110)),
      transmission: 'Otomatis (CVT)',
      fuelType: 'Pertalite (RON 90)',
      defaultColor: 'Hitam Doff',
      assetPath: assetVario,
    );
  }

  /// Resolusi jalur asset lokal studio sesuai merek/model motor.
  static String resolveAssetPath(String brand, String model) =>
      findSpec(brand, model).assetPath;

  /// Resolusi warna UI swatch dari nama warna.
  static Color resolveSwatchColor(String? colorName) {
    if (colorName == null || colorName.trim().isEmpty) {
      return AppColors.deepTeal;
    }
    final lower = colorName.toLowerCase();
    for (final opt in colorOptions) {
      if (opt.name.toLowerCase() == lower ||
          lower.contains(opt.name.split(' ').first.toLowerCase())) {
        return opt.swatch;
      }
    }
    if (lower.contains('hitam') || lower.contains('black')) {
      return const Color(0xFF1F2426);
    }
    if (lower.contains('biru') || lower.contains('blue') || lower.contains('navy')) {
      return const Color(0xFF1A325B);
    }
    if (lower.contains('putih') || lower.contains('white') || lower.contains('cream')) {
      return const Color(0xFFF3F1EB);
    }
    if (lower.contains('merah') || lower.contains('red')) {
      return const Color(0xFFB7242A);
    }
    if (lower.contains('abu') || lower.contains('grey') || lower.contains('titanium')) {
      return const Color(0xFF6B7278);
    }
    if (lower.contains('hijau') || lower.contains('green')) {
      return const Color(0xFF4F7363);
    }
    if (lower.contains('kuning') || lower.contains('yellow') || lower.contains('emas')) {
      return const Color(0xFFE0A922);
    }
    if (lower.contains('cokelat') || lower.contains('brown')) {
      return const Color(0xFF7A5238);
    }
    return AppColors.deepTeal;
  }
}

/// Widget penampil foto sepeda motor yang otomatis menangani URL jaringan,
/// asset lokal studio, dan fallback aman saat offline/error.
class MotorcycleImage extends StatelessWidget {
  final String brand;
  final String model;
  final String? photoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const MotorcycleImage({
    super.key,
    required this.brand,
    required this.model,
    this.photoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackAsset = MotorcycleCatalog.resolveAssetPath(brand, model);
    final rawUrl = photoUrl?.trim();

    Widget imageWidget;
    if (rawUrl != null &&
        (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))) {
      imageWidget = Image.network(
        rawUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => Image.asset(
          fallbackAsset,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _buildIconFallback(),
        ),
      );
    } else {
      final assetPath = (rawUrl != null && rawUrl.startsWith('assets/'))
          ? rawUrl
          : fallbackAsset;
      imageWidget = Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildIconFallback(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    return imageWidget;
  }

  Widget _buildIconFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.cream,
      alignment: Alignment.center,
      child: const Icon(
        Icons.two_wheeler_rounded,
        color: AppColors.terracotta,
        size: 32,
      ),
    );
  }
}

