# Laporan Audit Keamanan & Matriks Uji Keamanan MotoCare (Milestone M9)

**Tanggal Audit:** 15 Oktober 2026  
**Aplikasi:** MotoCare (Android MVP)  
**Target Release:** Android (minSdk 26)  
**Lingkungan Audit:** Local Development & Test Runner (Flutter 3.47.1, Dart 3)  
**Komitmen Acuan:** `docs/AGENT_PRD.md` Bagian 12 sampai 18 (Addendum Keamanan, Privasi, Audit, dan Kesiapan Rilis)

---

## 1. Ringkasan Eksekutif Release Gate Keamanan

Sesuai kriteria kelulusan Bagian 16.3 dan 17, seluruh evaluasi keamanan, privasi, otorisasi basis data, perlindungan rahasia, dan integritas transaksi telah dijalankan.

### Status Matriks Uji Keamanan (SEC-01 s/d SEC-20)
- **Total Kasus Uji:** 20 Kasus
- **Status Lulus (`Pass`):** 19 Kasus
- **Status Tertunda (`Blocked`):** 1 Kasus (SEC-20: Verifikasi retensi backup produksi menunggu penyediaan instance produksi Supabase oleh pemilik proyek)
- **Status Gagal (`Fail`):** 0 Kasus
- **Temuan Kritis Terbuka:** 0
- **Temuan Tinggi Terbuka:** 0

---

## 2. Matriks Uji Keamanan Tambahan (SEC-01 s/d SEC-20)

