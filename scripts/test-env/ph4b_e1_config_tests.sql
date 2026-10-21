-- =============================================================
-- PHASE 4B — E1 fully-configurable account policy: scratch verification.
-- ISOLATED scratch ONLY (container ph51_pg, DB postgres). NEVER production.
--
-- Run:
--   docker exec -i ph51_pg psql -U supabase_admin -d postgres \
--     -v ON_ERROR_STOP=1 -f - < scripts/test-env/ph4b_e1_config_tests.sql
--
-- Proves that NO account code is a fixed decision in the E1 posting logic:
-- every debit/credit leg is resolved from configuration
--   bonus_journal_leg_mapping (EARN, option) → (debit_role, credit_role)
--   bonus_role_account_map    (company, role) → financial_accounts.id
-- and frozen per-earn into the 0028 decision snapshot; 0030 posts from that
-- snapshot. Each CASE raises on failure (ON_ERROR_STOP aborts the file).
-- =============================================================

\echo == ph4b: cleanup prior run artifacts (scratch only) ==
alter table public.bonus_ledger disable trigger trg_bonus_ledger_immutable;
delete from public.bonus_audit_trail
 where entity_id in (select id from public.bonus_ledger where idempotency_key like 'EARN_PH4B%')
    or reference like 'ph4b%'
    or reference like 'EARN_PH4B%';
delete from public.bonus_ledger where idempotency_key like 'EARN_PH4B%';
delete from public.bonus_earn_gl_postings
 where ledger_id not in (select id from public.bonus_ledger);
alter table public.bonus_ledger enable trigger trg_bonus_ledger_immutable;
delete from public.bonus_journal_leg_mapping
 where company_id in (select id from public.financial_companies);
delete from public.bonus_role_account_map
 where company_id in (select id from public.financial_companies);
delete from public.bonus_settings where key like 'accounting_policy%';
update public.financial_periods set status = 'open';

\echo == ph4b: fixtures (director + client) ==
insert into auth.users(id, email, aud, role, encrypted_password, confirmed_at, created_at, updated_at) values
  ('11111111-1111-1111-1111-111111111111','client@x.test','authenticated','authenticated','','now()','now()','now()'),
  ('22222222-2222-2222-2222-222222222222','director@x.test','authenticated','authenticated','','now()','now()','now()'),
  ('33333333-3333-3333-3333-333333333333','driver@x.test','authenticated','authenticated','','now()','now()','now()')
on conflict (id) do update set email = excluded.email;
insert into public.users(id, email, role, created_at, terms_accepted_at) values
  ('11111111-1111-1111-1111-111111111111','client@x.test','client','now()','now()'),
  ('22222222-2222-2222-2222-222222222222','director@x.test','company_director','now()','now()'),
  ('33333333-3333-3333-3333-333333333333','driver@x.test','driver','now()','now()')
on conflict (id) do update set role = excluded.role;
insert into public.bonus_accounts(user_id, mode, status, currency)
  values ('11111111-1111-1111-1111-111111111111','SALES','active','YER')
on conflict (user_id) do nothing;

-- fixture: the project's own deferred-bonus-liability account (migration
-- 0017_financial_bonus_liability_account.sql), applied here because the
-- canonical replay chain uses root 0017 (bonus_order_integrity), not the web
-- 0017. This is the project's designated account definition — NOT an invented
-- code. Cash 1110 / bank 1120 are seeded by 0007.
insert into public.financial_accounts
  (company_id, code, name, account_type, level, is_postable, normal_balance)
select c.id, '2110', 'التزام البونص المستقبلي', 'liability', 3, true, 'credit'
from public.financial_companies c
where not exists (
  select 1 from public.financial_accounts a where a.company_id = c.id and a.code = '2110'
);

