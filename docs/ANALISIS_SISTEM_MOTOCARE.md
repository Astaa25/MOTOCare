# DOKUMEN ANALISIS DAN PERANCANGAN SISTEM MOTOCARE
**Aplikasi Motorcycle Care (Layanan Bantuan Montir & Perawatan Motor)**  
*Tahap: Analisis Sistem (Minggu 6–7)*  
*Wilayah Layanan: Kota Lhokseumawe dan Kabupaten Aceh Utara*  
*Target Platform: Android (Flutter & Supabase / Mock Architecture)*

---

## 1. Gambaran Umum Sistem

**MotoCare (Motorcycle Care)** merupakan aplikasi berbasis *mobile* yang dirancang untuk membantu pengendara sepeda motor mendapatkan bantuan mekanik ketika mengalami kerusakan atau kendala di perjalanan. Aplikasi ini berfokus pada layanan pemanggilan montir berdasarkan lokasi pengguna, terutama ketika pengguna mengalami masalah di daerah yang jauh dari bengkel.

MotoCare juga menyediakan fitur pendukung berupa:
1. **Pencarian Bengkel Terdekat**: Menggunakan Google Maps Platform untuk direktori bengkel di wilayah Kota Lhokseumawe dan Kabupaten Aceh Utara.
2. **Pengelolaan Data Kendaraan**: Manajemen multi-kendaraan dengan pencatatan merek, model, tahun, pelat nomor, dan pembaruan kilometer berkala.
3. **Pencatatan Riwayat Servis**: Pencatatan log servis berkala, komponen yang diganti, serta rincian biaya jasa dan suku cadang.
4. **Pengingat Perawatan & Notifikasi**: Pengingat berbasis kalender dan kilometer (*mileage threshold*), serta notifikasi *in-app* untuk perubahan status pemanggilan montir.
5. **Tutorial Perawatan Motor**: Panduan edukasi servis mandiri melalui kurasi video YouTube resmi beserta peringatan keselamatan kerja.

Aplikasi dirancang menggunakan pendekatan **Object-Oriented Programming (OOP)**, arsitektur *Clean Architecture / Feature-First*, antarmuka modern dengan font *Plus Jakarta Sans*, dominasi warna putih, gradasi oranye muda (*Warm Coral* `#FF5733`), dan abu-abu arang modern (`#2D3142`).

---

## 2. Analisis Permasalahan dan Solusi

### 2.1 Analisis Permasalahan
1. **Kendala Darurat di Perjalanan**: Pengendara motor kerap mengalami mogok, ban bocor, atau rantai putus di lokasi yang jauh dari pemukiman dan bengkel konvensional.
2. **Kesulitan Mendapatkan Mekanik Panggilan**: Belum ada sistem terpadu untuk menghubungkan pengendara dengan mekanik yang bersedia datang ke lokasi kejadian di wilayah Lhokseumawe dan Aceh Utara.
3. **Ketidakpastian Biaya dan Status**: Kurangnya transparansi mengenai estimasi biaya perbaikan dan ketidakpastian apakah mekanik sedang menuju ke lokasi.
4. **Disorientasi Lokasi Bengkel**: Pengendara yang sedang melintas di jalur lintas Sumatra sering tidak mengetahui bengkel terdekat yang masih buka.
5. **Kelalaian Perawatan Berkala**: Pengendara sering lupa mengganti oli mesin, kampas rem, atau transmisi CVT karena ketiadaan catatan riwayat dan pengingat kilometer.

### 2.2 Solusi yang Ditawarkan
- **Fitur Utama (Panggil Montir)**: Memungkinkan pengguna mengajukan permintaan darurat dengan deteksi lokasi GPS otomatis atau input manual, memilih jenis kendala, dan memantau status secara *real-time* (*Menunggu*, *Diterima*, *Ditolak*, *Sedang Ditangani*, *Selesai*).
- **Fitur Pendukung Terpadu**: Direktori bengkel lokal terverifikasi, pencatatan servis terpadu dengan odometer otomatis, pengingat preventif berbasis odometer, serta video tutorial edukasi.
- **Kepatuhan Data & Simulasi**: Selama tahap pengembangan, mekanik dan data simulasi diberi label eksplisit *"Demo / Simulasi"* agar tidak menyesatkan pengguna.

---

## 3. Analisis Kebutuhan Sistem

### 3.1 Kebutuhan Fungsional (Functional Requirements)
- **FR-01 (Autentikasi & Akun)**: Registrasi akun baru, login berbasis peran (Pemilik Kendaraan, Mekanik, Admin), verifikasi kredensial, dan manajemen profil.
- **FR-02 (Panggil Montir - Core)**: Pengajuan bantuan montir darurat, deteksi koordinat GPS kejadian, pemilihan motor, pemilihan jenis kendala, input deskripsi kerusakan, dan alur konfirmasi mekanik.
- **FR-03 (Pencarian Bengkel)**: Menampilkan daftar dan peta bengkel di Kota Lhokseumawe dan Kab. Aceh Utara, navigasi rute eksternal (*Google Maps*), dan informasi kontak/jam operasional.
- **FR-04 (Manajemen Kendaraan)**: CRUD data sepeda motor (merek, model, tahun produksi, nomor pelat, odometer kilometer) serta konfirmasi koreksi kilometer.
- **FR-05 (Riwayat Servis & Biaya)**: Pencatatan tanggal servis, kilometer saat servis, kategori tindakan, rincian biaya suku cadang dan jasa, serta sinkronisasi ke kilometer kendaraan.
- **FR-06 (Pengingat Servis & Notifikasi)**: Penjadwalan pengingat servis otomatis berbasis tanggal atau batas kilometer, serta pusat notifikasi *in-app*.
- **FR-07 (Tutorial Perawatan)**: Katalog tutorial berbasis kategori (oli, rem, aki, ban, rantai, mesin) dengan tautan video YouTube resmi dan peringatan keselamatan (*safety warning*).
- **FR-08 (Kelola Mekanik - Admin)**: Administrator dapat mengelola pendaftaran, spesialisasi keahlian, wilayah jangkauan, dan status ketersediaan mekanik.

