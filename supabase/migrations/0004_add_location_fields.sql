-- Migration 0004: Penambahan kolom wilayah & patokan lokasi pada tabel assistance_requests
alter table public.assistance_requests
  add column if not exists city_regency text default 'Kota Lhokseumawe',
  add column if not exists landmark text;

comment on column public.assistance_requests.city_regency is 'Wilayah administratif tingkat 2 (Kota Lhokseumawe atau Kabupaten Aceh Utara)';
comment on column public.assistance_requests.landmark is 'Patokan lokasi fisik penjemputan (opsional)';
