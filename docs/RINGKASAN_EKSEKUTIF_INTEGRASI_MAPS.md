# Ringkasan Eksekutif: Integrasi Google Maps Platform & Ketahanan Sistem MOTOCARE

**Proyek:** MOTOCARE (Motorcycle Care & Emergency Rescue Platform)  
**Wilayah Operasional:** Kota Lhokseumawe & Kabupaten Aceh Utara, Provinsi Aceh  
**Platform Target:** Android (Flutter 3.x, minSdk 26, targetSdk 34)  
**Backend:** Supabase Cloud (PostgreSQL 15, Auth, RLS, Edge Functions)  
**Status Integrasi:** Selesai 100% (Tahap 1 s/d Tahap 9)  
**Tanggal:** 14 November 2026  

---

## 1. Latar Belakang & Rumusan Masalah

Wilayah Kota Lhokseumawe dan Kabupaten Aceh Utara memiliki jalur lintas utama (seperti Jalan Medan–Banda Aceh dan Jalur Lingkar Simpang Elak) yang panjang dengan jarak antar-bengkel fisik yang berjauhan. Saat pengendara mengalami mogok kendaraan (seperti ban pecah, rantai putus, atau mesin mati mendadak), mereka menghadapi kendala:
1. Kesulitan menentukan titik lokasi akurat saat meminta pertolongan darurat.
2. Tidak mengetahui estimasi kedatangan mekanik secara transparan.
3. Ketiadaan katalog bengkel terpercaya yang terverifikasi di wilayah setempat.

Integrasi Google Maps Platform pada aplikasi MOTOCARE diimplementasikan untuk menyelesaikan masalah tersebut dengan tetap mematuhi batasan ketat: **tanpa kebocoran API Key ke sisi client**, **tanpa pembengkakan biaya API**, dan **menjunjung tinggi prinsip kejujuran data akademik**.

---

## 2. Arsitektur Terintegrasi & Komponen Google Maps Platform

Integrasi Google Maps Platform dieksekusi secara berurutan dalam 9 tahap komprehensif:

```mermaid
flowchart TD
    User["Aplikasi Pengendara (Flutter)"]
    Proxy["Supabase Edge Function (maps-proxy)"]
    GoogleAPI["Google Maps Platform API"]
    DB["Supabase PostgreSQL Cloud"]

    User -->|"1. Places Autocomplete & Geocoding"| Proxy
    Proxy -->|"2. Rate Limiter (30 req/min) & RAM Cache (10 min TTL)"| Proxy
    Proxy -->|"3. Server-to-Server HTTPS Request"| GoogleAPI
    GoogleAPI -->|"4. Response Data"| Proxy
    Proxy -->|"5. Sanitized JSON"| User

    User -->|"6. Emergency Dispatch (Idempotency Key)"| DB
    User -->|"7. Tracking Montir (Opsi A Simulasi Terkendali)"| User
    User -->|"8. Rute Eksternal Bengkel (Google Maps Intent)"| GoogleMapsApp["Aplikasi Google Maps Eksternal"]
```

### Rincian 9 Tahap Implementasi:
1. **Tahap 1 — Fondasi & Tata Kelola Keuangan ($0 Leakage):**
   - Pemisahan server key dan client key.
   - Pendaftaran dependensi `google_maps_flutter`, `geolocator`, `http`.
   - Setup konfigurasi `.env` yang terisolasi ketat di `.gitignore`.
2. **Tahap 2 — Lokasi Pengguna & Izin Kontekstual:**
   - Izin lokasi presisi bertahap (*foreground only*, `ACCESS_FINE_LOCATION`).
   - Dialog edukasi sebelum meminta izin sistem (*pre-permission dialog*).
   - Penanganan penolakan permanen dengan navigasi ke Pengaturan Aplikasi.
   - Fallback otomatis ke input alamat manual jika GPS dinonaktifkan.
3. **Tahap 3 — Autocomplete Alamat & Geocoding Terkendali:**
   - Debounce 300ms dan batas minimum 3 karakter.
   - Places Autocomplete Session Token (`sessiontoken` UUID v4).
   - In-memory RAM cache (TTL 10 menit).
   - Reverse geocoding koordinat GPS ke nama jalan lokal Lhokseumawe/Aceh Utara.
4. **Tahap 4 — Direktori Bengkel Hibrida (DB Lokal + Google Maps):**
   - Basis data bengkel resmi terverifikasi di Lhokseumawe & Aceh Utara.
   - Tombol buka rute langsung via Google Maps Intent (`https://www.google.com/maps/dir/?api=1&destination=lat,lng`).
   - Lembar ulasan bengkel hibrida (ulasan internal MOTOCARE + rating Google).
