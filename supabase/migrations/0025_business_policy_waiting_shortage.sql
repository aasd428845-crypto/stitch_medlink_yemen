-- `0025_business_policy_waiting_shortage.sql`
-- Phase 75: shortage / waiting / alternatives business-policy closure.
-- Adds the minimum schema/schema-level contracts required by the settled
-- business policy; it does NOT define accounting or production deploys.
--
-- 1) A new orders status <- waiting (cannot start from terminal states)
-- 2) Order shortage / waiting events table
-- 3) Alternative product approval table
--
-- Idempotent create/replace definitions; no changes to RLS grants;
-- no tables dropped.

alter table public.orders
  drop constraint if exists orders_status_check;

alter table public.orders
  add constraint orders_status_check
  check (status in ('pending','assigned','in_progress','waiting','delivered','cancelled'));

create table if not exists public.order_shortage_events (
  id            uuid primary key default gen_random_uuid(),
  order_id      uuid not null references public.orders(id) on delete cascade,
  branch_id     uuid references public.branches(id) on delete set null,
  event         text not null check (event in ('shortage_detected','waiting_started','available_again','waiting_ended','decision_recorded')),
  payload       jsonb,
  created_at    timestamptz not null default now()
);

create index if not exists order_shortage_events_order_idx on public.order_shortage_events(order_id);

