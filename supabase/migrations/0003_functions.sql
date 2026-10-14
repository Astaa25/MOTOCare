-- Migrasi 0003_functions.sql
-- Fungsi RPC Terotentikasi MotoCare sesuai PRD 5.4 & Addendum Keamanan 13.2

-- 1. FUNGSI PEMBATALAN PERMINTAAN OLEH PENGGUNA (cancel_request)
create or replace function public.cancel_request(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_req record;
begin
  -- Pastikan pengguna telah login
  if auth.uid() is null then
    raise exception 'Akses ditolak: sesi tidak valid.';
  end if;

  select * into v_req
  from public.service_requests
  where id = p_id;

  if not found then
    raise exception 'Permintaan bantuan tidak ditemukan.';
  end if;

  -- Pengguna hanya dapat membatalkan permintaan miliknya sendiri (SEC-08)
  if v_req.user_id != auth.uid() then
    raise exception 'Akses ditolak: Anda bukan pemilik permintaan ini.';
  end if;

  -- Pembatalan hanya sah pada status pending, accepted, atau on_the_way
  if v_req.status not in ('pending', 'accepted', 'on_the_way') then
    raise exception 'Permintaan dengan status % tidak dapat dibatalkan.', v_req.status;
  end if;

  update public.service_requests
  set status = 'cancelled'
  where id = p_id;
end;
$$;

-- 2. FUNGSI TRANSISI STATUS PERMINTAAN OLEH MEKANIK (advance_request)
create or replace function public.advance_request(p_id uuid, p_new request_status)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_req record;
  v_mechanic_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Akses ditolak: sesi tidak valid.';
  end if;

  -- Dapatkan id mekanik dari profile_id pemanggil
  select id into v_mechanic_id
  from public.mechanics
  where profile_id = auth.uid();

  if v_mechanic_id is null and not public.is_admin() then
    raise exception 'Akses ditolak: Anda bukan mekanik terdaftar.';
  end if;

  select * into v_req
  from public.service_requests
  where id = p_id
  for update; -- Lock row untuk mencegah race condition

  if not found then
    raise exception 'Permintaan bantuan tidak ditemukan.';
  end if;

  -- Transisi dari pending ke accepted / rejected
  if v_req.status = 'pending' and p_new in ('accepted', 'rejected') then
    update public.service_requests
    set status = p_new,
        mechanic_id = case when p_new = 'accepted' then v_mechanic_id else null end,
        accepted_at = case when p_new = 'accepted' then now() else null end
    where id = p_id;
    return;
  end if;

  -- Transisi lanjutan harus oleh mekanik yang ditugaskan (SEC-07)
  if v_req.mechanic_id != v_mechanic_id and not public.is_admin() then
    raise exception 'Akses ditolak: Anda bukan mekanik yang ditugaskan pada permintaan ini.';
  end if;

  -- Validasi rantai transisi sah
  if v_req.status = 'accepted' and p_new = 'on_the_way' then
    update public.service_requests set status = 'on_the_way' where id = p_id;
  elsif v_req.status = 'on_the_way' and p_new = 'in_progress' then
    update public.service_requests set status = 'in_progress' where id = p_id;
  elsif v_req.status = 'in_progress' and p_new = 'completed' then
    update public.service_requests
    set status = 'completed',
        completed_at = now()
    where id = p_id;
  else
    raise exception 'Transisi status tidak sah dari % ke %.', v_req.status, p_new;
  end if;
end;
$$;

-- 3. FUNGSI KEDALUWARSA PERMINTAAN STALE (expire_stale_requests)
create or replace function public.expire_stale_requests()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_updated_count int;
begin
  if auth.uid() is null then
    return 0;
  end if;

  -- Hanya mengubah permintaan milik pemanggil yang pending dan melewati expires_at
  update public.service_requests
  set status = 'expired'
  where user_id = auth.uid()
    and status = 'pending'
    and expires_at < now();

  get diagnostics v_updated_count = row_count;
  return v_updated_count;
end;
$$;
