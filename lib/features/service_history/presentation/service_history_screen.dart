import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_effects.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../domain/service_history.dart';
import 'service_history_providers.dart';

/// Layar Daftar Riwayat Servis & Total Biaya sesuai PRD 7 M4 & Rute `/motors/:id/services`
class ServiceHistoryScreen extends ConsumerStatefulWidget {
  final String motorcycleId;

  const ServiceHistoryScreen({
    super.key,
    required this.motorcycleId,
  });

  @override
  ConsumerState<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends ConsumerState<ServiceHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final selectedFilter = ref.read(serviceHistoryFilterProvider(widget.motorcycleId));
      ref.read(serviceHistoriesProvider(widget.motorcycleId).notifier).loadMore(serviceType: selectedFilter);
    }
  }

  IconData _getServiceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'ganti oli':
        return Icons.opacity_rounded;
      case 'servis berkala':
        return Icons.build_circle_rounded;
      case 'rem':
        return Icons.do_not_disturb_on_rounded;
      case 'rantai':
        return Icons.link_rounded;
      case 'ban':
        return Icons.adjust_rounded;
      case 'aki':
        return Icons.battery_charging_full_rounded;
      case 'busi':
        return Icons.flash_on_rounded;
      case 'filter udara':
        return Icons.air_rounded;
      default:
        return Icons.handyman_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredListAsync = ref.watch(filteredServiceHistoriesProvider(widget.motorcycleId));
    final selectedFilter = ref.watch(serviceHistoryFilterProvider(widget.motorcycleId));
    final totalCost = ref.watch(filteredTotalCostProvider(widget.motorcycleId));

    final filterOptions = <String>['Semua', ...AppConstants.serviceTypes];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Riwayat Servis & Biaya'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_service_history_fab'),
        onPressed: () => context.push('/motors/${widget.motorcycleId}/services/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catat Servis', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: AppBackground(
        child: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(serviceHistoriesProvider(widget.motorcycleId).notifier).loadServiceHistories(serviceType: selectedFilter);
          },
          child: Column(
            children: <Widget>[
              // Kartu Ringkasan Total Biaya Terfilter sesuai PRD 7 M4
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.vehicleCardGradient,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.peach, width: 1.2),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.peach),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              selectedFilter == null || selectedFilter == 'Semua'
                                  ? 'Total Pengeluaran Servis'
                                  : 'Total Biaya ($selectedFilter)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppFormatters.rupiah(totalCost),
                              key: const Key('total_service_cost_text'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryText,
                                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Bar Horizontal
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  scrollDirection: Axis.horizontal,
                  itemCount: filterOptions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final type = filterOptions[index];
                    final isSelected = (selectedFilter == null && type == 'Semua') ||
                        (selectedFilter == type);

                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          final newFilter = type == 'Semua' ? null : type;
                          ref
                              .read(serviceHistoryFilterProvider(widget.motorcycleId).notifier)
                              .state = newFilter;
                        }
                      },
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceLight,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),

              // Daftar Catatan Riwayat Servis
              Expanded(
                child: filteredListAsync.when(
                  loading: () => LoadingSkeleton.serviceHistoryList(),
                  error: (err, _) => ErrorState(
                    title: 'Gagal Memuat Riwayat',
                    message: err.toString(),
                    onRetry: () => ref
                        .read(serviceHistoriesProvider(widget.motorcycleId).notifier)
                        .loadServiceHistories(serviceType: selectedFilter),
                  ),
                  data: (List<ServiceHistory> list) {
                    if (list.isEmpty) {
                      return EmptyState(
                        key: const Key('empty_service_history_state'),
                        icon: Icons.history_toggle_off_rounded,
                        title: 'Catat Servis Pertama',
                        message: selectedFilter == null || selectedFilter == 'Semua'
                            ? 'Belum ada catatan servis untuk motor ini. Catat servis pertama Anda untuk memantau perawatan berkala dan biaya.'
                            : 'Belum ada riwayat servis kategori "$selectedFilter".',
                        actionLabel: 'Catat Servis Sekarang',
                        onAction: () => context.push('/motors/${widget.motorcycleId}/services/new'),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final icon = _getServiceIcon(item.serviceType);

                        return AnimatedEntrance(
                          index: index,
                          child: Material(
                          color: AppColors.surfaceBright,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => context.push('/services/${item.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.cream,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.peach),
                                    ),
                                    child: Icon(icon, color: AppColors.primary, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                item.serviceType,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              AppFormatters.rupiah(item.cost),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryText,
                                                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: <Widget>[
                                            const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              AppFormatters.dateShort(item.serviceDate),
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.speed_rounded, size: 13, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              AppFormatters.mileage(item.mileage),
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                        if (item.workshopName != null && item.workshopName!.isNotEmpty) ...<Widget>[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: <Widget>[
                                              const Icon(Icons.storefront_rounded, size: 13, color: AppColors.textSecondary),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  item.workshopName!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
