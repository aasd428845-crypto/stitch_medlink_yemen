-- =============================================================
-- Migration 0029 — Bonus Earn (E1) → GL: director account-role mapping
-- + journal leg layouts (Phase 2 of the E1 accounting integration).
--
-- WHY (updated): 0028 applies BD-01 fail-closed and emits
-- ACCOUNT_MAPPING_REQUIRED whenever a journal leg's role has no GL account bound
-- to it. The seeded COA (0007:38-59 + 0017) has NO customer-bonus liability
-- account (see docs/opencode/PHASE-49 §5.2): 2100 = supplier payables, 126000 =
-- doctor commissions, 6000 = generic expense, 4000 = revenue, 1110/1120 =
-- cash/bank. So roles are *structurally* unmapped today and 0028 is right to
-- refuse.
--
--   This migration adds TWO director-only bridges:
--   1. bonus_role_account_map  — role → GL account, single-company-scoped.
--      The role column is GENERAL (any non-empty string), so a director can
--      designate 'cash', 'deferred_bonus_liability', 'bonus_expense', or any
--      future role. NO account CODE is ever auto-seeded: the director points a
--      role at an existing, postable, company-scoped financial_accounts row.
--   2. bonus_journal_leg_mapping — (process, option) → (debit_role, credit_role).
--      This is the configurable layout that replaces every hardcoded account code
--      in the posting logic. A director defines: for event E1, option A, the
--      debit leg is the 'cash' role and the credit leg is the
--      'deferred_bonus_liability' role. Both roles resolve to GL account codes
--      via bonus_role_account_map (table 1 above). The resolved codes are
--      snapshotted per-earn by apply_bonus_earn_accounting (0030) so later
--      rebinding never changes an already-decided earn's legs.
--
--   current_user_role() is JWT-scoped (0001:52), so RLS keyed on it cannot
--   be bypassed by SECURITY DEFINER — only a company_director row can
--   read/write these tables, and only a company_director session can call the
--   management RPCs (see post_bonus_earn_to_gl in 0030).
--
-- WHAT THIS FILE ADDS (additive only — new DB objects, 0 tracked object modified):
--   1. bonus_role_account_map  — generalized role → GL account.
--   2. bonus_journal_leg_mapping — (process, option) → debit_role, credit_role.
--   3. RLS: director-only for all/select using on both tables.
--   4. upsert_bonus_role_account_map / delete_bonus_role_account_map /
--      get_bonus_role_account_map (generalized — any role string accepted).
--   5. upsert_journal_leg_layout / delete_journal_leg_layout /
--      get_journal_leg_layout (new — manage per-option leg layouts).
--
-- NO production change. Apply only to an isolated scratch database.
-- =============================================================

