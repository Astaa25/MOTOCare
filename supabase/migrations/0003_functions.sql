-- Migrasi 0003_functions.sql
-- Fungsi RPC Terotentikasi MotoCare untuk Skema Produksi assistance_requests & mechanics

create or replace function public.cancel_request(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_req record;
begin
  if auth.uid() is null then
    raise exception 'Akses ditolak: sesi tidak valid.';
  end if;

  select * into v_req
  from public.assistance_requests
  where id = p_id;

  if not found then
    raise exception 'Permintaan bantuan tidak ditemukan.';
  end if;

  if v_req.user_id != auth.uid() then
    raise exception 'Akses ditolak: Anda bukan pemilik permintaan ini.';
  end if;

  if v_req.status::text not in ('MENUNGGU', 'DITERIMA', 'DALAM_PERJALANAN') then
    raise exception 'Permintaan dengan status % tidak dapat dibatalkan.', v_req.status;
  end if;

  update public.assistance_requests
  set status = 'DIBATALKAN'::request_status,
      updated_at = now()
  where id = p_id;
end;
$$;

create or replace function public.advance_request(p_id uuid, p_new text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_req record;
  v_mechanic_id uuid;
  v_target_status request_status;
begin
  if auth.uid() is null then
    raise exception 'Akses ditolak: sesi tidak valid.';
  end if;

  select id into v_mechanic_id
  from public.mechanics
  where user_id = auth.uid();

  if v_mechanic_id is null and not public.is_admin() then
    raise exception 'Akses ditolak: Anda bukan mekanik terdaftar.';
  end if;

  v_target_status := (
    case upper(trim(p_new))
      when 'ACCEPTED' then 'DITERIMA'
      when 'REJECTED' then 'DITOLAK'
      when 'ON_THE_WAY' then 'DITERIMA'
      when 'IN_PROGRESS' then 'SEDANG_DITANGANI'
      when 'COMPLETED' then 'SELESAI'
      else upper(trim(p_new))
    end
  )::request_status;

  select * into v_req
  from public.assistance_requests
  where id = p_id
  for update;

  if not found then
    raise exception 'Permintaan bantuan tidak ditemukan.';
  end if;

  if v_req.status::text = 'MENUNGGU' and v_target_status::text in ('DITERIMA', 'DITOLAK') then
    update public.assistance_requests
    set status = v_target_status,
        mechanic_id = case when v_target_status::text = 'DITERIMA' then v_mechanic_id else null end,
        accepted_at = case when v_target_status::text = 'DITERIMA' then now() else null end,
        updated_at = now()
    where id = p_id;
    return;
  end if;

  if v_req.mechanic_id != v_mechanic_id and not public.is_admin() then
    raise exception 'Akses ditolak: Anda bukan mekanik yang ditugaskan.';
  end if;

  update public.assistance_requests
  set status = v_target_status,
      completed_at = case when v_target_status::text = 'SELESAI' then now() else completed_at end,
      updated_at = now()
  where id = p_id;
end;
$$;

-- Pembaruan koordinat GPS montir secara real-time saat sedang bertugas
create or replace function public.update_mechanic_location(p_lat double precision, p_lng double precision)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return;
  end if;

  update public.mechanics
  set latitude = p_lat,
      longitude = p_lng,
      updated_at = now()
  where user_id = auth.uid();
end;
$$;
