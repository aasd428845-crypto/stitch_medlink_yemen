-- ─────────────────────────────────────────────────────────────────────────
-- 0020_order_discount.sql — PHASE 17: Order Discount (LOCAL ONLY, NOT APPLIED)
--
-- Implements the locked product decisions (PHASE 16.7) inside the 16.5
-- configuration contract, reusing 0018/0019 primitives without touching them:
--
--   D1 REQUIRE_POSITIVE_REMAINING  -> discount.allow_zero_order = false
--   D2 ALL_ELIGIBLE_LOTS           -> discount.funding_scope (narrow-only
--                                     rule gate via bonus_rules_v2.allow_discount)
--   D3 AUTOMATIC_REVERSAL          -> discount.cancellation_mode (+ snapshot
--                                     governs later cancellation)
--   D4 TENANT FINANCIAL CONFIG     -> accounting-neutral: NO GL objects,
--                                     no accounting value stored, identifier
--                                     reserved as null in the snapshot
--   D5 NO_ADDITIONAL_POLICY_CAP    -> discount.max_amount/max_percent null
--   D6 NO_MINIMUM                  -> discount.min_amount null
--   D8 SNAPSHOT_AT_DISCOUNT_TIME   -> JSON snapshot in ledger.notes
--
-- Design notes (all verified against the local repository):
-- * Discount applies AFTER create_order_with_items, BEFORE branch_allocate_order.
--   Neither function — nor 0017/0018/0019, order_items prices, Free-Y columns,
--   createInvoice, RLS, or grants — is modified by this file.
-- * Ledger txn_type ORDER_DISCOUNT already exists in the 0018 CHECK
--   (0018:58); no enum is added.
-- * bonus_allocate_spend (0018:475) hard-gates txn types to
--   REDEEM_PRODUCT/CASH_WITHDRAWAL, so 0020 performs the lot walk inline with
--   IDENTICAL oldest-first/remainder/shortfall semantics via the existing
--   bonus_credit_remaining() helper. 0018 is NOT modified.
-- * reverse_bonus_txn (0018:1332) is director-only; 0020's cancel path writes
--   its own compensating REVERSAL with the same guards (POSTED-only,
--   one-effective-reversal, full debit compensation). 0018 is NOT modified.
-- * Idempotency keys: DISCOUNT:{order_id} / REVERSAL:DISCOUNT:{order_id},
--   enforced by the existing UNIQUE(bonus_ledger.idempotency_key).
-- * CURRENT GAP (16.7): no tenant architecture exists; settings are global
--   keys today. Nothing tenant-specific is fabricated here.
--
-- SAFETY: local file only. Do NOT supabase db push / migration up / db reset.
-- ─────────────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────
-- 1. Product-default policy seeds (data only; never overwrite configured values).
-- ─────────────────────────────────────────
insert into public.bonus_settings (key, value) values
  ('discount.allow_zero_order', 'false'::jsonb),
  ('discount.funding_scope', '"ALL_ELIGIBLE_LOTS"'::jsonb),
  ('discount.cancellation_mode', '"AUTOMATIC_REVERSAL"'::jsonb),
  ('discount.max_amount', 'null'::jsonb),
  ('discount.max_percent', 'null'::jsonb),
  ('discount.min_amount', 'null'::jsonb)
on conflict (key) do nothing;