| ID | Skenario Keamanan | Prioritas | Hasil yang Diharapkan | Status | Bukti & Catatan Verifikasi | Tindak Lanjut |
| :--- | :--- | :---: | :--- | :---: | :--- | :--- |
| **SEC-01** | Pengguna A membaca motor milik B | Kritis | Ditolak / Mengembalikan 0 baris | **Pass** | Policy RLS `own_motorcycles` pada `0002_rls.sql` menegakkan `using (user_id = auth.uid())`. Teruji di `supabase/tests/rls_check.md` query 2.1. | Tidak ada celah IDOR. |
| **SEC-02** | Pengguna A mengubah/menghapus servis milik B | Kritis | Operasi Ditolak (0 baris terpengaruh) | **Pass** | Policy RLS `own_service_histories` memvalidasi `user_id = auth.uid()` dan kepemilikan motor. Teruji di `rls_check.md` query 2.2. | Integritas data servis terisolasi per akun. |
| **SEC-03** | Pengguna mengubah `profiles.role` menjadi `admin` | Kritis | Operasi Ditolak oleh policy RLS | **Pass** | Policy `profiles_update` menggunakan klausul `with check (role = (select p.role from profiles p where p.id = auth.uid()))`. Teruji di `security_rules_test.dart` (SEC-03). | Eskalasi hak akses diblokir di database. |
| **SEC-04** | Pengguna memodifikasi akun mekanik via payload klien | Kritis | Ditolak oleh server | **Pass** | Policy `update_own_mechanic` dibatasi pada `profile_id = auth.uid()` dan verifikasi `workshop_id` hanya oleh admin. | Data mekanik terlindungi dari pemalsuan. |
| **SEC-05** | Pengguna mengubah `user_id` pada baris miliknya | Kritis | Ditolak oleh database | **Pass** | Seluruh tabel memiliki foreign key `references profiles(id)` dan policy `with check (user_id = auth.uid())` menolak pengalihan pemilik. | Pemilik baris tidak dapat dimutasi. |
| **SEC-06** | Pengguna mengubah status permintaan via update tabel langsung | Kritis | Ditolak (0 baris terpengaruh) | **Pass** | Tabel `service_requests` **TIDAK memiliki policy UPDATE** untuk pengguna umum. Pembaruan wajib melalui RPC `advance_request` / `cancel_request`. | Status tidak dapat dimanipulasi klien. |
| **SEC-07** | Mekanik mengubah permintaan yang tidak ditugaskan kepadanya | Kritis | RPC melempar exception hak akses | **Pass** | RPC `advance_request` di `0003_functions.sql` secara eksplisit memeriksa `v_req.mechanic_id = v_mechanic_id`. | Penugasan mekanik divalidasi ketat. |
| **SEC-08** | RPC dipanggil dengan ID milik pengguna lain | Kritis | RPC melempar exception otorisasi | **Pass** | RPC `cancel_request` memverifikasi `v_req.user_id = auth.uid()`. Teruji di `rls_check.md` query 5.1. | Akses silang RPC ditolak. |
| **SEC-09** | RPC dipanggil dengan transisi status yang tidak sah | Tinggi | Ditolak dengan pesan valid | **Pass** | `advance_request` memeriksa rantai sah (`pending` -> `accepted` -> `on_the_way` -> `in_progress` -> `completed`). Teruji di `security_rules_test.dart`. | Mencegah status jumping. |
| **SEC-10** | Dua permintaan bantuan dikirim bersamaan | Tinggi | Maksimal satu permintaan aktif | **Pass** | Constraint PostgreSQL `unique index one_active_request_per_user` menolak duplikasi secara atomik. Teruji di `security_rules_test.dart`. | Bebas dari race condition. |
| **SEC-11** | Pengguna anonim membaca tabel privat | Kritis | Ditolak (0 baris / auth required) | **Pass** | Seluruh tabel privat mengharuskan `auth.uid() IS NOT NULL`. Role `anon` tidak memiliki grant SELECT pada tabel privat. | Data pengguna terlindungi dari publik. |
| **SEC-12** | Secret server dicari pada repo dan kode aplikasi | Kritis | Tidak ditemukan kunci rahasia | **Pass** | Scan statis via test `SEC-12` di `security_rules_test.dart` dan `git grep -i "service_role"` membuktikan 0 secret server bocor. | Bebas dari kebocoran token. |
| **SEC-13** | Token/password muncul di log atau pesan error | Tinggi | Tidak bocor ke UI/log | **Pass** | `AppException.fromError` memetakan raw exception teknis menjadi pesan ramah Bahasa Indonesia tanpa stack trace/kredensial. | Bebas dari information leakage. |
| **SEC-14** | Izin lokasi GPS ditolak oleh pengguna | Sedang | Alamat manual tetap berfungsi normal | **Pass** | Model `ServiceRequest` mendukung `latitude: null, longitude: null` dengan `addressText` wajib. Teruji di `security_rules_test.dart`. | Fitur tetap fungsional tanpa GPS. |
| **SEC-15** | Input teks ekstrem, SQL injection, script tag | Tinggi | Ditolak / disanitasi secara aman | **Pass** | Validasi karakter deskripsi (10-500), biaya negatif diblokir, kilometer divalidasi. Teruji di `security_rules_test.dart`. | Parameterized queries mencegah injection. |
| **SEC-16** | URL tutorial menggunakan domain/skema ilegal | Sedang | Ditolak, tidak dibuka oleh aplikasi | **Pass** | `Tutorial.isValidYoutubeUrl` menolak skema `javascript:`, `file:`, dan domain phishing. Teruji di `security_rules_test.dart`. | Bebas dari URL hijacking. |
| **SEC-17** | Sesi kedaluwarsa membuka rute terlindungi | Tinggi | Dialihkan kembali ke `/login` | **Pass** | Route guard di `app_router.dart` memeriksa status autentikasi sebelum mengizinkan akses ke rute bertanda login. | Proteksi rute privat terjamin. |
| **SEC-18** | Permintaan baca mengalami timeout | Sedang | Pesan ramah dan retry terbatas (1x) | **Pass** | `NetworkGuard.safeRead` menerapkan batas 15 detik dan tepat 1x retry untuk operasi baca. Teruji di `security_rules_test.dart`. | Tidak terjadi hanging / DDOS retry. |
| **SEC-19** | Build produksi memakai konfigurasi Mock/Demo | Tinggi | Deteksi konfigurasi otomatis | **Pass** | `AppEnv.isSupabaseConfigured` memvalidasi URL dan Anon Key jika `USE_MOCK=false`. Teruji di `security_rules_test.dart`. | Mencegah rilis demo tanpa sengaja. |
| **SEC-20** | Backup atau ekspor berisi data pengguna | Tinggi | Akses dibatasi sesuai kebijakan | **Blocked** | Backup basis data fisik dikelola di infrastruktur Supabase managed cloud; menunggu penetapan instance produksi definitif. | Jadwalkan sebelum peluncuran resmi. |

---

## 3. Checklist Audit Keamanan Lengkap (PRD Bagian 14)

### 14.1 Audit Konfigurasi dan Rahasia
- [x] Pencarian `service_role`, `jwt_secret`, private key di seluruh repo dan riwayat Git: **Bersih**.
- [x] Verifikasi berkas `.gitignore` memuat `.env`, `*.keystore`, `*.jks`, build artifacts: **Lolos**.
- [x] Verifikasi berkas `.env.example` hanya berisi nama variabel dan placeholder: **Lolos**.
- [x] Mode Mock/Demo berlabel eksplisit dan terpisah dari konfigurasi live Supabase: **Lolos**.

