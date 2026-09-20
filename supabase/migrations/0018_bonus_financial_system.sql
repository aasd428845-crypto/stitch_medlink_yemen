-- =============================================================
-- Migration 0018 — Bonus Financial System (ledger, accounts, rules v2,
-- redemptions, withdrawals, settings, audit)
-- MedLink Yemen — shared Supabase database
--
-- SCOPE (per Final Design Review, READY FOR SQL):
--   Parallel financial layer. Does NOT touch Buy X → Free Y
--   (0016/0017 stay intact), does NOT modify create_order_with_items,
--   does NOT convert free units into money, creates NO test data.
--   Order-discount RPC is DEFERRED to 0019+.
--
-- Conventions: additive only (CREATE IF NOT EXISTS where possible),
-- SECURITY DEFINER with fixed search_path, RLS on every table,
-- direct client writes to the ledger are impossible by policy.
-- Run manually (Dashboard → SQL Editor) after review. No auto-apply.
-- =============================================================

-- ─────────────────────────────────────────
-- 1. bonus_accounts — one row per customer, no mutable balance.
--    Balance is ALWAYS derived: SUM(bonus_ledger.amount).
-- ─────────────────────────────────────────
create table if not exists public.bonus_accounts (
  user_id uuid primary key references public.users(id) on delete restrict,
  mode text not null default 'NONE'
    check (mode in ('NONE', 'OPENING_BALANCE', 'LEGACY_MIGRATION')),
  status text not null default 'active'
    check (status in ('active', 'suspended')),
  currency text not null default 'YER',
  opened_at timestamptz,
  opened_by uuid references public.users(id) on delete set null,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.bonus_accounts enable row level security;

drop policy if exists "bonus_accounts_client_select" on public.bonus_accounts;
create policy "bonus_accounts_client_select" on public.bonus_accounts
  for select using (user_id = auth.uid());

drop policy if exists "bonus_accounts_director_select" on public.bonus_accounts;
create policy "bonus_accounts_director_select" on public.bonus_accounts
  for select using (public.current_user_role() = 'company_director');

-- No INSERT/UPDATE/DELETE policies for clients or directors:
-- all writes go through the RPCs below (SECURITY DEFINER, audited).

-- ─────────────────────────────────────────
-- 2. bonus_ledger — append-only financial truth.
--    Positive amount = credit, negative amount = debit.
-- ─────────────────────────────────────────
create table if not exists public.bonus_ledger (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.bonus_accounts(user_id)
    on delete restrict,
  txn_type text not null check (txn_type in (
    'EARN', 'REDEEM_PRODUCT', 'ORDER_DISCOUNT', 'CASH_WITHDRAWAL',
    'REFUND', 'REVERSAL', 'ADJUSTMENT', 'EXPIRATION',
    'OPENING_BALANCE', 'LEGACY_MIGRATION'
  )),
  amount numeric(12,2) not null check (amount <> 0),
  status text not null default 'POSTED'
    check (status in ('POSTED', 'PENDING')),
  order_id uuid references public.orders(id) on delete set null,
  withdrawal_id uuid,
  redemption_id uuid,
  reverses_id uuid references public.bonus_ledger(id) on delete set null,
  rule_id uuid,
  actor uuid references public.users(id) on delete set null,
  reference text,
  notes text,
  idempotency_key text unique,
  created_at timestamptz not null default now()
);

create index if not exists bonus_ledger_account_time_idx
  on public.bonus_ledger (account_id, created_at desc);
create index if not exists bonus_ledger_account_status_idx
  on public.bonus_ledger (account_id, status);

alter table public.bonus_ledger enable row level security;

drop policy if exists "bonus_ledger_client_select" on public.bonus_ledger;
create policy "bonus_ledger_client_select" on public.bonus_ledger
  for select using (account_id = auth.uid());

drop policy if exists "bonus_ledger_director_select" on public.bonus_ledger;
create policy "bonus_ledger_director_select" on public.bonus_ledger
  for select using (public.current_user_role() = 'company_director');

-- No direct INSERT/UPDATE/DELETE for anyone: RPC-only writes.

-- Immutability: POSTED rows (financial history) can never be changed
-- or removed. PENDING reservation rows remain manageable through the
-- RPC lifecycle (fulfill/pay consume them, cancel/reject releases them).
-- Corrections use compensating REVERSAL rows, never mutation.
create or replace function public.prevent_bonus_ledger_mutation()
returns trigger
language plpgsql
as $$
begin
  if old.status = 'POSTED' then
    raise exception 'bonus_ledger POSTED rows are immutable (use REVERSAL/ADJUSTMENT)';
  end if;
  return old;
end $$;

drop trigger if exists trg_bonus_ledger_immutable on public.bonus_ledger;
create trigger trg_bonus_ledger_immutable
  before update or delete on public.bonus_ledger
  for each row execute function public.prevent_bonus_ledger_mutation();

-- ─────────────────────────────────────────
-- 3. bonus_rules_v2 — explicit typed rules beside the legacy table.
--    The legacy bonus_rules table is NOT modified.
-- ─────────────────────────────────────────
create table if not exists public.bonus_rules_v2 (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  rule_type text not null default 'PRODUCT'
    check (rule_type in ('PRODUCT', 'MONETARY', 'GENERAL')),
  status text not null default 'active'
    check (status in ('active', 'suspended', 'archived')),
  start_date date,
  end_date date,
  min_order_value numeric(12,2),
  min_quantity int check (min_quantity is null or min_quantity > 0),
  bonus_value numeric(12,2),
  bonus_percent numeric(5,2)
    check (bonus_percent is null or (bonus_percent >= 0 and bonus_percent <= 100)),
  max_earn numeric(12,2),
  eligible_customers uuid[],
  customer_type text,
  governorate text,
  products_include uuid[],
  products_exclude uuid[],
  is_stackable boolean not null default false,
  priority int not null default 0,
  usage_limit int check (usage_limit is null or usage_limit > 0),
  allow_product boolean not null default true,
  allow_discount boolean not null default false,
  allow_cash boolean not null default false,
  cash_min numeric(12,2),
  cash_max numeric(12,2),
  cash_monthly_limit numeric(12,2),
  approval_required boolean not null default true,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.bonus_rules_v2 enable row level security;

drop policy if exists "bonus_rules_v2_client_select_active" on public.bonus_rules_v2;
create policy "bonus_rules_v2_client_select_active" on public.bonus_rules_v2
  for select using (status = 'active');

drop policy if exists "bonus_rules_v2_director_manage" on public.bonus_rules_v2;
create policy "bonus_rules_v2_director_manage" on public.bonus_rules_v2
  for all using (public.current_user_role() = 'company_director')
  with check (public.current_user_role() = 'company_director');

-- NOTE: the pre-existing manual policy "director_manage_bonus_rules" lives
-- on the legacy bonus_rules table and is intentionally left untouched.

-- One compensation per original: second REVERSAL/EXPIRATION for the same
-- source row is rejected at the constraint level (concurrency-safe),
-- independent of application retries.
create unique index if not exists bonus_ledger_reverses_uniq
  on public.bonus_ledger (reverses_id)
  where reverses_id is not null and txn_type in ('REVERSAL', 'EXPIRATION');

-- (Request-link FKs are added after §5, once both tables exist.)

alter table public.bonus_ledger
  add constraint bonus_ledger_rule_fk
  foreign key (rule_id) references public.bonus_rules_v2(id)
  on delete set null
  not valid;

alter table public.bonus_ledger validate constraint bonus_ledger_rule_fk;

-- ─────────────────────────────────────────
-- 4. bonus_redemptions — one product per request (multi-product via
--    multiple requests; a lines table is deferred, not assumed).
-- ─────────────────────────────────────────
create table if not exists public.bonus_redemptions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.bonus_accounts(user_id)
    on delete restrict,
  product_id uuid not null references public.products(id)
    on delete restrict,
  quantity int not null check (quantity > 0),
  bonus_value numeric(12,2) not null check (bonus_value >= 0),
  status text not null default 'PENDING'
    check (status in ('PENDING','APPROVED','REJECTED','FULFILLED','CANCELLED')),
  ledger_id uuid references public.bonus_ledger(id) on delete set null,
  requested_by uuid references public.users(id) on delete set null,
  decided_by uuid references public.users(id) on delete set null,
  decided_at timestamptz,
  decision_reason text,
  idempotency_key text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists bonus_redemptions_account_status_idx
  on public.bonus_redemptions (account_id, status);

alter table public.bonus_redemptions enable row level security;

drop policy if exists "bonus_redemptions_client_select" on public.bonus_redemptions;
create policy "bonus_redemptions_client_select" on public.bonus_redemptions
  for select using (account_id = auth.uid());

drop policy if exists "bonus_redemptions_director_select" on public.bonus_redemptions;
create policy "bonus_redemptions_director_select" on public.bonus_redemptions
  for select using (public.current_user_role() = 'company_director');

-- ─────────────────────────────────────────
-- 5. bonus_withdrawals — full lifecycle with reservation.
-- ─────────────────────────────────────────
create table if not exists public.bonus_withdrawals (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.bonus_accounts(user_id)
    on delete restrict,
  amount numeric(12,2) not null check (amount > 0),
  status text not null default 'PENDING'
    check (status in ('PENDING','UNDER_REVIEW','APPROVED','REJECTED',
                      'PAID','COMPLETED','CANCELLED')),
  requested_at timestamptz not null default now(),
  reviewed_by uuid references public.users(id) on delete set null,
  reviewed_at timestamptz,
  approved_by uuid references public.users(id) on delete set null,
  approved_at timestamptz,
  paid_by uuid references public.users(id) on delete set null,
  paid_at timestamptz,
  payment_method text,
  payment_reference text,
  receipt_url text,
  notes text,
  rejection_reason text,
  ledger_id uuid references public.bonus_ledger(id) on delete set null,
  idempotency_key text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists bonus_withdrawals_account_status_idx
  on public.bonus_withdrawals (account_id, status);

alter table public.bonus_withdrawals enable row level security;

drop policy if exists "bonus_withdrawals_client_select" on public.bonus_withdrawals;
create policy "bonus_withdrawals_client_select" on public.bonus_withdrawals
  for select using (account_id = auth.uid());

drop policy if exists "bonus_withdrawals_director_select" on public.bonus_withdrawals;
create policy "bonus_withdrawals_director_select" on public.bonus_withdrawals
  for select using (public.current_user_role() = 'company_director');

-- Late FKs for the request links (both tables now exist).
-- RESTRICT: history must never lose its request side silently.
alter table public.bonus_ledger
  add constraint bonus_ledger_withdrawal_fk
  foreign key (withdrawal_id) references public.bonus_withdrawals(id)
  on delete restrict
  not valid;

alter table public.bonus_ledger
  add constraint bonus_ledger_redemption_fk
  foreign key (redemption_id) references public.bonus_redemptions(id)
  on delete restrict
  not valid;

alter table public.bonus_ledger validate constraint bonus_ledger_withdrawal_fk;
alter table public.bonus_ledger validate constraint bonus_ledger_redemption_fk;

-- ─────────────────────────────────────────
-- 6. bonus_settings — global key/value policies (director-managed).
--    Conservative secure defaults; the director enables features.
-- ─────────────────────────────────────────
create table if not exists public.bonus_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_by uuid references public.users(id) on delete set null,
  updated_at timestamptz not null default now()
);

alter table public.bonus_settings enable row level security;

drop policy if exists "bonus_settings_client_select" on public.bonus_settings;
create policy "bonus_settings_client_select" on public.bonus_settings
  for select using (auth.role() = 'authenticated');

drop policy if exists "bonus_settings_director_manage" on public.bonus_settings;
create policy "bonus_settings_director_manage" on public.bonus_settings
  for all using (public.current_user_role() = 'company_director')
  with check (public.current_user_role() = 'company_director');

insert into public.bonus_settings (key, value) values
  ('redemption_methods', '{"product": false, "discount": false, "cash": false}'::jsonb),
  ('withdrawal_policy', '{"enabled": false, "approval_required": true}'::jsonb),
  ('notifications', '{}'::jsonb),
  ('currency', '"YER"'::jsonb)
on conflict (key) do nothing;

-- ─────────────────────────────────────────
-- 7. bonus_audit_trail — append-only admin event log.
-- ─────────────────────────────────────────
create table if not exists public.bonus_audit_trail (
  id uuid primary key default gen_random_uuid(),
  entity text not null,
  entity_id uuid,
  action text not null,
  actor uuid references public.users(id) on delete set null,
  at_time timestamptz not null default now(),
  old_value jsonb,
  new_value jsonb,
  reason text,
  reference text
);

create index if not exists bonus_audit_trail_entity_idx
  on public.bonus_audit_trail (entity, entity_id, at_time desc);

alter table public.bonus_audit_trail enable row level security;

drop policy if exists "bonus_audit_client_select_own" on public.bonus_audit_trail;
create policy "bonus_audit_client_select_own" on public.bonus_audit_trail
  for select using (actor = auth.uid());

drop policy if exists "bonus_audit_director_select" on public.bonus_audit_trail;
create policy "bonus_audit_director_select" on public.bonus_audit_trail
  for select using (public.current_user_role() = 'company_director');

-- No UPDATE/DELETE policies for anyone: audit rows are immutable.

-- =============================================================
-- RPCs — all SECURITY DEFINER with fixed search_path.
-- Ownership and roles are enforced inside; RLS stays restrictive.
-- =============================================================

-- Shared balance reader: locks the account row, returns
-- (available, reserved). Reserved = PENDING ledger rows tied to
-- open redemption/withdrawal requests.
create or replace function public.bonus_account_funds(p_user_id uuid)
returns table (available numeric, reserved numeric)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_earned numeric(12,2) := 0;
  v_used numeric(12,2) := 0;
  v_reserved numeric(12,2) := 0;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  -- Privacy: only the account owner or the director may read funds.
  -- (SECURITY DEFINER bypasses RLS, so the check must live here.)
  if auth.uid() <> p_user_id
     and public.current_user_role() <> 'company_director' then
    raise exception 'Not permitted to read this bonus account';
  end if;

  perform 1 from public.bonus_accounts where user_id = p_user_id for update;
  if not found then
    return query select 0::numeric, 0::numeric;
    return;
  end if;

  select coalesce(sum(amount), 0) into v_earned
    from public.bonus_ledger
   where account_id = p_user_id and status = 'POSTED' and amount > 0;

  select coalesce(sum(-amount), 0) into v_used
    from public.bonus_ledger
   where account_id = p_user_id and status = 'POSTED' and amount < 0;

  select coalesce(sum(-amount), 0) into v_reserved
    from public.bonus_ledger
   where account_id = p_user_id and status = 'PENDING';

  return query select (v_earned - v_used - v_reserved)::numeric, v_reserved;
end $$;

-- 1) open_bonus_account — director only, idempotent per customer.
create or replace function public.open_bonus_account(
  p_user_id uuid,
  p_mode text default 'NONE',
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_current_mode text;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can open bonus accounts';
  end if;
  if p_mode not in ('NONE', 'OPENING_BALANCE', 'LEGACY_MIGRATION') then
    raise exception 'Unknown account mode %', p_mode;
  end if;
  if not exists (select 1 from public.users where id = p_user_id) then
    raise exception 'Customer % does not exist', p_user_id;
  end if;

  -- Mode history protection: an account that already carries a real mode
  -- must not be silently reclassified by a plain open call. NONE may move
  -- to its first real mode; anything else needs an explicit, audited
  -- reclassification path (not yet defined — intentionally blocked here).
  select mode into v_current_mode from public.bonus_accounts
   where user_id = p_user_id;
  if found
     and v_current_mode <> 'NONE'
     and v_current_mode is distinct from p_mode then
    raise exception 'Account % already has mode %; reclassification requires an explicit audited path',
      p_user_id, v_current_mode;
  end if;

  insert into public.bonus_accounts (user_id, mode, status, opened_at, opened_by, note)
  values (p_user_id, p_mode, 'active', now(), v_actor, p_note)
  on conflict (user_id) do update
    set mode = excluded.mode,
        status = 'active',
        opened_at = now(),
        opened_by = excluded.opened_by,
        note = excluded.note,
        updated_at = now();

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value, reason)
  values ('bonus_account', p_user_id, 'OPEN', v_actor,
          null, jsonb_build_object('mode', p_mode), p_note);

  return p_user_id;
end $$;

-- 2) post_opening_balance — director only, ledger-tracked, idempotent.
create or replace function public.post_opening_balance(
  p_user_id uuid,
  p_amount numeric,
  p_reference text,
  p_reason text default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_existing uuid;
  v_ledger_id uuid;
  v_current_mode text;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can post opening balances';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Opening balance must be positive';
  end if;
  if p_reference is null or btrim(p_reference) = '' then
    raise exception 'Opening balance requires a reference';
  end if;

  -- Mode consistency: never silently convert an account that already
  -- carries a different real mode (NONE or OPENING_BALANCE only).
  select mode into v_current_mode from public.bonus_accounts
   where user_id = p_user_id;
  if found
     and v_current_mode not in ('NONE', 'OPENING_BALANCE') then
    raise exception 'Account % already has mode %; refusing silent reclassification',
      p_user_id, v_current_mode;
  end if;

  if p_idempotency_key is not null then
    select id into v_existing from public.bonus_ledger
     where idempotency_key = p_idempotency_key;
    if found then return v_existing; end if;
  end if;

  insert into public.bonus_accounts (user_id, mode, status, opened_at, opened_by, note)
  values (p_user_id, 'OPENING_BALANCE', 'active', now(), v_actor, p_reason)
  on conflict (user_id) do update
    set mode = 'OPENING_BALANCE', status = 'active',
        opened_at = now(), opened_by = excluded.opened_by,
        note = excluded.note, updated_at = now();

  insert into public.bonus_ledger
    (account_id, txn_type, amount, status, actor, reference, notes, idempotency_key)
  values (p_user_id, 'OPENING_BALANCE', p_amount, 'POSTED',
          v_actor, p_reference, p_reason, p_idempotency_key)
  returning id into v_ledger_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value, reason, reference)
  values ('bonus_ledger', v_ledger_id, 'OPENING_BALANCE', v_actor,
          null, jsonb_build_object('account', p_user_id, 'amount', p_amount),
          p_reason, p_reference);

  return v_ledger_id;
