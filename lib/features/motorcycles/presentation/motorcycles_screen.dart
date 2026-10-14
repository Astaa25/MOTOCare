import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/motorcycle_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/motorcycle.dart';
import 'motorcycle_providers.dart';

/// Layar daftar sepeda motor pengguna sesuai PRD M3 & Rute `/motors`
class MotorcyclesScreen extends ConsumerWidget {
  const MotorcyclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motorcyclesAsync = ref.watch(motorcyclesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Motor Saya'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan data',
            onPressed: () => ref.read(motorcyclesProvider.notifier).loadMotorcycles(),
          ),
        ],
      ),
      body: SafeArea(
        child: motorcyclesAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: const <Widget>[
              LoadingSkeleton(height: 180, borderRadius: 16),
              SizedBox(height: 16),
              LoadingSkeleton(height: 180, borderRadius: 16),
            ],
          ),
          error: (error, _) => ErrorState(
            title: 'Gagal Memuat Data Motor',
            message: error.toString(),
            onRetry: () => ref.read(motorcyclesProvider.notifier).loadMotorcycles(),
          ),
          data: (List<Motorcycle> motors) {
            if (motors.isEmpty) {
              return EmptyState(
                key: const Key('empty_motorcycles_state'),
                icon: Icons.two_wheeler_rounded,
                title: 'Belum Ada Sepeda Motor',
                message:
                    'Tambahkan motor Anda untuk mulai memantau servis berkala, pengingat kilometer, dan memanggil bantuan montir.',
                actionLabel: 'Tambah Motor Sekarang',
                onAction: () => context.push('/motors/new'),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(motorcyclesProvider.notifier).loadMotorcycles(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: motors.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final motor = motors[index];
                  return MotorcycleCard(
                    key: Key('motor_card_${motor.id}'),
                    brand: motor.brand,
                    model: motor.model,
                    productionYear: motor.productionYear,
                    licensePlate: motor.licensePlate,
                    currentMileage: motor.currentMileage,
                    mileageUpdatedAt: motor.mileageUpdatedAt,
                    statusBadge: motor.isMileageStale
                        ? const StatusChip(
                            label: 'KM Perlu Update',
                            icon: Icons.history_toggle_off_rounded,
                            textColor: AppColors.warning,
                            backgroundColor: Color(0xFFFFF4E5),
                            borderColor: AppColors.peach,
                          )
                        : null,
                    onTap: () => context.push('/motors/${motor.id}'),
                    onUpdateMileage: () => context.push('/motors/${motor.id}/mileage'),
                    onViewServices: () => context.push('/motors/${motor.id}/services'),
                    onViewReminders: () => context.push('/motors/${motor.id}/reminders'),
                  );
                },
              ),
            );
          },
        ),
      ),
      bottomSheet: Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(16),
        child: PrimaryButton(
          key: const Key('add_motorcycle_fab'),
          label: 'Tambah Motor Baru',
          icon: Icons.add_rounded,
          onPressed: () => context.push('/motors/new'),
        ),
      ),
    );
  }
}
