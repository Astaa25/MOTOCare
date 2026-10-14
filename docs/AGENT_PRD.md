# PRD MotoCare untuk Agent AI (Spesifikasi Eksekusi)

Oct 14, 2026 · @Abrar Astafaraiz

## 1. Cara Memakai Dokumen Ini dan Aturan Kerja Agent

Dokumen ini adalah instruksi eksekusi untuk agent AI (misalnya Claude Code) yang membangun aplikasi Android MotoCare dari nol. Dokumen pendamping, PRD MotoCare (Versi Disempurnakan), menjelaskan alasan produk; bila keduanya berbeda, dokumen ini yang berlaku untuk implementasi.

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

MotoCare adalah aplikasi Android berbahasa Indonesia untuk pemilik motor di Kota Lhokseumawe dan Kabupaten Aceh Utara: mencatat motor, kilometer, riwayat servis dan biaya; mengingatkan servis berdasarkan tanggal atau kilometer; menampilkan tutorial, daftar bengkel terverifikasi; dan menerima permintaan bantuan mekanik beserta statusnya.

### 2.1 Keputusan teknis (tidak boleh diubah tanpa persetujuan)

Keputusan berikut mengisi pilihan terbuka pada PRD manusia (D1 sampai D3) dengan opsi paling ringan untuk tim kecil. Pemilik proyek dapat mengubahnya sebelum M0 dimulai.

| Aspek | Keputusan | Catatan |
| --- | --- | --- |
| Platform | Android saja; `minSdk` 26 | iOS dan web di luar lingkup |
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

Akun dan profil; CRUD motor dan pembaruan kilometer; catat dan lihat riwayat servis dengan biaya; pengingat tanggal dan kilometer dengan status; pusat notifikasi in-app; pencarian tutorial; daftar dan detail bengkel di wilayah layanan; permintaan bantuan mekanik dengan status dan pembatalan; state loading, kosong, error, dan konfirmasi di semua layar; keamanan dasar lewat RLS. Fitur Should dan Could (multi-motor, ringkasan pengeluaran, push, filter, panel admin, ulasan, favorit, ekspor) tidak dikerjakan kecuali diminta.

### 2.3 Wilayah layanan

Bengkel dan pencarian dibatasi pada dua nilai `city_or_regency`: `Kota Lhokseumawe` dan `Kabupaten Aceh Utara`. Pencarian di luar nilai ini menampilkan pesan batas wilayah, bukan hasil. Layar bengkel selalu menampilkan kalimat cakupan wilayah.

## 3. Struktur Repo, Konvensi Kode, dan Perintah Standar

Struktur dibuat per fitur di dalam lapisan inti agar tiap anggota tim dan agent dapat bekerja pada modul berbeda tanpa konflik.

### 3.1 Struktur folder

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

Setiap fitur memakai tiga lapis: `domain` (model dan `abstract class` repository, tanpa Flutter), `data` (implementasi Supabase dan mock), `presentation` (screen, widget, provider Riverpod).

### 3.2 Konvensi kode

- Nama berkas `snake_case.dart`; class `PascalCase`; variabel dan method `lowerCamelCase`.
- Model bersifat immutable (`final` field, `copyWith`, `fromJson`, `toJson`); aturan bisnis berada di class domain atau service murni (tanpa import Flutter) agar mudah diuji.
- Widget tidak memanggil Supabase langsung; hanya lewat provider yang memakai repository.
- Hasil operasi yang dapat gagal memakai tipe `Result<T>` atau `AsyncValue`; error ditampilkan dengan pesan Indonesia yang ramah dari `core/errors`, bukan pesan mentah.
- Satu widget publik per berkas bila lebih dari 80 baris; hindari berkas lebih dari 300 baris.
- Teks UI hanya Bahasa Indonesia, dikumpulkan di konstanta atau berkas string per fitur; tidak ada teks acak tersebar di widget.
- Semua tombol yang memicu request dinonaktifkan selama proses berjalan (cegah submit ganda).
- Waktu disimpan UTC; tampilkan dalam zona waktu perangkat.

### 3.3 Perintah standar

| Tujuan | Perintah |
| --- | --- |
| Pasang dependensi | `flutter pub get` |
| Analisis statis | `flutter analyze` |
| Jalankan semua test | `flutter test` |
| Format | `dart format lib test` |
| Jalankan debug dengan env | `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` |
| Build APK | `flutter build apk --debug` |

Sebelum commit, `flutter analyze` harus tanpa temuan dan `flutter test` harus lulus.

## 4. Design Tokens dan Aturan UI

UI harus konsisten dan ringan: putih dominan, oranye sebagai aksen, satu aksi utama per layar. Semua warna, jarak, dan tipografi diambil dari token; dilarang menulis hex atau angka ukuran langsung di widget.

### 4.1 Token warna

Kontras dihitung terhadap latar putih (target teks biasa 4,5:1). Teks putih di atas `#F47721` hanya sekitar 2,8:1 sehingga tidak boleh dipakai; label tombol utama memakai `onPrimary`.

| Token | Hex | Pemakaian |
| --- | --- | --- |
| `background` | `#FFFFFF` | Latar layar |
| `cream` | `#FFF0E3` | Panel lembut |
| `peach` | `#FFD0A6` | Kartu dan sorotan |
| `orangeSoft` | `#FF9B54` | Aksen dan gradasi |
| `primary` | `#F47721` | Isi tombol utama, elemen aktif, ikon aktif |
| `onPrimary` | `#1F1F1F` | Label dan ikon di atas `primary` (sekitar 5,9:1) |
| `primaryText` | `#B34D00` | Teks atau tautan oranye di atas putih (sekitar 5,3:1) |
| `textPrimary` | `#343434` | Teks utama |
| `textSecondary` | `#6C625B` | Teks sekunder |
| `success` | `#1B7F3B` | Status sukses (sekitar 5,1:1) |
| `error` | `#C62828` | Error dan servis terlambat (sekitar 5,6:1) |
| `warning` | `#8A5A00` | Status mendekati jatuh tempo |

Gradasi header: `#FFF7F0`, `#FFE2C7`, `#FFB875` (atas ke bawah). Verifikasi rasio kontras dengan perhitungan atau alat sebelum merge; nilai di atas adalah perkiraan.

### 4.2 Tipografi, jarak, bentuk

| Elemen | Aturan |
| --- | --- |
| Font | Plus Jakarta Sans (Regular 400, Medium 500, SemiBold 600, Bold 700, ExtraBold 800) |
| Display | 28 sp, ExtraBold |
| Judul layar | 22 sp, Bold |
| Subjudul | 16 sp, SemiBold |
| Isi | 14 sp, Regular, tinggi baris 1,4 |
| Label dan tombol | 14 sp, SemiBold |
| Jarak | Kelipatan 4: 4, 8, 12, 16, 24, 32 |
| Radius | Kartu 16, tombol 14, input 12, chip 999 |
| Elevasi | Kartu 0 sampai 2 (utamakan border `#F0E3D6` tipis) |
| Target sentuh | Minimal 48 x 48 dp |

Jangan mengunci ukuran font; hormati `textScaler` sistem hingga 130% tanpa teks terpotong.

### 4.3 Komponen reusable wajib (di `core/widgets/`)

`PrimaryButton`, `SecondaryButton`, `AppIconButton`, `AppTextField` (dengan validator dan pesan error), `MotorcycleCard`, `ServiceReminderCard`, `WorkshopCard`, `TutorialCard`, `StatusChip` (teks, ikon, dan warna), `LoadingSkeleton` (shimmer), `EmptyState` (ikon, judul, teks, tombol aksi), `ErrorState` (pesan dan tombol "Coba lagi"), `AppToast` atau `SuccessDialog`, `ConfirmationDialog`, `NotificationTile`, dan `AppBottomNav`.

### 4.4 Aturan status dan aksesibilitas

- Setiap daftar atau layar data memiliki empat keadaan yang dirancang dan diuji: loading, data, kosong, error.
- Status tidak hanya dibedakan lewat warna: `StatusChip` selalu memuat teks dan ikon.
- Ikon penting memiliki `semanticLabel` atau `Tooltip`.
- Aksi merusak (hapus motor, hapus servis, batalkan permintaan) selalu lewat `ConfirmationDialog`.

### 4.5 Motion

| Konteks | Efek | Durasi |
| --- | --- | --- |
| Splash | Logo fade dan scale ringan, ikon motor bergerak halus | 3 sampai 5 detik total, hanya saat peluncuran |
| Tombol ditekan | Scale atau opacity | 100 sampai 180 ms |
| Kartu masuk | Fade dan slide | 250 sampai 400 ms |
| Dialog | Fade dan scale | 180 sampai 280 ms |
| Sukses | Centang dan efek ringan | 400 sampai 800 ms |
| Pengingat penting | Pulse lembut, tidak berulang terus | 500 sampai 900 ms |

Gunakan animasi bawaan Flutter (`AnimatedOpacity`, `AnimatedContainer`, `AnimatedSwitcher`, `TweenAnimationBuilder`, `AnimationController`). Konstanta durasi dikumpulkan di `core/theme/motion.dart`. Bila `MediaQuery.disableAnimations` aktif, semua animasi dekoratif dimatikan atau dipersingkat menjadi nol. Splash tidak boleh menunda permintaan data: inisialisasi berjalan paralel dengan animasi.

## 5. Skema Database, RLS, dan Data Seed

Simpan SQL di `supabase/migrations/` sebagai berkas bernomor (`0001_schema.sql`, `0002_rls.sql`, `0003_functions.sql`). Skema di bawah adalah acuan; tambahkan indeks pada kolom yang sering difilter (`user_id`, `motorcycle_id`, `status`, `city_or_regency`). Status pengingat "Mendekati" dan "Terlambat" dihitung di aplikasi (bagian 6.2), bukan disimpan.

### 5.1 Skema (`0001_schema.sql`)