### 3.2 Kebutuhan Nonfungsional (Non-Functional Requirements)
- **Usability**: UI intuitif berbasis palet putih-oranye (*Warm Coral*), tombol CTA Panggil Montir terlihat menonjol di *Home*, tipografi Plus Jakarta Sans.
- **Performance**: Waktu respon halaman lokal < 1 detik, indikator skeleton loading, durasi splash screen 3–5 detik.
- **Security & Privacy**: Otorisasi data berbasis peran dan kepemilikan (*Supabase Row Level Security / RLS*), izin akses lokasi GPS hanya saat aplikasi digunakan, enkripsi kata sandi.
- **Reliability**: Penanganan *offline fallback*, validasi input form sebelum kirim, pembatalan permintaan montir otomatis jika batas waktu 15 menit tercapai tanpa respon (*timeout*).
- **Service Boundary**: Pembatasan wilayah layanan ketat pada Kota Lhokseumawe dan Kabupaten Aceh Utara.

---

## 4. Analisis Pengguna dan Aktor

| Aktor | Deskripsi Peran | Hak Akses Utama |
| :--- | :--- | :--- |
| **Pemilik Kendaraan** | Pengguna umum pengendara motor di wilayah Lhokseumawe & Aceh Utara | Registrasi/Login, memanggil montir, mencari bengkel, mengelola motor & riwayat servis, menerima pengingat. |
| **Mekanik** | Penyedia jasa servis panggilan yang terdaftar | Login, menerima/menolak panggilan montir darurat, memberikan estimasi biaya, memperbarui status penanganan, menandai servis selesai. |
| **Admin** | Pengelola sistem dan verifikator operasional | Login, mengelola data mekanik, memverifikasi bengkel rekanan, memantau riwayat layanan. |

---

## 5. Use Case Modeling

### 5.1 Use Case Diagram
Berikut diagram interaksi antar-aktor dengan modul use case sistem MotoCare:

```mermaid
flowchart LR
    subgraph Aktor
        U["Pemilik Kendaraan"]
        M["Mekanik"]
        A["Admin"]
    end

    subgraph Sistem_MotoCare["Sistem MotoCare"]
        UC01(["UC-01: Registrasi Akun"])
        UC02(["UC-02: Login Akun"])
        UC03(["UC-03: Panggil Montir Darurat"])
        UC04(["UC-04: Cari Bengkel Terdekat"])
        UC05(["UC-05: Kelola Data Kendaraan"])
        UC06(["UC-06: Kelola Riwayat Servis"])
        UC07(["UC-07: Kelola Data Mekanik"])
        UC08(["UC-08: Pengingat & Notifikasi"])
        UC09(["UC-09: Lihat Tutorial Perawatan"])
    end

    U --> UC01
    U --> UC02
    U --> UC03
    U --> UC04
    U --> UC05
    U --> UC06
    U --> UC08
    U --> UC09

    M --> UC02
    M --> UC03

    A --> UC02
    A --> UC07
```

---

### 5.2 Skenario Use Case Lengkap

#### UC-01: Skenario Registrasi Akun
| Identifikasi | Rincian |
| :--- | :--- |
| **No Use Case** | UC-01 |
| **Nama** | Registrasi Akun |
| **Tujuan** | Mendaftarkan akun pengguna baru ke dalam sistem MotoCare |
| **Aktor** | Pemilik Kendaraan |
| **Kondisi Awal** | Aplikasi menampilkan halaman Registrasi |
| **Kondisi Akhir** | Akun tersimpan dan diarahkan ke halaman Login |

**Skenario Utama**:
| Aksi Aktor | Reaksi Sistem |
| :--- | :--- |
| 1. Membuka halaman registrasi | 2. Menampilkan formulir pendaftaran akun |
| 3. Mengisi nama lengkap, email, dan kata sandi | 4. Melakukan validasi format data |
| 5. Menekan tombol "Daftar Sekarang" | 6. Menyimpan akun baru ke basis data |
|  | 7. Menampilkan pesan registrasi berhasil dan mengarahkan ke halaman Login |

**Skenario Alternatif**:
| Skenario Alternatif | Reaksi Sistem |
| :--- | :--- |
| 4a. Format email salah atau password kurang dari 8 karakter | Sistem menampilkan pesan validasi spesifik di bawah *text field*. |
| 4b. Email sudah terdaftar di sistem | Sistem menampilkan pesan kesalahan "Email sudah digunakan" dan meminta pengguna menggunakan email lain atau login. |

