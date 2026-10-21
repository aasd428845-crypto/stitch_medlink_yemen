-- =============================================================
-- PROBE G — snapshot isolation under BD-01 policy + role-mapping change.
-- ISOLATED scratch database ONLY (medlink_ph64_bonus_gl_test). Synthetic TEST_ fixtures.
-- §7: NO supabase db push; NO prod; NO commit/push/deploy.
--
-- Scenario (E1 control-surface audit — "Admin UI → bonus_settings → BD-01 →
-- E1 decision engine → posting behavior", and "Admin UI → account mapping →
-- bonus_role_account_map → E1 posting RPC → financial_accounts → journal lines"):
--
--   Admin UI writes bonus_settings + bonus_role_account_map  →  0028 trigger reads them
--   Admin UI THEN changes BD-01 (A→B) and the role→account mapping (X/Y → M/N)
--   → Event1 (old earn) must STAY on its snapshotted policy+mapping;
--   → Event2 (new earn) must use the NEW policy+mapping.
--
-- What this proves on scratch:
--   (G1) earn1 records an immutable decision snapshot when policy=A + liability mapped.
--   (G2) AFTER flipping BD-01=A→B and mapping expense→6000, a NEW earn2 (Event2)
--        records policy=B + expense account 6000 — the new configuration.
--   (G3) Re-dispatching earn1 AFTER the flip still returns option A (alreadyDecided),
--        never re-evaluated to B — history is locked (ON CONFLICT DO NOTHING snapshot
--        + audit dedup + bonus_ledger.idempotency_key).
--   (G4) Director posts BOTH earns: each posts under its OWN snapshotted option as a
--        distinct balanced journal; the cash leg resolves to the seeded 1110 in BOTH
--        (confirming the hardcoded-contra GAP; the role accounts 2100/6000 come from
--        the mapping). Debit/Credit per option is reported explicitly.
-- =============================================================
\set ON_ERROR_STOP on

-- (director impersonation uuid '00000000-0000-4000-8000-0000000000d1' is inlined in
--  each DO block below, matching ph61 TEST #8b / the ph64 probes.)

\echo '== [ph64-G] pre-wash: reset E1 GL test artifacts (6G namespace) =='
alter table public.bonus_ledger disable trigger trg_bonus_ledger_immutable;
delete from public.bonus_audit_trail
 where entity_id in (select id from public.bonus_ledger where idempotency_key like 'SALES_EARN:6G%');
delete from public.bonus_earn_gl_postings
 where idempotency_key like 'GL_POST_EARN:%6G%';
-- reset to a KNOWN base so phase 2 flips are observable (this probe owns its keys):
delete from public.bonus_ledger where idempotency_key like 'SALES_EARN:6G%';
delete from public.bonus_settings  where key like 'accounting_policy.snapshot.%6G%' or key in ('accounting_policy.BD-01');
delete from public.bonus_role_account_map where idempotency_key like 'GL_MAP:G%';
alter table public.bonus_ledger enable trigger trg_bonus_ledger_immutable;

-- state holder so each phase can address the exact earn ids across DO blocks.
drop table if exists ph64g_lids;
create temp table ph64g_lids(tag text primary key, ledger_id uuid);

-- fresh earn helper (distinct idempotency namespace from A–F)
create or replace function public._ph64g_insert_earn(p_tag text, p_amount int default 750)
returns uuid language plpgsql as $h$
declare _id uuid;
begin
  insert into public.bonus_ledger
    (account_id, txn_type, amount, status, rule_id, actor, reference, notes, idempotency_key)
  values
    ('00000000-0000-4000-8000-0000000000c1','EARN', p_amount,'POSTED',
     null, '00000000-0000-4000-8000-0000000000c1', p_tag, 'ph64G-test',
     'SALES_EARN:6G' || gen_random_uuid()::text)
  returning id into _id;
  return _id;
end;
$h$;

-- BD-01=A / BD-08=A / BD-09=A — all three policies must be present (the pre-wash
-- inserts BD-01 too; the Phase 1/2 steps then UPDATE it to the target letter).
insert into public.bonus_settings(key, value) values
  ('accounting_policy.BD-01','"A"'),
  ('accounting_policy.BD-08','"A"'),
  ('accounting_policy.BD-09','"A"')
on conflict (key) do update set value = excluded.value;

-- seed the bonus_accounts row for the client UUID that _ph64g_insert_earn uses
-- as account_id FK target (mirrors ph64-probes.sql inline seed; ph51-fixtures omits it).
insert into public.bonus_accounts(user_id, mode, status, currency)
  values ('00000000-0000-4000-8000-0000000000c1','SALES','active','YER')
on conflict (user_id) do nothing;

-- ── Phase 1: BD-01=A, liability role mapped → Event1 (earn1) ─────────────────────
\echo '== [ph64-G] Phase 1: BD-01=A, map liability → acctA(2100) → earn1 =='
DO $$
declare
  v_company uuid := (select id from public.financial_companies order by created_at limit 1);
  v_liab    uuid := (select id from public.financial_accounts where company_id=v_company and code='2100' and is_postable limit 1);
  v_lid     uuid;
  snap      text; opt text; liab_code text; n_link int;
begin
  if v_liab is null then raise exception 'prereq: 2100 not a postable account'; end if;
  perform set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000000000d1', true);
  perform public.upsert_bonus_role_account_map(v_company, 'deferred_bonus_liability', v_liab, 'GL_MAP:G1');
  update public.bonus_settings set value='"A"' where key='accounting_policy.BD-01';
  v_lid := public._ph64g_insert_earn('PROBE-G-earn1-policyA', 750);
  insert into ph64g_lids values ('earn1', v_lid);
  select value::text into snap from public.bonus_settings where key='accounting_policy.snapshot.'||v_lid::text;
  select new_value->>'option' into opt from public.bonus_audit_trail
   where entity='bonus_ledger_accounting' and entity_id=v_lid and action='EARN_ACCOUNTING_DECISION' order by at_time limit 1;
  select new_value->'intendedAccounts'->0->>'code' into liab_code from public.bonus_audit_trail
   where entity='bonus_ledger_accounting' and entity_id=v_lid and action='EARN_ACCOUNTING_DECISION' order by at_time limit 1;
  select count(*) into n_link from public.bonus_earn_gl_postings where ledger_id=v_lid;
  raise notice 'G1 earn1=% snapshot=% audit_option=% intended_account=% links=%', v_lid, snap, opt, liab_code, n_link;
  if snap = '"A"' and opt='A' and liab_code='2100' and n_link=1 then
    raise notice 'G1 PASS: earn1 decision frozen to BD-01=A, liability account 2100, 1 PENDING request queued';
  else
    raise exception 'G1 FAIL: snapshot=% option=% code=% links=% (want "A"/A/2100/1)', snap, opt, liab_code, n_link;
  end if;
end $$;

-- ── Phase 2: ADMIN CHANGES policy A→B + mapping (now map expense → acctB) ─────────
--        → Event2 (earn2) must pick up the NEW policy+mapping.
\echo '== [ph64-G] Phase 2: BD-01=B, map expense → acctB(6000) → earn2 (new event) =='
DO $$
declare
  v_company  uuid := (select id from public.financial_companies order by created_at limit 1);
  v_expense  uuid := (select id from public.financial_accounts where company_id=v_company and code='6000' and is_postable limit 1);
  v_lid      uuid;
  snap       text; opt text; exp_code text; n_link int;
begin
  if v_expense is null then raise exception 'prereq: 6000 not a postable account'; end if;
  perform set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000000000d1', true);
  -- the liability mapping from Phase 1 is LEFT INTACT (earnings under A stay postable);
  -- only the policy letter and the B-role mapping change — i.e. the configuration change.
  perform public.upsert_bonus_role_account_map(v_company, 'bonus_expense', v_expense, 'GL_MAP:G2');
  update public.bonus_settings set value='"B"' where key='accounting_policy.BD-01';
  v_lid := public._ph64g_insert_earn('PROBE-G-earn2-policyB', 750);
  insert into ph64g_lids values ('earn2', v_lid);
  select value::text into snap from public.bonus_settings where key='accounting_policy.snapshot.'||v_lid::text;
  select new_value->>'option' into opt from public.bonus_audit_trail
   where entity='bonus_ledger_accounting' and entity_id=v_lid and action='EARN_ACCOUNTING_DECISION' order by at_time limit 1;
  select new_value->'intendedAccounts'->0->>'code' into exp_code from public.bonus_audit_trail
   where entity='bonus_ledger_accounting' and entity_id=v_lid and action='EARN_ACCOUNTING_DECISION' order by at_time limit 1;
  select count(*) into n_link from public.bonus_earn_gl_postings where ledger_id=v_lid;
  raise notice 'G2 earn2=% snapshot=% audit_option=% intended_account=% links=%', v_lid, snap, opt, exp_code, n_link;
  if snap = '"B"' and opt='B' and exp_code='6000' and n_link=1 then
    raise notice 'G2 PASS: earn2 (new event) picked up BD-01=B + expense 6000; earn1 untouched (snapshot keys are per-ledger)';
  else
    raise exception 'G2 FAIL: snapshot=% option=% code=% links=% (want "B"/B/6000/1)', snap, opt, exp_code, n_link;
  end if;
end $$;

-- ── Phase 3: re-dispatch earn1 AFTER the flip → MUST stay on A (history locked) ───
\echo '== [ph64-G] Phase 3: re-dispatch earn1 after BD-01=B → stay A (history locked) =='
DO $$
declare
  v_lid1 uuid := (select ledger_id from ph64g_lids where tag='earn1');
  r      jsonb;
  snap   text; opt text; n_audits int;
begin
  perform set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000000000d1', true);
  r := public.apply_bonus_earn_accounting(v_lid1);  -- re-dispatch under BD-01=B live
  select value::text into snap from public.bonus_settings where key='accounting_policy.snapshot.'||v_lid1::text;
  select new_value->>'option' into opt from public.bonus_audit_trail
   where entity='bonus_ledger_accounting' and entity_id=v_lid1 and action='EARN_ACCOUNTING_DECISION' order by at_time limit 1;
  select count(*) into n_audits from public.bonus_audit_trail
   where entity='bonus_ledger_accounting' and entity_id=v_lid1 and action='EARN_ACCOUNTING_DECISION';
  raise notice 'G3 re-dispatch earn1=% alreadyDecided=% option=% snapshot=% audits=%', v_lid1, r->>'alreadyDecided', r->>'option', snap, n_audits;
  if (r->>'alreadyDecided')::boolean is true and (r->>'option')='A' and snap='"A"' and opt='A' and n_audits=1 then
    raise notice 'G3 PASS: earn1 replayed without re-evaluation; option snapshots A, audit row not duplicated (history locked)';
  else
    raise exception 'G3 FAIL: alreadyDecided=% option=% snapshot=% opt=% audits=% (want true/A/A/A/1)', r->>'alreadyDecided', r->>'option', snap, opt, n_audits;
  end if;
end $$;

-- ── Phase 4: director posts BOTH earns; per-option Debit/Credit + the 1110 GAP ───
-- earn1 (A): Dr 1110 / Cr mapped-liability(2100)  ← cash leg hardcoded 1110
-- earn2 (B): Dr mapped-expense(6000) / Cr 1110    ← cash leg hardcoded 1110
\echo '== [ph64-G] Phase 4: director posts earn1(A)+earn2(B); report Debit/Credit per option =='
DO $$
declare
  v_lid1 uuid := (select ledger_id from ph64g_lids where tag='earn1');
  v_lid2 uuid := (select ledger_id from ph64g_lids where tag='earn2');
  r1     jsonb; r2 jsonb;
  j1     uuid; j2 uuid;
  l1_dr  text; l1_cr text; l2_dr text; l2_cr text;
  n_j    int;
begin
  perform set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-0000000000d1', true);
  r1 := public.post_bonus_earn_to_gl(v_lid1);
  r2 := public.post_bonus_earn_to_gl(v_lid2);
  j1 := (r1->>'journalEntryId')::uuid; j2 := (r2->>'journalEntryId')::uuid;
  if r1->>'status' <> 'POSTED' or r2->>'status' <> 'POSTED' then
    raise exception 'G4 FAIL: earn1 post=% earn2 post=%', r1->>'status', r2->>'status';
  end if;
  if j1 = j2 then
    raise exception 'G4 FAIL: both earns posted the SAME journal % — no per-event journal', j1;
  end if;
  -- read the two lines of each journal: the debit leg (debit>0) and the credit leg (credit>0).
  select da.code, ca.code into l1_dr, l1_cr
    from public.financial_journal_entries je
    join public.financial_journal_lines dl on dl.journal_entry_id=je.id and dl.debit>0
    join public.financial_journal_lines cl on cl.journal_entry_id=je.id and cl.credit>0
    join public.financial_accounts da on da.id=dl.account_id
    join public.financial_accounts ca on ca.id=cl.account_id
   where je.id=j1;
  select da.code, ca.code into l2_dr, l2_cr
    from public.financial_journal_entries je
    join public.financial_journal_lines dl on dl.journal_entry_id=je.id and dl.debit>0
    join public.financial_journal_lines cl on cl.journal_entry_id=je.id and cl.credit>0
    join public.financial_accounts da on da.id=dl.account_id
    join public.financial_accounts ca on ca.id=cl.account_id
   where je.id=j2;
  select count(*) into n_j from public.financial_journal_entries where status='posted';
  raise notice 'G4 OPTION A: Debit=% Credit=% (journal %)', l1_dr, l1_cr, j1;
  raise notice 'G4 OPTION B: Debit=% Credit=% (journal %)', l2_dr, l2_cr, j2;
  raise notice 'G4 posted journals total=% (includes pre-existing B/D journals from this scratch)', n_j;
  -- earn1 (A): Debit cash 1110, Credit mapped liability 2100
  -- earn2 (B): Debit mapped expense 6000, Credit cash 1110
  if l1_dr='1110' and l1_cr='2100' and l2_dr='6000' and l2_cr='1110' then
    raise notice 'G4 PASS: each earn posted under its own option; cash leg is 1110 in BOTH (hardcoded contra)';
    raise notice 'G4 GAP: 1110 (cash) is hardcoded as the E1 contra offset in post_bonus_earn_to_gl — NOT configurable via bonus_role_account_map';
  else
    raise exception 'G4 FAIL: A dr=% cr=% / B dr=% cr=% (want 1110/2100 and 6000/1110)', l1_dr, l1_cr, l2_dr, l2_cr;
  end if;
end $$;

\echo '== [ph64-G] DONE — snapshot-isolation probe executed =='
