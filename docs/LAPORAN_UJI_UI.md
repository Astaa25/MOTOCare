# LAPORAN PENGUJIAN KUALITAS UI, NAVIGASI & SISTEM GERAK (MOTION DESIGN)
**Proyek:** MotoCare (Flutter Android & Supabase)  
**Tanggal Pengujian:** 18 November 2026  
**Peran:** Senior Flutter Engineer & Motion Design Specialist  
**Status Keseluruhan:** **LULUS PENUH (260 of 260 Tests Passing, 0 Analyzer Issues)**  
**Branch:** `milestone/m9-security-release-gate`

---

## 1. RINGKASAN EKSEKUTIF PENERAPAN SISTEM GERAK (MOTION DESIGN)

Sistem gerak (*motion design*) pada MotoCare diimplementasikan dengan berpegang teguh pada prinsip:
1. **Bermakna & Bertujuan:** Menunjukkan relasi spasial navigasi (perpindahan tab setara via *fade-through*, navigasi maju/mundur hierarkis via *shared-axis horizontal*, kontinuitas elemen via *Hero*).
2. **Cepat, Ringan & Efisien:** Rentang durasi 150 ms – 300 ms; kurva masuk `Curves.easeOutCubic`, kurva keluar `Curves.easeInCubic`, dan kurva simetris `Curves.easeInOutCubic`. Tidak ada efek bounce/elastic berlebihan.
3. **Ramah Aksesibilitas (Reduce-Motion):** Memeriksa `AppMotion.shouldDisableAnimation(context)`. Jika `disableAnimations = true` pada sistem pengguna, seluruh animasi secara otomatis dialihkan ke transisi instan tanpa delay.
4. **Performa GPU Optimal:** Hanya menganimasikan `Transform` dan `Opacity` (menggunakan `RepaintBoundary` pada lapisan animasi), menjamin bebas dari *raster thread jank* pada perangkat kelas menengah.

---

## 2. AUDIT HASIL IMPLEMENTASI GERAK (T-01 s/d T-07)