---

#### UC-02: Skenario Login Akun
| Identifikasi | Rincian |
| :--- | :--- |
| **No Use Case** | UC-02 |
| **Nama** | Login Akun |
| **Tujuan** | Memverifikasi identitas pengguna untuk mengakses sistem |
| **Aktor** | Pemilik Kendaraan, Mekanik, Admin |
| **Kondisi Awal** | Aplikasi menampilkan form login |
| **Kondisi Akhir** | Pengguna berhasil masuk dan dashboard ditampilkan sesuai peran |

**Skenario Utama**:
| Aksi Aktor | Reaksi Sistem |
| :--- | :--- |
| 1. Membuka halaman login | 2. Menampilkan form input email dan kata sandi |
| 3. Memasukkan email dan kata sandi | 4. Memverifikasi kredensial akun |
| 5. Menekan tombol "Masuk" | 6. Menginisialisasi sesi pengguna |
|  | 7. Menampilkan halaman utama sesuai peran aktor (Dashboard Pemilik / Mekanik / Admin) |

**Skenario Alternatif**:
| Skenario Alternatif | Reaksi Sistem |
| :--- | :--- |
| 4a. Email atau password tidak cocok | Sistem menampilkan pesan peringatan "Email atau kata sandi tidak valid" dan tetap di halaman login. |

---

#### UC-03: Skenario Panggil Montir
| Identifikasi | Rincian |
| :--- | :--- |
| **No Use Case** | UC-03 |
| **Nama** | Panggil Montir Darurat |
| **Tujuan** | Mengirimkan permintaan montir darurat ke lokasi kerusakan kendaraan |
| **Aktor** | Pemilik Kendaraan, Mekanik |
| **Kondisi Awal** | Pemilik kendaraan telah login dan berada di halaman utama |
| **Kondisi Akhir** | Permintaan tersimpan, dikonfirmasi mekanik, dan status terpantau |

**Skenario Utama**:
| Aksi Aktor | Reaksi Sistem |
| :--- | :--- |
| 1. Memilih menu / tombol "Panggil Montir" di halaman utama | 2. Menampilkan formulir permintaan dan meminta izin akses lokasi (GPS) |
| 3. Memilih motor, kategori kendala, lokasi, dan mengisi deskripsi | 4. Memvalidasi data dan mencari mekanik yang tersedia di wilayah jangkauan |
| 5. Menekan tombol "Kirim Permintaan Bantuan" | 6. Menyimpan permintaan dengan status `MENUNGGU` dan meneruskannya ke antrean mekanik |
| 7. Memantau status permintaan di layar pantau | 8. Mekanik menerima permintaan dengan estimasi biaya; status berubah menjadi `DITERIMA` |
| 9. Menunggu mekanik melakukan perbaikan di lokasi | 10. Mekanik menandai perbaikan selesai; status berubah menjadi `SELESAI` |
| 11. (Opsional) Memberikan ulasan dan penilaian | 12. Menyimpan ulasan ke sistem |

**Skenario Alternatif**:
| Skenario Alternatif | Reaksi Sistem |
| :--- | :--- |
| 4a. Data tidak lengkap atau tidak ada mekanik tersedia | Menampilkan pesan "Mekanik belum tersedia di area Anda" dan menyarankan mencari bengkel terdekat. |
| 8a. Mekanik menolak permintaan | Sistem mengubah status menjadi `DITOLAK`, mengirim notifikasi penolakan beserta alasan ke pemilik kendaraan. |
| 8b. Tidak ada respon dalam 15 menit (timeout) | Sistem mengubah status menjadi `KEDALUWARSA` dan menyajikan alternatif tombol darurat / bengkel terdekat. |

---

#### UC-04: Skenario Cari Bengkel Terdekat
| Identifikasi | Rincian |
| :--- | :--- |
| **No Use Case** | UC-04 |
| **Nama** | Cari Bengkel Terdekat |
| **Tujuan** | Menemukan bengkel motor resmi/umum di wilayah Lhokseumawe dan Aceh Utara |
| **Aktor** | Pemilik Kendaraan |
| **Kondisi Awal** | Pengguna membuka menu "Bengkel" |
| **Kondisi Akhir** | Daftar dan detail bengkel ditampilkan serta dapat dibuka di peta |

**Skenario Utama**:
| Aksi Aktor | Reaksi Sistem |
| :--- | :--- |
| 1. Memilih menu "Bengkel Terdekat" | 2. Meminta izin GPS dan membaca koordinat pengguna |
| 3. Memfilter bengkel berdasarkan radius atau kata kunci | 4. Mengambil data tempat bengkel sesuai cakupan wilayah layanan |
| 5. Melihat daftar bengkel dan peta | 6. Menampilkan kartu bengkel lengkap (nama, alamat, rating, jam buka) |
| 7. Memilih salah satu bengkel | 8. Menampilkan detail kontak, layanan servis, dan tombol petunjuk arah |
| 9. Menekan tombol "Petunjuk Arah" | 10. Membuka navigasi rute melalui Google Maps eksternal |

