import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../../motorcycles/presentation/motorcycle_providers.dart';
import '../../notifications/presentation/notifications_providers.dart';
import '../domain/default_templates.dart';
import '../domain/maintenance_reminder.dart';
import '../domain/reminder_rules.dart';
import '../domain/reminder_status.dart';
import 'reminders_providers.dart';

/// Layar Tambah / Ubah Pengingat Servis (`/reminders/new` & `/reminders/:id/edit`)
class AddEditReminderScreen extends ConsumerStatefulWidget {
  final String? reminderId;
  final String? motorcycleId;

  const AddEditReminderScreen({
    super.key,
    this.reminderId,
    this.motorcycleId,
  });

  @override
  ConsumerState<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends ConsumerState<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _targetKmController;
  late final TextEditingController _intervalKmController;
  late final TextEditingController _intervalMonthsController;

  String? _selectedServiceType;
  DateTime? _selectedReminderDate;
  ReminderTemplate? _selectedTemplate;

  bool _isLoading = false;
  bool _isInit = false;
  String? _motorId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _targetKmController = TextEditingController();
    _intervalKmController = TextEditingController();
    _intervalMonthsController = TextEditingController();
    _motorId = widget.motorcycleId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _initFormData();
      _isInit = true;
    }
  }

  Future<void> _initFormData() async {
    if (widget.reminderId != null) {
      final repo = ref.read(reminderRepositoryProvider);
      final res = await repo.getReminderById(widget.reminderId!);
      if (res.isSuccess && mounted) {
        final r = res.dataOrNull!;
        _motorId = r.motorcycleId;
        _titleController.text = r.title;
        _selectedServiceType = r.serviceType;
        _selectedReminderDate = r.reminderDate;
        if (r.targetMileage != null) {
          _targetKmController.text = r.targetMileage.toString();
        }
        if (r.intervalKm != null) {
          _intervalKmController.text = r.intervalKm.toString();
        }
        if (r.intervalMonths != null) {
          _intervalMonthsController.text = r.intervalMonths.toString();
        }
        setState(() {});
      }
    } else {
      // Default template: Oli Mesin
      _applyTemplate(DefaultReminderTemplates.engineOil);
    }
  }

  void _applyTemplate(ReminderTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _titleController.text = template.title;
      _selectedServiceType = template.serviceType;

      final motorAsync = _motorId != null
          ? ref.read(motorcycleDetailProvider(_motorId!))
          : ref.read(activeMotorcycleProvider);
      final int currentKm = motorAsync.valueOrNull?.currentMileage ?? 0;
      final DateTime now = DateTime.now();

      if (template.intervalKm != null) {
        _intervalKmController.text = template.intervalKm.toString();
        _targetKmController.text = (currentKm + template.intervalKm!).toString();
      } else {
        _intervalKmController.clear();
        _targetKmController.clear();
      }

      if (template.intervalMonths != null) {
        _intervalMonthsController.text = template.intervalMonths.toString();
        _selectedReminderDate = addMonths(now, template.intervalMonths!);
      } else {
        _intervalMonthsController.clear();
        _selectedReminderDate = null;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetKmController.dispose();
    _intervalKmController.dispose();
    _intervalMonthsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _selectedReminderDate ?? now.add(const Duration(days: 30));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedReminderDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final String targetKmText = _targetKmController.text.trim();
    if (_selectedReminderDate == null && targetKmText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal satu pemicu (Tanggal atau Target Kilometer) wajib diisi!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final int? targetKm = targetKmText.isNotEmpty ? int.tryParse(targetKmText) : null;
    final int? intervalKm = _intervalKmController.text.trim().isNotEmpty
        ? int.tryParse(_intervalKmController.text.trim())
        : null;
    final int? intervalMonths = _intervalMonthsController.text.trim().isNotEmpty
        ? int.tryParse(_intervalMonthsController.text.trim())
        : null;

    final resolvedMotorId = _motorId ?? ref.read(activeMotorcycleProvider).valueOrNull?.id;
    if (resolvedMotorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sepeda motor belum dipilih.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? 'demo-user-1';

    setState(() => _isLoading = true);

    // Minta izin notifikasi jika pembuatan pertama
    final notifService = ref.read(notificationServiceProvider);
    await notifService.requestPermission();

    if (widget.reminderId == null) {
      // Tambah Baru
      final reminder = MaintenanceReminder(
        id: '',
        motorcycleId: resolvedMotorId,
        userId: userId,
        title: _titleController.text.trim(),
        serviceType: _selectedServiceType,
        reminderDate: _selectedReminderDate,
        targetMileage: targetKm,
        intervalKm: intervalKm,
        intervalMonths: intervalMonths,
        status: StoredReminderStatus.active,
        createdAt: DateTime.now(),
      );

      final res = await ref.read(remindersNotifierProvider.notifier).addReminder(reminder);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res.isSuccess) {
        await SuccessDialog.show(
          context,
          title: 'Pengingat Disimpan',
          message: 'Jadwal servis berhasil dicatat dan akan dipantau otomatis.',
        );
        if (mounted) context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.exceptionOrNull?.message ?? 'Gagal menyimpan pengingat.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      // Ubah
      final reminder = MaintenanceReminder(
        id: widget.reminderId!,
        motorcycleId: resolvedMotorId,
        userId: userId,
        title: _titleController.text.trim(),
        serviceType: _selectedServiceType,
        reminderDate: _selectedReminderDate,
        targetMileage: targetKm,
        intervalKm: intervalKm,
        intervalMonths: intervalMonths,
        status: StoredReminderStatus.active,
        createdAt: DateTime.now(),
      );

      final res = await ref.read(remindersNotifierProvider.notifier).updateReminder(reminder);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res.isSuccess) {
        await SuccessDialog.show(
          context,
          title: 'Pengingat Diperbarui',
          message: 'Perubahan jadwal pengingat servis berhasil disimpan.',
        );
        if (mounted) context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.exceptionOrNull?.message ?? 'Gagal memperbarui pengingat.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.reminderId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Ubah Pengingat Servis' : 'Buat Pengingat Servis',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: <Widget>[
              // Templat Bawaan (Hanya tampil saat mode Buat Baru)
              if (!isEdit) ...<Widget>[
                const Text(
                  'Pilih Templat Cepat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Interval bawaan berdasarkan rekomendasi pabrikan. Anda dapat menyesuaikannya.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: DefaultReminderTemplates.all.map((t) {
                      final isSelected = _selectedTemplate == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t.title),
                          selected: isSelected,
                          selectedColor: AppColors.cream,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                          onSelected: (_) => _applyTemplate(t),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Judul Pengingat
              TextFormField(
                key: const Key('reminder_title_field'),
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Pengingat *',
                  hintText: 'Contoh: Ganti Oli Mesin',
                  prefixIcon: Icon(Icons.bookmark_outline_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul pengingat wajib diisi';
                  }
                  if (val.trim().length < 2 || val.trim().length > 80) {
                    return 'Judul harus antara 2 hingga 80 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Pilihan Jenis Servis Resmi
              DropdownButtonFormField<String>(
                key: const Key('reminder_service_type_field'),
                initialValue: _selectedServiceType,
                decoration: const InputDecoration(
                  labelText: 'Kategori Jenis Servis',
                  prefixIcon: Icon(Icons.build_outlined),
                ),
                items: AppConstants.serviceTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedServiceType = val;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Bagian Pemicu Pengingat
              const Text(
                'Pemicu Jadwal (Minimal Satu Wajib Diisi)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Pemicu 1: Tanggal Jatuh Tempo
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: InkWell(
                  key: const Key('reminder_date_picker_button'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickDate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Tanggal Jatuh Tempo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedReminderDate != null
                                    ? AppFormatters.formatDate(_selectedReminderDate!)
                                    : 'Pilih tanggal pengingat (Opsional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedReminderDate != null
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: _selectedReminderDate != null
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedReminderDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _selectedReminderDate = null),
                          )
                        else
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Pemicu 2: Target Kilometer
              TextFormField(
                key: const Key('reminder_target_km_field'),
                controller: _targetKmController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Target Kilometer (KM)',
                  hintText: 'Contoh: 15000',
                  prefixIcon: Icon(Icons.speed_rounded),
                  suffixText: 'km',
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final n = int.tryParse(val.trim());
                    if (n == null || n < 0 || n > AppConstants.mileageMax) {
                      return 'Kilometer harus antara 0 sampai ${AppConstants.mileageMax}';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Bagian Pengaturan Siklus Berulang
              const Text(
                'Pengaturan Pengingat Berulang (Opsional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Saat servis dicatat selesai, pengingat berikutnya akan otomatis dibuat berdasarkan interval ini.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),

              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      key: const Key('reminder_interval_km_field'),
                      controller: _intervalKmController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Interval KM',
                        hintText: 'Contoh: 3000',
                        suffixText: 'km',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('reminder_interval_months_field'),
                      controller: _intervalMonthsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Interval Bulan',
                        hintText: 'Contoh: 3',
                        suffixText: 'bulan',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Tombol Simpan
              PrimaryButton(
                key: const Key('save_reminder_button'),
                label: isEdit ? 'Simpan Perubahan' : 'Simpan Pengingat',
                icon: Icons.save_rounded,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
