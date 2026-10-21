-- PHASE 51 isolated-test bootstrap prerequisites (scratch container ONLY).
-- Minimal equivalents of the objects the local supabase stack services
-- (realtime, storage-api) would normally create, so the migration chain
-- 0001->0022 can replay against a bare supabase/postgres image.
-- NEVER run against a production project. Guarded by the runner script.

-- realtime: 0007_chat_location.sql does `alter publication supabase_realtime add table ...`
do $$ begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end $$;

-- storage: 0015_product_images_storage.sql inserts into storage.buckets
-- and creates policies on storage.objects. Minimal faithful columns only.
create schema if not exists storage;

create table if not exists storage.buckets (
  id text not null primary key,
  name text not null unique,
  owner uuid,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  public boolean default false
);

create table if not exists storage.objects (
  id uuid not null primary key default gen_random_uuid(),
  bucket_id text references storage.buckets(id),
  name text,
  owner uuid,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  last_accessed_at timestamptz default now(),
  metadata jsonb
);

alter table storage.buckets enable row level security;
alter table storage.objects enable row level security;

grant usage on schema storage to anon, authenticated, service_role;
grant all on storage.buckets, storage.objects to authenticated, service_role;

-- NOTE (PHASE 64): the supabase/postgres image provisions the full Supabase
-- `auth` schema natively at init — auth.users, auth.uid() (reads the singular
-- request.jwt.claim.sub GUC, matching ph61 TEST #8b), auth.role(), and the
-- anon/authenticated/service_role roles. GoTrue is NOT required for schema
-- bootstrap. We therefore stub nothing auth-related and never override auth.uid().

-- The bare image leaves a stub `graphql.increment_schema_version()` function
-- plus a ddl_command_end event trigger that calls it on every DDL statement,
-- but it never registers the pg_graphql extension — so
-- `graphql.seq_schema_version` is missing and any ALTER TABLE/CREATE TABLE
-- errors out. Completing the extension registration creates the sequence and
-- makes the DDL event trigger a no-op-safe normal call. Isolated scratch only.
create extension if not exists pg_graphql;