**Skenario Alternatif**:
| Skenario Alternatif | Reaksi Sistem |
| :--- | :--- |
| 2a. Layanan GPS tidak diizinkan atau dinonaktifkan | Sistem menampilkan prompt lokasi dan memungkinkan filter berdasarkan kota/kecamatan manual. |
| 4a. Lokasi berada di luar Lhokseumawe dan Aceh Utara | Sistem menampilkan pesan informasi bahwa lokasi saat ini di luar cakupan layanan MotoCare. |

---

#### UC-05: Skenario Kelola Data Kendaraan
| Identifikasi | Rincian |
| :--- | :--- |
| **No Use Case** | UC-05 |
| **Nama** | Kelola Data Kendaraan |
| **Tujuan** | Menambah, mengubah, dan menghapus data sepeda motor pengguna |
| **Aktor** | Pemilik Kendaraan |
| **Kondisi Awal** | Pengguna berada di menu "Motor Saya" |
| **Kondisi Akhir** | Data kendaraan tersimpan dan daftar kendaraan terbarui |

**Skenario Utama**:
| Aksi Aktor | Reaksi Sistem |
| :--- | :--- |
| 1. Membuka menu "Motor Saya" | 2. Menampilkan daftar sepeda motor terdaftar |
| 3. Memilih "Tambah Motor" | 4. Menampilkan formulir input kendaraan |
| 5. Mengisi merek, model, tahun pembuatan, nomor pelat, dan kilometer | 6. Memvalidasi data yang dimasukkan |
| 7. Menekan "Simpan" | 8. Menyimpan data motor dan memperbarui tampilan daftar motor |
| 9. (Alternatif Edit) Memilih motor dan mengubah data | 10. Memvalidasi dan memperbarui data motor |
| 11. (Alternatif Hapus) Menekan tombol hapus motor | 12. Menampilkan dialog konfirmasi penghapusan |
| 13. Mengonfirmasi hapus | 14. Menghapus motor dari database dan memperbarui daftar motor |

**Skenario Alternatif**:
| Skenario Alternatif | Reaksi Sistem |
| :--- | :--- |
| 6a. Kilometer yang dimasukkan lebih rendah dari catatan sebelumnya | Sistem memunculkan dialog konfirmasi koreksi odometer sebelum menyimpan. |

---

#### UC-06: Skenario Kelola Riwayat Servis
| Identifikasi | Rincian |
| :--- | :--- |
| **No Use Case** | UC-06 |
| **Nama** | Kelola Riwayat Servis & Biaya |
| **Tujuan** | Mencatat dan memantau riwayat servis serta pengeluaran biaya perawatan |
| **Aktor** | Pemilik Kendaraan |
| **Kondisi Awal** | Pengguna berada di menu "Riwayat Servis" |
| **Kondisi Akhir** | Catatan servis baru tersimpan dan odometer motor terupdate |

**Skenario Utama**:
| Aksi Aktor | Reaksi Sistem |
| :--- | :--- |
| 1. Membuka menu "Riwayat Servis" | 2. Menampilkan daftar riwayat servis berdasarkan motor |
| 3. Memilih tombol "Catat Servis Baru" | 4. Menampilkan formulir pencatatan servis |
| 5. Mengisi tanggal servis, kilometer saat servis, rincian tindakan, biaya jasa, dan suku cadang | 6. Memvalidasi kelengkapan form |
| 7. Menekan tombol "Simpan Riwayat" | 8. Menyimpan riwayat servis ke database dan menyinkronkan kilometer terbaru ke data motor |
|  | 9. Menampilkan kembali daftar riwayat servis yang sudah terbarui |

---

#### UC-07: Skenario Kelola Data Mekanik (Admin)
| Identifikasi | Rincian |
| :--- | :--- |
| **No Use Case** | UC-07 |
| **Nama** | Kelola Data Mekanik |
| **Tujuan** | Mengelola profil, wilayah jangkauan, dan keahlian mekanik rekanan |
| **Aktor** | Administrator |
| **Kondisi Awal** | Admin berada di menu manajemen mekanik |
| **Kondisi Akhir** | Data mekanik tersimpan, terbarui, atau dihapus |

**Skenario Utama**:
| Aksi Aktor | Reaksi Sistem |
| :--- | :--- |
| 1. Membuka menu manajemen data mekanik | 2. Menampilkan daftar mekanik yang terdaftar |
| 3. Memilih "Tambah Mekanik" | 4. Menampilkan formulir data profil mekanik |
| 5. Mengisi nama, keahlian khusus, nomor kontak, dan wilayah operasional | 6. Memvalidasi format isian data |
| 7. Menekan tombol "Simpan" | 8. Menyimpan data mekanik baru dan menyegarkan daftar |
| 9. (Opsi Edit) Memilih mekanik, mengubah status atau keahlian | 10. Memperbarui data mekanik |
| 11. (Opsi Hapus) Memilih mekanik dan menekan hapus | 12. Meminta konfirmasi dan menghapus data mekanik |

---

## 6. Activity Diagram Modeling

Berikut adalah 7 Activity Diagram lengkap untuk seluruh alur aktivitas utama sistem MotoCare.

### 6.1 Activity Diagram Registrasi

