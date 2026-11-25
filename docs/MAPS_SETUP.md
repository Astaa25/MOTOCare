# Panduan Konfigurasi & Keamanan Google Maps Platform — MotoCare

Dokumen ini merupakan panduan resmi pengaturan, pengamanan, kontrol biaya, dan arsitektur integrasi Google Maps Platform pada aplikasi **MotoCare** (Flutter Android & Supabase) sesuai spesifikasi Analisis Sistem dan desain Figma.

---

## 1. Ringkasan Arsitektur & Prinsip Keamanan

MotoCare menerapkan prinsip keamanan **Least Privilege**, **Zero Leakage**, dan **Defense-in-Depth**:
1. **Tidak Ada Server Key di Client**: Kunci API untuk Web Service (*Places API*, *Geocoding API*) **TIDAK PERNAH** disimpan di dalam aplikasi Flutter. Seluruh panggilan web service wajib melalui perantara (**Supabase Edge Function** / backend proxy).
2. **Kunci Android Dibatasi Ketat**: Kunci API Maps SDK for Android dibatasi hanya untuk package name `id.motocare.motocare` dan fingerprint sertifikat SHA-1 (Debug dan Release).
3. **Kontrol Biaya Berlapis**:
   - Debounce pengetikan (400 ms) pada input pencarian.
   - Penggunaan *Places Autocomplete Session Token (UUID v4)* untuk mengelompokkan panggilan menjadi 1 billing session.
   - In-memory cache jangka pendek (TTL 10 menit) untuk mencegah permintaan berulang pada sesi yang sama.
   - *FieldMask* minimal (hanya meminta field yang benar-benar ditampilkan).
   - Pembatasan wilayah layanan (Kota Lhokseumawe & Kab. Aceh Utara) sebelum memanggil web service.
4. **Feature Flag & Jalur Pemulihan (Fallback)**:
   - Tersedia flag `MAPS_ENABLED` (default: `true`). Jika dinonaktifkan atau jika kunci belum tersedia, aplikasi otomatis beralih ke navigasi eksternal (`url_launcher` via URL/Geo intent) dan formulir input manual tanpa crash.

---

## 2. Langkah Persiapan Google Cloud Console (Dilakukan Pengembang/Admin)

> **Catatan:** Langkah berikut memerlukan akun Google Cloud dengan billing aktif.