-- scratch-only helper: insert a POSTED EARN (the AFTER INSERT trigger fires the hook)
create or replace function public._ph4b_insert_earn(p_tag text, p_amount int default 750)
returns uuid language plpgsql as $h$
declare _id uuid;
begin
  insert into public.bonus_ledger
    (account_id, txn_type, amount, status, rule_id, actor, reference, notes, idempotency_key)
  values
    ('11111111-1111-1111-1111-111111111111','EARN', p_amount,'POSTED',
     null,'11111111-1111-1111-1111-111111111111', p_tag,'ph4b',
     'EARN_PH4B:'||p_tag||':'||gen_random_uuid()::text)
  returning id into _id;
  return _id;
end $h$;

-- scratch-only helper: account code set of a journal's lines
create or replace function public._ph4b_journal_codes(p_je uuid)
returns text language sql as $h$
  select string_agg(a.code, ',' order by a.code)
    from public.financial_journal_lines l
    join public.financial_accounts a on a.id = l.account_id
   where l.journal_entry_id = p_je;
$h$;

\echo == setup: director configures Debit=cash(1110) / Credit=liability(2110) for option A ==
do $$
declare v_company uuid; v_cash uuid; v_liab uuid;
begin
  perform set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222', true);
  select id into v_company from public.financial_companies order by created_at limit 1;
  select id into v_cash from public.financial_accounts where company_id=v_company and code='1110';
  select id into v_liab from public.financial_accounts where company_id=v_company and code='2110';
  perform public.upsert_bonus_role_account_map(v_company,'cash',v_cash,'ph4b:cash:1110');
  perform public.upsert_bonus_role_account_map(v_company,'deferred_bonus_liability',v_liab,'ph4b:liab:2110');
  perform public.upsert_journal_leg_layout(v_company,'EARN','A','cash','deferred_bonus_liability','ph4b:layout:A');
  insert into public.bonus_settings(key,value) values
    ('accounting_policy.BD-01','"A"'::jsonb),
    ('accounting_policy.BD-08','"A"'::jsonb),
    ('accounting_policy.BD-09','"A"'::jsonb)
  on conflict (key) do update set value = excluded.value;
end $$;

\echo == CASE 1: Option A Debit=1110 / Credit=2110 → trigger snapshots X/Y; director posts X/Y ==
do $$
declare v_lid uuid; v_dec jsonb; v_link public.bonus_earn_gl_postings%rowtype; v_res jsonb; v_je uuid;
        v_n int; v_dr numeric; v_cr numeric; v_codes text;
begin
  v_lid := public._ph4b_insert_earn('C1', 750);
  select new_value into v_dec from public.bonus_audit_trail
   where entity='bonus_ledger_accounting' and entity_id=v_lid and action='EARN_ACCOUNTING_DECISION';
  if v_dec->>'code' <> 'POSTING_AUTHORITY_REQUIRED' then raise exception 'CASE1 FAIL: code=%', v_dec->>'code'; end if;
  if v_dec->>'debit_account_code' <> '1110' or v_dec->>'credit_account_code' <> '2110' then
    raise exception 'CASE1 FAIL: snapshot debit=% credit=%', v_dec->>'debit_account_code', v_dec->>'credit_account_code'; end if;
  select * into v_link from public.bonus_earn_gl_postings where ledger_id=v_lid;
  if v_link.status <> 'PENDING' then raise exception 'CASE1 FAIL: link status=%', v_link.status; end if;

  perform set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222', true);
  v_res := public.post_bonus_earn_to_gl(v_lid);
  if v_res->>'status' <> 'POSTED' then raise exception 'CASE1 FAIL: post=%', v_res; end if;
  v_je := (v_res->>'journalEntryId')::uuid;

  select count(*), coalesce(sum(debit),0), coalesce(sum(credit),0) into v_n, v_dr, v_cr
    from public.financial_journal_lines where journal_entry_id = v_je;
  v_codes := public._ph4b_journal_codes(v_je);
  if v_n <> 2 then raise exception 'CASE1 FAIL: lines=%', v_n; end if;
  if v_dr <> 750 or v_cr <> 750 then raise exception 'CASE1 FAIL: Dr=% Cr=%', v_dr, v_cr; end if;
  if v_codes <> '1110,2110' then raise exception 'CASE1 FAIL: codes=%', v_codes; end if;
  raise notice 'CASE 1 PASS: snapshot debit=1110 credit=2110; director post -> 1 balanced journal on 1110/2110 (Dr=Cr=750)';
