-- ============================================================================
-- Seeder Khusus Semua Jenis Sepeda Motor Indonesia (46 Model Populer + Foto)
-- Jalankan langsung di Supabase SQL Editor (aman dijalankan ulang / idempotent).
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

-- 1. Seed Lengkap 46 Model Katalog Sepeda Motor Indonesia
insert into public.motorcycle_catalog (
  brand, model, category, engine_cc, transmission, fuel_type, default_color, photo_url
)
values
  -- HONDA (18 Model)
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

  -- YAMAHA (18 Model)
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

  -- SUZUKI (5 Model)
  ('Suzuki', 'Nex II', 'Skutik Harian', 115, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'Perak Metalik', 'assets/images/motorcycles/vario_160.jpg'),
  ('Suzuki', 'Address FI', 'Skutik Harian', 115, 'Otomatis (CVT)', 'Pertalite (RON 90)', 'Putih Mutiara', 'assets/images/motorcycles/vario_160.jpg'),
  ('Suzuki', 'Burgman Street 125EX', 'Skutik Maxi', 125, 'Otomatis (CVT)', 'Pertamax (RON 92)', 'Abu Titanium', 'assets/images/motorcycles/nmax_155.jpg'),
  ('Suzuki', 'Satria F150', 'Bebek / Cub', 150, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Hitam Doff', 'assets/images/motorcycles/vario_160.jpg'),
  ('Suzuki', 'GSX-R150', 'Sport Fairing', 150, 'Manual 6-Speed', 'Pertamax (RON 92)', 'Biru Navy', 'assets/images/motorcycles/vario_160.jpg'),

  -- KAWASAKI & VESPA (5 Model)
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

-- 2. Seed Seluruh Model Tersebut ke Garasi Pengguna Aktif (public.vehicles)
do $$
declare
  v_owner_1 uuid;
begin
  select id into v_owner_1
  from public.profiles
  where role::text in ('owner', 'user')
  order by created_at asc
  limit 1;

  if v_owner_1 is not null then
    insert into public.vehicles (
      id, owner_id, brand, model, production_year, license_plate, current_km,
      color, category, engine_cc, transmission, fuel_type, photo_url, is_simulation
    )
    select
      ('33333333-1111-0000-0000-' || lpad(row_number() over (order by brand, model)::text, 12, '0'))::uuid,
      v_owner_1,
      brand,
      model,
      2022 + ((row_number() over (order by brand, model)) % 3)::int,
      'BL ' || (3000 + row_number() over (order by brand, model) * 37)::text || ' MC',
      (5000 + row_number() over (order by brand, model) * 650)::int,
      default_color,
      category,
      engine_cc,
      transmission,
      fuel_type,
      photo_url,
      false
    from public.motorcycle_catalog
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
  end if;
end $$;