```sql
create extension if not exists pgcrypto;

create type user_role as enum ('user', 'mechanic', 'admin');
create type reminder_status as enum ('active', 'completed');
create type request_status as enum (
  'pending','accepted','rejected','on_the_way','in_progress','completed','cancelled','expired'
);

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(full_name) between 2 and 80),
  phone text check (phone ~ '^\+?[0-9]{8,15}$'),
  role user_role not null default 'user',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table workshops (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text not null,
  city_or_regency text not null
    check (city_or_regency in ('Kota Lhokseumawe', 'Kabupaten Aceh Utara')),
  latitude double precision, longitude double precision,
  phone text, opening_hours text, services text[] not null default '{}',
  is_active boolean not null default true,
  source text not null,            -- asal data, wajib diisi
  verified_at timestamptz,         -- null = belum terverifikasi, tidak boleh tampil
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);

create table motorcycles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  brand text not null, model text not null,
  production_year int not null check (production_year between 1980 and 2100),
  license_plate text,
  current_mileage int not null check (current_mileage between 0 and 999999),
  mileage_updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table service_histories (
  id uuid primary key default gen_random_uuid(),
  motorcycle_id uuid not null references motorcycles(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  service_date date not null,
  mileage int not null check (mileage between 0 and 999999),
  service_type text not null,
  description text,
  cost numeric(12,0) not null default 0 check (cost >= 0),
  workshop_id uuid references workshops(id) on delete set null,
  created_at timestamptz not null default now()
);

create table maintenance_reminders (
  id uuid primary key default gen_random_uuid(),
  motorcycle_id uuid not null references motorcycles(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  reminder_date date,
  target_mileage int check (target_mileage between 0 and 999999),
  status reminder_status not null default 'active',
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  check (reminder_date is not null or target_mileage is not null)
);

create table mechanics (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references profiles(id) on delete cascade,
  workshop_id uuid references workshops(id) on delete set null,
  is_available boolean not null default false,
  service_area text,
  availability_updated_at timestamptz not null default now(),
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);

create table service_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  mechanic_id uuid references mechanics(id) on delete set null,
  motorcycle_id uuid references motorcycles(id) on delete set null,
  issue_description text not null check (char_length(issue_description) between 10 and 500),
  latitude double precision, longitude double precision,
  address_text text not null,
  contact_phone text not null,
  status request_status not null default 'pending',
  created_at timestamptz not null default now(),
  accepted_at timestamptz, completed_at timestamptz,
  expires_at timestamptz not null default (now() + interval '15 minutes'),
  is_demo boolean not null default false
);

-- satu permintaan aktif per pengguna (mencegah duplikasi)
create unique index one_active_request_per_user on service_requests(user_id)
  where status in ('pending','accepted','on_the_way','in_progress');

create table tutorials (
  id uuid primary key default gen_random_uuid(),
  title text not null, topic text not null,
  youtube_url text not null
    check (youtube_url ~ '^https://(www\.)?(youtube\.com|youtu\.be)/'),
  thumbnail_url text, description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null, body text not null,
  type text not null check (type in ('reminder','request_status','system')),
  is_read boolean not null default false,
  related_id uuid,
  created_at timestamptz not null default now()
);
```

### 5.2 Pemicu

- Setelah baris `auth.users` dibuat, pemicu `handle_new_user` (security definer, `search_path = public`) membuat baris `profiles` dengan `role = 'user'` dan `full_name` dari metadata (default `Pengguna`).
- Pemicu `BEFORE INSERT OR UPDATE` pada `service_histories` menolak `service_date` di masa depan dengan pesan jelas.
- Pemicu `AFTER UPDATE OF status` pada `service_requests` menyisipkan baris `notifications` (`type = 'request_status'`, `related_id` = id permintaan) untuk pembuat permintaan.
- Pemicu `updated_at` pada `profiles` dan `motorcycles`.

### 5.3 Kebijakan akses (`0002_rls.sql`)

Aktifkan `enable row level security` pada **semua** tabel. Tanpa kebijakan, akses ditolak. Kebijakan minimal:

```sql
create function is_admin() returns boolean language sql stable
security definer set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin')
$$;

-- profiles: baca dan ubah milik sendiri; role tidak dapat diubah oleh pengguna
create policy profiles_select on profiles for select
  using (id = auth.uid() or is_admin());
create policy profiles_update on profiles for update
  using (id = auth.uid())
  with check (id = auth.uid() and role = (select p.role from profiles p where p.id = auth.uid()));

-- tabel milik pengguna: motorcycles, notifications
create policy own_rows on motorcycles for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_rows on notifications for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- tabel anak motor: pastikan motor milik pengguna
create policy own_rows on service_histories for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and exists (
    select 1 from motorcycles m where m.id = motorcycle_id and m.user_id = auth.uid()));
create policy own_rows on maintenance_reminders for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and exists (
    select 1 from motorcycles m where m.id = motorcycle_id and m.user_id = auth.uid()));

-- katalog: hanya data aktif dan terverifikasi; tulis oleh admin
create policy read_workshops on workshops for select to authenticated
  using ((is_active and (verified_at is not null or is_demo)) or is_admin());
create policy admin_workshops on workshops for all using (is_admin()) with check (is_admin());
create policy read_tutorials on tutorials for select to authenticated
  using (is_active or is_admin());
create policy admin_tutorials on tutorials for all using (is_admin()) with check (is_admin());

-- mechanics: terlihat bila tersedia atau milik sendiri; ubah milik sendiri
create policy read_mechanics on mechanics for select to authenticated
  using (is_available or profile_id = auth.uid() or is_admin());
create policy update_own_mechanic on mechanics for update
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- service_requests: baca oleh pembuat, mekanik terkait, admin; sisipkan hanya status pending
create policy read_requests on service_requests for select using (
  user_id = auth.uid() or is_admin() or
  mechanic_id in (select id from mechanics where profile_id = auth.uid()));
create policy insert_request on service_requests for insert
  with check (user_id = auth.uid() and status = 'pending' and mechanic_id is null);
-- TIDAK ada policy update/delete: perubahan status hanya lewat fungsi RPC (5.4)
```

### 5.4 Fungsi RPC (`0003_functions.sql`)

Semua fungsi `security definer`, `set search_path = public`, dan memeriksa `auth.uid()` di dalamnya.

| Fungsi | Pemanggil | Perilaku |
| --- | --- | --- |
| `cancel_request(p_id uuid)` | Pembuat permintaan | Ubah ke `cancelled` bila status saat ini `pending`, `accepted`, atau `on_the_way`; selain itu lempar error |
| `advance_request(p_id uuid, p_new request_status)` | Mekanik yang ditugaskan | Hanya transisi sah: `pending` ke `accepted` atau `rejected` (isi `mechanic_id`, `accepted_at`); `accepted` ke `on_the_way`; `on_the_way` ke `in_progress`; `in_progress` ke `completed` (isi `completed_at`); lainnya ditolak |
| `expire_stale_requests()` | Pembuat permintaan | Ubah permintaan milik pemanggil yang `pending` dan `expires_at < now()` menjadi `expired` |

Klien memanggil `expire_stale_requests()` saat membuka daftar dan detail permintaan. Pekerjaan terjadwal (`pg_cron`) opsional.

### 5.5 Data seed (`supabase/seed_demo.sql`)

- Semua baris seed berlabel: `is_demo = true` dan nama diawali `[Demo]`. UI menampilkan lencana "Demo/Simulasi" untuk baris `is_demo`.
- Minimal 6 bengkel (3 per wilayah), 8 tutorial (topik: ganti oli, rem, ban, aki, rantai, busi), 1 mekanik demo.
- Nilai alamat, telepon, dan koordinat adalah placeholder yang jelas; jangan meniru bisnis nyata.
- URL YouTube pada seed adalah placeholder `https://www.youtube.com/watch?v=GANTI_DENGAN_ID_VALID`. Manusia wajib mengganti dengan video sah sebelum demo; agent tidak boleh mengarang ID video.
- Rating tidak dibuat pada MVP.

## 6. Aturan Bisnis yang Presisi

Aturan di bagian ini diimplementasikan sebagai fungsi murni di lapisan `domain` (tanpa import Flutter) dan wajib diuji dengan contoh input-output yang tercantum. Nilai ambang berada di `core/config/app_constants.dart`.

### 6.1 Konstanta

| Konstanta | Nilai | Arti |
| --- | --- | --- |
| `mileageMax` | 999999 | Batas atas kilometer |
| `mileageJumpConfirmKm` | 5000 | Selisih yang memicu konfirmasi |
| `reminderNearDays` | 7 | Jendela "Mendekati" untuk tanggal |
| `reminderNearKm` | 200 | Jendela "Mendekati" untuk kilometer |
| `mileageStaleDays` | 30 | Batas saran memperbarui kilometer |
| `requestTimeoutMinutes` | 15 | Waktu tunggu permintaan bantuan |
| `pageSize` | 20 | Ukuran halaman daftar |
| `splashMinMs` / `splashMaxMs` | 3000 / 5000 | Rentang splash |

### 6.2 Validasi kilometer

Fungsi `validateMileage(int current, String rawInput)` mengembalikan salah satu: `invalid`, `ok`, `confirmDecrease`, `confirmBigJump`.

1. Jika `rawInput` bukan bilangan bulat tanpa tanda atau di luar 0 sampai 999999, hasilnya `invalid`.
2. Jika nilai lebih kecil dari `current`, hasilnya `confirmDecrease` (UI meminta konfirmasi koreksi).
3. Jika nilai dikurangi `current` lebih besar dari 5000, hasilnya `confirmBigJump`.
4. Selain itu `ok`.

| current | input | Hasil |
| --- | --- | --- |
| 12000 | 12000 | `ok` |
| 12000 | 11990 | `confirmDecrease` |
| 12000 | 17000 | `ok` (selisih tepat 5000) |
| 12000 | 17001 | `confirmBigJump` |
| 5000 | -1 | `invalid` |
| 0 | 1000000 | `invalid` |
| 100 | `abc` | `invalid` |

Setelah kilometer disimpan, `mileage_updated_at` diperbarui. Saat mencatat servis, kilometer motor hanya diperbarui bila `mileage` servis lebih besar dari `current_mileage`.

### 6.3 Status pengingat

Fungsi `computeReminderStatus` menerima `status` tersimpan, `reminderDate`, `targetMileage`, `currentMileage`, dan `today` (tanggal lokal tanpa jam). Hasil: `completed`, `overdue`, `near`, atau `scheduled`. Urutan keparahan: `overdue` lebih tinggi dari `near`, lebih tinggi dari `scheduled`; bila ada dua pemicu, ambil yang paling parah.

