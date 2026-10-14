import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/workshop.dart';
import '../domain/workshop_rules.dart';
import 'workshops_providers.dart';

/// Layar Katalog Bengkel Terverifikasi sesuai PRD Bagian 7 (M6)
class WorkshopsScreen extends ConsumerStatefulWidget {
  const WorkshopsScreen({super.key});

  @override
  ConsumerState<WorkshopsScreen> createState() => _WorkshopsScreenState();
}

class _WorkshopsScreenState extends ConsumerState<WorkshopsScreen> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(workshopSearchQueryProvider),
    );
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

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(workshopSelectedCityProvider);
    final workshopsAsync = ref.watch(workshopsListProvider);
    final currentQuery = ref.watch(workshopSearchQueryProvider);
    final userLocationAsync = ref.watch(userLocationProvider);
    final userLocation = userLocationAsync.valueOrNull;

    // Evaluasi TC-10: Pencarian di luar wilayah operasional MotoCare
    final bool isOutOfCoverage = WorkshopRules.isOutOfCoverageQuery(currentQuery);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bengkel Terverifikasi'),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/motors');
              break;
            case 2:
              break;
            case 3:
              context.go('/tutorials');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
      ),
      body: SafeArea(
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
              height: 44,
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
                        loading: () => ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: 4,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) => const LoadingSkeleton(
                            height: 140,
                            borderRadius: 16,
                          ),
                        ),
                        error: (error, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: ErrorState(
                              title: 'Gagal Memuat Bengkel',
                              message: error.toString(),
                              onRetry: () =>
                                  ref.invalidate(workshopsListProvider),
                            ),
                          ),
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
                            padding: const EdgeInsets.all(16),
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

                              return _WorkshopCard(
                                workshop: workshop,
                                distance: distanceStr,
                                onTap: () =>
                                    context.push('/workshops/${workshop.id}'),
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
    );
  }

  Widget _buildCityChip(String cityKey, String label, String currentSelected) {
    final bool isSelected = currentSelected.toLowerCase() == cityKey.toLowerCase();

    return ChoiceChip(
      key: Key('city_chip_${cityKey.replaceAll(' ', '_')}'),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _selectCity(cityKey),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Baris Header: Nama Bengkel & Lencana Demo/Simulasi
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      workshop.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (workshop.isDemo) ...<Widget>[
                    const SizedBox(width: 8),
                    const StatusChip(
                      key: Key('demo_workshop_badge'),
                      label: 'Demo/Simulasi',
                      icon: Icons.science_outlined,
                      backgroundColor: Color(0xFFF3F4F6),
                      textColor: AppColors.textSecondary,
                      borderColor: Color(0xFFE5E7EB),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),

              // Alamat & Kota
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      workshop.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Baris Info Jarak (jika ada) dan Jam Operasional
              Row(
                children: <Widget>[
                  if (distance != null) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.peach),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.directions_bike_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (workshop.openingHours != null) ...<Widget>[
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      workshop.openingHours!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),

              // Layanan Unggulan
              if (workshop.services.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: workshop.services.take(3).map((service) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        service,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
