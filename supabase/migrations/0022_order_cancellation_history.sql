-- ─────────────────────────────────────────────────────────────────────────
-- 0022_order_cancellation_history.sql — PHASE 33 (LOCAL ONLY, NOT APPLIED)
--
-- Implements the 32.1 FINAL CONTRACT (BD-1 = separate cancellation record):
-- event history for order cancellations, written ONLY inside the cancel
-- transaction. No backfill (history starts empty). 0021's FILE is untouched;
-- its cancel function is OR REPLACE'd here with the history INSERT added.
-- H2-A: no invoice objects. No tenant objects. POSTED rows never mutated.
--
-- SAFETY: local file only. Do NOT supabase db push / migration up / db reset.
-- ─────────────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────
-- 1. order_cancellations — one row per executed cancellation event
-- (present or future repeated attempts each record their own row).
-- ─────────────────────────────────────────
create table if not exists public.order_cancellations (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  reason text not null,
  reason_code text,
  note text,
  cancelled_by uuid references public.users(id) on delete set null,
  cancelled_at timestamptz not null default now(),
  previous_status text not null,
  source text not null,
  reversal_ledger_id uuid references public.bonus_ledger(id) on delete restrict,
  idempotency_key text,
  created_at timestamptz not null default now()
);

create index if not exists order_cancellations_order_idx
  on public.order_cancellations (order_id);

alter table public.order_cancellations enable row level security;

-- Reads mirror the orders SELECT precedent (0002:145-150): owner rows,
-- branch_manager and director unscoped. Writes: definer-RPC ONLY —
-- no INSERT/UPDATE/DELETE policy exists for any role.
drop policy if exists "order_cancellations_client_select" on public.order_cancellations;
create policy "order_cancellations_client_select" on public.order_cancellations
  for select using (
    exists (
      select 1 from public.orders o
       where o.id = order_cancellations.order_id
         and o.client_id = auth.uid()
    )
  );

drop policy if exists "order_cancellations_branch_select" on public.order_cancellations;
create policy "order_cancellations_branch_select" on public.order_cancellations
  for select using (public.current_user_role() = 'branch_manager');

drop policy if exists "order_cancellations_director_select" on public.order_cancellations;
create policy "order_cancellations_director_select" on public.order_cancellations
  for select using (public.current_user_role() = 'company_director');

-- ─────────────────────────────────────────
-- 2. cancel_order_with_discount — OR REPLACE with ONE delimited delta:
-- history INSERT inside the same transaction (Phase 23 atomicity rule).
-- Signature, security, grants, and all 0021 logic otherwise identical.
-- reason_code/note stay NULL until BD-2 taxonomy lands (no invented values).
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
  v_did_cancel boolean := false;
  v_made_reversal boolean := false;
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

      v_made_reversal := true;
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

    v_did_cancel := true;
  end if;

  -- 0022 DELTA START (sole intentional change vs 0021): history event row.
  -- Written only when THIS call executed something (status flip and/or fresh
  -- reversal); pure replays converge silently with zero new rows, matching
  -- the 0020 replay precedent. Same transaction: failure anywhere rolls back
  -- status, reversal, audit, and this row together — no cancelled-without-
  -- record and no record-without-cancel are reachable.
  if v_did_cancel or v_made_reversal then
    insert into public.order_cancellations
      (order_id, reason, reason_code, note, cancelled_by, cancelled_at,
       previous_status, source, reversal_ledger_id, idempotency_key)
    values (p_order_id, btrim(p_reason), null, null, v_caller, now(),
            v_order.status, v_role, v_reversal_id, v_key);
  end if;
  -- 0022 DELTA END.

  return v_reversal_id;
end $$;

grant execute on function public.cancel_order_with_discount(uuid, text, text) to authenticated;
