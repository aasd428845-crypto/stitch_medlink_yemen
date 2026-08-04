-- =============================================================
-- Migration 0004: Branch Manager read access to client & driver profiles
-- نفِّذ هذا الملف من Supabase Dashboard → SQL Editor
-- لا تعدّل الملفات 0001 أو 0002 أو 0003
--
-- السبب: سياسة 0001 الأصلية على public.users تسمح فقط بقراءة الصف
-- الخاص بالمستخدم نفسه أو لمدير الشركة العام. هذا يمنع مدير الفرع من رؤية
-- اسم/هاتف العميل صاحب الطلب، أو رؤية قائمة السائقين التابعين لفرعه —
-- وكلاهما ضروري للوحة تحكم مدير الفرع (المرحلة الرابعة).
-- =============================================================

create policy "users_select_branch_manager_clients_and_own_drivers"
  on public.users
  for select
  using (
    public.current_user_role() = 'branch_manager'
    and (
      role = 'client'
      or (role = 'driver' and branch_id = public.current_user_branch_id())
    )
  );

-- يسمح لمدير الفرع بإضافة صف مخزون جديد لفرعه إذا لم يكن موجوداً بعد
-- (المدير العام يبقى الوحيد المخوّل بالحذف/الإضافة لفروع أخرى عبر السياسة
-- الحالية inventory_director_insert_delete).
create policy "inventory_branch_manager_insert_own_branch"
  on public.inventory
  for insert
  with check (
    public.current_user_role() = 'branch_manager'
    and branch_id = public.current_user_branch_id()
  );
