-- Migration 0005: Tambah kolom idempotency_key pada tabel assistance_requests
alter table public.assistance_requests
  add column if not exists idempotency_key text unique;

create index if not exists idx_assistance_requests_idempotency
  on public.assistance_requests(idempotency_key);