end $$;

-- 3) post_legacy_migration — director only, ledger-tracked, idempotent.
create or replace function public.post_legacy_migration(
  p_user_id uuid,
  p_amount numeric,
  p_reference text,
  p_reason text default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_existing uuid;
  v_ledger_id uuid;
  v_current_mode text;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can post legacy migrations';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Legacy amount must be positive';
  end if;
  if p_reference is null or btrim(p_reference) = '' then
    raise exception 'Legacy migration requires an approval reference';
  end if;

  -- Mode consistency: never silently convert an account that already
  -- carries a different real mode (NONE or LEGACY_MIGRATION only).
  select mode into v_current_mode from public.bonus_accounts
   where user_id = p_user_id;
  if found
     and v_current_mode not in ('NONE', 'LEGACY_MIGRATION') then
    raise exception 'Account % already has mode %; refusing silent reclassification',
      p_user_id, v_current_mode;
  end if;

  if p_idempotency_key is not null then
    select id into v_existing from public.bonus_ledger
     where idempotency_key = p_idempotency_key;
    if found then return v_existing; end if;
  end if;

  insert into public.bonus_accounts (user_id, mode, status, opened_at, opened_by, note)
  values (p_user_id, 'LEGACY_MIGRATION', 'active', now(), v_actor, p_reason)
  on conflict (user_id) do update
    set mode = 'LEGACY_MIGRATION', status = 'active',
        opened_at = now(), opened_by = excluded.opened_by,
        note = excluded.note, updated_at = now();

  insert into public.bonus_ledger
    (account_id, txn_type, amount, status, actor, reference, notes, idempotency_key)
  values (p_user_id, 'LEGACY_MIGRATION', p_amount, 'POSTED',
          v_actor, p_reference, p_reason, p_idempotency_key)
  returning id into v_ledger_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value, reason, reference)
  values ('bonus_ledger', v_ledger_id, 'LEGACY_MIGRATION', v_actor,
          null, jsonb_build_object('account', p_user_id, 'amount', p_amount),
          p_reason, p_reference);

  return v_ledger_id;
