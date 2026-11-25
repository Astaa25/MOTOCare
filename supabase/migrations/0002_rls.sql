-- Migrasi 0002_rls.sql
-- Kebijakan Akses Row Level Security (RLS) MotoCare untuk Skema Produksi Supabase

alter table public.profiles enable row level security;
alter table public.vehicles enable row level security;
alter table public.mechanics enable row level security;
alter table public.workshops enable row level security;
alter table public.assistance_requests enable row level security;
alter table public.service_histories enable row level security;
alter table public.service_reminders enable row level security;
alter table public.notifications enable row level security;
alter table public.tutorials enable row level security;
alter table public.reviews enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'::user_role
  );
$$;

-- PROFILES
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select
  using (id = auth.uid() or is_admin());

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
  for update
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and role = (select p.role from public.profiles p where p.id = auth.uid())
  );

-- VEHICLES & NOTIFICATIONS
drop policy if exists own_vehicles on public.vehicles;
create policy own_vehicles on public.vehicles
  for all
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

drop policy if exists own_notifications on public.notifications;
create policy own_notifications on public.notifications
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- SERVICE_HISTORIES & SERVICE_REMINDERS
drop policy if exists own_service_histories on public.service_histories;
create policy own_service_histories on public.service_histories
  for all
  using (
    exists (
      select 1 from public.vehicles v
      where v.id = vehicle_id and v.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.vehicles v
      where v.id = vehicle_id and v.owner_id = auth.uid()
    )
  );

drop policy if exists own_service_reminders on public.service_reminders;
create policy own_service_reminders on public.service_reminders
  for all
  using (
    exists (
      select 1 from public.vehicles v
      where v.id = vehicle_id and v.owner_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.vehicles v
      where v.id = vehicle_id and v.owner_id = auth.uid()
    )
  );

-- WORKSHOPS & TUTORIALS (Katalog Publik)
drop policy if exists read_workshops on public.workshops;
create policy read_workshops on public.workshops
  for select
  to authenticated
  using (is_verified_partner or is_admin());

drop policy if exists admin_workshops on public.workshops;
create policy admin_workshops on public.workshops
  for all
  using (is_admin())
  with check (is_admin());

drop policy if exists read_tutorials on public.tutorials;
create policy read_tutorials on public.tutorials
  for select
  to authenticated
  using (true);

drop policy if exists admin_tutorials on public.tutorials;
create policy admin_tutorials on public.tutorials
  for all
  using (is_admin())
  with check (is_admin());

-- MECHANICS
drop policy if exists read_mechanics on public.mechanics;
create policy read_mechanics on public.mechanics
  for select
  to authenticated
  using (is_available or user_id = auth.uid() or is_admin());

drop policy if exists update_own_mechanic on public.mechanics;
create policy update_own_mechanic on public.mechanics
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ASSISTANCE_REQUESTS
drop policy if exists read_requests on public.assistance_requests;
create policy read_requests on public.assistance_requests
  for select
  using (
    user_id = auth.uid()
    or is_admin()
    or mechanic_id in (select id from public.mechanics where user_id = auth.uid())
    or (status = 'MENUNGGU'::request_status and exists (select 1 from public.mechanics where user_id = auth.uid()))
  );

drop policy if exists insert_own_request on public.assistance_requests;
create policy insert_own_request on public.assistance_requests
  for insert
  with check (
    user_id = auth.uid()
    and status = 'MENUNGGU'::request_status
    and mechanic_id is null
  );

-- REVIEWS
drop policy if exists read_reviews on public.reviews;
create policy read_reviews on public.reviews
  for select
  to authenticated
  using (true);

drop policy if exists insert_own_review on public.reviews;
create policy insert_own_review on public.reviews
  for insert
  with check (user_id = auth.uid());
