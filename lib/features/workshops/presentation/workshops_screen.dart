import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/env.dart';
import '../../../core/services/user_location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_effects.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../help_requests/presentation/location_picker_screen.dart';
import '../domain/workshop.dart';
import '../domain/workshop_rules.dart';
import 'workshops_providers.dart';

/// Layar Katalog Bengkel Terverifikasi sesuai PRD Bagian 7 (M6) & Figma 05.01
class WorkshopsScreen extends ConsumerStatefulWidget {
  final String? initialCity;
  final String? initialQuery;

  const WorkshopsScreen({
    super.key,
    this.initialCity,
    this.initialQuery,
  });

  @override
  ConsumerState<WorkshopsScreen> createState() => _WorkshopsScreenState();
}

class _WorkshopsScreenState extends ConsumerState<WorkshopsScreen> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final initialQ = widget.initialQuery ?? ref.read(workshopSearchQueryProvider);
    _searchController = TextEditingController(text: initialQ);

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(workshopSearchQueryProvider.notifier).state = widget.initialQuery!;
      });
    }
    if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(workshopSelectedCityProvider.notifier).state = widget.initialCity!;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(workshopSearchQueryProvider.notifier).state = value;
      }
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    ref.read(workshopSearchQueryProvider.notifier).state = '';
  }

  void _selectCity(String city) {
    ref.read(workshopSelectedCityProvider.notifier).state = city;
  }

  Future<void> _openSearchLocationPicker(BuildContext context) async {
    final draft = await context.push<LocationDraft>('/help/picker');
    if (draft != null && mounted) {
      if (draft.cityRegency.isNotEmpty) {
        ref.read(workshopSelectedCityProvider.notifier).state = draft.cityRegency;
      }
      ref.read(globalUserLocationProvider.notifier).setManualLocation(
        address: draft.addressText,
        cityRegency: draft.cityRegency,
        landmark: draft.landmark,
        latitude: draft.latitude,
        longitude: draft.longitude,
      );
      ref.invalidate(workshopsListProvider);
    }
  }

  Future<void> _openExternalMapsSearch(
    String query,
    double? lat,
    double? lon,
  ) async {
    final clean = query.trim().isNotEmpty ? query.trim() : 'bengkel motor';
    final Uri uri;
    if (lat != null && lon != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$clean&center=$lat,$lon',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$clean+lhokseumawe',
      );
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(workshopSelectedCityProvider);
    final workshopsAsync = ref.watch(workshopsListProvider);
    final currentQuery = ref.watch(workshopSearchQueryProvider);
    final userLocationAsync = ref.watch(userLocationProvider);
    final userLocation = userLocationAsync.valueOrNull;
    final globalLocation = ref.watch(globalUserLocationProvider);

    // Evaluasi TC-10: Pencarian di luar wilayah operasional MotoCare
    final bool isOutOfCoverage = WorkshopRules.isOutOfCoverageQuery(currentQuery);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Bengkel Terverifikasi',
          style: TextStyle(
            color: AppColors.deepTeal,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.deepTeal),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: <Widget>[
          if (AppEnv.showDemoFeatures)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.softPeach,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Simulasi',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.action,
                ),
              ),
            ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
          children: <Widget>[
            // Kalimat Cakupan Wilayah Permanen sesuai PRD 2.2 & 7 M6
            Container(
              key: const Key('permanent_coverage_notice'),
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.peach, width: 1),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      WorkshopRules.permanentCoverageNotice,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Baris Lokasi Pencarian (Figma 05.01)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                key: const Key('workshop_search_location_bar'),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBright,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.my_location_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Lokasi Pencarian',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            globalLocation.formattedAddress ??
                                (selectedCity != 'Semua'
                                    ? selectedCity
                                    : 'Kota Lhokseumawe & Kab. Aceh Utara'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      key: const Key('change_workshop_search_location_button'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _openSearchLocationPicker(context),
                      child: const Text(
                        'Ubah',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Kolom Pencarian Nama atau Alamat
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                key: const Key('workshop_search_field'),
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari nama bengkel atau alamat...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: currentQuery.isNotEmpty
                      ? IconButton(
                          key: const Key('clear_workshop_search_button'),
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // Filter Chips Wilayah
            SizedBox(
              height: 38,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  _buildCityChip('Semua', 'Semua Wilayah', selectedCity),
                  const SizedBox(width: 8),
                  _buildCityChip(
                    WorkshopCoverageAreas.lhokseumawe,
                    WorkshopCoverageAreas.lhokseumawe,
                    selectedCity,
                  ),
                  const SizedBox(width: 8),
                  _buildCityChip(
                    WorkshopCoverageAreas.acehUtara,
                    WorkshopCoverageAreas.acehUtara,
                    selectedCity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Daftar Bengkel / Pesan Batas Wilayah
            Expanded(
              child: isOutOfCoverage
                  ? _buildOutOfCoverageView(currentQuery)
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        ref.invalidate(workshopsListProvider);
                      },
                      child: workshopsAsync.when(
                        loading: () => LoadingSkeleton.workshopList(),
                        error: (error, _) => ListView(
                          padding: const EdgeInsets.all(20),
                          children: <Widget>[
                            const SizedBox(height: 24),
                            Center(
                              child: Container(
                                key: const Key('failed_workshops_state'),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFF3E0),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.cloud_off_rounded,
                                        size: 38,
                                        color: Color(0xFFE65100),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Bengkel belum dapat dimuat',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Terjadi kendala saat memuat data bengkel di sekitar lokasi Anda. Periksa koneksi internet atau gunakan pencarian langsung di Google Maps.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    PrimaryButton(
                                      key: const Key('retry_workshops_button'),
                                      label: 'Coba Muat Ulang',
                                      icon: Icons.refresh_rounded,
                                      onPressed: () =>
                                          ref.invalidate(workshopsListProvider),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      key: const Key('open_external_maps_search_button'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryText,
                                        side: const BorderSide(
                                          color: AppColors.peach,
                                          width: 1.5,
                                        ),
                                        backgroundColor: AppColors.cream,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.map_rounded, size: 18),
                                      label: const Text(
                                        'Buka Pencarian di Maps',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      onPressed: () => _openExternalMapsSearch(
                                        currentQuery,
                                        userLocation?.latitude ??
                                            globalLocation.latitude,
                                        userLocation?.longitude ??
                                            globalLocation.longitude,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        data: (List<Workshop> workshops) {
                          if (workshops.isEmpty) {
                            return ListView(
                              padding: const EdgeInsets.all(24),
                              children: <Widget>[
                                const SizedBox(height: 32),
                                EmptyState(
                                  key: const Key('empty_workshops_state'),
                                  icon: Icons.store_mall_directory_outlined,
                                  title: 'Bengkel Tidak Ditemukan',
                                  message: currentQuery.isNotEmpty
                                      ? 'Tidak ada bengkel terverifikasi yang cocok dengan kata kunci "$currentQuery" di $selectedCity.'
                                      : 'Belum ada bengkel terverifikasi yang terdaftar di wilayah $selectedCity.',
                                  actionLabel: currentQuery.isNotEmpty
                                      ? 'Reset Pencarian'
                                      : null,
                                  onAction: currentQuery.isNotEmpty
                                      ? _clearSearch
                                      : null,
                                ),
                              ],
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, AppTokens.tabContentBottomPadding),
                            itemCount: workshops.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final workshop = workshops[index];
                              final distanceStr = WorkshopRules.formatDistance(
                                workshopLat: workshop.latitude,
                                workshopLon: workshop.longitude,
                                userLat: userLocation?.latitude,
                                userLon: userLocation?.longitude,
                              );

                              return AnimatedEntrance(
                                index: index,
                                child: _WorkshopCard(
                                  workshop: workshop,
                                  distance: distanceStr,
                                  onTap: () =>
                                      context.push('/workshops/${workshop.id}'),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildCityChip(String cityKey, String label, String currentSelected) {
    final bool isSelected = currentSelected.toLowerCase() == cityKey.toLowerCase();

    return ChoiceChip(
      key: Key('city_chip_${cityKey.replaceAll(' ', '_')}'),
      label: Text(label),
      selected: isSelected,
      showCheckmark: isSelected,
      checkmarkColor: AppColors.primary,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        _selectCity(cityKey);
      },
      selectedColor: AppColors.navIndicator,
      backgroundColor: AppColors.surfaceBright,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryText : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.4 : 1.0,
        ),
      ),
    );
  }

  /// Tampilan khusus TC-10: Pesan batas wilayah bila mencari di luar cakupan
  Widget _buildOutOfCoverageView(String query) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 32),
        EmptyState(
          key: const Key('out_of_coverage_state'),
          icon: Icons.map_outlined,
          title: 'Wilayah di Luar Jangkauan Layanan',
          message:
              'Saat ini MotoCare hanya melayani wilayah Kota Lhokseumawe dan Kabupaten Aceh Utara. Kami belum dapat menampilkan bengkel di "$query".',
          actionLabel: 'Lihat Bengkel Area Layanan',
          onAction: _clearSearch,
        ),
      ],
    );
  }
}

/// Kartu Bengkel Terverifikasi dengan Komposisi Warna MotoCare
class _WorkshopCard extends StatelessWidget {
  final Workshop workshop;
  final String? distance;
  final VoidCallback onTap;

  const _WorkshopCard({
    required this.workshop,
    this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveHoverCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFF0EAE1),
      padding: const EdgeInsets.all(14),
      child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Ikon Bengkel Soft Peach (Figma 05)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.softPeach,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.deepTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Detail Bengkel
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          workshop.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepTeal,
                            height: 1.3,
                          ),
                        ),
                        if (AppEnv.showDemoFeatures && workshop.isDemo)
                          const StatusChip(
                            key: Key('demo_workshop_badge'),
                            label: 'Demo/Simulasi',
                            icon: Icons.science_outlined,
                            backgroundColor: Color(0xFFF3F4F6),
                            textColor: AppColors.textSecondary,
                            borderColor: Color(0xFFE5E7EB),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workshop.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        if (distance != null) ...<Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softButter,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(
                                  Icons.directions_bike_rounded,
                                  size: 13,
                                  color: AppColors.deepTeal,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  distance!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (workshop.openingHours != null) ...<Widget>[
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    workshop.openingHours!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
    );
  }
}
