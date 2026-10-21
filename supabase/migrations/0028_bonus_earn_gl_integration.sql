-- =============================================================
-- Migration 0028 — Bonus Earn (E1) → General Ledger accounting integration
-- Phase 1 (Accounting Integration Gap Audit → implementation).
--
-- WHY (evidence: Accounting Integration Gap Audit; the BD-01 accounting-policy
-- registry in artifacts/pharma-pwa/src/lib/accountingPolicies.ts; the pure
-- engine artifacts/pharma-pwa/src/lib/bonusAccountingPolicy.ts; the live wiring
-- artifacts/pharma-pwa/src/lib/bonusAccountingPolicyLive.ts; the posting guards
-- 0010:create_financial_journal_entry (0010:291) and
-- 0024:post_financial_journal_entry (0024:43); current_user_role() at 0001:52):
--
--   The Bonus E1 path is `bonus_on_order_delivered` (0019:463) →
--   `bonus_evaluate_order_earn` (0019:220), which INSERTs a POSTED 'EARN' row
--   into bonus_ledger (0019:397-403) under idempotency_key
--   'SALES_EARN:<order_id>:<rule_id>' (0019:386). That row is the financial
--   truth of a bonus earn and the only stable identity a GL integration can
--   be tied to (§7 source-trace requirement).
--
--   Posting to the General Ledger requires director authority: BOTH
--   create_financial_journal_entry and post_financial_journal_entry are
--   director-only via `current_user_role() <> 'company_director'` (0010:291 /
--   0024:43), and current_user_role() reads `auth.uid()` (the JWT session role,
--   0001:52) — so it CANNOT be bypassed by SECURITY DEFINER. E1 fires from a
--   driver/branch_manager session, where current_user_role() returns
--   'driver'/'branch_manager' and therefore posting is structurally impossible
--   (§6: leave the path closed and log the obstacle, never weaken authority).
--
--   The pure BD-01 engine (bonusAccountingPolicy.ts) is faithful on this exact
--   point: it never fabricates a journal (`journalEntryId: null` for every
--   option, lines 110/300-313) and its A/B dispatch yields
--   `would_post` + ACCOUNT_MAPPING_REQUIRED because the seeded COA (0007:38-59)
--   lacks a bonus-liability account. This migration is the SQL-resident
--   "separate authorised layer" that layer defers to (its docstring: "Actual
--   posting lives in a separate, authorised layer … out of scope").
--
-- WHAT THIS FILE ADDS (additive only — new DB objects, 0 tracked object modified):
--   1. apply_bonus_earn_accounting(p_ledger_id uuid) -> jsonb  (SECURITY DEFINER)
--      The decision hook. Reads BD-01/BD-08/BD-09/BD-10 live (no defaults), takes
--      ONLY the ledger id (no account/amount parameters — clients cannot choose
--      accounts or amounts, §7 #8), snapshots the resolved BD-01 option to
--      `accounting_policy.snapshot.<ledgerId>` (history-locked, first-wins),
--      records the faithful outcome (would_post / no_entry / fail_closed + the
--      real infra/authority/valuation sentinels), and writes it to
--      bonus_audit_trail. It NEVER calls create/post_financial_journal_entry
--      and NEVER creates a journal entry — not even a draft — because the E1
--      session cannot satisfy (a) director-only posting authority, (b) the
--      ACC-03 debit/credit valuation basis, or (c) a scheduling engine for any
--      periodic/aggregated option (§4: no financially-successful result when
--      timing/aggregation/posting is unavailable).
--   2. bonus_on_ledger_earn_posted()  (SECURITY DEFINER trigger wrapper)
--      Calls (1) inside a sub-transaction and SWALLOWS every exception, logging
--      EARN_ACCOUNTING_ERROR to bonus_audit_trail. The Bonus Earn commit is
--      therefore NEVER blocked by the accounting layer (§2/§7 non-blocking +
--      fail-closed).
--   3. trg_bonus_earn_accounting  AFTER INSERT ON bonus_ledger
--      FOR EACH ROW WHEN (status='POSTED' AND txn_type='EARN') — fires on the
--      real E1 POSTED write, not on PENDING reservations. The pre-fix
--      trg_bonus_ledger_immutable (BEFORE UPDATE/DELETE, 0024) is untouched;
--      this is a strictly additional AFTER INSERT trigger.
--
-- IDEMPOTENCY / HISTORY (§7): a recorded DECISION is never re-evaluated (the
-- audit trail is the dedup key; the option snapshot is ON CONFLICT DO NOTHING).
-- A policy change after the earn therefore cannot reprocess or duplicate the
-- decision. Re-delivery of the same order hits bonus_ledger.idempotency_key
-- (0018:73), produces no new row, and the AFTER INSERT trigger does not fire,
-- so no second decision and no journal can arise (§7 #2).
--
-- NO production change. Apply only to an isolated scratch database.
-- =============================================================

-- ── 1) Decision hook ────────────────────────────────────────────────────────
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
  v_liab_code           text;
  v_expense_code        text;
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
    -- Idempotency / history protection (§7): a recorded decision is never
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

      -- (3) Resolve the account ROLE the BD-01 option requires.
      --     A = deferred_bonus_liability -> 2110 (seeded by 0017);
      --     B = bonus_expense           -> 6000 (seeded by 0007).
      select code into v_liab_code
        from public.financial_accounts where company_id = v_company and code = '2110';
      select code into v_expense_code
        from public.financial_accounts where company_id = v_company and code = '6000';

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
      v_effect := 'would_post';
      if v_option = 'A' then
        v_intended := jsonb_build_array(jsonb_build_object('role', 'deferred_bonus_liability', 'code', v_liab_code));
        if v_liab_code is null then
          v_code := 'ACCOUNT_MAPPING_REQUIRED';
          v_reason := 'BD-01 A requires a deferred_bonus_liability account (2110); not seeded — refusing to fabricate.';
          exit resolve;
        end if;
        -- Liability role resolves. The actual POST is director-only
        -- (post_financial_journal_entry, 0024:43) and E1 runs as
        -- driver/branch_manager (JWT-scoped current_user_role, 0001:52) → the
        -- post can never run from E1 (§6). The credit/valuation basis is the
        -- out-of-scope ACC-03 layer.
        if v_bd08 = 'C' then
          v_code := 'TIMING_INFRASTRUCTURE_REQUIRED';
          v_reason := 'BD-08 C (periodic netting) requires a scheduler; none exists (no pg_cron/pgAgent).';
        elsif v_bd09 = 'C' then
          v_code := 'POSTING_INFRASTRUCTURE_REQUIRED';
          v_reason := 'BD-09 C (periodic netting) requires a scheduler plus a company-scoped netting key; bonus_ledger has no company_id (ACC-10).';
        elsif v_bd08 = 'A' then
          v_code := 'POSTING_AUTHORITY_REQUIRED';
          v_reason := 'BD-08 A posts immediately, but posting is director-only (0024:43) and E1 runs non-director (current_user_role is JWT-scoped) — authority un-bypassable.';
        else
          -- BD-08 B (draft-at-event): needs a balanced DR/CR; the CR offset is the
          -- ACC-03 valuation basis, which is out of scope.
          v_code := 'ACCOUNT_MAPPING_REQUIRED';
          v_reason := 'BD-08 B drafts at event, but BD-01 A credit offset is the ACC-03 valuation basis (out of scope); cannot form a balanced entry.';
        end if;
        exit resolve;
      else
        -- v_option = 'B'
        v_intended := jsonb_build_array(jsonb_build_object('role', 'bonus_expense', 'code', v_expense_code));
        if v_expense_code is null then
          v_code := 'ACCOUNT_MAPPING_REQUIRED';
          v_reason := 'BD-01 B requires a bonus_expense account (6000); not seeded — refusing to fabricate.';
          exit resolve;
        end if;
        if v_bd08 = 'C' then
          v_code := 'TIMING_INFRASTRUCTURE_REQUIRED';
          v_reason := 'BD-08 C (periodic netting) requires a scheduler; none exists.';
        elsif v_bd09 = 'C' then
          v_code := 'POSTING_INFRASTRUCTURE_REQUIRED';
          v_reason := 'BD-09 C (periodic netting) requires a scheduler plus a company-scoped netting key (ACC-10).';
        else
          -- DR bonus_expense (6000) resolves; CR offset is unspecified by the
          -- registry (ACC-03 valuation basis, out of scope).
          v_code := 'ACCOUNT_MAPPING_REQUIRED';
          v_reason := 'BD-01 B expense role resolves (6000) but its credit offset is unspecified (ACC-03 valuation basis out of scope); cannot form a balanced entry.';
        end if;
        exit resolve;
      end if;
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

  return v_decision;
end $fn$;

-- ── 2) Non-blocking AFTER INSERT trigger wrapper ─────────────────────────────
--    Swallows every exception so a failure in policy resolution can NEVER roll
--    back or block the Bonus Earn (§2/§7). A swallowed error is itself logged to
--    bonus_audit_trail as EARN_ACCOUNTING_ERROR.
create or replace function public.bonus_on_ledger_earn_posted()
returns trigger
language plpgsql
security definer
set search_path = public
as $fn$
begin
  if (NEW.status = 'POSTED' and NEW.txn_type = 'EARN') then
    begin
      perform public.apply_bonus_earn_accounting(NEW.id);
    exception
      when others then
        -- Inner audit is in its own sub-transaction so that even a failure to
        -- write the audit trail cannot escape and block the earn.
        begin
          insert into public.bonus_audit_trail
            (entity, entity_id, action, actor, reason)
          values ('bonus_ledger_accounting', NEW.id, 'EARN_ACCOUNTING_ERROR',
                  NEW.actor, 'apply_bonus_earn_accounting threw (swallowed, earn not blocked): ' || sqlerrm);
        exception when others then
          null;
        end;
    end;
  end if;
  return NEW;
end $fn$;

-- ── 3) Trigger on the real E1 POSTED write ──────────────────────────────────
--    Fires only on the actual E1 commit (POSTED EARN), never on PENDING
--    reservation rows. The pre-fix trg_bonus_ledger_immutable (BEFORE
--    UPDATE/DELETE) is left untouched; this is a strictly additional AFTER
--    INSERT trigger.
drop trigger if exists trg_bonus_earn_accounting on public.bonus_ledger;
create trigger trg_bonus_earn_accounting
  after insert on public.bonus_ledger
  for each row
  when (NEW.status = 'POSTED' and NEW.txn_type = 'EARN')
  execute function public.bonus_on_ledger_earn_posted();

-- ── 4) Grants mirror the existing bonus_ledger RPC pattern (0019:619-624):
--    revoke all from public, then grant execute to authenticated. The trigger
--    function needs no grant (PostgreSQL does not enforce execute privilege on
--    trigger functions). apply_bonus_earn_accounting is RPC-callable for the
--    live E2 seam / future wiring, but NEVER posts a journal.
revoke all on function public.apply_bonus_earn_accounting(uuid) from public;
revoke all on function public.bonus_on_ledger_earn_posted() from public;
grant execute on function public.apply_bonus_earn_accounting(uuid) to authenticated;
grant execute on function public.bonus_on_ledger_earn_posted() to authenticated;