```mermaid
flowchart TD
    Start([Mulai]) --> A1["Pengguna: Buka Halaman Registrasi"]
    A1 --> S1["Sistem: Tampilkan Form Registrasi"]
    S1 --> A2["Pengguna: Masukkan Nama, Email, dan Password"]
    A2 --> A3["Pengguna: Klik Daftar"]
    A3 --> S2{"Sistem: Validasi Data Registrasi"}
    
    S2 -- "Data Tidak Valid / Format Salah" --> S3["Sistem: Tampilkan Pesan Kesalahan"]
    S3 --> A2
    
    S2 -- "Email Sudah Terdaftar" --> S4["Sistem: Tampilkan Notifikasi Email Duplikat"]
    S4 --> A2
    
    S2 -- "Data Valid" --> S5["Sistem: Enkripsi Password & Simpan Akun"]
    S5 --> S6["Sistem: Tampilkan Notifikasi Sukses & Arahkan ke Login"]
    S6 --> EndNode([Selesai])
```

---

### 6.2 Activity Diagram Login

```mermaid
flowchart TD
    Start([Mulai]) --> A1["Pengguna: Buka Halaman Login"]
    A1 --> S1["Sistem: Tampilkan Form Login"]
    S1 --> A2["Pengguna: Masukkan Email & Password"]
    A2 --> A3["Pengguna: Klik Tombol Masuk"]
    A3 --> S2{"Sistem: Verifikasi Kredensial"}
    
    S2 -- "Kredensial Tidak Cocok" --> S3["Sistem: Tampilkan Peringatan Gagal Login"]
    S3 --> A2
    
    S2 -- "Kredensial Sesuai" --> S4["Sistem: Bentuk Sesi & Identifikasi Peran"]
    S4 --> S5{"Peran Pengguna?"}
    
    S5 -- "Pemilik Kendaraan" --> S6["Sistem: Tampilkan Dashboard Pemilik Motor"]
    S5 -- "Mekanik" --> S7["Sistem: Tampilkan Dashboard Permintaan Mekanik"]
    S5 -- "Admin" --> S8["Sistem: Tampilkan Panel Administrasi"]
    
    S6 --> EndNode([Selesai])
    S7 --> EndNode
    S8 --> EndNode
```

---

### 6.3 Activity Diagram Panggil Montir (Fitur Utama)

```mermaid
flowchart TD
    Start([Mulai]) --> A1["Pemilik: Pilih Menu Panggil Montir"]
    A1 --> S1["Sistem: Minta Izin Lokasi GPS & Tampilkan Form"]
    S1 --> A2["Pemilik: Pilih Motor, Kategori Masalah, Lokasi, & Catatan"]
    A2 --> A3["Pemilik: Tekan Kirim Permintaan"]
    A3 --> S2{"Sistem: Validasi Form & Cek Jangkauan"}
    
    S2 -- "Form Tidak Valid / Luar Jangkauan" --> S3["Sistem: Tampilkan Error & Sarankan Cari Bengkel"]
    S3 --> A2
    
    S2 -- "Valid & Ada Mekanik" --> S4["Sistem: Simpan Permintaan Status: MENUNGGU"]
    S4 --> S5["Sistem: Broadcast Notifikasi ke Mekanik Terdekat"]
    S5 --> M1["Mekanik: Periksa Detail Permintaan & Lokasi"]
    
    M1 --> M2{"Mekanik: Respon Permintaan?"}
    
    M2 -- "Tolak Permintaan" --> M3["Mekanik: Pilih Alasan Penolakan"]
    M3 --> S6["Sistem: Ubah Status Permintaan: DITOLAK"]
    S6 --> A4["Pemilik: Terima Notifikasi Penolakan & Opsi Lain"]
    A4 --> EndFail([Selesai / Batal])
    
    M2 -- "Terima Permintaan" --> M4["Mekanik: Masukkan Estimasi Biaya & Konfirmasi"]
    M4 --> S7["Sistem: Ubah Status Permintaan: DITERIMA"]
    S7 --> A5["Pemilik: Terima Notifikasi & Detail Montir"]
    A5 --> M5["Mekanik: Berangkat Menuju Lokasi & Tangani Kerusakan"]
    M5 --> M6["Mekanik: Selesaikan Pekerjaan & Tekan Selesai"]
    M6 --> S8["Sistem: Ubah Status Permintaan: SELESAI"]
    S8 --> A6["Pemilik: Lihat Rangkuman Servis & Berikan Penilaian"]
    A6 --> EndSuccess([Selesai])
```

---

### 6.4 Activity Diagram Cari Bengkel Terdekat

```mermaid
flowchart TD
    Start([Mulai]) --> A1["Pengguna: Buka Menu Bengkel Terdekat"]
    A1 --> S1["Sistem: Minta Izin GPS & Baca Koordinat"]
    S1 --> S2{"GPS Aktif & Diizinkan?"}
    
    S2 -- "Tidak" --> S3["Sistem: Tampilkan Pilihan Kota Manual: Lhokseumawe / Aceh Utara"]
    S2 -- "Ya" --> S4["Sistem: Ambil Koordinat Presisi"]
    
    S3 --> S5["Sistem: Query Direktori Bengkel Terverifikasi"]
    S4 --> S5
    
    S5 --> S6{"Hasil Ditemukan?"}
    S6 -- "Tidak Ada di Radius" --> S7["Sistem: Tampilkan Info 'Bengkel tidak ditemukan di area ini'"]
    S7 --> EndFail([Selesai])
    
    S6 -- "Ada" --> S8["Sistem: Tampilkan Daftar Bengkel & Pin Peta"]
    S8 --> A2["Pengguna: Pilih Salah Satu Bengkel"]
    A2 --> S9["Sistem: Tampilkan Detail Kontak, Layanan, & Alamat"]
    S9 --> A3{"Pengguna: Butuh Rute?"}
    
    A3 -- "Ya" --> S10["Sistem: Buka Google Maps dengan Koordinat Tujuan"]
    A3 -- "Tidak" --> EndSuccess([Selesai])
    S10 --> EndSuccess
```

