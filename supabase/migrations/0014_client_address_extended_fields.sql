-- ─────────────────────────────────────────────────────────────────────────────
-- Client delivery address details
-- The client address form collects these optional details in addition to the
-- original label/address_text/location fields from migration 0002.
-- ─────────────────────────────────────────────────────────────────────────────

alter table public.client_addresses
  add column if not exists owner_name text,
  add column if not exists phone text,
  add column if not exists alt_phone text,
  add column if not exists landmark text,
  add column if not exists governorate text,
  add column if not exists city text,
  add column if not exists district text;

comment on column public.client_addresses.owner_name is
  'Name of the person responsible for receiving the delivery.';
comment on column public.client_addresses.phone is
  'Primary delivery contact phone number.';
comment on column public.client_addresses.alt_phone is
  'Optional alternate delivery contact phone number.';
comment on column public.client_addresses.landmark is
  'Nearby landmark that helps the driver find the address.';
comment on column public.client_addresses.governorate is
  'Governorate where the delivery address is located.';
comment on column public.client_addresses.city is
  'City or district-level city name for the delivery address.';
comment on column public.client_addresses.district is
  'Neighborhood or local district for the delivery address.';

create index if not exists client_addresses_client_created_idx
  on public.client_addresses (client_id, created_at desc);