-- Seed Data Simulasi Demo MotoCare sesuai PRD Bagian 5.5
-- Semua data berlabel [Demo] dan is_demo = true. Tidak ada data bisnis riil yang ditiru.

-- 1. BENGKEL SIMULASI (Minimal 3 per wilayah)
-- Wilayah 1: Kota Lhokseumawe
insert into public.workshops (id, name, address, city_or_regency, latitude, longitude, phone, opening_hours, services, is_active, source, verified_at, is_demo)
values
  (
    '11111111-0000-0000-0000-000000000001',
    '[Demo] Bengkel Cepat Lhokseumawe',
    'Jl. Samudera No. 10, Banda Sakti',
    'Kota Lhokseumawe',
    5.1801, 97.1402,
    '081200000001',
    '08:00 - 17:00 WIB',
    array['Ganti Oli', 'Tune Up', 'Servis Rem'],
    true,
    'Data Simulasi Demo MVP',
    now(),
    true
  ),
  (
    '11111111-0000-0000-0000-000000000002',
    '[Demo] Servis Motor Samudera',
    'Jl. Merdeka Barat No. 24, Muara Dua',
    'Kota Lhokseumawe',
    5.1750, 97.1350,
    '081200000002',
    '08:30 - 18:00 WIB',
    array['Ganti Oli', 'Servis Injeksi', 'Tambal Ban'],
    true,
    'Data Simulasi Demo MVP',
    now(),
    true
  ),
  (
    '11111111-0000-0000-0000-000000000003',
    '[Demo] Sentra Ban & Aki Pase',
    'Jl. Pase Indah No. 5, Blang Mangat',
    'Kota Lhokseumawe',
    5.1620, 97.1510,
    '081200000003',
    '09:00 - 20:00 WIB',
    array['Ganti Ban', 'Cek Aki', 'Ganti Rantai'],
    true,
    'Data Simulasi Demo MVP',
    now(),
    true
  ),

-- Wilayah 2: Kabupaten Aceh Utara
  (
    '11111111-0000-0000-0000-000000000004',
    '[Demo] Bengkel Mandiri Malikussaleh',
    'Jl. Medan-Banda Aceh Km. 275, Reuleuet',
    'Kabupaten Aceh Utara',
    5.2300, 97.0600,
    '081200000004',
    '08:00 - 17:30 WIB',
    array['Ganti Oli', 'Servis Ringan', 'Ganti Busi'],
    true,
    'Data Simulasi Demo MVP',
    now(),
    true
  ),
  (
    '11111111-0000-0000-0000-000000000005',
    '[Demo] Putra Motor Lhoksukon',
    'Jl. Cut Nyak Dien No. 8, Lhoksukon',
    'Kabupaten Aceh Utara',
    5.0450, 97.3200,
    '081200000005',
    '08:00 - 17:00 WIB',
    array['Servis Besar', 'Ganti Oli', 'Setel Rantai'],
    true,
    'Data Simulasi Demo MVP',
    now(),
    true
  ),
  (
    '11111111-0000-0000-0000-000000000006',
    '[Demo] Bengkel Krueng Geukueh Jaya',
    'Jl. Pelabuhan Krueng Geukueh No. 15, Dewantara',
    'Kabupaten Aceh Utara',
    5.2450, 97.0250,
    '081200000006',
    '08:30 - 18:00 WIB',
    array['Ganti Oli', 'Tambal Ban Tubeless', 'Cek Kelistrikan'],
    true,
    'Data Simulasi Demo MVP',
    now(),
    true
  )
on conflict (id) do nothing;

