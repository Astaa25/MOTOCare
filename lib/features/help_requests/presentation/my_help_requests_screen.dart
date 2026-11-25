import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/service_request.dart';
import 'help_requests_providers.dart';

/// Layar Daftar Permintaan Panggilan Bantuan Montir sesuai PRD Bagian 7 (M7)
class MyHelpRequestsScreen extends ConsumerWidget {
  const MyHelpRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myHelpRequestsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Aktivitas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.deepTeal,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          if (AppEnv.showDemoFeatures)
            Container(
              margin: const EdgeInsets.only(right: 8),
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.deepTeal),
            tooltip: 'Segarkan',
            onPressed: () => ref.invalidate(myHelpRequestsProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.action,
          onRefresh: () async {
            ref.invalidate(myHelpRequestsProvider);
          },
          child: requestsAsync.when(
            loading: () => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  const LoadingSkeleton(height: 110, borderRadius: 16),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorState(
                  title: 'Gagal Memuat Riwayat Panggilan',
                  message: error.toString(),
                  onRetry: () => ref.invalidate(myHelpRequestsProvider),
                ),
              ),
            ),
            data: (List<ServiceRequest> requests) {
              if (requests.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: <Widget>[
                    const SizedBox(height: 48),
                    EmptyState(
                      key: const Key('empty_help_requests_state'),
                      icon: Icons.support_agent_rounded,
                      title: 'Belum Ada Panggilan Montir',
                      message:
                          'Butuh bantuan montir saat motor Anda mogok atau bermasalah di jalan? Anda dapat memanggil montir terdekat ke lokasi Anda kapan saja.',
                      actionLabel: 'Panggil Montir Sekarang',
                      onAction: () => context.push('/help/new'),
                    ),
                  ],
                );
              }

              final activeRequests = requests.where((r) => r.status.isActive).toList();
              final pastRequests = requests.where((r) => !r.status.isActive).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, AppTokens.tabContentBottomPadding),
                children: <Widget>[
                  const Text(
                    'Bantuan dan perawatan, satu tempat.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bagian Permintaan Berlangsung (Figma 02 Aktivitas)
                  if (activeRequests.isNotEmpty) ...<Widget>[
                    const Text(
                      'SEDANG BERLANGSUNG',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...activeRequests.map((req) => _buildActiveHeroCard(context, req)),
                    const SizedBox(height: 20),
                  ],

                  // Bagian Aktivitas Sebelumnya
                  if (pastRequests.isNotEmpty) ...<Widget>[
                    const Text(
                      'Aktivitas sebelumnya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepTeal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...pastRequests.map((req) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _HelpRequestCard(
                            request: req,
                            onTap: () => context.push('/help/${req.id}'),
                          ),
                        )),
                  ] else if (activeRequests.isEmpty) ...<Widget>[
                    const Text(
                      'Aktivitas sebelumnya',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepTeal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum ada aktivitas terdahulu.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.background,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: PrimaryButton(
          key: const Key('new_help_request_button'),
          label: 'Panggil Montir Baru',
          icon: Icons.add_rounded,
          onPressed: () => context.push('/help/new'),
        ),
      ),
    );
  }

  Widget _buildActiveHeroCard(BuildContext context, ServiceRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.softPeach,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.action.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              req.status.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.deepTeal,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Montir menuju lokasimu',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.deepTeal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            req.issueCategory,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.deepTeal,
            ),
          ),
          if (req.motorcycleName != null && req.motorcycleName!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              req.motorcycleName!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 2),
          Text(
            req.addressText,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/help/${req.id}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.action,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                'Lacak montir',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpRequestCard extends StatelessWidget {
  final ServiceRequest request;
  final VoidCallback onTap;

  const _HelpRequestCard({
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = request.status;

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
            border: Border.all(
              color: const Color(0xFFF0EAE1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Ikon dalam kontainer Soft Peach (Figma 02 Aktivitas)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.softPeach,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  status.icon,
                  color: AppColors.deepTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Rincian Aktivitas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            request.issueCategory,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepTeal,
                            ),
                          ),
                        ),
                        StatusChip(
                          label: status.label,
                          icon: status.icon,
                          backgroundColor: status.backgroundColor,
                          textColor: status.textColor,
                          borderColor: status.borderColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppFormatters.formatDate(request.createdAt)} • ${request.addressText}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (request.motorcycleName != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        request.motorcycleName!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.action,
                        ),
                      ),
                    ],
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
        ),
      ),
    );
  }
}