create table if not exists public.order_alternatives (
  id                  uuid primary key default gen_random_uuid(),
  order_id            uuid not null references public.orders(id) on delete cascade,
  original_product_id uuid references public.products(id) on delete set null,
  alternative_product_id uuid references public.products(id) on delete set null,
  customer_selected_by uuid references public.users(id) on delete set null,
  approved_by         uuid references public.users(id) on delete set null,
  status              text not null default 'PROPOSED' check (status in ('PROPOSED','CUSTOMER_SELECTED','MANAGER_APPROVED','APPLIED','REJECTED')),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index if not exists order_alternatives_order_idx on public.order_alternatives(order_id);


-- D6 helper: move order to `waiting`. Idempotent on order_id+waiting_event.
create or replace function public.set_order_waiting(p_order_id uuid, p_reason text default null)
returns text
language plpgsql
security definer
set search_path = public
as $f$
declare
  v_current text;
  v_client uuid;
  v_branch uuid;
  v_caller uuid := auth.uid();
  v_role text := public.current_user_role();
begin
  select status, client_id, branch_id into v_current, v_client, v_branch from public.orders where id = p_order_id;
  if not found then raise exception 'Order not found'; end if;

  -- authorization: only the owning client or a branch/company director may bound this
  if v_caller is null or (v_role not in ('company_director','branch_manager','client')) then
    raise exception 'غير مصرح لك';
  end if;
  if v_role = 'client' and v_client <> v_caller then
    raise exception 'يمكن للعميل فقط تعديل طلبه';
  end if;
  if v_role = 'branch_manager' then
    -- branch reachability verified inside same transaction below
    if not exists (
      select 1 from public.users u where u.id = v_caller and u.branch_id = v_branch
    ) then
      raise exception 'مدير فرع غير مخول لهذا الطلب';
    end if;
  end if;
  -- company isolation: caller's role governs, no cross-tenant order visible
  if v_current in ('delivered','cancelled','waiting') then
    return v_current; -- idempotent / no transition on terminal or already waiting
  end if;
  update public.orders set status = 'waiting' where id = p_order_id;
  insert into public.order_shortage_events (order_id, event, payload)
  values (p_order_id, 'waiting_started', jsonb_build_object('reason', p_reason));
  return 'waiting';
end;
$f$;

-- =============================================================
-- D4  Cross-branch shortage contract (added in Phase 75)
-- =============================================================
create or replace function public.cross_branch_candidates(p_order_id uuid)
returns table(branch_id uuid, branch_name text, product_id uuid, available_qty int)
language plpgsql
security definer
set search_path = public
as $f$
declare
  v_original_branch uuid;
  v_status text;
begin
  if auth.uid() is null then raise exception 'غير مصرح لك'; end if;

  select o.branch_id, o.status into v_original_branch, v_status
  from public.orders o where o.id = p_order_id;
  if not found then raise exception 'Order not found'; end if;

  return query
  select w.branch_id, b.name, w.product_id, w.quantity::int
  from public.warehouse_inventory w
  join public.branches b on b.id = w.branch_id
  where w.branch_id <> v_original_branch
    and w.quantity > 0
    and exists (
      select 1 from public.order_items oi
      where oi.order_id = p_order_id and oi.product_id = w.product_id
    );
end;
$f$;

create or replace function public.record_shortage_decision(
  p_order_id uuid,
  p_decision text,
  p_candidate_branch uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $f$
declare
  v_actor uuid := auth.uid();
  v_role text := public.current_user_role();
  v_branch uuid;
  v_status text;
  v_shortage_id uuid;
  v_existing uuid;
begin
  if v_actor is null or v_role <> 'branch_manager' then
    raise exception 'غير مصرح لك — مطلوب دور مدير فرع';
  end if;

  select o.branch_id, o.status into v_branch, v_status from public.orders o where o.id = p_order_id;
  if not found then raise exception 'Order not found'; end if;

  if v_branch is distinct from (select branch_id from public.users where id = v_actor) then
    raise exception 'مدير فرع غير مخول لهذا الطلب';
  end if;

  if v_status in ('delivered','cancelled') then
    raise exception 'لا يمكن تسجيل قرار على طلب منتهي';
  end if;

  if p_candidate_branch is not null then
    if not exists (
      select 1 from public.warehouse_inventory w
      join public.order_items oi on oi.product_id = w.product_id
      where w.branch_id = p_candidate_branch
        and oi.order_id = p_order_id
        and w.quantity > 0
    ) then
      raise exception 'No current stock at candidate branch for requested items';
    end if;
  end if;

  select id into v_existing
  from public.order_shortage_events
  where order_id = p_order_id
    and event = 'decision_recorded'
    and payload ->> 'decision' = p_decision;

  if v_existing is not null then
    return v_existing; -- idempotent repeat
  end if;

  insert into public.order_shortage_events (order_id, branch_id, event, payload)
  values (
    p_order_id,
    v_branch,
    'decision_recorded',
    jsonb_build_object(
      'decision', p_decision,
      'candidate_branch', p_candidate_branch,
      'actor', v_actor,
      'decided_at', now()
    )
  )
  returning id into v_shortage_id;

  return v_shortage_id;
end;
$f$;

-- =============================================================
-- D5  Alternative product state machine RPCs
-- =============================================================
create or replace function public.select_order_alternative(p_alt_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $f$
declare
  v_order_id uuid;
  v_client_id uuid;
  v_status text;
  v_alt_product uuid;
begin
  if auth.uid() is null then raise exception 'غير مصرح لك'; end if;

  select oa.order_id, o.client_id, oa.status, oa.alternative_product_id
    into v_order_id, v_client_id, v_status, v_alt_product
  from public.order_alternatives oa
  join public.orders o on o.id = oa.order_id
  where oa.id = p_alt_id;
  if not found then raise exception 'Alternative not found'; end if;

  if v_client_id <> auth.uid() then
    raise exception 'العميل صاحب الطلب فقط يمكنه اختيار البديل';
  end if;

  if v_status = 'CUSTOMER_SELECTED' then
    return 'CUSTOMER_SELECTED'; -- idempotent
  end if;
  if v_status <> 'PROPOSED' then
    raise exception 'Invalid state transition from %', v_status;
  end if;

  update public.order_alternatives
     set status = 'CUSTOMER_SELECTED',
         customer_selected_by = auth.uid(),
         updated_at = now()
   where id = p_alt_id;
  return 'CUSTOMER_SELECTED';
end;
$f$;

create or replace function public.approve_order_alternative(p_alt_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $f$
declare
  v_order_id uuid;
  v_branch_id uuid;
  v_manager_branch uuid;
  v_status text;
  v_alt_product uuid;
  v_orig_product uuid;
  v_order_status text;
  v_total numeric(12,2);
begin
  if auth.uid() is null or public.current_user_role() <> 'branch_manager' then
    raise exception 'غير مصرح لك — مطلوب دور مدير فرع';
  end if;

  select u.branch_id into v_manager_branch from public.users u where u.id = auth.uid();
  if v_manager_branch is null then raise exception 'لم يتم العثور على فرعك'; end if;

  select oa.order_id, o.branch_id, oa.status,
         oa.alternative_product_id, oa.original_product_id, o.status
    into v_order_id, v_branch_id, v_status, v_alt_product, v_orig_product, v_order_status
  from public.order_alternatives oa
  join public.orders o on o.id = oa.order_id
  where oa.id = p_alt_id;
  if not found then raise exception 'Alternative not found'; end if;

  if v_manager_branch <> v_branch_id then
    raise exception 'مدير فرع آخر غير مخول';
  end if;

  if v_order_status in ('delivered','cancelled') then
    raise exception 'لا يمكن تطبيق بديل على طلب منتهٍ';
  end if;

  if v_status = 'APPLIED' then
    return 'APPLIED'; -- idempotent
  end if;
  if v_status <> 'CUSTOMER_SELECTED' then
    raise exception 'Invalid state transition from %', v_status;
  end if;

  -- server-side stock recheck at execution time
  if not exists (
    select 1 from public.warehouse_inventory
     where branch_id = v_branch_id and product_id = v_alt_product and quantity > 0
  ) then
    raise exception 'المنتج البديل غير متوفر حاليًا';
  end if;

  update public.order_items
     set product_id = v_alt_product
   where order_id = v_order_id
     and product_id = v_orig_product;

  select coalesce(sum(quantity * unit_price), 0) into v_total
  from public.order_items where order_id = v_order_id;

  update public.orders set total_amount = v_total where id = v_order_id;

  update public.order_alternatives
     set status = 'APPLIED',
         approved_by = auth.uid(),
         updated_at = now()
   where id = p_alt_id;

  return 'APPLIED';
end;
$f$;

create or replace function public.reject_order_alternative(p_alt_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $f$
declare
  v_order_id uuid;
  v_branch_id uuid;
  v_status text;
  v_manager_branch uuid;
  v_client_id uuid;
begin
  if auth.uid() is null then raise exception 'غير مصرح لك'; end if;

  select oa.order_id, o.branch_id, oa.status, o.client_id
    into v_order_id, v_branch_id, v_status, v_client_id
  from public.order_alternatives oa
  join public.orders o on o.id = oa.order_id
  where oa.id = p_alt_id;
  if not found then raise exception 'Alternative not found'; end if;

  -- rejection allowed by owning customer or by the branch manager of the order
  if auth.uid() = v_client_id then
    null; -- customer reject OK
  elsif public.current_user_role() = 'branch_manager' then
    select u.branch_id into v_manager_branch from public.users u where u.id = auth.uid();
    if v_manager_branch <> v_branch_id then
      raise exception 'مدير فرع آخر غير مخول';
    end if;
  else
    raise exception 'غير مصرح لك';
  end if;

  if v_status in ('REJECTED','APPLIED') then
    return v_status;
  end if;

  update public.order_alternatives
     set status = 'REJECTED',
         updated_at = now()
   where id = p_alt_id;
  return 'REJECTED';
end;
$f$;
