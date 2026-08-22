-- =============================================================
-- Migration 0012: Client account notifications
-- MedLink Yemen — shared Supabase database
--
-- Adds direct user targeting for notifications used by the client
-- notification centre. Existing notifications remain visible according
-- to their current target_role because NULL means "not user-targeted".
-- =============================================================

alter table public.notifications
  add column if not exists target_user_ids uuid[];

comment on column public.notifications.target_user_ids is
  'Optional list of user IDs that may see this notification. NULL means no direct user restriction.';

create index if not exists notifications_target_user_ids_gin_idx
  on public.notifications using gin (target_user_ids);

-- Replace the old role-only policy with the same role rule plus direct
-- user targeting. This is idempotent and does not change director writes.
drop policy if exists "notifications_select_relevant"
  on public.notifications;

create policy "notifications_select_relevant" on public.notifications
  for select using (
    (target_role is null
      or target_role = public.current_user_role())
    and
    (target_user_ids is null
      or auth.uid() = any(target_user_ids))
  );