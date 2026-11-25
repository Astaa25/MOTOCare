-- ============================================================================
-- MotoCare Production & Comprehensive Seeder (Supabase Live Schema Aligned)
-- Memuat:
-- - 3 Akun Owner (Pelanggan), 1 Admin, 40 Montir Mitra (auth.users + profiles)
-- - 50 Bengkel Mitra Resmi (Kota Lhokseumawe & Kabupaten Aceh Utara)
-- - 40 Data Montir Lengkap dengan Koordinat GPS & Keahlian
-- - 8 Sepeda Motor Populer Indonesia (vehicles)
-- - 6 Riwayat Servis & 6 Pengingat Servis Aktif
-- - 10 Video Tutorial Perawatan Mandiri
-- - 3 Riwayat Panggilan Darurat Selesai + Ulasan (reviews) + Notifikasi
-- Sandi seragam seluruh akun seeder: Password123
-- ============================================================================

create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

-- ============================================================================
-- 0. SEED AUTH.USERS & PROFILES (Owner, Admin, & 40 Montir Mitra)
-- Catatan: role menggunakan enum user_role ('owner', 'mechanic', 'admin')
-- ============================================================================
do $$
declare
  i int;
  uid uuid;
  uemail text;
  uname text;
  uphone text;
  names text[] := array[
    'Andi Saputra', 'Budi Santoso', 'Rahmat Hidayat', 'Teuku Iskandar', 'Hasan Basri',
    'Dedi Kurniawan', 'Zulkifli', 'Muhammad Rizki', 'Saifullah', 'Faisal Akbar',
    'Mukhlis Amin', 'Ridwan Syahputra', 'Mahdi Sulaiman', 'Irwansyah', 'T. Munandar',
    'Surya Darma', 'Azhari Pratama', 'Junaidi', 'Bukhari Muslim', 'M. Nasir',
    'Ilham Maulana', 'Rudi Irawan', 'Safrizal', 'Murthala', 'Hamdani',
    'Zulfikar', 'Syahrul Ramadhan', 'Teuku Zulkarnain', 'Mahfud Ridwan', 'Cut Rizal',
    'Hendra Gunawan', 'Dedi Supriadi', 'Muslem Daud', 'Anwar Sadat', 'Fachrurrazi',
    'Teuku Fadhil', 'Munawir', 'Marzuki', 'Wahyu Pratama', 'Iskandar Muda'
  ];
  phones text[] := array[
    '081269112201', '081269112202', '081269112203', '085299881104', '081269112205',
    '081269112206', '085377221107', '081362889908', '085260114409', '081264332210',
    '085277443311', '081399001112', '085261778813', '081266224414', '085355112215',
    '081370889916', '085269334417', '081260445518', '085388112219', '081366554420',
    '085270119921', '081268331122', '085399442223', '081377005524', '085262883325',
    '081263117726', '081269112227', '081269112228', '081269112229', '081269112230',
    '081269112231', '081269112232', '081269112233', '081269112234', '081269112235',
    '081269112236', '081269112237', '081269112238', '081269112239', '081269112240'
  ];