- `completed` bila `status == completed`.
- Pemicu tanggal: `overdue` bila `today` setelah `reminderDate`; `near` bila selisih hari 0 sampai 7; selain itu `scheduled`.
- Pemicu kilometer: `overdue` bila `currentMileage` lebih besar dari `targetMileage`; `near` bila sisa 0 sampai 200 km; selain itu `scheduled`.

| Kasus | Hasil |
| --- | --- |
| Tanggal 2026-11-01, hari ini 2026-10-20 (12 hari) | `scheduled` |
| Tanggal 2026-11-01, hari ini 2026-10-25 (7 hari) | `near` |
| Tanggal 2026-11-01, hari ini 2026-11-01 | `near` |
| Tanggal 2026-11-01, hari ini 2026-11-02 | `overdue` |
| Target 15000, kilometer 14700 (sisa 300) | `scheduled` |
| Target 15000, kilometer 14800 (sisa 200) | `near` |
| Target 15000, kilometer 15000 | `near` |
| Target 15000, kilometer 15001 | `overdue` |
| Tanggal belum jatuh tempo, kilometer 15001 melewati target 15000 | `overdue` |
| `status == completed` | `completed` |

Tampilan: `scheduled` berlabel "Terjadwal"; `near` "Segera servis" (ikon peringatan, warna `warning`); `overdue` "Terlambat" (ikon peringatan, warna `error`); `completed` "Selesai" (warna `success`).

### 6.4 Templat pengingat dan jadwal berikutnya

Templat berada di `features/reminders/domain/default_templates.dart`. Nilainya adalah titik awal yang dapat diubah pengguna dan **wajib diverifikasi manusia** terhadap buku manual motor.

| Templat | Interval km | Interval bulan |
| --- | --- | --- |
| Oli mesin | 3000 | 3 |
| Filter udara | 10000 | tidak ada |
| Busi | 10000 | tidak ada |
| Cek rem | tidak ada | 1 |
| Cek rantai | tidak ada | 1 |
| Cek tekanan ban | tidak ada | 1 |
| Aki | tanpa default (pengguna mengisi) | tanpa default |

Saat pengingat ditandai selesai bersama catatan servis, buat pengingat berikutnya dengan judul sama: `target_mileage = mileage servis + interval km` dan `reminder_date = tanggal servis + interval bulan`, hanya untuk interval yang ada.

### 6.5 Notifikasi pengingat tanpa duplikasi

1. Saat aplikasi dibuka, saat kilometer diperbarui, dan saat tanggal berganti, hitung ulang status semua pengingat aktif.
2. Bila status berubah menjadi `near` atau `overdue` dan belum ada baris `notifications` dengan `related_id` pengingat itu dan judul yang sama, sisipkan satu baris.
3. Jadwalkan notifikasi lokal (zona `Asia/Jakarta`) pukul 08.00 pada 7 hari sebelum dan pada hari `reminder_date`; batalkan jadwal saat pengingat selesai atau dihapus.
4. Jika izin notifikasi ditolak, pusat notifikasi in-app tetap menjadi sumber utama; jangan tampilkan error.
5. Bila `mileage_updated_at` lebih dari 30 hari, tampilkan saran memperbarui kilometer di dashboard.

### 6.6 Permintaan bantuan mekanik

- Status mengikuti enum `request_status`. Jalur normal: `pending`, `accepted`, `on_the_way`, `in_progress`, `completed`. Jalur lain: `rejected`, `cancelled`, `expired`.
- Satu pengguna hanya boleh punya satu permintaan aktif; bila database menolak karena indeks unik, tampilkan "Anda masih memiliki permintaan aktif" dan buka permintaan itu.
- Pengguna dapat membatalkan pada `pending`, `accepted`, dan `on_the_way` (pada `on_the_way` tampilkan peringatan terlebih dahulu) lewat `cancel_request`.
- Tampilkan hitung mundur dari `expires_at`. Saat habis, panggil `expire_stale_requests()`; bila hasilnya `expired`, tampilkan opsi: kirim ulang, hubungi bengkel terverifikasi (`tel:` lewat `url_launcher`), dan kontak darurat dari `emergencyContacts`.
- `emergencyContacts` di `app_constants.dart` kosong secara default; bagian ini disembunyikan sampai manusia mengisi nomor yang sah. Agent tidak boleh mengarang nomor telepon.
- Layar permintaan menyatakan bahwa MotoCare tidak menjamin ketersediaan mekanik dan bukan layanan darurat medis atau kepolisian.
- Mode mock: `DemoMechanicSimulator` boleh memajukan status dengan timer, hanya bila `useMock == true`, dengan lencana "Demo/Simulasi" di layar permintaan.

### 6.7 Validasi isian

| Isian | Aturan |
| --- | --- |
| Email | Format email valid |
| Kata sandi | Minimal 8 karakter, mengandung huruf dan angka |
| Nama lengkap | 2 sampai 80 karakter |
| Telepon | Hapus spasi dan tanda hubung; `^\+?[0-9]{8,15}$` |
| Merek, model | Wajib, maksimal 40 karakter |
| Tahun produksi | Bilangan bulat 1980 sampai tahun berjalan ditambah 1 |
| Plat nomor | Opsional, maksimal 12 karakter, disimpan huruf besar |
| Tanggal servis | Tidak di masa depan |
| Biaya | Bilangan bulat Rupiah, minimal 0 |
| Jenis servis | Dari daftar (Ganti oli, Servis berkala, Rem, Rantai, Ban, Aki, Busi, Filter udara, Lainnya) |
| Deskripsi masalah | 10 sampai 500 karakter |
| Alamat atau lokasi | Wajib, minimal 5 karakter, atau koordinat GPS |

Validasi dilakukan di UI (pesan ramah) dan ditegakkan lagi di database.

## 7. Rencana Kerja Bertahap (M0 sampai M8)

Kerjakan berurutan. Setiap milestone memiliki tugas, keluaran, kriteria selesai, dan perintah verifikasi. Milestone dianggap selesai hanya bila semua kriteria terpenuhi dan `flutter analyze` serta `flutter test` lulus. Mode `USE_MOCK=true` (lewat `--dart-define`) memakai repository mock sehingga M3 sampai M7 dapat dikembangkan walau backend belum siap; implementasi Supabase menyusul pada antarmuka yang sama.

### M0. Fondasi proyek

**Tugas**

1. `flutter create` (org `id.motocare`, hanya Android), tambahkan dependensi bagian 2, atur `minSdk 26`.
2. Buat struktur folder bagian 3.1, `analysis_options.yaml` (include `flutter_lints`, aktifkan `prefer_const_constructors`, `avoid_print`, `always_declare_return_types`), `.env.example`, `.gitignore` (termasuk `.env`).
3. Bundel font Plus Jakarta Sans, buat `core/theme` (token bagian 4, `ThemeData`, `motion.dart`), locale `id_ID`.
4. Buat `app_router.dart` dengan rute bagian 8 berisi layar placeholder dan guard autentikasi.
5. Buat `SplashScreen`: animasi minimal 3000 ms dan maksimal 5000 ms; inisialisasi (Supabase atau mock, pemulihan sesi) berjalan paralel; navigasi dilakukan bila animasi minimal selesai dan inisialisasi selesai. Bila inisialisasi melewati 5000 ms, tampilkan progres jujur dan tombol "Coba lagi" saat gagal.
6. Tulis `README.md` (cara menjalankan, env, mode mock).

**Selesai bila:** aplikasi berjalan menampilkan splash lalu halaman login placeholder; `flutter analyze` tanpa temuan; ada widget test untuk splash (navigasi setelah inisialisasi, tanpa menunda lebih dari 5000 ms).

**Verifikasi:** `flutter pub get && flutter analyze && flutter test && flutter build apk --debug`.

### M1. Komponen UI, utilitas, dan validasi

**Tugas**

1. Implementasikan semua komponen bagian 4.3 di `core/widgets/` dengan token tema, `semanticLabel`, dan target sentuh 48 dp.
2. Buat `Result<T>`, `AppException`, pemetaan pesan error ramah (jaringan, izin, tidak ditemukan, tidak berizin, tidak diketahui).
3. Buat `formatters.dart` (Rupiah `Rp 1.250.000`, tanggal `14 Okt 2026`, kilometer `12.500 km`) dan `validators.dart` sesuai bagian 6.7.
4. Buat halaman katalog komponen (hanya build debug) untuk memeriksa semua state secara visual.

**Selesai bila:** setiap validator memiliki unit test untuk kasus valid dan tidak valid; widget test memverifikasi `ErrorState` memunculkan tombol "Coba lagi", `EmptyState` memuat teks dan aksi, `StatusChip` memuat teks dan ikon.

**Verifikasi:** `flutter test test/core`.

### M2. Database, autentikasi, dan profil

**Tugas**

1. Tulis migrasi `0001_schema.sql`, `0002_rls.sql`, `0003_functions.sql` sesuai bagian 5 dan `supabase/seed_demo.sql` sesuai 5.5.
2. Buat `AuthRepository` (abstract), `SupabaseAuthRepository`, `MockAuthRepository`, dan provider sesi.
3. Layar: Login, Registrasi, Lupa kata sandi (kirim tautan reset lewat Supabase; di mock tampilkan pesan demo), Profil (lihat dan ubah nama dan telepon), Logout dengan konfirmasi.
4. Guard router: tanpa sesi, semua rute terlindungi mengarah ke login; setelah login, arahkan ke Beranda.
5. Tulis `supabase/tests/rls_check.md` berisi langkah dan perintah SQL untuk membuktikan: pengguna A tidak dapat membaca atau mengubah baris pengguna B pada setiap tabel; pengguna tidak dapat mengubah `role`; `update` langsung pada `service_requests` ditolak.

**Selesai bila:** registrasi, login, logout, dan edit profil berfungsi di mode mock dan di Supabase; pesan error login salah bersifat umum; unit test `AuthRepository` mock dan widget test validasi form lulus; skrip pembuktian RLS tertulis dan hasilnya dilaporkan.

**Verifikasi:** `flutter test test/features/auth` dan jalankan langkah `rls_check.md` pada proyek Supabase uji.

### M3. Motor dan kilometer (termasuk kerangka Beranda)

**Tugas**

