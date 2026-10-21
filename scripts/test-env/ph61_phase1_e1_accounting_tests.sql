-- =============================================================
-- PHASE 1 — BONUS EARN (E1) → GENERAL LEDGER accounting integration
-- Test harness (ISOLATED scratch database ONLY; never run against production).
--
-- Run against the 0024-tipped scratch (container ph51_pg, DB postgres):
--   docker exec -i ph51_pg psql -U supabase_admin -d postgres \
--     -v ON_ERROR_STOP=1 -f scripts/test-env/ph61_phase1_e1_accounting_tests.sql
--
-- NOTE on -1 (single transaction): NOT used. Each statement/DO block is its own
-- transaction so the tx-local set_config('request.jwt.claim.sub',...) used in
-- TEST #8b is re-evaluated per block (current_user_role() is STABLE and caches
-- per transaction).
-- =============================================================

\echo == pre-wash: remove phase-1 test artifacts (isolated scratch only) ==
-- bonus_ledger is append-only/immutable against DELETE for POSTED rows (by
-- design, 0018). This is the ISOLATED scratch harness only (super-user reset),
-- never production: briefly disable that one trigger so we can wipe TEST
-- artifacts and make every run start from a clean ledger.
alter table public.bonus_ledger disable trigger trg_bonus_ledger_immutable;
-- 1a) audit trails that point at earns we recreate below (DECISION + ERROR),
--     the zero-uuid smoke-test audit, the SALES_EARN audit rows for order1.
delete from public.bonus_audit_trail
 where entity_id in (select id from public.bonus_ledger
                     where idempotency_key like 'EARN%'
                        or idempotency_key like 'SALES_EARN:6666%'
                        or idempotency_key like 'DBG_%');
delete from public.bonus_audit_trail
 where entity_id = '00000000-0000-0000-0000-000000000000'
   and action = 'EARN_ACCOUNTING_DECISION';
delete from public.bonus_audit_trail
 where entity = 'bonus_ledger' and reference like 'SALES_EARN:6666%';
-- 1b) the earn rows themselves
delete from public.bonus_ledger
 where idempotency_key like 'EARN%' or idempotency_key like 'SALES_EARN:6666%' or idempotency_key like 'DBG_%';
-- 2) order lines recreated by TEST #1
delete from public.order_items where order_id = '66666666-6666-6666-6666-666666666666';
-- 3) policy keys: start clean
delete from public.bonus_settings where key like 'accounting_policy%';
-- restore the immutability guard
alter table public.bonus_ledger enable trigger trg_bonus_ledger_immutable;

\echo == setup: test users, product, rule, account, order ==
-- auth.users (id is the only NOT NULL col; handle_new_user auto-creates public.users)
insert into auth.users(id, email, aud, role, encrypted_password, confirmed_at, created_at, updated_at) values
  ('11111111-1111-1111-1111-111111111111','client@x.test','authenticated','authenticated','','now()','now()','now()'),
  ('22222222-2222-2222-2222-222222222222','director@x.test','authenticated','authenticated','','now()','now()','now()'),
  ('33333333-3333-3333-3333-333333333333','driver@x.test','authenticated','authenticated','','now()','now()','now()')
on conflict (id) do update set email = excluded.email;

-- public.users with the role each test needs (CHECK: client|branch_manager|company_director|driver)
insert into public.users(id, email, role, created_at, terms_accepted_at) values
  ('11111111-1111-1111-1111-111111111111','client@x.test','client','now()','now()'),
  ('22222222-2222-2222-2222-222222222222','director@x.test','company_director','now()','now()'),
  ('33333333-3333-3333-3333-333333333333','driver@x.test','driver','now()','now()')
on conflict (id) do update set role = excluded.role;

insert into public.products(id, name, category, unit_price, is_active, created_at)
  values ('77777777-0000-0000-0000-000000000007','TestProduct','test',100,true,now())
  on conflict (id) do nothing;