-- ── 1) role → GL account map (director-managed, company-scoped) ────────────────
--     Role is GENERALIZED (any non-empty string) so directors can designate
--     'cash', 'deferred_bonus_liability', 'bonus_expense', and future roles
--     without a code change. The previous CHECK
--     (role in ('deferred_bonus_liability','bonus_expense')) is replaced.
create table if not exists public.bonus_role_account_map (
  id               uuid primary key default gen_random_uuid(),
  company_id       uuid not null references public.financial_companies(id),
  role             text not null check (role <> ''),
  account_id       uuid not null references public.financial_accounts(id),
  is_active        boolean not null default true,
  created_by       uuid references public.users(id) on delete set null,
  updated_by       uuid references public.users(id) on delete set null,
  idempotency_key  text unique,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- One active mapping per (company, role); history kept as inactive rows.
create unique index if not exists bonus_role_account_map_active_uniq
  on public.bonus_role_account_map (company_id, role, is_active)
  where is_active;

-- The same GL account may not serve two active roles within one company.
create unique index if not exists bonus_role_account_map_account_uniq
  on public.bonus_role_account_map (company_id, account_id, is_active)
  where is_active;

create index if not exists bonus_role_account_map_role_idx
  on public.bonus_role_account_map (company_id, role, is_active);

-- FK enforcement follows the 0018 idiom: NOT VALID, then validated.
alter table public.bonus_role_account_map
  add constraint bonus_role_account_map_company_fk
  foreign key (company_id) references public.financial_companies(id)
  not valid;
alter table public.bonus_role_account_map
  validate constraint bonus_role_account_map_company_fk;

alter table public.bonus_role_account_map
  add constraint bonus_role_account_map_account_fk
  foreign key (account_id) references public.financial_accounts(id)
  not valid;
alter table public.bonus_role_account_map
  validate constraint bonus_role_account_map_account_fk;

-- Only bind to a postable account (a closed/non-postable account is unusable).
-- CHECK constraints cannot contain subqueries in PostgreSQL, so enforce the
-- postable requirement with a BEFORE INSERT OR UPDATE trigger instead.
create or replace function public.bonus_role_account_map_postable_enforce()
returns trigger
language plpgsql
as $fn$
begin
  if NEW.is_active is true then
    if not exists (
      select 1 from public.financial_accounts a
       where a.id = NEW.account_id and a.is_postable
    ) then
      raise exception 'Cannot map role to non-postable account % (company %)', NEW.account_id, NEW.company_id;
    end if;
  end if;
  return NEW;
end $fn$;

create trigger trg_bonus_role_account_map_postable
before insert or update on public.bonus_role_account_map
for each row execute function public.bonus_role_account_map_postable_enforce();

-- ── 2) journal leg mapping (process, option) → (debit_role, credit_role) ────────
--     This is the configurable layout that replaces every hardcoded account code
--     in the posting logic. A director defines: for event E1, option A, the debit
--     leg is the 'cash' role and the credit leg is the 'deferred_bonus_liability'
--     role. Both roles are then resolved to GL account codes via
--     bonus_role_account_map (table 1 above). The resolved codes are snapshotted
--     per-earn by apply_bonus_earn_accounting (0030) so later rebinding never
--     changes an already-decided earn's legs.
--
--     debit_role / credit_role are NULL when the option produces no journal
--     (e.g. BD-01 C = no_entry). At least one must be non-NULL for any option that
--     produces a journal.
create table if not exists public.bonus_journal_leg_mapping (
  id              uuid primary key default gen_random_uuid(),
  company_id      uuid not null references public.financial_companies(id),
  process         text not null,                      -- e.g. 'EARN', 'WITHDRAWAL', ...
  option          text not null,                      -- BD-XX policy option letter (A/B/C)
  debit_role      text,                               -- → bonus_role_account_map role; NULL = no debit leg
  credit_role     text,                               -- → bonus_role_account_map role; NULL = no credit leg
  is_active       boolean not null default true,
  idempotency_key text unique,
  created_by      uuid references public.users(id) on delete set null,
  updated_by      uuid references public.users(id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- One active layout per (company, process, option).
create unique index if not exists bonus_journal_leg_mapping_active_uniq
  on public.bonus_journal_leg_mapping (company_id, process, option, is_active)
  where is_active;

create index if not exists bonus_journal_leg_mapping_lookup_idx
  on public.bonus_journal_leg_mapping (company_id, process, option);

-- FK (NOT VALID then validate, 0018 idiom).
alter table public.bonus_journal_leg_mapping
  add constraint bonus_journal_leg_mapping_company_fk
  foreign key (company_id) references public.financial_companies(id)
  not valid;
alter table public.bonus_journal_leg_mapping
  validate constraint bonus_journal_leg_mapping_company_fk;

-- ── 3) RLS: director-only on both tables ─────────────────────────────────────────
alter table public.bonus_role_account_map enable row level security;
alter table public.bonus_journal_leg_mapping enable row level security;

drop policy if exists "bonus_role_account_map_director_select" on public.bonus_role_account_map;
create policy "bonus_role_account_map_director_select" on public.bonus_role_account_map
  for select using (public.current_user_role() = 'company_director');

drop policy if exists "bonus_role_account_map_director_modify" on public.bonus_role_account_map;
create policy "bonus_role_account_map_director_modify" on public.bonus_role_account_map
  for all using (public.current_user_role() = 'company_director')
  with check (public.current_user_role() = 'company_director');

drop policy if exists "bonus_journal_leg_mapping_director_select" on public.bonus_journal_leg_mapping;
create policy "bonus_journal_leg_mapping_director_select" on public.bonus_journal_leg_mapping
  for select using (public.current_user_role() = 'company_director');

drop policy if exists "bonus_journal_leg_mapping_director_modify" on public.bonus_journal_leg_mapping;
create policy "bonus_journal_leg_layout_director_modify" on public.bonus_journal_leg_mapping
  for all using (public.current_user_role() = 'company_director')
  with check (public.current_user_role() = 'company_director');

revoke all on public.bonus_role_account_map from public;
grant select on public.bonus_role_account_map to authenticated;
revoke all on public.bonus_journal_leg_mapping from public;
grant select on public.bonus_journal_leg_mapping to authenticated;

-- ── 4) role account map RPCs (generalized — any role string accepted) ──────────
create or replace function public.upsert_bonus_role_account_map(
  p_company_id      uuid,
  p_role            text,
  p_account_id      uuid,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_actor   uuid := auth.uid();
  v_map_id  uuid;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can manage role account mappings';
  end if;
  if p_role is null or trim(p_role) = '' then
    raise exception 'p_role must be a non-empty role name';
  end if;

  if not exists (select 1 from public.financial_companies c where c.id = p_company_id) then
    raise exception 'Unknown financial company: %', p_company_id;
  end if;

  if not exists (
    select 1 from public.financial_accounts a
     where a.id = p_account_id and a.company_id = p_company_id and a.is_postable
  ) then
    raise exception 'Account % is not a postable account of company %', p_account_id, p_company_id;
  end if;

  -- Idempotency: exact replay is a true no-op — return that row WITHOUT
  -- mutating the active bindings (checked before soft-disable).
  if p_idempotency_key is not null then
    select id into v_map_id
      from public.bonus_role_account_map
     where idempotency_key = p_idempotency_key
     limit 1;
    if found then
      return v_map_id;
    end if;
  end if;

  -- One active mapping per (company, role): soft-disable the current active binding.
  update public.bonus_role_account_map
     set is_active = false,
         updated_by = v_actor,
         updated_at = now()
   where company_id = p_company_id and role = p_role and is_active;

  insert into public.bonus_role_account_map
    (company_id, role, account_id, is_active, created_by, updated_by, idempotency_key)
  values
    (p_company_id, p_role, p_account_id, true, v_actor, v_actor, p_idempotency_key)
  returning id into v_map_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value, reference)
  values ('bonus_role_account_map', v_map_id, 'ROLE_ACCOUNT_MAPPING_UPSERT', v_actor,
          null,
          jsonb_build_object('company_id', p_company_id, 'role', p_role, 'account_id', p_account_id),
          p_idempotency_key);

  return v_map_id;