end $$;

-- 4) earn_bonus — director/system credit linked to a v2 rule.
create or replace function public.earn_bonus(
  p_user_id uuid,
  p_amount numeric,
  p_rule_id uuid default null,
  p_reference text default null,
  p_reason text default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_existing uuid;
  v_ledger_id uuid;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can post earnings';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Earn amount must be positive';
  end if;
  if not exists (select 1 from public.bonus_accounts
                  where user_id = p_user_id and status = 'active') then
    raise exception 'No active bonus account for %', p_user_id;
  end if;

  if p_idempotency_key is not null then
    select id into v_existing from public.bonus_ledger
     where idempotency_key = p_idempotency_key;
    if found then return v_existing; end if;
  end if;

  insert into public.bonus_ledger
    (account_id, txn_type, amount, status, rule_id, actor, reference, notes, idempotency_key)
  values (p_user_id, 'EARN', p_amount, 'POSTED', p_rule_id,
          v_actor, p_reference, p_reason, p_idempotency_key)
  returning id into v_ledger_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value, reason, reference)
  values ('bonus_ledger', v_ledger_id, 'EARN', v_actor,
          null, jsonb_build_object('account', p_user_id, 'amount', p_amount),
          p_reason, p_reference);

  return v_ledger_id;
end $$;

