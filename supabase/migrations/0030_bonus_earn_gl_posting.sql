-- =============================================================
-- Migration 0030 — Bonus Earn (E1) → GL: posting table + director post RPC
-- Phase 3 of the E1 accounting integration (extends 0028, adds the GL link
-- table and the director-scoped posting RPC).
--
-- WHY (re-statement of the authority constraint — see 0028 header lines
-- 19-34): current_user_role() reads the JWT session role (0001:52). Both
-- create_financial_journal_entry (0010:291) and post_financial_journal_entry
-- (0024:43) enforce `current_user_role() <> 'company_director'` IN THE BODY,
-- which is NOT RLS and therefore NOT bypassable by SECURITY DEFINER. The E1
-- trigger fires under a driver/branch_manager session, so the trigger CANNOT
-- post a GL journal — posting must be a separate, director-scoped flow.
--
--   0028 = fail-closed decision + PENDING request (this file extends it to
--          write a PENDING link, and to resolve BOTH debit/credit legs from
--          the configurable journal leg mapping — no hardcoded account codes).
--   0030 = the director RPC that satisfies a PENDING request by calling
--          create_financial_journal_entry + post_financial_journal_entry under
--          the director's OWN JWT.
--
-- WHY NO hardcode (the admin control gap fix):
--   Previously post_bonus_earn_to_gl hardcoded '1110' (cash) as the debit/credit
--   offset for BOTH BD-01 option A (Dr 1110) and option B (Cr 1110). Now EVERY
--   journal leg is driven by configuration:
--     bonus_journal_leg_mapping (process=EARN, option) → (debit_role, credit_role)
--     bonus_role_account_map  (company, role)         → account_id
--   apply_bonus_earn_accounting resolves the layout → roles → account codes and
--   SNAPSHTS both codes into the decision (bonus_earn_gl_postings.decision).
--   post_bonus_earn_to_gl reads the codes from that snapshot — it never
--   hardcodes '1110', '2110', '6000', or any account ID. Changing the cash
--   role's account after the earn is decided cannot alter the posted journal.
--
-- WHY NO auto-seed: the seeded COA has no customer-bonus liability account
-- (2100 = supplier payables per PHASE-49 §5.2 obs#1; 126000 = doctor
-- commissions; 6000 = generic expense; 4000 = revenue; 1110/1120 = cash/bank
-- seeded by 0007/0010). The director binds roles to accounts via 0029 and
-- configures the leg layout via 0029's bonus_journal_leg_mapping. Until both
-- are configured, 0028 stays ACCOUNT_MAPPING_REQUIRED and writes no link.
--
-- WHAT THIS FILE ADDS (additive only):
--   1. bonus_earn_gl_postings — a single row per E1 earn, holding the BD-01
--      decision snapshot (including debit_account_code / credit_account_code
--      resolved at decision time) + status PENDING|POSTED|FAILED + the
--      resulting journal_entry_id. The trigger (0028) writes PENDING; the
--      director RPC flips it to POSTED (or FAILED on error).
--   2. CREATE OR REPLACE apply_bonus_earn_accounting — resolves BOTH legs via
--      bonus_journal_leg_mapping + bonus_role_account_map (no hardcoded codes),
--      stores resolved codes in the snapshot, and writes the fail-closed
--      PENDING link on the single gate (both roles mapped + BD-08 A immediate).
--   3. post_bonus_earn_to_gl(p_ledger_id) — SECURITY DEFINER, director-only in
--      body (JWT-scoped gate). Reads account codes from the decision snapshot
--      (never hardcoded), builds a BALANCED Dr/Cr (§7 #4), creates a draft journal
--      via create_financial_journal_entry, posts it via
--      post_financial_journal_entry, then flips the link to POSTED + audits.
--      Any error flips the link to FAILED and re-raises (no partial journal).
--
-- NO production change. Apply only to an isolated scratch database.
-- =============================================================

-- ── 1) PENDING request ledger (one row per E1 earn) ──────────────────────────────
create table if not exists public.bonus_earn_gl_postings (
  ledger_id        uuid primary key references public.bonus_ledger(id) on delete cascade,
  journal_entry_id uuid references public.financial_journal_entries(id) on delete set null,
  status           text not null default 'PENDING'
                    check (status in ('PENDING', 'POSTED', 'FAILED')),
  decision         jsonb not null,                 -- the BD-01 decision snapshot (from 0028/0030)
  idempotency_key  text unique,
  requested_at     timestamptz not null default now(),
  requested_by     uuid references public.users(id) on delete set null,
  posted_at        timestamptz,
  posted_by        uuid references public.users(id) on delete set null
);