### Langkah 2.1: Buat Project & Aktifkan Billing
1. Buka [Google Cloud Console](https://console.cloud.google.com/).
2. Buat project baru bernama `MotoCare-Production` (atau `MotoCare-Dev`).
3. Tautkan akun pembayaran (*Cloud Billing Account*). Google menyediakan saldo gratis senilai **$200/bulan** untuk Google Maps Platform.

### Langkah 2.2: Aktifkan API yang Dibutuhkan
Buka menu **APIs & Services > Library**, cari dan aktifkan:
- **Maps SDK for Android** (untuk merender peta di aplikasi Android)
- **Places API (New)** (untuk autocomplete lokasi & pencarian bengkel)
- **Geocoding API** (untuk konversi koordinat GPS ke nama alamat dan sebaliknya)
- *(Opsional)* **Routes API** (hanya jika di masa mendatang memilih tracking rute nyata Tahap 6 Opsi B; pada Opsi A tidak diperlukan).

---

## 3. Pembuatan & Pembatasan API Key

Anda wajib membuat **2 kunci API terpisah** dengan pembatasan yang berbeda:

### Kunci A: Kunci Android Client (`MAPS_API_KEY`)
Kunci ini digunakan secara eksklusif oleh aplikasi Android untuk menampilkan peta Google Maps SDK.

1. Buka **APIs & Services > Credentials > Create Credentials > API Key**.
2. Beri nama: `MotoCare-Android-Client-Key`.
3. Atur **Set application restrictions**:
   - Pilih **Android apps**.
   - Klik **Add an item**:
     - **Package name**: `id.motocare.motocare`
     - **SHA-1 certificate fingerprint**:
       - *Untuk Debug Keystore:* Dapatkan dengan menjalankan perintah berikut di terminal:
         ```bash
         keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
         ```
       - *Untuk Release Keystore:* Masukkan SHA-1 dari keystore rilis Anda.
4. Atur **API restrictions**:
   - Pilih **Restrict key**.
   - Centang **HANYA**: `Maps SDK for Android`.
5. Simpan kunci.
6. **Cara Memasang di Proyek Lokal**:
   - Buka berkas `android/local.properties` (berkas ini sudah masuk `.gitignore` sehingga tidak akan terunggah ke Git).
   - Tambahkan baris:
     ```properties
     MAPS_API_KEY=AIzaSy...masukkan_kunci_android_anda_di_sini...
     ```

### Kunci B: Kunci Server Web Service (`GOOGLE_MAPS_SERVER_KEY`)
Kunci ini digunakan oleh Supabase Edge Function untuk memanggil Places API dan Geocoding API.

1. Buat API Key baru bernama: `MotoCare-Server-Proxy-Key`.
2. Atur **Set application restrictions**:
   - Pilih **None** (atau batasi ke IP static jika menggunakan server VPS dedicated).
3. Atur **API restrictions**:
   - Pilih **Restrict key**.
   - Centang **HANYA**:
     - `Places API (New)`
     - `Geocoding API`
4. Simpan kunci.
5. **Cara Memasang di Supabase Secrets**:
   - Jalankan perintah Supabase CLI (atau melalui dashboard Supabase > Project Settings > Edge Functions > Secrets):
     ```bash
     supabase secrets set GOOGLE_MAPS_SERVER_KEY=AIzaSy...masukkan_kunci_server_anda_di_sini...
     ```
   - **PENTING**: JANGAN PERNAH meletakkan kunci ini di dalam proyek Flutter (`lib/`, `pubspec.yaml`, atau `.env` lokal).

---

## 4. Pengaturan Batas Kuota & Peringatan Anggaran (Budget Alert)

Untuk mencegah tagihan tidak terduga atau penyalahgunaan kuota:

1. **Pasang Budget Alert di Billing**:
   - Buka **Billing > Budgets & alerts > Create budget**.
   - Beri nama `Budget-MotoCare-Maps`.
   - Set target bulanan (misal Rp 100.000 atau $10).
   - Set ambang peringatan email pada 50%, 90%, dan 100%.
2. **Pasang Batas Kuota Harian (Daily Quota Cap)**:
   - Buka **APIs & Services > Places API (New) > Quotas**.
   - Batasi maksimum permintaan per hari (misal 1.000 request/hari untuk pengujian).
   - Lakukan hal yang sama untuk **Geocoding API** (misal 500 request/hari).

---

## 5. Estimasi Biaya & Pemakaian (Skenario Pengujian 100 Pengguna)

Google Cloud memberikan kredit bulanan gratis sebesar **\$200.00 USD** setiap bulan.

| Layanan API | Harga per 1.000 Panggilan | Estimasi Panggilan (Demo 100 Akun) | Estimasi Biaya | Status Penagihan |
| :--- | :--- | :--- | :--- | :--- |
| **Maps SDK for Android** | Gratis tanpa batas untuk render peta mobile dinamis | ~1.500 tampilan peta | \$0.00 | **Gratis** |
| **Places Autocomplete** (Session) | \$17.00 per 1.000 sesi (1 sesi = 1 rangkaian ketik hingga pilih tempat) | ~150 sesi pencarian | ~\$2.55 | **Tercakup Saldo Gratis** |
| **Place Details** (Basic FieldMask) | Termasuk dalam sesi autocomplete jika memakai session token | ~150 pemanggilan | \$0.00 | **Tercakup Saldo Gratis** |
| **Geocoding API** | \$5.00 per 1.000 panggilan | ~200 panggilan reverse geocode | ~\$1.00 | **Tercakup Saldo Gratis** |
| **Total Estimasi Uji Coba** | - | - | **~\$3.55** | **100% Gratis (\$0 Tagihan Bersih)** |

> Saldo kredit \$200 bulanan menyisakan margin keamanan sebesar **\$196.45 (98%)**.

---

## 6. Penanganan Fallback & Feature Flag

Aplikasi memiliki switch terpusat:
- Jika `MAPS_ENABLED=false` (dijalankan dengan `--dart-define MAPS_ENABLED=false`):
  - Komponen peta digantikan oleh kartu ringkasan lokasi ilustratif.
  - Terdapat tombol *"Buka di Google Maps"* yang memanfaatkan `url_launcher` dengan schema `geo:` atau tautan web browser Google Maps resmi.
  - Pemilihan lokasi menggunakan input teks manual dan dropdown wilayah resmi (Kota Lhokseumawe & Kab. Aceh Utara).
- Jika perangkat tidak memiliki Google Play Services / Google Maps terpasang:
  - Intent URL launcher secara elegan membuka peramban web (*browser fallback*).

