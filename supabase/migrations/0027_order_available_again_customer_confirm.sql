-- 0027_order_available_again_customer_confirm.sql — D8 backend contract.
-- Provides a minimal, idempotent and authorization-aware path for:
--   1. Marking the missing product available again for a waiting order
--   2. Creating an In-App notification for the owning customer
--   3. Recording the customer's explicit confirmation
--   4. Moving the order back to the existing pending flow after confirmation
-- No accounting/GL objects are created; the Bonus system remains intact.

create or replace function public.mark_order_available_again(
  p_order_id uuid,
  p_product_id uuid default null,
  p_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
  v_client uuid;
  v_has_waiting boolean;
  v_has_available boolean;
  v_event_id uuid;
begin
  if auth.uid() is null then raise exception 'غير مصرح لك'; end if;
  select status, client_id into v_status, v_client
  from public.orders where id = p_order_id;
  if not found then raise exception 'الطلب غير موجود'; end if;
  if v_status <> 'waiting' then
    raise exception 'الطلب ليس في حالة انتظار';
  end if;
  -- Must already have a waiting/shortage event
  select exists(select 1 from public.order_shortage_events e where e.order_id = p_order_id and e.event in ('waiting_started','shortage_detected')) into v_has_waiting;
  if not v_has_waiting then
    raise exception 'لا يوجد حدث نقص/انتظار مرتبط بهذا الطلب';
  end if;
  -- Idempotent: do not append the same available_again for same order/product
  select exists(
    select 1 from public.order_shortage_events e
    where e.order_id = p_order_id
      and e.event = 'available_again'
      and (e.payload->>'product_id') is not distinct from p_product_id::text
  ) into v_has_available;
  if v_has_available then
    -- return existing event id
    select id into v_event_id from public.order_shortage_events
    where order_id = p_order_id and event='available_again' and (payload->>'product_id') is not distinct from p_product_id::text
    order by created_at desc limit 1;
    return v_event_id;
  end if;

  insert into public.order_shortage_events (order_id, event, payload)
  values (p_order_id, 'available_again', jsonb_build_object('product_id', p_product_id, 'reason', p_reason))
  returning id into v_event_id;

  insert into public.notifications (title, body, target_role, target_branch_id, target_user_ids, related_offer_id, created_by)
  values ('المنتج أصبح متاحًا','المنتج الذي كان غير متوفر أصبح متوفرًا مرة أخرى. يرجى تأكيد متابعة الطلب.','client',null,array[v_client], null, auth.uid());

  return v_event_id;
end;
$$;

create or replace function public.confirm_order_resume(p_order_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status text;
  v_client uuid;
  v_has_available boolean;
  v_has_confirm boolean;
begin
  if auth.uid() is null then raise exception 'غير مصرح لك'; end if;
  select status, client_id into v_status, v_client from public.orders where id = p_order_id;
  if not found then raise exception 'الطلب غير موجود'; end if;
  if v_status <> 'waiting' then
    raise exception 'الطلب ليس في حالة انتظار';
  end if;
  if v_client <> auth.uid() then
    raise exception 'لا يمكنك تأكيد هذا الطلب';
  end if;
  select exists(select 1 from public.order_shortage_events where order_id=p_order_id and event='available_again') into v_has_available;
  if not v_has_available then
    raise exception 'لا يوجد حدث available_again مرتبط';
  end if;
  select exists(select 1 from public.order_shortage_events where order_id=p_order_id and event='waiting_ended') into v_has_confirm;
  if v_has_confirm then
    return 'already_confirmed';
  end if;
  update public.orders set status = 'pending' where id = p_order_id;
  insert into public.order_shortage_events (order_id, event, payload)
  values (p_order_id, 'waiting_ended', jsonb_build_object('confirmed_by', auth.uid()));
  return 'resumed';
end;
$$;
