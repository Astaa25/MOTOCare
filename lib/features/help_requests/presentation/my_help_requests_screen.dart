import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bantuan Montir'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: () => ref.invalidate(myHelpRequestsProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
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

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return _HelpRequestCard(
                    request: req,
                    onTap: () => context.push('/help/${req.id}'),
                  );
                },
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
              color: status.isActive ? status.borderColor : AppColors.border,
              width: status.isActive ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Baris Status & Tanggal
              Row(
                children: <Widget>[
                  StatusChip(
                    label: status.label,
                    icon: status.icon,
                    backgroundColor: status.backgroundColor,
                    textColor: status.textColor,
                    borderColor: status.borderColor,
                  ),
                  const Spacer(),
                  Text(
                    AppFormatters.formatDate(request.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Kategori Masalah
              Text(
                request.issueCategory,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),

              // Deskripsi Singkat
              Text(
                request.issueDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),

              // Alamat & Motor
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.addressText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (request.motorcycleName != null) ...<Widget>[
                    const SizedBox(width: 8),
                    Text(
                      request.motorcycleName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
