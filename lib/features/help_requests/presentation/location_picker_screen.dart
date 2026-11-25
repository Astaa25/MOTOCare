import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/maps_places_service.dart';
import '../../../core/services/user_location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/animated_loading.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/help_request_rules.dart';
import 'widgets/mini_map_picker_preview.dart';

/// Draf lokasi yang dipilih atau diketik pengguna
class LocationDraft {
  const LocationDraft({
    required this.addressText,
    required this.cityRegency,
    this.landmark,
    this.latitude,
    this.longitude,
  });

  final String addressText;
  final String cityRegency;
  final String? landmark;
  final double? latitude;
  final double? longitude;

  bool get isValid => addressText.trim().length >= 5;

  bool get isWithinServiceArea => HelpRequestRules.isWithinServiceArea(
        latitude: latitude,
        longitude: longitude,
        cityRegency: cityRegency,
      );
}

/// Provider penyimpanan draft form lokasi agar tidak hilang saat koneksi gagal (Figma 09.05)
final locationDraftProvider = StateProvider<LocationDraft>((ref) {
  final global = ref.watch(globalUserLocationProvider);
  return LocationDraft(
    addressText: global.formattedAddress ?? 'Jl. Merdeka, Banda Sakti, Kota Lhokseumawe',
    cityRegency: global.cityRegency,
    latitude: global.latitude ?? 5.1801,
    longitude: global.longitude ?? 97.1396,
  );
});

