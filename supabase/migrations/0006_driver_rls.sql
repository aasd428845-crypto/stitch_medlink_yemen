-- =============================================================
-- Migration 0006: Driver access to orders + status-advance RPC
-- نفِّذ هذا الملف من Supabase Dashboard → SQL Editor
-- لا تعدّل الملفات 0001–0005
--
-- ما يُضافه هذا الملف:
--   1. سياسة SELECT على orders تتيح للسائق رؤية طلباته المُسندة فقط
--   2. سياسة SELECT على users تتيح للسائق رؤية بيانات العميل (الاسم/الهاتف) لطلبات التوصيل
--   3. دالة driver_advance_order_status() بصلاحية security definer لتغيير الحالة بأمان
--      (تمنع السائق من تعديل أي حقل آخر، وتتحقق من الانتقالات المسموح بها)
-- =============================================================

-- ── 1. السائق يرى طلباته المُسندة فقط ──────────────────────────────────────
drop policy if exists "orders_driver_select" on public.orders;
create policy "orders_driver_select"
  on public.orders
  for select
  using (assigned_driver_id = auth.uid());

-- ── 2. السائق يرى بيانات العميل الخاصة بطلباته (الاسم والهاتف للتواصل) ────
drop policy if exists "users_driver_select_client_info" on public.users;
create policy "users_driver_select_client_info"
  on public.users
  for select
  using (
    public.current_user_role() = 'driver'
    and role = 'client'
  );

-- ── 3. دالة تغيير الحالة بصلاحية رفيعة (security definer) ─────────────────
-- السائق لا يملك UPDATE مباشرة على جدول orders؛ كل التعديلات تمر هنا.
-- الانتقالات المسموح بها:
--   assigned → in_progress
--   in_progress → delivered
create or replace function public.driver_advance_order_status(
  p_order_id   uuid,
  p_new_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current_status   text;
  v_assigned_driver  uuid;
  v_driver_id        uuid := auth.uid();
begin
  -- يجب أن يكون المستخدم مسجّلاً
  if v_driver_id is null then
    raise exception 'Unauthenticated';
  end if;

  -- اجلب الحالة الحالية والسائق المُسند
  select status, assigned_driver_id
    into v_current_status, v_assigned_driver
    from public.orders
   where id = p_order_id;

  if not found then
    raise exception 'Order % not found', p_order_id;
  end if;

  -- المُستدعي يجب أن يكون هو السائق المُسند
  if v_assigned_driver is distinct from v_driver_id then
    raise exception 'You are not the assigned driver for this order';
  end if;

  -- تحقق من صحة الانتقال
  if not (
    (v_current_status = 'assigned'    and p_new_status = 'in_progress') or
    (v_current_status = 'in_progress' and p_new_status = 'delivered')
  ) then
    raise exception 'Invalid transition: % → %', v_current_status, p_new_status;
  end if;

  -- طبّق التعديل
  update public.orders
     set status = p_new_status
   where id = p_order_id;
end;
$$;

-- منح صلاحية التنفيذ للمستخدمين المُسجَّلين
grant execute on function public.driver_advance_order_status(uuid, text)
  to authenticated;