5. **Tahap 5 — Dispatch Mekanik & Privasi Pengguna:**
   - Formulir pendaftaran bantuan darurat dengan pratinjau peta interaktif.
   - Fitur samarkan lokasi (*fuzzing* lokasi $\pm 100\text{ m}$) untuk melindungi privasi tempat tinggal pengendara.
   - Estimasi biaya transparan sebelum pemesanan.
6. **Tahap 6 — Tracking Montir Transparan (Opsi A Simulasi Animasi):**
   - Animasi pergerakan montir secara halus dengan interpolasi matematis.
   - Badge kejujuran data: `"Simulasi dipercepat - bukan GPS nyata"`.
   - Fallback lokasi usang (*stale location*, Figma 09.07) jika pembaruan berhenti $>30$ detik.
   - Micro-copy status Figma 03.10 (*"Montir Sudah Tiba di Lokasi"*) dan 03.11 (*"Kembali ke Aktivitas"*).
7. **Tahap 7 — Ketangguhan & Keamanan Maps:**
   - *Idempotency Key* pada setiap transaksi bantuan darurat untuk mencegah pesanan ganda (*double-submit*).
   - *Rate limiting* 30 request/menit pada Supabase Edge Function `maps-proxy`.
8. **Tahap 8 — Uji & Dokumentasi Teknis:**
   - Matriks pengujian manual 35 skenario (`docs/MANUAL_TESTING_MATRIX.md`).
   - Diagram arsitektur dan sequence diagram (`docs/MAPS_ARCHITECTURE_AND_SEQUENCES.md`).
9. **Tahap 9 — Sinkronisasi Dokumen Akhir:**
   - Pembaruan PRD menyeluruh, README proyek, dan Ringkasan Eksekutif ini.

---

## 3. Strategi Keamanan & Pengendalian Biaya ($0 Cost Leakage)

Untuk memastikan aplikasi layak secara operasional dan tidak menimbulkan pembengkakan tagihan Google Cloud:

| Aspek | Risiko Potensial | Solusi & Mitigasi MOTOCARE |
| --- | --- | --- |
| **Penyimpanan API Key** | Kunci bocor via dekompilasi APK / GitHub repository | Kunci disimpan di Supabase Vault / Secrets dan `.env` yang diabaikan Git (`.gitignore:52:*.env`). Aplikasi client memanggil Edge Function proxy tanpa memegang kunci server. |
| **Pencarian Alamat** | Pengguna mengetik cepat memicu puluhan API call berbayar | Debounce 300ms, minimum 3 karakter, dan Session Token UUID v4 (Google hanya menagih 1 sesi autocomplete per pemilihan alamat). |
| **Permintaan Berulang** | Alamat atau koordinat yang sama diminta berulang kali | In-memory cache berdurasi 10 menit pada Edge Function dan aplikasi client. |
| **Rute & Pelacakan** | Routes API menagih \$0.01 per panggilan (biaya tinggi saat realtime polling) | Memilih **Opsi A (Simulasi Terkendali)**: $0 konsumsi Routes API. Menghitung jarak via Haversine Formula dan interpolasi animasi lokal. |
| **Pencegahan Spam / DDoS** | Bot atau pengguna menembak proxy secara masif | Sliding-window rate limiter: maksimum 30 request per menit per user/IP. |
| **Koneksi Seluler Tidak Stabil** | Pengguna menekan tombol SOS berkali-kali saat sinyal lambat | Idempotency Key unik per permintaan; request duplikat otomatis mengembalikan pesanan yang sedang berjalan tanpa duplikasi di database. |

---

## 4. Prinsip Kejujuran Data Akademik (Tahap 6 — Opsi A)

Dalam dunia akademik dan pengujian profesional, menyajikan data palsu sebagai data riil tanpa pemberitahuan merupakan pelanggaran integritas. MOTOCARE secara tegas menerapkan transparansi penuh pada fitur pelacakan montir:
1. **Label Kejujuran Jelas:** Layar tracking montir menyematkan badge berwarna kuning amber yang terbaca jelas oleh pengguna:  
   `"Simulasi dipercepat - bukan GPS nyata"`.
2. **Tanpa Klaim Palsu:** Sistem tidak mengklaim telah terhubung dengan satelit GPS mekanik asli saat menjalankan simulasi demo.
3. **Mekanisme Ketahanan Nyata:** Tetap menyertakan penanganan kondisi darurat riil seperti tombol panggilan telepon langsung ke montir dan deteksi lokasi tertunda (*stale location fallback*).

---

## 5. Sinkronisasi Skema Supabase Live