1. Model `Motorcycle`, `MotorcycleRepository` (abstract, Supabase, mock), provider daftar dan detail.
2. Layar Motor Saya (daftar), Tambah dan Ubah motor, Hapus motor dengan `ConfirmationDialog` yang menyebut riwayat dan pengingat ikut terhapus.
3. Implementasikan `validateMileage` (bagian 6.2) dan dialog konfirmasi untuk `confirmDecrease` dan `confirmBigJump`; layar "Perbarui kilometer".
4. Kerangka Beranda: kartu motor aktif dan tombol "Butuh bantuan mekanik" (menuju layar M7); bagian ringkasan diisi pada milestone berikutnya.
5. Satu pengguna dapat memiliki beberapa baris motor di database, tetapi UI MVP mengelola satu motor aktif (pemilih multi-motor termasuk Should, jangan dikerjakan).

**Selesai bila:** CRUD motor berfungsi; semua baris tabel contoh bagian 6.2 lulus sebagai unit test; empty state "Belum ada motor" tampil dengan tombol tambah.

**Verifikasi:** `flutter test test/features/motorcycles`.

### M4. Riwayat servis dan biaya

**Tugas**

1. Model `ServiceHistory`, `ServiceHistoryRepository`, provider daftar (pagination 20 per halaman) dan filter jenis servis.
2. Layar: Daftar riwayat (terbaru dahulu), Tambah servis (tanggal, kilometer, jenis, biaya, bengkel opsional, catatan), Detail, Ubah, Hapus dengan konfirmasi.
3. Validasi: tanggal tidak di masa depan, biaya minimal 0, kilometer valid; setelah simpan, perbarui kilometer motor bila lebih besar (bagian 6.2).
4. Tampilkan total biaya riwayat yang sedang terfilter di bagian atas daftar (ringkasan bulanan adalah Should, jangan dikerjakan).

**Selesai bila:** servis tersimpan dan tampil kembali setelah aplikasi dibuka ulang; tanggal masa depan dan biaya negatif ditolak dengan pesan; unit test untuk logika pembaruan kilometer dan total biaya lulus; empty state "Catat servis pertama" tampil.

**Verifikasi:** `flutter test test/features/service_history`.

### M5. Pengingat dan pusat notifikasi

**Tugas**

1. Model `MaintenanceReminder`, `AppNotification`, repository masing-masing, `ReminderService` (murni: `computeReminderStatus`, pembuatan pengingat berikutnya, bagian 6.3 dan 6.4).
2. Layar: Daftar pengingat per motor (urut dari yang paling parah), Buat dan ubah pengingat (pilih templat atau kustom; minimal satu pemicu), Detail pengingat dengan aksi "Tandai selesai" dan "Catat servis".
3. Alur selesai: tandai selesai membuka formulir servis terisi awal; setelah servis tersimpan, pengingat berikutnya dibuat otomatis (bagian 6.4).
4. Layar Pusat Notifikasi: urut waktu, tandai dibaca (satu dan semua), ketuk membuka layar terkait; lencana jumlah belum dibaca di Beranda.
5. `NotificationService` dengan antarmuka dan dua implementasi (lokal dan in-app); penjadwalan notifikasi lokal sesuai bagian 6.5 termasuk pembatalan; izin diminta saat pertama kali pengguna membuat pengingat, dengan penjelasan.
6. Lengkapi Beranda: ringkasan pengingat terdekat, ringkasan servis terakhir, saran memperbarui kilometer bila lebih dari 30 hari.

**Selesai bila:** semua baris tabel contoh bagian 6.3 lulus sebagai unit test; menyelesaikan servis membuat pengingat berikutnya dengan nilai benar (uji dengan Oli mesin: servis di 12000 km pada 2026-10-14 menghasilkan target 15000 km dan tanggal 2027-01-14); tidak ada notifikasi ganda untuk perubahan status yang sama; penolakan izin notifikasi tidak menimbulkan error.

**Verifikasi:** `flutter test test/features/reminders test/features/notifications`.

### M6. Tutorial dan bengkel

**Tugas**

1. Tutorial: model, repository, daftar dengan chip topik dan kolom pencarian (debounce 300 ms), detail (judul, topik, deskripsi, tombol "Tonton di YouTube" lewat `url_launcher`), penanganan gagal membuka tautan.
2. Bengkel: model, repository (hanya baris yang lolos RLS), daftar dengan pencarian nama atau alamat, pagination, detail (alamat, kontak, jam, layanan; bagian tanpa data disembunyikan atau berlabel "Belum tersedia"), tombol "Buka di peta" (geo URI atau URL Google Maps, fallback salin alamat) dan tombol "Minta bantuan mekanik".
3. Batas wilayah: kalimat cakupan permanen di layar Bengkel; pencarian yang menyebut nama wilayah di luar cakupan (contoh daftar pemeriksaan: Banda Aceh, Medan, Jakarta) menampilkan pesan batas wilayah, bukan daftar kosong. Jarak hanya tampil bila izin lokasi diberikan dan koordinat bengkel tersedia.
4. Lencana "Demo/Simulasi" pada baris `is_demo`.

**Selesai bila:** pencarian tanpa hasil menampilkan `EmptyState`; pencarian di luar wilayah menampilkan pesan batas; tidak ada rating atau jarak palsu; widget test mencakup kedua kondisi tersebut.

**Verifikasi:** `flutter test test/features/tutorials test/features/workshops`.

### M7. Bantuan mekanik

**Tugas**

1. Model `ServiceRequest`, `Mechanic`, `MechanicRequestService` (memanggil RPC bagian 5.4; mock untuk pengembangan).
2. Formulir permintaan: pilihan masalah umum dan deskripsi (10 sampai 500 karakter), lokasi dari GPS (`geolocator`, izin dijelaskan) atau alamat manual, kontak terisi dari profil dan dapat diubah, motor opsional; ringkasan dan `ConfirmationDialog` sebelum kirim; tombol kirim dinonaktifkan selama proses.
3. Detail permintaan: status terkini, riwayat waktu, hitung mundur `expires_at`, tombol batalkan dengan aturan bagian 6.6, pernyataan batas layanan.
4. Penanganan `expired`: lembar opsi kirim ulang, hubungi bengkel terverifikasi, dan kontak darurat bila `emergencyContacts` berisi.
5. Daftar permintaan saya (aktif dan riwayat); notifikasi in-app saat status berubah (dari pemicu database, atau dari mock).
6. Mode mock: `DemoMechanicSimulator` dengan lencana "Demo/Simulasi".
7. Sisi mekanik (Should, hanya bila diminta): jangan dikerjakan pada MVP.

**Selesai bila:** permintaan valid tersimpan dengan status `pending`; permintaan kedua saat ada yang aktif ditolak dengan pesan benar; pembatalan bekerja pada status yang diizinkan; kedaluwarsa menghasilkan `expired` dan lembar opsi; pengiriman berulang cepat hanya menghasilkan satu permintaan; unit test transisi dan aturan pembatalan lulus.

**Verifikasi:** `flutter test test/features/help_requests`.

### M8. Penyelesaian, aksesibilitas, dan QA

**Tugas**

1. Pastikan setiap layar data memiliki loading (skeleton), kosong, error dengan "Coba lagi", dan sukses; tangani offline dan timeout di semua repository (timeout 15 detik, satu kali retry otomatis untuk permintaan baca).
2. Audit aksesibilitas: `textScaler` 1,3 tanpa teks terpotong pada layar utama, target sentuh 48 dp, label semantik ikon, kontras token, dukungan `MediaQuery.disableAnimations`.
3. Jalankan seluruh daftar test case pada bagian 9.3 dan catat hasil nyata `Pass`, `Fail`, atau `Blocked` di `docs/test_report.md`; perbaiki semua `Fail` kritis dan uji ulang.
4. Lengkapi `README.md`: cara menjalankan (mock dan Supabase), cara menerapkan migrasi dan seed, daftar placeholder yang wajib diisi manusia (URL YouTube, `emergencyContacts`, data bengkel terverifikasi, interval templat), dan batas yang diketahui.
5. Bangun APK debug, periksa tidak ada secret di repositori (`git grep` untuk `service_role`, kunci API).

**Selesai bila:** seluruh fitur Must pada bagian 2.2 berfungsi; `docs/test_report.md` terisi dengan hasil nyata; tidak ada bug kritis terbuka; `flutter analyze` bersih; `flutter build apk --debug` berhasil.

**Verifikasi:** `flutter analyze && flutter test && flutter build apk --debug`, lalu telusuri alur utama S1 sampai S5 secara manual di emulator.

## 8. Peta Layar dan Rute

Navigasi memakai `go_router` dengan `StatefulShellRoute` untuk lima tab bawah: Beranda, Motor Saya, Bengkel, Tutorial, Profil. Rute bertanda "Ya" pada kolom Login memerlukan sesi; tanpa sesi, guard mengarahkan ke `/login` lalu kembali ke tujuan semula setelah masuk.

| Rute | Layar | Login | Milestone | Catatan |
| --- | --- | --- | --- | --- |
| `/splash` | Splash | Tidak | M0 | Rute awal; 3 sampai 5 detik |
| `/login` | Masuk | Tidak | M2 | Pesan error umum |
| `/register` | Daftar | Tidak | M2 | Validasi bagian 6.7 |
| `/forgot-password` | Lupa kata sandi | Tidak | M2 |  |
| `/home` | Beranda (tab 1) | Ya | M3, M5 | Motor aktif, pengingat terdekat, servis terakhir, tombol bantuan, lencana notifikasi |
| `/motors` | Motor Saya (tab 2) | Ya | M3 | Daftar dan tombol tambah |
| `/motors/new` | Tambah motor | Ya | M3 |  |
| `/motors/:id` | Detail motor | Ya | M3 | Kilometer, tautan ke servis dan pengingat |
| `/motors/:id/edit` | Ubah motor | Ya | M3 |  |
| `/motors/:id/mileage` | Perbarui kilometer | Ya | M3 | Dialog konfirmasi bagian 6.2 |
| `/motors/:id/services` | Riwayat servis | Ya | M4 | Filter jenis, total biaya |
| `/motors/:id/services/new` | Tambah servis | Ya | M4 | Dapat terisi awal dari pengingat |
| `/services/:id` | Detail servis | Ya | M4 | Ubah dan hapus |
| `/motors/:id/reminders` | Daftar pengingat | Ya | M5 | Urut paling parah |
| `/reminders/new` | Buat pengingat | Ya | M5 | Parameter `motorId` |
| `/reminders/:id` | Detail pengingat | Ya | M5 | Tandai selesai, catat servis |
| `/notifications` | Pusat notifikasi | Ya | M5 | Ketuk membuka layar terkait |
| `/workshops` | Bengkel (tab 3) | Ya | M6 | Kalimat cakupan wilayah permanen |
| `/workshops/:id` | Detail bengkel | Ya | M6 | Buka di peta, minta bantuan |
| `/tutorials` | Tutorial (tab 4) | Ya | M6 | Chip topik dan pencarian |
| `/tutorials/:id` | Detail tutorial | Ya | M6 | Buka YouTube |
| `/help` | Permintaan bantuan saya | Ya | M7 | Aktif dan riwayat |
| `/help/new` | Buat permintaan | Ya | M7 | Konfirmasi sebelum kirim |
| `/help/:id` | Detail permintaan | Ya | M7 | Status, hitung mundur, batalkan |
| `/profile` | Profil (tab 5) | Ya | M2 | Pengaturan notifikasi, logout |
| `/profile/edit` | Ubah profil | Ya | M2 |  |