-- 5) request_redemption — customer reserves bonus for one product.
create or replace function public.request_redemption(
  p_product_id uuid,
  p_quantity int,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client uuid := auth.uid();
  v_available numeric;
  v_reserved numeric;
  v_price numeric(10,2);
  v_value numeric(12,2);
  v_existing uuid;
  v_redemption_id uuid;
  v_ledger_id uuid;
begin
  if v_client is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'client' then
    raise exception 'Only clients can request redemptions';
  end if;
  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Quantity must be positive';
  end if;

  if p_idempotency_key is not null then
    select id into v_existing from public.bonus_redemptions
     where idempotency_key = p_idempotency_key;
    if found then return v_existing; end if;
  end if;

  -- Catalog price is read under a row lock so a concurrent price change
  -- cannot slip between the read and the reservation insert; the stored
  -- bonus_value is therefore a fixed snapshot of this request's value.
  select unit_price into v_price from public.products
   where id = p_product_id and is_active = true for update;
  if not found then
    raise exception 'Product % is not active or does not exist', p_product_id;
  end if;
  v_value := (v_price * p_quantity)::numeric(12,2);

  select * into v_available, v_reserved
    from public.bonus_account_funds(v_client);
  if v_available < v_value then
    raise exception 'Insufficient available bonus (need %, have %)',
      v_value, v_available;
  end if;

  insert into public.bonus_redemptions
    (account_id, product_id, quantity, bonus_value, status,
     requested_by, idempotency_key)
  values (v_client, p_product_id, p_quantity, v_value, 'PENDING',
          v_client, p_idempotency_key)
  returning id into v_redemption_id;

  insert into public.bonus_ledger
    (account_id, txn_type, amount, status, redemption_id, actor, notes)
  values (v_client, 'REDEEM_PRODUCT', -v_value, 'PENDING',
          v_redemption_id, v_client, 'reservation')
  returning id into v_ledger_id;

  update public.bonus_redemptions
     set ledger_id = v_ledger_id
   where id = v_redemption_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value)
  values ('bonus_redemption', v_redemption_id, 'REQUEST', v_client,
          null, jsonb_build_object('value', v_value));

  return v_redemption_id;