create index if not exists bonus_earn_gl_postings_status_idx
  on public.bonus_earn_gl_postings (status);
create index if not exists bonus_earn_gl_postings_journal_idx
  on public.bonus_earn_gl_postings (journal_entry_id);

-- ── 2) apply_bonus_earn_accounting: resolve BOTH legs from layout + write PENDING ──
--     Full-body REPLACE of the 0028 function. Everything from 0028 is preserved;
--     only the account resolution (was hardcoded 2110/6000, now layout-driven) and
--     the addition of the fail-closed PENDING link are changed. 0028's
--     journalEntryId=null contract and fail-closed semantics are intact.
create or replace function public.apply_bonus_earn_accounting(p_ledger_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_ledger              public.bonus_ledger%rowtype;
  v_option              text;                          -- BD-01 option once resolved
  v_bd01  text;
  v_bd08  text;
  v_bd09  text;
  v_company             uuid;
  v_company_count       int;
  v_company_resolution  text := '';
  v_debit_role          text;                         -- layout-defined debit role (from 0029 bonus_journal_leg_mapping)
  v_credit_role         text;                         -- layout-defined credit role
  v_debit_code          text;                         -- resolved debit account code (from bonus_role_account_map)
  v_credit_code         text;                         -- resolved credit account code
  v_effect              text;                          -- 'no_entry' | 'would_post' | 'fail_closed'
  v_code                text := null;
  v_reason              text := '';
  v_intended            jsonb := '[]'::jsonb;
  v_diagnostics         jsonb := '[]'::jsonb;
  v_journal_id          uuid := null;                  -- never set (no journal created in Phase 1)
  v_decision            jsonb;
  v_snapshot_key        text;
  v_existing            jsonb;
begin
  -- E1 identity guard: must resolve to a POSTED EARN row.
  select * into v_ledger from public.bonus_ledger where id = p_ledger_id;
  if not found or v_ledger.txn_type <> 'EARN' or v_ledger.status <> 'POSTED' then
    v_effect := 'fail_closed';
    v_code := 'NOT_AN_EARN_EVENT';
    v_reason := 'ledger row is not a POSTED EARN event; refusing to account for it.';
  else
    -- Idempotency / history protection (§7): a recorded DECISION is never
    -- re-evaluated. The audit row is the dedup key.
    v_snapshot_key := 'accounting_policy.snapshot.' || p_ledger_id::text;
    select new_value into v_existing
      from public.bonus_audit_trail
     where entity = 'bonus_ledger_accounting'
       and entity_id = p_ledger_id
       and action = 'EARN_ACCOUNTING_DECISION'
     order by at_time limit 1;
    if found then
      -- No second journal, no second decision. Replays return the prior record.
      return v_existing || jsonb_build_object('alreadyDecided', true, 'replayed', true);
    end if;

    <<resolve>>
    begin
      -- (1) BD-01 — primary earn policy. Fail closed, NO default.
      v_bd01 := nullif(trim(both '"' from (select value::text
                                           from public.bonus_settings
                                          where key = 'accounting_policy.BD-01')), '');
      if v_bd01 is null then
        v_effect := 'fail_closed';
        v_code := 'ACCOUNTING_POLICY_NOT_CONFIGURED';
        v_reason := 'BD-01 is not configured; refusing to assume a policy.';
        exit resolve;
      end if;
      if v_bd01 not in ('A', 'B', 'C') then
        v_effect := 'fail_closed';
        v_code := 'INVALID_ACCOUNTING_POLICY';
        v_reason := format('BD-01 option "%s" is not a registered alternative.', v_bd01);
        exit resolve;
      end if;
      v_option := v_bd01;

      -- BD-01 C — no recognition at grant (owner-decided, ACC-01). Realisable today.
      if v_option = 'C' then
        v_effect := 'no_entry';
        v_reason := 'BD-01 Option C — no accounting recognition at grant (ACC-01). No journal created by design.';
        exit resolve;
      end if;

      -- (2) BD-10 company attribution — C-3 single-company resolution
      --     (bonusAccountingPolicyLive.ts readCurrentCompanyId:
      --      financial_companies order by created_at limit 1).
      select count(*) into v_company_count from public.financial_companies;
      if v_company_count = 0 then
        v_effect := 'fail_closed';
        v_code := 'COMPANY_POLICY_ISOLATION_GAP';
        v_reason := 'No financial company seeded; cannot attribute the earn (ACC-10).';
        exit resolve;
      elsif v_company_count > 1 then
        v_effect := 'fail_closed';
        v_code := 'COMPANY_POLICY_ISOLATION_GAP';
        v_reason := format('Company count is %s; C-3 single-company attribution is ambiguous (ACC-10).', v_company_count);
        exit resolve;
      else
        select id into v_company
          from public.financial_companies order by created_at limit 1;
        v_company_resolution := 'C-3 single-company (financial_companies order by created_at limit 1)';
        -- bonus_settings has no company_id (0018; PHASE-49 §1.4): emit as a
        -- warning diagnostic, not a block (mirrors the pure live wiring).
        v_diagnostics := v_diagnostics || to_jsonb('COMPANY_POLICY_ISOLATION_GAP'::text);
      end if;

      -- (3) Resolve the journal leg LAYOUT for this option (0029
      --     bonus_journal_leg_mapping). NO hardcoded account codes — the layout
      --     defines which ROLES are the debit and credit legs. If no layout is
      --     configured for this (process, option), fail closed.
      select m.debit_role, m.credit_role into v_debit_role, v_credit_role
        from public.bonus_journal_leg_mapping m
       where m.company_id = v_company
         and m.process = 'EARN'
         and m.option = v_option
         and m.is_active;
      if not found then
        v_effect := 'fail_closed';
        v_code := 'JOURNAL_LAYOUT_NOT_CONFIGURED';
        v_reason := format('No active journal leg layout for EARN option %s — configure via the director Control Center (AccountingSection).', v_option);
        exit resolve;
      end if;

      -- (3a) Resolve each leg's role to an account code via bonus_role_account_map
      --      (0029). No auto-seed: an unmapped role is structurally
      --      ACCOUNT_MAPPING_REQUIRED. financial_accounts.code is what the journal
      --      builder (fn_financial_auto_entry, 0009:84-85) ultimately needs.
      v_debit_code := null;
      v_credit_code := null;
      if v_debit_role is not null then
        select fa.code into v_debit_code
          from public.bonus_role_account_map m
          join public.financial_accounts fa on fa.id = m.account_id
         where m.company_id = v_company
           and m.role = v_debit_role
           and m.is_active;
      end if;
      if v_credit_role is not null then
        select fa.code into v_credit_code
          from public.bonus_role_account_map m
          join public.financial_accounts fa on fa.id = m.account_id
         where m.company_id = v_company
           and m.role = v_credit_role
           and m.is_active;
      end if;

      -- Build the intended accounts array (both legs, with leg direction + resolved code).
      if v_debit_role is not null or v_credit_role is not null then
        v_intended := jsonb_build_array(
          jsonb_build_object('role', v_debit_role,  'leg', 'debit',  'code', v_debit_code),
          jsonb_build_object('role', v_credit_role, 'leg', 'credit', 'code', v_credit_code)
        );
      end if;

      -- (4) BD-08 timing + BD-09 aggregation (Phase-1 SQL posting gate; the pure
      --     BD-01 engine defers timing to this authorised layer, §4).
      v_bd08 := nullif(trim(both '"' from (select value::text
                                          from public.bonus_settings
                                         where key = 'accounting_policy.BD-08')), '');
      v_bd09 := nullif(trim(both '"' from (select value::text
                                          from public.bonus_settings
                                         where key = 'accounting_policy.BD-09')), '');
      if v_bd08 is null or v_bd08 not in ('A', 'B', 'C') then
        v_effect := 'fail_closed';
        v_code := 'ACCOUNTING_POLICY_NOT_CONFIGURED';
        v_reason := 'BD-08 timing is not configured; cannot schedule E1 posting.';
        exit resolve;
      end if;
      if v_bd09 is null or v_bd09 not in ('A', 'B', 'C') then
        v_effect := 'fail_closed';
        v_code := 'ACCOUNTING_POLICY_NOT_CONFIGURED';
        v_reason := 'BD-09 aggregation is not configured; cannot batch E1 posting.';
        exit resolve;
      end if;

      -- (5) Dispatch BD-01 A / B (C already handled above).
      --     For journal-producing options, BOTH legs must be mapped.
      v_effect := 'would_post';
      if (v_debit_role is not null and v_debit_code is null)
         or (v_credit_role is not null and v_credit_code is null) then
        v_code := 'ACCOUNT_MAPPING_REQUIRED';
        v_reason := format('BD-01 %s requires roles "%s" (debit) and "%s" (credit) to both be mapped via the role→account designation; at least one is unmapped — refusing to fabricate.', v_option, v_debit_role, v_credit_role);
        exit resolve;
      end if;

      -- Both legs resolved. The actual POST is director-only
      -- (post_financial_journal_entry, 0024:43) and E1 runs as
      -- driver/branch_manager (JWT-scoped current_user_role, 0001:52) → the
      -- post can never run from E1 (§6). The valuation basis is the
      -- out-of-scope ACC-03 layer. Timing gates below select the right code.
      if v_bd08 = 'C' then
        v_code := 'TIMING_INFRASTRUCTURE_REQUIRED';
        v_reason := 'BD-08 C (periodic netting) requires a scheduler; none exists (no pg_cron/pgAgent).';
      elsif v_bd09 = 'C' then
        v_code := 'POSTING_INFRASTRUCTURE_REQUIRED';
        v_reason := 'BD-09 C (periodic netting) requires a scheduler plus a company-scoped netting key; bonus_ledger has no company_id (ACC-10).';
      elsif v_bd08 = 'A' then
        v_code := 'POSTING_AUTHORITY_REQUIRED';
        v_reason := format('BD-01 %s: both legs resolved (debit "%s"→%s, credit "%s"→%s); BD-08 A posts immediately, but posting is director-only (0024:43) and E1 runs non-director (JWT-scoped current_user_role, 0001:52) — authority un-bypassable.', v_option, v_debit_role, v_debit_code, v_credit_role, v_credit_code);
      else
        -- BD-08 B (draft-at-event): needs a balanced DR/CR; the valuation basis
        -- is the out-of-scope ACC-03 layer, so a balanced entry cannot be formed here.
        v_code := 'ACCOUNT_MAPPING_REQUIRED';
        v_reason := format('BD-01 %s with BD-08 B: draft-at-event requires the ACC-03 valuation basis for a balanced entry; cannot form a journal here.', v_option);
      end if;
      exit resolve;
    end;

  end if;

  -- Finalize: history-locked snapshot (option letter) + audit + return.
  -- The snapshot is stored under the engine's namespace
  -- (accounting_policy.snapshot.<ledgerId>) so the pure BD-01 resolver can read
  -- it back; ON CONFLICT DO NOTHING makes it first-wins / history-locked (§7).
  if v_option is not null then
    insert into public.bonus_settings(key, value)
      values (v_snapshot_key, to_jsonb(v_option))
      on conflict (key) do nothing;
  end if;

  v_decision := jsonb_build_object(
    'ledgerId',           p_ledger_id,
    'option',             v_option,
    'effect',             v_effect,
    'code',               v_code,
    'journalEntryId',     null,
    'effectKey',          'bd01:earn:' || p_ledger_id::text,
    'alreadyDecided',     false,
    'company_id',         v_company,
    'company_resolution', v_company_resolution,
    'timing',             v_bd08,
    'aggregation',        v_bd09,
    'debit_role',         v_debit_role,
    'credit_role',        v_credit_role,
    'debit_account_code', v_debit_code,
    'credit_account_code', v_credit_code,
    'intendedAccounts',   v_intended,
    'diagnostics',        v_diagnostics,
    'sourceTrace',        jsonb_build_object(
                            'sourceTable', 'bonus_ledger',
                            'sourceId',    p_ledger_id::text,
                            'idempotencyKey', v_ledger.idempotency_key,
                            'documentType', 'bonus_earn'),
    'journalId',          v_journal_id
  );

  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value, reason, reference)
  values ('bonus_ledger_accounting', p_ledger_id, 'EARN_ACCOUNTING_DECISION',
          v_ledger.actor, null, v_decision, v_reason, v_ledger.idempotency_key);

  -- Fail-closed PENDING request (§6): the trigger can never post a journal
  -- (JWT-scoped director gate, 0028 header 19-26). When BOTH legs are mapped and
  -- BD-08 A (immediate) is configured — i.e. authority is the ONLY remaining
  -- gate (code = POSTING_AUTHORITY_REQUIRED) — record exactly one PENDING link
  -- row that the director-scoped post_bonus_earn_to_gl (§3) will satisfy. In
  -- every other state (ACCOUNT_MAPPING_REQUIRED, TIMING_*, POSTING_*, etc.)
  -- NO link is written, so a half-configured policy never creates a postable
  -- request. Idempotent: ON CONFLICT (ledger_id) DO NOTHING. The PENDING write
  -- is the last statement before return so a failure here cannot discard the
  -- decision audit row above (the outer WHEN wrapper logs it and never blocks
  -- the earn).
  if (v_option = 'A' or v_option = 'B')
     and v_code = 'POSTING_AUTHORITY_REQUIRED' then
    insert into public.bonus_earn_gl_postings
      (ledger_id, journal_entry_id, status, decision, idempotency_key,
       requested_at, requested_by)
    values
      (p_ledger_id, null, 'PENDING', v_decision,
       'GL_POST_EARN:' || p_ledger_id::text, now(), v_ledger.actor)
    on conflict (ledger_id) do nothing;

    insert into public.bonus_audit_trail
      (entity, entity_id, action, actor, reason, reference)
    values ('bonus_earn_gl', p_ledger_id, 'EARN_GL_REQUEST',
            v_ledger.actor,
            format('E1 earn queued for director GL posting (option %s, debit %s→%s, credit %s→%s; role mapped, BD-08 A immediate)', v_option, v_debit_role, v_debit_code, v_credit_role, v_credit_code),
            v_ledger.idempotency_key);
  end if;

  return v_decision;
