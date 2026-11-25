import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/services/maps_cost_controller.dart';
import '../../../core/services/user_location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_loading.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../../motorcycles/presentation/motorcycle_providers.dart';
import '../domain/help_request_rules.dart';
import '../domain/service_request.dart';
import 'help_requests_providers.dart';
import 'location_access_dialogs.dart';
import 'location_picker_screen.dart';
import 'widgets/mini_map_picker_preview.dart';

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
  late final TextEditingController _landmarkController;
  late final TextEditingController _phoneController;

  String _cityRegency = 'Kota Lhokseumawe';
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
    _landmarkController = TextEditingController();

    final user = ref.read(currentUserProvider);
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Mendeteksi koordinat GPS pengguna dengan penjelasan izin kontekstual (Figma 09.06 & 09.07)
  Future<void> _detectGpsLocation() async {
    setState(() => _isDetectingLocation = true);
    final service = ref.read(userLocationServiceProvider);

    try {
      final result = await service.requestCurrentLocation();
      if (!mounted) return;

      switch (result.status) {
        case LocationStatus.success:
          setState(() {
            _latitude = result.latitude;
            _longitude = result.longitude;
            _cityRegency = result.cityRegency;
            if (result.formattedAddress != null && result.formattedAddress!.isNotEmpty) {
              _addressController.text = result.formattedAddress!;
            }
          });
          ref.read(globalUserLocationProvider.notifier).setManualLocation(
                address: result.formattedAddress ?? _addressController.text,
                cityRegency: result.cityRegency,
                latitude: result.latitude,
                longitude: result.longitude,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lokasi terdeteksi: ${result.formattedAddress}'),
              backgroundColor: AppColors.success,
            ),
          );
          break;

        case LocationStatus.permissionDenied:
          showDialog<void>(
            context: context,
            builder: (ctx) => LocationPermissionDialog(
              isPermanentlyDenied: false,
              onRetry: () {
                Navigator.pop(ctx);
                _detectGpsLocation();
              },
              onManualInput: () => Navigator.pop(ctx),
            ),
          );
          break;

        case LocationStatus.permissionDeniedForever:
          showDialog<void>(
            context: context,
            builder: (ctx) => LocationPermissionDialog(
              isPermanentlyDenied: true,
              onRetry: () async {
                Navigator.pop(ctx);
                await service.openAppSettings();
              },
              onManualInput: () => Navigator.pop(ctx),
            ),
          );
          break;

        case LocationStatus.serviceDisabled:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Layanan GPS di perangkat belum aktif. Aktifkan lokasi.'),
              action: SnackBarAction(
                label: 'Setelan',
                textColor: Colors.white,
                onPressed: () => service.openLocationSettings(),
              ),
              backgroundColor: AppColors.warning,
            ),
          );
          break;

        case LocationStatus.outOfServiceArea:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.errorMessage ??
                    'Lokasi Anda berada di luar cakupan MotoCare. Masukkan alamat di Lhokseumawe/Aceh Utara.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          break;

        case LocationStatus.timeout:
          showDialog<void>(
            context: context,
            builder: (ctx) => LocationStaleDialog(
              lastAddress: _addressController.text.isNotEmpty
                  ? _addressController.text
                  : 'Banda Sakti, Kota Lhokseumawe',
              lastUpdatedText: 'Sinyal GPS lemah',
              onRefresh: () {
                Navigator.pop(ctx);
                _detectGpsLocation();
              },
              onUseLastLocation: () {
                Navigator.pop(ctx);
                if (_addressController.text.isEmpty) {
                  _addressController.text = 'Jl. Merdeka, Banda Sakti, Kota Lhokseumawe';
                }
              },
            ),
          );
          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Gagal mendeteksi sinyal GPS. Anda dapat mengisi manual.'),
              backgroundColor: AppColors.error,
            ),
          );
          break;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mendeteksi sinyal GPS. Anda dapat mengisi alamat manual.'),
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

    // Validasi cakupan wilayah layanan (Kota Lhokseumawe & Kab. Aceh Utara)
    if (!HelpRequestRules.isWithinServiceArea(
      latitude: _latitude,
      longitude: _longitude,
      cityRegency: _cityRegency,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lokasi berada di luar wilayah layanan MotoCare. Layanan hanya mencakup Kota Lhokseumawe dan Kabupaten Aceh Utara.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? 'user-current';

    final landmarkText = _landmarkController.text.trim();

    // Tinjau Permintaan (Figma 03.04 & PRD 631)
    final confirmed = await _showReviewBottomSheet(context);

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
      cityRegency: _cityRegency,
      landmark: landmarkText.isNotEmpty ? landmarkText : null,
      contactPhone: _phoneController.text.trim(),
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      isDemo: AppEnv.showDemoFeatures,
      idempotencyKey: MapsSessionTokenManager.generateUuidV4(),
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

  Future<bool?> _showReviewBottomSheet(BuildContext context) {
    final landmarkText = _landmarkController.text.trim();
    final addressText = _addressController.text.trim();
    final phoneText = _phoneController.text.trim();
    final hasCoords = _latitude != null && _longitude != null;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceBright,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x261B2B25),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Konfirmasi Panggilan Montir',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(20),
                shrinkWrap: true,
                children: <Widget>[
                  if (hasCoords) ...<Widget>[
                    MiniMapPickerPreview(
                      latitude: _latitude!,
                      longitude: _longitude!,
                      address: addressText,
                      isWithinServiceArea: true,
                      height: 140,
                    ),
                    const SizedBox(height: 14),
                  ],
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Row(
                          children: <Widget>[
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Lokasi Penjemputan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          addressText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _cityRegency,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (landmarkText.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Patokan: $landmarkText',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.two_wheeler_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedMotorcycleName ??
                                  'Motor Belum Ditentukan',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kendala: $_selectedCategory',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _descriptionController.text.trim(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Divider(height: 16),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Kontak: $phoneText',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Kesepakatan Biaya & Waktu Aktif',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Mekanik terdekat akan segera dihubungi. Permintaan aktif selama 15 menit.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Biaya jasa perbaikan disepakati langsung dengan montir di lokasi pengerjaan.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    key: const Key('confirmation_dialog_confirm_button'),
                    label: 'Konfirmasi & Panggil Montir',
                    icon: Icons.support_agent_rounded,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    key: const Key('confirmation_dialog_cancel_button'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Center(
                      child: Text(
                        'Periksa Kembali',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motorcyclesAsync = ref.watch(motorcyclesProvider);
    final actionState = ref.watch(helpRequestActionNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Panggil Montir'),
      ),
      body: AppBackground(
        child: SafeArea(
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
                    backgroundColor: AppColors.surfaceBright,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextButton.icon(
                        key: const Key('btn_open_picker_from_form'),
                        icon: const Icon(Icons.map_outlined, size: 15),
                        label: const Text('Peta', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final result = await context.push<LocationDraft>('/help/picker');
                          if (result != null && mounted) {
                            setState(() {
                              _addressController.text = result.addressText;
                              _cityRegency = result.cityRegency;
                              _latitude = result.latitude;
                              _longitude = result.longitude;
                              if (result.landmark != null && result.landmark!.isNotEmpty) {
                                _landmarkController.text = result.landmark!;
                              }
                            });
                          }
                        },
                      ),
                      TextButton.icon(
                        key: const Key('get_gps_location_button'),
                        icon: _isDetectingLocation
                            ? MotoCareLoadingIndicator.small(color: AppColors.primary)
                            : const Icon(Icons.my_location_rounded, size: 15),
                        label: Text(
                          _isDetectingLocation ? 'Mencari...' : 'GPS',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: _isDetectingLocation ? null : _detectGpsLocation,
                      ),
                    ],
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
              const SizedBox(height: 10),

              // Pilihan Wilayah Administratif Layanan
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  const Text(
                    'Wilayah: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  ChoiceChip(
                    key: const Key('chip_lhokseumawe'),
                    label: const Text('Kota Lhokseumawe', style: TextStyle(fontSize: 12)),
                    selected: _cityRegency == 'Kota Lhokseumawe',
                    selectedColor: AppColors.cream,
                    side: BorderSide(
                      color: _cityRegency == 'Kota Lhokseumawe' ? AppColors.primary : AppColors.border,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _cityRegency = 'Kota Lhokseumawe');
                    },
                  ),
                  ChoiceChip(
                    key: const Key('chip_aceh_utara'),
                    label: const Text('Kab. Aceh Utara', style: TextStyle(fontSize: 12)),
                    selected: _cityRegency == 'Kabupaten Aceh Utara',
                    selectedColor: AppColors.cream,
                    side: BorderSide(
                      color: _cityRegency == 'Kabupaten Aceh Utara' ? AppColors.primary : AppColors.border,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _cityRegency = 'Kabupaten Aceh Utara');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Patokan Lokasi Opsional (Landmark)
              TextFormField(
                key: const Key('help_landmark_field'),
                controller: _landmarkController,
                decoration: InputDecoration(
                  labelText: 'Patokan Lokasi (Opsional)',
                  hintText: 'Contoh: Depan ruko fotocopy, dekat SPBU Cunda...',
                  prefixIcon: const Icon(
                    Icons.flag_outlined,
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
                    isExpanded: true,
                    initialValue: _selectedMotorcycleId,
                    items: motors.map((m) {
                      final label =
                          '${m.brand} ${m.model} (${m.licensePlate ?? "-"})';
                      return DropdownMenuItem<String>(
                        value: m.id,
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
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
    ),
  );
}
}