Tautan dari notifikasi: `type = reminder` membuka `/reminders/:related_id`; `type = request_status` membuka `/help/:related_id`. Tombol "Butuh bantuan mekanik" tersedia di `/home` dan `/workshops/:id` dan menuju `/help/new`.

## 9. Pengujian yang Wajib

Tes ditulis bersamaan dengan fitur dan berada di `test/` dengan struktur yang mencerminkan `lib/`. Repository diuji dengan implementasi mock atau `mocktail`; tidak ada tes yang bergantung pada jaringan atau backend nyata.

### 9.1 Aturan pengujian

- Setiap fungsi di bagian 6 memiliki unit test yang memuat seluruh baris contoh input-output di tabelnya, ditambah kasus batas.
- Setiap layar data memiliki widget test untuk empat keadaan: loading, data, kosong, error (dengan tombol coba lagi berfungsi).
- Setiap formulir memiliki widget test: isian tidak valid menampilkan pesan dan tidak mengirim; isian valid memanggil repository tepat satu kali meskipun tombol ditekan dua kali cepat.
- Tes tidak boleh dihapus atau dilonggarkan agar lulus; perbaiki kode, bukan tes, kecuali spesifikasi memang berubah dan perubahan itu dicatat di laporan.
- Hasil dilaporkan apa adanya: `Pass`, `Fail`, atau `Blocked`. Jangan menyatakan lulus tanpa menjalankannya.

### 9.2 Skenario penerimaan manual (S1 sampai S5)

| ID | Skenario |
| --- | --- |
| S1 | Pengguna baru mendaftar, menambah motor, dan membuat pengingat ganti oli |
| S2 | Pengguna mencatat servis (tanggal, kilometer, biaya) dan melihat jadwal berikutnya terbentuk |
| S3 | Pengguna mencari tutorial "rantai" dan membuka detailnya |
| S4 | Pengguna membuat permintaan bantuan mekanik, melihat status, lalu membatalkan atau menunggu kedaluwarsa |
| S5 | Pengguna mencari bengkel di dalam dan di luar wilayah layanan |

### 9.3 Daftar test case

Kolom Jenis: U = unit test, W = widget test, M = manual di emulator, D = pemeriksaan database (skrip `rls_check.md`).

| ID | Skenario | Jenis | Hasil yang diharapkan | Milestone |
| --- | --- | --- | --- | --- |
| TC-01 | Registrasi dengan data valid | U, W | Akun dibuat dan masuk | M2 |
| TC-02 | Login dengan kredensial salah | U, W | Pesan error umum; tidak masuk | M2 |
| TC-03 | Tambah motor valid | U, W | Motor tersimpan dan tampil | M3 |
| TC-04 | Kilometer lebih kecil dari sebelumnya | U, W | Dialog konfirmasi koreksi | M3 |
| TC-05 | Simpan servis lalu buka ulang aplikasi | U, M | Catatan tampil; kilometer motor diperbarui | M4 |
| TC-06 | Kilometer atau tanggal mencapai ambang | U | Status sesuai tabel 6.3; satu notifikasi per perubahan | M5 |
| TC-07 | Tandai notifikasi dibaca | U, W | Status baca berubah dan lencana berkurang | M5 |
| TC-08 | Cari tutorial tanpa hasil | W | `EmptyState` dengan saran topik | M6 |
| TC-09 | Cari bengkel di area cakupan | W | Hanya data dari repository | M6 |
| TC-10 | Cari bengkel di luar wilayah | W | Pesan batas wilayah | M6 |
| TC-11 | Buat permintaan bantuan valid | U, W | Tersimpan dengan status `pending` | M7 |
| TC-12 | Status permintaan berubah | U, M | Status benar dan notifikasi in-app muncul | M7 |
| TC-13 | Akses data pengguna lain | D | Akses ditolak pada semua tabel | M2 |
| TC-14 | Jaringan lambat | W, M | Loading tampil; UI tidak membeku | M8 |
| TC-15 | API gagal | W | Pesan error dan tombol coba lagi | M8 |
| TC-16 | Pengaturan kurangi gerakan aktif | W | Animasi dekoratif dimatikan | M8 |
| TC-17 | Tombol kirim ditekan berulang | U, W | Hanya satu permintaan terkirim | M7 |
| TC-18 | Logout lalu buka rute terlindungi | W | Diarahkan ke login | M2 |
| TC-19 | Permintaan tanpa respons melewati 15 menit | U | Status `expired` dan opsi alternatif | M7 |
| TC-20 | Batalkan saat `pending` | U | Status `cancelled` | M7 |
| TC-21 | Permintaan kedua saat ada yang aktif | U | Ditolak dengan pesan benar | M7 |
| TC-22 | Tanggal servis masa depan atau biaya negatif | U, W | Input ditolak | M4 |
| TC-23 | Tautan YouTube gagal dibuka | W | Pesan dan opsi salin tautan | M6 |
| TC-24 | Font sistem 130% | W | Tidak ada teks terpotong pada layar utama | M8 |
| TC-25 | Splash dengan inisialisasi cepat dan lambat | W | Navigasi setelah minimal 3 detik; tidak menahan lebih dari 5 detik tanpa progres | M0 |

### 9.4 Cakupan minimum

Target praktis: unit test untuk seluruh `domain` dan validator; widget test untuk setiap komponen `core/widgets` dan setiap layar utama. Cakupan angka bukan tujuan; yang diwajibkan adalah semua baris contoh di bagian 6 dan seluruh TC di atas yang berjenis U atau W.

## 10. Definition of Done, Laporan, dan Pertanyaan

### 10.1 Definition of Done (per milestone dan akhir)

Sebuah milestone selesai hanya bila semua poin berikut benar:

- Semua tugas dan kriteria "Selesai bila" pada bagian 7 terpenuhi.
- `flutter analyze` tanpa temuan dan `flutter test` lulus; hasil perintah dilampirkan di laporan.
- Tidak ada teks UI selain Bahasa Indonesia, tidak ada hex atau ukuran ajaib di widget, tidak ada secret di repositori.
- Semua data contoh berlabel Demo/Simulasi; tidak ada data atau angka yang dikarang tampil sebagai nyata.
- Perubahan telah di-commit dalam cabang milestone dengan pesan commit yang bermakna.

Definition of Done akhir (setelah M8) adalah kriteria M8 ditambah: seluruh TC berjenis U dan W lulus, TC berjenis M dan D dieksekusi dan dicatat, serta daftar placeholder untuk manusia di `README.md` lengkap.

### 10.2 Format laporan setelah tiap milestone

Tulis laporan singkat (maksimal sekitar 25 baris) dengan bagian berikut:

1. Milestone dan cabang atau commit.
2. Yang dikerjakan (daftar berkas utama).
3. Hasil verifikasi: keluaran ringkas `flutter analyze` dan `flutter test` (jumlah lulus dan gagal).
4. Status TC terkait: `Pass`, `Fail`, atau `Blocked` beserta alasan.
5. Keputusan yang diambil di luar spesifikasi (bila ada) dan alasannya.
6. Risiko atau hal yang perlu ditinjau manusia.
7. Langkah berikutnya.

### 10.3 Kapan harus bertanya

Berhenti dan bertanya (satu pesan, dengan opsi yang Anda usulkan dan satu rekomendasi) bila:

- Dua bagian dokumen bertentangan atau ada aturan bisnis yang tidak terdefinisi.
- Perubahan akan menyentuh keputusan teknis di bagian 2.1 atau skema di bagian 5.
- Ada kebutuhan data nyata (nomor telepon darurat, video YouTube, data bengkel) yang tidak boleh dikarang.
- Anda perlu menambah dependensi baru di luar bagian 2.1.

Untuk keputusan kecil yang tidak memengaruhi perilaku (nama variabel, tata letak internal), putuskan sendiri dan catat di laporan.

### 10.4 Pemeriksaan akhir oleh manusia

Hal berikut tidak dapat diselesaikan agent dan harus dilakukan manusia sebelum demo:

- Mengisi URL YouTube sah pada seed tutorial dan memeriksa tiap tautan.
- Mengisi data bengkel terverifikasi (sumber dan tanggal verifikasi) atau mempertahankan label Demo/Simulasi.
- Mengisi `emergencyContacts` dengan nomor sah, atau membiarkan kosong.
- Memverifikasi nilai templat pengingat dengan buku manual motor.
- Menjalankan UAT dengan calon pengguna dan mencatat hasil.

## 11. Prompt Awal untuk Agent

Unduh dokumen ini sebagai Markdown, simpan di repositori sebagai `docs/AGENT_PRD.md` (dan, bila memakai Claude Code, rujuk dari `CLAUDE.md`), lalu berikan prompt berikut.

### 11.1 Prompt memulai proyek

```text
Anda adalah engineer Flutter senior. Bangun aplikasi Android "MotoCare" sesuai
dokumen docs/AGENT_PRD.md. Baca seluruh dokumen terlebih dahulu.

Aturan:
1. Kerjakan milestone M0 sampai M8 secara berurutan. Mulai dari M0.
2. Ikuti keputusan teknis di bagian 2.1; jangan mengganti paket atau arsitektur.
3. Jalankan `flutter analyze` dan `flutter test` sebelum setiap commit; semua harus bersih.
4. Jangan mengarang data (bengkel, rating, nomor telepon, ID video YouTube).
   Semua data contoh berlabel "Demo/Simulasi".
5. Jangan menaruh secret di repositori.
6. Jika spesifikasi ambigu atau bertentangan, berhenti dan tanya dengan opsi dan
   rekomendasi Anda (bagian 10.3).
7. Setelah menyelesaikan M0, tulis laporan sesuai bagian 10.2 lalu berhenti dan
   tunggu persetujuan saya sebelum M1.

Mulai sekarang dengan M0.
```