-- valid PER_UNIT rule: 2 units * 5 = earn 10 (0023 contract: customer_type null,
-- product_values null, bonus_value>=0, value_basis PER_UNIT)
insert into public.bonus_rules_v2(id, name, rule_type, value_basis, bonus_value, status, created_at, updated_at)
  values ('55555555-5555-5555-5555-555555555555','TestRule','PRODUCT','PER_UNIT',5,'active','now()','now()')
  on conflict (id) do nothing;

-- bonus_accounts row for the client (account_id FK target; E1 also creates one on first earn)
insert into public.bonus_accounts(user_id, mode, status, currency)
  values ('11111111-1111-1111-1111-111111111111','SALES','active','YER')
  on conflict (user_id) do nothing;

-- the E1 order (id PK): starts 'pending'; TEST #1 flips it to 'delivered'
insert into public.orders(id, client_id, status)
  values ('66666666-6666-6666-6666-666666666666','11111111-1111-1111-1111-111111111111','pending')
  on conflict (id) do update set status = 'pending', client_id = '11111111-1111-1111-1111-111111111111';

-- prerequisite gate: isolated scratch must be at the 0024 tip with 0017 applied
do $$
declare c int;
begin
  select count(*) into c from public.financial_companies;
  if c <> 1 then raise exception 'SETUP FAIL: expected 1 financial_company, got %', c; end if;
  select count(*) into c from public.financial_accounts where code = '2110';
  if c <> 1 then raise exception 'SETUP FAIL: 2110 deferred_bonus_liability missing (0017)'; end if;
  select count(*) into c from public.financial_accounts where code = '6000';
  if c <> 1 then raise exception 'SETUP FAIL: 6000 bonus_expense missing (0007 seed)'; end if;
end $$;

-- ── helper: insert a direct EARN POSTED row (bypasses the engine; the AFTER
--    INSERT trigger still fires the accounting hook). Scratch-only test helper.
--    Single positional arg = p_tag (a descriptive label); account/actor/rule/amount
--    default to the phase-1 fixtures. idempotency_key is unique per call, so
--    repeated runs never collide.
create or replace function public._ph61_insert_earn(p_tag text,
  p_actor uuid default '11111111-1111-1111-1111-111111111111',
  p_rule uuid default '55555555-5555-5555-5555-555555555555',
  p_amount int default 10)
returns uuid language plpgsql as $h$
declare _id uuid;
begin
  insert into public.bonus_ledger
    (account_id, txn_type, amount, status, order_id, rule_id, actor, reference, notes, idempotency_key)
  values
    ('11111111-1111-1111-1111-111111111111', 'EARN', p_amount, 'POSTED',
     null, p_rule, p_actor, p_tag, 'ph61-test',
     p_tag || ':' || gen_random_uuid()::text)
  returning id into _id;
  return _id;
end;
$h$;

\echo == TEST #1: one E1 earn produces POSTED row + E1 identity (real E1 path) ==
do $$
declare
  v_key   text := 'SALES_EARN:66666666-6666-6666-6666-666666666666:55555555-5555-5555-5555-555555555555';
  v_count int; v_amt numeric(12,2); v_rule uuid; v_actor uuid; v_lid uuid; v_dec int;