end $fn$;

-- The trigger wrapper + AFTER INSERT trigger from 0028 are unchanged (the
-- function they call is replaced in place; trigger name unchanged).
revoke all on function public.apply_bonus_earn_accounting(uuid) from public;
grant execute on function public.apply_bonus_earn_accounting(uuid) to authenticated;

-- ── 3) Director-only GL post RPC ─────────────────────────────────────────────────
--    Consumes a PENDING link (written by 0028 when both legs are mapped), builds
--    a BALANCED Dr/Cr journal from the earn amount (bonus_ledger.amount = gross
--    order value, ACC-03 §3 E1), and posts it under the director's own JWT, so
--    both create_financial_journal_entry (0010:291) and post_financial_journal_entry
--    (0024:43) pass their in-body director gate. Security definer only bypasses
--    RLS for table access — it does NOT bypass the JWT-scoped current_user_role()
--    gate, so a non-director session is rejected here too.
--
--    NO hardcoded account codes: the debit/credit account codes are read from the
--    decision snapshot (written by apply_bonus_earn_accounting at earn-decision
--    time). Changing the cash role's account after the earn is decided cannot
--    alter the posted journal.
create or replace function public.post_bonus_earn_to_gl(p_ledger_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $fn$
declare
  v_actor          uuid := auth.uid();
  v_ledger         public.bonus_ledger%rowtype;
  v_link           public.bonus_earn_gl_postings%rowtype;
  v_decision       jsonb;
  v_option         text;
  v_company        uuid;
  v_company_count  int;
  v_amount         numeric(12,2);
  v_debit_code     text;                           -- from the snapshot (NEVER hardcoded)
  v_credit_code    text;                           -- from the snapshot (NEVER hardcoded)
  v_lines          jsonb;
  v_eid            uuid;
  v_result         jsonb;
  v_old_status     text;
begin
  if v_actor is null then raise exception 'Authentication required'; end if;
  if public.current_user_role() <> 'company_director' then
    raise exception 'Only the company director can post bonus earns to the general ledger';
  end if;

  -- (a) The earn row must be a POSTED EARN.
  select * into v_ledger from public.bonus_ledger where id = p_ledger_id;
  if not found or v_ledger.txn_type <> 'EARN' or v_ledger.status <> 'POSTED' then
    raise exception 'Not a POSTED EARN ledger row — cannot post to GL';
  end if;

  -- (b) Read the PENDING request 0028 wrote. Idempotent: if already POSTED,
  --     return the existing journal id (single source of truth = the link row).
  select * into v_link
    from public.bonus_earn_gl_postings
   where ledger_id = p_ledger_id
   for update;
  if not found then
    raise exception 'No GL posting request for this earn — run apply_bonus_earn_accounting first (both legs may be unmapped or no journal layout configured)';
  end if;
  if v_link.status = 'POSTED' then
    return jsonb_build_object(
      'ledgerId',       p_ledger_id,
      'status',         'POSTED',
      'journalEntryId', v_link.journal_entry_id,
      'idempotent',     true,
      'option',         (v_link.decision->>'option'));
  end if;
  if v_link.status = 'FAILED' then
    raise exception 'A previous GL posting attempt for this earn FAILED — resolve the error and re-post';
  end if;
  if v_link.status <> 'PENDING' then
    raise exception 'Unexpected GL posting request status: %', v_link.status;
  end if;

  -- (c) Re-derive the decision from the snapshot stored on the link. We never
  --     trust caller-supplied amounts/options (§7 #8).
  v_decision := v_link.decision;
  v_option   := v_decision->>'option';
  if v_option not in ('A', 'B') then
    raise exception 'BD-01 option in link is not postable: %', v_option;
  end if;

  -- (d) Company (C-3 single-company).
  select count(*) into v_company_count from public.financial_companies;
  if v_company_count <> 1 then
    raise exception 'Company resolution failed (count=%s); refusing to post', v_company_count;
  end if;
  select id into v_company from public.financial_companies order by created_at limit 1;

  -- (e) Valuation = earn amount (= gross order value, ACC-03 §3 E1). Fail closed
  --     if it is absent/non-positive — we never post a zero/unknown debit/credit.
  v_amount := v_ledger.amount;
  if v_amount is null or v_amount <= 0 then
    raise exception 'Earn amount is not available — cannot form a balanced GL entry';
  end if;

  -- (f) Read the resolved debit/credit account codes FROM THE DECISION SNAPSHOT.
  --     These were frozen by apply_bonus_earn_accounting at earn-decision time,
  --     so later role→account rebinding cannot change what this earn posts.
  --     NO hardcoded codes, NO live role-map lookup. Fail closed if the snapshot
  --     is somehow incomplete.
  v_debit_code := v_decision->>'debit_account_code';
  v_credit_code := v_decision->>'credit_account_code';
  if v_debit_code is null or v_credit_code is null then
    v_old_status := v_link.status;
    update public.bonus_earn_gl_postings set status = 'FAILED', journal_entry_id = null
     where ledger_id = p_ledger_id;
    insert into public.bonus_audit_trail
      (entity, entity_id, action, actor, reason, reference)
    values ('bonus_earn_gl', p_ledger_id, 'GL_POST_FAILED', v_actor,
            format('decision snapshot missing debit/credit account codes (was %s); no journal created', v_old_status),
            v_ledger.idempotency_key);
    raise exception 'Decision snapshot is missing resolved debit/credit account codes — refused to post';
  end if;

  -- (g) Balanced Dr/Cr (§7 #4). The debit/credit account codes come from the
  --     snapshot — the director's configured layout (debit_role → account,
  --     credit_role → account). fn_financial_auto_entry resolves account_code→id
  --     (0009:84-85), §2 lines per the journal contract
  --     (account_code, debit, credit, description).
  v_lines := jsonb_build_array(
    jsonb_build_object('account_code', v_debit_code,  'debit', v_amount, 'credit', 0,
                       'description', 'نقل ربح المكافأة E1 — ' || (v_decision->>'debit_role') || ' (خط الخصم)'),
    jsonb_build_object('account_code', v_credit_code, 'debit', 0,        'credit', v_amount,
                       'description', 'نقل ربح المكافأة E1 — ' || (v_decision->>'credit_role') || ' (خط الدين)'));

  -- (h) Advisory lock on ledger_id so concurrent director posts serialize and the
  --     idempotent POSTED path is race-safe.
  perform pg_advisory_xact_lock(hashtext(p_ledger_id::text));

  -- (i) Create draft journal (director JWT → create's gate passes; the entry is
  --     inserted as status='draft' by fn_financial_auto_entry, 0009:77), then
  --     post it (director gate passes; requires OPEN period + balanced Dr=Ce,
  --     ≥2 lines — enforced by the posting fn itself). create+post are wrapped in
  --     a sub-transaction so that a posting failure (e.g. closed period,
  --     unbalanced) voids the draft entry instead of leaving a partial journal
  --     (§7 #5). The FAILED marker + audit are RETURNED (not re-raised) so they
  --     commit and the director sees the reason.
  begin
    v_eid := public.create_financial_journal_entry(
              current_date,
              'نقل ربح المكافأة E1 — ' || v_ledger.idempotency_key,
              v_lines);
    perform public.post_financial_journal_entry(v_eid);
  exception
    when others then
      -- Only a DRAFT entry can be voided ('voided' is a valid status, 0006:160;
      -- status='posted' is blocked by prevent_posted_journal_mutation). If
      -- create itself failed, v_eid is null → nothing to void.
      if v_eid is not null then
        update public.financial_journal_entries
           set status = 'voided'
         where id = v_eid;
      end if;
      update public.bonus_earn_gl_postings
         set status = 'FAILED',
             journal_entry_id = null
       where ledger_id = p_ledger_id;
      insert into public.bonus_audit_trail
        (entity, entity_id, action, actor, old_value, new_value, reason, reference)
      values ('bonus_earn_gl', p_ledger_id, 'GL_POST_FAILED', v_actor,
              case when v_eid is null then '"create_financial_journal_entry"'::jsonb
                   else '"post_financial_journal_entry"'::jsonb end,
              null,
              sqlerrm,
              v_ledger.idempotency_key);
      -- Return the failure as a result (don't re-raise): the director sees
      -- status=FAILED + reason; the marker + audit persist in the txn.
      return jsonb_build_object(
        'ledgerId', p_ledger_id,
        'status',   'FAILED',
        'reason',   sqlerrm,
        'option',   v_option,
        'amount',   v_amount);
  end;

  -- (j) Success: link the journal to the earn posting request + audit.
  update public.bonus_earn_gl_postings
     set status = 'POSTED',
         journal_entry_id = v_eid,
         posted_at = now(),
         posted_by = v_actor
   where ledger_id = p_ledger_id;

  v_result := jsonb_build_object(
    'ledgerId',       p_ledger_id,
    'status',         'POSTED',
    'journalEntryId', v_eid,
    'idempotent',     false,
    'option',         v_option,
    'amount',         v_amount,
    'company_id',     v_company,
    'debit_account_code', v_debit_code,
    'credit_account_code', v_credit_code);
  insert into public.bonus_audit_trail
    (entity, entity_id, action, actor, old_value, new_value, reference)
  values ('bonus_earn_gl', p_ledger_id, 'GL_POST', v_actor, to_jsonb(v_link.status::text), v_result, v_ledger.idempotency_key);

  return v_result;
end $fn$;

revoke all on function public.post_bonus_earn_to_gl(uuid) from public;
grant execute on function public.post_bonus_earn_to_gl(uuid) to authenticated;
