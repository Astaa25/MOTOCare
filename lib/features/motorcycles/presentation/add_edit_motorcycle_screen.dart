import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/motorcycle.dart';
import 'motorcycle_providers.dart';

/// Layar Tambah / Ubah Sepeda Motor sesuai PRD M3
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

  bool _isLoading = false;
  String? _errorMessage;
  Motorcycle? _existingMotorcycle;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    final list = ref.read(motorcyclesProvider).valueOrNull ?? <Motorcycle>[];
    final motor = list.where((m) => m.id == widget.motorcycleId).firstOrNull;
    if (motor != null) {
      _populateFields(motor);
    } else {
      // Ambil dari detail provider
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
    });
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _mileageController.dispose();
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

    if (widget.isEditing) {
      if (_existingMotorcycle == null) return;
      final updated = _existingMotorcycle!.copyWith(
        brand: brand,
        model: model,
        productionYear: year,
        licensePlate: plate,
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
            message: 'Informasi $brand $model berhasil diperbarui.',
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
      // Tambah motor baru
      final mileage = int.parse(_mileageController.text.trim());
      final result = await ref
          .read(motorcyclesProvider.notifier)
          .addMotorcycle(
            brand: brand,
            model: model,
            productionYear: year,
            licensePlate: plate,
            currentMileage: mileage,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      result.when(
        onSuccess: (_) async {
          await SuccessDialog.show(
            context,
            title: 'Motor Berhasil Ditambahkan',
            message: '$brand $model berhasil didaftarkan ke MotoCare.',
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
    final title = widget.isEditing ? 'Ubah Sepeda Motor' : 'Tambah Motor Baru';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Header penjelasan singkat
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.peach),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.isEditing
                              ? 'Ubah informasi umum sepeda motor Anda di bawah ini.'
                              : 'Daftarkan motor Anda untuk mengaktifkan pengingat servis berkala dan riwayat perawatan.',
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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
                      style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Merek Motor
                AppTextField(
                  controller: _brandController,
                  label: 'Merek Motor',
                  hint: 'Contoh: Honda, Yamaha, Suzuki',
                  prefixIcon: Icons.branding_watermark_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: (val) => AppValidators.validateBrandOrModel(val, 'Merek'),
                ),
                const SizedBox(height: 16),

                // Model Motor
                AppTextField(
                  controller: _modelController,
                  label: 'Model / Tipe Motor',
                  hint: 'Contoh: Vario 160, NMAX 155, Beat',
                  prefixIcon: Icons.two_wheeler_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: (val) => AppValidators.validateBrandOrModel(val, 'Model'),
                ),
                const SizedBox(height: 16),

                // Tahun Produksi
                AppTextField(
                  controller: _yearController,
                  label: 'Tahun Produksi',
                  hint: 'Contoh: 2022',
                  prefixIcon: Icons.calendar_today_rounded,
                  keyboardType: TextInputType.number,
                  validator: AppValidators.validateProductionYear,
                ),
                const SizedBox(height: 16),

                // Plat Nomor (Opsional)
                AppTextField(
                  controller: _plateController,
                  label: 'Nomor Polisi / Plat (Opsional)',
                  hint: 'Contoh: BL 1234 AB',
                  prefixIcon: Icons.pin_rounded,
                  textCapitalization: TextCapitalization.characters,
                  validator: AppValidators.validateLicensePlate,
                ),
                const SizedBox(height: 16),

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
    );
  }
}
