import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_bottom_nav.dart';
import 'app_dialogs.dart';
import 'app_icon_button.dart';
import 'app_text_field.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'loading_skeleton.dart';
import 'motorcycle_card.dart';
import 'notification_tile.dart';
import 'primary_button.dart';
import 'secondary_button.dart';
import 'service_reminder_card.dart';
import 'status_chip.dart';
import 'tutorial_card.dart';
import 'workshop_card.dart';

/// Halaman katalog komponen visual untuk pengujian debug sesuai PRD 7 M1
class ComponentCatalogScreen extends StatefulWidget {
  const ComponentCatalogScreen({super.key});

  @override
  State<ComponentCatalogScreen> createState() => _ComponentCatalogScreenState();
}

class _ComponentCatalogScreenState extends State<ComponentCatalogScreen> {
  int _navIndex = 0;
  bool _btnLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Komponen UI MotoCare'),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          _buildSectionTitle('1. Tombol (Buttons)'),
          PrimaryButton(
            label: 'Primary Button Normal',
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Primary Button Loading',
            isLoading: _btnLoading,
            onPressed: () {
              setState(() => _btnLoading = !_btnLoading);
            },
          ),
          const SizedBox(height: 12),
          const PrimaryButton(
            label: 'Primary Button Dinonaktifkan',
            onPressed: null,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Secondary Button Normal',
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              AppIconButton(
                icon: Icons.notifications_outlined,
                semanticLabel: 'Notifikasi',
                onPressed: () {},
                backgroundColor: AppColors.cream,
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: 12),
              AppIconButton(
                icon: Icons.settings_outlined,
                semanticLabel: 'Pengaturan',
                onPressed: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('2. Input Teks (Form Field)'),
          const AppTextField(
            label: 'Email Pengguna',
            hint: 'nama@domain.com',
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: 12),
          const AppTextField(
            label: 'Kata Sandi',
            hint: 'Minimal 8 karakter',
            isPassword: true,
            prefixIcon: Icons.lock_outline,
          ),
          const SizedBox(height: 12),
          const AppTextField(
            label: 'Input dengan Error',
            hint: 'Isian salah',
            errorText: 'Format email tidak valid',
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('3. Status Chips'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              StatusChip.scheduled(),
              StatusChip.near(),
              StatusChip.overdue(),
              StatusChip.completed(),
              StatusChip.demo(),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('4. Shimmer Loading Skeleton'),
          LoadingSkeleton.cardList(count: 2),

          const SizedBox(height: 24),
          _buildSectionTitle('5. Dialog & Toast Feedbacks'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  ConfirmationDialog.show(
                    context,
                    title: 'Hapus Motor?',
                    message: 'Riwayat servis dan pengingat terkait akan ikut terhapus.',
                    isDestructive: true,
                  );
                },
                child: const Text('Dialog Hapus (Destructive)'),
              ),
              ElevatedButton(
                onPressed: () {
                  SuccessDialog.show(
                    context,
                    title: 'Servis Tercatat!',
                    message: 'Pengingat servis berikutnya telah otomatis dibuat.',
                  );
                },
                child: const Text('Dialog Sukses'),
              ),
              ElevatedButton(
                onPressed: () {
                  AppToast.showSuccess(context, 'Data motor berhasil disimpan');
                },
                child: const Text('Toast Sukses'),
              ),
              ElevatedButton(
                onPressed: () {
                  AppToast.showError(context, 'Gagal terhubung ke jaringan');
                },
                child: const Text('Toast Error'),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('6. Motorcycle Card'),
          MotorcycleCard(
            brand: 'Honda',
            model: 'Vario 160 ABS',
            productionYear: 2023,
            licensePlate: 'BL 4567 AA',
            currentMileage: 12500,
            mileageUpdatedAt: DateTime.now().subtract(const Duration(days: 5)),
            onUpdateMileage: () {},
            onViewServices: () {},
            onViewReminders: () {},
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('7. Service Reminder Card'),
          ServiceReminderCard(
            title: 'Ganti Oli Mesin',
            motorcycleName: 'Honda Vario 160',
            reminderDate: DateTime.now().add(const Duration(days: 3)),
            targetMileage: 13000,
            status: 'near',
            onComplete: () {},
            onRecordService: () {},
          ),
          const SizedBox(height: 12),
          ServiceReminderCard(
            title: 'Ganti Busi & Filter',
            reminderDate: DateTime.now().subtract(const Duration(days: 2)),
            targetMileage: 12000,
            status: 'overdue',
            onComplete: () {},
            onRecordService: () {},
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('8. Workshop Card'),
          WorkshopCard(
            name: 'Bengkel Resmi Sejahtera Motor',
            address: 'Jl. Merdeka No. 45, Simpang Empat',
            cityOrRegency: 'Kota Lhokseumawe',
            openingHours: '08:00 - 17:00 WIB',
            phone: '081234567890',
            services: const <String>['Servis Rutin', 'Ganti Oli', 'Tune Up'],
            isDemo: false,
            distanceKm: 2.4,
            onOpenMap: () {},
            onRequestHelp: () {},
          ),
          const SizedBox(height: 12),
          WorkshopCard(
            name: '[Demo] Bengkel Cepat Simulasi',
            address: 'Jl. Samudera Pasai No. 12',
            cityOrRegency: 'Kabupaten Aceh Utara',
            services: const <String>['Darurat 24 Jam', 'Tambal Ban'],
            isDemo: true,
            onOpenMap: () {},
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('9. Tutorial Card'),
          TutorialCard(
            title: 'Cara Mengganti Oli Mesin Motor Matic Sendiri di Rumah',
            topic: 'Ganti Oli',
            description: 'Panduan lengkap alat dan langkah pengurasan oli mesin dengan benar dan aman.',
            onWatchYouTube: () {},
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('10. Notification Tile'),
          NotificationTile(
            title: 'Waktunya Ganti Oli Mesin',
            body: 'Motor Honda Vario Anda mendekati batas 13.000 km.',
            type: 'reminder',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            onTap: () {},
          ),
          NotificationTile(
            title: 'Mekanik Menuju Lokasi',
            body: 'Mekanik Budi sedang dalam perjalanan ke alamat Anda.',
            type: 'request_status',
            isRead: true,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            onTap: () {},
          ),

          const SizedBox(height: 24),
          _buildSectionTitle('11. Empty State & Error State'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: EmptyState(
              icon: Icons.two_wheeler_outlined,
              title: 'Belum Ada Sepeda Motor',
              message: 'Daftarkan motor Anda untuk mulai memantau jadwal servis dan jarak tempuh berkala.',
              actionLabel: 'Tambah Motor Pertama',
              onAction: () {},
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ErrorState(
              message: 'Gagal memuat daftar bengkel. Periksa koneksi internet Anda.',
              onRetry: () {},
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}
