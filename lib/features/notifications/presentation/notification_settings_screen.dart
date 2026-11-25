import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/primary_button.dart';

/// State Provider untuk Pengaturan Preferensi Notifikasi (Figma 06.06)
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(
  (ref) => NotificationSettingsNotifier(),
);

class NotificationSettingsState {
  final bool helpStatus;
  final bool serviceReminders;
  final bool mileageUpdates;

  const NotificationSettingsState({
    this.helpStatus = true,
    this.serviceReminders = true,
    this.mileageUpdates = false,
  });

  NotificationSettingsState copyWith({
    bool? helpStatus,
    bool? serviceReminders,
    bool? mileageUpdates,
  }) {
    return NotificationSettingsState(
      helpStatus: helpStatus ?? this.helpStatus,
      serviceReminders: serviceReminders ?? this.serviceReminders,
      mileageUpdates: mileageUpdates ?? this.mileageUpdates,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettingsState> {
  NotificationSettingsNotifier() : super(const NotificationSettingsState());

  void setHelpStatus(bool val) {
    state = state.copyWith(helpStatus: val);
  }

  void setServiceReminders(bool val) {
    state = state.copyWith(serviceReminders: val);
  }

  void setMileageUpdates(bool val) {
    state = state.copyWith(mileageUpdates: val);
  }
}

/// Layar Pengaturan Preferensi Notifikasi sesuai Figma 06.06
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: <Widget>[
                    const Text(
                      'Pilih yang ingin kamu terima.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 1. Status Bantuan
                    _buildToggleRow(
                      title: 'Status bantuan',
                      subtitle: 'Diterima, perjalanan, dan layanan selesai.',
                      value: settings.helpStatus,
                      onChanged: notifier.setHelpStatus,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),

                    // 2. Pengingat Servis
                    _buildToggleRow(
                      title: 'Pengingat servis',
                      subtitle: 'Jadwal perawatan motor yang kamu atur.',
                      value: settings.serviceReminders,
                      onChanged: notifier.setServiceReminders,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),

                    // 3. Pembaruan Kilometer
                    _buildToggleRow(
                      title: 'Pembaruan kilometer',
                      subtitle: 'Pengingat untuk mencatat odometer.',
                      value: settings.mileageUpdates,
                      onChanged: notifier.setMileageUpdates,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 28),

                    // Notice Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.softMint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Izin notifikasi perangkat tetap diperlukan. Jika pesan tidak muncul, periksa pengaturan MotoCare di perangkatmu.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.deepTeal,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tombol Simpan Preferensi di bawah
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                color: Colors.transparent,
                child: PrimaryButton(
                  key: const Key('save_notification_settings_button'),
                  label: 'Simpan preferensi',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preferensi notifikasi berhasil disimpan.'),
                        backgroundColor: AppColors.deepTeal,
                      ),
                    );
                    Navigator.of(context).maybePop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepTeal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(
          value: value,
          activeTrackColor: AppColors.deepTeal,
          activeThumbColor: Colors.white,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
