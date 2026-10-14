# PRD MotoCare untuk Agent AI (Spesifikasi Eksekusi)

Oct 14, 2026 · @Abrar Astafaraiz

## 1. Cara Memakai Dokumen Ini dan Aturan Kerja Agent

Dokumen ini adalah instruksi eksekusi untuk agent AI (misalnya Claude Code) yang membangun aplikasi MotoCare dari nol. Dokumen pendamping, PRD MotoCare (Versi Disempurnakan), menjelaskan alasan produk; bila keduanya berbeda, dokumen ini yang berlaku untuk implementasi.

### 1.1 Peran dan hasil akhir

Anda adalah engineer Flutter senior. Hasil akhir: repositori Flutter yang dapat dibangun (`flutter build apk`), lulus `flutter analyze` dan `flutter test`, menjalankan seluruh fitur Must pada bagian 7, dan terhubung ke backend Supabase atau berjalan dengan repository mock berlabel Demo.

### 1.2 Aturan kerja (wajib)

1. Kerjakan milestone secara berurutan (M0 sampai M8). Jangan memulai milestone berikutnya sebelum kriteria selesai milestone saat ini terpenuhi dan perintah verifikasinya lulus.
2. Satu milestone = satu cabang Git dan satu rangkaian commit kecil dengan pesan format `feat(modul): ringkasan` atau `fix(modul): ringkasan`.
3. Jalankan `flutter analyze` dan `flutter test` sebelum setiap commit; perbaiki semua error dan warning.
4. Ikuti keputusan teknis pada bagian 2; jangan mengganti paket atau arsitektur tanpa persetujuan.
5. Tulis test bersamaan dengan fitur (bagian 9), bukan di akhir.
6. Jika spesifikasi ambigu atau bertentangan, berhenti dan ajukan pertanyaan singkat dengan opsi yang Anda usulkan (format di bagian 10.3); jangan menebak.
7. Setelah tiap milestone, tulis laporan singkat sesuai format bagian 10.2.

### 1.3 Larangan

- Jangan mengarang data: tidak ada bengkel, rating, jarak, atau ketersediaan mekanik palsu yang tampil sebagai nyata. Semua data contoh wajib berlabel "Demo/Simulasi" di UI dan di nama berkas seed.
- Jangan menaruh secret, service role key, atau kredensial di kode atau repositori. Gunakan `--dart-define` atau berkas `.env` yang masuk `.gitignore`; sediakan `.env.example`.
- Jangan menyimpan password atau token di `SharedPreferences` biasa; pakai penyimpanan yang disediakan `supabase_flutter` atau `flutter_secure_storage`.
- Jangan mengandalkan UI untuk otorisasi; semua pembatasan akses ditegakkan di database lewat RLS (bagian 5).
- Jangan menambah fitur di luar daftar Must tanpa diminta. Fitur Should dan Could hanya dikerjakan setelah semua Must lulus dan diminta eksplisit.
- Jangan menahan pengguna dengan delay buatan; hanya splash screen yang berdurasi 3 sampai 5 detik.
- Jangan menyatakan fitur atau tes lulus tanpa menjalankannya; laporkan hasil nyata `Pass`, `Fail`, atau `Blocked`.
- Jangan menulis komentar atau teks UI berbahasa selain Indonesia untuk teks yang tampil ke pengguna; nama kode, class, dan commit boleh berbahasa Inggris.

## 2. Konteks Produk dan Keputusan Teknis Final

MotoCare adalah aplikasi berbahasa Indonesia untuk pemilik motor di Kota Lhokseumawe dan Kabupaten Aceh Utara: mencatat motor, kilometer, riwayat servis dan biaya; mengingatkan servis berdasarkan tanggal atau kilometer; menampilkan tutorial, daftar bengkel terverifikasi; dan menerima permintaan bantuan mekanik beserta statusnya.

### 2.1 Keputusan teknis (tidak boleh diubah tanpa persetujuan)

| Aspek | Keputusan | Catatan |
| --- | --- | --- |
| Platform | Android dan Web (untuk running di Chrome) | `minSdk` 26 untuk Android |
| Framework | Flutter stable terbaru, Dart 3 | Null safety penuh |
| State management | `flutter_riverpod` | Provider dan notifier per fitur |
| Navigasi | `go_router` | Rute di bagian 8; guard autentikasi |
| Backend | Supabase (Auth, PostgreSQL, RLS) lewat `supabase_flutter` | Tanpa backend kedua |
| Pola data | Repository berantarmuka (`abstract class`) dengan implementasi `Supabase*Repository` dan `Mock*Repository` | Mock berlabel Demo untuk pengembangan dan fallback |
| Peta | Tidak ada peta tertanam; buka aplikasi peta eksternal lewat `url_launcher` (geo URI atau URL Google Maps) | Fallback: salin alamat |
| Lokasi | `geolocator` dengan izin saat dipakai; input alamat manual selalu tersedia |  |
| Tutorial | Tautan YouTube dibuka lewat `url_launcher`; thumbnail dari URL yang tersimpan | Embed hanya bila diminta kemudian |
| Notifikasi | Pusat notifikasi in-app (tabel `notifications`) wajib; pengingat lokal dengan `flutter_local_notifications` dan `timezone` | Push FCM tidak dikerjakan (Should) |
| Format | `intl` untuk tanggal dan mata uang (`id_ID`, Rp) |  |
| Font | Plus Jakarta Sans dibundel di `assets/fonts/` | Fallback sans-serif sistem |
| Pengujian | `flutter_test`, `mocktail` | Integration test hanya bila diminta |
| Lint | `flutter_lints` dengan aturan ketat di `analysis_options.yaml` |  |

