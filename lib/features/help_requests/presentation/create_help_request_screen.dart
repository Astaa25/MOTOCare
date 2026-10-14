import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../../motorcycles/presentation/motorcycle_providers.dart';
import '../domain/help_request_rules.dart';
import '../domain/service_request.dart';
import 'help_requests_providers.dart';

/// Layar Buat Permintaan Panggilan Bantuan Montir sesuai PRD Bagian 7 (M7)
class CreateHelpRequestScreen extends ConsumerStatefulWidget {
  final String? initialWorkshopId;

  const CreateHelpRequestScreen({
    super.key,
    this.initialWorkshopId,
  });

  @override
  ConsumerState<CreateHelpRequestScreen> createState() =>
      _CreateHelpRequestScreenState();
}

class _CreateHelpRequestScreenState
    extends ConsumerState<CreateHelpRequestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedCategory = CommonIssues.mesinMogok;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;

  double? _latitude;
  double? _longitude;
  bool _isDetectingLocation = false;
  String? _selectedMotorcycleId;
  String? _selectedMotorcycleName;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();

    final user = ref.read(currentUserProvider);
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Mendeteksi koordinat GPS pengguna dengan penjelasan izin ramah
  Future<void> _detectGpsLocation() async {
    setState(() => _isDetectingLocation = true);

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Layanan GPS di perangkat Anda belum aktif. Mohon aktifkan GPS.',
              ),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Izin lokasi diperlukan agar mekanik dapat menuju posisi Anda.',
                ),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi dinonaktifkan secara permanen di setelan HP.',
              ),
            ),
          );
        }
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          if (_addressController.text.trim().isEmpty) {
            _addressController.text =
                'Lokasi GPS (${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)})';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi koordinat GPS berhasil diperoleh.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal mendeteksi sinyal GPS. Anda dapat mengisi alamat manual.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetectingLocation = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? 'user-current';

    // Konfirmasi ringkasan sebelum kirim sesuai PRD 631
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Konfirmasi Panggilan Montir',
      message:
          'Anda akan memanggil mekanik untuk masalah "$_selectedCategory". '
          'Pastikan nomor telepon dan alamat Anda sudah benar:\n\n'
          '📍 Alamat: ${_addressController.text.trim()}\n'
          '📞 Kontak: ${_phoneController.text.trim()}\n'
          '🏍️ Motor: ${_selectedMotorcycleName ?? "Tidak ditentukan"}',
      confirmLabel: 'Ya, Panggil Montir',
      cancelLabel: 'Periksa Kembali',
    );

    if (confirmed != true || !mounted) return;

    final newRequest = ServiceRequest(
      id: '',
      userId: userId,
      motorcycleId: _selectedMotorcycleId,
      motorcycleName: _selectedMotorcycleName,
      issueCategory: _selectedCategory,
      issueDescription: _descriptionController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      addressText: _addressController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      isDemo: true,
    );

    final created = await ref
        .read(helpRequestActionNotifierProvider.notifier)
        .createRequest(newRequest);

    if (!mounted) return;

    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan panggilan montir berhasil dibuat!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/help/${created.id}');
    } else {
      final errorMsg =
          ref.read(helpRequestActionNotifierProvider).errorMessage ?? '';

      // TC-21: Penanganan permintaan kedua saat masih ada permintaan aktif
      if (errorMsg.contains('masih memiliki permintaan aktif')) {
        _showActiveRequestAlert();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg.isNotEmpty ? errorMsg : 'Gagal membuat permintaan.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showActiveRequestAlert() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('active_request_conflict_dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: <Widget>[
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text(
              'Permintaan Masih Aktif',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Anda masih memiliki permintaan bantuan mekanik yang sedang berjalan. '
          'Selesaikan atau batalkan permintaan sebelumnya sebelum membuat panggilan baru.',
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            key: const Key('open_active_request_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final active = await ref
                  .read(helpRequestRepositoryProvider)
                  .getActiveRequest();
              if (mounted) {
                if (active != null) {
                  context.go('/help/${active.id}');
                } else {
                  context.go('/help');
                }
              }
            },
            child: const Text('Buka Permintaan Aktif'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motorcyclesAsync = ref.watch(motorcyclesProvider);
    final actionState = ref.watch(helpRequestActionNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panggil Montir'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              // Banner Pernyataan Batas Layanan sesuai PRD 503 & 6.6
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.peach),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        HelpRequestRules.disclaimerText,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryText,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Pilihan Masalah Umum
              const Text(
                'Kategori Masalah *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CommonIssues.list.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    key: Key('category_${category.replaceAll(' ', '_')}'),
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Deskripsi Masalah (10 - 500 karakter)
              const Text(
                'Jelaskan Kondisi Motor Anda *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('issue_description_field'),
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 500,
                validator: HelpRequestRules.validateIssueDescription,
                decoration: InputDecoration(
                  hintText:
                      'Contoh: Mesin mati mendadak saat di jalan, tidak bisa distarter manual maupun elektrik...',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Alamat Penjemputan / Lokasi GPS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Lokasi Penjemputan *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('get_gps_location_button'),
                    icon: _isDetectingLocation
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded, size: 16),
                    label: Text(
                      _isDetectingLocation ? 'Mencari...' : 'Gunakan GPS',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: _isDetectingLocation ? null : _detectGpsLocation,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextFormField(
                key: const Key('help_address_field'),
                controller: _addressController,
                maxLines: 2,
                validator: (val) => HelpRequestRules.validateAddress(
                  addressText: val,
                  latitude: _latitude,
                  longitude: _longitude,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Jl. Merdeka No. 12, depan ruko fotocopy, Banda Sakti...',
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pilihan Motor
              const Text(
                'Sepeda Motor (Opsional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              motorcyclesAsync.maybeWhen(
                data: (motors) {
                  if (motors.isEmpty) {
                    return const Text(
                      'Belum ada motor terdaftar. Mekanik akan menanyakan tipe motor saat konfirmasi.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    );
                  }

                  // Default pilih motor pertama jika belum ada yang terpilih
                  if (_selectedMotorcycleId == null && motors.isNotEmpty) {
                    _selectedMotorcycleId = motors.first.id;
                    _selectedMotorcycleName =
                        '${motors.first.brand} ${motors.first.model} (${motors.first.licensePlate ?? "-"})';
                  }

                  return DropdownButtonFormField<String>(
                    key: const Key('select_motorcycle_dropdown'),
                    initialValue: _selectedMotorcycleId,
                    items: motors.map((m) {
                      final label =
                          '${m.brand} ${m.model} (${m.licensePlate ?? "-"})';
                      return DropdownMenuItem<String>(
                        value: m.id,
                        child: Text(label, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedMotorcycleId = val;
                        final motor = motors.firstWhere((m) => m.id == val);
                        _selectedMotorcycleName =
                            '${motor.brand} ${motor.model} (${motor.licensePlate ?? "-"})';
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Nomor Kontak Telepon
              const Text(
                'Nomor Telepon Kontak Anda *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('contact_phone_field'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: HelpRequestRules.validateContactPhone,
                decoration: InputDecoration(
                  hintText: '081234567890',
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Tombol Kirim Permintaan (TC-17: Disabled selama proses pengiriman)
              PrimaryButton(
                key: const Key('submit_help_request_button'),
                label: actionState.isLoading
                    ? 'Mengirim Permintaan...'
                    : 'Panggil Montir Sekarang',
                icon: Icons.send_rounded,
                isLoading: actionState.isLoading,
                onPressed: actionState.isLoading ? null : _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