### 11.2 Prompt melanjutkan milestone

```text
Lanjutkan ke milestone M{n} di docs/AGENT_PRD.md. Pastikan kriteria "Selesai bila"
milestone sebelumnya masih lulus (`flutter analyze` dan `flutter test`). Kerjakan
semua tugas M{n}, tulis test yang diwajibkan, lalu kirim laporan sesuai 10.2 dan
berhenti.
```

### 11.3 Prompt memperbaiki temuan

```text
Temuan berikut gagal pada milestone M{n}: {deskripsi dan langkah reproduksi}.
Perbaiki penyebabnya (jangan melonggarkan tes), tambahkan tes regresi, jalankan
`flutter analyze` dan `flutter test`, lalu laporkan hasil nyata.
```

Meminta agent berhenti dan melapor di akhir tiap milestone memberi Anda titik tinjauan manusia; pada proyek tim, tiap anggota dapat memegang satu atau dua milestone dengan cabang terpisah selama kontrak repository (bagian 3.2) dihormati.


---

# ADDENDUM WAJIB — KEAMANAN, PRIVASI, AUDIT, DAN KESIAPAN RILIS

> Addendum ini melengkapi PRD utama. Semua ketentuan di sini wajib diterapkan untuk rilis yang terhubung ke backend nyata. Jangan menganggap audit selesai hanya karena aplikasi berhasil di-build atau seluruh unit test lulus.

## 12. Sasaran Keamanan dan Aturan Umum

### 12.1 Prinsip keamanan

1. Terapkan **least privilege**, deny-by-default, validasi sisi server, dan pemisahan data setiap pengguna.
2. Anggap semua input dari aplikasi sebagai input yang tidak tepercaya, termasuk `user_id`, `role`, ID motor, ID mekanik, status permintaan, harga/biaya, koordinat, dan metadata akun.
3. Jangan mengandalkan validasi UI, route guard, variabel lokal, atau tombol tersembunyi sebagai kontrol otorisasi.
4. Semua operasi sensitif harus divalidasi ulang di PostgreSQL/RPC. Operasi yang mengubah status tidak boleh dapat dilakukan dengan mengirim pembaruan tabel langsung.
5. Jangan mencatat kata sandi, token sesi, OTP, reset token, secret, isi sensitif profil, atau koordinat GPS lengkap ke log.
6. Gunakan data sintetis untuk pengujian. Jangan menyalin data pribadi pengguna nyata ke log, screenshot, seed, atau laporan.
7. Temuan keamanan tidak boleh ditutup hanya dengan menyembunyikan error atau melonggarkan tes.
8. Audit hanya dilakukan pada repositori, proyek Supabase, akun, dan perangkat uji yang memang diizinkan pemiliknya. Jangan melakukan pengujian terhadap pihak ketiga.

### 12.2 Klasifikasi data

| Data | Klasifikasi | Aturan |
| --- | --- | --- |
| Password, token sesi, reset token, secret | Sangat sensitif | Tidak boleh dicatat atau disimpan sendiri oleh aplikasi; gunakan mekanisme resmi |
| Nama, email, nomor telepon | Pribadi | Hanya ditampilkan kepada pihak yang memang memerlukan |
| Koordinat GPS dan alamat permintaan bantuan | Pribadi dan berisiko tinggi | Minta izin saat dibutuhkan, jelaskan tujuan, batasi akses dan masa penyimpanan |
| Plat nomor, motor, riwayat servis dan biaya | Pribadi | Hanya pemilik dan peran berwenang yang boleh mengakses |
| Katalog bengkel terverifikasi dan tutorial aktif | Publik terbatas | Baca sesuai kebijakan; perubahan hanya oleh admin yang sah |
| Data Demo/Simulasi | Sintetis | Harus diberi label dan tidak boleh menyerupai klaim data nyata |

### 12.3 Batas klaim keamanan

- Jangan mengklaim aplikasi “100% aman”, “bebas celah”, atau “lulus pentest” tanpa bukti pengujian yang terdokumentasi.
- Gunakan istilah `Pass`, `Fail`, `Blocked`, atau `Not Run` untuk setiap pemeriksaan.
- Bedakan hasil pengujian otomatis, tinjauan kode, pengujian manual, dan audit eksternal independen.
- Jika audit eksternal belum dilakukan, nyatakan secara eksplisit di laporan rilis.

## 13. Persyaratan Keamanan Implementasi

### 13.1 Rahasia, konfigurasi, dan sesi

1. `SUPABASE_URL` dan publishable/anon key boleh tersedia di aplikasi klien sesuai desain Supabase, tetapi **bukan** `service_role` key atau secret server.
2. Secret server hanya berada pada secret manager atau environment server yang sesuai. Jangan memasukkannya ke APK, `.env` yang di-commit, asset, log build, dokumentasi, atau pipeline artifact.
3. Sediakan `.env.example` berisi nama variabel dan nilai placeholder saja. Pastikan `.env`, file kredensial, signing key, keystore, dan hasil dump lokal masuk `.gitignore`.
4. Gunakan penyimpanan sesi yang disediakan SDK atau penyimpanan aman yang sesuai platform. Jangan menyimpan password atau access/refresh token di `SharedPreferences`, file biasa, atau log.
5. Saat logout, pastikan sesi lokal dibersihkan dan rute terlindungi tidak lagi dapat dibuka menggunakan state lama.
6. Periksa perilaku kedaluwarsa sesi, refresh token, reset kata sandi, email yang belum diverifikasi bila fitur verifikasi diaktifkan, dan kegagalan jaringan ketika autentikasi.
7. Pesan login gagal harus umum dan tidak membocorkan apakah email terdaftar. Alur lupa kata sandi juga tidak boleh mengungkap keberadaan akun.
8. Jangan membuat sistem PIN atau enkripsi buatan sendiri untuk menggantikan mekanisme autentikasi yang tersedia.

### 13.2 Otorisasi PostgreSQL dan RLS

1. Verifikasi `ENABLE ROW LEVEL SECURITY` pada **setiap** tabel yang dapat diakses melalui API, termasuk tabel baru yang ditambahkan nanti.
2. Audit kebijakan untuk operasi `SELECT`, `INSERT`, `UPDATE`, dan `DELETE` secara terpisah. Jangan menganggap satu policy otomatis mengamankan seluruh operasi.
3. Pastikan pengguna tidak dapat mengubah `profiles.role`, menetapkan dirinya menjadi `admin`/`mechanic`, mengubah pemilik baris, atau mengakses baris milik pengguna lain.
4. Periksa bahwa relasi `service_histories`, `maintenance_reminders`, `service_requests`, dan `mechanics` divalidasi terhadap pemilik atau penugasan yang benar di sisi database.
5. Tinjau semua fungsi `SECURITY DEFINER`: gunakan `SET search_path` yang aman, skema objek yang eksplisit bila diperlukan, hak `EXECUTE` minimum, dan pemeriksaan `auth.uid()` serta kepemilikan/penugasan di dalam fungsi.
6. Cabut hak eksekusi fungsi sensitif dari `PUBLIC`/role yang tidak memerlukannya, lalu berikan hanya ke role yang sesuai.
7. Pastikan akses tabel dan fungsi tidak bisa melewati RLS melalui view, function, trigger, atau konfigurasi API yang terlalu luas.
8. Pastikan tabel internal, log, tabel audit, dan tabel konfigurasi tidak terekspos ke API publik tanpa alasan dan kebijakan yang jelas.
9. Pastikan operasi yang mengubah status permintaan dilakukan melalui RPC tervalidasi. Uji juga ID acak, ID milik pengguna lain, pemanggilan berulang, dan dua permintaan bersamaan.
10. Jangan mengaktifkan policy yang mengizinkan pengguna mengubah seluruh baris `mechanics` apabila hal itu memungkinkan pengguna menaikkan `is_available`, mengganti `workshop_id`, atau mengubah data yang semestinya dikendalikan admin. Batasi kolom yang dapat diubah atau gunakan RPC khusus.
11. `is_admin()` dan policy terkait harus ditinjau untuk mencegah rekursi policy, eskalasi hak, dan akses tak sengaja. Jika memakai fungsi `SECURITY DEFINER`, pastikan implementasinya tidak dapat dimanipulasi oleh pengguna biasa.
12. Tambahkan pengujian untuk akun anonim, pengguna biasa, mekanik yang ditugaskan, mekanik yang tidak ditugaskan, admin, dan dua pengguna terpisah.

### 13.3 Validasi dan integritas data

1. Validasi semua masukan di UI dan ulangi validasi yang relevan pada database/RPC.
2. Gunakan parameter query atau API terparameterisasi; jangan merangkai SQL dari input pengguna.
3. Tetapkan batas panjang untuk teks, ukuran payload, pagination, dan frekuensi operasi. Tangani karakter Unicode, spasi, string kosong, nilai ekstrem, dan input tidak valid.
4. Validasi relasi foreign key dan kepemilikan pada operasi perubahan, bukan hanya ketika data ditampilkan.
5. Pastikan biaya tidak negatif, kilometer tidak keluar rentang, tanggal servis tidak di masa depan, dan status permintaan mengikuti transisi yang sah.
6. Gunakan constraint dan transaksi database untuk mencegah duplikasi permintaan aktif serta kondisi race.
7. Untuk operasi berulang, gunakan mekanisme idempotensi atau constraint server-side agar retry tidak membuat catatan/permintaan ganda.
8. Jangan mempercayai `user_id`, `role`, `mechanic_id`, `status`, `accepted_at`, `completed_at`, atau `expires_at` yang dikirim langsung dari klien.
9. Periksa konsistensi zona waktu dan batas hari pada pengingat. Uji perubahan tanggal, pergantian zona waktu perangkat, dan waktu perangkat yang tidak akurat.
10. Pastikan penghapusan motor dan perilaku `ON DELETE CASCADE` dijelaskan sebelum konfirmasi; jangan menghapus data lebih luas daripada yang dinyatakan di UI.

### 13.4 Lokasi dan privasi

