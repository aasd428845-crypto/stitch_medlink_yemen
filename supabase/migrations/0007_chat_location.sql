-- مرحلة 9: دردشة حيّة للسائق ومدير الفرع، وموقع السائق المباشر.
create table public.chat_rooms (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  driver_id uuid not null references public.users(id),
  branch_id uuid not null references public.branches(id),
  created_at timestamptz not null default now(),
  unique(order_id)
);
create table public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms(id) on delete cascade,
  sender_id uuid not null references public.users(id),
  content text not null check (length(trim(content)) > 0),
  created_at timestamptz not null default now()
);
create table public.driver_locations (
  driver_id uuid primary key references public.users(id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  updated_at timestamptz not null default now()
);
alter table public.chat_rooms enable row level security;
alter table public.chat_messages enable row level security;
alter table public.driver_locations enable row level security;
create policy "chat_rooms_member_select" on public.chat_rooms for select using (
  driver_id = auth.uid() or (public.current_user_role() = 'branch_manager' and branch_id = public.current_user_branch_id()));
create policy "chat_rooms_member_insert" on public.chat_rooms for insert with check (
  driver_id = auth.uid() or (public.current_user_role() = 'branch_manager' and branch_id = public.current_user_branch_id()));
create policy "chat_messages_member_select" on public.chat_messages for select using (
  exists (select 1 from public.chat_rooms r where r.id = room_id and
    (r.driver_id = auth.uid() or (public.current_user_role() = 'branch_manager' and r.branch_id = public.current_user_branch_id()))));
create policy "chat_messages_member_insert" on public.chat_messages for insert with check (
  sender_id = auth.uid() and exists (select 1 from public.chat_rooms r where r.id = room_id and
    (r.driver_id = auth.uid() or (public.current_user_role() = 'branch_manager' and r.branch_id = public.current_user_branch_id()))));
create policy "driver_locations_own_upsert" on public.driver_locations for all
  using (driver_id = auth.uid()) with check (driver_id = auth.uid());
create policy "driver_locations_parties_select" on public.driver_locations for select using (
  public.current_user_role() in ('client', 'branch_manager') or driver_id = auth.uid());
alter publication supabase_realtime add table public.chat_messages, public.driver_locations;