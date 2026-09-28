-- =============================================================
-- Migration 0019 — Bonus Earn Engine (sales earn at delivery)
-- MedLink Yemen — shared Supabase database
--
-- SCOPE (per approved blueprints ONLY):
--   Sales-driven EARN creation when orders reach 'delivered'.
--   NO General Ledger, NO revenue recognition, NO liability posting,
--   NO order-discount engine, NO UI, NO changes to 0016/0017/0018 files.
--   0017 (create_order_with_items) is NOT modified: earn happens at
--   delivery via trigger, covering Driver RPC and Manager direct UPDATE.
--
-- Conventions: additive only; SECURITY DEFINER + fixed search_path;
-- RLS untouched (new table gets its own policies); deterministic
-- oldest-first/priority ordering; idempotent event keys.
-- Run manually (Dashboard → SQL Editor) after review. No auto-apply.
-- =============================================================

-- ─────────────────────────────────────────
-- 1. Account mode: SALES origin (0018 file untouched — ALTER here).
-- ─────────────────────────────────────────
alter table public.bonus_accounts
  drop constraint if exists bonus_accounts_mode_check;

alter table public.bonus_accounts
  add constraint bonus_accounts_mode_check
  check (mode in ('NONE', 'SALES', 'OPENING_BALANCE', 'LEGACY_MIGRATION'));

-- ─────────────────────────────────────────
-- 2. Rule value basis + per-product values (0018 file untouched).
-- ─────────────────────────────────────────
alter table public.bonus_rules_v2
  add column if not exists value_basis text not null default 'PER_ORDER';

alter table public.bonus_rules_v2
  drop constraint if exists bonus_rules_v2_value_basis_check;

alter table public.bonus_rules_v2
  add constraint bonus_rules_v2_value_basis_check
  check (value_basis in ('PER_ORDER', 'PER_UNIT', 'PER_PRODUCT'));

alter table public.bonus_rules_v2
  add column if not exists product_values jsonb;

