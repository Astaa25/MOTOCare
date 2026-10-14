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

-- 2. TUTORIAL PERAWATAN MANDIRI (Minimal 8 Topik)
-- URL YouTube adalah placeholder resmi: manusia wajib mengganti dengan video sah sebelum rilis
insert into public.tutorials (id, title, topic, youtube_url, description, is_active)
values
  (
    '22222222-0000-0000-0000-000000000001',
    'Cara Mengganti Oli Mesin Motor Matic Sendiri',
    'Ganti Oli',
    'https://www.youtube.com/watch?v=GANTI_DENGAN_ID_VALID',
    'Langkah demi langkah menguras dan mengisi oli mesin matic dengan volume yang tepat.',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000002',
    'Memeriksa & Membersihkan Kampas Rem Cakram',
    'Rem',
    'https://www.youtube.com/watch?v=GANTI_DENGAN_ID_VALID',
    'Panduan memeriksa ketebalan kampas rem depan dan mengatasi rem berdecit.',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000003',
    'Panduan Menjaga Tekanan Ban dan Deteksi Keausan',
    'Ban',
    'https://www.youtube.com/watch?v=GANTI_DENGAN_ID_VALID',
    'Mengetahui standar tekanan angin psi ban depan-belakang dan batas aus TWI.',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000004',
    'Cara Merawat dan Mengukur Tegangan Aki Motor',
    'Aki',
    'https://www.youtube.com/watch?v=GANTI_DENGAN_ID_VALID',
    'Tanda-tanda aki mulai lemah dan tips menjaga keawetan sistem starter elektrik.',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000005',
    'Cara Menyetel dan Melumasi Rantai Roda',
    'Rantai',
    'https://www.youtube.com/watch?v=GANTI_DENGAN_ID_VALID',
    'Mengatur kekencangan jarak bebas rantai (20-30 mm) dan memilih pelumas rantai yang tepat.',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000006',
    'Cara Cek dan Ganti Busi Motor Bebek & Matic',
    'Busi',
    'https://www.youtube.com/watch?v=GANTI_DENGAN_ID_VALID',
    'Melihat warna elektroda busi untuk membaca kondisi pembakaran mesin motor Anda.',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000007',
    'Membersihkan dan Mengganti Filter Udara',
    'Filter Udara',
    'https://www.youtube.com/watch?v=GANTI_DENGAN_ID_VALID',
    'Menjaga tarikan mesin tetap responsif dengan filter udara yang bersih dari debu.',
    true
  ),
  (
    '22222222-0000-0000-0000-000000000008',
    'Checklist Servis Berkala Mandiri Setiap 3.000 Km',
    'Servis Berkala',
    'https://www.youtube.com/watch?v=GANTI_DENGAN_ID_VALID',
    'Daftar 10 titik penting pemeriksaan sepeda motor sebelum melakukan perjalanan jauh.',
    true
  )
on conflict (id) do nothing;
