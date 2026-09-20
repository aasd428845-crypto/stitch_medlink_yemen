-- =============================================================
-- MedLink Yemen — Bonus invariants regression check (TEST ONLY)
--
-- Purpose: verify the three bonus invariants from task
-- "Fix and Complete the Existing Bonus System" (§4 BONUS INVENTORY,
-- §8 FINANCIAL, §9 ANALYTICS) against migrations 0016
-- (branch_allocate_order paid/bonus split) and 0017
-- (create_order_with_items + get_order_product_distribution).
--
-- DO NOT RUN ON PRODUCTION. Requires a scratch Supabase project
-- (or `supabase start` locally) with migrations 0001→0017 applied,
-- plus operator-provisioned test rows (branch, client, manager).
-- Test fixture contract (operator must provision exactly this):
-- product unit_price = 100; rule buy 10 / free 1 / active / this product;
-- inventory row for (branch, product) with quantity >= 11.
-- Everything runs inside ONE transaction that ALWAYS ROLLS BACK.
-- Needs a role that can read the test rows (RLS-shaped RPCs enforce
-- caller role; run as the test branch_manager or service_role where
-- the RPC logic permits).
--
-- Usage (psql):
--   psql "$TEST_DATABASE_URL" -v branch_id='...' -v client_id='...'
--     -v product_id='...' -v rule_id='...' -v address_id='...'
--     -f scripts/sql/bonus-invariants-regression.sql
--
-- Each invariant raises EXCEPTION on violation; success prints NOTICE.
-- =============================================================

\set ON_ERROR_STOP on

-- 0) Guard: refuse to run when test identifiers are missing.
\if :{?branch_id} \else \echo 'Missing -v branch_id' \quit 1 \endif
\if :{?client_id} \else \echo 'Missing -v client_id' \quit 1 \endif
\if :{?product_id} \else \echo 'Missing -v product_id' \quit 1 \endif
\if :{?rule_id} \else \echo 'Missing -v rule_id' \quit 1 \endif
\if :{?address_id} \else \echo 'Missing -v address_id' \quit 1 \endif

begin;

-- Snapshot inventory before the flow.
create temp table _inv_before as
select quantity from public.inventory
where branch_id = :'branch_id'::uuid and product_id = :'product_id'::uuid;

-- J) Create order through the validating RPC (buy 10, rule gives +1 free).
--    Mirrors Flutter OrderService.createOrder payload shape.
do $$
declare
  v_order_id uuid;
begin
  select public.create_order_with_items(
    :'address_id'::uuid,
    jsonb_build_array(
      jsonb_build_object('product_id', :'product_id'::uuid, 'quantity', 10,
                         'unit_price', 100, 'is_bonus', false, 'bonus_rule_id', null),
      jsonb_build_object('product_id', :'product_id'::uuid, 'quantity', 1,
                         'unit_price', 0, 'is_bonus', true, 'bonus_rule_id', :'rule_id'::uuid)
    ),
    'regression-check'
  ) into v_order_id;
  perform set_config('regression.order_id', v_order_id::text, true);
  raise notice 'order created: %', v_order_id;
end $$;

-- K+M) Allocate as branch manager: 10 paid + 1 bonus physical units.
select public.branch_allocate_order(
  current_setting('regression.order_id')::uuid,
  true,
  current_date + 1,
  jsonb_build_array(
    jsonb_build_object('product_id', :'product_id'::uuid, 'allocated_qty', 11)
  )
);

-- INVARIANT I1: single physical deduction, no double counting.
-- Inventory must drop by exactly 11 (10 paid + 1 bonus), once.
do $$
declare
  v_before int; v_after int;
begin
  select quantity into v_before from _inv_before;
  select quantity into v_after from public.inventory
  where branch_id = :'branch_id'::uuid and product_id = :'product_id'::uuid;
  if v_before - v_after <> 11 then
    raise exception 'I1 violated: inventory delta % (expected 11)', v_before - v_after;
  end if;
  raise notice 'I1 ok: single physical deduction of 11 units';
end $$;

-- I1b: re-allocation of a non-pending order must be rejected (status gate).
do $$
begin
  begin
    perform public.branch_allocate_order(
      current_setting('regression.order_id')::uuid, true, null,
      jsonb_build_array(
        jsonb_build_object('product_id', :'product_id'::uuid, 'allocated_qty', 1)
      )
    );
    raise exception 'I1b violated: second allocation was accepted';
  exception when others then
    if sqlerrm = 'I1b violated: second allocation was accepted' then raise; end if;
    raise notice 'I1b ok: second allocation rejected (%)', sqlerrm;
  end;
end $$;

-- INVARIANT I2: invoice covers the paid part only; bonus lines stay free
-- and traceable to their rule.
do $$
declare
  v_inv_amount numeric; v_bonus_price numeric; v_orphan_bonus int;
begin
  select amount into v_inv_amount from public.invoices
  where client_id = :'client_id'::uuid order by created_at desc limit 1;
  -- 10 paid units at price 100; the 1 free unit must not inflate the total.
  if v_inv_amount <> 1000 then
    raise exception 'I2 violated: invoice amount % (expected 1000)', v_inv_amount;
  end if;
  select max(unit_price) into v_bonus_price from public.order_items
  where order_id = current_setting('regression.order_id')::uuid and is_bonus;
  if v_bonus_price <> 0 then
    raise exception 'I2 violated: bonus unit_price % (expected 0)', v_bonus_price;
  end if;
  select count(*) into v_orphan_bonus from public.order_items
  where order_id = current_setting('regression.order_id')::uuid
    and is_bonus and bonus_rule_id is null;
  if v_orphan_bonus > 0 then
    raise exception 'I2 violated: % bonus lines without bonus_rule_id', v_orphan_bonus;
  end if;
  raise notice 'I2 ok: invoice=1000, bonus free and rule-linked';
end $$;

-- INVARIANT I3: analytics split — paid excludes bonus, totals reconcile.
do $$
declare
  v_paid int; v_bonus int; v_total int;
begin
  select coalesce(sum(paid_sales_quantity),0),
         coalesce(sum(bonus_quantity),0),
         coalesce(sum(total_distributed_quantity),0)
    into v_paid, v_bonus, v_total
    from public.get_order_product_distribution(
      current_setting('regression.order_id')::uuid);
  if v_paid <> 10 or v_bonus <> 1 or v_total <> 11 then
    raise exception 'I3 violated: paid=% bonus=% total=% (expected 10/1/11)',
      v_paid, v_bonus, v_total;
  end if;
  raise notice 'I3 ok: paid=10 bonus=1 total=11';
end $$;

-- Always roll back: this script must never persist test data.
rollback;

\echo 'BONUS INVARIANTS: ALL CHECKS PASSED (rolled back, no data persisted)'
