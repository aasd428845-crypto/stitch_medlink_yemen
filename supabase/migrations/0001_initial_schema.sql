create extension if not exists "pgcrypto";

create table if not exists public.branches (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  governorate text,
  address_text text,
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now()
);

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  email text unique not null,
  phone text,
  role text not null default 'client'
    check (role in ('client','branch_manager','company_director','driver')),
  branch_id uuid references public.branches(id),
  branch_name text,
  requires_password_change boolean not null default false,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.users (id, email, name, role, branch_id, branch_name, phone, requires_password_change)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'client'),
    nullif(new.raw_user_meta_data->>'branch_id','')::uuid,
    coalesce(new.raw_user_meta_data->>'branch_name', ''),
    coalesce(new.raw_user_meta_data->>'phone', ''),
    coalesce((new.raw_user_meta_data->>'requires_password_change')::boolean, false)
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.current_user_role()
returns text
language sql stable security definer set search_path = public
as $$
  select role from public.users where id = auth.uid();
$$;

create or replace function public.current_user_branch_id()
returns uuid
language sql stable security definer set search_path = public
as $$
  select branch_id from public.users where id = auth.uid();
$$;

alter table public.users enable row level security;
alter table public.branches enable row level security;

create policy "users_select_own_or_director" on public.users
  for select using (id = auth.uid() or public.current_user_role() = 'company_director');
create policy "users_update_own" on public.users
  for update using (id = auth.uid());

create policy "branches_select_all_authenticated" on public.branches
  for select using (auth.role() = 'authenticated');
create policy "branches_director_manage" on public.branches
  for all using (public.current_user_role() = 'company_director');
