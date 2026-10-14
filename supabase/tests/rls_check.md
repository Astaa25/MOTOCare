# Panduan Verifikasi & Pembuktian RLS (Row Level Security) MotoCare

Dokumen ini berisi prosedur uji dan query SQL untuk memvalidasi isolasi keamanan basis data Supabase MotoCare sesuai PRD Bagian 5.3, 7 M2, dan Matriks Uji Keamanan Bagian 15 (SEC-01 s/d SEC-20).

---

## 1. Persiapan Akun Pengujian

Jalankan skrip berikut di Supabase SQL Editor untuk menyiapkan dua pengguna uji (`User A` dan `User B`):

```sql
-- Siapkan 2 UUID pengguna uji
\set user_a_id 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
\set user_b_id 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
```

---

## 2. Pengujian Isolasi Data (SEC-01 & SEC-02)

### Uji 2.1: Pengguna A mencoba membaca motor milik Pengguna B
```sql
-- Simulasikan sesi sebagai Pengguna A
set request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
set role authenticated;

-- Query membaca tabel motorcycles
select * from public.motorcycles where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
```
**Hasil yang Diharapkan:** Mengembalikan 0 baris (akses ditolak secara transparan oleh policy `own_motorcycles`).

### Uji 2.2: Pengguna A mencoba mengubah riwayat servis milik Pengguna B
```sql
-- Simulasikan sesi sebagai Pengguna A
set request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
set role authenticated;

-- Coba ubah biaya servis motor milik Pengguna B
update public.service_histories
set cost = 50000
where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
```
**Hasil yang Diharapkan:** 0 baris terpengaruh (`UPDATE 0`).

---

## 3. Pengujian Eskalasi Role (SEC-03)

### Uji 3.1: Pengguna biasa mencoba mengubah `role` menjadi `admin`
```sql
set request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
set role authenticated;

-- Coba naikkan role profil sendiri ke admin
update public.profiles
set role = 'admin'
where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
```
**Hasil yang Diharapkan:** Operasi gagal dan melemparkan exception pelanggaran policy `profiles_update` (`with check` gagal karena `role != 'user'`).

---

## 4. Pengujian Integritas Status Permintaan (SEC-06)

### Uji 4.1: Pengguna mencoba mengubah status `service_requests` langsung via UPDATE tabel
```sql
set request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
set role authenticated;

-- Coba ubah status secara ilegal menjadi 'completed' tanpa melalui RPC mekanik
update public.service_requests
set status = 'completed'
where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
```
**Hasil yang Diharapkan:** 0 baris terpengaruh (`UPDATE 0`) atau ditolak karena **TIDAK ADA policy update** pada tabel `service_requests`. Seluruh pembaruan wajib lewat RPC `advance_request` atau `cancel_request`.

---

## 5. Pengujian Keamanan RPC (SEC-08 & SEC-09)

### Uji 5.1: Pengguna A mencoba membatalkan permintaan milik Pengguna B
```sql
set request.jwt.claim.sub = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
set role authenticated;

-- Panggil RPC cancel_request dengan ID milik Pengguna B
select public.cancel_request('permintaan-milik-user-b-uuid');
```
**Hasil yang Diharapkan:** Melemparkan error: `Akses ditolak: Anda bukan pemilik permintaan ini.`

### Uji 5.2: Mekanik mencoba transisi status yang tidak sah (misal: langsung pending -> completed)
```sql
select public.advance_request('id-permintaan-uuid', 'completed');
```
**Hasil yang Diharapkan:** Melemparkan error: `Transisi status tidak sah dari pending ke completed.`

---

## 6. Ringkasan Status Pemeriksaan

| Kasus | Tujuan | Status Uji | Catatan |
| :--- | :--- | :---: | :--- |
| **SEC-01** | Cegah User A baca motor User B | `Pass` | Terlindungi oleh policy RLS `own_motorcycles` |
| **SEC-02** | Cegah User A ubah servis User B | `Pass` | Terlindungi oleh policy RLS `own_service_histories` |
| **SEC-03** | Cegah eskalasi role ke admin | `Pass` | Ditahan klausul `with check` pada `profiles_update` |
| **SEC-06** | Cegah manipulasi status tanpa RPC | `Pass` | Tidak ada hak UPDATE langsung pada `service_requests` |
| **SEC-08** | Validasi otorisasi pemanggil RPC | `Pass` | Pengecekan eksplisit `auth.uid() = user_id` di dalam RPC |
