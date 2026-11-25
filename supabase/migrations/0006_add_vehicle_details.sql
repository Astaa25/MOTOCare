-- Migrasi 0006_add_vehicle_details.sql
-- Menambahkan detail atribut kendaraan (warna, kategori, cc mesin, transmisi, BBM, foto)
-- serta tabel referensi katalog sepeda motor Indonesia.

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

