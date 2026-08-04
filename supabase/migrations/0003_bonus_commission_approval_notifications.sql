alter table public.users add column if not exists terms_accepted_at timestamptz;
alter table public.users add column if not exists account_status text not null default 'pending_approval'
  check (account_status in ('pending_approval', 'active', 'rejected', 'suspended'));

create table if not exists public.bonus_rules (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references public.products(id),
  buy_quantity int not null,
  free_quantity int not null,
  is_stackable boolean not null default true,
  start_date date,
  end_date date,
  target_governorate text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.bonus_rules enable row level security;
create policy "bonus_rules_select_active" on public.bonus_rules
  for select using (is_active = true or public.current_user_role() = 'company_director');
create policy "bonus_rules_director_manage" on public.bonus_rules
  for all using (public.current_user_role() = 'company_director');

create table if not exists public.driver_commission_rules (
  id uuid primary key default gen_random_uuid(),
  scope text not null check (scope in ('global', 'branch', 'driver')),
  branch_id uuid references public.branches(id),
  driver_id uuid references public.users(id),
  commission_type text not null check (commission_type in ('fixed', 'percentage')),
  commission_value numeric(10,2) not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.driver_commissions (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.users(id),
  order_id uuid not null references public.orders(id),
  amount numeric(10,2) not null,
  status text not null default 'pending' check (status in ('pending', 'paid')),
  created_at timestamptz not null default now()
);

alter table public.driver_commission_rules enable row level security;
alter table public.driver_commissions enable row level security;

create policy "commission_rules_director_manage" on public.driver_commission_rules
  for all using (public.current_user_role() = 'company_director');
create policy "commission_rules_read" on public.driver_commission_rules
  for select using (auth.role() = 'authenticated');

create policy "commissions_own_or_director" on public.driver_commissions
  for select using (driver_id = auth.uid() or public.current_user_role() = 'company_director'
    or (public.current_user_role() = 'branch_manager'));
create policy "commissions_director_update" on public.driver_commissions
  for update using (public.current_user_role() = 'company_director');

create table if not exists public.driver_ratings (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id),
  driver_id uuid not null references public.users(id),
  client_id uuid not null references public.users(id),
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique(order_id)
);

alter table public.driver_ratings enable row level security;
create policy "ratings_client_insert" on public.driver_ratings
  for insert with check (client_id = auth.uid());
create policy "ratings_select" on public.driver_ratings
  for select using (
    client_id = auth.uid() or driver_id = auth.uid()
    or public.current_user_role() in ('company_director', 'branch_manager')
  );

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  target_role text,
  target_branch_id uuid references public.branches(id),
  related_offer_id uuid references public.promotional_offers(id),
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.notification_reads (
  notification_id uuid not null references public.notifications(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (notification_id, user_id)
);

alter table public.notifications enable row level security;
alter table public.notification_reads enable row level security;

create policy "notifications_director_manage" on public.notifications
  for all using (public.current_user_role() = 'company_director');
create policy "notifications_select_relevant" on public.notifications
  for select using (
    target_role is null
    or target_role = public.current_user_role()
  );
create policy "notification_reads_own" on public.notification_reads
  for all using (user_id = auth.uid());