begin
  -- fresh client/order: pending -> delivered triggers the real E1 commit
  insert into public.orders(id, client_id, status)
    values ('66666666-6666-6666-6666-666666666666', '11111111-1111-1111-1111-111111111111', 'pending')
  on conflict (id) do update set status = 'pending';

  insert into public.order_items(order_id, product_id, quantity, unit_price, is_bonus)
    values ('66666666-6666-6666-6666-666666666666', '77777777-0000-0000-0000-000000000007', 2, 100, false)
  on conflict (id) do nothing;

  update public.orders set status = 'delivered' where id = '66666666-6666-6666-6666-666666666666';

  select count(*) into v_count from public.bonus_ledger
   where order_id = '66666666-6666-6666-6666-666666666666' and txn_type = 'EARN' and status = 'POSTED';
  if v_count <> 1 then raise exception 'TEST #1 FAIL: expected 1 POSTED EARN, got %', v_count; end if;

  select id, amount, rule_id, actor, idempotency_key
    into v_lid, v_amt, v_rule, v_actor, v_key
    from public.bonus_ledger
   where order_id = '66666666-6666-6666-6666-666666666666' and txn_type = 'EARN';
  if v_amt <> 10 then raise exception 'TEST #1 FAIL: amount=% expected 10 (2 units * 5)', v_amt; end if;
  if v_rule <> '55555555-5555-5555-5555-555555555555' then raise exception 'TEST #1 FAIL: rule_id mismatch'; end if;
  if v_actor <> '11111111-1111-1111-1111-111111111111' then raise exception 'TEST #1 FAIL: actor mismatch'; end if;
  if v_key <> 'SALES_EARN:66666666-6666-6666-6666-666666666666:55555555-5555-5555-5555-555555555555' then
    raise exception 'TEST #1 FAIL: idempotency_key not the E1 identity';
  end if;

  select count(*) into v_dec from public.bonus_audit_trail
   where entity = 'bonus_ledger_accounting' and entity_id = v_lid and action = 'EARN_ACCOUNTING_DECISION';
  if v_dec <> 1 then raise exception 'TEST #1 FAIL: expected 1 accounting DECISION, got %', v_dec; end if;

  raise notice 'TEST #1 PASS: real E1 -> 1 POSTED EARN (amount=10, actor=client, key=SALES_EARN:order:rule) + trigger fired 1 DECISION';
end $$;

\echo == TEST #2: reprocessing yields no duplicate ledger/decision/journal ==
do $$
declare
  v_lid   uuid; n_earn int; n_dec int; rec jsonb;
begin
  select id into v_lid from public.bonus_ledger where idempotency_key = 'SALES_EARN:66666666-6666-6666-6666-666666666666:55555555-5555-5555-5555-555555555555';
  if v_lid is null then raise exception 'TEST #2 FAIL: no earn from #1'; end if;

  -- (a) E1 evaluator idempotency key UNIQUE -> no new ledger row
  perform public.bonus_evaluate_order_earn('66666666-6666-6666-6666-666666666666');
  select count(*) into n_earn from public.bonus_ledger where idempotency_key = 'SALES_EARN:66666666-6666-6666-6666-666666666666:55555555-5555-5555-5555-555555555555';
  if n_earn <> 1 then raise exception 'TEST #2 FAIL (a): ledger rows=% expected 1', n_earn; end if;

  -- (b) accounting hook itself is idempotent (audit row = dedup key)
  rec := public.apply_bonus_earn_accounting(v_lid);
  if (rec->>'alreadyDecided')::boolean is not true then
    raise exception 'TEST #2 FAIL (b): re-call not idempotent';
  end if;
  select count(*) into n_dec from public.bonus_audit_trail
   where entity = 'bonus_ledger_accounting' and entity_id = v_lid and action = 'EARN_ACCOUNTING_DECISION';
  if n_dec <> 1 then raise exception 'TEST #2 FAIL (b): decision rows=% expected 1', n_dec; end if;

  raise notice 'TEST #2 PASS: no duplicate ledger/decision/journal on reprocess';
end $$;

\echo == TEST #3: missing / invalid policy -> fail_closed (no journal) ==
do $$
declare
  l_missing uuid; l_invalid uuid; l_dec jsonb; n_j int;
begin
  delete from public.bonus_settings where key = 'accounting_policy.BD-01';

  l_missing := public._ph61_insert_earn('EARN_3_missing');
  select new_value into l_dec from public.bonus_audit_trail
   where entity = 'bonus_ledger_accounting' and entity_id = l_missing and action = 'EARN_ACCOUNTING_DECISION';
  if (l_dec->>'effect') <> 'fail_closed' or (l_dec->>'code') <> 'ACCOUNTING_POLICY_NOT_CONFIGURED' then
    raise exception 'TEST #3 FAIL (missing): effect=% code=%', l_dec->>'effect', l_dec->>'code';
  end if;

  insert into public.bonus_settings(key, value) values ('accounting_policy.BD-01', '"X"'::jsonb)
    on conflict (key) do update set value = excluded.value;
  l_invalid := public._ph61_insert_earn('EARN_3_invalid');
  select new_value into l_dec from public.bonus_audit_trail
   where entity = 'bonus_ledger_accounting' and entity_id = l_invalid and action = 'EARN_ACCOUNTING_DECISION';
  if (l_dec->>'effect') <> 'fail_closed' or (l_dec->>'code') <> 'INVALID_ACCOUNTING_POLICY' then
    raise exception 'TEST #3 FAIL (invalid): effect=% code=%', l_dec->>'effect', l_dec->>'code';
  end if;

  select count(*) into n_j from public.financial_journal_entries;
  if n_j <> 0 then raise exception 'TEST #3 FAIL: journal rows=% expected 0', n_j; end if;
  raise notice 'TEST #3 PASS: missing BD-01 -> fail_closed ACCOUNTING_POLICY_NOT_CONFIGURED; invalid -> fail_closed INVALID_ACCOUNTING_POLICY; 0 journals';