-- ─────────────────────────────────────────
-- 2. apply_order_discount — client applies bonus to their own pending order.
--    Name and signature per PHASE 16.4 blueprint §7.
-- ─────────────────────────────────────────
create or replace function public.apply_order_discount(
  p_order_id uuid,
  p_amount numeric,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_role text := public.current_user_role();
  v_order public.orders%rowtype;
  v_key text := coalesce(nullif(btrim(p_idempotency_key), ''),
                         'DISCOUNT:' || p_order_id::text);
  v_existing uuid;
  v_total numeric(12,2);
  v_requested numeric(12,2);
  v_available numeric;
  v_reserved numeric;
  v_allow_zero boolean := false;
  v_scope text := 'ALL_ELIGIBLE_LOTS';
  v_cancel_mode text := 'AUTOMATIC_REVERSAL';
  v_max_amount numeric(12,2);
  v_max_percent numeric(5,2);
  v_min_amount numeric(12,2);
  v_effective numeric(12,2);
  v_tmp jsonb;
  v_debit_id uuid;
  v_lot uuid;
  v_left numeric(12,2);
  v_rem numeric;
  v_take numeric(12,2);
  v_flipped int;
  v_snapshot text;
begin
  if v_caller is null then raise exception 'Authentication required'; end if;
  if v_role <> 'client' then
    raise exception 'Only clients can apply order discounts';
  end if;
  if p_order_id is null then raise exception 'Order id is required'; end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Discount amount must be positive';
  end if;
  v_requested := p_amount::numeric(12,2);

  -- Idempotent replay: same logical request returns the existing result
  -- (pattern matches request_redemption / reverse_bonus_txn).
  select id into v_existing from public.bonus_ledger
   where idempotency_key = v_key;
  if found then return v_existing; end if;

  -- Lock the order and enforce ownership + discountable state.
  -- 'pending' is the only pre-allocation state (0017 inserts pending;
  -- branch_allocate_order requires pending before moving to assigned).
  select * into v_order from public.orders
   where id = p_order_id for update;
  if not found then raise exception 'Order % not found', p_order_id; end if;
  if v_order.client_id <> v_caller then
    raise exception 'Not your order';
  end if;
  if v_order.status <> 'pending' then
    raise exception 'Only pending orders can be discounted (current: %)',
      v_order.status;
  end if;
  v_total := coalesce(v_order.total_amount, 0)::numeric(12,2);
  if v_total <= 0 then
    raise exception 'Order total must be positive to apply a discount';
  end if;

  -- One discount per order: anything left here after the replay check means
  -- cancel-before-reapply (no in-place amount edits, no second discounts).
  if exists (select 1 from public.bonus_ledger
              where order_id = p_order_id
                and txn_type = 'ORDER_DISCOUNT'
                and status = 'POSTED') then
    raise exception 'Order % already has an applied discount; cancel it before reapplying',
      p_order_id;
  end if;

  -- Policy reads (server-side; absent keys fall back to locked product defaults).
  select value into v_tmp from public.bonus_settings
   where key = 'discount.allow_zero_order';
  if found and jsonb_typeof(v_tmp) = 'boolean' then
    v_allow_zero := (v_tmp #>> '{}')::boolean;
  end if;

  select value into v_tmp from public.bonus_settings
   where key = 'discount.funding_scope';
  if found then
    if jsonb_typeof(v_tmp) <> 'string' then
      raise exception 'Invalid discount.funding_scope setting';
    end if;
    v_scope := v_tmp #>> '{}';
    if v_scope not in ('ALL_ELIGIBLE_LOTS', 'MONETARY_ONLY') then
      raise exception 'Invalid discount.funding_scope setting';
    end if;
  end if;

  select value into v_tmp from public.bonus_settings
   where key = 'discount.cancellation_mode';
  if found then
    if jsonb_typeof(v_tmp) <> 'string' then
      raise exception 'Invalid discount.cancellation_mode setting';
    end if;
    v_cancel_mode := v_tmp #>> '{}';
    if v_cancel_mode not in ('AUTOMATIC_REVERSAL', 'MANUAL_REVIEW') then
      raise exception 'Invalid discount.cancellation_mode setting';
    end if;
  end if;

  select value into v_tmp from public.bonus_settings
   where key = 'discount.max_amount';
  if found and v_tmp <> 'null'::jsonb then
    if jsonb_typeof(v_tmp) <> 'number' then
      raise exception 'Invalid discount.max_amount setting';
    end if;
    v_max_amount := (v_tmp #>> '{}')::numeric(12,2);
    if v_max_amount < 0 then
      raise exception 'Invalid discount.max_amount setting';
    end if;
  end if;

  select value into v_tmp from public.bonus_settings
   where key = 'discount.max_percent';
  if found and v_tmp <> 'null'::jsonb then
    if jsonb_typeof(v_tmp) <> 'number' then
      raise exception 'Invalid discount.max_percent setting';
    end if;
    v_max_percent := (v_tmp #>> '{}')::numeric(5,2);
    if v_max_percent < 0 or v_max_percent > 100 then
      raise exception 'Invalid discount.max_percent setting';
    end if;
  end if;

  select value into v_tmp from public.bonus_settings
   where key = 'discount.min_amount';
  if found and v_tmp <> 'null'::jsonb then
    if jsonb_typeof(v_tmp) <> 'number' then
      raise exception 'Invalid discount.min_amount setting';
    end if;
    v_min_amount := (v_tmp #>> '{}')::numeric(12,2);
    if v_min_amount < 0 then
      raise exception 'Invalid discount.min_amount setting';
    end if;
  end if;

  -- Available funds, server-side (also takes the account row lock, which
  -- serializes concurrent discount/redemption/withdrawal attempts).
  select * into v_available, v_reserved
    from public.bonus_account_funds(v_caller);

  -- Effective discount: Order constraints > Rule/Global policy > defaults.
  v_effective := least(v_requested, v_total, v_available::numeric(12,2));
  if v_max_amount is not null then
    v_effective := least(v_effective, v_max_amount);
  end if;
  if v_max_percent is not null then
    v_effective := least(v_effective,
      (v_total * v_max_percent / 100)::numeric(12,2));
  end if;
  if v_effective <= 0 then
    raise exception 'Insufficient available bonus (need %, have %)',
      v_requested, v_available;
  end if;
  if not v_allow_zero and v_effective >= v_total then
    raise exception 'Discount would cover the full order total (zero-remaining orders are disabled)';
  end if;
  if v_min_amount is not null and v_effective < v_min_amount then
    raise exception 'Discount is below the configured minimum';
  end if;

  -- Policy snapshot (D8): this transaction is forever governed by the values
  -- below, never by later global edits. Accounting stays null (D4 undecided).
  v_snapshot := jsonb_build_object(
    'version', 'discount_policy_v1',
    'allow_zero_order', v_allow_zero,
    'funding_scope', v_scope,
    'cancellation_mode', v_cancel_mode,
    'max_amount', v_max_amount,
    'max_percent', v_max_percent,
    'min_amount', v_min_amount,
    'accounting_treatment', null,
    'order_total', v_total,
    'requested', v_requested,
    'available', v_available,
    'applied', v_effective
  )::text;

  -- Ledger debit first (PENDING reservation, mirrors request_redemption).
  insert into public.bonus_ledger
    (account_id, txn_type, amount, status, order_id, rule_id,
     actor, reference, notes, idempotency_key)
  values (v_caller, 'ORDER_DISCOUNT', -v_effective, 'PENDING',
          p_order_id, null, v_caller, v_key, v_snapshot, v_key)
  returning id into v_debit_id;

  -- Lot attribution: oldest-first with remainder caps and shortfall raise
  -- (same semantics as bonus_allocate_spend), PLUS the narrow-only funding
  -- filter — lots from rules with allow_discount=false are excluded, and
  -- under MONETARY_ONLY only MONETARY-rule lots qualify. Rule-less credits
  -- (opening balance / legacy migration) carry no restricting rule and stay
  -- eligible under ALL_ELIGIBLE_LOTS.
  v_left := v_effective;
  for v_lot in
    select l.id
      from public.bonus_ledger l
      left join public.bonus_rules_v2 r on r.id = l.rule_id
     where l.account_id = v_caller
       and l.status = 'POSTED'
       and l.amount > 0
       and (l.rule_id is null or r.allow_discount is true)
       and (v_scope = 'ALL_ELIGIBLE_LOTS'
            or (l.rule_id is not null and r.rule_type = 'MONETARY'))
     order by l.created_at, l.id
  loop
    exit when v_left <= 0;
    v_rem := public.bonus_credit_remaining(v_lot);
    if v_rem <= 0 then continue; end if;
    v_take := least(v_rem, v_left);
    insert into public.bonus_earn_allocations
      (account_id, credit_ledger_id, debit_ledger_id, amount)
    values (v_caller, v_lot, v_debit_id, v_take);
    v_left := v_left - v_take;
  end loop;

  if v_left > 0 then
    raise exception 'Attribution shortfall: % unattributed', v_left;
  end if;

  -- Commit the reservation (same PENDING->POSTED flip as fulfill_redemption;
  -- the trg_bonus_ledger_immutable trigger permits this: old row is PENDING).
  update public.bonus_ledger
     set status = 'POSTED'
   where id = v_debit_id and status = 'PENDING';
  get diagnostics v_flipped = row_count;
  if v_flipped <> 1 then
    raise exception 'Discount reservation % was not committed; aborting', v_debit_id;
  end if;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value)
  values ('bonus_ledger', v_debit_id, 'DISCOUNT_APPLY', v_caller,
          jsonb_build_object('requested', v_requested, 'order_total', v_total,
                             'available', v_available, 'order_id', p_order_id),
          jsonb_build_object('applied', v_effective, 'ledger_id', v_debit_id));

  return v_debit_id;
end $$;

-- ─────────────────────────────────────────
-- 3. cancel_order_discount — compensating reversal governed by the SNAPSHOT
--    captured at discount time (never by the current global policy).
-- ─────────────────────────────────────────
create or replace function public.cancel_order_discount(
  p_order_id uuid,
  p_reason text default 'Order cancelled',
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller uuid := auth.uid();
  v_role text := public.current_user_role();
  v_order public.orders%rowtype;
  v_debit public.bonus_ledger%rowtype;
  v_key text := coalesce(nullif(btrim(p_idempotency_key), ''),
                         'REVERSAL:DISCOUNT:' || p_order_id::text);
  v_existing uuid;
  v_snapshot jsonb;
  v_mode text;
  v_reversal_id uuid;
begin
  if v_caller is null then raise exception 'Authentication required'; end if;
  if v_role not in ('client', 'company_director') then
    raise exception 'Not permitted to cancel order discounts';
  end if;
  if p_order_id is null then raise exception 'Order id is required'; end if;
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'Cancellation requires a reason';
  end if;

  select id into v_existing from public.bonus_ledger
   where idempotency_key = v_key;
  if found then return v_existing; end if;

  select * into v_order from public.orders
   where id = p_order_id for update;
  if not found then raise exception 'Order % not found', p_order_id; end if;
  if v_role = 'client' and v_order.client_id <> v_caller then
    raise exception 'Not your order';
  end if;
  if v_order.status = 'delivered' then
    raise exception 'Discounts on delivered orders cannot be reversed here';
  end if;

  select * into v_debit from public.bonus_ledger
   where order_id = p_order_id
     and txn_type = 'ORDER_DISCOUNT'
     and status = 'POSTED'
   order by created_at desc
   limit 1
   for update;
  if not found then
    raise exception 'Order % has no applied discount to cancel', p_order_id;
  end if;

  -- One effective reversal per original (mirrors reverse_bonus_txn).
  if exists (select 1 from public.bonus_ledger
              where reverses_id = v_debit.id
                and txn_type = 'REVERSAL'
                and status = 'POSTED') then
    raise exception 'Discount % already has an effective reversal', v_debit.id;
  end if;

  -- Snapshot governs: a MANUAL-era discount stays manual even if the current
  -- global mode is AUTOMATIC, and vice versa.
  begin
    v_snapshot := v_debit.notes::jsonb;
  exception when others then
    raise exception 'Discount % has no readable policy snapshot; manual settlement required',
      v_debit.id;
  end;
  v_mode := v_snapshot ->> 'cancellation_mode';
  if v_mode is distinct from 'AUTOMATIC_REVERSAL' then
    raise exception 'Discount % requires manual settlement (snapshot mode: %)',
      v_debit.id, coalesce(v_mode, 'missing');
  end if;

  -- Compensating credit in full (debit reversal: undo the consumption).
  -- The original POSTED row is never touched.
  insert into public.bonus_ledger
    (account_id, txn_type, amount, status, order_id, rule_id,
     reverses_id, actor, reference, notes, idempotency_key)
  values (v_debit.account_id, 'REVERSAL', -v_debit.amount, 'POSTED',
          v_debit.order_id, v_debit.rule_id, v_debit.id, v_caller, v_key,
          'Reversal of ' || v_debit.id::text || ': ' || btrim(p_reason), v_key)
  returning id into v_reversal_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value, reason)
  values ('bonus_ledger', v_reversal_id, 'REVERSAL', v_caller,
          jsonb_build_object('reversed', v_debit.id, 'kind', 'ORDER_DISCOUNT'),
          jsonb_build_object('amount', -v_debit.amount), btrim(p_reason));

  return v_reversal_id;
end $$;

-- ─────────────────────────────────────────
-- 4. Grants (existing convention: EXECUTE to authenticated; in-function
--    role/ownership checks carry the authorization, RLS untouched).
-- ─────────────────────────────────────────
grant execute on function public.apply_order_discount(uuid, numeric, text) to authenticated;
grant execute on function public.cancel_order_discount(uuid, text, text) to authenticated;
