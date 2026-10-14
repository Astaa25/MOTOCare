-- Migrasi 0002_rls.sql
-- Kebijakan Akses Row Level Security (RLS) MotoCare sesuai PRD 5.3 & Addendum Keamanan 13.2

-- 1. AKTIFKAN RLS PADA SELURUH TABEL TANPA PENGECUALIAN
alter table profiles enable row level security;
alter table workshops enable row level security;
alter table motorcycles enable row level security;
alter table service_histories enable row level security;
alter table maintenance_reminders enable row level security;
alter table mechanics enable row level security;
alter table service_requests enable row level security;
alter table tutorials enable row level security;
alter table notifications enable row level security;

-- 2. HELPER FUNCTION IS_ADMIN
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- 3. POLICIES: PROFILES
-- Baca data profil milik sendiri atau jika admin
create policy profiles_select on profiles
  for select
  using (id = auth.uid() or is_admin());

-- Pengguna hanya dapat mengubah profil milik sendiri dan DILARANG eskalasi role (SEC-03)
create policy profiles_update on profiles
  for update
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and role = (select p.role from profiles p where p.id = auth.uid())
  );

-- 4. POLICIES: MOTORCYCLES & NOTIFICATIONS (Milik Langsung Pengguna)
create policy own_motorcycles on motorcycles
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy own_notifications on notifications
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- 5. POLICIES: SERVICE_HISTORIES & MAINTENANCE_REMINDERS (Relasi Kepemilikan Motor)
create policy own_service_histories on service_histories
  for all
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from motorcycles m
      where m.id = motorcycle_id and m.user_id = auth.uid()
    )
  );

create policy own_maintenance_reminders on maintenance_reminders
  for all
  using (user_id = auth.uid())
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from motorcycles m
      where m.id = motorcycle_id and m.user_id = auth.uid()
    )
  );

-- 6. POLICIES: WORKSHOPS & TUTORIALS (Katalog Publik Terverifikasi)
create policy read_workshops on workshops
  for select
  to authenticated
  using ((is_active and (verified_at is not null or is_demo)) or is_admin());

create policy admin_workshops on workshops
  for all
  using (is_admin())
  with check (is_admin());

create policy read_tutorials on tutorials
  for select
  to authenticated
  using (is_active or is_admin());

create policy admin_tutorials on tutorials
  for all
  using (is_admin())
  with check (is_admin());

-- 7. POLICIES: MECHANICS
create policy read_mechanics on mechanics
  for select
  to authenticated
  using (is_available or profile_id = auth.uid() or is_admin());

create policy update_own_mechanic on mechanics
  for update
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- 8. POLICIES: SERVICE_REQUESTS
-- Pengguna pembuat, mekanik bertugas, dan admin yang dapat membaca permintaan
create policy read_requests on service_requests
  for select
  using (
    user_id = auth.uid()
    or is_admin()
    or mechanic_id in (select id from mechanics where profile_id = auth.uid())
  );

-- Klien hanya diizinkan melakukan insert dengan status 'pending' dan tanpa mechanic_id
create policy insert_request on service_requests
  for insert
  with check (
    user_id = auth.uid()
    and status = 'pending'
    and mechanic_id is null
  );

-- TIDAK ADA policy UPDATE/DELETE langsung pada service_requests:
-- Seluruh perubahan status ditegakkan secara ketat melalui RPC (bagian 5.4 & 13.2)
