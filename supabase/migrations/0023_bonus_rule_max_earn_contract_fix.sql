-- =============================================================
-- Migration 0023 — Bonus rule contract fix: max_bonus -> max_earn
-- MedLink Yemen — shared Supabase database (main repository)
--
-- WHY (evidence: docs/opencode/PHASE-46-BONUS-CURRENT-STATE-AUDIT.md section E.4,
--           docs/opencode/PHASE-47-BONUS-RULE-CONTRACT-FIX-DESIGN.md sections A and E)
--   Migration 0018 declares the column
--     public.bonus_rules_v2.max_earn            (0018_bonus_financial_system.sql:133)
--   Migration 0019 references a composite field named max_bonus
--     (0019_bonus_earn_engine.sql:171, 172, 377, 378)
--   which exists in no table, view or type. Because p_rule / v_rule are
--   PL/pgSQL variables of composite type public.bonus_rules_v2, field access
--   is resolved at execution time, so every affected statement raises:
--     record "bonus_rules_v2" has no field "max_bonus"      (SQLSTATE 42703)
--
--   Live consequences (catalog-verified read-only in PHASE-46 / PHASE-47):
--     * any INSERT or UPDATE on bonus_rules_v2 fails, through the BEFORE
--       trigger trg_bonus_rules_v2_validate -> bonus_rules_v2_validate_trigger
--       -> bonus_validate_rule_v2 -> bonus_check_rule_v2 (line 171).
--       This covers rule creation, rule editing and status-only toggles.
--     * orders.status -> 'delivered' fails and the status flip rolls back,
--       through the AFTER trigger trg_bonus_on_order_delivered ->
--       bonus_on_order_delivered -> bonus_evaluate_order_earn.
--
-- SCOPE (minimal, contract-restoring only)
--   This file replaces exactly two function bodies and changes nothing else:
--     (A) public.bonus_check_rule_v2(public.bonus_rules_v2)  -- 0019:88-180
--     (B) public.bonus_evaluate_order_earn(uuid)             -- 0019:220-455
--   The only edits are the six wrong field references, which become the real
--   column name (the validator's related message text is updated to match).
--   Every other line is copied verbatim from 0019_bonus_earn_engine.sql.
--
--   Semantics are unchanged: the cap keeps its meaning — if the rule defines a
--   cap and the computed earn exceeds it, the earned amount equals the cap;
--   a NULL cap means unlimited. No change to stacking, priority ordering,
--   usage limits, eligibility, minimums, value_basis, the idempotency keys,
--   the pending snapshots, the exception classification, account modes, RLS,
--   triggers, indexes or grants.
--
-- NOT IN THIS FILE (deliberately)
--   * no ALTER TABLE; no column added, renamed, dropped or typed;
--   * no CREATE TABLE / TRIGGER / POLICY / INDEX / CHECK / DEFAULT;
--   * no INSERT / UPDATE / DELETE of data;
--   * no GRANT and no REVOKE. CREATE OR REPLACE FUNCTION preserves the
--     existing ACL, and 0019 already contains the revoke/grant block for these
--     functions, so restating privileges would change nothing and grant
--     nothing. The live ACL was inspected in PHASE-47 section E.3.
--   * 0019 is intentionally left untouched: it is already applied, and editing
--     an applied migration would desynchronise the file from the database.
--   * no copy of this file in the Medlik-Waap submodule: that chain contains no
--     bonus_rules_v2 DDL, so a copy would create new divergence.
--
-- APPLICATION: creating this file does NOT apply it and does NOT change the
--   live database. Apply manually (Dashboard -> SQL Editor) only after an
--   isolated environment has executed the tests in PHASE-47 section G, and a
--   restore point has been confirmed. Do NOT run "supabase db push": the CLI
--   in this repository is linked to the production project.
-- =============================================================
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
  if p_rule.max_earn is not null and p_rule.max_earn <= 0 then
    return format('Rule %s: max_earn must be positive', p_rule.id);
  end if;
  if p_rule.start_date is not null and p_rule.end_date is not null
     and p_rule.start_date > p_rule.end_date then
    return format('Rule %s: start_date is after end_date', p_rule.id);
  end if;

  return null;
end $$;

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

    if v_rule.max_earn is not null and v_earned > v_rule.max_earn then
      v_earned := v_rule.max_earn;
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
