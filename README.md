# MotoCare - Aplikasi Perawatan Motor & Bantuan Darurat

MotoCare adalah aplikasi mobile (Android) berbahasa Indonesia untuk pemilik sepeda motor di **Kota Lhokseumawe** dan **Kabupaten Aceh Utara**. Aplikasi ini membantu mencatat motor di garasi digital, riwayat servis dan biaya transparan, pengingat servis otomatis berbasis tanggal dan kilometer, tutorial perawatan mandiri, direktori bengkel terverifikasi hibrida, serta sistem panggilan mekanik darurat lengkap dengan integrasi **Google Maps Platform** dan backend **Supabase Cloud**.

---

## 🚀 Fitur Utama

1. **Garasi Motor Digital**:
   - Pendaftaran sepeda motor (Merek, Model, Tahun Pembuatan, Nomor Polisi, Kilometer Terkini).
   - Validasi selisih kilometer cerdas (konfirmasi jika kilometer turun / koreksi) sesuai aturan bisnis PRD 6.2.
   - Peringatan pembaruan kilometer jika belum diperbarui lebih dari 30 hari (*mileage stale*).

2. **Riwayat Servis & Transparansi Biaya**:
   - Catat tanggal servis, kilometer, rincian tindakan servis, biaya jasa, dan biaya suku cadang dalam format Rupiah.
   - Pembaruan otomatis kilometer sepeda motor saat pencatatan servis baru disimpan.
   - Filter riwayat servis berdasarkan kategori (Rutin, Perbaikan, Darurat) dan kalkulasi total pengeluaran.

3. **Pengingat Perawatan Pintar**:
   - Pengingat berbasis tanggal kalender atau ambang batas kilometer.
   - Penentuan status otomatis: *Overdue* (Merah), *Segera Servis* (Oranye), *Terjadwal* (Abu-abu), *Selesai* (Hijau).
   - Templat servis bawaan pabrikan (Ganti Oli Mesin, Servis CVT, Busi, Kampas Rem, Radiator, Gir & Rantai).

4. **Pusat Notifikasi In-App**:
   - Notifikasi otomatis saat status pengingat jatuh tempo atau status panggilan mekanik darurat berubah.
   - Notifikasi lokal di perangkat menggunakan `flutter_local_notifications` & `timezone`.

5. **Katalog Bengkel Terverifikasi Hibrida (Tahap 4 Maps)**:
   - Direktori bengkel resmi terpercaya di wilayah layanan tetap (Kota Lhokseumawe & Kab. Aceh Utara).
   - Rating hibrida (gabungan rating pengguna internal MOTOCARE dan Google Places Rating).
   - Tombol buka rute langsung via Google Maps Intent eksternal dan salin alamat/kontak langsung.

6. **Tutorial Perawatan Mandiri**:
   - Video edukasi perawatan motor mandiri terkurasi berdasarkan topik (mesin, rem, rantai, ban, kelistrikan).
   - Integrasi tautan YouTube via `url_launcher` dengan opsi salin tautan video (*fallback*).

7. **Sistem Panggilan Mekanik Darurat (Emergency Rescue)**:
   - Panggilan montir datang ke lokasi dengan deteksi koordinat GPS presisi (`geolocator`), reverse geocoding otomatis, atau pencarian alamat via Google Places Autocomplete.
   - Pratinjau peta interaktif terintegrasi (`google_maps_flutter`) dengan penanda lokasi pengguna dan estimasi biaya awal.
   - Opsi samarkan lokasi (*location fuzzing* $\pm 100\text{ m}$) untuk melindungi privasi tempat tinggal pengguna.
   - Proteksi *idempotency key* dan *anti-double-submit* pada jaringan seluler tidak stabil.
   - Batas waktu tunggu respons otomatis (15 menit) dengan alternatif hubungi kontak darurat lokal jika kedaluwarsa.

8. **Pelacakan Montir Transparan (Tahap 6 Maps — Opsi A Simulasi)**:
   - Animasi visual pergerakan montir secara halus di atas kartu rute mini.
   - Menjunjung tinggi prinsip kejujuran data akademik melalui badge permanen: `"Simulasi dipercepat - bukan GPS nyata"`.
   - Estimasi jarak sisa dan waktu tiba (ETA) yang diperbarui secara dinamis.
   - Deteksi lokasi usang (*stale location fallback*, Figma 09.07) jika pembaruan terhenti $>30$ detik lengkap dengan tombol panggilan telepon ke montir.
   - Kartu status penyelesaian Figma 03.10 (*"Montir Sudah Tiba di Lokasi"*) dan tombol CTA Figma 03.11 (*"Kembali ke Aktivitas"*).