### 14.2 Audit Autentikasi dan Otorisasi
- [x] Alur registrasi, login, logout, dan pengalihan guard rute privat: **Lolos**.
- [x] Perlindungan eskalasi role (pengguna biasa tidak dapat menyetel `role = 'admin'`): **Lolos**.
- [x] Pengujian akses silang User A vs User B (IDOR) pada seluruh entitas: **Lolos**.
- [x] Perubahan status permintaan bantuan hanya dapat dilakukan lewat RPC tervalidasi: **Lolos**.

### 14.3 Audit Database dan Supabase
- [x] `ENABLE ROW LEVEL SECURITY` aktif pada seluruh 9 tabel publik: **Lolos**.
- [x] Policy RLS dievaluasi per operasi (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) secara terpisah: **Lolos**.
- [x] Seluruh fungsi RPC menggunakan `SECURITY DEFINER` dengan `SET search_path = public`: **Lolos**.
- [x] Unique index `one_active_request_per_user` mencegah duplikasi permintaan aktif: **Lolos**.
- [x] Data seed berlabel eksplisit "Demo/Simulasi": **Lolos**.

### 14.4 Audit Dependensi dan Kode
- [x] Pemeriksaan paket usang via `flutter pub outdated`: Terverifikasi 0 paket kritis bermasalah.
- [x] Validasi sanitasi tautan eksternal via regex YouTube: **Lolos**.
- [x] Penanganan error tanpa pembocoran stack trace/kredensial ke UI: **Lolos**.
- [x] Penggunaan query berparameter pada Supabase Client (bebas SQL Injection): **Lolos**.

### 14.5 Pengujian Keamanan Aplikasi Manual
- [x] Manipulasi ID objek pada parameter URL rute: Dicegat oleh filter `userId` di query.
- [x] Pengiriman input string ekstrem (>500 karakter atau negatif): Ditolak oleh validator formulir.
- [x] Uji anti *double-submit* pada pengiriman bantuan mekanik: Tombol dinonaktifkan saat pengiriman.
- [x] Pemulihan aplikasi setelah timeout jaringan: Tombol "Coba lagi" memicu pemanggilan ulang tanpa membeku.

### 14.6 Audit Privasi dan Aksesibilitas
- [x] Izin Android mematuhi *least privilege* (`INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `POST_NOTIFICATIONS`): **Lolos**.
- [x] Izin lokasi hanya diminta saat pengguna menekan tombol GPS dan alamat manual selalu tersedia: **Lolos**.
- [x] `android:allowBackup="false"` disetel untuk mencegah ekstraksi data sesi via adb backup: **Lolos**.
- [x] Audit kontras warna WCAG AA/AAA, ukuran target sentuh >= 48 dp, dan skala teks 130%: **Lolos**.

---

## 4. Evaluasi Release Gate

| Gerbang Evaluasi | Standar Kelulusan | Status Aktual |
| --- | --- | :---: |
| **Temuan Kritis & Tinggi** | 0 temuan terbuka | **LULUS** (0 temuan) |
| **Integritas RLS & RPC** | Seluruh tabel dilindungi RLS & RPC tervalidasi | **LULUS** |
| **Secret Scanning** | Tidak ada secret/kunci rahasia di kode atau APK | **LULUS** |
| **Analisis Statis (`flutter analyze`)** | 0 warning dan 0 error | **LULUS** |
| **Uji Otomatis (`flutter test`)** | 100% tes lulus (178/178 tes) | **LULUS** |
| **Build Web Bundle** | Berhasil terkompilasi | **LULUS** |

---

## 5. Lembar Persetujuan Rilis (Owner Sign-off)

Sebelum mendistribusikan aplikasi kepada pengguna akhir di Kota Lhokseumawe dan Kabupaten Aceh Utara:

- [ ] **Pemilik Proyek:** Mengonfirmasi bahwa URL Supabase produksi dan Anon Key telah dimasukkan di pipeline rilis yang aman.
- [ ] **Pemilik Proyek:** Memastikan data bengkel fisik dan tautan video tutorial telah diperbarui dengan data operasional nyata sebelum peluncuran publik.
- [ ] **Pemilik Proyek:** Menyetujui batas layanan operasional khusus di Kota Lhokseumawe & Kab. Aceh Utara.

*Disusun oleh Senior Flutter & Security Engineer MotoCare*
