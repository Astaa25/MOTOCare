import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/theme/app_theme.dart';
import 'package:motocare/core/widgets/app_dialogs.dart';
import 'package:motocare/core/widgets/empty_state.dart';
import 'package:motocare/core/widgets/error_state.dart';
import 'package:motocare/core/widgets/primary_button.dart';
import 'package:motocare/core/widgets/status_chip.dart';

void main() {
  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('Widget Tests Komponen Core MotoCare (M1)', () {
    testWidgets('ErrorState memuat pesan, judul, dan memunculkan tombol Coba lagi',
        (WidgetTester tester) async {
      bool retryClicked = false;

      await tester.pumpWidget(
        wrapWithTheme(
          ErrorState(
            message: 'Gagal memuat data dari server.',
            onRetry: () {
              retryClicked = true;
            },
          ),
        ),
      );

      // Verifikasi judul dan pesan error muncul
      expect(find.text('Terjadi Kendala'), findsOneWidget);
      expect(find.text('Gagal memuat data dari server.'), findsOneWidget);

      // Verifikasi tombol Coba lagi ada
      final retryBtnFinder = find.byKey(const Key('error_state_retry_button'));
      expect(retryBtnFinder, findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);

      // Ketuk tombol Coba lagi dan pastikan callback terpanggil
      await tester.tap(retryBtnFinder);
      await tester.pump();
      expect(retryClicked, isTrue);
    });

    testWidgets('EmptyState memuat teks judul, pesan, dan tombol aksi',
        (WidgetTester tester) async {
      bool actionClicked = false;

      await tester.pumpWidget(
        wrapWithTheme(
          EmptyState(
            icon: Icons.two_wheeler_outlined,
            title: 'Belum Ada Motor',
            message: 'Silakan tambahkan motor pertama Anda.',
            actionLabel: 'Tambah Motor',
            onAction: () {
              actionClicked = true;
            },
          ),
        ),
      );

      // Verifikasi judul dan deskripsi
      expect(find.text('Belum Ada Motor'), findsOneWidget);
      expect(find.text('Silakan tambahkan motor pertama Anda.'), findsOneWidget);

      // Verifikasi tombol aksi
      expect(find.text('Tambah Motor'), findsOneWidget);
      await tester.tap(find.text('Tambah Motor'));
      await tester.pump();
      expect(actionClicked, isTrue);
    });

    testWidgets('StatusChip memuat teks dan ikon secara konsisten',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          Column(
            children: <Widget>[
              StatusChip.scheduled(),
              StatusChip.near(),
              StatusChip.overdue(),
              StatusChip.completed(),
              StatusChip.demo(),
            ],
          ),
        ),
      );

      // 1. Scheduled: teks "Terjadwal" & ikon calendar
      expect(find.text('Terjadwal'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);

      // 2. Near: teks "Segera servis" & ikon warning
      expect(find.text('Segera servis'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // 3. Overdue: teks "Terlambat" & ikon error
      expect(find.text('Terlambat'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      // 4. Completed: teks "Selesai" & ikon check
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

      // 5. Demo: teks "Demo/Simulasi" & ikon science
      expect(find.text('Demo/Simulasi'), findsOneWidget);
      expect(find.byIcon(Icons.science_outlined), findsOneWidget);
    });

    testWidgets('PrimaryButton menampilkan loading spinner dan mencegah tap saat loading',
        (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        wrapWithTheme(
          PrimaryButton(
            label: 'Simpan Data',
            isLoading: true,
            onPressed: () {
              tapCount++;
            },
          ),
        ),
      );

      // Saat loading, teks disembunyikan dan spinner muncul
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Simpan Data'), findsNothing);

      // Tap tidak memicu callback
      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();
      expect(tapCount, 0);
    });

    testWidgets('ConfirmationDialog menampilkan teks dan memproses aksi konfirmasi',
        (WidgetTester tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ConfirmationDialog.show(
                      context,
                      title: 'Hapus Riwayat Servis?',
                      message: 'Data yang dihapus tidak dapat dipulihkan.',
                      isDestructive: true,
                    ).then((value) {
                      if (value == true) confirmed = true;
                    });
                  },
                  child: const Text('Buka Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Buka dialog
      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      // Verifikasi konten dialog
      expect(find.text('Hapus Riwayat Servis?'), findsOneWidget);
      expect(find.text('Data yang dihapus tidak dapat dipulihkan.'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Ya, Lanjutkan'), findsOneWidget);

      // Ketuk Ya, Lanjutkan
      await tester.tap(find.byKey(const Key('confirmation_dialog_confirm_button')));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });
  });
}
