import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/motorcycle.dart';
import 'motorcycle_providers.dart';

/// Layar Perbarui Kilometer Sepeda Motor sesuai PRD 6.2 & M3
class UpdateMileageScreen extends ConsumerStatefulWidget {
  final String motorcycleId;

  const UpdateMileageScreen({
    super.key,
    required this.motorcycleId,
  });

  @override
  ConsumerState<UpdateMileageScreen> createState() =>
      _UpdateMileageScreenState();
}

class _UpdateMileageScreenState extends ConsumerState<UpdateMileageScreen> {
  final _mileageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(Motorcycle motor) async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final rawInput = _mileageController.text.trim();
    final validation = AppValidators.validateMileage(motor.currentMileage, rawInput);

    if (validation == MileageValidationResult.invalid) {
      setState(() => _errorMessage = 'Masukkan angka kilometer valid (0 - 999.999)');
      return;
    }

    final newMileage = int.parse(rawInput);

    // Dialog konfirmasi bila kilometer menurun (koreksi) sesuai PRD 6.2
    if (validation == MileageValidationResult.confirmDecrease) {
      final confirm = await ConfirmationDialog.show(
        context,
        title: 'Koreksi Penurunan Kilometer?',
        message:
            'Kilometer baru (${AppFormatters.mileage(newMileage)}) lebih rendah dari catatan sebelumnya (${AppFormatters.mileage(motor.currentMileage)}).\n\nApakah Anda yakin ingin mengoreksi catatan kilometer ini?',
        confirmLabel: 'Ya, Koreksi',
        cancelLabel: 'Batal',
      );
      if (!mounted || confirm != true) return;
    }

    // Dialog konfirmasi bila kenaikan kilometer melonjak > 5000 km sesuai PRD 6.2
    if (validation == MileageValidationResult.confirmBigJump) {
      final confirm = await ConfirmationDialog.show(
        context,
        title: 'Konfirmasi Kenaikan Kilometer',
        message:
            'Kenaikan kilometer melonjak lebih dari 5.000 km dari catatan sebelumnya (${AppFormatters.mileage(motor.currentMileage)} → ${AppFormatters.mileage(newMileage)}).\n\nPastikan angka speedometer yang Anda masukkan sudah benar.',
        confirmLabel: 'Lanjutkan Simpan',
        cancelLabel: 'Periksa Lagi',
      );
      if (!mounted || confirm != true) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(motorcyclesProvider.notifier)
        .updateMileage(motorcycleId: motor.id, newMileage: newMileage);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.when(
      onSuccess: (_) async {
        await SuccessDialog.show(
          context,
          title: 'Kilometer Diperbarui',
          message:
              'Catatan kilometer ${motor.name} kini ${AppFormatters.mileage(newMileage)}.',
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

  @override
  Widget build(BuildContext context) {
    final motorDetailAsync = ref.watch(motorcycleDetailProvider(widget.motorcycleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perbarui Kilometer'),
      ),
      body: SafeArea(
        child: motorDetailAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: LoadingSkeleton(height: 240, borderRadius: 16),
          ),
          error: (err, _) => ErrorState(
            title: 'Gagal Memuat Motor',
            message: err.toString(),
            onRetry: () => ref.refresh(motorcycleDetailProvider(widget.motorcycleId)),
          ),
          data: (Motorcycle motor) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Kartu status kilometer saat ini
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.vehicleCardGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.peach),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(Icons.two_wheeler_rounded, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  motor.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Catatan Kilometer Saat Ini',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppFormatters.mileage(motor.currentMileage),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pembaruan terakhir: ${AppFormatters.dateShort(motor.mileageUpdatedAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Banner Error
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

                    // Input kilometer baru
                    AppTextField(
                      controller: _mileageController,
                      label: 'Kilometer Speedometer Baru (km)',
                      hint: 'Contoh: ${motor.currentMileage + 500}',
                      prefixIcon: Icons.speed_rounded,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Angka kilometer wajib diisi';
                        }
                        final res = AppValidators.validateMileage(motor.currentMileage, val);
                        if (res == MileageValidationResult.invalid) {
                          return 'Masukkan angka kilometer valid (0 - 999.999)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Tips: Catatan kilometer yang akurat membantu MotoCare memprediksi jadwal ganti oli dan servis rutin dengan tepat waktu.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),

                    // Tombol simpan
                    PrimaryButton(
                      key: const Key('save_mileage_button'),
                      label: 'Simpan Kilometer Baru',
                      isLoading: _isLoading,
                      icon: Icons.check_circle_rounded,
                      onPressed: () => _handleSave(motor),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