/// Layar Pemilihan Lokasi Manual Figma 03.02: "Di mana kamu menunggu?"
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialDraft,
  });

  final LocationDraft? initialDraft;

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _addressController;
  late final TextEditingController _landmarkController;

  String _cityRegency = 'Kota Lhokseumawe';
  double? _latitude;
  double? _longitude;
  List<PlaceSuggestion> _suggestions = <PlaceSuggestion>[];
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    final LocationDraft draft = widget.initialDraft ?? ref.read(locationDraftProvider);

    _searchController = TextEditingController();
    _addressController = TextEditingController(text: draft.addressText);
    _landmarkController = TextEditingController(text: draft.landmark ?? '');
    _cityRegency = draft.cityRegency;
    _latitude = draft.latitude;
    _longitude = draft.longitude;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final placesService = ref.read(mapsPlacesServiceProvider);
    placesService.costController.debouncer.run(() async {
      if (!mounted) return;
      if (query.trim().length < 2) {
        setState(() {
          _suggestions = <PlaceSuggestion>[];
          _isLoadingSuggestions = false;
        });
        return;
      }

      setState(() => _isLoadingSuggestions = true);
      final results = await placesService.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isLoadingSuggestions = false;
      });
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    final placesService = ref.read(mapsPlacesServiceProvider);
    final detail = await placesService.getPlaceDetails(suggestion.placeId);

    if (!mounted) return;
    setState(() {
      _suggestions = <PlaceSuggestion>[];
      _searchController.clear();
      if (detail != null) {
        _addressController.text = detail.formattedAddress;
        _cityRegency = detail.cityRegency;
        _latitude = detail.latitude;
        _longitude = detail.longitude;
        if (detail.landmark != null && detail.landmark!.isNotEmpty) {
          _landmarkController.text = detail.landmark!;
        }
      } else {
        _addressController.text = suggestion.secondaryText.isNotEmpty
            ? suggestion.secondaryText
            : suggestion.mainText;
        _cityRegency = suggestion.cityRegency;
        _latitude = suggestion.latitude ?? 5.1801;
        _longitude = suggestion.longitude ?? 97.1396;
      }
    });

    _persistDraft();
  }

  void _persistDraft() {
    final draft = LocationDraft(
      addressText: _addressController.text.trim(),
      cityRegency: _cityRegency,
      landmark: _landmarkController.text.trim().isNotEmpty ? _landmarkController.text.trim() : null,
      latitude: _latitude,
      longitude: _longitude,
    );
    ref.read(locationDraftProvider.notifier).state = draft;
  }

  void _submit() {
    final addressText = _addressController.text.trim();
    if (addressText.length < 5) return;

    final inServiceArea = HelpRequestRules.isWithinServiceArea(
      latitude: _latitude,
      longitude: _longitude,
      cityRegency: _cityRegency,
    );
    if (!inServiceArea) return;

    final result = LocationDraft(
      addressText: addressText,
      cityRegency: _cityRegency,
      landmark: _landmarkController.text.trim().isNotEmpty ? _landmarkController.text.trim() : null,
      latitude: _latitude,
      longitude: _longitude,
    );

    // Perbarui draf dan lokasi global aplikasi
    ref.read(locationDraftProvider.notifier).state = result;
    ref.read(globalUserLocationProvider.notifier).setManualLocation(
          address: result.addressText,
          cityRegency: result.cityRegency,
          latitude: result.latitude,
          longitude: result.longitude,
          landmark: result.landmark,
        );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final addressText = _addressController.text.trim();
    final bool isAddressValid = addressText.length >= 5;
    final bool isAreaValid = HelpRequestRules.isWithinServiceArea(
      latitude: _latitude,
      longitude: _longitude,
      cityRegency: _cityRegency,
    );
    final bool canConfirm = isAddressValid && isAreaValid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Ubah Lokasi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: <Widget>[
                  // Judul Figma 03.02
                  const Text(
                    'Di mana kamu menunggu?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih lokasi penjemputan atau ketik alamat agar mekanik dapat langsung menuju posisi Anda.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar Autocomplete dengan Debounce 400ms & Session Token
                  TextFormField(
                    key: const Key('places_autocomplete_search_field'),
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari alamat, nama tempat, atau jalan...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                      suffixIcon: _isLoadingSuggestions
                          ? Padding(
                              padding: const EdgeInsets.all(10),
                              child: MotoCareLoadingIndicator.small(),
                            )
                          : (_searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _suggestions = <PlaceSuggestion>[]);
                                  },
                                )
                              : null),
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

                  // Daftar Saran Autocomplete (Maksimal 5)
                  if (_suggestions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: _suggestions.map((s) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined, color: AppColors.primary, size: 20),
                            title: Text(
                              s.mainText,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            subtitle: Text(
                              s.secondaryText,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSuggestion(s),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Pratinjau Mini Map dengan Marker Pin
                  MiniMapPickerPreview(
                    latitude: _latitude ?? 5.1801,
                    longitude: _longitude ?? 97.1396,
                    address: addressText.isNotEmpty ? addressText : 'Lokasi Terpilih',
                    isWithinServiceArea: isAreaValid,
                    onLocationChanged: (newLat, newLng) {
                      setState(() {
                        _latitude = newLat;
                        _longitude = newLng;
                      });
                      _persistDraft();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pilihan Kota / Kabupaten
                  const Text(
                    'Kota / Kabupaten Layanan *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: <Widget>[
                      ChoiceChip(
                        key: const Key('picker_chip_lhokseumawe'),
                        label: const Text('Kota Lhokseumawe', style: TextStyle(fontSize: 12)),
                        selected: _cityRegency == 'Kota Lhokseumawe',
                        selectedColor: AppColors.cream,
                        side: BorderSide(
                          color: _cityRegency == 'Kota Lhokseumawe' ? AppColors.primary : AppColors.border,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _cityRegency = 'Kota Lhokseumawe');
                            _persistDraft();
                          }
                        },
                      ),
                      ChoiceChip(
                        key: const Key('picker_chip_aceh_utara'),
                        label: const Text('Kab. Aceh Utara', style: TextStyle(fontSize: 12)),
                        selected: _cityRegency == 'Kabupaten Aceh Utara',
                        selectedColor: AppColors.cream,
                        side: BorderSide(
                          color: _cityRegency == 'Kabupaten Aceh Utara' ? AppColors.primary : AppColors.border,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _cityRegency = 'Kabupaten Aceh Utara');
                            _persistDraft();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Alamat Lengkap Penjemputan
                  const Text(
                    'Alamat Lengkap *',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('picker_address_field'),
                    controller: _addressController,
                    maxLines: 2,
                    onChanged: (_) {
                      setState(() {});
                      _persistDraft();
                    },
                    decoration: InputDecoration(
                      hintText: 'Contoh: Jl. Merdeka No. 12, Banda Sakti...',
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
                  const SizedBox(height: 14),

                  // Patokan Lokasi (Landmark Opsional)
                  const Text(
                    'Patokan Lokasi (Opsional)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: const Key('picker_landmark_field'),
                    controller: _landmarkController,
                    onChanged: (_) => _persistDraft(),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Depan ruko fotocopy, dekat jembatan...',
                      prefixIcon: const Icon(Icons.flag_outlined, color: AppColors.textSecondary),
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
                ],
              ),
            ),

            // Bagian Bawah: Pesan Validasi & Tombol "Gunakan lokasi ini"
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceBright,
                border: const Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Pesan validasi bertulis (bukan hanya border merah sesuai handoff)
                  if (!isAddressValid && addressText.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Alamat lokasi minimal 5 karakter.',
                        style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    )
                  else if (!isAreaValid)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Lokasi di luar wilayah operasional (Kota Lhokseumawe & Kab. Aceh Utara).',
                        style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ),

                  PrimaryButton(
                    key: const Key('btn_confirm_location_picker'),
                    label: 'Gunakan lokasi ini',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: canConfirm ? _submit : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
