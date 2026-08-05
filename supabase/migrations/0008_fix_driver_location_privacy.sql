-- =============================================================
-- Migration 0008: تقييد خصوصية موقع السائق (driver_locations)
-- نفِّذ هذا الملف من Supabase Dashboard → SQL Editor
-- لا تعدّل الملفات 0001–0007
--
-- المشكلة: سياسة driver_locations_parties_select في 0007 كانت تسمح
-- لأي مستخدم بدور 'client' أو 'branch_manager' برؤية موقع أي سائق،
-- بصرف النظر عن وجود علاقة فعلية بينهما.
--
-- الإصلاح:
--   - مدير الفرع: يرى موقع سائقي فرعه فقط (ربط عبر public.users.branch_id).
--   - العميل: يرى موقع السائق فقط إذا كان لديه طلب مُسنَد لذلك السائق
--     تحديداً وبحالة 'in_progress' (التوصيل الجاري — المعادل الفعلي
--     لحالة "قيد التوصيل" في enum orders.status الحالي، الذي لا يحوي
--     'out_for_delivery' — انظر public.orders.status check constraint
--     في 0002_catalog_inventory_orders.sql).
--   - السائق نفسه يبقى يرى موقعه (لا تغيير).
-- =============================================================

drop policy if exists "driver_locations_parties_select" on public.driver_locations;

-- ── مدير الفرع: فقط سائقو فرعه ──────────────────────────────────────────────
create policy "driver_locations_branch_manager_select"
  on public.driver_locations
  for select
  using (
    public.current_user_role() = 'branch_manager'
    and exists (
      select 1
        from public.users u
       where u.id = driver_locations.driver_id
         and u.branch_id = public.current_user_branch_id()
    )
  );

-- ── العميل: فقط سائقه المُسنَد لطلب جارٍ فعلياً (in_progress) ───────────────
create policy "driver_locations_client_active_order_select"
  on public.driver_locations
  for select
  using (
    public.current_user_role() = 'client'
    and exists (
      select 1
        from public.orders o
       where o.assigned_driver_id = driver_locations.driver_id
         and o.client_id = auth.uid()
         and o.status = 'in_progress'
    )
  );

-- ── السائق نفسه (بدون تغيير عن 0007؛ يُعاد إنشاؤها هنا للوضوح والاكتفاء الذاتي) ──
drop policy if exists "driver_locations_own_select" on public.driver_locations;
create policy "driver_locations_own_select"
  on public.driver_locations
  for select
  using (driver_id = auth.uid());