-- ─────────────────────────────────────────
-- 3. Pending entitlements (never deleted; PROCESSED retained for audit).
-- ─────────────────────────────────────────
create table if not exists public.bonus_pending_entitlements (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  account_id uuid not null references public.bonus_accounts(user_id)
    on delete restrict,
  rule_id uuid references public.bonus_rules_v2(id) on delete set null,
  value_basis text,
  computed_value numeric(12,2),
  product_snapshot jsonb,
  rule_snapshot jsonb,
  idempotency_key text unique,
  status text not null default 'PENDING'
    check (status in ('PENDING', 'PROCESSED', 'FAILED')),
  error_reason text,
  attempts int not null default 0 check (attempts >= 0),
  processed_at timestamptz,
  ledger_id uuid references public.bonus_ledger(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists bonus_pending_account_status_idx
  on public.bonus_pending_entitlements (account_id, status);

alter table public.bonus_pending_entitlements enable row level security;

drop policy if exists "bonus_pending_client_select" on public.bonus_pending_entitlements;
create policy "bonus_pending_client_select" on public.bonus_pending_entitlements
  for select using (account_id = auth.uid());

drop policy if exists "bonus_pending_director_select" on public.bonus_pending_entitlements;
create policy "bonus_pending_director_select" on public.bonus_pending_entitlements
  for select using (public.current_user_role() = 'company_director');

-- No direct writes for anyone: trigger/processor RPCs only.

-- ─────────────────────────────────────────
-- 4. Rule checks: bonus_check_rule_v2() returns the first violation
--    message (or null when valid). No exception text is ever parsed for
--    control flow — callers branch on null-ness only.
-- ─────────────────────────────────────────
create or replace function public.bonus_check_rule_v2(p_rule public.bonus_rules_v2)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_key text;
  v_val text;
  v_missing int;
  v_bad int;
begin
  -- Type / basis compatibility (contract §5).
  if p_rule.rule_type = 'PRODUCT'
     and p_rule.value_basis not in ('PER_ORDER', 'PER_UNIT', 'PER_PRODUCT') then
    return format('Rule %s: PRODUCT allows only PER_ORDER/PER_UNIT/PER_PRODUCT', p_rule.id);
  end if;
  if p_rule.rule_type = 'MONETARY'
     and p_rule.value_basis not in ('PER_ORDER') then
    return format('Rule %s: MONETARY allows only PER_ORDER basis', p_rule.id);
  end if;
  if p_rule.rule_type = 'MONETARY'
     and ((p_rule.bonus_percent is null) = (p_rule.bonus_value is null)) then
    return format('Rule %s: MONETARY requires exactly one of percent/xor fixed value', p_rule.id);
  end if;
  if p_rule.rule_type = 'GENERAL' and p_rule.value_basis <> 'PER_ORDER' then
    return format('Rule %s: GENERAL allows only PER_ORDER basis', p_rule.id);
  end if;
  if p_rule.rule_type = 'GENERAL'
     and (p_rule.products_include is not null
          or p_rule.products_exclude is not null) then
    return format('Rule %s: GENERAL must not bind products', p_rule.id);
  end if;

  -- customer_type has no users-side column in the current schema, so any
  -- rule carrying it is unverifiable by definition (IMPLEMENTATION GAP).
  if p_rule.customer_type is not null and btrim(p_rule.customer_type) <> '' then
    return format('Rule %s: customer_type has no backing users column yet', p_rule.id);
  end if;

  -- product_values is only meaningful for PER_PRODUCT.
  if (p_rule.value_basis is distinct from 'PER_PRODUCT')
     and p_rule.product_values is not null
     and p_rule.product_values <> '{}'::jsonb then
    return format('Rule %s: product_values is only supported for PER_PRODUCT', p_rule.id);
  end if;

  -- Deep product_values validation (object, UUID keys, numeric >= 0,
  -- products exist and are active, include/exclude consistency).
  if p_rule.value_basis = 'PER_PRODUCT' then
    if p_rule.product_values is null
       or jsonb_typeof(p_rule.product_values) <> 'object'
       or p_rule.product_values = '{}'::jsonb then
      return format('Rule %s: PER_PRODUCT requires a non-empty product_values object', p_rule.id);
    end if;
    for v_key, v_val in
      select k, p_rule.product_values ->> k from jsonb_object_keys(p_rule.product_values) k
    loop
      if v_key !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
        return format('Rule %s: product_values key %s is not a UUID', p_rule.id, v_key);
      end if;
      if v_val is null or v_val !~ '^[0-9]+(\.[0-9]+)?$' then
        return format('Rule %s: product_values[%s] is not a non-negative number', p_rule.id, v_key);
      end if;
      if not exists (select 1 from public.products
                      where id = v_key::uuid and is_active = true) then
        return format('Rule %s: product %s is missing or inactive', p_rule.id, v_key);
      end if;
      if p_rule.products_include is not null
         and not (v_key::uuid = any (p_rule.products_include)) then
        return format('Rule %s: product %s not in products_include', p_rule.id, v_key);
      end if;
      if p_rule.products_exclude is not null
         and v_key::uuid = any (p_rule.products_exclude) then
        return format('Rule %s: product %s is both valued and excluded', p_rule.id, v_key);
      end if;
    end loop;
  end if;

  -- Value sanity (no negative economics, no zero-quantity traps).
  if p_rule.bonus_value is not null and p_rule.bonus_value < 0 then
    return format('Rule %s: bonus_value must be >= 0', p_rule.id);
  end if;
  if p_rule.max_bonus is not null and p_rule.max_bonus <= 0 then
    return format('Rule %s: max_bonus must be positive', p_rule.id);
  end if;
  if p_rule.start_date is not null and p_rule.end_date is not null
     and p_rule.start_date > p_rule.end_date then
    return format('Rule %s: start_date is after end_date', p_rule.id);
  end if;

  return null;
end $$;

-- Thin raising wrapper kept for backward-compatible direct calls.
create or replace function public.bonus_validate_rule_v2(p_rule public.bonus_rules_v2)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_msg text;
begin
  v_msg := public.bonus_check_rule_v2(p_rule);
  if v_msg is not null then raise exception '%', v_msg; end if;
end $$;

-- DB-level save guard: invalid rules are rejected at INSERT/UPDATE time,
-- regardless of which client path writes them (RLS alone is not enough).
create or replace function public.bonus_rules_v2_validate_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.bonus_validate_rule_v2(NEW);
  return NEW;
end $$;

drop trigger if exists trg_bonus_rules_v2_validate on public.bonus_rules_v2;
create trigger trg_bonus_rules_v2_validate
  before insert or update on public.bonus_rules_v2
  for each row execute function public.bonus_rules_v2_validate_trigger();

-- ─────────────────────────────────────────
-- 5. Earn evaluator for one delivered order (called by trigger below).
--    Deterministic: priority, created_at, id. stacking: first
--    non-stackable winner stops later rules. usage: ledger-derived
--    count of POSTED SALES earns per (rule, account), minus reversed.
-- ─────────────────────────────────────────
create or replace function public.bonus_evaluate_order_earn(p_order_id uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_client uuid;
  v_governorate text;
  v_branch_governorate text;
  v_items_total numeric(12,2) := 0;
  v_items_qty int := 0;
  v_rule public.bonus_rules_v2%rowtype;
  v_eligible_value numeric(12,2);
  v_eligible_qty int;
  v_earned numeric(12,2);
  v_used_count int;
  v_key text;
  v_ledger_id uuid;
  v_count int := 0;
  v_stop boolean := false;
  v_cfg_err text;
  v_today date;
  v_prod_snap jsonb;
begin
  select * into v_order from public.orders where id = p_order_id;
  if not found then raise exception 'Order % not found', p_order_id; end if;
  if v_order.status <> 'delivered' then
    raise exception 'Order % is not delivered (status: %)', p_order_id, v_order.status;
  end if;
  v_client := v_order.client_id;

  -- Account must exist (created at first earn); never reclassify origins.
  insert into public.bonus_accounts (user_id, mode, status)
  values (v_client, 'SALES', 'active')
  on conflict (user_id) do nothing;

  -- First sales earn promotes NONE to SALES; OPENING/LEGACY never change.
  update public.bonus_accounts
     set mode = 'SALES', updated_at = now()
   where user_id = v_client and mode = 'NONE';

  -- Lock the account row: serializes concurrent earn runs per customer.
  perform 1 from public.bonus_accounts where user_id = v_client for update;

  -- Suspended accounts earn nothing here (trigger diverts to pending).
  if exists (select 1 from public.bonus_accounts
              where user_id = v_client and status = 'suspended') then
    raise exception 'Bonus account is suspended for %', v_client;
  end if;

  select governorate into v_branch_governorate
    from public.branches where id = v_order.branch_id;
  select governorate into v_governorate
    from public.client_addresses where id = v_order.delivery_address_id;

  -- Server-accepted paid lines only (Free-Y bonus lines excluded).
  select coalesce(sum(oi.quantity * oi.unit_price), 0),
         coalesce(sum(oi.quantity), 0)
    into v_items_total, v_items_qty
    from public.order_items oi
   where oi.order_id = p_order_id and not coalesce(oi.is_bonus, false);

  -- Business calendar: Yemen (Asia/Aden). Matches the client-side
  -- date-only convention (device-local calendar days); the DB server
  -- itself runs on UTC, so the zone is stated explicitly, never assumed.
  v_today := ((now() at time zone 'Asia/Aden'))::date;

  for v_rule in
    -- Priority direction (documented contract): ASCENDING priority wins
    -- first; ties break by created_at, then id. Deterministic always.
    select * from public.bonus_rules_v2
     where status = 'active'
     order by priority, created_at, id
  loop
    exit when v_stop;

    -- Date window evaluated at DELIVERY time (earn event time).
    if v_rule.start_date is not null and v_today < v_rule.start_date then continue; end if;
    if v_rule.end_date is not null and v_today > v_rule.end_date then continue; end if;

    -- Structural validation via check function (never exception-text
    -- parsing): a bad rule aborts loudly with one fixed sentinel, so the
    -- delivery fails visibly instead of minting misleading pending rows.
    select public.bonus_check_rule_v2(v_rule) into v_cfg_err;
    if v_cfg_err is not null then
      raise exception 'BONUS_CONFIG_ERROR';
    end if;

    -- Eligibility: customer / type / governorate / products / minimums.
    if v_rule.eligible_customers is not null
       and not (v_client = any (v_rule.eligible_customers)) then continue; end if;
    if v_rule.governorate is not null
       and lower(btrim(v_rule.governorate)) not in (
         lower(btrim(coalesce(v_governorate, ''))),
         lower(btrim(coalesce(v_branch_governorate, '')))) then continue; end if;

    -- Eligible slice of THIS order (excluded wins; NULL/[] semantics).
    select coalesce(sum(oi.quantity * oi.unit_price), 0),
           coalesce(sum(oi.quantity), 0)
      into v_eligible_value, v_eligible_qty
      from public.order_items oi
     where oi.order_id = p_order_id
       and not coalesce(oi.is_bonus, false)
       and (v_rule.products_include is null
            or oi.product_id = any (v_rule.products_include))
       and not (v_rule.products_exclude is not null
                and oi.product_id = any (v_rule.products_exclude));

    if v_rule.min_order_value is not null
       and v_eligible_value < v_rule.min_order_value then continue; end if;
    if v_rule.min_quantity is not null
       and v_eligible_qty < v_rule.min_quantity then continue; end if;
    if v_rule.value_basis = 'PER_PRODUCT' and v_eligible_qty = 0 then continue; end if;

    -- Usage limit: ledger-derived count per (rule, account), net of reversals.
    if v_rule.usage_limit is not null then
      select count(*) into v_used_count
        from public.bonus_ledger el
       where el.account_id = v_client
         and el.rule_id = v_rule.id
         and el.txn_type = 'EARN'
         and el.status = 'POSTED'
         and not exists (
           select 1 from public.bonus_ledger r
            where r.reverses_id = el.id
              and r.txn_type = 'REVERSAL'
              and r.status = 'POSTED');
      if v_used_count >= v_rule.usage_limit then continue; end if;
    end if;

    -- Business value per basis (accounting-neutral numbers only).
    if v_rule.value_basis = 'PER_ORDER' then
      v_earned := coalesce(v_rule.bonus_value, 0);
    elsif v_rule.value_basis = 'PER_UNIT' then
      v_earned := (v_eligible_qty * coalesce(v_rule.bonus_value, 0))::numeric(12,2);
    else
      -- PER_PRODUCT: per-product values map; products without a value earn nothing.
      select coalesce(sum(
               oi.quantity * coalesce(((v_rule.product_values ->> oi.product_id::text))::numeric, 0)
             ), 0)::numeric(12,2)
        into v_earned
        from public.order_items oi
       where oi.order_id = p_order_id
         and not coalesce(oi.is_bonus, false)
         and (v_rule.products_include is null
              or oi.product_id = any (v_rule.products_include))
         and not (v_rule.products_exclude is not null
                  and oi.product_id = any (v_rule.products_exclude));
    end if;

    -- MONETARY percent alternative (xor enforced at rule validation).
    if v_rule.rule_type = 'MONETARY' and v_rule.bonus_percent is not null then
      v_earned := (v_eligible_value * v_rule.bonus_percent / 100)::numeric(12,2);
    end if;

    if v_rule.max_bonus is not null and v_earned > v_rule.max_bonus then
      v_earned := v_rule.max_bonus;
    end if;
    if v_earned <= 0 then
      if not v_rule.is_stackable then v_stop := true; end if;
      continue;
    end if;

    -- Deterministic idempotency: one earn per (order, rule).
    v_key := 'SALES_EARN:' || p_order_id::text || ':' || v_rule.id::text;

    -- Per-rule sub-transaction: a transient failure here becomes a
    -- snapshot pending row (replayable, exact same key/amount) instead
    -- of aborting the whole delivery or losing the entitlement.
    -- Config/fatal errors propagate loudly by design (never pending).
    -- Per-rule sub-transaction with EXPLICIT error classification
    -- (no catch-all): only retry-safe transient states become pending.
    -- Anything else (config/integrity/programming) propagates loudly so
    -- the delivery fails visibly instead of hiding a real defect.
    begin
      insert into public.bonus_ledger
        (account_id, txn_type, amount, status, order_id, rule_id,
         actor, reference, notes, idempotency_key)
      values (v_client, 'EARN', v_earned, 'POSTED', p_order_id, v_rule.id,
              v_client, v_key, 'sales earn at delivery', v_key)
      on conflict (idempotency_key) do nothing
      returning id into v_ledger_id;

      -- Count and audit only actual inserts; skipped duplicates are silent
      -- (the idempotency key already proves the earn exists).
      if found then
        v_count := v_count + 1;
        insert into public.bonus_audit_trail
          (entity, entity_id, action, actor, old_value, new_value, reference)
        values ('bonus_ledger', v_ledger_id, 'SALES_EARN', v_client,
                null, jsonb_build_object('order', p_order_id, 'rule', v_rule.id,
                                         'amount', v_earned), v_key);
      end if;
    exception
      when sqlstate '40001' or sqlstate '40P01' or sqlstate '55P03' then
        -- Transient and retry-safe only (serialization / deadlock /
        -- lock timeout): snapshot everything needed to replay this exact
        -- earn later without re-reading rules that may have changed.
        select coalesce(jsonb_agg(jsonb_build_object(
                 'product_id', oi.product_id,
                 'quantity', oi.quantity,
                 'unit_price', oi.unit_price)), '[]'::jsonb)
          into v_prod_snap
          from public.order_items oi
         where oi.order_id = p_order_id
           and not coalesce(oi.is_bonus, false)
           and (v_rule.products_include is null
                or oi.product_id = any (v_rule.products_include))
           and not (v_rule.products_exclude is not null
                    and oi.product_id = any (v_rule.products_exclude));

        insert into public.bonus_pending_entitlements
          (order_id, account_id, rule_id, value_basis, computed_value,
           product_snapshot, rule_snapshot, idempotency_key,
           status, error_reason)
        values (p_order_id, v_client, v_rule.id, v_rule.value_basis, v_earned,
                v_prod_snap, to_jsonb(v_rule), v_key, 'PENDING', SQLERRM)
        on conflict (idempotency_key) do nothing;

        insert into public.bonus_audit_trail
          (entity, entity_id, action, actor, old_value, new_value, reason)
        values ('bonus_pending_entitlement', p_order_id, 'PENDING_CREATED', v_client,
                null, jsonb_build_object('order', p_order_id, 'rule', v_rule.id,
                                         'amount', v_earned), SQLERRM);
      when others then
        -- Config/integrity/programming/fatal: never converted to pending.
        raise;
    end;

    if not v_rule.is_stackable then v_stop := true; end if;
  end loop;

  return v_count;
end $$;

-- ─────────────────────────────────────────
-- 6. Delivered trigger: covers Driver RPC and Manager direct UPDATE.
--    Containable failures become pending entitlements (same txn);
--    invalid config is a loud error + audit; fatal errors roll back
--    everything including the status change (safe retry via keys).
-- ─────────────────────────────────────────
create or replace function public.bonus_on_order_delivered()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client uuid := NEW.client_id;
  v_acct_status text;
begin
  if OLD.status = 'delivered' or NEW.status <> 'delivered' then
    return NEW;
  end if;

  -- Suspended accounts: preserve entitlement, never silently drop it.
  -- These hold rows carry NO rule snapshot (no rule was evaluated yet);
  -- the processor re-runs evaluation for them when the account is active.
  -- Documented semantics: suspension-hold ≠ evaluated-pending.
  select status into v_acct_status from public.bonus_accounts
   where user_id = v_client;
  if found and v_acct_status = 'suspended' then
    insert into public.bonus_pending_entitlements
      (order_id, account_id, status, error_reason, idempotency_key)
    values (NEW.id, v_client, 'PENDING', 'ACCOUNT_SUSPENDED',
            'SUSPENDED-HOLD:' || NEW.id::text)
    on conflict (idempotency_key) do nothing;

    insert into public.bonus_audit_trail
      (entity, entity_id, action, actor, old_value, new_value, reason)
    values ('bonus_pending_entitlement', NEW.id, 'SUSPENDED_HOLD', v_client,
            null, jsonb_build_object('order', NEW.id), 'account suspended');
    return NEW;
  end if;

  -- No exception classification here by design: the evaluator converts
  -- containable per-rule failures into pending rows itself, while config
  -- errors (BONUS_CONFIG_ERROR) and fatal errors propagate loudly and
  -- roll back the status change for a safe, idempotent retry.
  perform public.bonus_evaluate_order_earn(NEW.id);

  return NEW;
end $$;

drop trigger if exists trg_bonus_on_order_delivered on public.orders;
create trigger trg_bonus_on_order_delivered
  after update of status on public.orders
  for each row
  when (OLD.status is distinct from 'delivered' and NEW.status = 'delivered')
  execute function public.bonus_on_order_delivered();

-- ─────────────────────────────────────────
-- 7. Pending processor: exactly one row per call (no batch).
--    Snapshot authority: replay uses the STORED computed value, rule
--    snapshot and idempotency key — never the current live rule row.
-- ─────────────────────────────────────────
create or replace function public.bonus_process_pending(p_pending_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.bonus_pending_entitlements%rowtype;
  v_ledger_id uuid;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can process pending entitlements';
  end if;

  select * into v_row from public.bonus_pending_entitlements
   where id = p_pending_id for update;
  if not found then raise exception 'Pending entitlement % not found', p_pending_id; end if;
  if v_row.status <> 'PENDING' then
    raise exception 'Only PENDING rows can be processed (current: %)', v_row.status;
  end if;

  -- Suspension holds carry no rule snapshot: re-run the evaluator for the
  -- whole order (fresh rules), then close the hold itself as processed.
  -- Only retry-safe transient states stay pending here; anything else
  -- propagates loudly (a stuck hold is visible, never silently dropped).
  if v_row.rule_id is null then
    begin
      perform public.bonus_evaluate_order_earn(v_row.order_id);
    exception
      when sqlstate '40001' or sqlstate '40P01' or sqlstate '55P03' then
        update public.bonus_pending_entitlements
           set attempts = attempts + 1, error_reason = SQLERRM,
               updated_at = now()
         where id = p_pending_id;
        return null;
      when others then
        raise;
    end;

    update public.bonus_pending_entitlements
       set status = 'PROCESSED', processed_at = now(),
           attempts = attempts + 1, updated_at = now()
     where id = p_pending_id;

    insert into public.bonus_audit_trail
      (entity, entity_id, action, actor, old_value, new_value)
    values ('bonus_pending_entitlement', p_pending_id, 'HOLD_PROCESSED', v_actor,
            jsonb_build_object('status', 'PENDING'),
            jsonb_build_object('status', 'PROCESSED'));
    return null;
  end if;

  -- Evaluated pending: replay EXACTLY the snapshotted earn. Transient
  -- contention stays pending (visible, retryable); anything else is loud.
  begin
    insert into public.bonus_ledger
      (account_id, txn_type, amount, status, order_id, rule_id,
       actor, reference, notes, idempotency_key)
    values (v_row.account_id, 'EARN', v_row.computed_value, 'POSTED',
            v_row.order_id, v_row.rule_id, v_actor,
            v_row.idempotency_key, 'pending replay at processing',
            v_row.idempotency_key)
    on conflict (idempotency_key) do nothing
    returning id into v_ledger_id;

    if not found then
      select id into v_ledger_id from public.bonus_ledger
       where idempotency_key = v_row.idempotency_key;
    end if;
  exception
    when sqlstate '40001' or sqlstate '40P01' or sqlstate '55P03' then
      update public.bonus_pending_entitlements
         set attempts = attempts + 1, error_reason = SQLERRM,
             updated_at = now()
       where id = p_pending_id;
      -- Explicit contract: null return + PENDING status = not processed yet.
      return null;
    when others then
      raise;
  end;

  update public.bonus_pending_entitlements
     set status = 'PROCESSED', processed_at = now(),
         ledger_id = v_ledger_id, attempts = attempts + 1,
         updated_at = now()
   where id = p_pending_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value)
  values ('bonus_pending_entitlement', p_pending_id, 'PROCESSED', v_actor,
          jsonb_build_object('status', 'PENDING'),
          jsonb_build_object('status', 'PROCESSED'));

  return v_ledger_id;
end $$;

-- Grants: internal helpers are revoked from direct calls; only the
-- director-gated processor (plus its internal role check) stays callable.
-- (Validator/evaluator/trigger run as SECURITY DEFINER callees only.)
revoke all on function public.bonus_check_rule_v2(public.bonus_rules_v2) from public;
revoke all on function public.bonus_validate_rule_v2(public.bonus_rules_v2) from public;
revoke all on function public.bonus_evaluate_order_earn(uuid) from public;
revoke all on function public.bonus_on_order_delivered() from public;
revoke all on function public.bonus_rules_v2_validate_trigger() from public;
grant execute on function public.bonus_process_pending(uuid) to authenticated;
