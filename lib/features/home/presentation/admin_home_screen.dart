import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../auth/presentation/auth_state_provider.dart';

/// Model sederhana data mekanik untuk manajemen admin (UC-07)
class AdminMechanicItem {
  final String id;
  final String name;
  final String phone;
  final String workshop;
  final String specialty;
  final String area;
  final bool isApproved;

  const AdminMechanicItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.workshop,
    required this.specialty,
    required this.area,
    this.isApproved = true,
  });

  AdminMechanicItem copyWith({bool? isApproved}) {
    return AdminMechanicItem(
      id: id,
      name: name,
      phone: phone,
      workshop: workshop,
      specialty: specialty,
      area: area,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}

/// Dashboard Khusus Administrator MotoCare (Sesuai UC-07 & Sequence Diagram Data Mekanik)
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  // Simulasi daftar verifikasi mekanik baru (Metode B)
  final List<AdminMechanicItem> _pendingMechanics = <AdminMechanicItem>[
    const AdminMechanicItem(
      id: 'mech-p-01',
      name: 'Rahmat Hidayat',
      phone: '081265443322',
      workshop: 'Bengkel Samudera Pase',
      specialty: 'Mesin 4-Tak & Transmisi CVT',
      area: 'Banda Sakti, Kota Lhokseumawe',
      isApproved: false,
    ),
    const AdminMechanicItem(
      id: 'mech-p-02',
      name: 'Teuku Iskandar',
      phone: '085299881122',
      workshop: 'Karya Motor Panton Labu',
      specialty: 'Kelistrikan & Injeksi ECU',
      area: 'Tanah Jambo Aye, Aceh Utara',
      isApproved: false,
    ),
  ];

  // Daftar mekanik aktif terdaftar (UC-07)
  final List<AdminMechanicItem> _activeMechanics = <AdminMechanicItem>[
    const AdminMechanicItem(
      id: 'mech-a-01',
      name: 'Budi Santoso',
      phone: '081200000001',
      workshop: 'Bengkel Resmi Samudera Motor',
      specialty: 'Servis Ringan & Ganti Ban Darurat',
      area: 'Kota Lhokseumawe & Sekitarnya',
    ),
    const AdminMechanicItem(
      id: 'mech-a-02',
      name: 'Hasan Basri',
      phone: '081200000002',
      workshop: 'Bengkel Maju Bersama Krueng Geukueh',
      specialty: 'Mesin Karbu / Injeksi & Radiator',
      area: 'Dewantara, Aceh Utara',
    ),
    const AdminMechanicItem(
      id: 'mech-a-03',
      name: 'Dedi Kurniawan',
      phone: '081200000003',
      workshop: 'Pos Panggilan Darurat Blang Mangat',
      specialty: 'Tambal Ban Tubeless & Aki',
      area: 'Blang Mangat, Kota Lhokseumawe',
    ),
  ];

  void _approveMechanic(int index) {
    final item = _pendingMechanics[index];
    setState(() {
      _pendingMechanics.removeAt(index);
      _activeMechanics.insert(0, item.copyWith(isApproved: true));
    });
    HapticFeedback.heavyImpact();
    AppToast.showSuccess(context, 'Akun mekanik ${item.name} berhasil disetujui & aktif!');
  }

  void _rejectMechanic(int index) {
    final item = _pendingMechanics[index];
    setState(() {
      _pendingMechanics.removeAt(index);
    });
    AppToast.showError(context, 'Pendaftaran mekanik ${item.name} ditolak.');
  }

  Future<void> _deleteMechanic(int index) async {
    final item = _activeMechanics[index];
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Hapus Data Mekanik',
      message: 'Apakah Anda yakin ingin menghapus mekanik "${item.name}" dari sistem MotoCare?',
      confirmLabel: 'Ya, Hapus',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() {
        _activeMechanics.removeAt(index);
      });
      HapticFeedback.heavyImpact();
      AppToast.showSuccess(context, 'Mekanik ${item.name} berhasil dihapus.');
    }
  }

  void _showAddMechanicDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final workshopCtrl = TextEditingController();
    final specialtyCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: 'Kota Lhokseumawe & Aceh Utara');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Tambah Mekanik Baru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Lengkap Mekanik', hintText: 'Contoh: Rudi Pratama'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor WhatsApp', hintText: '081234567890'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: workshopCtrl,
                decoration: const InputDecoration(labelText: 'Nama Bengkel Induk', hintText: 'Bengkel Samudera'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: specialtyCtrl,
                decoration: const InputDecoration(labelText: 'Spesialisasi Keahlian', hintText: 'Mesin, Ban, Aki'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: areaCtrl,
                decoration: const InputDecoration(labelText: 'Wilayah Layanan'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              setState(() {
                _activeMechanics.insert(
                  0,
                  AdminMechanicItem(
                    id: 'mech-new-${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    workshop: workshopCtrl.text.trim(),
                    specialty: specialtyCtrl.text.trim(),
                    area: areaCtrl.text.trim(),
                  ),
                );
              });
              Navigator.of(ctx).pop();
              AppToast.showSuccess(context, 'Mekanik baru berhasil ditambahkan!');
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.fullName ?? 'Administrator';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              displayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const Text(
              'Panel Administrator • Lhokseumawe & Aceh Utara',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: <Widget>[
            // Banner Wilayah Kontrol
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.peach),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sistem Database Terintegrasi Supabase (Multi-Role RBAC: Admin, Mekanik, User)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metrik Ringkasan Eksekutif (4 Kartu)
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildAdminMetric('Total Mekanik', '75 Akun', '72 Aktif • 3 Pending', Icons.handyman_rounded, AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildAdminMetric('Total Pelanggan', '25 Akun', 'Pengendara Terdaftar', Icons.people_rounded, AppColors.skyBlue),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildAdminMetric('Panggilan Selesai', '14 Kasus', 'Area Lhokseumawe & AU', Icons.task_alt_rounded, AppColors.emerald),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildAdminMetric('Bengkel Rekanan', '6 Terverifikasi', 'Direktori Terdaftar', Icons.storefront_rounded, const Color(0xFFFF9B54)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bagian Verifikasi Akun Mekanik Baru (Metode B)
            Row(
              children: <Widget>[
                const Flexible(
                  child: Text(
                    'Verifikasi Mekanik Baru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                if (_pendingMechanics.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(8)),
                    child: Text('${_pendingMechanics.length}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (_pendingMechanics.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                child: const Center(
                  child: Text('Semua permohonan pendaftaran mekanik telah diverifikasi.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              )
            else
              ...List.generate(_pendingMechanics.length, (index) {
                final item = _pendingMechanics[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.5), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 2,
                        children: <Widget>[
                          Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          const Text('Menunggu Persetujuan', style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${item.workshop} • WA: ${item.phone}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text('Keahlian: ${item.specialty}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                      const SizedBox(height: 2),
                      Text('Wilayah: ${item.area}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _rejectMechanic(index),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                              child: const Text('Tolak'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => _approveMechanic(index),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, foregroundColor: Colors.white),
                              icon: const Icon(Icons.check_circle_rounded, size: 16),
                              label: const Text('Setujui Akun'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 20),

            // Kelola Data Mekanik Terdaftar (CRUD UC-07)
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Data Mekanik Terdaftar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddMechanicDialog,
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text('Tambah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ...List.generate(_activeMechanics.length, (index) {
              final item = _activeMechanics[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBright,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.handyman_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('${item.workshop} • ${item.phone}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(item.specialty, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      tooltip: 'Hapus Data Mekanik',
                      onPressed: () => _deleteMechanic(index),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppTokens.tabContentBottomPadding),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildAdminMetric(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