---

## 🛠️ Persyaratan Sistem & Tech Stack

- **Platform Target**: Android (minSdk 26, targetSdk 34)
- **Framework**: Flutter (Channel stable, Dart 3)
- **State Management**: `flutter_riverpod` 2.6.x
- **Navigasi**: `go_router` 14.8.x dengan proteksi sesi (Auth Guard)
- **Peta & Lokasi**: `google_maps_flutter`, `geolocator`
- **Desain & Tema**: Design tokens MotoCare (Sleek Warm Coral `#FF5733`, Navy Charcoal `#2D3142`, Cream `#FFF9F5`)
- **Tipografi**: Plus Jakarta Sans (dibundel di `assets/fonts/`)
- **Backend Cloud**: Supabase (PostgreSQL 15, Auth, Row Level Security, Edge Functions)
- **Pengujian**: `flutter_test`, `mocktail` (226 unit/widget automated tests, 100% Pass)

---

## 💻 Cara Menjalankan Aplikasi

Aplikasi MotoCare dapat dijalankan dalam dua mode:

### 1. Mode Mock (Demo / Pengujian Cepat Tanpa Koneksi Internet)

Mode default yang langsung bekerja tanpa memerlukan kredensial Supabase. Seluruh repository menggunakan implementasi in-memory berlabel "Demo/Simulasi".

```bash
# Menjalankan di Android Emulator / Perangkat Fisik
flutter run -d android

# Menjalankan di Chrome (Web preview)
flutter run -d chrome
```

### 2. Mode Live Supabase & Google Maps Platform

Untuk menghubungkan aplikasi ke instance Supabase Cloud dan layanan peta:

1. Buat file `.env` di root proyek (file ini otomatis diabaikan oleh Git via `.gitignore`):
   ```bash
   cp .env.example .env
   ```
2. Isi kredensial Supabase dan Google Maps Anda di dalam berkas `.env`:
   ```env
   SUPABASE_URL=https://acdfesajqkwbsczdiedt.supabase.co
   SUPABASE_ANON_KEY=sb_publishable_XTnYGL96nOF5jy7Qw-NOEQ_bq82UAYY
   GOOGLE_MAPS_API_KEY=AIzaSy...
   USE_MOCK=false
   ```
3. Jalankan aplikasi menggunakan argumen `--dart-define-from-file=.env`:
   ```bash
   flutter run -d android --dart-define-from-file=.env
   ```
   *Catatan: Pada VS Code, Anda juga dapat langsung menekan tombol F5 (Run & Debug) karena konfigurasi `.vscode/launch.json` telah disiapkan.*

---

## 🔒 Strategi Keamanan & Pengendalian Biaya ($0 Cost Leakage)

1. **Edge Function Proxy (`maps-proxy`)**:
   - Seluruh pemanggilan Google Places Autocomplete dan Geocoding dialirkan melalui Edge Function Supabase.
   - Kunci server Google Maps tersimpan aman di Supabase Secrets / Vault, **bukan di dalam file APK client**.
2. **Debounce 300ms & Session Token**:
   - Pencarian alamat menerapkan debounce 300ms dan batas minimum 3 karakter.
   - Penggunaan `sessiontoken` UUID v4 memastikan Google hanya menagih 1 sesi pengetikan per pemilihan alamat.
3. **RAM Cache 10 Menit**:
   - Hasil pencarian dan geocoding identik disimpan di RAM cache lokal selama 10 menit untuk mencegah panggilan API berulang.
4. **$0 Routes API Usage**:
   - Menghindari pemanggilan Google Routes API yang mahal (\$0.01 per panggilan) dengan memanfaatkan interpolasi matematis dan simulasi animasi rute transparan.
5. **Rate Limiting 30 req/menit**:
   - Edge Function proxy membatasi maksimal 30 request per menit per pengguna untuk mencegah eksploitasi dan lonjakan biaya.
6. **Proteksi Idempotensi**:
   - Setiap transaksi darurat dilengkapi `idempotencyKey` unik berbasis UUID v4 untuk memblokir pesanan ganda saat jaringan seluler lambat.