end $$;

\echo == CASE 2: re-point Debit to M=1120 → a NEW earn uses M/N ==
do $$
declare v_company uuid; v_cash2 uuid; v_lid uuid; v_dec jsonb; v_res jsonb; v_je uuid; v_codes text;
begin
  perform set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222', true);
  select id into v_company from public.financial_companies order by created_at limit 1;
  select id into v_cash2 from public.financial_accounts where company_id=v_company and code='1120';
  perform public.upsert_bonus_role_account_map(v_company,'cash',v_cash2,'ph4b:cash:1120');

  v_lid := public._ph4b_insert_earn('C2', 300);
  select new_value into v_dec from public.bonus_audit_trail
   where entity='bonus_ledger_accounting' and entity_id=v_lid and action='EARN_ACCOUNTING_DECISION';
  if v_dec->>'debit_account_code' <> '1120' or v_dec->>'credit_account_code' <> '2110' then
    raise exception 'CASE2 FAIL: new earn snapshot debit=% credit=%', v_dec->>'debit_account_code', v_dec->>'credit_account_code'; end if;

  v_res := public.post_bonus_earn_to_gl(v_lid);
  v_je := (v_res->>'journalEntryId')::uuid;
  v_codes := public._ph4b_journal_codes(v_je);
  if v_codes <> '1120,2110' then raise exception 'CASE2 FAIL: new journal codes=%', v_codes; end if;
  raise notice 'CASE 2 PASS: after re-pointing Debit to 1120, the NEW earn posts Debit 1120 / Credit 2110';
end $$;

\echo == CASE 3: re-read the OLD earn (C1) → still 1110/2110 (snapshot history-locked) ==
do $$
declare v_dec jsonb;
begin
  select new_value into v_dec from public.bonus_audit_trail
   where entity='bonus_ledger_accounting' and action='EARN_ACCOUNTING_DECISION'
     and new_value->>'ledgerId' in (
       select id::text from public.bonus_ledger where idempotency_key like 'EARN_PH4B:C1:%')
   order by at_time limit 1;
  if v_dec->>'debit_account_code' <> '1110' or v_dec->>'credit_account_code' <> '2110' then
    raise exception 'CASE3 FAIL: old earn snapshot debit=% credit=%', v_dec->>'debit_account_code', v_dec->>'credit_account_code'; end if;
  raise notice 'CASE 3 PASS: the old earn still carries debit=1110 credit=2110 despite the live config now being 1120';
end $$;

\echo == CASE 4: remove Debit mapping → ACCOUNT_MAPPING_REQUIRED, no PENDING link, no journal ==
do $$
declare v_company uuid; v_lid uuid; v_dec jsonb; v_links int; v_j int;
begin
  perform set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222', true);
  select id into v_company from public.financial_companies order by created_at limit 1;
  perform public.delete_bonus_role_account_map(v_company,'cash');

  v_lid := public._ph4b_insert_earn('C4', 200);
  select new_value into v_dec from public.bonus_audit_trail
   where entity='bonus_ledger_accounting' and entity_id=v_lid and action='EARN_ACCOUNTING_DECISION';
  if v_dec->>'code' <> 'ACCOUNT_MAPPING_REQUIRED' then raise exception 'CASE4 FAIL: code=%', v_dec->>'code'; end if;
  if v_dec->>'debit_account_code' is not null then raise exception 'CASE4 FAIL: debit should be null'; end if;
  select count(*) into v_links from public.bonus_earn_gl_postings where ledger_id=v_lid;
  if v_links <> 0 then raise exception 'CASE4 FAIL: PENDING link written (%)', v_links; end if;
  select count(*) into v_j from public.financial_journal_entries where id in (
    select journal_entry_id from public.bonus_earn_gl_postings where ledger_id=v_lid);
  if v_j <> 0 then raise exception 'CASE4 FAIL: journal created'; end if;
  raise notice 'CASE 4 PASS: removing the Debit mapping -> ACCOUNT_MAPPING_REQUIRED, no PENDING link, no journal';