| ID | Butir / Fitur Gerak | Status | Lokasi Bukti Kode | Hasil Verifikasi |
| :--- | :--- | :---: | :--- | :--- |
| **T-01** | **Konfigurasi Gerak Terpusat:** Durasi baku (`shortDuration = 150ms`, `tabTransition = 220ms`, `standardDuration = 250ms`, `pageTransition = 300ms`), kurva baku (`enterCurve`, `exitCurve`, `standardCurve`), dan builder transisi halaman. | **LULUS** | [lib/core/theme/motion.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/core/theme/motion.dart) (`AppMotion`) | Terpusat dalam satu berkas; seluruh router dan widget mereferensikan konstanta ini. |
| **T-02** | **Transisi Antar Tab (Bottom Nav):** Perpindahan tab utama dengan efek fade-through (layar lama memudar keluar, layar baru muncul dengan skala 0.98 $\to$ 1.0 + fade-in, 220ms). | **LULUS** | [lib/core/router/app_router.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/core/router/app_router.dart#L120-L160)<br>[motion_transitions_test.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/test/core/widgets/motion_transitions_test.dart) (T-02) | Seluruh tab utama (`/home`, `/help`, `/motors`, `/workshops`, `/tutorials`, `/profile`) menggunakan `AppMotion.fadeThroughPage`. State tab tetap terjaga. |
| **T-03** | **Transisi Masuk/Keluar Layar Turunan:** Layar form dan detail masuk dari kanan (offset 30px + fade, 300ms, easeOutCubic); mundur dengan easeInCubic. Modal dialog/picker meluncur dari bawah (250ms). | **LULUS** | [lib/core/router/app_router.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/core/router/app_router.dart#L165-L305)<br>[motion_transitions_test.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/test/core/widgets/motion_transitions_test.dart) (T-03) | Rute turunan (`/motors/new`, `/motors/:id`, `/help/new`, `/help/:id`, `/workshops/:id`, dll.) menggunakan `AppMotion.sharedAxisPage`. Location picker menggunakan `AppMotion.modalPage`. |
| **T-04A** | **Kontinuitas Elemen Kartu Motor (Hero):** Kartu motor di Beranda & Motor Saya $\to$ Detail Kendaraan dengan animasi `Hero` pada plat nomor dan ikon motor. | **LULUS** | [lib/core/widgets/motorcycle_card.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/core/widgets/motorcycle_card.dart#L78-L135)<br>[motorcycle_detail_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/motorcycles/presentation/motorcycle_detail_screen.dart#L85-L138) | Tag `motor_icon_$id` dan `motor_plate_$id` terpasang secara dinamis; transisi halus saat membuka kartu kendaraan tanpa overflow. |
| **T-04B** | **Kontinuitas Perubahan Status Permintaan:** Kartu status (Menunggu $\to$ Diterima $\to$ Ditangani $\to$ Selesai) berganti dengan `AnimatedSwitcher` (fade + geser 12px, 250ms). | **LULUS** | [help_request_detail_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/help_requests/presentation/help_request_detail_screen.dart#L188-L245) | Perubahan status permintaan menggunakan `AnimatedSwitcher` dengan kurva `AppMotion.enterCurve`. |
| **T-05A** | **Mikro-Interaksi Tekan Tombol:** Skala 0.97 + haptic `selectionClick()` (100–140ms). | **LULUS** | [primary_button.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/core/widgets/primary_button.dart)<br>[secondary_button.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/core/widgets/secondary_button.dart)<br>[tertiary_button.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/core/widgets/tertiary_button.dart) | Terpasang konsisten pada semua tombol aksi. |
| **T-05B** | **Kemunculan Daftar Bertahap (Staggered Entrance):** Stagger 45ms per item, dibatasi maksimum 6 item pertama (index 0..5). | **LULUS** | [lib/core/widgets/animated_effects.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/core/widgets/animated_effects.dart#L202-L260)<br>[motion_transitions_test.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/test/core/widgets/motion_transitions_test.dart) (T-05) | Efektif dibatasi dengan `index.clamp(0, 5)` sehingga daftar panjang tetap responsif tanpa penundaan berlebih. |
| **T-05C** | **Transisi Teks Hitung Mundur 15 Menit:** Warna berubah secara halus ke peringatan (`AppColors.error`) saat sisa waktu $\le 1$ menit. | **LULUS** | [help_request_detail_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/help_requests/presentation/help_request_detail_screen.dart#L250-L270) | Menggunakan `AnimatedDefaultTextStyle(duration: 300ms)`. |
| **T-06** | **Kepatuhan Larangan Gerak:** Durasi maksimal $\le 350\text{ ms}$, tidak ada efek blur beranimasi, tidak ada bounce berlebih, ramah vestibular. | **LULUS** | Seluruh basis kode gerak terpusat. | Tidak ada animasi loop tanpa fungsi selain pulsing siaga montir yang menghormati reduce-motion. |
| **T-07** | **Suite Pengujian Otomatis Transisi Gerak:** Pengujian durasi, kurva, reduce-motion, dan kontinuitas Hero. | **LULUS** | [test/core/widgets/motion_transitions_test.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/test/core/widgets/motion_transitions_test.dart) | 6 dari 6 test gerak lulus 100%. |

---

## 3. IMPLEMENTASI FIGMA 03.01 S/D 04.03: ALUR PANGGIL MONTIR & TRACKING DARURAT

| ID | Layar / Fitur | Status | Lokasi Bukti Kode | Detail Implementasi & Kepatuhan Figma |
| :--- | :--- | :---: | :--- | :--- |
| **PM-01** | **Form Panggilan Montir (Figma 03.01)** | **LULUS** | [create_help_request_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/help_requests/presentation/create_help_request_screen.dart) | • Terbungkus `AppBackground` (gradasi hangat + radial glow).<br>• ChoiceChip kategori berlatar putih hangat (`#FFFDFB`), border `#EADBC8`, terpilih terakota `#B84A28`.<br>• Banner batasan layanan PRD 503 beraksen terakota. |
| **PM-02** | **Ubah Lokasi "Di mana kamu menunggu?" (Figma 03.02)** | **LULUS** | [location_picker_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/help_requests/presentation/location_picker_screen.dart) | • Terbungkus `AppBackground`.<br>• Search field autocomplete dengan debouncing 400ms & session token.<br>• Bottom action container dengan border pemisah dan `PrimaryButton` melayang. |
| **PM-03** | **Tinjau Permintaan (Figma 03.04)** | **LULUS** | [create_help_request_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/help_requests/presentation/create_help_request_screen.dart#L350-L400) | • Bottom sheet berpermukaan `AppColors.surfaceBright` dengan radius 24.<br>• Kartu mini map, rincian titik jemput, motor terpilih, dan klausul jujur: *"Biaya jasa perbaikan disepakati langsung dengan montir di lokasi pengerjaan"*. |
| **PM-04** | **Detail Permintaan & Hitung Mundur (Figma 03.06–03.07)** | **LULUS** | [help_request_detail_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/help_requests/presentation/help_request_detail_screen.dart) | • Terbungkus `AppBackground`.<br>• Kartu info mekanik dan rincian kerusakan berlatar putih hangat dengan aksen terakota & charcoal.<br>• Countdown timer 15 menit dengan transisi warna peringatan. |
| **PM-05** | **Pelacakan Montir Simulasi & Kartu Tiba (Figma 03.08–03.11)** | **LULUS** | [simulated_mechanic_tracking_card.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/help_requests/presentation/widgets/simulated_mechanic_tracking_card.dart) | • Lencana kejujuran data amber chip: *"Simulasi dipercepat - bukan GPS nyata"*. Rute simulasi dan kartu montir tiba (03.10) aktif saat status `inProgress`. |
| **PM-06** | **Penanganan Kondisi Izin & Sinyal GPS (Figma 09.06 & 09.07)** | **LULUS** | [location_access_dialogs.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/help_requests/presentation/location_access_dialogs.dart) | • Dialog izin kontekstual dan alur manual fallback bila GPS timeout atau lemah. |

---

## 4. IMPLEMENTASI FIGMA LAYAR LAINNYA: KATALOG BENGKEL, TUTORIAL, GARASI, DASHBOARD & PROFIL (BK-01 S/D BK-07)

Seluruh layar di luar alur panggil montir darurat telah diselaraskan 100% dengan panduan visual Figma *"Bengkel yang Ramah"* (warm cream background gradient `#FBE3CC` $\to$ `#FFFBF5` via `AppBackground`, warm white card surface `#FFFDFB` via `AppColors.surfaceBright`, border `#EADBC8`, dan aksen terakota `#B84A28` / peach `#F8DFC9` / charcoal `#243830`).

| ID | Layar / Fitur | Status | Lokasi Bukti Kode | Detail Implementasi & Kepatuhan Visual Figma |
| :--- | :--- | :---: | :--- | :--- |
| **BK-01** | **Katalog Bengkel Terverifikasi (Figma 05.01)** | **LULUS** | [workshops_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/workshops/presentation/workshops_screen.dart) | • Terbungkus `AppBackground`.<br>• Search bar berlatar `surfaceBright` dengan border melingkar halus.<br>• Filter kota (Semua, Lhokseumawe, Aceh Utara) menggunakan `surfaceBright` dengan border `#EADBC8` dan terakota saat aktif.<br>• Kartu `_WorkshopCard` menggunakan `Material(color: AppColors.surfaceBright)`. |
| **BK-02** | **Detail Bengkel Terverifikasi (Figma 05.02)** | **LULUS** | [workshop_detail_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/workshops/presentation/workshop_detail_screen.dart) | • Terbungkus `AppBackground`.<br>• Kartu informasi utama bengkel (kontak, jam buka, reputasi) dan kartu daftar layanan berlatar `AppColors.surfaceBright` dengan radius 16.<br>• Tombol aksi panggil montir terintegrasi mulus. |
| **BK-03** | **Tutorial Perawatan Mandiri (Figma 06.01)** | **LULUS** | [tutorials_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/tutorials/presentation/tutorials_screen.dart) | • Terbungkus `AppBackground`.<br>• Filter topik (Semua, Rantai, Oli, Aki, Ban) dengan `surfaceBright` dan border hangat.<br>• Kartu panduan `_TutorialCard` berlatar `AppColors.surfaceBright` dengan penanda tingkat kesulitan dan estimasi waktu. |
| **BK-04** | **Garasi Motor Saya (Figma 07.01 – 07.03)** | **LULUS** | [motorcycles_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/motorcycles/presentation/motorcycles_screen.dart)<br>[motorcycle_detail_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/motorcycles/presentation/motorcycle_detail_screen.dart)<br>[add_edit_motorcycle_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/motorcycles/presentation/add_edit_motorcycle_screen.dart) | • Seluruh layar garasi (daftar motor, form tambah/edit, detail) terbungkus `AppBackground`.<br>• Kartu spesifikasi kendaraan pada `motorcycle_detail_screen.dart` berlatar `surfaceBright`.<br>• Animasi Hero pada plat nomor dan ikon motor tetap berjalan mulus. |
| **BK-05** | **Dashboard Montir / Mitra Siaga (Figma 08.01 – 08.03)** | **LULUS** | [mechanic_home_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/home/presentation/mechanic_home_screen.dart) | • Terbungkus `AppBackground`.<br>• Kartu ringkasan metrik harian (panggilan selesai, rating, pendapatan) dan kartu penugasan aktif berlatar `surfaceBright`.<br>• Toggle status kesiapan siaga montir dengan aksen terakota & hijau sukses. |
| **BK-06** | **Dashboard Admin / Pengawas (Figma 09.01 – 09.03)** | **LULUS** | [admin_home_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/home/presentation/admin_home_screen.dart) | • Terbungkus `AppBackground`.<br>• Kartu metrik sistem (total montir aktif, permintaan aktif, verifikasi pending) dan kartu item montir berlatar `surfaceBright`.<br>• Desain ringkas dan responsif untuk admin operasional. |
| **BK-07** | **Profil, Riwayat Servis, & Pengingat (Figma 10.01 – 10.03)** | **LULUS** | [profile_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/profile/presentation/profile_screen.dart)<br>[service_history_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/service_history/presentation/service_history_screen.dart)<br>[reminders_screen.dart](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/reminders/presentation/reminders_screen.dart) | • Seluruh layar akun dan pendukung terbungkus `AppBackground`.<br>• `profile_screen.dart`: Kartu header pengguna dan kartu rincian akun berlatar `surfaceBright`.<br>• `service_history_screen.dart`: Kartu riwayat servis berlatar `surfaceBright` dengan status tag warna terstandarisasi.<br>• `reminders_screen.dart`: Kartu jadwal pengingat servis `_ReminderCard` berlatar `surfaceBright`. |

---

## 5. FIGMA CODE CONNECT INTEGRATION

Untuk mendukung alur *design-to-code* Figma secara langsung:
- **Konfigurasi:** [figma.config.json](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/figma.config.json) mendefinisikan bahasa `Flutter (Dart)` dan mencakup file `lib/core/widgets/**/*.figma.ts`.
- **TypeScript & Type Support:** [tsconfig.json](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/tsconfig.json) mengonfigurasi module types `@figma/code-connect/figma-types`.
- **Pemetaan Tombol Figma $\leftrightarrow$ Flutter:** [PrimaryButton.figma.ts](file:///D:/.Mine/Informatic%20engineering/MOTOCARE/lib/core/widgets/PrimaryButton.figma.ts) menghubungkan Figma Button Component ID (`cr2WrAfZEm0KTQvmYRL3w4/0-1`) dengan `PrimaryButton` dan `SecondaryButton` Flutter lengkap dengan properti `label`, `onPressed`, `isLoading`, `icon`, dan varian warna.

---

## 7. PENYELARASAN TOTAL DENGAN FIGMA RESMI: "ARAH VISUAL BARU" (MOTOCARE.ZIP)

Berdasarkan artefak Figma resmi (`MotoCare.zip` / Canvases 00 s/d 11), visual sistem aplikasi dirombak secara presisi mengikuti gaya on-demand / modern mobility (*Arah Visual Baru*):

### A. Palet Token Desain Baru:
1. **Latar Belakang Bersih & Hangat:** `#FFFCF9` (*Off-white*) menggantikan gradasi krem tua.
2. **Header & Aksen Utama:**
   - Coral Header: `#FF7966`
   - Tombol Aksi & Brand Utama: `#C74635` (*Action Red*)
   - Tipografi & Kontras Gelap: `#173C3B` (*Deep Teal*)
3. **Warna Kategori Lembut (*Soft Categorical Accents*):**
   - Soft Peach: `#FDE8E1` (Hero Banner & Pilihan Darurat)
   - Soft Mint: `#E2F1ED` (Motor Saya, Status Servis Berkala)
   - Soft Butter: `#FFF4D4` (Pengingat & Riwayat Servis)

### B. Hasil Penyelarasan Layar Kunci:
1. **Layar Masuk & Splash (Figma 01):**
   - `SplashScreen`: Latar Coral solid `#FF7966`, tipografi Deep Teal `#173C3B`, slogan resmi *"Teman andalan di perjalanan."*, indikator loading, dan footer *"BANTUAN • BENGKEL • PERAWATAN"*.
   - `LoginScreen`: Header lengkung Coral `#FF7966` dengan teks *"Perjalanan lebih tenang, mulai di sini."*, form input bersih, dan tombol aksi terakota/action `#C74635`.
2. **Beranda & Navigasi Utama (Figma 02):**
   - `HomeScreen`: Top Bar Coral `#FF7966` dengan alamat aktif, dropdown wilayah, notifikasi bell putih. Hero Banner Peach `#FDE8E1` dengan ilustrasi kurir vespa merah `rider_courier.png`. Grid 6 fitur dengan badge Simulasi. Kartu gelap Deep Teal `#173C3B` *"MOTOR SAYA"* dengan tautan detail.
   - `AppBottomNav`: Bar bawah *docked* berlatar putih bersih `#FFFFFF`, border atas `#F0EAE1`, ikon aktif `#C74635`, inaktif `#8F9E9D`.
3. **Panggil Montir & Tinjau Permintaan (Figma 03):**
   - `CreateHelpRequestScreen`: Indikator 3 tahap (*Keluhan* $\to$ *Tinjau* $\to$ *Cari montir*), badge Simulasi peach, pilihan 6 chip masalah umum, kartu lokasi bantuan berlatar mint lembut, dan bottom sheet tinjau permintaan lengkap dengan klausul jujur.
4. **Garasi Motor Saya (Figma 04):**
   - `MotorcyclesScreen`: Subtitle *"Kenali motor, rawat lebih mudah."*, kartu motor berlatar mint lembut `#E2F1ED` dengan tag *"Motor utama"*, dan kartu tindakan perawatan motor (Riwayat servis & Pengingat servis berlatar butter lembut `#FFF4D4`).

### C. Penyelarasan Lengkap Berkas Figma MOTOCare.zip (Section 05 & 06):
1. **Penghapusan Debug Tile (Sesuai Permintaan Pengguna):**
   - Tile *"Katalog Komponen UI (Debug)"* pada `profile_screen.dart` telah **dihapus permanen**.
   - Halaman `profile_screen.dart` kini 100% merefleksikan Figma 06.04 (*Akun saya*): Kartu profil berlatar Soft Mint `#E2F1ED` dengan inisial Deep Teal, 4 menu bersih dengan ikon berlatar Soft Peach (`Edit profil`, `Motor saya`, `Pengaturan notifikasi`, `Tutorial perawatan`), tombol merah *"Keluar dari akun"*, dan penjelajahan peran demo (*Area mekanik*, *Area admin*) menggunakan layout `Wrap` responsif.
2. **Layar Pengaturan Notifikasi (Figma 06.06):**
   - Berkas baru: [`lib/features/notifications/presentation/notification_settings_screen.dart`](file:///d:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/notifications/presentation/notification_settings_screen.dart).
   - Menyediakan 3 toggle preferensi (*Status bantuan*, *Pengingat servis*, *Pembaruan kilometer*), kartu catatan privasi izin perangkat Soft Mint, tombol simpan preferensi, dan rute navigasi `/notifications/settings`.
3. **Layar Detail Panduan Singkat (Figma 06.02):**
   - [`lib/features/tutorials/presentation/tutorial_detail_screen.dart`](file:///d:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/tutorials/presentation/tutorial_detail_screen.dart) telah disesuaikan: Squircle ikon motor Soft Butter, judul tebal Deep Teal, deskripsi pendahuluan, daftar bernomor 1-3 berbadge bulat Soft Mint, dan tombol *"Cari video di YouTube"*.
4. **Penyelarasan Aktivitas (Figma 02 Screen 3):**
   - [`lib/features/help_requests/presentation/my_help_requests_screen.dart`](file:///d:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/help_requests/presentation/my_help_requests_screen.dart) memisahkan kartu Hero permintaan aktif (*"Montir menuju lokasimu"*) dengan daftar aktivitas sebelumnya secara presisi tanpa duplikasi widget status.
5. **Penyelarasan Katalog Bengkel (Figma 05.01):**
   - [`lib/features/workshops/presentation/workshops_screen.dart`](file:///d:/.Mine/Informatic%20engineering/MOTOCARE/lib/features/workshops/presentation/workshops_screen.dart) kartu `_WorkshopCard` Soft Peach dengan pembatas `ConstrainedBox` dan `Flexible` teks jam operasional untuk perlindungan bebas overflow pada skala font 130%–150%.

### D. Verifikasi Kualitas Akhir:
- **Analisis Statis (`flutter analyze --no-pub lib/ test/`):** 0 issues found (100% Bersih).
- **Pengujian Otomatis (`flutter test --no-pub`):** 260 of 260 tests passed (100% Lulus).
- **Aksesibilitas Skala Font:** Bebas layout overflow pada skala font 130% s/d 150%.