end $$;

-- 6) approve_redemption — director moves PENDING to APPROVED.
create or replace function public.approve_redemption(p_redemption_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.bonus_redemptions%rowtype;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can approve redemptions';
  end if;

  select * into v_row from public.bonus_redemptions
   where id = p_redemption_id for update;
  if not found then raise exception 'Redemption % not found', p_redemption_id; end if;
  if v_row.status <> 'PENDING' then
    raise exception 'Only PENDING redemptions can be approved (current: %)', v_row.status;
  end if;

  update public.bonus_redemptions
     set status = 'APPROVED', decided_by = v_actor,
         decided_at = now(), updated_at = now()
   where id = p_redemption_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value)
  values ('bonus_redemption', p_redemption_id, 'APPROVE', v_actor,
          jsonb_build_object('status', 'PENDING'),
          jsonb_build_object('status', 'APPROVED'));
end $$;

-- 7) fulfill_redemption — director consumes the reservation.
create or replace function public.fulfill_redemption(p_redemption_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.bonus_redemptions%rowtype;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can fulfill redemptions';
  end if;

  select * into v_row from public.bonus_redemptions
   where id = p_redemption_id for update;
  if not found then raise exception 'Redemption % not found', p_redemption_id; end if;
  if v_row.status <> 'APPROVED' then
    raise exception 'Only APPROVED redemptions can be fulfilled (current: %)', v_row.status;
  end if;

  update public.bonus_ledger
     set status = 'POSTED'
   where id = v_row.ledger_id and status = 'PENDING';

  update public.bonus_redemptions
     set status = 'FULFILLED', updated_at = now()
   where id = p_redemption_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value)
  values ('bonus_redemption', p_redemption_id, 'FULFILL', v_actor,
          jsonb_build_object('status', 'APPROVED'),
          jsonb_build_object('status', 'FULFILLED'));
end $$;

-- 8) cancel_redemption — client (own PENDING) or director releases it.
create or replace function public.cancel_redemption(p_redemption_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_role text := public.current_user_role();
  v_row public.bonus_redemptions%rowtype;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;

  select * into v_row from public.bonus_redemptions
   where id = p_redemption_id for update;
  if not found then raise exception 'Redemption % not found', p_redemption_id; end if;
  if v_row.status <> 'PENDING' then
    raise exception 'Only PENDING redemptions can be cancelled (current: %)', v_row.status;
  end if;
  if v_role = 'client' and v_row.account_id <> v_actor then
    raise exception 'Not your redemption request';
  end if;
  if v_role not in ('client', 'company_director') then
    raise exception 'Not permitted to cancel redemptions';
  end if;

  delete from public.bonus_ledger where id = v_row.ledger_id and status = 'PENDING';

  update public.bonus_redemptions
     set status = 'CANCELLED', decided_by = v_actor,
         decided_at = now(), updated_at = now()
   where id = p_redemption_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value)
  values ('bonus_redemption', p_redemption_id, 'CANCEL', v_actor,
          jsonb_build_object('status', 'PENDING'),
          jsonb_build_object('status', 'CANCELLED'));
