-- ─────────────────────────────────────────────────────────────────────────
-- 0026_order_item_modification.sql — D7 Backend Contract (LOCAL, additive)
-- SANCTIONED: only replaces nothing; provides a safe server-single-transaction
-- modify_order_item(...) contract. No accounting/GL objects.
-- ─────────────────────────────────────────────────────────────────────────
create or replace function public.modify_order_item(
  p_order_id uuid,
  p_order_item_id uuid,
  p_operation text,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor uuid := auth.uid();
  v_role text := public.current_user_role();
  v_order public.orders%rowtype;
  v_item public.order_items%rowtype;
  v_key text := coalesce(nullif(btrim(p_idempotency_key), ''),
                         'MOD:' || p_order_id::text || ':' || p_order_item_id::text);
  v_old_total numeric(12,2);
  v_new_total numeric(12,2);
  v_discount_row public.bonus_ledger%rowtype;
  v_discount numeric(12,2) := 0;
  v_new_discount numeric(12,2) := 0;
  v_refund numeric(12,2) := 0;
  v_existing jsonb;
begin
  if v_actor is null then raise exception 'غير مصرح لك'; end if;
  if v_role not in ('client','branch_manager','company_director') then
    raise exception 'غير مصرح لك';
  end if;
  if p_operation is null or p_operation <> 'remove' then
    raise exception 'غير مدعوم حاليًا إلا إزالة بند كامل';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then raise exception 'الطلب غير موجود'; end if;

  if v_role = 'client' and v_order.client_id <> v_actor then
    raise exception 'ليس طلبك';
  end if;
  if v_role = 'branch_manager' then
    if not exists (
      select 1
      from public.users u
      where u.id = v_actor
        and u.role = 'branch_manager'
        and u.branch_id = v_order.branch_id
    ) then
      raise exception 'مدير فرع غير مخول لهذا الطلب';
    end if;
  end if;
  if v_order.status in ('delivered','cancelled') then
    raise exception 'لا يمكن تعديل طلب منتهٍ';
  end if;
  if v_order.status not in ('pending','assigned','in_progress','waiting') then
    raise exception 'الحالة غير مسموحة';
  end if;


  -- idempotent replay: same logical removal returns the recorded result instead
  -- of mutating any state again.
  if exists (
    select 1 from public.bonus_audit_trail a
    where a.reason = v_key and a.action = 'REMOVE_ORDER_ITEM'
  ) then
    return jsonb_build_object('status','already_processed','order_id',p_order_id,'order_item_id',p_order_item_id,'operation',p_operation,'idempotency_key',v_key);
  end if;

  select * into v_item from public.order_items
   where id = p_order_item_id and order_id = p_order_id;
  if not found then raise exception 'بند غير موجود'; end if;

  v_old_total := coalesce(v_order.total_amount, 0);
  -- pick the latest POSTED discount, if any
  select * into v_discount_row from public.bonus_ledger
   where order_id = p_order_id and txn_type = 'ORDER_DISCOUNT' and status = 'POSTED'
   order by created_at desc limit 1;
  if found then
    v_discount := abs(v_discount_row.amount);
  end if;

  -- remove item
  delete from public.order_items where id = p_order_item_id;

  select coalesce(sum(quantity * unit_price), 0)::numeric(12,2) into v_new_total
  from public.order_items where order_id = p_order_id;

  -- proportional allowance of the previous discount to the remaining subtotal
  if v_old_total > 0 then
    v_new_discount := least(v_discount, round(v_discount * v_new_total / v_old_total, 2));
  else
    v_new_discount := 0;
  end if;
  v_refund := greatest(v_discount - v_new_discount, 0);

  update public.orders set total_amount = v_new_total where id = p_order_id;

  if v_refund > 0 then
    insert into public.bonus_ledger
      (account_id, txn_type, amount, status, order_id, actor, reference, notes, idempotency_key)
    values
      (v_discount_row.account_id, 'REFUND', v_refund, 'POSTED', p_order_id, v_actor,
       'MOD:' || p_order_id::text, 'Excess bonus refund after item removal', v_key);
  end if;

  insert into public.bonus_audit_trail (entity, entity_id, action, actor, old_value, new_value, reason)
  values ('order_item', p_order_item_id, 'REMOVE_ORDER_ITEM', v_actor,
          jsonb_build_object('order_id', p_order_id, 'total_amount', v_old_total, 'discount', v_discount),
          jsonb_build_object('new_total', v_new_total, 'new_discount', v_new_discount, 'refund', v_refund),
          v_key);

  return jsonb_build_object(
    'order_id', p_order_id,
    'order_item_id', p_order_item_id,
    'status', 'ok',
    'old_total', v_old_total,
    'new_total', v_new_total,
    'old_discount', v_discount,
    'new_discount', v_new_discount,
    'refund_amount', v_refund,
    'idempotency_key', v_key
  );
end;
$$;

grant execute on function public.modify_order_item(uuid, uuid, text, text) to authenticated;