---

### 6.5 Activity Diagram Data Kendaraan

```mermaid
flowchart TD
    Start([Mulai]) --> A1["Pengguna: Buka Menu Motor Saya"]
    A1 --> S1["Sistem: Tampilkan Daftar Sepeda Motor Terdaftar"]
    S1 --> A2{"Aksi Pengguna?"}
    
    A2 -- "Tambah Motor" --> A3["Pengguna: Isi Merek, Model, Tahun, Pelat, & Kilometer"]
    A3 --> S2{"Sistem: Validasi Data"}
    S2 -- "Tidak Valid" --> S3["Sistem: Tampilkan Pesan Kesalahan"]
    S3 --> A3
    S2 -- "Valid" --> S4["Sistem: Simpan Data Motor Baru ke Database"]
    S4 --> S5["Sistem: Segarkan Tampilan Daftar Motor"]
    
    A2 -- "Ubah Motor" --> A4["Pengguna: Pilih Motor & Ubah Data / Update KM"]
    A4 --> S6{"Sistem: Kilometer Lebih Rendah?"}
    S6 -- "Ya" --> A5["Pengguna: Konfirmasi Koreksi Odometer"]
    A5 --> S7["Sistem: Update Data Motor"]
    S6 -- "Tidak" --> S7
    S7 --> S5
    
    A2 -- "Hapus Motor" --> A6["Pengguna: Pilih Hapus Motor"]
    A6 --> S8["Sistem: Tampilkan Dialog Konfirmasi Hapus"]
    S8 --> A7{"Pengguna: Konfirmasi Hapus?"}
    A7 -- "Batal" --> S1
    A7 -- "Ya, Hapus" --> S9["Sistem: Hapus Data Motor & Relasi Terkait"]
    S9 --> S5
    
    S5 --> EndNode([Selesai])
```

---

### 6.6 Activity Diagram Riwayat Servis

```mermaid
flowchart TD
    Start([Mulai]) --> A1["Pengguna: Buka Menu Riwayat Servis"]
    A1 --> S1["Sistem: Tampilkan Daftar Servis per Kendaraan"]
    S1 --> A2{"Aksi Pengguna?"}
    
    A2 -- "Lihat Detail" --> A3["Pengguna: Pilih Catatan Servis"]
    A3 --> S2["Sistem: Tampilkan Rincian Komponen, Bengkel, & Biaya"]
    S2 --> EndNode([Selesai])
    
    A2 -- "Catat Servis Baru" --> A4["Pengguna: Isi Tanggal, Kilometer, Tindakan, & Biaya"]
    A4 --> S3{"Sistem: Validasi Input Form"}
    S3 -- "Tidak Valid" --> S4["Sistem: Tampilkan Pesan Error Form"]
    S4 --> A4
    S3 -- "Valid" --> S5["Sistem: Simpan Catatan Servis ke Database"]
    S5 --> S6["Sistem: Update Kilometer Terkini pada Data Motor"]
    S6 --> S7["Sistem: Evaluasi Ulang Pengingat Servis Terkait"]
    S7 --> S8["Sistem: Tampilkan Daftar Riwayat Servis Terupdate"]
    S8 --> EndNode
```

---

### 6.7 Activity Diagram Data Mekanik (Admin)

```mermaid
flowchart TD
    Start([Mulai]) --> A1["Admin: Buka Menu Kelola Mekanik"]
    A1 --> S1["Sistem: Tampilkan Daftar Mekanik Terdaftar"]
    S1 --> A2{"Aksi Admin?"}
    
    A2 -- "Tambah Mekanik" --> A3["Admin: Input Profil, Spesialisasi, No Telp, Wilayah"]
    A3 --> S2{"Sistem: Validasi Data"}
    S2 -- "Tidak Valid" --> S3["Sistem: Tampilkan Pesan Error"]
    S3 --> A3
    S2 -- "Valid" --> S4["Sistem: Simpan Data Mekanik Baru"]
    S4 --> S5["Sistem: Segarkan Daftar Mekanik"]
    
    A2 -- "Ubah Mekanik" --> A4["Admin: Pilih Mekanik & Ubah Data / Status Ketersediaan"]
    A4 --> S6["Sistem: Update Data Mekanik"]
    S6 --> S5
    
    A2 -- "Hapus Mekanik" --> A5["Admin: Pilih Hapus Mekanik"]
    A5 --> S7["Sistem: Tampilkan Konfirmasi Penghapusan"]
    S7 --> A6{"Admin: Konfirmasi Hapus?"}
    A6 -- "Batal" --> S1
    A6 -- "Ya" --> S8["Sistem: Hapus Data Mekanik"]
    S8 --> S5
    
    S5 --> EndNode([Selesai])
```