end $fn$;

create or replace function public.delete_bonus_role_account_map(
  p_company_id uuid,
  p_role       text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can manage role account mappings';
  end if;
  if p_role is null or trim(p_role) = '' then
    raise exception 'p_role must be a non-empty role name';
  end if;

  update public.bonus_role_account_map
     set is_active = false,
         updated_by = v_actor,
         updated_at = now()
   where company_id = p_company_id and role = p_role and is_active;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, reason, reference)
  values ('bonus_role_account_map', null, 'ROLE_ACCOUNT_MAPPING_DELETE', v_actor,
          format('soft-deleted role %s for company %s (0 rows affected if already unmapped)', p_role, p_company_id),
          p_role);

  return found;
end $fn$;

create or replace function public.get_bonus_role_account_map(
  p_company_id uuid,
  p_role       text
)
returns table (
  map_id       uuid,
  account_id   uuid,
  account_code text,
  account_name text,
  is_active    boolean
)
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can read role account mappings';
  end if;
  if p_role is null or trim(p_role) = '' then
    raise exception 'p_role must be a non-empty role name';
  end if;
  return query
  select m.id, m.account_id, a.code, a.name, m.is_active
    from public.bonus_role_account_map m
    join public.financial_accounts a on a.id = m.account_id
   where m.company_id = p_company_id
     and m.role = p_role
     and m.is_active
   order by m.updated_at desc
   limit 1;
end $fn$;

