import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/service_history.dart';
import '../../reminders/presentation/reminders_providers.dart';
import 'service_history_providers.dart';

/// Layar Tambah / Ubah Catatan Servis sesuai PRD 7 M4
class AddEditServiceHistoryScreen extends ConsumerStatefulWidget {
  final String motorcycleId;
  final ServiceHistory? existingService;
  final String? initialServiceType;
  final int? initialMileage;
  final String? initialDescription;
  final String? reminderId;

  const AddEditServiceHistoryScreen({
    super.key,
    required this.motorcycleId,
    this.existingService,
    this.initialServiceType,
    this.initialMileage,
    this.initialDescription,
    this.reminderId,
  });

  bool get isEditing => existingService != null;

  @override
  ConsumerState<AddEditServiceHistoryScreen> createState() =>
      _AddEditServiceHistoryScreenState();
}

class _AddEditServiceHistoryScreenState
    extends ConsumerState<AddEditServiceHistoryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  late String _selectedServiceType;
  late final TextEditingController _mileageController;
  late final TextEditingController _costController;
  late final TextEditingController _workshopController;
  late final TextEditingController _descriptionController;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingService;

    _selectedDate = existing?.serviceDate ?? DateTime.now();
    _selectedServiceType = existing?.serviceType ??
        widget.initialServiceType ??
        AppConstants.serviceTypes.first;

    _mileageController = TextEditingController(
      text: existing?.mileage.toString() ??
          widget.initialMileage?.toString() ??
          '',
    );
    _costController = TextEditingController(
      text: existing?.cost.toString() ?? '0',
    );
    _workshopController = TextEditingController(
      text: existing?.workshopName ?? '',
    );
    _descriptionController = TextEditingController(
      text: existing?.description ?? widget.initialDescription ?? '',
    );
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _costController.dispose();
    _workshopController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Pilih Tanggal Servis',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _errorMessage = null);

    final formValid = _formKey.currentState?.validate() ?? false;
    final dateErr = AppValidators.validateServiceDate(_selectedDate);
    if (dateErr != null) {
      setState(() => _errorMessage = dateErr);
      return;
    }
    if (!formValid) return;

    setState(() => _isLoading = true);

    final cleanCost = _costController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final cost = int.tryParse(cleanCost) ?? 0;
    final mileage = int.parse(_mileageController.text.trim());
    final workshop = _workshopController.text.trim().isEmpty
        ? null
        : _workshopController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    if (widget.isEditing) {
      final updated = widget.existingService!.copyWith(
        serviceDate: _selectedDate,
        serviceType: _selectedServiceType,
        mileage: mileage,
        cost: cost,
        workshopName: workshop,
        description: description,
      );

      final result = await ref
          .read(serviceHistoriesProvider(widget.motorcycleId).notifier)
          .updateServiceHistory(updated);

      if (!mounted) return;
      setState(() => _isLoading = false);

      result.when(
        onSuccess: (_) async {
          await SuccessDialog.show(
            context,
            title: 'Servis Diperbarui',
            message: 'Catatan servis berhasil diperbarui.',
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
      final result = await ref
          .read(serviceHistoriesProvider(widget.motorcycleId).notifier)
          .addServiceHistory(
            serviceDate: _selectedDate,
            mileage: mileage,
            serviceType: _selectedServiceType,
            cost: cost,
            workshopName: workshop,
            description: description,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      result.when(
        onSuccess: (_) async {
          if (widget.reminderId != null) {
            await ref.read(remindersNotifierProvider.notifier).completeReminder(
                  widget.reminderId!,
                  widget.motorcycleId,
                  serviceMileage: mileage,
                  serviceDate: _selectedDate,
                );
          }

          if (!mounted) return;
          await SuccessDialog.show(
            context,
            title: 'Servis Berhasil Dicatat',
            message: 'Catatan servis telah tersimpan dan kilometer motor telah diperbarui.',
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
    final title = widget.isEditing ? 'Ubah Catatan Servis' : 'Catat Servis Baru';

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
                // Header panduan singkat
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.peach),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Catat tanggal, jenis servis, kilometer, dan biaya perawatan motor Anda secara teratur.',
                          style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Error Banner
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

                // Pemilihan Tanggal Servis
                const Text(
                  'Tanggal Servis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  key: const Key('service_date_picker_button'),
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppFormatters.dateShort(_selectedDate),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Pilih Tanggal',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pemilihan Jenis Servis
                const Text(
                  'Jenis Servis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: const Key('service_type_dropdown'),
                      value: _selectedServiceType,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      items: AppConstants.serviceTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedServiceType = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Kilometer Servis
                AppTextField(
                  key: const Key('service_mileage_input'),
                  controller: _mileageController,
                  label: 'Kilometer Saat Servis (km)',
                  hint: 'Contoh: 12000',
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
                const SizedBox(height: 16),

                // Biaya Servis (Rp)
                AppTextField(
                  key: const Key('service_cost_input'),
                  controller: _costController,
                  label: 'Biaya Servis (Rp)',
                  hint: 'Contoh: 150000',
                  prefixIcon: Icons.payments_rounded,
                  keyboardType: TextInputType.number,
                  validator: AppValidators.validateCost,
                ),
                const SizedBox(height: 16),

                // Nama Bengkel (Opsional)
                AppTextField(
                  key: const Key('service_workshop_input'),
                  controller: _workshopController,
                  label: 'Nama Bengkel (Opsional)',
                  hint: 'Contoh: AHASS Surya Motor Lhokseumawe',
                  prefixIcon: Icons.storefront_rounded,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Catatan Servis (Opsional)
                AppTextField(
                  key: const Key('service_description_input'),
                  controller: _descriptionController,
                  label: 'Catatan Servis (Opsional)',
                  hint: 'Contoh: Ganti oli MPX2, filter udara, dan servis CVT',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Tombol Simpan
                PrimaryButton(
                  key: const Key('submit_service_button'),
                  label: widget.isEditing ? 'Simpan Perubahan' : 'Simpan Catatan Servis',
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
