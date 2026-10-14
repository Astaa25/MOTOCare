# Log Temuan Keamanan & Tindakan Perbaikan MotoCare (Milestone M9)

Dokumen ini mencatat seluruh temuan keamanan yang teridentifikasi selama audit Milestone M9, tingkat keparahan, akar penyebab (*root cause*), tindakan perbaikan yang telah diterapkan (*remediation*), dan tes regresi terkait sesuai PRD Bagian 16.

---

## 1. Ringkasan Status Temuan

| Tingkat Keparahan | Total Teridentifikasi | Status Selesai / Ditutup | Status Terbuka |
| :--- | :---: | :---: | :---: |
| **Kritis (Critical)** | 0 | 0 | 0 |
| **Tinggi (High)** | 0 | 0 | 0 |
| **Sedang (Medium)** | 1 | 1 | 0 |
| **Rendah (Low)** | 1 | 1 | 0 |
| **Total** | **2** | **2** | **0** |

> **Catatan Kelulusan Release Gate:** Seluruh temuan yang teridentifikasi selama Milestone M9 telah berhasil diperbaiki, diverifikasi ulang, dan disertai tes regresi otomatis. Tidak ada temuan terbuka berkategori Kritis, Tinggi, maupun Sedang.

---

## 2. Rincian Temuan & Tindakan Perbaikan

### FINDING-01: Bypass Validasi Tanda Negatif pada Input Biaya Servis
- **ID:** FINDING-01
- **Tingkat Keparahan:** Sedang (*Medium*)
- **Komponen:** `lib/core/utils/validators.dart` (`AppValidators.validateCost`)
- **Dampak:** Pengguna dapat memasukkan nilai biaya bertanda minus (contoh: `-5000`) karena fungsi pembersihan `value.replaceAll(RegExp(r'[^0-9]'), '')` menghapus karakter minus sebelum pengujian `amount < 0`, sehingga string `-5000` diubah menjadi `5000` dan lolos validasi form sebagai angka positif.
- **Akar Penyebab (*Root Cause*):** Pembersihan string angka dilakukan sebelum pengecekan karakter tanda negatif.
- **Tindakan Perbaikan (*Remediation*):**
  Menambahkan pengecekan eksplisit karakter minus sebelum pembersihan regex angka:
  ```dart
  final trimmed = value.trim();
  if (trimmed.contains('-')) {
    return 'Biaya servis tidak boleh negatif';
  }
  ```
- **Tes Regresi Otomatis:**
  Diverifikasi di [security_rules_test.dart](file:///d:/.Mine/Informatic%20engineering/MOTOCARE/test/features/security/security_rules_test.dart) baris 180:
  ```dart
  expect(AppValidators.validateCost('-5000'), isNotNull);
  ```
- **Status:** **TERTUTUP (RESOLVED)**

---

### FINDING-02: Konfigurasi Default Android Backup Memungkinkan Ekstraksi Data Lokal
- **ID:** FINDING-02
- **Tingkat Keparahan:** Rendah (*Low*)
- **Komponen:** `android/app/src/main/AndroidManifest.xml`
- **Dampak:** Tanpa deklarasi eksplisit `android:allowBackup="false"`, sistem Android mengizinkan pembuatan cadangan aplikasi (*adb backup*), yang berpotensi mengekspos cache lokal aplikasi pada perangkat yang terhubung melalui antarmuka debug.
- **Akar Penyebab (*Root Cause*):** Nilai default atribut `allowBackup` pada elemen `<application>` di Android adalah `true` jika tidak ditentukan secara eksplisit.
- **Tindakan Perbaikan (*Remediation*):**
  Menambahkan `android:allowBackup="false"` secara eksplisit pada tag `<application>` di [AndroidManifest.xml](file:///d:/.Mine/Informatic%20engineering/MOTOCARE/android/app/src/main/AndroidManifest.xml).
- **Verifikasi:**
  Inspeksi manifes membuktikan `android:allowBackup="false"` aktif dan membatasi izin hanya pada 4 izin *least privilege* (`INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `POST_NOTIFICATIONS`).
- **Status:** **TERTUTUP (RESOLVED)**

---

## 3. Matriks Mitigasi Risiko Residual

| Risiko Residual | Mitigasi yang Diterapkan | Status Penerimaan Risiko |
| :--- | :--- | :--- |
| **Ketergantungan Supabase Cloud** | Menggunakan arsitektur repository berantarmuka (`abstract class`) dengan isolasi implementasi Supabase vs Mock sehingga aplikasi tetap tangguh saat koneksi terputus. | Diterima oleh desain produk |
| **Kehilangan Koneksi GPS saat Panggilan Darurat** | Aplikasi menyediakan form input alamat manual yang selalu aktif tanpa mengharuskan izin lokasi GPS. | Mitigasi lengkap |
| **Pencurian Perangkat Fisik Pengguna** | Token sesi disimpan menggunakan enkripsi hardware-backed `flutter_secure_storage` dan sesi dapat di-revoke dari dashboard Supabase. | Mitigasi lengkap |