1. Izin GPS hanya diminta saat pengguna menggunakan fitur yang memerlukannya. Alamat manual harus tetap tersedia.
2. Jelaskan tujuan penggunaan lokasi sebelum meminta izin. Jika izin ditolak, aplikasi tetap dapat digunakan melalui alamat manual.
3. Jangan mengambil lokasi di latar belakang; fitur tersebut di luar lingkup kecuali disetujui secara eksplisit.
4. Jangan mengirim koordinat ke layanan eksternal kecuali diperlukan oleh aksi yang dipilih pengguna dan tujuan tersebut dijelaskan.
5. Hindari koordinat lengkap di log, analytics, crash report, dan notifikasi layar kunci.
6. Nomor telepon dan alamat pengguna hanya boleh terlihat oleh pihak yang diperlukan untuk permintaan bantuan terkait. Uji bahwa pengguna lain tidak dapat membacanya.
7. Dokumentasikan data yang dikumpulkan, tujuan, lokasi penyimpanan, pihak yang dapat mengakses, serta cara pengguna meminta penghapusan akun/data.
8. Tentukan kebijakan retensi untuk akun, permintaan bantuan, dan lokasi. Jangan menyimpan lokasi lebih lama dari kebutuhan yang disetujui.
9. Sebelum rilis, tinjau kewajiban privasi dan perlindungan data yang berlaku di Indonesia bersama pemilik proyek; jangan menyatakan kepatuhan hukum tanpa peninjauan yang sesuai.

### 13.5 Jaringan, tautan, dan tampilan error

1. Gunakan HTTPS untuk semua endpoint jaringan produksi. Jangan menonaktifkan validasi sertifikat TLS.
2. Batasi domain/jenis tautan yang diterima untuk tutorial dan tautan eksternal. Jangan membuka skema berbahaya atau URL yang tidak tervalidasi.
3. Tampilkan pesan error yang ramah; jangan menampilkan stack trace, query SQL, token, atau detail konfigurasi kepada pengguna.
4. Tangani timeout, offline, respons server yang tidak valid, dan retry secara terbatas. Operasi tulis tidak boleh diulang secara membabi buta jika hasil permintaan sebelumnya belum diketahui.
5. Pastikan deep link dan parameter rute tidak dapat membuka data privat tanpa pemeriksaan sesi dan otorisasi backend.
6. Jangan menampilkan lokasi, nomor telepon, atau deskripsi masalah di notifikasi layar kunci secara default.

### 13.6 Ketahanan aplikasi Android

1. Periksa konfigurasi release Android, izin yang diminta, exported components, intent/deep link, backup, dan konfigurasi network security.
2. Minta hanya izin yang diperlukan. Tidak boleh ada izin SMS, kontak, mikrofon, kamera, atau lokasi latar belakang tanpa fitur dan persetujuan eksplisit.
3. Pastikan data sensitif tidak masuk ke logcat, screenshot debug otomatis, atau pesan crash.
4. Gunakan signing key release di luar repositori dan simpan cadangannya secara aman. Jangan memakai debug signing sebagai prosedur rilis produksi.
5. Jika menerapkan obfuscation, simpan simbol pemetaan secara aman untuk diagnosis crash; obfuscation bukan pengganti kontrol akses backend.
6. Jangan menambahkan root detection, certificate pinning, atau mekanisme anti-tamper yang kompleks tanpa kebutuhan dan pengujian kompatibilitas yang jelas.

## 14. Audit Keamanan Wajib

Audit dilakukan pada proyek uji dan akun yang diizinkan. Semua hasil harus disimpan di `docs/security/`.

### 14.1 Audit konfigurasi dan rahasia

- [ ] Cari secret, token, password, private key, dan `service_role` key di seluruh repo serta riwayat Git yang relevan.
- [ ] Periksa `.gitignore`, `.env.example`, file konfigurasi, workflow CI, artefak build, dan log.
- [ ] Jika secret pernah ter-commit, anggap secret telah bocor: cabut/rotasi terlebih dahulu, lalu bersihkan riwayat sesuai prosedur proyek.
- [ ] Pastikan APK tidak berisi secret server atau kredensial pribadi.
- [ ] Pastikan mode Mock/Demo tidak aktif secara tidak sengaja pada build produksi.

### 14.2 Audit autentikasi dan otorisasi

- [ ] Uji registrasi, login, logout, reset kata sandi, sesi kedaluwarsa, dan pemulihan sesi.
- [ ] Uji rute terlindungi sebelum login, setelah logout, dan setelah sesi tidak berlaku.
- [ ] Uji bahwa pengguna tidak dapat mengubah role atau membuat akun admin/mekanik melalui metadata atau payload klien.
- [ ] Uji akses silang pengguna A dan B untuk setiap tabel dan operasi CRUD.
- [ ] Uji IDOR/BOLA secara terkontrol: ganti ID motor, servis, pengingat, notifikasi, bengkel, dan permintaan dengan ID milik akun uji lain.
- [ ] Uji akses mekanik hanya terhadap permintaan yang benar-benar ditugaskan kepadanya.
- [ ] Uji bahwa status permintaan tidak bisa diubah langsung dari klien dan transisi tidak sah ditolak.
- [ ] Uji semua fungsi RPC dengan sesi anonim, pengguna biasa, role yang tepat, ID milik orang lain, parameter invalid, dan pemanggilan berulang.

### 14.3 Audit database dan Supabase

- [ ] Verifikasi RLS aktif pada semua tabel yang dapat diakses API.
- [ ] Periksa policy per operasi dan role database; pastikan tidak ada policy permisif yang meniadakan pembatasan.
- [ ] Periksa grants, fungsi `SECURITY DEFINER`, `search_path`, hak `EXECUTE`, trigger, view, dan extension.
- [ ] Uji eskalasi role dan manipulasi kolom sensitif seperti `user_id`, `role`, `is_available`, `mechanic_id`, dan `status`.
- [ ] Uji konkurensi dua permintaan bantuan, retry, dan kedaluwarsa untuk memastikan integritas status.
- [ ] Pastikan data seed sintetis, tidak memuat informasi pribadi, dan selalu berlabel Demo/Simulasi.
- [ ] Pastikan backup, pemulihan, dan prosedur rotasi secret diketahui pemilik proyek sebelum produksi.

### 14.4 Audit dependensi dan kode

- [ ] Jalankan `flutter pub outdated` dan tinjau dependensi yang usang; jangan melakukan upgrade besar tanpa tes regresi.
- [ ] Periksa advisori keamanan yang relevan untuk paket Flutter/Dart dan konfigurasi Android.
- [ ] Jalankan pemeriksaan dependensi/secret scanning yang tersedia di CI atau alat lokal yang disetujui.
- [ ] Tinjau penggunaan `url_launcher`, parsing URL, penyimpanan lokal, serialisasi, logging, dan error handling.
- [ ] Cari penggunaan `print`, debug logging sensitif, konfigurasi TLS yang dinonaktifkan, dan penggunaan secret yang tidak semestinya.
- [ ] Tinjau kode SQL untuk injection, otorisasi yang hilang, transaksi yang tidak atomik, dan race condition.

### 14.5 Pengujian keamanan aplikasi secara manual

Pengujian dilakukan hanya pada build dan backend uji milik proyek:

- [ ] Manipulasi ID objek untuk memastikan data pengguna lain tetap tertutup.
- [ ] Kirim field tambahan atau field terlarang untuk memastikan server menolak perubahan role/pemilik/status.
- [ ] Uji input sangat panjang, format tidak valid, karakter khusus, dan nilai batas.
- [ ] Uji pengiriman permintaan berulang cepat dan permintaan serentak.
- [ ] Uji pemanggilan endpoint tanpa sesi, dengan sesi kedaluwarsa, dan dengan role yang salah.
- [ ] Uji pemulihan aplikasi setelah offline, timeout, atau respons gagal di tengah operasi.
- [ ] Uji bahwa data sensitif tidak muncul di log, pesan error, notifikasi, atau layar yang dapat diakses pengguna lain.
- [ ] Jangan menguji denial-of-service, melakukan pemindaian terhadap pihak ketiga, atau menjalankan eksploitasi destruktif pada sistem produksi.

### 14.6 Audit privasi dan aksesibilitas

- [ ] Tinjau izin Android dan pastikan setiap izin memiliki alasan fitur yang jelas.
- [ ] Pastikan pengguna dapat memakai alamat manual jika tidak memberi izin lokasi.
- [ ] Periksa kebocoran data pribadi di notifikasi, log, screenshot, dan analytics.
- [ ] Verifikasi kontras warna, label semantik, ukuran target sentuh, text scaling 130%, dan `disableAnimations`.
- [ ] Pastikan label status tidak hanya mengandalkan warna.
- [ ] Periksa penghapusan akun/data dan kebijakan retensi yang disepakati sebelum rilis produksi.

## 15. Matriks Uji Keamanan Tambahan

Tambahkan kasus berikut ke `docs/security/security_test_report.md`. Semua hasil harus mencatat build/commit, lingkungan, akun uji, langkah, hasil aktual, bukti yang sudah disamarkan, status, dan tindak lanjut.

| ID | Kasus | Hasil yang diharapkan | Prioritas |
| --- | --- | --- | --- |
| SEC-01 | Pengguna A membaca motor milik B | Ditolak/tidak ada data | Kritis |
| SEC-02 | Pengguna A mengubah atau menghapus servis milik B | Ditolak | Kritis |
| SEC-03 | Pengguna mengubah `profiles.role` menjadi `admin` | Ditolak | Kritis |
| SEC-04 | Pengguna membuat atau memodifikasi akun mekanik melalui payload klien | Ditolak | Kritis |
| SEC-05 | Pengguna mengubah `user_id` pada baris miliknya | Ditolak | Kritis |
| SEC-06 | Pengguna mengubah status permintaan lewat update tabel langsung | Ditolak | Kritis |
| SEC-07 | Mekanik mengubah permintaan yang tidak ditugaskan kepadanya | Ditolak | Kritis |
| SEC-08 | RPC dipanggil dengan ID milik pengguna lain | Ditolak | Kritis |
| SEC-09 | RPC dipanggil dengan transisi status yang tidak sah | Ditolak | Tinggi |
| SEC-10 | Dua permintaan bantuan dikirim bersamaan | Maksimal satu permintaan aktif | Tinggi |
| SEC-11 | Pengguna anonim membaca tabel privat | Ditolak | Kritis |
| SEC-12 | Secret server dicari pada repo dan APK | Tidak ditemukan | Kritis |
| SEC-13 | Token/password muncul di log atau pesan error | Tidak muncul | Tinggi |
| SEC-14 | Izin lokasi ditolak | Alamat manual tetap berfungsi | Sedang |
| SEC-15 | Input teks ekstrem atau format salah | Ditolak dengan aman | Tinggi |
| SEC-16 | URL tutorial menggunakan skema/domain tidak diizinkan | Tidak dibuka | Sedang |
| SEC-17 | Sesi kedaluwarsa membuka rute terlindungi | Dialihkan ke login | Tinggi |
| SEC-18 | Permintaan baca mengalami timeout | Pesan aman dan retry terbatas | Sedang |
| SEC-19 | Build produksi memakai konfigurasi Mock/Demo | Build/check rilis menolak atau memberi kegagalan jelas | Tinggi |
| SEC-20 | Backup atau ekspor berisi data pengguna | Akses dibatasi dan data ditangani sesuai kebijakan | Tinggi |