end $$;

-- 9a) cancel_withdrawal — client (own PENDING/UNDER_REVIEW) or director
--     releases the reservation. (CANCELLED is reachable only via this path.)
create or replace function public.cancel_withdrawal(p_withdrawal_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_role text := public.current_user_role();
  v_row public.bonus_withdrawals%rowtype;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;

  select * into v_row from public.bonus_withdrawals
   where id = p_withdrawal_id for update;
  if not found then raise exception 'Withdrawal % not found', p_withdrawal_id; end if;
  if v_row.status not in ('PENDING', 'UNDER_REVIEW') then
    raise exception 'Only PENDING/UNDER_REVIEW withdrawals can be cancelled (current: %)',
      v_row.status;
  end if;
  if v_role = 'client' and v_row.account_id <> v_actor then
    raise exception 'Not your withdrawal request';
  end if;
  if v_role not in ('client', 'company_director') then
    raise exception 'Not permitted to cancel withdrawals';
  end if;

  delete from public.bonus_ledger where id = v_row.ledger_id and status = 'PENDING';

  update public.bonus_withdrawals
     set status = 'CANCELLED', updated_at = now()
   where id = p_withdrawal_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value)
  values ('bonus_withdrawal', p_withdrawal_id, 'CANCEL', v_actor,
          jsonb_build_object('status', v_row.status),
          jsonb_build_object('status', 'CANCELLED'));
end $$;

-- 9) request_withdrawal — client reserves bonus as cash (policy-gated).
create or replace function public.request_withdrawal(
  p_amount numeric,
  p_method text default null,
  p_notes text default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client uuid := auth.uid();
  v_available numeric;
  v_reserved numeric;
  v_policy jsonb;
  v_existing uuid;
  v_withdrawal_id uuid;
  v_ledger_id uuid;
  v_month_used numeric(12,2) := 0;
begin
  if v_client is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'client' then
    raise exception 'Only clients can request withdrawals';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Amount must be positive';
  end if;

  select value into v_policy from public.bonus_settings
   where key = 'withdrawal_policy';
  if coalesce((v_policy->>'enabled')::boolean, false) is not true then
    raise exception 'Cash withdrawal is currently disabled';
  end if;
  if (v_policy->>'min_amount')::numeric is not null
     and p_amount < (v_policy->>'min_amount')::numeric then
    raise exception 'Amount below the minimum withdrawal';
  end if;
  if (v_policy->>'max_amount')::numeric is not null
     and p_amount > (v_policy->>'max_amount')::numeric then
    raise exception 'Amount exceeds the maximum withdrawal';
  end if;

  select * into v_available, v_reserved
    from public.bonus_account_funds(v_client);
  if v_available < p_amount then
    raise exception 'Insufficient available bonus (need %, have %)',
      p_amount, v_available;
  end if;

  -- Optional policy caps, all settings-driven (skipped when unconfigured).
  if (v_policy->>'max_percent_of_available')::numeric is not null
     and v_available > 0
     and p_amount * 100 > v_available * (v_policy->>'max_percent_of_available')::numeric then
    raise exception 'Amount exceeds the allowed percentage of available bonus';
  end if;
  if (v_policy->>'monthly_max')::numeric is not null then
    select coalesce(sum(amount), 0) into v_month_used
      from public.bonus_withdrawals
     where account_id = v_client
       and status not in ('REJECTED', 'CANCELLED')
       and created_at >= date_trunc('month', now());
    if v_month_used + p_amount > (v_policy->>'monthly_max')::numeric then
      raise exception 'Amount exceeds the monthly withdrawal limit';
    end if;
  end if;

  if p_idempotency_key is not null then
    select id into v_existing from public.bonus_withdrawals
     where idempotency_key = p_idempotency_key;
    if found then return v_existing; end if;
  end if;

  insert into public.bonus_withdrawals
    (account_id, amount, status, payment_method, notes, idempotency_key)
  values (v_client, p_amount, 'PENDING', p_method, p_notes, p_idempotency_key)
  returning id into v_withdrawal_id;

  insert into public.bonus_ledger
    (account_id, txn_type, amount, status, withdrawal_id, actor, notes)
  values (v_client, 'CASH_WITHDRAWAL', -p_amount, 'PENDING',
          v_withdrawal_id, v_client, 'reservation')
  returning id into v_ledger_id;

  update public.bonus_withdrawals
     set ledger_id = v_ledger_id
   where id = v_withdrawal_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value)
  values ('bonus_withdrawal', v_withdrawal_id, 'REQUEST', v_client,
          null, jsonb_build_object('amount', p_amount));

  return v_withdrawal_id;
end $$;