begin
  -- A. Akun Pemilik Motor (Owner) & Administrator
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  )
  values
    (
      '00000000-0000-0000-0000-000000000000',
      '00000000-0000-0000-0000-000000000001',
      'authenticated', 'authenticated',
      'pengguna.demo@motocare.id',
      crypt('Password123', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Abrar Astafaraiz","phone_number":"081234567890","role":"owner"}',
      now(), now()
    ),
    (
      '00000000-0000-0000-0000-000000000002',
      '00000000-0000-0000-0000-000000000002',
      'authenticated', 'authenticated',
      'admin@motocare.id',
      crypt('Password123', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Administrator MotoCare","phone_number":"081299999999","role":"admin"}',
      now(), now()
    ),
    (
      '00000000-0000-0000-0000-000000000000',
      '00000000-0000-0000-0000-000000000003',
      'authenticated', 'authenticated',
      'rizky.owner@motocare.id',
      crypt('Password123', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Rizky Pratama","phone_number":"081265001122","role":"owner"}',
      now(), now()
    ),
    (
      '00000000-0000-0000-0000-000000000000',
      '00000000-0000-0000-0000-000000000004',
      'authenticated', 'authenticated',
      'putri.owner@motocare.id',
      crypt('Password123', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Putri Amanda","phone_number":"085277889900","role":"owner"}',
      now(), now()
    )
  on conflict (id) do update set
    encrypted_password = excluded.encrypted_password,
    email_confirmed_at = excluded.email_confirmed_at,
    raw_user_meta_data = excluded.raw_user_meta_data;

  -- Koreksi instance_id admin jika perlu & pastikan profiles lengkap
  update auth.users
  set instance_id = '00000000-0000-0000-0000-000000000000'
  where id = '00000000-0000-0000-0000-000000000002';

  insert into public.profiles (id, full_name, email, phone_number, role, is_simulation)
  values
    ('00000000-0000-0000-0000-000000000001', 'Abrar Astafaraiz', 'pengguna.demo@motocare.id', '081234567890', 'owner'::user_role, false),
    ('00000000-0000-0000-0000-000000000002', 'Administrator MotoCare', 'admin@motocare.id', '081299999999', 'admin'::user_role, false),
    ('00000000-0000-0000-0000-000000000003', 'Rizky Pratama', 'rizky.owner@motocare.id', '081265001122', 'owner'::user_role, false),
    ('00000000-0000-0000-0000-000000000004', 'Putri Amanda', 'putri.owner@motocare.id', '085277889900', 'owner'::user_role, false)
  on conflict (id) do update set
    full_name = excluded.full_name,
    email = excluded.email,
    phone_number = excluded.phone_number,
    role = excluded.role,
    is_simulation = false;

  -- B. 40 Akun Montir Mitra (auth.users + public.profiles)
  for i in 1..40 loop
    uid := ('a1111111-0000-0000-0000-' || lpad(i::text, 12, '0'))::uuid;
    uname := names[i];
    uphone := phones[i];
    uemail := 'mekanik' || i::text || '@motocare.id';
    if i = 2 then
      uemail := 'budi.mekanik@motocare.id';
    end if;

    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    )
    values (
      '00000000-0000-0000-0000-000000000000',
      uid,
      'authenticated', 'authenticated',
      uemail,
      crypt('Password123', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      jsonb_build_object('full_name', uname, 'phone_number', uphone, 'role', 'mechanic'),
      now(), now()
    ) on conflict (id) do update set
      email = excluded.email,
      encrypted_password = excluded.encrypted_password,
      email_confirmed_at = excluded.email_confirmed_at,
      raw_user_meta_data = excluded.raw_user_meta_data;

    insert into public.profiles (id, full_name, email, phone_number, role, is_simulation)
    values (uid, uname, uemail, uphone, 'mechanic'::user_role, false)
    on conflict (id) do update set
      full_name = excluded.full_name,
      email = excluded.email,
      phone_number = excluded.phone_number,
      role = 'mechanic'::user_role,
      is_simulation = false;
  end loop;
end $$;

-- ============================================================================
-- 1. WORKSHOPS: 50 Bengkel Mitra Terverifikasi (Lhokseumawe & Aceh Utara)
-- ============================================================================
insert into public.workshops (
  id, name, address, service_region, latitude, longitude,
  phone_number, operating_hours, services_offered, google_rating, is_verified_partner
)
values
  -- Kota Lhokseumawe (25 Bengkel)
  ('11111111-0000-0000-0000-000000000001', 'Bengkel Resmi Honda AHASS Samudera Motor', 'Jl. Merdeka Barat No. 12, Banda Sakti, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1801, 97.1405, '081269000111', '08:00 - 17:00 WIB', array['Servis Rutin', 'Ganti Oli', 'Tune Up', 'Ganti Ban', 'Kelistrikan'], 4.8, true),
  ('11111111-0000-0000-0000-000000000002', 'Bengkel Yamaha Alfa Scorpii Cunda', 'Jl. Medan - Banda Aceh Km. 274, Cunda, Muara Dua, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1672, 97.1320, '081269000222', '08:30 - 18:00 WIB', array['Servis Injeksi', 'Ganti Oli', 'Servis Rem', 'Cek Aki', 'Tune Up'], 4.7, true),
  ('11111111-0000-0000-0000-000000000003', 'Sentra Ban Tubeless & Aki Pase', 'Jl. Pase Indah No. 5, Banda Sakti, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1820, 97.1440, '081269000333', '08:00 - 20:00 WIB', array['Tambal Ban Tubeless', 'Ganti Ban', 'Cek Aki', 'Strum Aki'], 4.6, true),
  ('11111111-0000-0000-0000-000000000004', 'Bengkel Suzuki Rakan Motor Lhokseumawe', 'Jl. Perdagangan No. 88, Banda Sakti, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1790, 97.1430, '081269000444', '08:00 - 17:00 WIB', array['Servis Ringan', 'Ganti Oli', 'Servis Karburator', 'Ganti Busi'], 4.5, true),
  ('11111111-0000-0000-0000-000000000005', 'Bengkel Cipta Mandiri Motor', 'Jl. Samudera Baru No. 21, Banda Sakti, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1845, 97.1390, '081269000555', '08:00 - 18:00 WIB', array['Ganti Oli', 'Servis Rem', 'Setel Klep', 'Ganti Rantai'], 4.7, true),
  ('11111111-0000-0000-0000-000000000006', 'Bengkel Presisi Kandang Motor', 'Jl. Elak Simpang Kandang, Blang Mangat, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1420, 97.1210, '081269000666', '08:00 - 17:30 WIB', array['Servis Mesin', 'Ganti Oli', 'Bongkar Pasang Mesin', 'Kelistrikan'], 4.8, true),
  ('11111111-0000-0000-0000-000000000007', 'Bengkel Harapan Motor Blang Panyang', 'Jl. Medan-Banda Aceh Km. 268, Muara Satu, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1550, 97.1080, '081269000777', '07:30 - 18:00 WIB', array['Ganti Oli', 'Tambal Ban', 'Servis Darurat 24 Jam', 'Ganti Busi'], 4.6, true),
  ('11111111-0000-0000-0000-000000000008', 'Bengkel Injeksi Bintang Motor Panggoi', 'Jl. Line Pipa No. 14, Muara Dua, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1610, 97.1250, '081269000888', '08:30 - 17:30 WIB', array['Scan ECU Injeksi', 'Ganti Oli', 'Pembersihan Injektor', 'Servis CVT'], 4.9, true),
  ('11111111-0000-0000-0000-000000000009', 'Bengkel Berkah Service Batuphat', 'Jl. Rancong Indah No. 3, Batuphat Timur, Muara Satu, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1480, 97.0980, '081269000999', '08:00 - 17:30 WIB', array['Servis Rutin', 'Ganti Oli', 'Servis CVT Matic', 'Ganti Kampas Rem'], 4.6, true),
  ('11111111-0000-0000-0000-000000000010', 'Sentosa Jaya Motor Ujong Blang', 'Jl. Pantai Ujong Blang No. 7, Banda Sakti, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1910, 97.1520, '081269001010', '08:30 - 18:00 WIB', array['Tambal Ban Tubeless', 'Ganti Oli', 'Servis Karbu', 'Cuci Motor Salju'], 4.5, true),
  ('11111111-0000-0000-0000-000000000011', 'Bengkel Mitra Sejati Meunasah Masjid', 'Jl. Cut Meutia No. 34, Cunda, Muara Dua, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1710, 97.1380, '081269001111', '08:00 - 17:00 WIB', array['Servis Injeksi', 'Ganti Oli', 'Ganti Ban', 'Tune Up'], 4.7, true),
  ('11111111-0000-0000-0000-000000000012', 'Pos Panggilan Darurat Alue Awe', 'Jl. Simpang Len No. 9, Alue Awe, Muara Dua, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1580, 97.1420, '081269001212', '24 Jam (Siaga Panggilan)', array['Mogok Darurat', 'Tambal Ban Keliling', 'Cek Aki', 'Derek Motor'], 4.9, true),
  ('11111111-0000-0000-0000-000000000013', 'Bengkel Karbu & Injeksi Punteuet', 'Jl. Medan-Banda Aceh Km. 278, Punteuet, Blang Mangat, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1380, 97.1350, '081269001313', '08:00 - 18:00 WIB', array['Ganti Oli', 'Tune Up Injeksi', 'Ganti Shockbreaker', 'Ganti Rantai'], 4.6, true),
  ('11111111-0000-0000-0000-000000000014', 'Bengkel Loskala Service', 'Jl. Pelabuhan Lama No. 50, Loskala, Banda Sakti, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1760, 97.1510, '081269001414', '08:30 - 17:30 WIB', array['Ganti Oli', 'Ganti Busi', 'Servis Rem', 'Cek Kelistrikan'], 4.5, true),
  ('11111111-0000-0000-0000-000000000015', 'Bengkel Reuleuet Jaya Motor', 'Jl. Kampus Unimal Buket Indah, Blang Mangat, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1460, 97.1150, '081269001515', '08:00 - 17:00 WIB', array['Servis Ringan', 'Ganti Oli', 'Tambal Ban'], 4.7, true),
  ('11111111-0000-0000-0000-000000000016', 'Bengkel Mon Geudong Perkasa', 'Jl. Pase Baru No. 16, Banda Sakti, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1740, 97.1410, '081269001616', '08:00 - 18:00 WIB', array['Servis CVT', 'Ganti Oli', 'Rem'], 4.6, true),
  ('11111111-0000-0000-0000-000000000041', 'Bengkel Banda Sakti Utama', 'Jl. Samudera No. 40, Banda Sakti, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1815, 97.1420, '081269000411', '08:00 - 17:00 WIB', array['Servis Ringan', 'Ganti Oli', 'Busi'], 4.7, true),
  ('11111111-0000-0000-0000-000000000042', 'Bengkel Lancang Garam Motor', 'Jl. Tgk Chik Di Tunong No. 8, Banda Sakti, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1780, 97.1450, '081269000422', '08:00 - 18:00 WIB', array['Ganti Ban', 'Tambal Ban', 'Ganti Oli'], 4.6, true),
  ('11111111-0000-0000-0000-000000000043', 'Bengkel Tumpok Teungoh Service', 'Jl. Merdeka Timur No. 56, Banda Sakti, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1830, 97.1380, '081269000433', '08:00 - 17:00 WIB', array['Servis Karbu', 'Ganti Kampas Rem', 'Ganti Oli'], 4.5, true),
  ('11111111-0000-0000-0000-000000000044', 'Bengkel Hagu Barat Laut', 'Jl. Rel Kereta Api No. 12, Banda Sakti, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1860, 97.1350, '081269000444', '08:00 - 17:30 WIB', array['Servis Rutin', 'Ganti Oli', 'Aki'], 4.6, true),
  ('11111111-0000-0000-0000-000000000045', 'Bengkel Muara Dua Cemerlang', 'Jl. Line Pipa No. 30, Muara Dua, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1630, 97.1290, '081269000455', '08:30 - 17:30 WIB', array['Servis Injeksi', 'Ganti Oli', 'Shockbreaker'], 4.8, true),
  ('11111111-0000-0000-0000-000000000046', 'Bengkel Panggoi Indah Motor', 'Jl. Panggoi Baru No. 7, Muara Dua, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1600, 97.1230, '081269000466', '08:00 - 18:00 WIB', array['Tune Up', 'Ganti Oli', 'Tambal Ban'], 4.7, true),
  ('11111111-0000-0000-0000-000000000047', 'Bengkel Blang Poroh Jaya', 'Jl. Simpang Len No. 25, Muara Dua, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1570, 97.1360, '081269000477', '08:00 - 17:00 WIB', array['Servis CVT', 'Ganti Oli', 'Rem'], 4.6, true),
  ('11111111-0000-0000-0000-000000000048', 'Bengkel Batuphat Barat Service', 'Jl. ExxonMobil No. 19, Muara Satu, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1450, 97.0920, '081269000488', '08:00 - 17:30 WIB', array['Servis Mesin', 'Ganti Oli', 'Rantai'], 4.7, true),
  ('11111111-0000-0000-0000-000000000049', 'Bengkel Padang Sakti Motor', 'Jl. Medan-Banda Aceh Km. 265, Muara Satu, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1510, 97.1020, '081269000499', '08:00 - 18:00 WIB', array['Tambal Ban Tubeless', 'Ganti Oli', 'Tune Up'], 4.6, true),

  -- Kabupaten Aceh Utara (25 Bengkel)
  ('11111111-0000-0000-0000-000000000017', 'Bengkel Resmi Honda AHASS Krueng Geukueh', 'Jl. Medan-Banda Aceh Km. 261, Dewantara, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.2390, 97.0280, '081269000177', '08:00 - 17:00 WIB', array['Servis Rutin', 'Ganti Oli', 'Kelistrikan', 'Ganti Ban'], 4.8, true),
  ('11111111-0000-0000-0000-000000000018', 'Bengkel Barokah Motor Lhoksukon', 'Jl. Teuku Umar No. 45, Kota Lhoksukon, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.0450, 97.3180, '081269000188', '08:00 - 17:00 WIB', array['Servis Rutin', 'Ganti Oli', 'Bongkar Mesin', 'Ganti Kampas Rem'], 4.7, true),
  ('11111111-0000-0000-0000-000000000019', 'Bengkel Panton Labu Mandiri Jaya', 'Jl. Pasar Baru No. 18, Panton Labu, Tanah Jambo Aye, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.0120, 97.4850, '081269000199', '08:30 - 17:30 WIB', array['Servis Rutin', 'Ganti Oli', 'Servis Injeksi', 'Ganti Ban'], 4.6, true),
  ('11111111-0000-0000-0000-000000000020', 'Bengkel Dewantara Prima Motor', 'Jl. Pelabuhan Krueng Geukueh, Dewantara, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.2410, 97.0250, '081269000200', '08:00 - 18:00 WIB', array['Servis Rutin', 'Ganti Oli', 'Cek Kelistrikan', 'Servis Rem & Rantai'], 4.7, true),
  ('11111111-0000-0000-0000-000000000021', 'Bengkel Samudera Pasai Geudong', 'Jl. Medan-Banda Aceh Km. 282, Geudong, Samudera, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.1340, 97.2020, '081269000211', '08:00 - 18:00 WIB', array['Servis Rutin', 'Ganti Oli', 'Tambal Ban', 'Setel Klep'], 4.6, true),
  ('11111111-0000-0000-0000-000000000022', 'Bengkel Muara Batu Speed', 'Jl. Banda Aceh - Medan Km. 250, Krueng Mane, Muara Batu, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.2450, 96.9610, '081269000222', '08:00 - 17:30 WIB', array['Tune Up', 'Ganti Oli', 'Bongkar Karburator', 'Servis Rantai'], 4.7, true),
  ('11111111-0000-0000-0000-000000000023', 'Bengkel Injeksi Matangkuli Sentosa', 'Jl. Simpang Keude Matangkuli No. 8, Matangkuli, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.0280, 97.2890, '081269000233', '08:30 - 17:00 WIB', array['Servis Injeksi', 'Scan ECU', 'Ganti Oli', 'Cek Kelistrikan'], 4.8, true),
  ('11111111-0000-0000-0000-000000000024', 'Bengkel Tanah Luas Presisi', 'Jl. Blang Jruen No. 14, Tanah Luas, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.0610, 97.2140, '081269000244', '08:00 - 17:00 WIB', array['Ganti Oli', 'Ganti Busi', 'Servis Kampas Rem'], 4.5, true),
  ('11111111-0000-0000-0000-000000000025', 'Bengkel Reuleuet Indah Motor', 'Jl. Bandara Malikussaleh No. 12, Muara Batu, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.2280, 96.9850, '081269000255', '08:00 - 17:30 WIB', array['Ganti Oli', 'Servis Rem', 'Tambal Ban'], 4.6, true),
  ('11111111-0000-0000-0000-000000000026', 'Bengkel Seunuddon Pesisir Motor', 'Jl. Pantai Ulee Rubek No. 5, Seunuddon, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.0820, 97.4580, '081269000266', '08:00 - 17:00 WIB', array['Tambal Ban Tubeless', 'Ganti Oli', 'Servis Karbu'], 4.5, true),
  ('11111111-0000-0000-0000-000000000027', 'Bengkel Baktiya Auto Care', 'Jl. Medan-Banda Aceh Km. 305, Alue Ie Puteh, Baktiya, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.0180, 97.4080, '081269000277', '08:00 - 17:30 WIB', array['Servis Injeksi', 'Ganti Oli', 'Tune Up'], 4.7, true),
  ('11111111-0000-0000-0000-000000000028', 'Bengkel Syamtalira Aron Motor', 'Jl. Simpang Muling No. 20, Syamtalira Aron, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.1120, 97.1850, '081269000288', '08:00 - 18:00 WIB', array['Ganti Oli', 'Tambal Ban', 'Kelistrikan', 'Ganti Rantai'], 4.6, true),
  ('11111111-0000-0000-0000-000000000029', 'Bengkel Buloh Blang Ara Speed', 'Jl. Simpang Elak Kuta Makmur, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.1050, 97.1120, '081269000299', '08:00 - 17:00 WIB', array['Ganti Oli', 'Bongkar Mesin', 'Setel Karbu'], 4.5, true),
  ('11111111-0000-0000-0000-000000000030', 'Bengkel Tambon Baroh Motor', 'Jl. Medan-Banda Aceh Km. 260, Tambon Baroh, Dewantara, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.2380, 97.0390, '081269000300', '07:30 - 18:00 WIB', array['Ganti Oli', 'Tambal Ban Tubeless', 'Servis CVT'], 4.7, true),
  ('11111111-0000-0000-0000-000000000031', 'Bengkel Nibong Perkasa', 'Jl. Keude Nibong No. 17, Nibong, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.0510, 97.2650, '081269000311', '08:00 - 17:00 WIB', array['Ganti Oli', 'Servis Rutin', 'Ganti Kampas Rem'], 4.6, true),
  ('11111111-0000-0000-0000-000000000032', 'Bengkel Meurah Mulia Sejahtera', 'Jl. Simpang Rangkaya No. 12, Meurah Mulia, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.0920, 97.1620, '081269000322', '08:00 - 17:30 WIB', array['Ganti Oli', 'Tune Up', 'Tambal Ban', 'Cek Kelistrikan'], 4.6, true),
  ('11111111-0000-0000-0000-000000000033', 'Bengkel Kuta Makmur Motor', 'Jl. Keude Blang Ara No. 5, Kuta Makmur, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.1102, 97.1085, '081269000333', '08:00 - 17:00 WIB', array['Ganti Oli', 'Servis Mesin', 'Tambal Ban'], 4.5, true),
  ('11111111-0000-0000-0000-000000000034', 'Bengkel Syamtalira Bayu Sejahtera', 'Jl. Medan-Banda Aceh Km. 280, Syamtalira Bayu, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.1290, 97.1780, '081269000344', '08:00 - 18:00 WIB', array['Servis Rutin', 'Ganti Oli', 'Kelistrikan'], 4.7, true),
  ('11111111-0000-0000-0000-000000000035', 'Bengkel Baktiya Perkasa', 'Jl. Alue Ie Puteh No. 22, Baktiya, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.0120, 97.4100, '081269000355', '08:00 - 17:00 WIB', array['Ganti Ban', 'Tambal Ban', 'Ganti Oli'], 4.5, true),
  ('11111111-0000-0000-0000-000000000036', 'Bengkel Tanah Jambo Aye Motor', 'Jl. Perdagangan No. 10, Panton Labu, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 4.9850, 97.4950, '081269000366', '08:00 - 17:30 WIB', array['Servis Rutin', 'Ganti Oli', 'Bongkar Mesin'], 4.7, true),
  ('11111111-0000-0000-0000-000000000037', 'Bengkel Samudera Pase Service', 'Jl. Malikussaleh No. 18, Geudong, Samudera, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.1320, 97.2050, '081269000377', '08:00 - 18:00 WIB', array['Servis Injeksi', 'Ganti Oli', 'Servis Rem'], 4.8, true),
  ('11111111-0000-0000-0000-000000000038', 'Bengkel Seunuddon Jaya', 'Jl. Simpang Tiga Ulee Rubek, Seunuddon, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.0750, 97.4620, '081269000388', '08:00 - 17:00 WIB', array['Tambal Ban', 'Ganti Oli', 'Rantai'], 4.5, true),
  ('11111111-0000-0000-0000-000000000039', 'Bengkel Muara Batu Mandiri', 'Jl. Pasar Krueng Mane No. 4, Muara Batu, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.2420, 96.9550, '081269000399', '08:00 - 17:30 WIB', array['Servis CVT', 'Ganti Oli', 'Tune Up'], 4.7, true),
  ('11111111-0000-0000-0000-000000000040', 'Bengkel Dewantara Teknik', 'Jl. Kompleks Arun No. 15, Krueng Geukueh, Kabupaten Aceh Utara', 'Kabupaten Aceh Utara', 5.2350, 97.0250, '081269000400', '08:00 - 18:00 WIB', array['Scan Injeksi', 'Ganti Oli', 'Kelistrikan'], 4.8, true),
  ('11111111-0000-0000-0000-000000000050', 'Bengkel Kumbang Punteuet Motor', 'Jl. Elak Punteuet No. 11, Blang Mangat, Kota Lhokseumawe', 'Kota Lhokseumawe', 5.1390, 97.1310, '081269000500', '08:00 - 17:00 WIB', array['Ganti Oli', 'Servis Rutin', 'Kelistrikan'], 4.6, true)
on conflict (id) do update set
  name = excluded.name,
  address = excluded.address,
  service_region = excluded.service_region,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  phone_number = excluded.phone_number,
  operating_hours = excluded.operating_hours,
  services_offered = excluded.services_offered,
  google_rating = excluded.google_rating,
  is_verified_partner = excluded.is_verified_partner;

-- ============================================================================
-- 2. MECHANICS: 40 Montir Mitra Lengkap dengan Koordinat GPS & Keahlian
-- ============================================================================
insert into public.mechanics (
  id, user_id, full_name, phone_number, specialties, service_area,
  latitude, longitude, is_available, is_verified, is_simulation, rating_avg
)
values
  ('b1111111-0000-0000-0000-000000000001', 'a1111111-0000-0000-0000-000000000001', 'Andi Saputra', '081269112201', array['Servis Rutin', 'Ganti Oli', 'Kelistrikan'], 'Banda Sakti & Muara Dua, Kota Lhokseumawe', 5.1805, 97.1410, true, true, false, 4.9),
  ('b1111111-0000-0000-0000-000000000002', 'a1111111-0000-0000-0000-000000000002', 'Budi Santoso', '081269112202', array['Servis Injeksi', 'Tune Up', 'Ban Bocor'], 'Cunda, Panggoi & Muara Dua', 5.1678, 97.1325, true, true, false, 4.9),
  ('b1111111-0000-0000-0000-000000000003', 'a1111111-0000-0000-0000-000000000003', 'Rahmat Hidayat', '081269112203', array['Tambal Ban Tubeless', 'Cek Aki'], 'Banda Sakti & Ujong Blang', 5.1825, 97.1445, true, true, false, 4.8),
  ('b1111111-0000-0000-0000-000000000004', 'a1111111-0000-0000-0000-000000000004', 'Teuku Iskandar', '085299881104', array['Servis Karburator', 'Ganti Busi'], 'Pusat Kota & Keude Aceh, Lhokseumawe', 5.1792, 97.1432, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000005', 'a1111111-0000-0000-0000-000000000005', 'Hasan Basri', '081269112205', array['Servis Rem', 'Rantai & Gear'], 'Banda Sakti & Hagu', 5.1848, 97.1392, true, true, false, 4.8),
  ('b1111111-0000-0000-0000-000000000006', 'a1111111-0000-0000-0000-000000000006', 'Dedi Kurniawan', '081269112206', array['Bongkar Mesin', 'Kelistrikan'], 'Simpang Kandang & Blang Mangat', 5.1422, 97.1214, true, true, false, 4.8),
  ('b1111111-0000-0000-0000-000000000007', 'a1111111-0000-0000-0000-000000000007', 'Zulkifli', '085377221107', array['Darurat Mogok', 'Tambal Ban'], 'Blang Panyang & Muara Satu', 5.1555, 97.1082, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000008', 'a1111111-0000-0000-0000-000000000008', 'Muhammad Rizki', '081362889908', array['Scan ECU Injeksi', 'Servis CVT'], 'Panggoi & Meunasah Mee', 5.1612, 97.1255, true, true, false, 4.9),
  ('b1111111-0000-0000-0000-000000000009', 'a1111111-0000-0000-0000-000000000009', 'Saifullah', '085260114409', array['Servis CVT Matic', 'Kampas Rem'], 'Batuphat & Rancong, Muara Satu', 5.1482, 97.0985, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000010', 'a1111111-0000-0000-0000-000000000010', 'Faisal Akbar', '081264332210', array['Tambal Ban', 'Servis Ringan'], 'Ujong Blang & Loskala', 5.1912, 97.1524, true, true, false, 4.6),
  ('b1111111-0000-0000-0000-000000000011', 'a1111111-0000-0000-0000-000000000011', 'Mukhlis Amin', '085277443311', array['Servis Injeksi', 'Ganti Oli'], 'Cunda & Meunasah Masjid', 5.1712, 97.1384, true, true, false, 4.8),
  ('b1111111-0000-0000-0000-000000000012', 'a1111111-0000-0000-0000-000000000012', 'Ridwan Syahputra', '081399001112', array['Mogok Darurat', 'Derek Motor'], 'Alue Awe, Buket Rata & Kampus PNL', 5.1582, 97.1422, true, true, false, 4.9),
  ('b1111111-0000-0000-0000-000000000013', 'a1111111-0000-0000-0000-000000000013', 'Mahdi Sulaiman', '085261778813', array['Tune Up', 'Shockbreaker'], 'Punteuet & Blang Mangat', 5.1382, 97.1355, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000014', 'a1111111-0000-0000-0000-000000000014', 'Irwansyah', '081266224414', array['Servis Rutin', 'Kelistrikan'], 'Krueng Geukueh & Tambon Baroh, Dewantara', 5.2392, 97.0285, true, true, false, 4.8),
  ('b1111111-0000-0000-0000-000000000015', 'a1111111-0000-0000-0000-000000000015', 'T. Munandar', '085355112215', array['Cek Aki', 'Servis Rem'], 'Paloh Gadeng & Dewantara', 5.2412, 97.0252, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000016', 'a1111111-0000-0000-0000-000000000016', 'Surya Darma', '081370889916', array['Bongkar Mesin', 'Ganti Oli'], 'Kota Lhoksukon & Sekitarnya', 5.0452, 97.3182, true, true, false, 4.8),
  ('b1111111-0000-0000-0000-000000000017', 'a1111111-0000-0000-0000-000000000017', 'Azhari Pratama', '085269334417', array['Servis Injeksi', 'Ganti Ban'], 'Panton Labu & Tanah Jambo Aye', 5.0122, 97.4852, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000018', 'a1111111-0000-0000-0000-000000000018', 'Junaidi', '081260445518', array['Tambal Ban', 'Setel Klep'], 'Geudong & Samudera Pase', 5.1342, 97.2022, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000019', 'a1111111-0000-0000-0000-000000000019', 'Bukhari Muslim', '085388112219', array['Tune Up', 'Bongkar Karbu'], 'Krueng Mane & Muara Batu', 5.2452, 96.9612, true, true, false, 4.8),
  ('b1111111-0000-0000-0000-000000000020', 'a1111111-0000-0000-0000-000000000020', 'M. Nasir', '081366554420', array['Ganti Oli', 'Tambal Ban'], 'Reuleuet & Kampus Utama Unimal', 5.2282, 96.9852, true, true, false, 4.6),
  ('b1111111-0000-0000-0000-000000000021', 'a1111111-0000-0000-0000-000000000021', 'Ilham Maulana', '085270119921', array['Scan ECU', 'Kelistrikan'], 'Matangkuli & Keude Pirak', 5.0282, 97.2892, true, true, false, 4.8),
  ('b1111111-0000-0000-0000-000000000022', 'a1111111-0000-0000-0000-000000000022', 'Rudi Irawan', '081268331122', array['Ganti Busi', 'Kampas Rem'], 'Blang Jruen & Tanah Luas', 5.0612, 97.2142, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000023', 'a1111111-0000-0000-0000-000000000023', 'Safrizal', '085399442223', array['Tambal Ban', 'Servis Karbu'], 'Seunuddon & Ulee Rubek', 5.0822, 97.4582, true, true, false, 4.6),
  ('b1111111-0000-0000-0000-000000000024', 'a1111111-0000-0000-0000-000000000024', 'Murthala', '081377005524', array['Servis Injeksi', 'Tune Up'], 'Alue Ie Puteh & Baktiya', 5.0182, 97.4082, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000025', 'a1111111-0000-0000-0000-000000000025', 'Hamdani', '085262883325', array['Kelistrikan', 'Rantai & Gear'], 'Simpang Muling & Syamtalira Aron', 5.1122, 97.1852, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000026', 'a1111111-0000-0000-0000-000000000026', 'Zulfikar', '081263117726', array['Servis Rutin', 'Ganti Oli'], 'Syamtalira Bayu & Beunot', 5.1292, 97.1782, true, true, false, 4.8),
  ('b1111111-0000-0000-0000-000000000027', 'a1111111-0000-0000-0000-000000000027', 'Syahrul Ramadhan', '081269112227', array['Servis Mesin', 'Tambal Ban'], 'Kuta Makmur & Simpang Elak', 5.1105, 97.1088, true, true, false, 4.6),
  ('b1111111-0000-0000-0000-000000000028', 'a1111111-0000-0000-0000-000000000028', 'Teuku Zulkarnain', '081269112228', array['Kelistrikan', 'Ganti Aki'], 'Syamtalira Bayu & Punteuet', 5.1295, 97.1785, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000029', 'a1111111-0000-0000-0000-000000000029', 'Mahfud Ridwan', '081269112229', array['Ganti Ban', 'Tambal Ban'], 'Baktiya & Alue Ie Puteh', 5.0125, 97.4105, true, true, false, 4.6),
  ('b1111111-0000-0000-0000-000000000030', 'a1111111-0000-0000-0000-000000000030', 'Cut Rizal', '081269112230', array['Bongkar Mesin', 'Ganti Oli'], 'Tanah Jambo Aye & Panton Labu', 4.9852, 97.4955, true, true, false, 4.8),
  ('b1111111-0000-0000-0000-000000000031', 'a1111111-0000-0000-0000-000000000031', 'Hendra Gunawan', '081269112231', array['Servis Injeksi', 'Servis Rem'], 'Geudong & Samudera Pase', 5.1322, 97.2055, true, true, false, 4.8),
  ('b1111111-0000-0000-0000-000000000032', 'a1111111-0000-0000-0000-000000000032', 'Dedi Supriadi', '081269112232', array['Tambal Ban', 'Rantai & Gear'], 'Seunuddon & Ulee Rubek', 5.0752, 97.4622, true, true, false, 4.6),
  ('b1111111-0000-0000-0000-000000000033', 'a1111111-0000-0000-0000-000000000033', 'Muslem Daud', '081269112233', array['Servis CVT', 'Tune Up'], 'Muara Batu & Krueng Mane', 5.2422, 96.9555, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000034', 'a1111111-0000-0000-0000-000000000034', 'Anwar Sadat', '081269112234', array['Scan Injeksi', 'Kelistrikan'], 'Dewantara & Krueng Geukueh', 5.2355, 97.0255, true, true, false, 4.9),
  ('b1111111-0000-0000-0000-000000000035', 'a1111111-0000-0000-0000-000000000035', 'Fachrurrazi', '081269112235', array['Servis Ringan', 'Ganti Busi'], 'Banda Sakti & Simpang Empat', 5.1818, 97.1422, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000036', 'a1111111-0000-0000-0000-000000000036', 'Teuku Fadhil', '081269112236', array['Ganti Ban', 'Tambal Ban'], 'Lancang Garam & Keude Aceh', 5.1782, 97.1452, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000037', 'a1111111-0000-0000-0000-000000000037', 'Munawir', '081269112237', array['Servis Injeksi', 'Shockbreaker'], 'Muara Dua & Cunda Plaza', 5.1632, 97.1292, true, true, false, 4.8),
  ('b1111111-0000-0000-0000-000000000038', 'a1111111-0000-0000-0000-000000000038', 'Marzuki', '081269112238', array['Tune Up', 'Tambal Ban'], 'Panggoi & Kampus Unimal Buket Indah', 5.1602, 97.1235, true, true, false, 4.7),
  ('b1111111-0000-0000-0000-000000000039', 'a1111111-0000-0000-0000-000000000039', 'Wahyu Pratama', '081269112239', array['Servis Mesin', 'Rantai & Gear'], 'Batuphat Barat & Pelabuhan Krueng Geukueh', 5.1452, 97.0925, true, true, false, 4.8),
  ('b1111111-0000-0000-0000-000000000040', 'a1111111-0000-0000-0000-000000000040', 'Iskandar Muda', '081269112240', array['Ganti Oli', 'Kelistrikan'], 'Kumbang Punteuet & Simpang Len', 5.1392, 97.1312, true, true, false, 4.8)
on conflict (id) do update set
  user_id = excluded.user_id,
  full_name = excluded.full_name,
  phone_number = excluded.phone_number,
  specialties = excluded.specialties,
  service_area = excluded.service_area,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  is_available = excluded.is_available,
  is_verified = excluded.is_verified,
  is_simulation = false,
  rating_avg = excluded.rating_avg;

-- ============================================================================
-- 3. TUTORIALS (10 Video Tutorial Resmi — Resolusi Dinamis Enum Category)
-- ============================================================================
do $$
declare
  v_enum_type text;
  v_labels text[];
  v_cat text;

  function_cat_oli text;
  function_cat_rem text;
  function_cat_ban text;
  function_cat_aki text;
  function_cat_rantai text;
  function_cat_busi text;
begin
  select t.typname, array_agg(e.enumlabel order by e.enumsortorder)
  into v_enum_type, v_labels
  from information_schema.columns c
  join pg_type t on t.typname = c.udt_name
  join pg_enum e on e.enumtypid = t.oid
  where c.table_schema = 'public'
    and c.table_name = 'tutorials'
    and c.column_name = 'category'
  group by t.typname;

  if v_labels is not null and array_length(v_labels, 1) > 0 then
    select coalesce((select l from unnest(v_labels) l where lower(l) like '%oli%' limit 1), v_labels[1]) into function_cat_oli;
    select coalesce((select l from unnest(v_labels) l where lower(l) like '%rem%' or lower(l) like '%brake%' limit 1), v_labels[1]) into function_cat_rem;
    select coalesce((select l from unnest(v_labels) l where lower(l) like '%ban%' or lower(l) like '%tire%' limit 1), v_labels[1]) into function_cat_ban;
    select coalesce((select l from unnest(v_labels) l where lower(l) like '%aki%' or lower(l) like '%baterai%' or lower(l) like '%listrik%' limit 1), v_labels[1]) into function_cat_aki;
    select coalesce((select l from unnest(v_labels) l where lower(l) like '%rantai%' or lower(l) like '%cvt%' limit 1), v_labels[1]) into function_cat_rantai;
    select coalesce((select l from unnest(v_labels) l where lower(l) like '%busi%' or lower(l) like '%mesin%' limit 1), v_labels[1]) into function_cat_busi;

    execute format($q$
      insert into public.tutorials (
        id, title, category, keywords, description, youtube_url, youtube_video_id, has_safety_warning, safety_warning_text
      )
      values
        ('22222222-0000-0000-0000-000000000001', 'Cara Mengganti Oli Mesin Motor Sendiri di Rumah', %L::%I, array['oli','mesin','ganti oli'], 'Panduan lengkap menguras dan mengisi oli mesin motor dengan aman serta memeriksa takaran volume oli.', 'https://www.youtube.com/watch?v=2Ax9qDmNJ-c', '2Ax9qDmNJ-c', true, 'Pastikan mesin dalam kondisi dingin sebelum membuka baut pembuangan oli agar ulir tidak aus.'),
        ('22222222-0000-0000-0000-000000000002', 'Memilih Kekentalan dan Jenis Oli yang Cocok untuk Motor Anda', %L::%I, array['oli','sae','jaso'], 'Penjelasan kode SAE, standar JASO MA/MB, serta perbedaan oli mineral dan full sintetis.', 'https://www.youtube.com/watch?v=umf0szoTZ6E', 'umf0szoTZ6E', false, null),
        ('22222222-0000-0000-0000-000000000003', 'Panduan Lengkap Mengganti Kampas Rem Cakram Depan', %L::%I, array['rem','kampas','cakram'], 'Trik cepat dan aman mengganti kampas rem cakram motor tanpa melepas roda serta uji pakem rem.', 'https://www.youtube.com/watch?v=RfXUKgl4L5k', 'RfXUKgl4L5k', true, 'Jangan menekan tuas rem saat kaliper sedang terlepas dari piringan cakram.'),
        ('22222222-0000-0000-0000-000000000004', 'Cara Memeriksa dan Menambah Minyak Rem Motor', %L::%I, array['rem','minyak rem','dot4'], 'Langkah memeriksa kejernihan dan ketinggian minyak rem DOT 3 / DOT 4 pada master rem.', 'https://www.youtube.com/watch?v=Ef7pHuP0VqA', 'Ef7pHuP0VqA', true, 'Hindari tumpahan minyak rem mengenai cat bodi motor karena bersifat korosif.'),
        ('22222222-0000-0000-0000-000000000005', 'Tips Memeriksa Tekanan Angin dan Keausan Alur Ban', %L::%I, array['ban','psi','tubeless'], 'Cara mengukur tekanan psi ban depan dan belakang sesuai pabrikan serta membaca tanda TWI.', 'https://www.youtube.com/watch?v=464DBCyxAjI', '464DBCyxAjI', false, null),
        ('22222222-0000-0000-0000-000000000006', 'Cara Merawat dan Menguji Tegangan Aki Motor', %L::%I, array['aki','kelistrikan','voltmeter'], 'Panduan membersihkan kutub aki dan mengukur tegangan aki standar 12.4V - 12.8V.', 'https://www.youtube.com/watch?v=YB_deLSgHPU', 'YB_deLSgHPU', true, 'Lepas terminal negatif (-) terlebih dahulu saat membongkar aki untuk menghindari korsleting.'),
        ('22222222-0000-0000-0000-000000000007', 'Membersihkan dan Melumasi Rantai Roda Motor', %L::%I, array['rantai','gear','chain lube'], 'Teknik menyetel jarak bebas rantai 20-30 mm dan penyelarasan swing arm.', 'https://www.youtube.com/watch?v=5wsjfNE1IwM', '5wsjfNE1IwM', true, 'Matikan mesin motor saat membersihkan atau melumasi rantai agar jari tidak terjepit gear.'),
        ('22222222-0000-0000-0000-000000000008', 'Cara Melepas, Membersihkan, dan Menyetel Celah Busi', %L::%I, array['busi','pengapian','injeksi'], 'Cara membuka busi, membaca warna elektroda pembakaran mesin, dan membersihkan kerak karbon.', 'https://www.youtube.com/watch?v=eRUOo6i4uRE', 'eRUOo6i4uRE', false, null)
      on conflict (id) do update set
        title = excluded.title,
        category = excluded.category,
        keywords = excluded.keywords,
        description = excluded.description,
        youtube_url = excluded.youtube_url,
        youtube_video_id = excluded.youtube_video_id,
        has_safety_warning = excluded.has_safety_warning,
        safety_warning_text = excluded.safety_warning_text;
    $q$,
      function_cat_oli, v_enum_type,
      function_cat_oli, v_enum_type,
      function_cat_rem, v_enum_type,
      function_cat_rem, v_enum_type,
      function_cat_ban, v_enum_type,
      function_cat_aki, v_enum_type,
      function_cat_rantai, v_enum_type,
      function_cat_busi, v_enum_type
    );
  end if;
end $$;

-- ============================================================================
-- 4. VEHICLES DETAIL COLUMNS, MOTORCYCLE CATALOG, VEHICLES, HISTORIES, ETC.
-- ============================================================================
alter table public.vehicles
  add column if not exists color text,
  add column if not exists category text,
  add column if not exists engine_cc integer,
  add column if not exists transmission text,
  add column if not exists fuel_type text,
  add column if not exists photo_url text;

create table if not exists public.motorcycle_catalog (
  id uuid primary key default uuid_generate_v4(),
  brand text not null,
  model text not null,
  category text not null,
  engine_cc integer not null,
  transmission text not null,
  fuel_type text not null,
  default_color text not null,
  photo_url text not null,
  created_at timestamptz not null default now(),
  unique (brand, model)
);

insert into public.motorcycle_catalog (
  brand, model, category, engine_cc, transmission, fuel_type, default_color, photo_url
)
values
  ('Honda', 'BeAT Deluxe', 'Skutik Harian', 110, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'Hitam Doff', 'assets/images/motorcycles/vario_160.jpg'),
  ('Honda', 'BeAT Street', 'Skutik Harian', 110, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'Abu Titanium', 'assets/images/motorcycles/vario_160.jpg'),
  ('Honda', 'Genio', 'Skutik Harian', 110, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'Merah Crimson', 'assets/images/motorcycles/scoopy_prestige.jpg'),
  ('Honda', 'Scoopy Prestige', 'Skutik Retro', 110, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'Putih Mutiara', 'assets/images/motorcycles/scoopy_prestige.jpg'),
  ('Honda', 'Vario 125', 'Skutik Harian', 125, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'Biru Navy', 'assets/images/motorcycles/vario_160.jpg'),
  ('Honda', 'Vario 160', 'Skutik Sporty', 160, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Hitam Doff', 'assets/images/motorcycles/vario_160.jpg'),
  ('Honda', 'Stylo 160', 'Skutik Retro', 160, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Hijau Sage', 'assets/images/motorcycles/scoopy_prestige.jpg'),
  ('Honda', 'PCX 160', 'Skutik Maxi', 160, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Putih Mutiara', 'assets/images/motorcycles/nmax_155.jpg'),
  ('Honda', 'ADV 160', 'Skutik Maxi', 160, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Merah Crimson', 'assets/images/motorcycles/nmax_155.jpg'),
  ('Honda', 'Forza 250', 'Skutik Maxi', 250, 'Otomatis (CVT)', 'Pertamax Turbo (RON 98)', 'Abu Titanium', 'assets/images/motorcycles/nmax_155.jpg'),
  ('Honda', 'Revo X', 'Bebek / Cub', 110, 'Semi-Otomatis 4-Speed', 'Pertalite (RON 90)', 'Hitam Doff', 'assets/images/motorcycles/vario_160.jpg'),
  ('Honda', 'Supra X 125', 'Bebek / Cub', 125, 'Semi-Otomatis 4-Speed', 'Pertalite (RON 90)', 'Hitam Doff', 'assets/images/motorcycles/vario_160.jpg'),
  ('Honda', 'Supra GTR 150', 'Bebek / Cub', 150, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Merah Crimson', 'assets/images/motorcycles/vario_160.jpg'),
  ('Honda', 'Sonic 150R', 'Bebek / Cub', 150, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Putih Mutiara', 'assets/images/motorcycles/vario_160.jpg'),
  ('Honda', 'CB150R StreetFire', 'Sport Naked', 150, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Merah Crimson', 'assets/images/motorcycles/vario_160.jpg'),
  ('Honda', 'CB150X', 'Sport Naked', 150, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Hijau Sage', 'assets/images/motorcycles/vario_160.jpg'),
  ('Honda', 'CBR150R', 'Sport Fairing', 150, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Merah Crimson', 'assets/images/motorcycles/vario_160.jpg'),
  ('Honda', 'CRF 150L', 'Trail / Dual Sport', 150, 'Manual 5-Speed', 'Pertamax (RON 92)', 'Merah Crimson', 'assets/images/motorcycles/vario_160.jpg'),
  ('Yamaha', 'Mio M3', 'Skutik Harian', 125, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'Kuning Cyber', 'assets/images/motorcycles/vario_160.jpg'),
  ('Yamaha', 'Gear 125', 'Skutik Harian', 125, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'Perak Metalik', 'assets/images/motorcycles/vario_160.jpg'),
  ('Yamaha', 'FreeGo 125', 'Skutik Harian', 125, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'Biru Navy', 'assets/images/motorcycles/vario_160.jpg'),
  ('Yamaha', 'Fino 125', 'Skutik Retro', 125, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'Cokelat Prestige', 'assets/images/motorcycles/scoopy_prestige.jpg'),
  ('Yamaha', 'Fazzio Hybrid', 'Skutik Retro', 125, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Putih Mutiara', 'assets/images/motorcycles/scoopy_prestige.jpg'),
  ('Yamaha', 'Grand Filano', 'Skutik Retro', 125, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Cokelat Prestige', 'assets/images/motorcycles/scoopy_prestige.jpg'),
  ('Yamaha', 'Lexi LX 155', 'Skutik Maxi', 155, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Abu Titanium', 'assets/images/motorcycles/nmax_155.jpg'),
  ('Yamaha', 'Aerox 155', 'Skutik Sporty', 155, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Hitam Doff', 'assets/images/motorcycles/vario_160.jpg'),
  ('Yamaha', 'NMAX 155', 'Skutik Maxi', 155, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Biru Navy', 'assets/images/motorcycles/nmax_155.jpg'),
  ('Yamaha', 'NMAX Turbo', 'Skutik Maxi', 155, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Abu Titanium', 'assets/images/motorcycles/nmax_155.jpg'),
  ('Yamaha', 'XMAX 250', 'Skutik Maxi', 250, 'Otomatis (CVT)', 'Pertamax Turbo (RON 98)', 'Hitam Doff', 'assets/images/motorcycles/nmax_155.jpg'),
  ('Yamaha', 'Jupiter Z1', 'Bebek / Cub', 115, 'Semi-Otomatis 4-Speed', 'Pertalite (RON 90)', 'Biru Navy', 'assets/images/motorcycles/vario_160.jpg'),
  ('Yamaha', 'MX King 150', 'Bebek / Cub', 150, 'Manual 5-Speed', 'Pertamax (RON 92)', 'Oranye Sporty', 'assets/images/motorcycles/vario_160.jpg'),
  ('Yamaha', 'Vixion R', 'Sport Naked', 155, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Hitam Doff', 'assets/images/motorcycles/vario_160.jpg'),
  ('Yamaha', 'MT-15', 'Sport Naked', 155, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Biru Navy', 'assets/images/motorcycles/vario_160.jpg'),
  ('Yamaha', 'XSR 155', 'Sport Naked', 155, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Perak Metalik', 'assets/images/motorcycles/vario_160.jpg'),
  ('Yamaha', 'R15M', 'Sport Fairing', 155, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Perak Metalik', 'assets/images/motorcycles/vario_160.jpg'),
  ('Yamaha', 'WR 155R', 'Trail / Dual Sport', 155, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Biru Navy', 'assets/images/motorcycles/vario_160.jpg'),
  ('Suzuki', 'Nex II', 'Skutik Harian', 115, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'Perak Metalik', 'assets/images/motorcycles/vario_160.jpg'),
  ('Suzuki', 'Address FI', 'Skutik Harian', 115, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'Putih Mutiara', 'assets/images/motorcycles/vario_160.jpg'),
  ('Suzuki', 'Burgman Street 125EX', 'Skutik Maxi', 125, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Abu Titanium', 'assets/images/motorcycles/nmax_155.jpg'),
  ('Suzuki', 'Satria F150', 'Bebek / Cub', 150, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Hitam Doff', 'assets/images/motorcycles/vario_160.jpg'),
  ('Suzuki', 'GSX-R150', 'Sport Fairing', 150, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Biru Navy', 'assets/images/motorcycles/vario_160.jpg'),
  ('Kawasaki', 'KLX 150', 'Trail / Dual Sport', 150, 'Manual 5-Speed', 'Pertamax (RON 92)', 'Hijau Sage', 'assets/images/motorcycles/vario_160.jpg'),
  ('Kawasaki', 'W175 SE', 'Sport Naked', 177, 'Manual 5-Speed', 'Pertamax (RON 92)', 'Hitam Doff', 'assets/images/motorcycles/vario_160.jpg'),
  ('Kawasaki', 'Ninja 250 SL', 'Sport Fairing', 250, 'Manual 6-Speed', 'Pertamax Turbo (RON 98)', 'Hijau Sage', 'assets/images/motorcycles/vario_160.jpg'),
  ('Vespa', 'LX 125', 'Skutik Retro', 125, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Merah Crimson', 'assets/images/motorcycles/scoopy_prestige.jpg'),
  ('Vespa', 'Primavera 150', 'Skutik Retro', 155, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Hijau Sage', 'assets/images/motorcycles/scoopy_prestige.jpg')
on conflict (brand, model) do update set
  category = excluded.category,
  engine_cc = excluded.engine_cc,
  transmission = excluded.transmission,
  fuel_type = excluded.fuel_type,
  default_color = excluded.default_color,
  photo_url = excluded.photo_url;

do $$
declare
  v_owner_1 uuid := '00000000-0000-0000-0000-000000000001';
  v_owner_2 uuid := '00000000-0000-0000-0000-000000000003';
  v_owner_3 uuid := '00000000-0000-0000-0000-000000000004';
  v_rem_aktif text;
  v_req_selesai text;
begin
  -- Pastikan fallback jika pemilik lain belum ada
  if not exists (select 1 from public.profiles where id = v_owner_1) then
    select id into v_owner_1 from public.profiles where role::text in ('owner', 'user') limit 1;
  end if;

  if v_owner_1 is not null then
    -- A. 12 Sepeda Motor Populer Indonesia Lengkap Detail (Warna, Kategori, CC, Transmisi, BBM, Foto)
    insert into public.vehicles (
      id, owner_id, brand, model, production_year, license_plate, current_km,
      color, category, engine_cc, transmission, fuel_type, photo_url, is_simulation
    )
    values
      ('33333333-0000-0000-0000-000000000001', v_owner_1, 'Honda', 'Vario 160 CBS', 2023, 'BL 4521 KF', 12450, 'Hitam Doff', 'Skutik Sporty', 160, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'assets/images/motorcycles/vario_160.jpg', false),
      ('33333333-0000-0000-0000-000000000002', v_owner_1, 'Yamaha', 'NMAX 155 Connected', 2024, 'BL 3533 NAN', 17023, 'Biru Navy', 'Skutik Maxi', 155, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'assets/images/motorcycles/nmax_155.jpg', false),
      ('33333333-0000-0000-0000-000000000003', v_owner_1, 'Honda', 'BeAT Deluxe eSP', 2021, 'BL 3190 QA', 31800, 'Hitam Doff', 'Skutik Harian', 110, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'assets/images/motorcycles/vario_160.jpg', false),
      ('33333333-0000-0000-0000-000000000004', v_owner_1, 'Yamaha', 'Aerox 155 CyberCity', 2023, 'BL 5542 AB', 8200, 'Abu Titanium', 'Skutik Sporty', 155, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'assets/images/motorcycles/vario_160.jpg', false),
      ('33333333-0000-0000-0000-000000000005', v_owner_1, 'Honda', 'Scoopy Prestige', 2022, 'BL 2981 LM', 16500, 'Putih Mutiara', 'Skutik Retro', 110, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'assets/images/motorcycles/scoopy_prestige.jpg', false),
      ('33333333-0000-0000-0000-000000000006', coalesce((select id from public.profiles where id = v_owner_2), v_owner_1), 'Honda', 'PCX 160 ABS', 2024, 'BL 7102 AZ', 5400, 'Putih Mutiara', 'Skutik Maxi', 160, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'assets/images/motorcycles/nmax_155.jpg', false),
      ('33333333-0000-0000-0000-000000000007', coalesce((select id from public.profiles where id = v_owner_2), v_owner_1), 'Yamaha', 'Fazzio Neo Hybrid', 2023, 'BL 3891 BB', 9800, 'Putih Mutiara', 'Skutik Retro', 125, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'assets/images/motorcycles/scoopy_prestige.jpg', false),
      ('33333333-0000-0000-0000-000000000008', coalesce((select id from public.profiles where id = v_owner_3), v_owner_1), 'Honda', 'CB150R StreetFire', 2022, 'BL 4412 KJ', 19300, 'Merah Crimson', 'Sport Naked', 150, 'Manual 6-Speed', 'Pertamax (RON 92)', 'assets/images/motorcycles/vario_160.jpg', false),
      ('33333333-0000-0000-0000-000000000009', v_owner_1, 'Honda', 'Vario 125 CBS-ISS', 2023, 'BL 2145 CC', 11200, 'Biru Navy', 'Skutik Harian', 125, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'assets/images/motorcycles/vario_160.jpg', false),
      ('33333333-0000-0000-0000-000000000010', coalesce((select id from public.profiles where id = v_owner_2), v_owner_1), 'Honda', 'ADV 160 ABS', 2024, 'BL 6099 TR', 4800, 'Merah Crimson', 'Skutik Maxi', 160, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'assets/images/motorcycles/nmax_155.jpg', false),
      ('33333333-0000-0000-0000-000000000011', coalesce((select id from public.profiles where id = v_owner_3), v_owner_1), 'Honda', 'Supra X 125 FI', 2020, 'BL 1984 DX', 38500, 'Hitam Doff', 'Bebek / Cub', 125, 'Semi-Otomatis 4-Speed', 'Pertalite (RON 90)', 'assets/images/motorcycles/vario_160.jpg', false),
      ('33333333-0000-0000-0000-000000000012', coalesce((select id from public.profiles where id = v_owner_3), v_owner_1), 'Vespa', 'Primavera 150 i-get', 2023, 'BL 8810 VP', 6200, 'Hijau Sage', 'Skutik Retro', 155, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'assets/images/motorcycles/scoopy_prestige.jpg', false)
    on conflict (id) do update set
      brand = excluded.brand,
      model = excluded.model,
      production_year = excluded.production_year,
      license_plate = excluded.license_plate,
      current_km = excluded.current_km,
      color = excluded.color,
      category = excluded.category,
      engine_cc = excluded.engine_cc,
      transmission = excluded.transmission,
      fuel_type = excluded.fuel_type,
      photo_url = excluded.photo_url,
      is_simulation = false;

    -- B. 6 Riwayat Servis Terhubung Bengkel
    insert into public.service_histories (
      id, vehicle_id, workshop_id, service_date, km_at_service, service_type,
      replaced_parts, work_description, labor_cost, parts_cost, is_simulation
    )
    values
      ('44444444-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000001', current_date - 25, 12000, 'Servis Berkala', array['Oli MPX2', 'Oli Gardan', 'Filter Udara'], 'Servis CVT, pembersihan injektor, dan pengecekan kelistrikan lengkap.', 55000, 115000, false),
      ('44444444-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000001', current_date - 60, 10000, 'Ganti Oli', array['Oli MPX2'], 'Penggantian oli mesin rutin 2.000 km dan cek tekanan angin ban.', 20000, 65000, false),
      ('44444444-0000-0000-0000-000000000003', '33333333-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000002', current_date - 18, 23500, 'Servis Rem & CVT', array['Kampas Rem Depan', 'V-Belt'], 'Penggantian kampas rem depan & pembersihan roller rumah CVT.', 70000, 185000, false),
      ('44444444-0000-0000-0000-000000000004', '33333333-0000-0000-0000-000000000003', '11111111-0000-0000-0000-000000000005', current_date - 42, 30000, 'Tune Up Injeksi', array['Busi Iridium', 'Oli Mesin'], 'Tune up ruang bakar, bersihkan throttle body, dan ganti busi.', 60000, 105000, false),
      ('44444444-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000004', '11111111-0000-0000-0000-000000000008', current_date - 10, 8000, 'Ganti Oli', array['Yamalube Super Matic'], 'Penggantian oli Yamalube dan scan kode diagnostik ECU.', 25000, 75000, false),
      ('44444444-0000-0000-0000-000000000006', '33333333-0000-0000-0000-000000000005', '11111111-0000-0000-0000-000000000003', current_date - 15, 16000, 'Ganti Ban', array['Ban Belakang Tubeless 110/90'], 'Penggantian ban belakang tubeless dengan pentil baru.', 25000, 245000, false)
    on conflict (id) do nothing;

    -- C. 6 Pengingat Servis Aktif (Resolusi enum reminder_status)
    select coalesce(
      (select e.enumlabel from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = 'reminder_status' and upper(e.enumlabel) in ('AKTIF', 'ACTIVE') limit 1),
      (select e.enumlabel from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = 'reminder_status' limit 1)
    ) into v_rem_aktif;

    if v_rem_aktif is not null then
      execute format($q$
        insert into public.service_reminders (id, vehicle_id, service_type, target_date, target_km, status, notes)
        values
          ('55555555-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000001', 'Ganti Oli Mesin', current_date + 14, 14000, %L::reminder_status, 'Jadwal ganti oli mesin Vario 160 setiap 2.000 km'),
          ('55555555-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000001', 'Servis CVT & Roller', current_date + 45, 16000, %L::reminder_status, 'Bersihkan rumah CVT dan cek keausan V-Belt'),
          ('55555555-0000-0000-0000-000000000003', '33333333-0000-0000-0000-000000000002', 'Ganti Oli & Filter', current_date + 7, 26000, %L::reminder_status, 'Persiapan perjalanan jauh NMAX 155'),
          ('55555555-0000-0000-0000-000000000004', '33333333-0000-0000-0000-000000000003', 'Cek Rem & Kampas', current_date + 5, 33000, %L::reminder_status, 'Periksa ketebalan kampas rem depan & belakang'),
          ('55555555-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000004', 'Ganti Oli Gardan', current_date + 30, 10000, %L::reminder_status, 'Perawatan transmisi akhir matic Aerox'),
          ('55555555-0000-0000-0000-000000000006', '33333333-0000-0000-0000-000000000005', 'Cek Tegangan Aki', current_date + 21, 18000, %L::reminder_status, 'Pastikan starter elektrik optimal di pagi hari')
        on conflict (id) do update set
          service_type = excluded.service_type,
          target_date = excluded.target_date,
          target_km = excluded.target_km,
          notes = excluded.notes;
      $q$, v_rem_aktif, v_rem_aktif, v_rem_aktif, v_rem_aktif, v_rem_aktif, v_rem_aktif);
    end if;

    -- D. 3 Riwayat Panggilan Darurat Selesai, Ulasan, & Notifikasi
    select coalesce(
      (select e.enumlabel from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = 'request_status' and upper(e.enumlabel) in ('SELESAI', 'COMPLETED') limit 1),
      (select e.enumlabel from pg_enum e join pg_type t on t.oid = e.enumtypid where t.typname = 'request_status' limit 1)
    ) into v_req_selesai;

    if v_req_selesai is not null then
      execute format($q$
        insert into public.assistance_requests (
          id, user_id, vehicle_id, mechanic_id, issue_category, issue_description,
          latitude, longitude, manual_address, status, estimated_cost, final_cost,
          is_simulation, requested_at, accepted_at, completed_at
        )
        values
          ('66666666-0000-0000-0000-000000000001', %L, '33333333-0000-0000-0000-000000000001', 'b1111111-0000-0000-0000-000000000002', 'Ban Bocor', 'Ban belakang bocor terkena paku di depan Politeknik Negeri Lhokseumawe', 5.1205, 97.1585, 'Depan PNL, Buket Rata, Lhokseumawe', %L::request_status, 35000, 35000, false, now() - interval '6 days', now() - interval '6 days' + interval '3 minutes', now() - interval '6 days' + interval '35 minutes'),
          ('66666666-0000-0000-0000-000000000002', %L, '33333333-0000-0000-0000-000000000002', 'b1111111-0000-0000-0000-000000000001', 'Aki Lemah / Mati', 'Motor tidak mau distarter sama sekali setelah parkir di Waduk Pusong', 5.1742, 97.1475, 'Area Waduk Pusong, Banda Sakti, Lhokseumawe', %L::request_status, 50000, 45000, false, now() - interval '14 days', now() - interval '14 days' + interval '4 minutes', now() - interval '14 days' + interval '40 minutes'),
          ('66666666-0000-0000-0000-000000000003', %L, '33333333-0000-0000-0000-000000000003', 'b1111111-0000-0000-0000-000000000012', 'Mesin Mogok', 'Mesin mati mendadak saat hujan deras dekat Simpang Len Alue Awe', 5.1585, 97.1418, 'Simpang Len, Alue Awe, Muara Dua', %L::request_status, 75000, 65000, false, now() - interval '22 days', now() - interval '22 days' + interval '2 minutes', now() - interval '22 days' + interval '48 minutes')
        on conflict (id) do nothing;
      $q$, v_owner_1, v_req_selesai, v_owner_1, v_req_selesai, v_owner_1, v_req_selesai);

      insert into public.reviews (id, user_id, request_id, mechanic_id, workshop_id, rating, comment, is_simulation)
      values
        ('77777777-0000-0000-0000-000000000001', v_owner_1, '66666666-0000-0000-0000-000000000001', 'b1111111-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000002', 5, 'Bang Budi datang cepat kurang dari 10 menit, tambal ban tubeless rapi dan ramah!', false),
        ('77777777-0000-0000-0000-000000000002', v_owner_1, '66666666-0000-0000-0000-000000000002', 'b1111111-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000001', 5, 'Pelayanan sangat profesional, jumper aki beres dan dicek kelistrikannya gratis.', false),
        ('77777777-0000-0000-0000-000000000003', v_owner_1, '66666666-0000-0000-0000-000000000003', 'b1111111-0000-0000-0000-000000000012', '11111111-0000-0000-0000-000000000012', 5, 'Sangat membantu saat mogok malam hari dekat Simpang Len.', false)
      on conflict (id) do nothing;

      insert into public.notifications (id, user_id, reminder_id, request_id, title, message, notification_type, is_read)
      values
        ('88888888-0000-0000-0000-000000000001', v_owner_1, '55555555-0000-0000-0000-000000000001', null, 'Jadwal Ganti Oli Mendekati Waktunya', 'Honda Vario 160 CBS Anda mendekati batas 14.000 km. Segera jadwalkan ganti oli di bengkel mitra.', 'REMINDER', false),
        ('88888888-0000-0000-0000-000000000002', v_owner_1, null, '66666666-0000-0000-0000-000000000001', 'Panggilan Bantuan Selesai', 'Penanganan Ban Bocor oleh Budi Santoso telah selesai dengan total biaya Rp 35.000.', 'REQUEST_STATUS', true)
      on conflict (id) do nothing;
    end if;
  end if;
end $$;