end $$;

\echo == TEST #4: each BD-01 option A/B/C yields the prescribed outcome ==
do $$
declare
  l_id uuid; l_dec jsonb;
begin
  delete from public.bonus_settings where key in ('accounting_policy.BD-01','accounting_policy.BD-08','accounting_policy.BD-09');
  insert into public.bonus_settings(key, value) values ('accounting_policy.BD-08','"A"'::jsonb), ('accounting_policy.BD-09','"A"'::jsonb)
    on conflict (key) do update set value = excluded.value;

  -- C -> no_entry
  insert into public.bonus_settings(key, value) values ('accounting_policy.BD-01','"C"'::jsonb)
    on conflict (key) do update set value = excluded.value;
  l_id := public._ph61_insert_earn('EARN_4_C');
  select new_value into l_dec from public.bonus_audit_trail where entity='bonus_ledger_accounting' and entity_id=l_id and action='EARN_ACCOUNTING_DECISION';
  if (l_dec->>'effect') <> 'no_entry' then raise exception 'TEST #4 C FAIL: effect=%', l_dec->>'effect'; end if;
  if (l_dec->>'code') is not null then raise exception 'TEST #4 C FAIL: expected null code, got %', l_dec->>'code'; end if;
  if (l_dec->>'journalEntryId') is not null then raise exception 'TEST #4 C FAIL: journalEntryId set'; end if;

  -- A + BD-08 A -> would_post + POSTING_AUTHORITY_REQUIRED, liability 2110 resolved
  insert into public.bonus_settings(key, value) values ('accounting_policy.BD-01','"A"'::jsonb)
    on conflict (key) do update set value = excluded.value;
  l_id := public._ph61_insert_earn('EARN_4_A_auth');
  select new_value into l_dec from public.bonus_audit_trail where entity='bonus_ledger_accounting' and entity_id=l_id and action='EARN_ACCOUNTING_DECISION';
  if (l_dec->>'effect') <> 'would_post' then raise exception 'TEST #4 A FAIL: effect=%', l_dec->>'effect'; end if;
  if (l_dec->>'code') <> 'POSTING_AUTHORITY_REQUIRED' then raise exception 'TEST #4 A FAIL: code=%', l_dec->>'code'; end if;
  if (l_dec->'intendedAccounts' @> '[{"role":"deferred_bonus_liability","code":"2110"}]'::jsonb) is not true then
    raise exception 'TEST #4 A FAIL: intendedAccounts=%', l_dec->'intendedAccounts';
  end if;

  -- A + BD-08 B -> would_post + ACCOUNT_MAPPING_REQUIRED (credit offset = ACC-03 out of scope)
  insert into public.bonus_settings(key, value) values ('accounting_policy.BD-08','"B"'::jsonb)
    on conflict (key) do update set value = excluded.value;
  l_id := public._ph61_insert_earn('EARN_4_A_bd08b');
  select new_value into l_dec from public.bonus_audit_trail where entity='bonus_ledger_accounting' and entity_id=l_id and action='EARN_ACCOUNTING_DECISION';
  if (l_dec->>'effect') <> 'would_post' or (l_dec->>'code') <> 'ACCOUNT_MAPPING_REQUIRED' then
    raise exception 'TEST #4 A/BD-08B FAIL: effect=% code=%', l_dec->>'effect', l_dec->>'code';
  end if;

  -- B + BD-08 A -> would_post + ACCOUNT_MAPPING_REQUIRED, expense 6000 resolved
  insert into public.bonus_settings(key, value) values ('accounting_policy.BD-01','"B"'::jsonb), ('accounting_policy.BD-08','"A"'::jsonb)
    on conflict (key) do update set value = excluded.value;
  l_id := public._ph61_insert_earn('EARN_4_B');
  select new_value into l_dec from public.bonus_audit_trail where entity='bonus_ledger_accounting' and entity_id=l_id and action='EARN_ACCOUNTING_DECISION';
  if (l_dec->>'effect') <> 'would_post' or (l_dec->>'code') <> 'ACCOUNT_MAPPING_REQUIRED' then
    raise exception 'TEST #4 B FAIL: effect=% code=%', l_dec->>'effect', l_dec->>'code';
  end if;
  if (l_dec->'intendedAccounts' @> '[{"role":"bonus_expense","code":"6000"}]'::jsonb) is not true then
    raise exception 'TEST #4 B FAIL: intendedAccounts=%', l_dec->'intendedAccounts';
  end if;

  raise notice 'TEST #4 PASS: C(no_entry) | A+BD08A(POSTING_AUTHORITY_REQUIRED/2110) | A+BD08B(ACCOUNT_MAPPING_REQUIRED) | B+BD08A(ACCOUNT_MAPPING_REQUIRED/6000)';