-- 10a) start_withdrawal_review — director moves PENDING to UNDER_REVIEW.
--     (Required so the UNDER_REVIEW lifecycle state is reachable;
--     approve/reject remain in review_withdrawal. Documented deviation:
--     15 RPCs total instead of 14.)
create or replace function public.start_withdrawal_review(p_withdrawal_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.bonus_withdrawals%rowtype;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can review withdrawals';
  end if;

  select * into v_row from public.bonus_withdrawals
   where id = p_withdrawal_id for update;
  if not found then raise exception 'Withdrawal % not found', p_withdrawal_id; end if;
  if v_row.status <> 'PENDING' then
    raise exception 'Only PENDING withdrawals can start review (current: %)', v_row.status;
  end if;

  update public.bonus_withdrawals
     set status = 'UNDER_REVIEW', reviewed_by = v_actor,
         reviewed_at = now(), updated_at = now()
   where id = p_withdrawal_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value)
  values ('bonus_withdrawal', p_withdrawal_id, 'START_REVIEW', v_actor,
          jsonb_build_object('status', 'PENDING'),
          jsonb_build_object('status', 'UNDER_REVIEW'));
end $$;

-- 10) review_withdrawal — director approves (to UNDER_REVIEW/APPROVED
--     path) or rejects with a reason. No self-approval possible:
--     requesters are clients, reviewers must be directors.
create or replace function public.review_withdrawal(
  p_withdrawal_id uuid,
  p_approve boolean,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.bonus_withdrawals%rowtype;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can review withdrawals';
  end if;

  select * into v_row from public.bonus_withdrawals
   where id = p_withdrawal_id for update;
  if not found then raise exception 'Withdrawal % not found', p_withdrawal_id; end if;
  if v_row.status not in ('PENDING', 'UNDER_REVIEW') then
    raise exception 'Only PENDING/UNDER_REVIEW withdrawals can be reviewed (current: %)',
      v_row.status;
  end if;

  if p_approve then
    update public.bonus_withdrawals
       set status = 'APPROVED', reviewed_by = v_actor, reviewed_at = now(),
           approved_by = v_actor, approved_at = now(), updated_at = now()
     where id = p_withdrawal_id;
  else
    if p_reason is null or btrim(p_reason) = '' then
      raise exception 'Rejection requires a reason';
    end if;
    delete from public.bonus_ledger
     where id = v_row.ledger_id and status = 'PENDING';

    update public.bonus_withdrawals
       set status = 'REJECTED', reviewed_by = v_actor, reviewed_at = now(),
           rejection_reason = p_reason, updated_at = now()
     where id = p_withdrawal_id;
  end if;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value, reason)
  values ('bonus_withdrawal', p_withdrawal_id,
          case when p_approve then 'APPROVE' else 'REJECT' end, v_actor,
          jsonb_build_object('status', v_row.status),
          jsonb_build_object('status', case when p_approve then 'APPROVED' else 'REJECTED' end),
          p_reason);
end $$;

-- 11) mark_withdrawal_paid — director records the payment reference.
create or replace function public.mark_withdrawal_paid(
  p_withdrawal_id uuid,
  p_reference text,
  p_receipt_url text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.bonus_withdrawals%rowtype;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can mark withdrawals paid';
  end if;
  if p_reference is null or btrim(p_reference) = '' then
    raise exception 'Payment requires a reference';
  end if;

  select * into v_row from public.bonus_withdrawals
   where id = p_withdrawal_id for update;
  if not found then raise exception 'Withdrawal % not found', p_withdrawal_id; end if;
  if v_row.status <> 'APPROVED' then
    raise exception 'Only APPROVED withdrawals can be paid (current: %)', v_row.status;
  end if;

  update public.bonus_ledger
     set status = 'POSTED'
   where id = v_row.ledger_id and status = 'PENDING';

  update public.bonus_withdrawals
     set status = 'PAID', paid_by = v_actor, paid_at = now(),
         payment_reference = p_reference, receipt_url = p_receipt_url,
         updated_at = now()
   where id = p_withdrawal_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value, reference)
  values ('bonus_withdrawal', p_withdrawal_id, 'PAY', v_actor,
          jsonb_build_object('status', 'APPROVED'),
          jsonb_build_object('status', 'PAID'), p_reference);
end $$;

-- 12) complete_withdrawal — director closes a paid withdrawal.
create or replace function public.complete_withdrawal(p_withdrawal_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.bonus_withdrawals%rowtype;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can complete withdrawals';
  end if;

  select * into v_row from public.bonus_withdrawals
   where id = p_withdrawal_id for update;
  if not found then raise exception 'Withdrawal % not found', p_withdrawal_id; end if;
  if v_row.status <> 'PAID' then
    raise exception 'Only PAID withdrawals can be completed (current: %)', v_row.status;
  end if;

  update public.bonus_withdrawals
     set status = 'COMPLETED', updated_at = now()
   where id = p_withdrawal_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value)
  values ('bonus_withdrawal', p_withdrawal_id, 'COMPLETE', v_actor,
          jsonb_build_object('status', 'PAID'),
          jsonb_build_object('status', 'COMPLETED'));
end $$;

