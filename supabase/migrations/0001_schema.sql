-- Migrasi 0001_schema.sql
-- Skema Database Produksi MotoCare (Selaras dengan Supabase Live & Aplikasi Flutter)

create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

-- 1. ENUM TYPES
do $$ begin
  create type user_role as enum ('owner', 'mechanic', 'admin');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type reminder_status as enum ('AKTIF', 'SELESAI');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type request_status as enum (
    'MENUNGGU', 'DITERIMA', 'DALAM_PERJALANAN', 'TIBA', 'SEDANG_DITANGANI', 'SELESAI', 'DITOLAK', 'DIBATALKAN', 'KEDALUWARSA'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type tutorial_category as enum (
    'Ganti Oli', 'Rem', 'Ban', 'Aki', 'Rantai', 'Busi'
  );
exception
  when duplicate_object then null;
end $$;

-- 2. TABEL PROFILES (terkait auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null unique,
  phone_number text,
  role user_role not null default 'owner'::user_role,
  avatar_url text,
  is_simulation boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 3. TABEL VEHICLES (Kendaraan Pengguna)
create table if not exists public.vehicles (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  brand text not null,
  model text not null,
  production_year integer not null check (production_year >= 1970 and production_year::numeric <= (extract(year from now()) + 1::numeric)),
  license_plate text,
  current_km integer not null default 0 check (current_km >= 0),
  is_simulation boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 4. TABEL MECHANICS (Mekanik Mitra Terdaftar)
create table if not exists public.mechanics (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid unique references public.profiles(id) on delete cascade,
  full_name text not null,
  phone_number text not null,
  specialties text[] not null default '{}'::text[],
  service_area text not null default 'Kota Lhokseumawe'::text,
  latitude double precision,
  longitude double precision,
  is_available boolean not null default true,
  is_verified boolean not null default false,
  is_simulation boolean not null default false,
  rating_avg numeric default 0.00,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 5. TABEL WORKSHOPS (Bengkel Resmi & Terverifikasi)
create table if not exists public.workshops (
  id uuid primary key default uuid_generate_v4(),
  google_place_id text unique,
  name text not null,
  address text not null,
  service_region text not null default 'Kota Lhokseumawe'::text,
  latitude double precision not null,
  longitude double precision not null,
  phone_number text,
  operating_hours text,
  services_offered text[] default '{}'::text[],
  google_rating numeric,
  is_verified_partner boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 6. TABEL ASSISTANCE_REQUESTS (Permintaan Bantuan Mekanik Darurat)
create table if not exists public.assistance_requests (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  mechanic_id uuid references public.mechanics(id) on delete set null,
  issue_category text not null,
  issue_description text not null,
  latitude double precision not null,
  longitude double precision not null,
  manual_address text,
  status request_status not null default 'MENUNGGU'::request_status,
  estimated_cost numeric,
  final_cost numeric,
  rejection_reason text,
  cancellation_reason text,
  is_simulation boolean not null default false,
  requested_at timestamptz not null default now(),
  accepted_at timestamptz,
  completed_at timestamptz,
  updated_at timestamptz not null default now()
);

-- 7. TABEL SERVICE_HISTORIES (Riwayat Servis dan Biaya)
create table if not exists public.service_histories (
  id uuid primary key default uuid_generate_v4(),
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  workshop_id uuid references public.workshops(id) on delete set null,
  custom_workshop_name text,
  service_date date not null default current_date,
  km_at_service integer not null check (km_at_service >= 0),
  service_type text not null,
  replaced_parts text[] default '{}'::text[],
  work_description text,
  labor_cost numeric not null default 0,
  parts_cost numeric not null default 0,
  total_cost numeric default (labor_cost + parts_cost),
  is_simulation boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 8. TABEL SERVICE_REMINDERS (Pengingat Servis)
create table if not exists public.service_reminders (
  id uuid primary key default uuid_generate_v4(),
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  service_type text not null,
  target_date date,
  target_km integer check (target_km >= 0),
  status reminder_status not null default 'AKTIF'::reminder_status,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (target_date is not null or target_km is not null)
);

-- 9. TABEL NOTIFICATIONS (Pusat Notifikasi In-App)
create table if not exists public.notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reminder_id uuid references public.service_reminders(id) on delete cascade,
  request_id uuid references public.assistance_requests(id) on delete cascade,
  title text not null,
  message text not null,
  notification_type text not null default 'SYSTEM'::text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- 10. TABEL TUTORIALS (Edukasi Perawatan Motor Mandiri)
create table if not exists public.tutorials (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  category tutorial_category not null,
  keywords text[] not null default '{}'::text[],
  description text not null,
  youtube_url text not null,
  youtube_video_id text not null,
  has_safety_warning boolean not null default false,
  safety_warning_text text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 11. TABEL REVIEWS (Ulasan & Penilaian Pelanggan)
create table if not exists public.reviews (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  request_id uuid unique references public.assistance_requests(id) on delete cascade,
  mechanic_id uuid references public.mechanics(id) on delete set null,
  workshop_id uuid references public.workshops(id) on delete set null,
  rating integer not null check (rating >= 1 and rating <= 5),
  comment text,
  is_simulation boolean not null default false,
  created_at timestamptz not null default now()
);

-- 12. INDEXES UNTUK PERFORMA
create index if not exists idx_vehicles_owner_id on public.vehicles(owner_id);
create index if not exists idx_service_histories_vehicle_id on public.service_histories(vehicle_id);
create index if not exists idx_service_reminders_vehicle_id on public.service_reminders(vehicle_id);
create index if not exists idx_workshops_region_partner on public.workshops(service_region, is_verified_partner);
create index if not exists idx_assistance_requests_user_status on public.assistance_requests(user_id, status);
create index if not exists idx_notifications_user_unread on public.notifications(user_id, is_read);

-- 13. TRIGGERS
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.email,
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'owner'::user_role)
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    email = excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_vehicles_updated_at on public.vehicles;
create trigger trg_vehicles_updated_at
  before update on public.vehicles
  for each row execute function public.set_updated_at();