---

## 🗄️ Sinkronisasi Skema Supabase Live

Aplikasi mendukung **dual-compatibility** cerdas terhadap skema dev maupun skema produksi PostgreSQL resmi:

| Entitas Domain | Tabel Supabase Live | Peran & Kolom Kunci |
| --- | --- | --- |
| `UserProfile` | `public.profiles` | Profil pengguna, peran (`'owner'`, `'mechanic'`, `'admin'`), no. telepon |
| `Motorcycle` | `public.vehicles` | Garasi motor (`owner_id`, `current_km`, merek, model, plat nomor) |
| `Mechanic` | `public.mechanics` | Data montir mitra (`specialties`, `service_area`, koordinat GPS) |
| `Workshop` | `public.workshops` | Katalog bengkel terverifikasi (`service_region`, rating Google) |
| `ServiceRequest` | `public.assistance_requests` | Panggilan darurat (status: `'MENUNGGU'`, `'DITERIMA'`, dll.) |
| `ServiceHistory` | `public.service_histories` | Catatan servis (`vehicle_id`, biaya jasa, biaya suku cadang) |
| `MaintenanceReminder` | `public.service_reminders` | Pengingat servis (`target_date`, `target_km`, status: `'AKTIF'`) |
| `AppNotification` | `public.notifications` | Notifikasi riil in-app |
| `Tutorial` | `public.tutorials` | Panduan perawatan motor mandiri berbasis video YouTube |
| `Review` | `public.reviews` | Ulasan dan rating bintang pasca-servis |

---

## 🧪 Pengujian Kualitas & Verifikasi (QA)

Aplikasi telah diaudit secara menyeluruh dengan hasil **100% Lulus**:

```bash
# 1. Analisis kode statis ketat (0 issue, 0 warning)
flutter analyze --no-pub

# 2. Jalankan seluruh 226 automated unit & widget tests
flutter test --no-pub

# 3. Uji ketahanan Maps & Idempotensi (Tahap 7)
flutter test test/features/help_requests/tahap_7_security_resilience_test.dart

# 4. Uji pelacakan montir simulasi (Tahap 6)
flutter test test/features/help_requests/tahap_6_tracking_simulasi_test.dart
```

### Matriks Pengujian Manual
Tersedia 35 skenario pengujian komprehensif pada dokumen [docs/MANUAL_TESTING_MATRIX.md](docs/MANUAL_TESTING_MATRIX.md) yang mencakup penolakan izin lokasi, pencarian di luar batas wilayah Lhokseumawe/Aceh Utara, transisi status darurat, hingga pemulihan jaringan offline.

---

## 📚 Dokumentasi Terkait

- [Ringkasan Eksekutif Integrasi Maps](docs/RINGKASAN_EKSEKUTIF_INTEGRASI_MAPS.md) — Dokumen tinjauan eksekutif untuk penguji/dosen.
- [Diagram Arsitektur & Sequence Diagram Maps](docs/MAPS_ARCHITECTURE_AND_SEQUENCES.md) — Diagram Mermaid arsitektur, sequence diagram, dan ERD database lengkap.
- [Matriks Pengujian Manual (35 Skenario)](docs/MANUAL_TESTING_MATRIX.md) — Panduan pengujian langkah-demi-langkah.
- [Panduan Setup Maps & Edge Function](docs/MAPS_SETUP.md) — Langkah deployment Edge Function dan konfigurasi API key.
- [Laporan Pengujian QA Awal](docs/test_report.md) — Catatan pengujian awal Milestone M8.

---

## ⚠️ Batasan Operasional yang Diketahui

1. **Wilayah Layanan Tetap**: Layanan bantuan darurat dan bengkel terverifikasi dibatasi secara ketat di **Kota Lhokseumawe** dan **Kabupaten Aceh Utara**. Pencarian di luar koordinat ini akan menampilkan penolakan ramah kontekstual.
2. **Satu Permintaan Darurat Aktif**: Pengguna hanya dapat memiliki satu panggilan montir aktif secara bersamaan untuk mencegah kebingungan armada mekanik.
3. **Kejujuran Pelacakan Montir**: Pelacakan montir berjalan dalam mode simulasi animasi rute transparan dengan badge kejujuran akademik aktif (*Opsi A*).