-- 13) reverse_bonus_txn — director posts a compensating REVERSAL.
--     One compensation per original is enforced by the partial unique
--     index on reverses_id; REVERSAL rows themselves cannot be reversed.
create or replace function public.reverse_bonus_txn(
  p_ledger_id uuid,
  p_reason text,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.bonus_ledger%rowtype;
  v_existing uuid;
  v_reversal_id uuid;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can reverse transactions';
  end if;
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'Reversal requires a reason';
  end if;

  if p_idempotency_key is not null then
    select id into v_existing from public.bonus_ledger
     where idempotency_key = p_idempotency_key;
    if found then return v_existing; end if;
  end if;

  select * into v_row from public.bonus_ledger
   where id = p_ledger_id for update;
  if not found then raise exception 'Ledger entry % not found', p_ledger_id; end if;
  if v_row.status <> 'POSTED' then
    raise exception 'Only POSTED entries can be reversed (current: %)', v_row.status;
  end if;
  if v_row.txn_type = 'REVERSAL' then
    raise exception 'A REVERSAL entry cannot itself be reversed';
  end if;
  if exists (select 1 from public.bonus_ledger
              where reverses_id = p_ledger_id
                and txn_type = 'REVERSAL'
                and status = 'POSTED') then
    raise exception 'Ledger entry % already has an effective reversal', p_ledger_id;
  end if;

  -- The original row is never touched: compensation only.
  insert into public.bonus_ledger
    (account_id, txn_type, amount, status, order_id, withdrawal_id,
     redemption_id, rule_id, reverses_id, actor, reference, notes, idempotency_key)
  values (v_row.account_id, 'REVERSAL', -v_row.amount, 'POSTED',
          v_row.order_id, v_row.withdrawal_id, v_row.redemption_id,
          v_row.rule_id, v_row.id, v_actor, v_row.reference,
          'Reversal of ' || v_row.id::text || ': ' || p_reason,
          p_idempotency_key)
  returning id into v_reversal_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value, reason)
  values ('bonus_ledger', v_reversal_id, 'REVERSAL', v_actor,
          jsonb_build_object('reversed', v_row.id),
          jsonb_build_object('amount', -v_row.amount), p_reason);

  return v_reversal_id;
end $$;

-- 14) expire_bonus — system/director expires aged EARN balances per
--     settings (no hard-coded durations here; disabled unless configured).
create or replace function public.expire_bonus(
  p_asof date default current_date
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_role text := public.current_user_role();
  v_expiry_days int;
  v_count int := 0;
  v_n int;
  v_available numeric;
  v_reserved numeric;
  v_row record;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if v_role <> 'company_director' then
    raise exception 'Only the company director can run expiry';
  end if;

  select nullif(value->>'expiry_days', '')::int into v_expiry_days
    from public.bonus_settings where key = 'expiry_policy';
  if v_expiry_days is null or v_expiry_days <= 0 then
    raise exception 'Expiry is not configured (bonus_settings.expiry_policy)';
  end if;

  for v_row in
    select l.id, l.account_id, l.amount
      from public.bonus_ledger l
     where l.txn_type = 'EARN'
       and l.status = 'POSTED'
       and l.created_at::date <= p_asof - v_expiry_days
       and not exists (
         select 1 from public.bonus_ledger e
          where e.reverses_id = l.id
            and e.txn_type = 'EXPIRATION'
            and e.status = 'POSTED'
       )
     order by l.account_id, l.created_at
     for update of l
  loop
    -- Cap at the account's currently available balance: never expire
    -- more than what is actually expirable, even under reruns/races.
    -- (The partial unique index on reverses_id is the backstop.)
    select * into v_available, v_reserved
      from public.bonus_account_funds(v_row.account_id);
    if v_available <= 0 then continue; end if;

    -- Original EARN row is never touched: compensation only, linked.
    -- ON CONFLICT makes concurrent/duplicate runs skip gracefully instead
    -- of aborting (arbiter matches bonus_ledger_reverses_uniq exactly).
    insert into public.bonus_ledger
      (account_id, txn_type, amount, status, rule_id, reverses_id,
       actor, notes)
    values (v_row.account_id, 'EXPIRATION',
            -least(v_row.amount, v_available), 'POSTED',
            null, v_row.id, v_actor, 'Expired EARN ' || v_row.id::text)
    on conflict (reverses_id)
      where reverses_id is not null and txn_type in ('REVERSAL', 'EXPIRATION')
      do nothing;
    get diagnostics v_n = row_count;
    v_count := v_count + v_n;
  end loop;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value)
  values ('bonus_expiry', null, 'EXPIRE_RUN', v_actor,
          null, jsonb_build_object('asof', p_asof, 'expired', v_count));

  return v_count;
end $$;

-- Grants: clients may call request/cancel flows; everything else is
-- still role-gated inside the functions. No table-level writes granted.
grant execute on function public.bonus_account_funds(uuid) to authenticated;
grant execute on function public.open_bonus_account(uuid, text, text) to authenticated;
grant execute on function public.post_opening_balance(uuid, numeric, text, text, text) to authenticated;
grant execute on function public.post_legacy_migration(uuid, numeric, text, text, text) to authenticated;
grant execute on function public.earn_bonus(uuid, numeric, uuid, text, text, text) to authenticated;
grant execute on function public.request_redemption(uuid, int, text) to authenticated;
grant execute on function public.approve_redemption(uuid) to authenticated;
grant execute on function public.fulfill_redemption(uuid) to authenticated;
grant execute on function public.cancel_redemption(uuid) to authenticated;
grant execute on function public.request_withdrawal(numeric, text, text, text) to authenticated;
grant execute on function public.cancel_withdrawal(uuid) to authenticated;
grant execute on function public.start_withdrawal_review(uuid) to authenticated;
grant execute on function public.review_withdrawal(uuid, boolean, text) to authenticated;
grant execute on function public.mark_withdrawal_paid(uuid, text, text) to authenticated;
grant execute on function public.complete_withdrawal(uuid) to authenticated;
grant execute on function public.reverse_bonus_txn(uuid, text, text) to authenticated;
grant execute on function public.expire_bonus(date) to authenticated;