end $$;

\echo == TEST #5: BD-08 C / BD-09 C -> no journal, infra-required sentinel ==
do $$
declare
  l_id uuid; l_dec jsonb; n_j int;
begin
  delete from public.bonus_settings where key in ('accounting_policy.BD-01','accounting_policy.BD-08','accounting_policy.BD-09');
  insert into public.bonus_settings(key, value) values ('accounting_policy.BD-01','"A"'::jsonb)
    on conflict (key) do update set value = excluded.value;

  -- BD-08 C (periodic netting) -> no scheduler -> TIMING_INFRASTRUCTURE_REQUIRED
  insert into public.bonus_settings(key, value) values ('accounting_policy.BD-08','"C"'::jsonb), ('accounting_policy.BD-09','"A"'::jsonb)
    on conflict (key) do update set value = excluded.value;
  l_id := public._ph61_insert_earn('EARN_5_bd08c');
  select new_value into l_dec from public.bonus_audit_trail where entity='bonus_ledger_accounting' and entity_id=l_id and action='EARN_ACCOUNTING_DECISION';
  if (l_dec->>'effect') <> 'would_post' then raise exception 'TEST #5 BD-08C FAIL: effect=%', l_dec->>'effect'; end if;
  if (l_dec->>'code') <> 'TIMING_INFRASTRUCTURE_REQUIRED' then raise exception 'TEST #5 BD-08C FAIL: code=%', l_dec->>'code'; end if;
  if (l_dec->>'journalEntryId') is not null then raise exception 'TEST #5 BD-08C FAIL: journalEntryId set'; end if;

  -- BD-09 C (periodic netting) -> scheduler + company-netting-key gap -> POSTING_INFRASTRUCTURE_REQUIRED
  insert into public.bonus_settings(key, value) values ('accounting_policy.BD-08','"A"'::jsonb), ('accounting_policy.BD-09','"C"'::jsonb)
    on conflict (key) do update set value = excluded.value;
  l_id := public._ph61_insert_earn('EARN_5_bd09c');
  select new_value into l_dec from public.bonus_audit_trail where entity='bonus_ledger_accounting' and entity_id=l_id and action='EARN_ACCOUNTING_DECISION';
  if (l_dec->>'effect') <> 'would_post' or (l_dec->>'code') <> 'POSTING_INFRASTRUCTURE_REQUIRED' then
    raise exception 'TEST #5 BD-09C FAIL: effect=% code=%', l_dec->>'effect', l_dec->>'code';
  end if;

  select count(*) into n_j from public.financial_journal_entries;
  if n_j <> 0 then raise exception 'TEST #5 FAIL: journal rows=% expected 0', n_j; end if;
  raise notice 'TEST #5 PASS: BD-08C -> would_post/TIMING_INFRASTRUCTURE_REQUIRED; BD-09C -> would_post/POSTING_INFRASTRUCTURE_REQUIRED; 0 journals';
