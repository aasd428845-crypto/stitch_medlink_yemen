-- =============================================================
-- Migration 0005: Narrow users RLS + secure password-change RPC
-- نفِّذ هذا الملف من Supabase Dashboard → SQL Editor
-- لا تعدّل الملفات 0001–0004
--
-- السبب: سياسة 0001 الأصلية "users_update_own" أتاحت للمستخدم تعديل أي
-- حقل في صفه الخاص — بما فيها role وaccount_status وbranch_id و
-- requires_password_change — مما يتيح ترقية الدور ذاتياً ثم استغلال
-- Edge Function الخاصة بالمرحلة الخامسة. هذه الهجرة تغلق هذا الثغرة.
-- =============================================================

-- 1. Drop the dangerously broad update policy.
drop policy if exists "users_update_own" on public.users;

-- 2. Replace it with a narrow policy that only allows authenticated users
--    to update their own display name and phone number.
--    Sensitive fields (role, account_status, branch_id,
--    requires_password_change) are backend-only and cannot be written via
--    this policy.
create policy "users_update_own_profile"
  on public.users
  for update
  using  (id = auth.uid())
  with check (
    -- Prevent any write that changes protected columns.
    -- The WITH CHECK expression runs after the update; if any protected
    -- column was modified the check fails and the update is rolled back.
    id              = auth.uid()
    and role        = (select role        from public.users where id = auth.uid())
    and account_status = (select account_status from public.users where id = auth.uid())
    and branch_id   is not distinct from (select branch_id from public.users where id = auth.uid())
    and requires_password_change = (select requires_password_change from public.users where id = auth.uid())
  );

-- 3. Security-definer RPC used by the driver's "change password" flow.
--    It atomically clears requires_password_change for the calling user —
--    no other column can be touched through this function.
--    Called from Flutter after supabase.auth.updateUser(password: …) succeeds.
create or replace function public.clear_requires_password_change()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  update public.users
  set requires_password_change = false
  where id = v_uid
    -- Extra guard: only clear if the column is currently true.
    -- Prevents spurious calls from non-driver accounts.
    and requires_password_change = true;
end;
$$;

-- Grant execute only to authenticated role (drivers, managers, etc.).
-- The function is security definer so it runs as the function owner (postgres),
-- but auth.uid() inside still returns the calling user — no privilege leakage.
grant execute on function public.clear_requires_password_change() to authenticated;
