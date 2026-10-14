import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/app.dart';

void main() {
  testWidgets('Aplikasi MotoCare dapat dimulai dan menampilkan Splash Screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MotoCareApp(),
      ),
    );

    // Verifikasi teks merek dan slogan muncul
    expect(find.text('MOTO'), findsOneWidget);
    expect(find.text('CARE'), findsOneWidget);
    expect(find.text('Rawat Motor Anda Tanpa Cemas'), findsOneWidget);

    // Majukan waktu hingga inisialisasi (1200ms) dan durasi minimum splash (3000ms) selesai
    await tester.pump(const Duration(milliseconds: 3200));
    await tester.pump();

    // Verifikasi aplikasi telah berpindah ke halaman login
    expect(find.text('Masuk ke MotoCare'), findsOneWidget);
  });
}