end $$;

\echo == TEST #6: no journal ever created; engine statically never calls create/post journal_rpc ==
do $$
declare
  n_j int; n_jid int; def text;
begin
  select count(*) into n_j from public.financial_journal_entries;
  if n_j <> 0 then raise exception 'TEST #6 FAIL (a): financial_journal_entries=% expected 0', n_j; end if;

  -- NOTE: use ->> (text) not -> (jsonb). With ->, a stored JSON null is returned
  -- as a jsonb null VALUE (not SQL NULL), so "(…->'k') is not null" is TRUE for a
  -- JSON-null field — a false positive. ->>> returns SQL NULL for both absent and
  -- JSON-null, so "is not null" correctly fires only on an actual journal id.
  select count(*) into n_jid from public.bonus_audit_trail
   where action = 'EARN_ACCOUNTING_DECISION'
     and ((new_value->>'journalEntryId') is not null or (new_value->>'journalId') is not null);
  if n_jid <> 0 then raise exception 'TEST #6 FAIL (b): % decisions carry a journal id', n_jid; end if;

  -- Static proof: the accounting engine and its trigger wrapper must NEVER invoke
  -- the (director-only) create/post journal RPCs. oid-based lookup is used (robust
  -- vs. the regclass text form, which is fragile for security-definer signatures).
  select pg_get_functiondef(p.oid) into def
   from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'apply_bonus_earn_accounting'
   limit 1;
  if def like '%public.create_financial_journal_entry(%' then
    raise exception 'TEST #6 FAIL (c): apply_bonus_earn_accounting CALLS create_financial_journal_entry';
  end if;
  if def like '%public.post_financial_journal_entry(%' then
    raise exception 'TEST #6 FAIL (c): apply_bonus_earn_accounting CALLS post_financial_journal_entry';
  end if;
  select pg_get_functiondef(p.oid) into def
   from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'bonus_on_ledger_earn_posted'
   limit 1;
  if def like '%public.create_financial_journal_entry(%' or def like '%public.post_financial_journal_entry(%' then
    raise exception 'TEST #6 FAIL (c): wrapper calls a journal RPC';
  end if;
  raise notice 'TEST #6 PASS: 0 journal rows; every DECISION journalEntryId=null; static proof engine never calls create/post_financial_journal_entry';
end $$;

\echo == TEST #7: policy change AFTER an earn -> history-locked, no reprocess/duplicate ==
do $$
declare
  l_id uuid; l_snap0 text; l_snap1 text; l_n0 int; l_n1 int; l_rec jsonb; v_sk text;
begin
  delete from public.bonus_settings where key in ('accounting_policy.BD-01','accounting_policy.BD-08','accounting_policy.BD-09');
  insert into public.bonus_settings(key, value) values
    ('accounting_policy.BD-01','"A"'::jsonb), ('accounting_policy.BD-08','"A"'::jsonb), ('accounting_policy.BD-09','"A"'::jsonb)
  on conflict (key) do update set value = excluded.value;

  l_id := public._ph61_insert_earn('EARN_7');
  select count(*) into l_n0 from public.bonus_audit_trail
   where entity='bonus_ledger_accounting' and entity_id=l_id and action='EARN_ACCOUNTING_DECISION';
  if l_n0 <> 1 then raise exception 'TEST #7 FAIL: expected 1 decision, got %', l_n0; end if;

  v_sk := 'accounting_policy.snapshot.' || l_id::text;
  select trim(both '"' from value::text) into l_snap0 from public.bonus_settings where key = v_sk;
  if l_snap0 <> 'A' then raise exception 'TEST #7 FAIL: snapshot before change = % expected A', l_snap0; end if;

  -- director flips BD-01 A->B AFTER the earn is settled
  insert into public.bonus_settings(key, value) values ('accounting_policy.BD-01','"B"'::jsonb)
    on conflict (key) do update set value = excluded.value;

  -- replay path: no-op, NOT a re-evaluation under B
  l_rec := public.apply_bonus_earn_accounting(l_id);
  if (l_rec->>'alreadyDecided')::boolean is not true then
    raise exception 'TEST #7 FAIL: replay was not idempotent';
  end if;
  select count(*) into l_n1 from public.bonus_audit_trail
   where entity='bonus_ledger_accounting' and entity_id=l_id and action='EARN_ACCOUNTING_DECISION';
  if l_n1 <> 1 then raise exception 'TEST #7 FAIL: decision rows=% expected 1 (no re-decision)', l_n1; end if;

  -- snapshot must STILL read A (first-wins / history-locked)
  select trim(both '"' from value::text) into l_snap1 from public.bonus_settings where key = v_sk;
  if l_snap1 <> 'A' then raise exception 'TEST #7 FAIL: snapshot after change = % expected A (history-locked)', l_snap1; end if;

  raise notice 'TEST #7 PASS: policy flip A->B after earn did not reprocess, did not duplicate (decisions=%), snapshot stayed A (history-locked)', l_n1;