end $$;

\echo == CASE 7: re-POST CASE 1 earn → same journal_entry_id, exactly 1 journal ==
do $$
declare v_lid uuid; v_res jsonb; v_first uuid; v_n int;
begin
  select id into v_lid from public.bonus_ledger where idempotency_key like 'EARN_PH4B:C1:%' limit 1;
  select journal_entry_id into v_first from public.bonus_earn_gl_postings where ledger_id=v_lid;
  perform set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222', true);
  v_res := public.post_bonus_earn_to_gl(v_lid);
  if v_res->>'idempotent' <> 'true' then raise exception 'CASE7 FAIL: not idempotent: %', v_res; end if;
  if (v_res->>'journalEntryId')::uuid <> v_first then raise exception 'CASE7 FAIL: journal id changed'; end if;
  select count(*) into v_n from public.financial_journal_entries where id = v_first;
  if v_n <> 1 then raise exception 'CASE7 FAIL: journal rows=%', v_n; end if;
  raise notice 'CASE 7 PASS: re-post returns the SAME journal_entry_id (idempotent); exactly 1 journal';
end $$;

\echo == CASE 8: non-director (driver) cannot post ==
do $$
declare v_lid uuid;
begin
  -- re-bind the debit so a fresh postable earn exists
  perform set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222', true);
  perform public.upsert_bonus_role_account_map(
    (select id from public.financial_companies order by created_at limit 1),
    'cash', (select id from public.financial_accounts where code='1110'), 'ph4b:cash:again');
  v_lid := public._ph4b_insert_earn('C8', 150);

  perform set_config('request.jwt.claim.sub','33333333-3333-3333-3333-333333333333', true); -- driver
  begin
    perform public.post_bonus_earn_to_gl(v_lid);
    raise exception 'CASE8 FAIL: non-director was allowed to post';
  exception when others then
    if sqlerrm like '%CASE8 FAIL%' then raise; end if;
    raise notice 'CASE 8 PASS: non-director rejected at the director-only gate (%)', sqlerrm;
  end;
end $$;

\echo == CASE 9: closed period → post refused (no posted journal) ==
do $$
declare v_lid uuid; v_res jsonb; v_posted int;
begin
  update public.financial_periods set status = 'closed';
  v_lid := public._ph4b_insert_earn('C9', 500);
  select count(*) into v_posted from public.financial_journal_entries where status='posted';
  perform set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222', true);
  v_res := public.post_bonus_earn_to_gl(v_lid);
  if v_res->>'status' <> 'FAILED' then raise exception 'CASE9 FAIL: expected FAILED, got %', v_res; end if;
  if (select count(*) from public.financial_journal_entries where status='posted') <> v_posted then
    raise exception 'CASE9 FAIL: a posted journal was created against a closed period'; end if;
  update public.financial_periods set status = 'open';
  raise notice 'CASE 9 PASS: closed period -> post FAILED, no posted journal created';
end $$;

\echo == ph4b summary ==
do $$
declare v_map int; v_layout int; v_pending int; v_posted int;
begin
  select count(*) into v_map from public.bonus_role_account_map where is_active;
  select count(*) into v_layout from public.bonus_journal_leg_mapping where is_active;
  select count(*) into v_pending from public.bonus_earn_gl_postings where status='PENDING';
  select count(*) into v_posted from public.bonus_earn_gl_postings where status='POSTED';
  raise notice 'ph4b DONE: active role maps=%, active layouts=%, PENDING links=%, POSTED links=%', v_map, v_layout, v_pending, v_posted;
end $$;

-- teardown: drop scratch-only helpers (not migrations)
drop function if exists public._ph4b_insert_earn(text,int);
drop function if exists public._ph4b_journal_codes(uuid);
\echo == ph4b E1 configuration tests complete ==