## 16. Penanganan Temuan dan Kriteria Lulus Audit

### 16.1 Tingkat temuan

- **Kritis:** kebocoran data lintas pengguna, eskalasi hak admin, secret server terekspos, bypass autentikasi/RLS, atau perubahan status sensitif tanpa otorisasi.
- **Tinggi:** akses data sensitif oleh role yang tidak berhak, manipulasi permintaan, kerentanan integritas yang berdampak besar, atau kebocoran kredensial/token.
- **Sedang:** kelemahan dengan dampak terbatas yang membutuhkan kondisi tertentu.
- **Rendah:** masalah dengan dampak keamanan kecil atau hardening tambahan.

Tingkat akhir harus ditentukan berdasarkan dampak dan kemungkinan eksploitasi yang benar-benar ditemukan, bukan sekadar label otomatis alat.

### 16.2 Aturan penutupan temuan

1. Setiap temuan memiliki ID, tingkat, komponen, dampak, langkah reproduksi yang aman, bukti tersamarkan, pemilik perbaikan, dan status.
2. Temuan Kritis dan Tinggi harus diperbaiki serta diuji ulang sebelum rilis produksi.
3. Temuan yang belum diperbaiki harus dinyatakan terbuka beserta mitigasi dan persetujuan tertulis pemilik proyek.
4. Setelah perbaikan, tambahkan tes regresi agar masalah tidak muncul kembali.
5. Jangan menulis `Pass` jika tes tidak dijalankan. Gunakan `Blocked` bila lingkungan atau kredensial uji tidak tersedia, dan `Not Run` bila belum dikerjakan.
6. Audit otomatis tidak menggantikan tinjauan manual terhadap RLS, RPC, alur role, dan privasi.

### 16.3 Kriteria lulus keamanan sebelum rilis

Rilis produksi hanya dapat direkomendasikan bila:

- Tidak ada temuan Kritis atau Tinggi yang belum ditangani.
- Pengujian RLS lintas pengguna lulus untuk seluruh tabel dan operasi yang relevan.
- Tidak ada secret server dalam repo, riwayat aktif yang diketahui, artefak, atau APK.
- Fungsi RPC sensitif telah diuji untuk autentikasi, kepemilikan, role, transisi status, dan pemanggilan berulang.
- Pengujian privasi lokasi, nomor telepon, log, dan notifikasi lulus.
- `flutter analyze`, `flutter test`, build release, dan seluruh tes penerimaan yang diwajibkan lulus atau memiliki status Blocked yang disetujui secara eksplisit.
- `docs/security/security_test_report.md` dan `docs/security/security_findings.md` tersedia dan berisi hasil nyata.
- Pemilik proyek menyetujui risiko tersisa dan konfigurasi produksi.

## 17. Milestone Tambahan — M9 Audit Keamanan dan Release Gate

M9 dilakukan setelah M8 dan sebelum distribusi produksi. M9 tidak menggantikan M2 atau M8; pemeriksaan keamanan dasar tetap harus berjalan sejak awal.

### Tugas M9

1. Buat `docs/security/security_test_report.md` dan `docs/security/security_findings.md`.
2. Jalankan seluruh checklist bagian 14 dan kasus SEC-01 sampai SEC-20 pada lingkungan uji.
3. Perkuat RLS, grants, RPC, trigger, dan constraint berdasarkan temuan. Jangan menambal masalah otorisasi hanya pada UI.
4. Jalankan secret scanning pada repo dan inspeksi konfigurasi/artefak APK.
5. Tinjau dependensi dan konfigurasi Android release.
6. Uji akses lintas akun dengan minimal dua akun pengguna, satu akun mekanik uji bila alur mekanik tersedia, serta akun admin yang disiapkan secara aman.
7. Uji privasi dan penyimpanan data, izin lokasi, logout, sesi kedaluwarsa, error handling, dan notifikasi.
8. Perbaiki seluruh temuan Kritis/Tinggi dan tambahkan tes regresi.
9. Jalankan ulang `flutter analyze`, `flutter test`, seluruh pemeriksaan database yang relevan, dan `flutter build apk --release` dengan konfigurasi produksi yang benar.
10. Buat ringkasan release gate: hasil aktual, temuan terbuka, risiko residual, batasan audit, dan persetujuan pemilik proyek.

### Kriteria selesai M9

- Semua checklist telah berstatus `Pass`, `Fail`, `Blocked`, atau `Not Run`; tidak ada status kosong.
- Semua temuan Kritis/Tinggi sudah diperbaiki dan diverifikasi ulang atau rilis ditahan.
- Tes RLS dan RPC benar-benar dijalankan pada proyek Supabase uji; tidak cukup hanya menulis skrip.
- Tidak ada secret server dalam APK maupun repo yang diperiksa.
- Laporan menyatakan secara jelas apabila pengujian tertentu belum dapat dilakukan.
- Build release berhasil, konfigurasi Demo/Mock tidak aktif tanpa sengaja, dan pemilik proyek menyetujui rilis.

**Verifikasi M9:** jalankan semua perintah pengujian yang tersedia, skrip database di `supabase/tests/`, inspeksi secret/release, dan checklist manual. Catat versi alat serta commit yang diuji. Jangan mengarang perintah dari alat keamanan yang belum dipasang; jika diperlukan alat tambahan, jelaskan opsi dan minta persetujuan sebelum menambah dependensi.

## 18. Pembaruan Aturan Kerja Agent

Tambahkan aturan berikut ke bagian 1.2 dan prompt awal bagian 11:

- Keamanan harus diperiksa sejak M2 dan setiap perubahan schema, policy, RPC, autentikasi, atau data sensitif harus menyertakan tes keamanan/regresi.
- Jangan menganggap `flutter analyze`, `flutter test`, atau build APK sebagai bukti bahwa RLS dan keamanan backend sudah benar.
- Jangan menjalankan pengujian keamanan pada target di luar lingkungan dan akun yang diizinkan.
- Jangan menampilkan nilai secret saat melaporkan temuan. Samarkan token, nomor telepon, alamat, dan koordinat dalam bukti.
- M9 wajib dilakukan sebelum rilis produksi. Jika pengujian backend nyata terhalang karena Supabase belum tersedia, tandai `Blocked` dan jangan mengklaim audit keamanan lulus.
- Jika menemukan kerentanan Kritis/Tinggi, hentikan langkah rilis, laporkan dampak dan reproduksi yang aman, perbaiki setelah persetujuan bila perubahan menyentuh keputusan teknis, lalu jalankan tes ulang.
- Jangan menambah paket keamanan atau layanan eksternal tanpa persetujuan bila berada di luar keputusan teknis yang sudah ditetapkan.

### Tambahan prompt awal agent

Sisipkan instruksi berikut ke prompt bagian 11.1:

```text
Keamanan dan privasi:
1. Terapkan kontrol keamanan sejak M2, bukan hanya pada akhir proyek.
2. Audit RLS, grants, RPC SECURITY DEFINER, role, akses lintas pengguna,
   penyimpanan sesi, secret, lokasi, log, dan konfigurasi Android.
3. Tambahkan tes regresi untuk setiap temuan keamanan.
4. Jangan mengklaim audit lulus tanpa menjalankan pengujian pada lingkungan
   yang berwenang dan melaporkan hasil aktual.
5. Setelah M8, kerjakan M9 Audit Keamanan dan Release Gate sebelum rilis.
6. Jika ada temuan Kritis/Tinggi, hentikan rekomendasi rilis sampai temuan
   diperbaiki dan diverifikasi ulang.
```

---

## Catatan tinjauan untuk pemilik proyek

Hal berikut perlu ditinjau secara khusus sebelum implementasi atau sebelum backend dinyatakan siap:

1. **Policy `profiles_update`:** pastikan pengguna tidak dapat mengubah `role` melalui pembaruan profil; uji juga perilaku policy dan fungsi `is_admin()` agar tidak menimbulkan rekursi atau eskalasi hak.
2. **Policy `mechanics`:** kebijakan pembaruan seluruh baris berisiko memberi mekanik kemampuan mengubah kolom yang semestinya dikelola admin, misalnya `is_available` atau `workshop_id`. Batasi kolom atau gunakan RPC dengan otorisasi yang jelas.
3. **RPC `advance_request`:** pastikan fungsi secara atomik memeriksa penugasan mekanik, status saat ini, transisi yang sah, dan kondisi race sebelum mengubah baris.
4. **RPC `expire_stale_requests`:** pastikan fungsi hanya mengubah permintaan milik pemanggil yang memenuhi kondisi kedaluwarsa, dan tidak dapat dipakai untuk mengubah permintaan pengguna lain.
5. **Kolom sensitif dan grants:** tinjau apakah seluruh kolom `service_requests` yang memuat telepon, alamat, dan koordinat benar-benar perlu dapat dibaca setiap role yang saat ini memiliki akses.
6. **Akses publik dan seed:** jangan memasukkan data bengkel atau mekanik nyata sebelum sumber, izin penggunaan, dan verifikasinya jelas.

Catatan ini adalah daftar risiko untuk diperiksa, bukan pernyataan bahwa kerentanan telah berhasil dieksploitasi. Temuan baru boleh dinyatakan terkonfirmasi setelah tes yang sesuai benar-benar dijalankan.
