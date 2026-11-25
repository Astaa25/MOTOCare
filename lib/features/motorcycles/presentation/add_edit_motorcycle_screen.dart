import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../data/motorcycle_catalog.dart';
import '../domain/motorcycle.dart';
import 'motorcycle_providers.dart';

/// Layar Tambah / Ubah Sepeda Motor sesuai PRD M3 beserta detail warna, spesifikasi & preview foto
class AddEditMotorcycleScreen extends ConsumerStatefulWidget {
  final String? motorcycleId;

  const AddEditMotorcycleScreen({
    super.key,
    this.motorcycleId,
  });

  bool get isEditing => motorcycleId != null;

  @override
  ConsumerState<AddEditMotorcycleScreen> createState() =>
      _AddEditMotorcycleScreenState();
}

class _AddEditMotorcycleScreenState
    extends ConsumerState<AddEditMotorcycleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _mileageController = TextEditingController();
  final _colorController = TextEditingController(text: 'Hitam Doff');
  final _ccController = TextEditingController(text: '125');

  String _selectedCategory = MotorcycleCatalog.categories.first;
  String _selectedTransmission = MotorcycleCatalog.transmissions.first;
  String _selectedFuelType = MotorcycleCatalog.fuelTypes.first;
  String? _customPhotoUrl;

  bool _isLoading = false;
  String? _errorMessage;
  Motorcycle? _existingMotorcycle;

  @override
  void initState() {
    super.initState();
    _brandController.addListener(_onModelTyping);
    _modelController.addListener(_onModelTyping);
    if (widget.isEditing) {
      _loadExistingData();
    }
  }

  void _onModelTyping() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadExistingData() async {
    final list = ref.read(motorcyclesProvider).valueOrNull ?? <Motorcycle>[];
    final motor = list.where((m) => m.id == widget.motorcycleId).firstOrNull;
    if (motor != null) {
      _populateFields(motor);
    } else {
      try {
        final fetched = await ref.read(motorcycleDetailProvider(widget.motorcycleId!).future);
        if (mounted) {
          _populateFields(fetched);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _errorMessage = 'Gagal memuat data motor: $e');
        }
      }
    }
  }

  void _populateFields(Motorcycle motor) {
    setState(() {
      _existingMotorcycle = motor;
      _brandController.text = motor.brand;
      _modelController.text = motor.model;
      _yearController.text = motor.productionYear.toString();
      _plateController.text = motor.licensePlate ?? '';
      _colorController.text = motor.resolvedColor;
      _ccController.text = motor.resolvedEngineCc.toString();
      _selectedCategory = MotorcycleCatalog.categories.contains(motor.resolvedCategory)
          ? motor.resolvedCategory
          : MotorcycleCatalog.categories.first;
      _selectedTransmission =
          MotorcycleCatalog.transmissions.contains(motor.resolvedTransmission)
              ? motor.resolvedTransmission
              : MotorcycleCatalog.transmissions.first;
      _selectedFuelType = MotorcycleCatalog.fuelTypes.contains(motor.resolvedFuelType)
          ? motor.resolvedFuelType
          : MotorcycleCatalog.fuelTypes.first;
      _customPhotoUrl = motor.photoUrl;
    });
  }

  void _applyCatalogSpec(MotorcycleCatalogSpec spec) {
    setState(() {
      _brandController.text = spec.brand;
      _modelController.text = spec.model;
      _colorController.text = spec.defaultColor;
      _ccController.text = spec.engineCc.toString();
      if (MotorcycleCatalog.categories.contains(spec.category)) {
        _selectedCategory = spec.category;
      }
      if (MotorcycleCatalog.transmissions.contains(spec.transmission)) {
        _selectedTransmission = spec.transmission;
      }
      if (MotorcycleCatalog.fuelTypes.contains(spec.fuelType)) {
        _selectedFuelType = spec.fuelType;
      }
      _customPhotoUrl = spec.assetPath;
    });
  }

  @override
  void dispose() {
    _brandController.removeListener(_onModelTyping);
    _modelController.removeListener(_onModelTyping);
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _mileageController.dispose();
    _colorController.dispose();
    _ccController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();
    final year = int.parse(_yearController.text.trim());
    final plate = _plateController.text.trim().isEmpty
        ? null
        : _plateController.text.trim().toUpperCase();
    final color = _colorController.text.trim().isEmpty
        ? MotorcycleCatalog.findSpec(brand, model).defaultColor
        : _colorController.text.trim();
    final parsedCc = int.tryParse(_ccController.text.trim()) ??
        MotorcycleCatalog.findSpec(brand, model).engineCc;
    final resolvedPhoto = (_customPhotoUrl != null && _customPhotoUrl!.trim().isNotEmpty)
        ? _customPhotoUrl!.trim()
        : MotorcycleCatalog.resolveAssetPath(brand, model);

    if (widget.isEditing) {
      if (_existingMotorcycle == null) return;
      final updated = _existingMotorcycle!.copyWith(
        brand: brand,
        model: model,
        productionYear: year,
        licensePlate: plate,
        color: color,
        category: _selectedCategory,
        engineCc: parsedCc,
        transmission: _selectedTransmission,
        fuelType: _selectedFuelType,
        photoUrl: resolvedPhoto,
      );

      final result = await ref
          .read(motorcyclesProvider.notifier)
          .updateMotorcycle(updated);

      if (!mounted) return;
      setState(() => _isLoading = false);

      result.when(
        onSuccess: (_) async {
          await SuccessDialog.show(
            context,
            title: 'Berhasil Diperbarui',
            message: 'Informasi $brand $model ($color) berhasil diperbarui.',
            buttonLabel: 'Selesai',
          );
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        onFailure: (err) {
          setState(() => _errorMessage = err.message);
        },
      );
    } else {
      final mileage = int.parse(_mileageController.text.trim());
      final result = await ref
          .read(motorcyclesProvider.notifier)
          .addMotorcycle(
            brand: brand,
            model: model,
            productionYear: year,
            licensePlate: plate,
            currentMileage: mileage,
            color: color,
            category: _selectedCategory,
            engineCc: parsedCc,
            transmission: _selectedTransmission,
            fuelType: _selectedFuelType,
            photoUrl: resolvedPhoto,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      result.when(
        onSuccess: (_) async {
          await SuccessDialog.show(
            context,
            title: 'Motor Berhasil Ditambahkan',
            message: '$brand $model ($color) berhasil didaftarkan ke MotoCare.',
            buttonLabel: 'Selesai',
          );
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        onFailure: (err) {
          setState(() => _errorMessage = err.message);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user != null && (user.isMechanic || user.isAdmin)) {
      final isMech = user.isMechanic;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Akses Dibatasi')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    size: 38,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isMech ? 'Mekanik Tidak Menambah Kendaraan' : 'Akses Dibatasi Administrator',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  isMech
                      ? 'Sebagai Mekanik Mitra, Anda bertugas merawat dan melayani servis motor pelanggan dari pesanan darurat, bukan menambahkan kendaraan di aplikasi.'
                      : 'Halaman ini hanya untuk pengguna / pelanggan motor.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: isMech ? 'Kembali ke Tugas Montir' : 'Kembali ke Beranda',
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final title = widget.isEditing ? 'Ubah Sepeda Motor' : 'Tambah Motor Baru';
    final previewBrand = _brandController.text.trim();
    final previewModel = _modelController.text.trim();
    final matchedSpec = MotorcycleCatalog.findSpec(previewBrand, previewModel);
    final previewColor = _colorController.text.trim().isNotEmpty
        ? _colorController.text.trim()
        : matchedSpec.defaultColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Preview Foto Studio & Info Singkat Kendaraan
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6F0),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.peach),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: 136,
                          width: double.infinity,
                          child: MotorcycleImage(
                            brand: previewBrand.isEmpty ? 'Yamaha' : previewBrand,
                            model: previewModel.isEmpty ? 'NMAX 155' : previewModel,
                            photoUrl: _customPhotoUrl ?? matchedSpec.assetPath,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: MotorcycleCatalog.resolveSwatchColor(previewColor),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.charcoalGreen, width: 0.8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                previewBrand.isEmpty && previewModel.isEmpty
                                    ? 'Pilih model di bawah untuk pratinjau otomatis'
                                    : '$previewBrand $previewModel • $previewColor • $_selectedCategory',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Banner Error jika ada
                  if (_errorMessage != null) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Rekomendasi Cepat Model Riil Indonesia
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Pilihan Cepat Model Riil Indonesia:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepTeal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: MotorcycleCatalog.popularModels.map((spec) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                key: Key('quick_motor_${spec.brand}_${spec.model}'.replaceAll(' ', '_')),
                                avatar: const Icon(
                                  Icons.two_wheeler_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                label: Text('${spec.brand} ${spec.model}'),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: AppColors.peach),
                                labelStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                onPressed: () => _applyCatalogSpec(spec),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Merek Motor
                  AppTextField(
                    key: const Key('motorcycle_brand_field'),
                    controller: _brandController,
                    label: 'Merek Motor',
                    hint: 'Contoh: Honda, Yamaha, Suzuki',
                    prefixIcon: Icons.branding_watermark_rounded,
                    textCapitalization: TextCapitalization.words,
                    validator: (val) => AppValidators.validateBrandOrModel(val, 'Merek'),
                  ),
                  const SizedBox(height: 14),

                  // Model Motor
                  AppTextField(
                    controller: _modelController,
                    label: 'Model / Tipe Motor',
                    hint: 'Contoh: Vario 160, NMAX 155, Beat',
                    prefixIcon: Icons.two_wheeler_rounded,
                    textCapitalization: TextCapitalization.words,
                    validator: (val) => AppValidators.validateBrandOrModel(val, 'Model'),
                  ),
                  const SizedBox(height: 14),

                  // Warna Kendaraan + Chip Swatch
                  const Text(
                    'Warna Kendaraan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: MotorcycleCatalog.colorOptions.map((opt) {
                        final isSelected =
                            _colorController.text.trim().toLowerCase() == opt.name.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: isSelected,
                            showCheckmark: false,
                            backgroundColor: Colors.white,
                            selectedColor: AppColors.softPeach,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                            avatar: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: opt.swatch,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.charcoalGreen, width: 0.8),
                              ),
                            ),
                            label: Text(
                              opt.name,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: AppColors.deepTeal,
                              ),
                            ),
                            onSelected: (_) {
                              setState(() => _colorController.text = opt.name);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    key: const Key('motorcycle_color_field'),
                    controller: _colorController,
                    label: 'Detail Warna',
                    hint: 'Contoh: Hitam Doff, Biru Navy, Merah Crimson',
                    prefixIcon: Icons.palette_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 14),

                  // Kategori & Kapasitas Mesin (CC)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: MotorcycleCatalog.categories
                              .map((cat) => DropdownMenuItem<String>(
                                    value: cat,
                                    child: Text(cat, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AppTextField(
                          key: const Key('motorcycle_cc_field'),
                          controller: _ccController,
                          label: 'Mesin (CC)',
                          hint: '155',
                          prefixIcon: Icons.bolt_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Transmisi & BBM
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedTransmission,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Transmisi',
                            prefixIcon: Icon(Icons.settings_outlined),
                          ),
                          items: MotorcycleCatalog.transmissions
                              .map((t) => DropdownMenuItem<String>(
                                    value: t,
                                    child: Text(t, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedTransmission = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedFuelType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Rekomendasi BBM',
                            prefixIcon: Icon(Icons.local_gas_station_outlined),
                          ),
                          items: MotorcycleCatalog.fuelTypes
                              .map((f) => DropdownMenuItem<String>(
                                    value: f,
                                    child: Text(f, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedFuelType = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tahun Produksi
                  AppTextField(
                    controller: _yearController,
                    label: 'Tahun Produksi',
                    hint: 'Contoh: 2022',
                    prefixIcon: Icons.calendar_today_rounded,
                    keyboardType: TextInputType.number,
                    validator: AppValidators.validateProductionYear,
                  ),
                  const SizedBox(height: 14),

                  // Plat Nomor (Opsional)
                  AppTextField(
                    controller: _plateController,
                    label: 'Nomor Polisi / Plat (Opsional)',
                    hint: 'Contoh: BL 1234 AB',
                    prefixIcon: Icons.pin_rounded,
                    textCapitalization: TextCapitalization.characters,
                    validator: AppValidators.validateLicensePlate,
                  ),
                  const SizedBox(height: 14),

                  // Kilometer Awal (Hanya saat tambah baru)
                  if (!widget.isEditing) ...<Widget>[
                    AppTextField(
                      controller: _mileageController,
                      label: 'Kilometer Saat Ini (km)',
                      hint: 'Contoh: 12500',
                      prefixIcon: Icons.speed_rounded,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        final res = AppValidators.validateMileage(0, val ?? '');
                        if (res == MileageValidationResult.invalid) {
                          return 'Masukkan angka kilometer valid (0 - 999.999)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                  ] else
                    const SizedBox(height: 8),

                  // Tombol Simpan
                  PrimaryButton(
                    key: const Key('submit_motorcycle_button'),
                    label: widget.isEditing ? 'Simpan Perubahan' : 'Daftarkan Motor',
                    isLoading: _isLoading,
                    icon: widget.isEditing ? Icons.save_rounded : Icons.check_rounded,
                    onPressed: _handleSubmit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
