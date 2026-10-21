-- PHASE 70: Local debugging produced two live static defects in the journal
-- posting path.
--
-- Defect 1: post_financial_journal_entry() selected `status` from a join of
-- financial_periods and financial_journal_entries, which is an ambiguous
-- column reference on Postgres 17 and aborted every posting attempt.
--
-- Defect 2: prevent_posted_journal_mutation() BEFORE UPDATE/DELETE trigger
-- returned OLD unconditionally, silently discarding any UPDATE to a draft
-- row (a BEFORE UPDATE trigger that returns OLD replaces the new row with
-- the old row). Drafts could never be modified or posted.
--
-- Fixes are OR REPLACE definitions only; no schema, policy, or security
-- change is involved.
create or replace function public.prevent_posted_journal_mutation()
returns trigger
language plpgsql
as $f$
begin
  if old.status = 'posted' then
    raise exception 'Posted journal entries are immutable; use a reversal';
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$f$;

create or replace function public.post_financial_journal_entry(p_entry_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $f$
declare
  v_debit numeric(18,2);
  v_credit numeric(18,2);
  v_count integer;
  v_status text;
  v_period_status text;
begin
  if public.current_user_role() <> 'company_director' then
    raise exception 'غير مصرح لك — مطلوب دور المدير العام';
  end if;

  select status into v_status
  from public.financial_journal_entries
  where id = p_entry_id
  for update;

  if v_status is null then raise exception 'Journal entry not found'; end if;
  if v_status <> 'draft' then raise exception 'Only draft entries can be posted'; end if;

  select p.status into v_period_status
  from public.financial_periods p
  join public.financial_journal_entries e on e.period_id = p.id
  where e.id = p_entry_id;
  if v_period_status is null or v_period_status <> 'open' then
    raise exception 'Period is closed or missing';
  end if;

  select count(*), coalesce(sum(debit), 0), coalesce(sum(credit), 0)
  into v_count, v_debit, v_credit
  from public.financial_journal_lines
  where journal_entry_id = p_entry_id;

  if v_count < 2 or v_debit <> v_credit then
    raise exception 'Journal entry is not balanced';
  end if;

  update public.financial_journal_entries
  set status = 'posted', posted_at = now(), posted_by = auth.uid()
  where id = p_entry_id;
end;
$f$;

-- Defect 3 (same silent-UPDATE pattern in the bonus reserve flow):
-- prevent_bonus_ledger_mutation() also returned OLD unconditionally, so any
-- UPDATE to a non-POSTED bonus_ledger row (e.g. the PENDING -> POSTED commit
-- of ORDER_DISCOUNT reservations) was silently discarded.
create or replace function public.prevent_bonus_ledger_mutation()
returns trigger
language plpgsql
as $f$
begin
  if old.status = 'POSTED' then
    raise exception 'bonus_ledger POSTED rows are immutable (use REVERSAL/ADJUSTMENT)';
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$f$;

-- Defect 4 (same pattern for unposted journal line edits).
create or replace function public.prevent_posted_journal_line_mutation()
returns trigger
language plpgsql
as $f$
declare
  s text;
begin
  select status into s from public.financial_journal_entries
  where id = old.journal_entry_id;
  if s = 'posted' then raise exception 'Posted journal lines are immutable'; end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$f$;