---

## 7. Sequence Diagram Modeling

Berikut adalah 7 Sequence Diagram MotoCare yang menggambarkan interaksi dinamis aktor dan sistem berdasarkan urutan waktu.

### 7.1 Sequence Diagram Registrasi
```mermaid
sequenceDiagram
    autonumber
    actor Pengguna
    participant Sistem as Sistem MotoCare

    Pengguna->>Sistem: Buka halaman registrasi
    Sistem-->>Pengguna: Tampilkan form registrasi
    Pengguna->>Sistem: Isi nama, email, password
    Sistem->>Sistem: Validasi data
    alt data tidak valid / email terdaftar
        Sistem-->>Pengguna: Pesan kesalahan
    else data valid
        Sistem->>Sistem: Simpan akun baru
        Sistem-->>Pengguna: Registrasi berhasil, menuju login
    end
```

---

### 7.2 Sequence Diagram Login
```mermaid
sequenceDiagram
    autonumber
    actor Pengguna
    participant Sistem as Sistem MotoCare

    Pengguna->>Sistem: Buka halaman login
    Sistem-->>Pengguna: Tampilkan form login
    Pengguna->>Sistem: Input email & password
    Sistem->>Sistem: Verifikasi email & password
    alt email & password sesuai
        Sistem-->>Pengguna: Halaman utama sesuai peran
    else tidak sesuai
        Sistem-->>Pengguna: Peringatan, kembali ke login
    end
```

---

### 7.3 Sequence Diagram Panggil Montir
```mermaid
sequenceDiagram
    autonumber
    actor Pemilik as Pemilik Kendaraan
    participant Sistem as Sistem MotoCare
    actor Mekanik as Mekanik

    Pemilik->>Sistem: Pilih menu Panggil Montir
    Sistem-->>Pemilik: Form + minta izin lokasi
    Pemilik->>Sistem: Isi kendala, kendaraan, lokasi
    Pemilik->>Sistem: Kirim permintaan
    Sistem->>Sistem: Validasi data & cari mekanik
    alt data tidak valid / mekanik tidak tersedia
        Sistem-->>Pemilik: Pesan + saran cari bengkel
    else data valid & mekanik tersedia
        Sistem->>Sistem: Simpan permintaan (MENUNGGU)
        Sistem->>Mekanik: Teruskan permintaan
        Sistem-->>Pemilik: Status: MENUNGGU
        alt mekanik menolak
            Mekanik->>Sistem: Tolak permintaan
            Sistem->>Sistem: Status menjadi DITOLAK
            Sistem-->>Pemilik: Notifikasi: DITOLAK + pesan
        else mekanik menerima
            Mekanik->>Sistem: Terima + estimasi biaya
            Sistem->>Sistem: Status menjadi DITERIMA
            Sistem-->>Pemilik: Notifikasi: DITERIMA
            Mekanik->>Mekanik: Tangani motor di lokasi
            Mekanik->>Sistem: Tandai selesai
            Sistem-->>Pemilik: Status: SELESAI
            opt fitur ulasan tersedia
                Pemilik->>Sistem: Beri penilaian & ulasan
            end
        end
    end
```

---

### 7.4 Sequence Diagram Cari Bengkel Terdekat
```mermaid
sequenceDiagram
    autonumber
    actor Pemilik as Pemilik Kendaraan
    participant Sistem as Sistem MotoCare
    participant Maps as Google Maps Platform

    Pemilik->>Sistem: Cari bengkel terdekat
    Sistem->>Sistem: Ambil lokasi (izin GPS)
    Sistem->>Maps: Cari bengkel (lokasi, radius)
    Maps-->>Sistem: Data tempat bengkel
    alt layanan peta gagal
        Sistem-->>Pemilik: Pesan: peta tidak tersedia
    else hasil kosong / luar cakupan
        Sistem-->>Pemilik: Info: hasil tidak ditemukan
    else hasil tersedia
        Sistem-->>Pemilik: Daftar & peta bengkel
        Pemilik->>Sistem: Pilih bengkel
        Sistem-->>Pemilik: Detail alamat, kontak, jam
        opt minta petunjuk arah
            Pemilik->>Sistem: Buka petunjuk arah
            Sistem->>Maps: Minta rute navigasi
        end
    end
```

---

### 7.5 Sequence Diagram Data Kendaraan
```mermaid
sequenceDiagram
    autonumber
    actor Pemilik as Pemilik Kendaraan
    participant Sistem as Sistem MotoCare

    Pemilik->>Sistem: Buka menu data kendaraan
    Sistem-->>Pemilik: Tampilkan daftar kendaraan
    alt tambah kendaraan
        Pemilik->>Sistem: Isi merek, model, tahun, pelat, km
        Sistem->>Sistem: Validasi data
        alt data tidak valid
            Sistem-->>Pemilik: Pesan kesalahan
        else data valid
            Sistem->>Sistem: Simpan kendaraan
            Sistem-->>Pemilik: Daftar kendaraan diperbarui
        end
    else ubah kendaraan
        Pemilik->>Sistem: Pilih kendaraan, ubah data
        Sistem->>Sistem: Validasi & perbarui data
        Sistem-->>Pemilik: Data kendaraan diperbarui
    else hapus kendaraan
        Pemilik->>Sistem: Pilih kendaraan, hapus
        Sistem-->>Pemilik: Minta konfirmasi
        Pemilik->>Sistem: Konfirmasi hapus
        Sistem->>Sistem: Hapus data kendaraan
        Sistem-->>Pemilik: Daftar kendaraan diperbarui
    end
```