-- 2. TUTORIAL PERAWATAN MANDIRI (8 Topik Riil YouTube GridOto Tips)
insert into public.tutorials (id, title, topic, youtube_url, thumbnail_url, description, is_active)
values
  (
    '22222222-0000-0000-0000-000000000001',
    'Cara Mengganti Oli Mesin Motor Sendiri di Rumah',
    'Ganti Oli',
    'https://www.youtube.com/watch?v=2Ax9qDmNJ-c',
    'https://img.youtube.com/vi/2Ax9qDmNJ-c/hqdefault.jpg',
    'Panduan langkah demi langkah menguras dan mengisi oli mesin motor dengan aman, memilih kunci pas yang tepat, dan memeriksa takaran volume oli.',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000002',
    'Memilih Kekentalan dan Jenis Oli yang Cocok untuk Motor Anda',
    'Ganti Oli',
    'https://www.youtube.com/watch?v=umf0szoTZ6E',
    'https://img.youtube.com/vi/umf0szoTZ6E/hqdefault.jpg',
    '10 hal penting seputar oli mesin motor: penjelasan kode SAE, standar JASO MA/MB, serta perbedaan oli mineral, semi sintetis, dan full sintetis.',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000003',
    'Panduan Lengkap Mengganti Kampas Rem Cakram Depan',
    'Rem',
    'https://www.youtube.com/watch?v=RfXUKgl4L5k',
    'https://img.youtube.com/vi/RfXUKgl4L5k/hqdefault.jpg',
    'Trik cepat dan aman mengganti kampas rem cakram motor tanpa perlu melepas roda atau ban, mendeteksi ketebalan kampas, dan menguji pakemnya rem.',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000004',
    'Cara Memeriksa dan Menambah Minyak Rem Motor',
    'Rem',
    'https://www.youtube.com/watch?v=Ef7pHuP0VqA',
    'https://img.youtube.com/vi/Ef7pHuP0VqA/hqdefault.jpg',
    'Langkah memeriksa kejernihan dan ketinggian minyak rem pada master rem kaca intip, memilih cairan DOT 3 atau DOT 4, dan mencegah gelembung udara masuk.',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000005',
    'Tips Memeriksa Tekanan Angin dan Keausan Alur Ban',
    'Ban',
    'https://www.youtube.com/watch?v=464DBCyxAjI',
    'https://img.youtube.com/vi/464DBCyxAjI/hqdefault.jpg',
    'Cara simpel menjaga ban motor lebih awet, mengukur tekanan psi ban depan dan belakang sesuai standar pabrikan, serta membaca tanda TWI (Tread Wear Indicator).',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000006',
    'Cara Merawat dan Menguji Tegangan Aki Motor',
    'Aki',
    'https://www.youtube.com/watch?v=YB_deLSgHPU',
    'https://img.youtube.com/vi/YB_deLSgHPU/hqdefault.jpg',
    'Panduan merawat kutub aki dari jamur putih, mengukur tegangan aki dengan multimeter/voltmeter (12.4V - 12.8V), dan tanda-tanda aki perlu dicharge atau diganti.',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000007',
    'Membersihkan dan Melumasi Rantai Roda Motor',
    'Rantai',
    'https://www.youtube.com/watch?v=5wsjfNE1IwM',
    'https://img.youtube.com/vi/5wsjfNE1IwM/hqdefault.jpg',
    'Teknik menyetel kelonggaran rantai roda motor (jarak bebas 20-30 mm), menyelaraskan posisi ban belakang di swing arm, dan tips pelumasan rantai.',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000008',
    'Cara Melepas, Membersihkan, dan Menyetel Celah Busi',
    'Busi',
    'https://www.youtube.com/watch?v=eRUOo6i4uRE',
    'https://img.youtube.com/vi/eRUOo6i4uRE/hqdefault.jpg',
    'Cara membuka busi dengan kunci busi standar, membaca warna elektroda (indikasi pembakaran mesin), membersihkan kerak karbon, dan menyetel celah elektroda busi.',
    true
  )
on conflict (id) do update set
  title = excluded.title,
  topic = excluded.topic,
  youtube_url = excluded.youtube_url,
  thumbnail_url = excluded.thumbnail_url,
  description = excluded.description,
  is_active = excluded.is_active;

-- 3. DATA SEPEDA MOTOR RIIL (Model Populer Indonesia)
-- Memasukkan 5 data sepeda motor riil populer untuk profil pengguna aktif
do $$
declare
  v_user_id uuid;
begin
  select id into v_user_id from public.profiles where role = 'user' limit 1;
  
  if v_user_id is not null then
    insert into public.motorcycles (id, user_id, brand, model, production_year, license_plate, current_mileage, mileage_updated_at)
    values
      ('33333333-0000-0000-0000-000000000001', v_user_id, 'Honda', 'Vario 160 CBS', 2023, 'BL 4521 KF', 12450, now() - interval '5 days'),
      ('33333333-0000-0000-0000-000000000002', v_user_id, 'Yamaha', 'NMAX 155 Connected', 2022, 'BL 6812 KP', 24100, now() - interval '3 days'),
      ('33333333-0000-0000-0000-000000000003', v_user_id, 'Honda', 'BeAT Deluxe eSP', 2021, 'BL 3190 QA', 31800, now() - interval '35 days'),
      ('33333333-0000-0000-0000-000000000004', v_user_id, 'Yamaha', 'Aerox 155 CyberCity', 2023, 'BL 5542 AB', 8200, now() - interval '8 days'),
      ('33333333-0000-0000-0000-000000000005', v_user_id, 'Honda', 'Scoopy Prestige', 2022, 'BL 2981 LM', 16500, now() - interval '12 days')
    on conflict (id) do update set
      brand = excluded.brand,
      model = excluded.model,
      production_year = excluded.production_year,
      license_plate = excluded.license_plate,
      current_mileage = excluded.current_mileage,
      mileage_updated_at = excluded.mileage_updated_at;

    -- Riwayat servis awal untuk motor riil
    insert into public.service_histories (id, motorcycle_id, user_id, service_date, mileage, service_type, description, cost)
    values
      ('44444444-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000001', v_user_id, current_date - 25, 12000, 'Servis berkala', 'Servis CVT, pembersihan injektor, dan pengecekan kelistrikan', 150000),
      ('44444444-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000001', v_user_id, current_date - 60, 10000, 'Ganti oli', 'Ganti oli mesin MPX2 dan pembersihan filter udara', 85000)
    on conflict (id) do nothing;
  end if;
end $$;
