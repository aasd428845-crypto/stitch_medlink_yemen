-- PHASE 72 — migration-chain integrity assertion (ISOLATED databases only).
--
-- Purpose: fail closed if a rebuilt database ends on the PRE-0024 guard
-- bodies. The repository has two migration directories that are complementary
-- fragments, not alternatives:
--   * root  supabase/migrations/        (0001..0024, authoritative)
--   * web   Medlik-Waap/supabase/migrations/ (0001..0016, legacy fragment)
-- The interleaved order lives only in scripts/test-env/replay-chain.sh.
-- The legacy fragment still contains the pre-fix bodies in
-- Medlik-Waap/supabase/migrations/0008_financial_audit_immutability.sql and
-- 0010_financial_simple_entries.sql; if the chain is applied in the wrong
-- order (fragment after root 0024) those bodies overwrite the fix.
--
-- Run against the tip database after a replay:
--   docker exec -i <scratch> psql -U postgres -d <db> -v ON_ERROR_STOP=1 \
--     -f scripts/test-env/ph72-chain-integrity.sql
--
-- Isolation: this script only reads pg_catalog. It never writes and never
-- resolves a remote project. Do not run it against production.

do $integrity$
declare
  v_present integer;
  v_bad     text[] := array[]::text[];
  r         record;
begin
  select count(*) into v_present
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (
      'prevent_posted_journal_mutation',
      'prevent_posted_journal_line_mutation',
      'prevent_bonus_ledger_mutation',
      'post_financial_journal_entry'
    );

  if v_present <> 4 then
    raise exception
      'CHAIN INTEGRITY FAIL: expected 4 guard functions, found %', v_present;
  end if;

  for r in
    select p.proname, p.prosrc
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'prevent_posted_journal_mutation',
        'prevent_posted_journal_line_mutation',
        'prevent_bonus_ledger_mutation',
        'post_financial_journal_entry'
      )
  loop
    if r.proname = 'post_financial_journal_entry' then
      -- 0024 qualifies the period-status column; the pre-fix body selects an
      -- ambiguous unqualified `status` and aborts every posting attempt.
      if r.prosrc not like '%select p.status into v_period_status%' then
        v_bad := v_bad || r.proname;
      end if;
    else
      -- 0024 returns NEW for non-protected rows; the pre-fix body returns OLD
      -- unconditionally and silently discards every UPDATE.
      if r.prosrc not like '%return new;%' then
        v_bad := v_bad || r.proname;
      end if;
    end if;
  end loop;

  if array_length(v_bad, 1) is not null then
    raise exception
      'CHAIN INTEGRITY FAIL: pre-0024 bodies present (%); the chain was applied '
      'out of order or stopped before root 0024_fix_posted_journal_posting.sql',
      array_to_string(v_bad, ', ');
  end if;

  -- Protection triggers that must accompany the corrected bodies.
  if to_regclass('public.financial_journal_entries') is not null then
    if not exists (
      select 1 from pg_trigger
      where tgname = 'trg_financial_journal_immutable' and not tgisinternal
    ) then
      raise exception 'CHAIN INTEGRITY FAIL: trg_financial_journal_immutable missing';
    end if;
  end if;

  if to_regclass('public.financial_journal_lines') is not null then
    if not exists (
      select 1 from pg_trigger
      where tgname = 'trg_financial_journal_line_immutable' and not tgisinternal
    ) then
      raise exception 'CHAIN INTEGRITY FAIL: trg_financial_journal_line_immutable missing';
    end if;
  end if;

  if to_regclass('public.bonus_ledger') is not null then
    if not exists (
      select 1 from pg_trigger
      where tgname = 'trg_bonus_ledger_immutable' and not tgisinternal
    ) then
      raise exception 'CHAIN INTEGRITY FAIL: trg_bonus_ledger_immutable missing';
    end if;
  end if;

  raise notice 'CHAIN INTEGRITY OK: corrected guard definitions and protection triggers present';
end
$integrity$;