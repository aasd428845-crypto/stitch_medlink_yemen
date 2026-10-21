-- =============================================================
-- PHASE 64 §6 — SQL probes A/B/C (+D, +E, +F) for the bonus earn → GL
-- integration (0028 decision hook + 0030 director post RPC).
-- ISOLATED scratch database ONLY. Synthetic TEST_ fixtures only.
--
-- Run as supabase_admin (table owner → RLS-bypass for direct fixture writes,
-- exactly like the ph51/ph61 harnesses). Director impersonation uses
-- set_config('request.jwt.claim.sub', '<dir-uuid>', true) inside each DO block
-- (current_user_role() is STABLE → caches per-tx; ph61 TEST #8b pattern).
-- No production. No supabase db push. No commit/push/deploy.
-- =============================================================
\set ON_ERROR_STOP on

\echo '== [ph64] pre-wash: reset test artifacts =='
alter table public.bonus_ledger disable trigger trg_bonus_ledger_immutable;
delete from public.bonus_audit_trail
 where entity_id in (select id from public.bonus_ledger
                      where idempotency_key like 'SALES_EARN:64%');
delete from public.bonus_earn_gl_postings
 where idempotency_key like 'GL_POST_EARN:%';
delete from public.bonus_ledger where idempotency_key like 'SALES_EARN:64%';
delete from public.bonus_settings where key like 'accounting_policy%';
delete from public.bonus_role_account_map where idempotency_key like 'GL_MAP%';
alter table public.bonus_ledger enable trigger trg_bonus_ledger_immutable;

insert into public.bonus_accounts(user_id, mode, status, currency)
  values ('00000000-0000-4000-8000-0000000000c1','SALES','active','YER')
on conflict (user_id) do nothing;

-- helper: direct-insert a POSTED EARN (the AFTER INSERT trigger still fires)
create or replace function public._ph64_insert_earn(p_tag text, p_amount int default 750)
returns uuid language plpgsql as $h$
declare _id uuid;
begin
  insert into public.bonus_ledger
    (account_id, txn_type, amount, status, rule_id, actor, reference, notes, idempotency_key)
  values
    ('00000000-0000-4000-8000-0000000000c1','EARN', p_amount,'POSTED',
     null, '00000000-0000-4000-8000-0000000000c1', p_tag, 'ph64-test',
     'SALES_EARN:64' || gen_random_uuid()::text)
  returning id into _id;
  return _id;
end;
$h$;

-- configure BD-01 A + BD-08 A + BD-09 A (the ONLY missing gate is the mapping)
insert into public.bonus_settings(key, value) values
  ('accounting_policy.BD-01','"A"'),
  ('accounting_policy.BD-08','"A"'),
  ('accounting_policy.BD-09','"A"')
on conflict (key) do update set value = excluded.value;

-- ── PROBE A: unmapped → ACCOUNT_MAPPING_REQUIRED, 0 links, 0 journals ───────────
\echo '== [ph64] PROBE A: unmapped → ACCOUNT_MAPPING_REQUIRED, 0 links, 0 journals =='
DO $$
declare
  v_lid uuid; n_link int; n_j int; n_audit int; code text;
begin
  v_lid := public._ph64_insert_earn('PROBE-A-unmapped', 750);
  select count(*) into n_link from public.bonus_earn_gl_postings;
  select count(*) into n_j   from public.financial_journal_entries;
  select count(*) into n_audit from public.bonus_audit_trail
    where entity='bonus_ledger_accounting' and entity_id=v_lid and action='EARN_ACCOUNTING_DECISION';
  select new_value->>'code' into code from public.bonus_audit_trail
    where entity='bonus_ledger_accounting' and entity_id=v_lid and action='EARN_ACCOUNTING_DECISION'
    order by at_time limit 1;
  if n_link = 0 and n_j = 0 and code = 'ACCOUNT_MAPPING_REQUIRED' and n_audit = 1 then
    raise notice 'PROBE A PASS: unmapped → 0 links, 0 journals, code=% (decision audited)', code;
  else
    raise exception 'PROBE A FAIL: links=% journals=% code=% audits=% (want 0/0/ACCOUNT_MAPPING_REQUIRED/1)',
      n_link, n_j, code, n_audit;
  end if;
end $$;

-- ── PROBE B: mapped A → PENDING link (no journal) → director posts → 1 balanced ──
\echo '== [ph64] PROBE B: mapped A → PENDING link → director posts → 1 balanced journal =='
DO $$
declare
  v_company uuid := (select id from public.financial_companies order by created_at limit 1);
  v_acc uuid := (select id from public.financial_accounts where company_id=v_company and code='2100' and is_postable limit 1);
begin
  perform set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000000000d1', true);
  perform public.upsert_bonus_role_account_map(v_company, 'deferred_bonus_liability', v_acc, 'GL_MAP:A');
end $$;
DO $$
declare
  v_lid uuid; n_link int; n_j int; lk public.bonus_earn_gl_postings%rowtype;
begin
  v_lid := public._ph64_insert_earn('PROBE-B-mapped-A', 750);
  select count(*) into n_link from public.bonus_earn_gl_postings;
  select count(*) into n_j   from public.financial_journal_entries;
  select * into lk from public.bonus_earn_gl_postings where ledger_id = v_lid;
  if n_link = 1 and lk.status = 'PENDING' and lk.journal_entry_id is null and n_j = 0 then
    raise notice 'PROBE B(pass-1) PASS: trigger queued exactly 1 PENDING link, journal_entry_id null, 0 journals';
  else
    raise exception 'PROBE B(pass-1) FAIL: link=% status=% jid=% journals=%', n_link, lk.status, lk.journal_entry_id, n_j;
  end if;
end $$;
DO $$
declare
  v_lid uuid := (select ledger_id from public.bonus_earn_gl_postings where status='PENDING' limit 1);
  r jsonb; n_j int; n_lines int; dr numeric; cr numeric; lk_status text; jid uuid;
begin
  if v_lid is null then raise exception 'PROBE B: no PENDING link found'; end if;
  perform set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000000000d1', true);
  r := public.post_bonus_earn_to_gl(v_lid);
  select count(*) into n_j from public.financial_journal_entries;
  select count(*) into n_lines from public.financial_journal_lines l
    join public.financial_journal_entries e on e.id = l.journal_entry_id
   where e.id = (r->>'journalEntryId')::uuid;
  select coalesce(sum(debit),0), coalesce(sum(credit),0) into dr, cr
    from public.financial_journal_lines l
    join public.financial_journal_entries e on e.id = l.journal_entry_id
   where e.id = (r->>'journalEntryId')::uuid;
  select status, journal_entry_id into lk_status, jid from public.bonus_earn_gl_postings where ledger_id = v_lid;
  if r->>'status' = 'POSTED'
     and n_j = 1 and n_lines = 2 and dr = cr
     and lk_status = 'POSTED' and jid = (r->>'journalEntryId')::uuid then
    raise notice 'PROBE B(pass-2) PASS: posted 1 journal, % lines, balanced Dr=% Ce=% , link POSTED', n_lines, dr, cr;
  else
    raise exception 'PROBE B(pass-2) FAIL: status=% journals=% lines=% dr=% cr=% link=% jid=%',
      r->>'status', n_j, n_lines, dr, cr, lk_status, jid;
  end if;
end $$;

-- ── PROBE C: idempotent re-post → same journal_entry_id, 1 journal total ───────
\echo '== [ph64] PROBE C: idempotent re-post → same journal_entry_id, 1 journal =='
DO $$
declare
  v_lid uuid := (select ledger_id from public.bonus_earn_gl_postings where status='POSTED' limit 1);
  j_first uuid := (select journal_entry_id from public.bonus_earn_gl_postings where ledger_id = v_lid);
  r jsonb; n_j int; j_same uuid;
begin
  if v_lid is null then raise exception 'PROBE C: no POSTED link found'; end if;
  perform set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000000000d1', true);
  r := public.post_bonus_earn_to_gl(v_lid);
  select count(*) into n_j from public.financial_journal_entries;
  select journal_entry_id into j_same from public.bonus_earn_gl_postings where ledger_id = v_lid;
  if (r->>'idempotent')::boolean = true
     and j_first = j_same and j_first = (r->>'journalEntryId')::uuid and n_j = 1 then
    raise notice 'PROBE C PASS: idempotent re-post returned existing journal %, still 1 journal', j_first;
  else
    raise exception 'PROBE C FAIL: idempotent=% first=% same=% result_jid=% journals=%',
      r->>'idempotent', j_first, j_same, r->>'journalEntryId', n_j;
  end if;
end $$;

-- ── PROBE D: mapped B → Dr bonus_expense, Cr cash ───────────────────────────────
\echo '== [ph64] PROBE D: mapped B → Dr 6000, Cr 1110 =='
DO $$
declare
  v_company uuid := (select id from public.financial_companies order by created_at limit 1);
  v_acc uuid := (select id from public.financial_accounts where company_id=v_company and code='6000' and is_postable limit 1);
  v_lid uuid; r jsonb; n_lines int;
  dr_acct text; last_acct text; dr_val numeric; cr_val numeric;
begin
  update public.bonus_settings set value = '"B"' where key = 'accounting_policy.BD-01';
  perform set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000000000d1', true);
  perform public.upsert_bonus_role_account_map(v_company, 'bonus_expense', v_acc, 'GL_MAP:B');
  v_lid := public._ph64_insert_earn('PROBE-D-mapped-B', 750);
  r := public.post_bonus_earn_to_gl(v_lid);
  select count(*) into n_lines from public.financial_journal_lines
   where journal_entry_id = (r->>'journalEntryId')::uuid;
  select a.code, l.debit into dr_acct, dr_val
    from public.financial_journal_lines l join public.financial_accounts a on a.id = l.account_id
   where l.journal_entry_id = (r->>'journalEntryId')::uuid order by l.line_number limit 1;
  select a.code, l.credit into last_acct, cr_val
    from public.financial_journal_lines l join public.financial_accounts a on a.id = l.account_id
   where l.journal_entry_id = (r->>'journalEntryId')::uuid order by l.line_number desc limit 1;
  if r->>'status' = 'POSTED' and n_lines = 2
     and dr_acct = '6000' and dr_val = 750
     and last_acct = '1110' and cr_val = 750 then
    raise notice 'PROBE D PASS: B → Dr 6000(%g) Cr 1110(750) ; % lines, balanced', dr_val, n_lines;
  else
    raise exception 'PROBE D FAIL: status=% lines=% dr_acct=% dr=% cr_acct=% cr=%',
      r->>'status', n_lines, dr_acct, dr_val, last_acct, cr_val;
  end if;
end $$;

-- ── PROBE E: non-director (client) cannot post — authority fail-closed ─────────
\echo '== [ph64] PROBE E: non-director (client) cannot post (authority fail-closed) =='
DO $$
declare
  v_lid uuid := (select ledger_id from public.bonus_earn_gl_postings where status='PENDING' order by ledger_id limit 1);
  err text;
begin
  if v_lid is null then
    update public.bonus_settings set value = '"A"' where key = 'accounting_policy.BD-01';
    perform (select public.upsert_bonus_role_account_map(c.id, 'deferred_bonus_liability', a.id, 'GL_MAP:E')
             from public.financial_companies c
                  cross join lateral (select id from public.financial_accounts where company_id=c.id and code='2100' and is_postable limit 1) a);
    v_lid := public._ph64_insert_earn('PROBE-E-auth', 750);
  end if;
  begin
    perform set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000000000c1', true); -- client
    perform public.post_bonus_earn_to_gl(v_lid);
    err := 'NO_ERROR';
  exception when others then
    err := sqlerrm;
  end;
  if err like '%company_director%' then
    raise notice 'PROBE E PASS: non-director rejected at authority gate => %', err;
  else
    raise exception 'PROBE E FAIL: expected director-only rejection, got => %', err;
  end if;
end $$;

-- ── PROBE F: no OPEN period → post fails guarded (void-draft-on-fail) ──────────
\echo '== [ph64] PROBE F: closed period blocks posting (void-draft-on-fail) =='
DO $$
declare
  v_company uuid := (select id from public.financial_companies order by created_at limit 1);
  v_acc uuid := (select id from public.financial_accounts where company_id=v_company and code='2100' and is_postable limit 1);
  v_lid uuid; r jsonb; n_j_before int; n_j_after int; n_draft int;
begin
  update public.bonus_settings set value = '"A"' where key = 'accounting_policy.BD-01';
  perform set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000000000d1', true);
  perform public.upsert_bonus_role_account_map(v_company, 'deferred_bonus_liability', v_acc, 'GL_MAP:F');
  -- close the period the earn falls into
  update public.financial_periods set status = 'closed';
  v_lid := public._ph64_insert_earn('PROBE-F-closed-period', 750);
  -- trigger queues a PENDING link; the director post must now FAIL + void the draft.
  -- Capture posted/journal counts BEFORE the attempt: probes B & D already posted 2
  -- journals in this scratch, so the assertion must be a DELTA (this attempt must add
  -- ZERO posted journals and void its own draft), not an absolute count.
  select count(*) into n_j_before from public.financial_journal_entries where status='posted';
  r := public.post_bonus_earn_to_gl(v_lid);
  select count(*) into n_j_after from public.financial_journal_entries where status='posted';
  select count(*) into n_draft from public.financial_journal_entries where status='draft';
  if (r->>'status') = 'FAILED' and n_j_after = n_j_before and n_draft = 0 then
    raise notice 'PROBE F PASS: closed period → status=FAILED, posted %→% (no new), draft=0 (voided), reason=%',
      n_j_before, n_j_after, r->>'reason';
  else
    raise exception 'PROBE F FAIL: status=% posted %→% draft=% reason=%',
      r->>'status', n_j_before, n_j_after, n_draft, r->>'reason';
  end if;
end $$;
update public.financial_periods set status = 'open';

\echo '== [ph64] DONE — all probes executed =='
