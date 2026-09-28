-- ─────────────────────────────────────────────────────────────────────────
-- 0021_order_cancellation_with_discount.sql — PHASE 24 (LOCAL ONLY, NOT APPLIED)
--
-- Implements Phase 23 spec under 22.3 product locks:
--   H1 B-NARROW (owner-client cancel of own PENDING orders only),
--   H2 A (manual invoices stay independent; no linkage here),
--   H3 A (fail-closed + escalation; abort pre-write, never partial money).
--
-- Contents: (F1) NEW cancel_order_with_discount — atomic cancel + conditional
-- compensating reversal; (F2) OR REPLACE branch_allocate_order — identical
-- signature/behavior except the invoice total nets POSTED Order Discounts
-- (coalesce-neutral for orders without discounts); (I1) F6 lookup index.
-- No tables, columns, triggers, RLS, or role changes. 0017–0020 untouched.
-- POSTED ledger rows are never UPDATED or DELETED; corrections are REVERSAL
-- rows linked by reverses_id (0018 pattern). No bonus_reversals table.
-- Future invoice-order linkage is out of scope for 0021.
--
-- SAFETY: local file only. Do NOT supabase db push / migration up / db reset.
-- ─────────────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────
-- I1. Discount-detection lookup index (F6). Serves the cancel RPC's
-- detection query and the existing 0020 order-scoped lookups. Partial:
-- most ledger rows carry no order link. No existing index covers order_id.
-- ─────────────────────────────────────────
create index if not exists bonus_ledger_order_idx
  on public.bonus_ledger (order_id)
  where order_id is not null;

