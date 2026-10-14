# MotoCare - Aplikasi Perawatan Motor

MotoCare adalah aplikasi mobile (Android) berbahasa Indonesia untuk pemilik sepeda motor di Kota Lhokseumawe dan Kabupaten Aceh Utara. Aplikasi ini membantu mencatat motor, riwayat servis dan biaya, pengingat servis otomatis berbasis tanggal dan kilometer, tutorial perawatan mandiri, direktori bengkel terverifikasi, serta sistem permintaan bantuan mekanik darurat.

---

## 🚀 Fitur Utama (MVP)

1. **Manajemen Motor Saya**:
   - Pendaftaran sepeda motor (Merek, Model, Tahun Pembuatan, Nomor Polisi, Kilometer Terkini).
   - Validasi selisih kilometer cerdas (konfirmasi jika kilometer turun / koreksi) sesuai aturan bisnis PRD 6.2.
   - Peringatan pembaruan kilometer jika belum diperbarui lebih dari 30 hari (*mileage stale*).
2. **Riwayat Servis & Pencatatan Biaya**:
   - Catat tanggal servis, kilometer, rincian tindakan servis, dan biaya dalam Rupiah.
   - Pembaruan otomatis kilometer sepeda motor saat pencatatan servis baru disimpan.
   - Filter riwayat servis berdasarkan kategori (Rutin, Perbaikan, Darurat) dan perhitungan total pengeluaran.
3. **Pengingat Perawatan Pintar**:
   - Pengingat berbasis tanggal kalender atau ambang kilometer.
   - Penentuan status otomatis: *Overdue* (Merah), *Segera Servis* (Oranye), *Terjadwal* (Abu-abu), *Selesai* (Hijau).
   - Templat servis bawaan pabrikan (Ganti Oli Mesin, Servis CVT, Busi, Kampas Rem, Radiator, Gir & Rantai).
4. **Pusat Notifikasi In-App**:
   - Notifikasi otomatis saat status pengingat atau permintaan mekanik berubah.
   - Notifikasi lokal di perangkat menggunakan `flutter_local_notifications` & `timezone`.
5. **Katalog Bengkel Terverifikasi**:
   - Direktori bengkel resmi & tepercaya di wilayah layanan permanen (Kota Lhokseumawe & Kab. Aceh Utara).
   - Akses rute via aplikasi peta eksternal dan salin alamat/kontak langsung.
6. **Tutorial Perawatan Mandiri**:
   - Video edukasi perawatan motor mandiri terkurasi berdasarkan topik.
   - Integrasi tautan YouTube via `url_launcher` dengan opsi salin tautan video (*fallback*).
7. **Sistem Bantuan Mekanik & Darurat**:
   - Panggilan montir datang ke lokasi dengan pilihan deteksi koordinat GPS (`geolocator`) atau alamat manual.
   - Perlindungan anti *double-submit* dan penegakan aturan *single active request*.
   - Hitung mundur kedaluwarsa 15 menit dengan opsi alternatif kontak darurat saat kedaluwarsa.

---

## 🛠️ Persyaratan Sistem & Tech Stack

- **Platform**: Android (minSdk 26, targetSdk 34)
- **Framework**: Flutter (Channel stable, Dart 3)
- **State Management**: `flutter_riverpod` 2.6.x
- **Navigasi**: `go_router` 14.8.x dengan auth guard
- **Desain & Tema**: Design tokens MotoCare (Sleek Warm Coral `#FF5733`, Navy Charcoal `#2D3142`, Cream `#FFF9F5`)
- **Tipografi**: Plus Jakarta Sans (dibundel di `assets/fonts/`)
- **Backend**: Supabase (Auth, PostgreSQL, Row Level Security, RPC Functions)
- **Pengujian**: `flutter_test`, `mocktail`

---

## 💻 Cara Menjalankan Aplikasi

Aplikasi MotoCare dapat dijalankan dalam dua mode:

### 1. Mode Mock (Demo / Tanpa Koneksi Internet Backend)

Mode default yang langsung bekerja tanpa memerlukan kredensial Supabase. Seluruh repository menggunakan implementasi in-memory berlabel "Demo/Simulasi".

```bash
# Menjalankan di Android Emulator / Perangkat Nyata
flutter run -d android

# Menjalankan di Chrome (Web preview)
flutter run -d chrome
```

### 2. Mode Supabase (Live Backend)

Untuk menghubungkan aplikasi ke instance Supabase PostgreSQL:

1. Buat proyek baru di [Supabase Dashboard](https://supabase.com).
2. Terapkan skema basis data dan RLS (lihat bagian Migrasi di bawah).
3. Salin file template environment:
   ```bash
   cp .env.example .env
   ```
4. Masukkan URL dan Kunci Publik Supabase Anda pada berkas `.env`:
   ```env
   SUPABASE_URL=https://proyek-anda.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   USE_MOCK=false
   ```
5. Jalankan aplikasi dengan `--dart-define`:
   ```bash
   flutter run -d android \
     --dart-define=SUPABASE_URL=https://proyek-anda.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... \
     --dart-define=USE_MOCK=false
   ```

---

## 🗄️ Panduan Migrasi Database & Data Seed

Seluruh skrip migrasi SQL tersimpan di folder `supabase/migrations/`:

### Langkah Migrasi:
1. **Eksekusi Skema Awal & RLS**:
   Jalankan file `supabase/migrations/20261014000000_initial_schema.sql` di SQL Editor Supabase.
   Skrip ini mencakup:
   - Pembuatan tabel `profiles`, `motorcycles`, `service_histories`, `maintenance_reminders`, `notifications`, `help_requests`.
   - Aktivasi Row Level Security (RLS) di seluruh tabel.
   - Pemicu otomatis pembuatan profil saat registrasi pengguna (`handle_new_user`).
   - RPC function `create_service_request` untuk transaksi bantuan mekanik aman.
2. **Eksekusi Data Seed Demo/Simulasi**:
   Jalankan file `supabase/seed_demo.sql` di SQL Editor Supabase untuk memuat data awal katalog bengkel dan tutorial berlabel demo.

---

## 📋 Daftar Placeholder yang Wajib Diisi Manusia Sebelum Rilis

Sesuai ketentuan PRD 10.4, data berikut wajib disempurnakan oleh manusia sebelum demonstrasi publik atau peluncuran produksi:

1. **URL Video YouTube Valid (`tutorials`)**:
   - Tautan video YouTube pada `supabase/seed_demo.sql` dan `MockTutorialRepository` perlu diganti dengan video tutorial perawatan sepeda motor asli berbahasa Indonesia yang telah dicek kelayakan hak cipta dan ketersediaan tayangannya.
2. **Kontak Darurat Resmi (`emergencyContacts`)**:
   - Nomor telepon pada lembar opsi bantuan darurat (`lib/features/help_requests/`) perlu disesuaikan dengan call center resmi instansi lokal (Polres Lhokseumawe, PMI, PSC 119 Aceh Utara).
3. **Data Bengkel Terverifikasi Asli (`workshops`)**:
   - Koordinat latitude/longitude, alamat lengkap, dan nomor kontak bengkel resmi di Kota Lhokseumawe dan Kabupaten Aceh Utara harus diverifikasi dengan mitra bengkel fisik setempat.
4. **Interval Servis Rekomendasi Pabrikan (`reminders`)**:
   - Nilai interval kilometer dan bulan pada templat pengingat perawatan mandiri perlu diselaraskan dengan buku panduan resmi pabrikan motor umum (misal: Honda, Yamaha, Suzuki).

---

## ⚠️ Batas yang Diketahui (Known Limitations)

1. **Wilayah Layanan Khusus**:
   - Bengkel terverifikasi dan bantuan mekanik dibatasi secara permanen di **Kota Lhokseumawe** dan **Kabupaten Aceh Utara**. Permintaan atau pencarian di luar wilayah ini akan menampilkan peringatan batas cakupan wilayah.
2. **Satu Permintaan Mekanik Aktif (*Single Active Request*)**:
   - Pengguna hanya diperbolehkan memiliki 1 permintaan bantuan mekanik aktif berstatus `pending` atau `accepted`. Pengguna harus membatalkan atau menyelesaikan permintaan sebelum membuat panggilan baru.
3. **Navigasi Peta Eksternal**:
   - Aplikasi tidak memuat peta (*map*) interaktif tertanam di dalam aplikasi (menghindari ketergantungan API key pihak ketiga yang berat). Navigasi lokasi dilakukan dengan membuka aplikasi Google Maps eksternal atau penyalinan alamat fisik.
4. **Platform Target**:
   - Dioptimalkan khusus untuk Android (`minSdk 26`).

---

## 🧪 Perintah Pengujian & QA

```bash
# Analisis statis linter ketat
flutter analyze

# Jalankan seluruh 167 unit dan widget test
flutter test

# Uji ketahanan jaringan & aksesibilitas QA (M8)
flutter test test/features/qa/accessibility_and_network_resilience_test.dart

# Kompilasi build APK debug
flutter build apk --debug
```

---

## 📁 Struktur Direktori

```text
motocare/
  ├── lib/
  │   ├── app.dart                        # Inisialisasi tema, router, locale id_ID
  │   ├── core/
  │   │   ├── config/                     # Konstanta (timeout 15s, batas wilayah, env)
  │   │   ├── errors/                     # AppException & pemetaan pesan ramah
  │   │   ├── router/                     # GoRouter & rute dengan proteksi sesi
  │   │   ├── theme/                      # AppColors, AppTheme, AppMotion
  │   │   ├── utils/                      # NetworkGuard, Formatters, Validators, Result
  │   │   └── widgets/                    # Komponen UI: Button, StatusChip, Skeleton, dll.
  │   └── features/                       # Arsitektur per fitur (Domain, Data, Presentation)
  │       ├── auth/
  │       ├── home/
  │       ├── motorcycles/
  │       ├── service_history/
  │       ├── reminders/
  │       ├── notifications/
  │       ├── workshops/
  │       ├── tutorials/
  │       ├── help_requests/
  │       └── profile/
  ├── docs/
  │   ├── AGENT_PRD.md                    # Dokumen spesifikasi eksekusi lengkap
  │   └── test_report.md                  # Laporan hasil uji QA (TC-01 s/d TC-25)
  ├── supabase/
  │   ├── migrations/                     # Skema SQL, RLS, & Trigger DB
  │   └── seed_demo.sql                   # Data awal bengkel & tutorial demo
  └── test/                               # 167 unit & widget automated tests
```
