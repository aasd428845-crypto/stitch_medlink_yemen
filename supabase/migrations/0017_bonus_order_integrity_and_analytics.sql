-- =============================================================
-- Migration 0017 — Bonus order integrity and distribution analytics
-- MedLink Yemen — shared Supabase database
--
-- 0016 fixed the branch-side physical deduction. This migration closes the
-- client-side trust gap: order creation validates the selected rule and
-- computes the payable amount on the server. It also preserves the rule id
-- and exposes paid/bonus/physical quantities for demand analysis.
-- =============================================================

alter table public.order_items
  add column if not exists bonus_rule_id uuid references public.bonus_rules(id);

alter table public.order_items
  drop constraint if exists order_items_bonus_price_check;

alter table public.order_items
  add constraint order_items_bonus_price_check
  check (not is_bonus or unit_price = 0)
  not valid;

-- Orders and order_items must be created through the validating RPC below.
-- Keeping the old direct client INSERT policies would allow a caller to mark
-- arbitrary paid units as free and bypass the exact cart calculation.
drop policy if exists "orders_client_insert" on public.orders;
drop policy if exists "order_items_insert" on public.order_items;

create or replace function public.create_order_with_items(
  p_delivery_address_id uuid,
  p_items jsonb,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client_id uuid := auth.uid();
  v_address_governorate text;
  v_branch_id uuid;
  v_order_id uuid;
  v_item_count int;
  v_product record;
  v_product_price numeric(10,2);
  v_paid_qty int;
  v_bonus_qty int;
  v_expected_bonus_qty int;
  v_expected_rule_id uuid;
  v_has_specific_rule boolean;
  v_total numeric(12,2) := 0;
begin
  if v_client_id is null then
    raise exception 'Authentication required';
  end if;

  if p_delivery_address_id is null then
    raise exception 'A delivery address is required';
  end if;

  select governorate
    into v_address_governorate
    from public.client_addresses
   where id = p_delivery_address_id
     and client_id = v_client_id;

  if not found then
    raise exception 'Delivery address does not belong to the current client';
  end if;

  select count(*)::int
    into v_item_count
    from jsonb_to_recordset(coalesce(p_items, '[]'::jsonb))
      as x(product_id uuid, quantity int, unit_price numeric,
          is_bonus boolean, bonus_rule_id uuid);

  if v_item_count = 0 then
    raise exception 'Cannot create an order without items';
  end if;

  if exists (
    select 1
      from jsonb_to_recordset(p_items)
        as x(product_id uuid, quantity int, unit_price numeric,
            is_bonus boolean, bonus_rule_id uuid)
     where product_id is null or quantity is null or quantity <= 0
  ) then
    raise exception 'Order items must have a product and a positive quantity';
  end if;

  if exists (
    select 1
      from jsonb_to_recordset(p_items)
        as x(product_id uuid, quantity int, unit_price numeric,
            is_bonus boolean, bonus_rule_id uuid)
     where coalesce(is_bonus, false) and coalesce(unit_price, 0) <> 0
  ) then
    raise exception 'Bonus items must have a zero price';
  end if;

  -- Evaluate one winning rule per product. Product-specific rules win over
  -- general rules. Within that scope: highest earned bonus, lowest threshold,
  -- earliest creation timestamp, then id. This is the same deterministic
  -- selection documented in CartController.
  for v_product in
    select product_id,
           coalesce(sum(quantity) filter (where not coalesce(is_bonus, false)), 0)::int
             as paid_qty,
           coalesce(sum(quantity) filter (where coalesce(is_bonus, false)), 0)::int
             as bonus_qty,
           max(bonus_rule_id) filter (where coalesce(is_bonus, false)) as submitted_rule_id
      from jsonb_to_recordset(p_items)
        as x(product_id uuid, quantity int, unit_price numeric,
            is_bonus boolean, bonus_rule_id uuid)
     group by product_id
  loop
    select unit_price
      into v_product_price
      from public.products
     where id = v_product.product_id
       and is_active = true;

    if not found then
      raise exception 'Product % is not active or does not exist', v_product.product_id;
    end if;

    if exists (
      select 1
        from jsonb_to_recordset(p_items)
          as x(product_id uuid, quantity int, unit_price numeric,
              is_bonus boolean, bonus_rule_id uuid)
       where x.product_id = v_product.product_id
         and not coalesce(x.is_bonus, false)
         and abs(coalesce(x.unit_price, v_product_price) - v_product_price) > 0.005
    ) then
      raise exception 'Product price changed for %; refresh the cart',
        v_product.product_id;
    end if;

    v_paid_qty := v_product.paid_qty;
    v_bonus_qty := v_product.bonus_qty;
    v_expected_bonus_qty := 0;
    v_expected_rule_id := null;

    select exists (
      select 1
        from public.bonus_rules r
       where r.product_id = v_product.product_id
         and r.is_active
         and current_date >= coalesce(r.start_date, current_date)
         and current_date <= coalesce(r.end_date, current_date)
         and r.buy_quantity > 0
         and r.free_quantity > 0
         and v_paid_qty >= r.buy_quantity
         and (
           r.target_governorate is null
           or lower(trim(r.target_governorate)) =
              lower(trim(v_address_governorate))
         )
    ) into v_has_specific_rule;

    select r.id,
           case when r.is_stackable
             then (floor(v_paid_qty::numeric / r.buy_quantity)::int * r.free_quantity)
             else r.free_quantity
           end
      into v_expected_rule_id, v_expected_bonus_qty
      from public.bonus_rules r
     where (r.product_id = v_product.product_id
            or (r.product_id is null and not v_has_specific_rule))
       and r.is_active
       and current_date >= coalesce(r.start_date, current_date)
       and current_date <= coalesce(r.end_date, current_date)
       and r.buy_quantity > 0
       and r.free_quantity > 0
       and v_paid_qty >= r.buy_quantity
       and (
         r.target_governorate is null
         or lower(trim(r.target_governorate)) =
            lower(trim(v_address_governorate))
       )
     order by
       (case when r.is_stackable
          then floor(v_paid_qty::numeric / r.buy_quantity)::int * r.free_quantity
          else r.free_quantity
        end) desc,
       r.buy_quantity asc,
       r.created_at asc nulls first,
       r.id asc
     limit 1;

    v_expected_bonus_qty := coalesce(v_expected_bonus_qty, 0);

    if v_bonus_qty <> v_expected_bonus_qty then
      raise exception
        'Bonus quantity is no longer valid for product % (expected %, received %)',
        v_product.product_id, v_expected_bonus_qty, v_bonus_qty;
    end if;

    if v_bonus_qty > 0 and v_expected_rule_id is distinct from v_product.submitted_rule_id then
      raise exception 'Bonus rule changed for product %; refresh the cart',
        v_product.product_id;
    end if;

    v_total := v_total + (v_paid_qty * v_product_price);
  end loop;

  select id
    into v_branch_id
    from public.branches
   order by created_at asc, id asc
   limit 1;

  insert into public.orders (
    client_id, branch_id, status, delivery_address_id, total_amount, notes
  )
  values (
    v_client_id, v_branch_id, 'pending', p_delivery_address_id, v_total, p_notes
  )
  returning id into v_order_id;

  insert into public.order_items (
    order_id, product_id, quantity, unit_price, is_bonus, bonus_rule_id
  )
  select
    v_order_id,
    x.product_id,
    x.quantity,
    case when coalesce(x.is_bonus, false) then 0 else p.unit_price end,
    coalesce(x.is_bonus, false),
    case when coalesce(x.is_bonus, false) then x.bonus_rule_id else null end
    from jsonb_to_recordset(p_items)
      as x(product_id uuid, quantity int, unit_price numeric,
          is_bonus boolean, bonus_rule_id uuid)
    join public.products p on p.id = x.product_id;

  return v_order_id;
end;
$$;

grant execute on function public.create_order_with_items(uuid, jsonb, text)
  to authenticated;

-- Product-level distribution facts remain available for forecasting without
-- misclassifying free units as paid sales. Access is intentionally provided
-- through this filtered RPC instead of granting a view over all customers.
create or replace function public.get_order_product_distribution(
  p_order_id uuid default null
)
returns table (
  order_id uuid,
  product_id uuid,
  paid_sales_quantity bigint,
  bonus_quantity bigint,
  total_distributed_quantity bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    oi.order_id,
    oi.product_id,
    coalesce(sum(oi.quantity) filter (where not oi.is_bonus), 0)::bigint,
    coalesce(sum(oi.quantity) filter (where oi.is_bonus), 0)::bigint,
    coalesce(sum(oi.quantity), 0)::bigint
  from public.order_items oi
  join public.orders o on o.id = oi.order_id
  where (p_order_id is null or oi.order_id = p_order_id)
    and (
      o.client_id = auth.uid()
      or o.assigned_driver_id = auth.uid()
      or public.current_user_role() = 'company_director'
      or (
        public.current_user_role() = 'branch_manager'
        and o.branch_id = public.current_user_branch_id()
      )
    )
  group by oi.order_id, oi.product_id;
$$;

grant execute on function public.get_order_product_distribution(uuid)
  to authenticated;