---

### 7.6 Sequence Diagram Riwayat Servis
```mermaid
sequenceDiagram
    autonumber
    actor Pemilik as Pemilik Kendaraan
    participant Sistem as Sistem MotoCare

    Pemilik->>Sistem: Buka menu riwayat servis
    Pemilik->>Sistem: Pilih kendaraan
    Sistem-->>Pemilik: Tampilkan riwayat servis
    opt tambah / perbarui riwayat
        Pemilik->>Sistem: Isi tanggal, km, perawatan, biaya
        Sistem->>Sistem: Validasi data
        alt data tidak valid
            Sistem-->>Pemilik: Pesan kesalahan
        else data valid
            Sistem->>Sistem: Simpan riwayat servis
            Sistem-->>Pemilik: Riwayat ditampilkan kembali
        end
    end
```

---

### 7.7 Sequence Diagram Data Mekanik (Admin)
```mermaid
sequenceDiagram
    autonumber
    actor Admin
    participant Sistem as Sistem MotoCare

    Admin->>Sistem: Buka menu data mekanik
    Sistem-->>Admin: Tampilkan daftar mekanik
    alt tambah mekanik
        Admin->>Sistem: Isi profil, keahlian, area layanan
        Sistem->>Sistem: Validasi data
        alt data tidak valid
            Sistem-->>Admin: Pesan kesalahan
        else data valid
            Sistem->>Sistem: Simpan data mekanik
            Sistem-->>Admin: Daftar mekanik diperbarui
        end
    else ubah mekanik
        Admin->>Sistem: Pilih mekanik, ubah data
        Sistem->>Sistem: Validasi & perbarui data
        Sistem-->>Admin: Data mekanik diperbarui
    else hapus mekanik
        Admin->>Sistem: Pilih mekanik, hapus
        Sistem-->>Admin: Minta konfirmasi
        Admin->>Sistem: Konfirmasi hapus
        Sistem->>Sistem: Hapus data mekanik
        Sistem-->>Admin: Daftar mekanik diperbarui
    end
```

---

## 8. Pemetaan ke Implementasi OOP & Arsitektur Kode MotoCare

Seluruh spesifikasi dalam analisis sistem ini terhubung langsung dengan kode aplikasi Flutter di repositori `MOTOCARE`:

1. **Struktur Berbasis Fitur (*Feature-First*)**:
   - `lib/features/auth/`: Mengimplementasikan UC-01 & UC-02 (Registrasi, Login, Profile).
   - `lib/features/help_requests/`: Mengimplementasikan UC-03 (Panggil Montir, alur status `MENUNGGU` -> `DITERIMA` -> `SELESAI`, kalkulasi kedaluwarsa 15 menit).
   - `lib/features/workshops/`: Mengimplementasikan UC-04 (Pencarian bengkel Lhokseumawe & Aceh Utara, integrasi peta eksternal).
   - `lib/features/motorcycles/`: Mengimplementasikan UC-05 (CRUD motor, validasi penurunan odometer).
   - `lib/features/service_history/`: Mengimplementasikan UC-06 (Catatan servis, biaya Rupiah, sinkronisasi km).
   - `lib/features/reminders/` & `notifications/`: Pengingat servis cerdas & notifikasi status.
   - `lib/features/tutorials/`: Edukasi tutorial video YouTube terkurasi.

2. **Pola Data Repository (Polimorfisme & Abstraksi)**:
   - Setiap fitur memiliki kontrak abstrak (misal `HelpRequestRepository`, `MotorcycleRepository`).
   - Implementasi ganda: `Mock*Repository` (untuk simulasi/pengujian) dan `Supabase*Repository` (untuk database live).
   - Seluruh data simulasi diberi label `[Demo/Simulasi]` sesuai mandat analisis kebutuhan.

3. **Keamanan & Konsistensi Data**:
   - Validasi sisi klien di `lib/core/utils/validators.dart`.
   - Validasi otorisasi sisi server ditegakkan melalui *Row Level Security (RLS)* di `supabase/migrations/`.

---

## 9. Kesimpulan

Dokumen Analisis Sistem MotoCare telah dirampungkan secara komprehensif, mencakup:
1. Analisis permasalahan dan solusi sistem bantuan darurat sepeda motor di Lhokseumawe dan Aceh Utara.
2. Spesifikasi kebutuhan fungsional (FR) dan non-fungsional (NFR).
3. Permodelan UML lengkap yang terdiri dari:
   - **Use Case Diagram** dan **7 Tabel Skenario Use Case Rinci**.
   - **7 Activity Diagram** terstruktur dengan alur keputusan (decision nodes) yang lengkap.
   - **7 Sequence Diagram** yang mencerminkan interaksi dinamis antara aktor, sistem, dan layanan peta Google Maps Platform.
4. Keselarasan penuh antara dokumen analisis dan implementasi kode sumber Flutter MotoCare pada repositori.