end $$;

\echo == TEST #8a: signature (p_ledger_id only) + wrapper is a trigger (no args) ==
do $$
declare s text;
begin
  -- oid-based lookup (robust vs. the regclass text form, which is fragile for
  -- security-definer signatures — see TEST #6(c)).
  select pg_get_function_arguments(p.oid) into s
   from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'apply_bonus_earn_accounting'
   limit 1;
  if s <> 'p_ledger_id uuid' then
    raise exception 'TEST #8a FAIL: signature=% expected "p_ledger_id uuid"', s;
  end if;
  select pg_get_function_arguments(p.oid) into s
   from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'bonus_on_ledger_earn_posted'
   limit 1;
  if s is not null and s <> '' then
    raise exception 'TEST #8a FAIL: wrapper signature=% expected empty', s;
  end if;
  raise notice 'TEST #8a PASS: apply_bonus_earn_accounting(p_ledger_id uuid); wrapper is SECURITY DEFINER trigger (no args)';
end $$;

\echo == TEST #8b: non-director (driver) cannot post; director passes the authority gate ==
-- driver (E1 earn session role) is blocked AT the guard, before the entry lookup;
-- director passes the guard and reaches 'Journal entry not found' (fake id).
do $$
begin
  perform set_config('request.jwt.claim.sub', '33333333-3333-3333-3333-333333333333', true); -- driver
  begin
    perform public.post_financial_journal_entry('00000000-0000-0000-0000-000000000000'::uuid);
    raise exception 'TEST #8b FAIL: non-director (driver) was allowed to call post_financial_journal_entry';
  exception when others then
    if sqlerrm like '%not found%' or sqlerrm like '%Only draft%' or sqlerrm like '%balanced%' or sqlerrm like '%Period%' then
      raise exception 'TEST #8b FAIL: driver reached PAST the director guard (bypassed): %', sqlerrm;
    end if;
    raise notice 'TEST #8b PASS: non-director (driver) blocked at director-only post guard';
  end;
end $$;

do $$
begin
  perform set_config('request.jwt.claim.sub', '22222222-2222-2222-2222-222222222222', true); -- company_director
  begin
    perform public.post_financial_journal_entry('00000000-0000-0000-0000-000000000000'::uuid);
    raise exception 'TEST #8b FAIL: director call did not raise (unexpected success)';
  exception when others then
    if sqlerrm not like '%not found%' then
      raise exception 'TEST #8b FAIL: director passed guard but unexpected error: %', sqlerrm;
    end if;
    raise notice 'TEST #8b PASS: company_director passes the authority guard -> reaches entry-lookup (Journal entry not found), proving the gate is role-based';
  end;
end $$;

-- teardown: remove the ephemeral test helper (not a migration; scratch-only)
drop function if exists public._ph61_insert_earn(text,uuid,uuid,int);
\echo == Phase-1 E1->GL integration test harness: ALL 8 TESTS DONE ==