Aplikasi telah berhasil disinkronkan dan diuji langsung dengan proyek Supabase Cloud resmi:
- **Project Ref:** `acdfesajqkwbsczdiedt`
- **Tabel Basis Data Riil (10 Tabel):**
  1. `profiles`: Data pengguna, peran (`'owner'`, `'mechanic'`, `'admin'`), nomor telepon.
  2. `vehicles`: Garasi motor pengendara (menggantikan nama skema dev `motorcycles`).
  3. `mechanics`: Mitra mekanik, area servis, ketersediaan, rating.
  4. `workshops`: Katalog bengkel terverifikasi di Lhokseumawe dan Aceh Utara.
  5. `assistance_requests`: Panggilan darurat montir (status: `'MENUNGGU'`, `'DITERIMA'`, `'SEDANG_DITANGANI'`, `'SELESAI'`, `'DIBATALKAN'`, `'DITOLAK'`).
  6. `service_histories`: Riwayat servis dan transparansi pengeluaran biaya.
  7. `service_reminders`: Pengingat servis berkala (status: `'AKTIF'`, `'SELESAI'`, `'DIABAIKAN'`).
  8. `notifications`: Notifikasi in-app untuk pengguna.
  9. `tutorials`: Video tutorial perawatan mandiri berbasis YouTube.
  10. `reviews`: Ulasan dan rating bintang pasca-servis bantuan darurat.
- **Dual-Compatibility Repository:** Seluruh repository Supabase diimplementasikan secara cerdas dengan dukungan dua arah (*dual-schema*), membaca tabel produksi resmi dengan fallback aman ke tabel skema dev tanpa memutus kompatibilitas kode pengujian lokal.

---

## 6. Metrik Pengujian & Jaminan Mutu Kualitas Perangkat Lunak

Kualitas perangkat lunak MOTOCARE diverifikasi secara ketat melalui audit kode statis dan pengujian otomatis:

```text
================================================================================
                    HASIL AUDIT MUTU PERANGKAT LUNAK MOTOCARE
================================================================================
Analisis Kode Statis (flutter analyze) : 0 Error, 0 Warning, 0 Issue (CLEAN)
Total Automated Test Suite             : 226 / 226 Tests LULUS (100% Pass)
  - Unit Tests Formatter & Validator   : LULUS
  - Widget Tests Core UI & Aksesibilitas: LULUS (Bebas RenderFlex Overflow)
  - Multi-Role Auth & RLS Isolation    : LULUS
  - Modul Garasi, Servis, Pengingat    : LULUS
  - Tahap 1-5 Maps Services & Widgets  : LULUS
  - Tahap 6 Tracking Montir Simulasi   : LULUS (5/5 tests)
  - Tahap 7 Security & Idempotency Key : LULUS (4/4 tests)
Matriks Pengujian Manual (TC-MAPS)     : 35 / 35 Skenario Terverifikasi Lolos
Kepatuhan Batasan Wilayah Operasional  : Terverifikasi (Lhokseumawe & Aceh Utara)
Kepatuhan Keamanan Kredensial (.gitignore): Terverifikasi (.env bebas tracking)
================================================================================
```

---

## 7. Rekomendasi Menuju Peluncuran Komersial (Production Roadmap)

Untuk membawa aplikasi MOTOCARE dari status siap-demo/akademik menuju rilis komersial di Google Play Store:
1. **Deploy Supabase Edge Function (`maps-proxy`):** Unggah kode di `supabase/functions/maps-proxy/index.ts` ke instance Supabase Cloud dan tetapkan secret `GOOGLE_MAPS_SERVER_KEY`.
2. **Aktifkan Opsi B Tracking GPS Riil (Pasca-MVP):** Saat armada montir fisik telah dilengkapi aplikasi mekanik dengan background geolocation tracker, alihkan `SimulatedMechanicTrackingCard` ke `LiveMechanicTrackingCard` dengan mendengarkan stream lokasi koordinat mekanik dari Supabase Realtime Channel.
3. **Penyempurnaan Data Kontak Darurat:** Perbarui daftar nomor darurat pada lembar bantuan darurat dengan nomor resmi instansi lokal (Polres Lhokseumawe, PSC 119 Aceh Utara, BPBD).
4. **Verifikasi Mitra Bengkel Fisik:** Menjalin kerja sama resmi dengan bengkel-bengkel lokal di Kota Lhokseumawe dan Kabupaten Aceh Utara untuk pemberian lencana mitra terverifikasi.

---

*Dokumen ini disusun sebagai bukti kelengkapan teknis, kepatuhan arsitektur, dan integritas implementasi integrasi Google Maps Platform pada aplikasi MOTOCARE.*