-- ─────────────────────────────────────────
-- F1. cancel_order_with_discount — atomic order cancellation with
-- conditional compensating reversal of the order's Order Discount.
-- ─────────────────────────────────────────
create or replace function public.cancel_order_with_discount(
  p_order_id uuid,
  p_reason text,
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
  v_branch uuid := public.current_user_branch_id();
  v_order public.orders%rowtype;
  v_key text := coalesce(nullif(btrim(p_idempotency_key), ''),
                         'CANCEL:' || p_order_id::text);
  v_revkey text := 'REVERSAL:DISCOUNT:' || p_order_id::text;
  v_debit public.bonus_ledger%rowtype;
  v_has_discount boolean := false;
  v_snapshot jsonb;
  v_mode text;
  v_reversal_id uuid;
  v_flipped int;
begin
  if v_caller is null then raise exception 'Authentication required'; end if;
  if p_order_id is null then raise exception 'Order id is required'; end if;
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'Cancellation requires a reason';
  end if;
  if v_role not in ('client', 'branch_manager', 'company_director') then
    raise exception 'Not permitted to cancel orders';
  end if;

  select * into v_order from public.orders
   where id = p_order_id for update;
  if not found then raise exception 'Order % not found', p_order_id; end if;

  -- H1 authorization, server-side only (auth.uid; no client-supplied identity).
  if v_role = 'client' then
    if v_order.client_id <> v_caller then
      raise exception 'Not your order';
    end if;
  elsif v_role = 'branch_manager' then
    if v_order.branch_id is null
       or v_order.branch_id is distinct from v_branch then
      raise exception 'Order % is not assigned to your branch', p_order_id;
    end if;
  end if;
  -- company_director: all orders (delivered still excluded below).

  if v_order.status = 'delivered' then
    raise exception 'Delivered orders cannot be cancelled here';
  end if;

  -- H1 state gate: a client may cancel only a pending order (fixed safety
  -- condition). Already-cancelled orders skip the gate (replay/converge).
  -- Branch/director may cancel any non-final, non-delivered order.
  if v_order.status <> 'cancelled'
     and v_role = 'client'
     and v_order.status <> 'pending' then
    raise exception 'Only pending orders can be cancelled by the client (current: %)',
      v_order.status;
  end if;

  -- Detect reversible discount: latest POSTED ORDER_DISCOUNT for the order.
  -- Source of truth is the ledger itself; no duplicate financial state.
  select * into v_debit from public.bonus_ledger
   where order_id = p_order_id
     and txn_type = 'ORDER_DISCOUNT'
     and status = 'POSTED'
   order by created_at desc
   limit 1
   for update;
  v_has_discount := found;

  if v_has_discount then
    -- One effective reversal per original (0020 guard, duplicated here
    -- because 0020 is immutable and its role gate rejects branch_manager;
    -- the partial unique index bonus_ledger_reverses_uniq backstops races).
    select id into v_reversal_id from public.bonus_ledger
     where reverses_id = v_debit.id
       and txn_type = 'REVERSAL'
       and status = 'POSTED';
    if not found then
      -- H3 fail-closed: the discount-time snapshot must allow automatic
      -- reversal, else abort BEFORE any write (escalation, not settlement).
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

      -- Compensating credit in full. The POSTED original is never touched.
      insert into public.bonus_ledger
        (account_id, txn_type, amount, status, order_id, rule_id,
         reverses_id, actor, reference, notes, idempotency_key)
      values (v_debit.account_id, 'REVERSAL', -v_debit.amount, 'POSTED',
              v_debit.order_id, v_debit.rule_id, v_debit.id, v_caller, v_revkey,
              'Reversal of ' || v_debit.id::text || ' on cancellation: ' || btrim(p_reason),
              v_revkey)
      returning id into v_reversal_id;

      insert into public.bonus_audit_trail
        (entity, entity_id, action, actor, old_value, new_value, reason)
      values ('bonus_ledger', v_reversal_id, 'REVERSAL', v_caller,
              jsonb_build_object('reversed', v_debit.id, 'kind', 'ORDER_DISCOUNT'),
              jsonb_build_object('amount', -v_debit.amount), btrim(p_reason));
    end if;
  end if;

  -- Status transition (skipped when already cancelled: replay/converge).
  if v_order.status <> 'cancelled' then
    update public.orders
       set status = 'cancelled'
     where id = p_order_id;
    get diagnostics v_flipped = row_count;
    if v_flipped <> 1 then
      raise exception 'Order % status was not updated; aborting', p_order_id;
    end if;

    insert into public.bonus_audit_trail
      (entity, entity_id, action, actor, old_value, new_value, reason, reference)
    values ('order', p_order_id, 'CANCEL', v_caller,
            jsonb_build_object('status', v_order.status),
            jsonb_build_object('status', 'cancelled', 'reversal', v_reversal_id),
            btrim(p_reason), v_key);
  end if;

  return v_reversal_id;
end $$;

grant execute on function public.cancel_order_with_discount(uuid, text, text) to authenticated;

-- ─────────────────────────────────────────
-- F2. branch_allocate_order — OR REPLACE with ONE delimited delta (Phase 23):
-- the invoice total nets POSTED Order Discounts so order-linked invoices
-- reflect the payable. Body is otherwise identical to 0016 (same signature,
-- security, locks, inventory semantics, grant). Orders without discounts
-- produce byte-identical amounts (coalesce-neutral).
-- ─────────────────────────────────────────
create or replace function public.branch_allocate_order(
  p_order_id uuid,
  p_issue_invoice boolean default true,
  p_expected_delivery_date date default null,
  p_allocations jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_branch_id uuid;
  v_client_id uuid;
  v_status text;
  v_total numeric(12,2) := 0;
  v_invoice_id uuid;
  v_alloc record;
  v_inv_qty int;
  v_required_qty int;
  v_paid_qty int;
  v_paid_unit_price numeric(10,2);
  v_allocated_any boolean := false;
  v_discount numeric(12,2) := 0;
begin
  if public.current_user_role() <> 'branch_manager' then
    raise exception 'Only a branch manager can allocate orders';
  end if;

  select branch_id, client_id, status
    into v_branch_id, v_client_id, v_status
    from public.orders
   where id = p_order_id
   for update;

  if not found then
    raise exception 'Order % not found', p_order_id;
  end if;
  if v_branch_id is distinct from public.current_user_branch_id() then
    raise exception 'Order does not belong to your branch';
  end if;
  if v_status <> 'pending' then
    raise exception 'Only pending orders can be allocated (current: %)', v_status;
  end if;

  -- An order is assigned only after every product has its complete physical
  -- demand allocated. This includes free bonus units: Buy 10 + Bonus 1
  -- requires an allocation of 11, not 10.
  for v_alloc in
    select oi.product_id,
           sum(oi.quantity)::int as required_qty,
           coalesce((
             select sum(x.allocated_qty)::int
               from jsonb_to_recordset(coalesce(p_allocations, '[]'::jsonb))
                 as x(product_id uuid, allocated_qty int)
              where x.product_id = oi.product_id
                and x.allocated_qty is not null
                and x.allocated_qty > 0
           ), 0)::int as allocated_qty
      from public.order_items oi
     where oi.order_id = p_order_id
     group by oi.product_id
  loop
    if v_alloc.allocated_qty <> v_alloc.required_qty then
      raise exception
        'Full physical allocation required for product % (need %, received %)',
        v_alloc.product_id, v_alloc.required_qty, v_alloc.allocated_qty;
    end if;
  end loop;

  -- Aggregate client input by product so a repeated JSON entry cannot cause
  -- separate checks/updates for the same physical stock row.
  for v_alloc in
    select product_id, sum(allocated_qty)::int as allocated_qty
      from jsonb_to_recordset(coalesce(p_allocations, '[]'::jsonb))
        as x(product_id uuid, allocated_qty int)
     where product_id is not null and allocated_qty is not null and allocated_qty > 0
     group by product_id
   loop
     v_allocated_any := true;
    -- Both paid and is_bonus order lines are physical demand. The explicit
    -- split remains available in order_items for audit and analytics.
    select
      coalesce(sum(quantity), 0)::int,
      coalesce(sum(quantity) filter (where not is_bonus), 0)::int,
      coalesce(max(unit_price) filter (where not is_bonus), 0)
      into v_required_qty, v_paid_qty, v_paid_unit_price
      from public.order_items
     where order_id = p_order_id and product_id = v_alloc.product_id;

    if v_required_qty = 0 then
      raise exception 'Product % is not part of order %',
        v_alloc.product_id, p_order_id;
    end if;
    if v_alloc.allocated_qty <> v_required_qty then
      raise exception 'Allocated quantity for product % must equal ordered physical quantity %',
        v_alloc.product_id, v_required_qty;
    end if;

    select quantity into v_inv_qty
      from public.inventory
     where branch_id = v_branch_id and product_id = v_alloc.product_id
     for update;

    if v_inv_qty is null or v_inv_qty < v_alloc.allocated_qty then
      raise exception 'Insufficient stock for product % (need %, have %)',
        v_alloc.product_id, v_alloc.allocated_qty, coalesce(v_inv_qty, 0);
    end if;

    -- This is the sole operational-inventory deduction. A Buy 10 + 1 bonus
    -- allocation of 11 subtracts 11 here, never another 1 elsewhere.
    update public.inventory
       set quantity = quantity - v_alloc.allocated_qty,
           updated_at = now()
     where branch_id = v_branch_id and product_id = v_alloc.product_id;

    if p_issue_invoice then
      -- Invoice no more than the paid units, even though the allocation also
      -- includes free physical bonus units.
      v_total := v_total + least(v_alloc.allocated_qty, v_paid_qty) *
        coalesce(v_paid_unit_price, 0);
    end if;
  end loop;

   if not v_allocated_any then
     raise exception 'At least one physical allocation is required';
   end if;

  -- 0021 DELTA START (sole intentional change vs 0016): net the order's
  -- effective POSTED discount (debits minus their linked REVERSAL credits,
  -- so removed discounts net to zero) off the invoice total. H2-A: manual
  -- invoices untouched; no order linkage invented.
  select coalesce(sum(-l.amount), 0)::numeric(12,2)
       - coalesce((
           select sum(r.amount)
             from public.bonus_ledger r
            where r.txn_type = 'REVERSAL'
              and r.status = 'POSTED'
              and r.reverses_id in (
                select d.id from public.bonus_ledger d
                 where d.order_id = p_order_id
                   and d.txn_type = 'ORDER_DISCOUNT'
              )
         ), 0)::numeric(12,2)
    into v_discount
    from public.bonus_ledger l
   where l.order_id = p_order_id
     and l.txn_type = 'ORDER_DISCOUNT'
     and l.status = 'POSTED';
  if v_discount < 0 then
    raise exception 'Negative net discount for order %', p_order_id;
  end if;
  if v_discount > v_total then
    raise exception 'Net discount % exceeds invoice total % for order %',
      v_discount, v_total, p_order_id;
  end if;
  v_total := v_total - v_discount;
  -- 0021 DELTA END.

   update public.orders
     set status = 'assigned',
         scheduled_delivery_at = p_expected_delivery_date
   where id = p_order_id;

  if p_issue_invoice then
    insert into public.invoices (client_id, branch_id, amount, status, due_date)
    values (v_client_id, v_branch_id, v_total, 'pending', p_expected_delivery_date)
    returning id into v_invoice_id;
  end if;

  return v_invoice_id;
end;
$$;

grant execute on function public.branch_allocate_order(uuid, boolean, date, jsonb)
  to authenticated;
