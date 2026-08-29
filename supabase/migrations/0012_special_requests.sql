-- ─────────────────────────────────────────
-- 12. جدول الطلبات الخاصة (Special Requests)
-- ─────────────────────────────────────────
-- Clients use this to request a medicine/product that is not currently
-- available in the catalog. Branch managers and the director review it.
create table if not exists public.special_requests (
  id           uuid        primary key default gen_random_uuid(),
  client_id    uuid        not null references public.users(id) on delete cascade,
  product_name text        not null,
  quantity     integer     not null default 1 check (quantity > 0),
  notes        text,
  status       text        not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'fulfilled')),
  created_at   timestamptz not null default now()
);

alter table public.special_requests enable row level security;

-- Clients can read and create their own special requests.
create policy "special_requests_client_own" on public.special_requests
  for all using (client_id = auth.uid());
create policy "special_requests_client_insert" on public.special_requests
  for insert with check (client_id = auth.uid());

-- Branch managers and the company director can read all special requests.
create policy "special_requests_manager_read" on public.special_requests
  for select using (
    public.current_user_role() in ('branch_manager', 'company_director')
  );
