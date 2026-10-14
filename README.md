# MotoCare - Aplikasi Perawatan Motor

MotoCare adalah aplikasi mobile (Android & Web Chrome) berbahasa Indonesia untuk pemilik sepeda motor di Kota Lhokseumawe dan Kabupaten Aceh Utara. Aplikasi ini membantu mencatat motor, riwayat servis dan biaya, pengingat servis otomatis berbasis tanggal dan kilometer, tutorial perawatan mandiri, direktori bengkel terverifikasi, serta permintaan bantuan mekanik darurat.

## 🚀 Fitur Utama (MVP)
- **Motor Saya**: Pencatatan motor, kilometer terkini, dan validasi selisih kilometer.
- **Riwayat Servis**: Pencatatan tanggal servis, kilometer, biaya (Rupiah), dan pembaruan kilometer otomatis.
- **Pengingat Perawatan**: Penghitungan status cerdas (*Terjadwal*, *Segera Servis*, *Terlambat*, *Selesai*).
- **Pusat Notifikasi**: Notifikasi in-app untuk pengingat dan status mekanik tanpa duplikasi.
- **Bengkel Terverifikasi**: Direktori bengkel lokal resmi di Kota Lhokseumawe & Kab. Aceh Utara.
- **Tutorial Perawatan**: Video edukasi perawatan motor mandiri.
- **Bantuan Mekanik**: Permintaan mekanik datang ke lokasi dengan hitung mundur kedaluwarsa 15 menit.

## 🛠️ Persyaratan Sistem & Tech Stack
- **Framework**: Flutter (Channel stable, Dart 3)
- **State Management**: `flutter_riverpod`
- **Navigasi**: `go_router`
- **Tipografi**: Plus Jakarta Sans
- **Backend**: Supabase (Auth, PostgreSQL, Row Level Security)
- **Platform**: Android (minSdk 26) & Web Chrome

## 💻 Cara Menjalankan Aplikasi

### 1. Mode Mock (Demo / Tanpa Backend Supabase)
Aplikasi dapat dijalankan secara instan dengan data simulasi:

```bash
# Menjalankan di Google Chrome
flutter run -d chrome

# Menjalankan di Android Emulator / Perangkat
flutter run -d android
```

### 2. Mode Supabase (Live Backend)
Salin konfigurasi environment dari template:
```bash
cp .env.example .env
```
Isi nilai `SUPABASE_URL` dan `SUPABASE_ANON_KEY` Anda di `.env`.

Jalankan dengan parameter `--dart-define`:
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://xyzcompany.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJh... \
  --dart-define=USE_MOCK=false
```

### 3. Perintah Analisis & Pengujian
```bash
# Analisis kode (linter ketat)
flutter analyze

# Jalankan seluruh unit dan widget test
flutter test

# Format kode
dart format lib test
```

## 📂 Struktur Proyek
Sesuai PRD MotoCare:
- `lib/core/`: Desain tokens, tema, konfigurasi, router, widgets umum, utilitas.
- `lib/features/`: Arsitektur Clean/Feature-first (`auth`, `motorcycles`, `service_history`, `reminders`, `notifications`, `tutorials`, `workshops`, `help_requests`, `profile`, `home`).
- `supabase/migrations/`: Skema basis data, RLS, dan RPC PostgreSQL.
- `test/`: Cerminan struktur pengujian unit dan widget.
