-- Migrasi 0001_schema.sql
-- Skema Database MotoCare sesuai PRD Bagian 5.1 & 5.2

create extension if not exists pgcrypto;

-- 1. ENUM TYPES
do $$ begin
  create type user_role as enum ('user', 'mechanic', 'admin');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type reminder_status as enum ('active', 'completed');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type request_status as enum (
    'pending', 'accepted', 'rejected', 'on_the_way', 'in_progress', 'completed', 'cancelled', 'expired'
  );
exception
  when duplicate_object then null;
end $$;

-- 2. TABEL PROFILES (terkait auth.users)
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(full_name) between 2 and 80),
  phone text check (phone ~ '^\+?[0-9]{8,15}$'),
  role user_role not null default 'user',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 3. TABEL WORKSHOPS (Bengkel Resmi & Terverifikasi)
create table if not exists workshops (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text not null,
  city_or_regency text not null
    check (city_or_regency in ('Kota Lhokseumawe', 'Kabupaten Aceh Utara')),
  latitude double precision,
  longitude double precision,
  phone text,
  opening_hours text,
  services text[] not null default '{}',
  is_active boolean not null default true,
  source text not null,            -- asal data (wajib diisi untuk audit)
  verified_at timestamptz,         -- null = belum terverifikasi (tidak boleh tampil)
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);

-- 4. TABEL MOTORCYCLES (Kendaraan Pengguna)
create table if not exists motorcycles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  brand text not null,
  model text not null,
  production_year int not null check (production_year between 1980 and 2100),
  license_plate text,
  current_mileage int not null check (current_mileage between 0 and 999999),
  mileage_updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 5. TABEL SERVICE_HISTORIES (Riwayat Servis dan Biaya)
create table if not exists service_histories (
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

-- 6. TABEL MAINTENANCE_REMINDERS (Pengingat Servis)
create table if not exists maintenance_reminders (
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

-- 7. TABEL MECHANICS (Mekanik Terdaftar)
create table if not exists mechanics (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references profiles(id) on delete cascade,
  workshop_id uuid references workshops(id) on delete set null,
  is_available boolean not null default false,
  service_area text,
  availability_updated_at timestamptz not null default now(),
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);

-- 8. TABEL SERVICE_REQUESTS (Permintaan Bantuan Mekanik Darurat)
create table if not exists service_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  mechanic_id uuid references mechanics(id) on delete set null,
  motorcycle_id uuid references motorcycles(id) on delete set null,
  issue_description text not null check (char_length(issue_description) between 10 and 500),
  latitude double precision,
  longitude double precision,
  address_text text not null,
  contact_phone text not null,
  status request_status not null default 'pending',
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  completed_at timestamptz,
  expires_at timestamptz not null default (now() + interval '15 minutes'),
  is_demo boolean not null default false
);

-- Mencegah duplikasi: Maksimal satu permintaan aktif per pengguna
create unique index if not exists one_active_request_per_user on service_requests(user_id)
  where status in ('pending', 'accepted', 'on_the_way', 'in_progress');

-- 9. TABEL TUTORIALS (Edukasi Perawatan Motor Mandiri)
create table if not exists tutorials (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  topic text not null,
  youtube_url text not null
    check (youtube_url ~ '^https://(www\.)?(youtube\.com|youtu\.be)/'),
  thumbnail_url text,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- 10. TABEL NOTIFICATIONS (Pusat Notifikasi In-App)
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null check (type in ('reminder', 'request_status', 'system')),
  is_read boolean not null default false,
  related_id uuid,
  created_at timestamptz not null default now()
);

-- 11. INDEXES UNTUK PERFORMA
create index if not exists idx_motorcycles_user_id on motorcycles(user_id);
create index if not exists idx_service_histories_motorcycle_id on service_histories(motorcycle_id);
create index if not exists idx_service_histories_user_id on service_histories(user_id);
create index if not exists idx_reminders_motorcycle_id on maintenance_reminders(motorcycle_id);
create index if not exists idx_reminders_user_id on maintenance_reminders(user_id);
create index if not exists idx_workshops_city_active on workshops(city_or_regency, is_active);
create index if not exists idx_service_requests_user_status on service_requests(user_id, status);
create index if not exists idx_notifications_user_unread on notifications(user_id, is_read);

-- 12. TRIGGERS
-- Trigger otomatis membuat profile baru saat auth.users dibuat
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'Pengguna'),
    'user'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Trigger menolak service_date di masa depan
create or replace function public.check_future_service_date()
returns trigger
language plpgsql
as $$
begin
  if new.service_date > current_date then
    raise exception 'Tanggal servis tidak boleh di masa depan (service_date: %)', new.service_date;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_check_future_service_date on service_histories;
create trigger trg_check_future_service_date
  before insert or update on service_histories
  for each row execute function public.check_future_service_date();

-- Trigger otomatis membuat notifikasi in-app saat status bantuan mekanik berubah
create or replace function public.notify_on_request_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  status_label text;
begin
  if old.status is distinct from new.status then
    status_label := case new.status
      when 'accepted' then 'Permintaan bantuan Anda telah diterima oleh mekanik.'
      when 'on_the_way' then 'Mekanik sedang dalam perjalanan menuju lokasi Anda.'
      when 'in_progress' then 'Mekanik sedang menangani masalah motor Anda.'
      when 'completed' then 'Bantuan mekanik telah selesai.'
      when 'cancelled' then 'Permintaan bantuan telah dibatalkan.'
      when 'expired' then 'Permintaan bantuan kedaluwarsa karena tidak ada respon.'
      when 'rejected' then 'Mekanik tidak dapat menerima permintaan saat ini.'
      else 'Status bantuan diperbarui: ' || new.status
    end;

    insert into public.notifications (user_id, title, body, type, related_id)
    values (
      new.user_id,
      'Status Bantuan Mekanik',
      status_label,
      'request_status',
      new.id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notify_on_request_status_change on service_requests;
create trigger trg_notify_on_request_status_change
  after update of status on service_requests
  for each row execute function public.notify_on_request_status_change();

-- Trigger timestamp updated_at
create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on profiles;
create trigger trg_profiles_updated_at
  before update on profiles
  for each row execute function public.update_updated_at_column();

drop trigger if exists trg_motorcycles_updated_at on motorcycles;
create trigger trg_motorcycles_updated_at
  before update on motorcycles
  for each row execute function public.update_updated_at_column();