-- ── 5) journal leg layout RPCs (new — manage per-option Debit/Credit roles) ─────
create or replace function public.upsert_journal_leg_layout(
  p_company_id      uuid,
  p_process         text,
  p_option          text,
  p_debit_role      text,
  p_credit_role     text,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_actor uuid := auth.uid();
  v_id    uuid;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can manage journal leg layouts';
  end if;
  if not exists (select 1 from public.financial_companies c where c.id = p_company_id) then
    raise exception 'Unknown financial company: %', p_company_id;
  end if;
  if p_process is null or trim(p_process) = '' then
    raise exception 'p_process must be a non-empty event name (e.g. EARN)';
  end if;
  if p_option is null or trim(p_option) = '' then
    raise exception 'p_option must be a non-empty option letter';
  end if;

  -- Idempotency: exact replay is a true no-op.
  if p_idempotency_key is not null then
    select id into v_id
      from public.bonus_journal_leg_mapping
     where idempotency_key = p_idempotency_key
     limit 1;
    if found then
      return v_id;
    end if;
  end if;

  -- One active layout per (company, process, option): soft-disable the current.
  update public.bonus_journal_leg_mapping
     set is_active = false,
         updated_by = v_actor,
         updated_at = now()
   where company_id = p_company_id and process = p_process and option = p_option and is_active;

  insert into public.bonus_journal_leg_mapping
    (company_id, process, option, debit_role, credit_role, is_active, created_by, updated_by, idempotency_key)
  values
    (p_company_id, p_process, p_option, p_debit_role, p_credit_role, true, v_actor, v_actor, p_idempotency_key)
  returning id into v_id;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value, reference)
  values ('bonus_journal_leg_mapping', v_id, 'JOURNAL_LEG_LAYOUT_UPSERT', v_actor,
          null,
          jsonb_build_object('company_id', p_company_id, 'process', p_process, 'option', p_option,
                             'debit_role', p_debit_role, 'credit_role', p_credit_role),
          p_idempotency_key);

  return v_id;
end $fn$;

create or replace function public.delete_journal_leg_layout(
  p_company_id uuid,
  p_process    text,
  p_option     text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can manage journal leg layouts';
  end if;

  update public.bonus_journal_leg_mapping
     set is_active = false,
         updated_by = v_actor,
         updated_at = now()
   where company_id = p_company_id and process = p_process and option = p_option and is_active;

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, reason, reference)
  values ('bonus_journal_leg_mapping', null, 'JOURNAL_LEG_LAYOUT_DELETE', v_actor,
          format('soft-deleted layout process=%s option=%s company=%s (0 rows if absent)', p_process, p_option, p_company_id),
          jsonb_build_object('process', p_process, 'option', p_option));

  return found;
end $fn$;

create or replace function public.get_journal_leg_layout(
  p_company_id uuid,
  p_process    text,
  p_option     text
)
returns table (
  layout_id   uuid,
  debit_role  text,
  credit_role text,
  is_active   boolean
)
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can read journal leg layouts';
  end if;
  return query
  select m.id, m.debit_role, m.credit_role, m.is_active
    from public.bonus_journal_leg_mapping m
   where m.company_id = p_company_id
     and m.process = p_process
     and m.option = p_option
     and m.is_active
   order by m.updated_at desc
   limit 1;
end $fn$;

-- ── 6) Grants mirror the existing bonus_ledger RPC pattern (0019:619-624) ──────────
revoke all on function public.upsert_bonus_role_account_map(uuid, text, uuid, text) from public;
revoke all on function public.delete_bonus_role_account_map(uuid, text) from public;
revoke all on function public.get_bonus_role_account_map(uuid, text) from public;
grant execute on function public.upsert_bonus_role_account_map(uuid, text, uuid, text) to authenticated;
grant execute on function public.delete_bonus_role_account_map(uuid, text) to authenticated;
grant execute on function public.get_bonus_role_account_map(uuid, text) to authenticated;

revoke all on function public.upsert_journal_leg_layout(uuid, text, text, text, text, text) from public;
revoke all on function public.delete_journal_leg_layout(uuid, text, text) from public;
revoke all on function public.get_journal_leg_layout(uuid, text, text) from public;
grant execute on function public.upsert_journal_leg_layout(uuid, text, text, text, text, text) to authenticated;
grant execute on function public.delete_journal_leg_layout(uuid, text, text) to authenticated;
grant execute on function public.get_journal_leg_layout(uuid, text, text) to authenticated;