### 2.2 Cakupan MVP (Must) yang harus selesai

Akun dan profil; CRUD motor dan pembaruan kilometer; catat dan lihat riwayat servis dengan biaya; pengingat tanggal dan kilometer dengan status; pusat notifikasi in-app; pencarian tutorial; daftar dan detail bengkel di wilayah layanan; permintaan bantuan mekanik dengan status dan pembatalan; state loading, kosong, error, dan konfirmasi di semua layar; keamanan dasar lewat RLS.

### 2.3 Wilayah layanan

Bengkel dan pencarian dibatasi pada dua nilai `city_or_regency`: `Kota Lhokseumawe` dan `Kabupaten Aceh Utara`.

## 3. Struktur Repo, Konvensi Kode, dan Perintah Standar

```text
motocare/
  lib/
    main.dart
    app.dart                    # MaterialApp.router, tema, locale id_ID
    core/
      config/                   # env, konstanta (ambang km, timeout 15 menit)
      theme/                    # tokens, app_theme.dart, motion.dart
      router/                   # app_router.dart, guard auth
      widgets/                  # komponen reusable (bagian 4.3)
      utils/                    # validators.dart, formatters.dart, result.dart
      errors/                   # app_exception.dart, pesan error ramah
    features/
      auth/ (data, domain, presentation)
      motorcycles/
      service_history/
      reminders/
      notifications/
      tutorials/
      workshops/
      help_requests/
      profile/
      home/
    data_mock/                  # seed Demo/Simulasi
  assets/fonts/  assets/images/
  supabase/
    migrations/                 # SQL bagian 5
    seed_demo.sql               # data contoh berlabel Demo/Simulasi
  test/                         # cerminan struktur lib/
  .env.example
  analysis_options.yaml
  README.md
```

## 4. Design Tokens dan Aturan UI

### 4.1 Token warna

| Token | Hex | Pemakaian |
| --- | --- | --- |
| `background` | `#FFFFFF` | Latar layar |
| `cream` | `#FFF0E3` | Panel lembut |
| `peach` | `#FFD0A6` | Kartu dan sorotan |
| `orangeSoft` | `#FF9B54` | Aksen dan gradasi |
| `primary` | `#F47721` | Isi tombol utama, elemen aktif, ikon aktif |
| `onPrimary` | `#1F1F1F` | Label dan ikon di atas `primary` |
| `primaryText` | `#B34D00` | Teks atau tautan oranye di atas putih |
| `textPrimary` | `#343434` | Teks utama |
| `textSecondary` | `#6C625B` | Teks sekunder |
| `success` | `#1B7F3B` | Status sukses |
| `error` | `#C62828` | Error dan servis terlambat |
| `warning` | `#8A5A00` | Status mendekati jatuh tempo |

Gradasi header: `#FFF7F0`, `#FFE2C7`, `#FFB875` (atas ke bawah).

### 4.2 Tipografi, jarak, bentuk

- Font: Plus Jakarta Sans (Regular 400, Medium 500, SemiBold 600, Bold 700, ExtraBold 800)
- Display: 28 sp, ExtraBold
- Judul layar: 22 sp, Bold
- Subjudul: 16 sp, SemiBold
- Isi: 14 sp, Regular, tinggi baris 1,4
- Label dan tombol: 14 sp, SemiBold
- Jarak: Kelipatan 4: 4, 8, 12, 16, 24, 32
- Radius: Kartu 16, tombol 14, input 12, chip 999
- Elevasi: Kartu 0 sampai 2 (utamakan border `#F0E3D6` tipis)
- Target sentuh: Minimal 48 x 48 dp

### 4.3 Komponen reusable wajib (di `core/widgets/`)
`PrimaryButton`, `SecondaryButton`, `AppIconButton`, `AppTextField`, `MotorcycleCard`, `ServiceReminderCard`, `WorkshopCard`, `TutorialCard`, `StatusChip`, `LoadingSkeleton`, `EmptyState`, `ErrorState`, `AppToast`, `ConfirmationDialog`, `NotificationTile`, dan `AppBottomNav`.

### 4.5 Motion
- Splash: Logo fade dan scale ringan, ikon motor bergerak halus (3 sampai 5 detik total)
- Tombol ditekan: Scale atau opacity (100 sampai 180 ms)
- Kartu masuk: Fade dan slide (250 sampai 400 ms)
- Dialog: Fade dan scale (180 sampai 280 ms)
- Sukses: Centang dan efek ringan (400 sampai 800 ms)
- Pengingat penting: Pulse lembut, tidak berulang terus (500 sampai 900 ms)

## 5. Skema Database, RLS, dan Data Seed
Tercakup dalam `supabase/migrations/` dan `supabase/seed_demo.sql`.

## 6. Aturan Bisnis yang Presisi
- `validateMileage(int current, String rawInput)`
- `computeReminderStatus`
- Templat pengingat dan jadwal berikutnya
- Permintaan bantuan mekanik
- Validasi isian
