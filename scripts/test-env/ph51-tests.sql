-- =============================================================
-- PHASE 51 — behavioural tests T1..T15 (+T17/T18 snapshots) for
-- migration 0023 (max_earn contract fix), executed on the FIXED schema.
-- Synthetic TEST_ fixtures only. Isolated scratch container ONLY.
-- Every delivery rule is bound to a dedicated synthetic client via
-- eligible_customers so active rules can never cross-contaminate results.
-- =============================================================

create or replace function test_exec(p_sql text) returns text
language plpgsql as $$
begin
  execute p_sql;
  return 'OK';
exception when others then
  return sqlstate || ': ' || sqlerrm;
end $$;

-- ─────────────────────────── fixtures ───────────────────────────
insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-4000-8000-0000000000d1','medlink-test+director@invalid','{"name":"TEST_DIRECTOR","role":"company_director"}'::jsonb),
  ('00000000-0000-4000-8000-0000000000c1','medlink-test+c1@invalid','{"name":"TEST_C1","role":"client"}'::jsonb),
  ('00000000-0000-4000-8000-0000000000c2','medlink-test+c2@invalid','{"name":"TEST_C2","role":"client"}'::jsonb),
  ('00000000-0000-4000-8000-0000000000c3','medlink-test+c3@invalid','{"name":"TEST_C3","role":"client"}'::jsonb),
  ('00000000-0000-4000-8000-0000000000c4','medlink-test+c4@invalid','{"name":"TEST_C4","role":"client"}'::jsonb),
  ('00000000-0000-4000-8000-0000000000c5','medlink-test+c5@invalid','{"name":"TEST_C5","role":"client"}'::jsonb),
  ('00000000-0000-4000-8000-0000000000c6','medlink-test+c6@invalid','{"name":"TEST_C6","role":"client"}'::jsonb),
  ('00000000-0000-4000-8000-0000000000c7','medlink-test+c7@invalid','{"name":"TEST_C7","role":"client"}'::jsonb),
  ('00000000-0000-4000-8000-0000000000c8','medlink-test+c8@invalid','{"name":"TEST_C8","role":"client"}'::jsonb),
  ('00000000-0000-4000-8000-0000000000c9','medlink-test+c9@invalid','{"name":"TEST_C9","role":"client"}'::jsonb),
  ('00000000-0000-4000-8000-0000000000ca','medlink-test+c10@invalid','{"name":"TEST_C10","role":"client"}'::jsonb)
on conflict (id) do nothing;

-- public.users rows written directly (trigger may have pre-created some).
insert into public.users (id, email, name, role) values
  ('00000000-0000-4000-8000-0000000000d1','medlink-test+director@invalid','TEST_DIRECTOR','company_director'),
  ('00000000-0000-4000-8000-0000000000c1','medlink-test+c1@invalid','TEST_C1','client'),
  ('00000000-0000-4000-8000-0000000000c2','medlink-test+c2@invalid','TEST_C2','client'),
  ('00000000-0000-4000-8000-0000000000c3','medlink-test+c3@invalid','TEST_C3','client'),
  ('00000000-0000-4000-8000-0000000000c4','medlink-test+c4@invalid','TEST_C4','client'),
  ('00000000-0000-4000-8000-0000000000c5','medlink-test+c5@invalid','TEST_C5','client'),
  ('00000000-0000-4000-8000-0000000000c6','medlink-test+c6@invalid','TEST_C6','client'),
  ('00000000-0000-4000-8000-0000000000c7','medlink-test+c7@invalid','TEST_C7','client'),
  ('00000000-0000-4000-8000-0000000000c8','medlink-test+c8@invalid','TEST_C8','client'),
  ('00000000-0000-4000-8000-0000000000c9','medlink-test+c9@invalid','TEST_C9','client'),
  ('00000000-0000-4000-8000-0000000000ca','medlink-test+c10@invalid','TEST_C10','client')
on conflict (id) do update set role = excluded.role, name = excluded.name;

insert into public.branches (id, name, governorate) values
  ('00000000-0000-4000-8000-0000000000b1','TEST_BRANCH_1','TEST_GOV') on conflict do nothing;

insert into public.products (id, name, category, unit_price, is_active) values
  ('00000000-0000-4000-8000-000000000001','TEST_P1_PRODUCT','test',100,true),
  ('00000000-0000-4000-8000-000000000002','TEST_P2_EXCLUDED','test',100,true),
  ('00000000-0000-4000-8000-000000000003','TEST_P3_PERUNIT','test',100,true),
  ('00000000-0000-4000-8000-000000000004','TEST_P4_PERPROD','test',100,true)
on conflict do nothing;

insert into public.client_addresses (id, client_id, label, address_text, governorate) values
  ('00000000-0000-4000-8000-0000000000a1','00000000-0000-4000-8000-0000000000c1','TEST_ADDR','s','TEST_GOV'),
  ('00000000-0000-4000-8000-0000000000a2','00000000-0000-4000-8000-0000000000c2','TEST_ADDR','s','TEST_GOV'),
  ('00000000-0000-4000-8000-0000000000a3','00000000-0000-4000-8000-0000000000c3','TEST_ADDR','s','TEST_GOV'),
  ('00000000-0000-4000-8000-0000000000a4','00000000-0000-4000-8000-0000000000c4','TEST_ADDR','s','TEST_GOV'),
  ('00000000-0000-4000-8000-0000000000a5','00000000-0000-4000-8000-0000000000c5','TEST_ADDR','s','TEST_GOV'),
  ('00000000-0000-4000-8000-0000000000a6','00000000-0000-4000-8000-0000000000c6','TEST_ADDR','s','TEST_GOV'),
  ('00000000-0000-4000-8000-0000000000a7','00000000-0000-4000-8000-0000000000c7','TEST_ADDR','s','TEST_GOV'),
  ('00000000-0000-4000-8000-0000000000a8','00000000-0000-4000-8000-0000000000c8','TEST_ADDR','s','TEST_GOV'),
  ('00000000-0000-4000-8000-0000000000a9','00000000-0000-4000-8000-0000000000c9','TEST_ADDR','s','TEST_GOV'),
  ('00000000-0000-4000-8000-0000000000aa','00000000-0000-4000-8000-0000000000ca','TEST_ADDR','s','TEST_GOV')
on conflict do nothing;

-- orders (pending, one paid line each; created directly — the deliver
-- trigger path is what the tests exercise, not the order-creation RPC).
create or replace function test_make_order(p_oid uuid, p_client uuid, p_prod uuid, p_qty int)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.orders (id, client_id, branch_id, delivery_address_id, status, total_amount)
  select p_oid, p_client,
         '00000000-0000-4000-8000-0000000000b1',
         (select id from public.client_addresses where client_id = p_client),
         'pending', p_qty * 100;
  insert into public.order_items (order_id, product_id, quantity, unit_price, is_bonus)
  values (p_oid, p_prod, p_qty, 100, false);
end $$;

select test_make_order('00000000-0000-4000-8000-0000000000f1','00000000-0000-4000-8000-0000000000c1','00000000-0000-4000-8000-000000000001',1);
select test_make_order('00000000-0000-4000-8000-0000000000f2','00000000-0000-4000-8000-0000000000c2','00000000-0000-4000-8000-000000000001',1);
select test_make_order('00000000-0000-4000-8000-0000000000f3','00000000-0000-4000-8000-0000000000c3','00000000-0000-4000-8000-000000000001',1);
select test_make_order('00000000-0000-4000-8000-0000000000f4','00000000-0000-4000-8000-0000000000c4','00000000-0000-4000-8000-000000000001',5);
select test_make_order('00000000-0000-4000-8000-0000000000f5','00000000-0000-4000-8000-0000000000c5','00000000-0000-4000-8000-000000000003',5);
select test_make_order('00000000-0000-4000-8000-0000000000f6','00000000-0000-4000-8000-0000000000c6','00000000-0000-4000-8000-000000000004',10);
select test_make_order('00000000-0000-4000-8000-0000000000f7','00000000-0000-4000-8000-0000000000c7','00000000-0000-4000-8000-000000000001',1);
select test_make_order('00000000-0000-4000-8000-0000000000f8','00000000-0000-4000-8000-0000000000c8','00000000-0000-4000-8000-000000000001',1);
select test_make_order('00000000-0000-4000-8000-0000000000f9','00000000-0000-4000-8000-0000000000c9','00000000-0000-4000-8000-000000000001',1);
select test_make_order('00000000-0000-4000-8000-0000000000fa','00000000-0000-4000-8000-0000000000ca','00000000-0000-4000-8000-000000000001',1);

-- T14 setup: c10's bonus account pre-created SUSPENDED (before delivery).
insert into public.bonus_accounts (user_id, mode, status)
values ('00000000-0000-4000-8000-0000000000ca', 'SALES', 'suspended')
on conflict (user_id) do update set status = 'suspended';

-- ═══════════════════════ T1–T6: rule write path ═══════════════════════
-- T1: validator accepts max_earn > 0 through the real BEFORE trigger.
select 'T1|' || test_exec($sql$
  insert into public.bonus_rules_v2 (id,name,rule_type,value_basis,bonus_value,max_earn,status)
  values ('00000000-0000-4000-8000-0000000000e1','TEST_T1_RULE','MONETARY','PER_ORDER',500,100,'active')
$sql$);

-- T2: validator rejects max_earn = 0 (real verification path).
select 'T2a|' || test_exec($sql$
  insert into public.bonus_rules_v2 (id,name,rule_type,value_basis,bonus_value,max_earn,status)
  values ('00000000-0000-4000-8000-0000000000e2','TEST_T2_ZERO','MONETARY','PER_ORDER',500,0,'active')
$sql$);
-- T2b: validator rejects max_earn = -1.
select 'T2b|' || test_exec($sql$
  insert into public.bonus_rules_v2 (id,name,rule_type,value_basis,bonus_value,max_earn,status)
  values ('00000000-0000-4000-8000-0000000000e3','TEST_T2_NEG','MONETARY','PER_ORDER',500,-1,'active')
$sql$);

-- T3: NULL cap accepted (unlimited semantics).
select 'T3|' || test_exec($sql$
  insert into public.bonus_rules_v2 (id,name,rule_type,value_basis,bonus_value,max_earn,status)
  values ('00000000-0000-4000-8000-0000000000e4','TEST_T3_NULL','MONETARY','PER_ORDER',500,null,'active')
$sql$);

-- T4: full PWA toDbPayload key set accepted.
select 'T4|' || test_exec($sql$
  insert into public.bonus_rules_v2
    (name,description,rule_type,status,start_date,end_date,min_order_value,min_quantity,
     bonus_value,bonus_percent,max_earn,eligible_customers,customer_type,governorate,
     products_include,products_exclude,is_stackable,priority,usage_limit,
     allow_product,allow_discount,allow_cash,cash_min,cash_max,cash_monthly_limit,
     approval_required,product_values,value_basis)
  values ('TEST_T4_PAYLOAD','desc','MONETARY','active',null,null,null,null,
          null,10,100,null,null,null,
          null,null,false,0,null,
          true,false,false,null,null,null,
          true,null,'PER_ORDER')
$sql$);

-- T5: UPDATE path passes BEFORE UPDATE trigger.
select 'T5|' || test_exec($sql$
  update public.bonus_rules_v2 set name='TEST_T1_RENAMED'
   where id='00000000-0000-4000-8000-0000000000e1'
$sql$);

-- T6: status-only toggles suspended / active.
select 'T6a|' || test_exec($sql$
  update public.bonus_rules_v2 set status='suspended'
   where id='00000000-0000-4000-8000-0000000000e1'
$sql$);
select 'T6b|' || test_exec($sql$
  update public.bonus_rules_v2 set status='active'
   where id='00000000-0000-4000-8000-0000000000e1'
$sql$);

-- quarantine write-path rules so they cannot earn in delivery scenarios
-- (T4's payload rule is unbound => would match EVERY client; must be archived)
update public.bonus_rules_v2 set status='archived'
 where id in ('00000000-0000-4000-8000-0000000000e1','00000000-0000-4000-8000-0000000000e4')
    or name = 'TEST_T4_PAYLOAD';

-- ═══════════════════ delivery rules (one per scenario, bound to a client) ═══════════════════
insert into public.bonus_rules_v2 (id,name,rule_type,value_basis,bonus_value,max_earn,status,eligible_customers)
values
  ('00000000-0000-4000-8000-0000000000e5','TEST_T7_CAP','MONETARY','PER_ORDER',500,200,'active',array['00000000-0000-4000-8000-0000000000c1']::uuid[]),
  ('00000000-0000-4000-8000-0000000000e6','TEST_T8_NOCAP','MONETARY','PER_ORDER',500,null,'active',array['00000000-0000-4000-8000-0000000000c2']::uuid[]),
  ('00000000-0000-4000-8000-0000000000e7','TEST_T9_EQUAL','MONETARY','PER_ORDER',200,200,'active',array['00000000-0000-4000-8000-0000000000c3']::uuid[]),
  ('00000000-0000-4000-8000-0000000000e8','TEST_T10_ZERO','PRODUCT','PER_UNIT',0,null,'active',array['00000000-0000-4000-8000-0000000000c4']::uuid[]),
  ('00000000-0000-4000-8000-0000000000e9','TEST_T11_UNIT','PRODUCT','PER_UNIT',100,250,'active',array['00000000-0000-4000-8000-0000000000c5']::uuid[]),
  ('00000000-0000-4000-8000-0000000000ea','TEST_T11_PROD','PRODUCT','PER_PRODUCT',null,200,'active',array['00000000-0000-4000-8000-0000000000c6']::uuid[])
on conflict do nothing;

update public.bonus_rules_v2
   set product_values = '{"00000000-0000-4000-8000-000000000004": 50}'::jsonb
 where id='00000000-0000-4000-8000-0000000000ea';

insert into public.bonus_rules_v2 (id,name,rule_type,value_basis,bonus_value,max_earn,status,eligible_customers)
values
  ('00000000-0000-4000-8000-0000000000eb','TEST_T12_IDEM','MONETARY','PER_ORDER',100,300,'active',array['00000000-0000-4000-8000-0000000000c7']::uuid[]),
  ('00000000-0000-4000-8000-0000000000ec','TEST_T13_DELIVER','MONETARY','PER_ORDER',100,null,'active',array['00000000-0000-4000-8000-0000000000c8']::uuid[]),
  ('00000000-0000-4000-8000-0000000000ed','TEST_T15_MIN','MONETARY','PER_ORDER',500,null,'active',array['00000000-0000-4000-8000-0000000000c9']::uuid[])
on conflict do nothing;
update public.bonus_rules_v2 set min_order_value=10000 where id='00000000-0000-4000-8000-0000000000ed';
insert into public.bonus_rules_v2 (id,name,rule_type,value_basis,bonus_value,max_earn,status,eligible_customers)
values ('00000000-0000-4000-8000-0000000000ee','TEST_T14_CAP','MONETARY','PER_ORDER',500,200,'active',array['00000000-0000-4000-8000-0000000000ca']::uuid[])
on conflict do nothing;

-- ═══════════════════════ T7–T15: real delivery trigger path ═══════════════════════
-- Each delivery runs through orders.status -> 'delivered' firing
-- trg_bonus_on_order_delivered (the exact production code path).

-- T7: cap applied (value 500, cap 200 -> earn 200).
select 'T7-deliver|' || test_exec($sql$
  update public.orders set status='delivered' where id='00000000-0000-4000-8000-0000000000f1'
$sql$);
select 'T7-assert|' || coalesce(txn_type||'='||amount::text||' n='||cnt::text,'NO-ROW')
from (select txn_type, amount, count(*) over () as cnt from public.bonus_ledger
      where order_id='00000000-0000-4000-8000-0000000000f1') x limit 2;

-- T8: NULL cap = unlimited (earn full 500).
select 'T8-deliver|' || test_exec($sql$
  update public.orders set status='delivered' where id='00000000-0000-4000-8000-0000000000f2'
$sql$);
select 'T8-assert|' || coalesce(txn_type||'='||amount::text,'NO-ROW')
from public.bonus_ledger where order_id='00000000-0000-4000-8000-0000000000f2';

-- T9: exactly at cap not capped (strict >).
select 'T9-deliver|' || test_exec($sql$
  update public.orders set status='delivered' where id='00000000-0000-4000-8000-0000000000f3'
$sql$);
select 'T9-assert|' || coalesce(txn_type||'='||amount::text,'NO-ROW')
from public.bonus_ledger where order_id='00000000-0000-4000-8000-0000000000f3';

-- T10: zero computed earn -> no ledger row, no error.
select 'T10-deliver|' || test_exec($sql$
  update public.orders set status='delivered' where id='00000000-0000-4000-8000-0000000000f4'
$sql$);
select 'T10-assert|rows=' || count(*) from public.bonus_ledger
 where order_id='00000000-0000-4000-8000-0000000000f4';

-- T11a: PER_UNIT 5x100=500 with cap 250.
select 'T11a-deliver|' || test_exec($sql$
  update public.orders set status='delivered' where id='00000000-0000-4000-8000-0000000000f5'
$sql$);
select 'T11a-assert|' || coalesce(txn_type||'='||amount::text,'NO-ROW')
from public.bonus_ledger where order_id='00000000-0000-4000-8000-0000000000f5';

-- T11b: PER_PRODUCT 10x50=500 with cap 200.
select 'T11b-deliver|' || test_exec($sql$
  update public.orders set status='delivered' where id='00000000-0000-4000-8000-0000000000f6'
$sql$);
select 'T11b-assert|' || coalesce(txn_type||'='||amount::text,'NO-ROW')
from public.bonus_ledger where order_id='00000000-0000-4000-8000-0000000000f6';

-- T12: idempotency — evaluator re-invoked for same order (processor-retry shape).
select 'T12-deliver|' || test_exec($sql$
  update public.orders set status='delivered' where id='00000000-0000-4000-8000-0000000000f7'
$sql$);
select 'T12-refire|' || test_exec($sql$
  select public.bonus_evaluate_order_earn('00000000-0000-4000-8000-0000000000f7')
$sql$);
select 'T12-assert|rows=' || count(*) || ' keys_distinct=' || count(distinct idempotency_key)
from public.bonus_ledger where order_id='00000000-0000-4000-8000-0000000000f7';

-- T13: delivery status persists + earn created (primary defect symptom gone).
select 'T13-deliver|' || test_exec($sql$
  update public.orders set status='delivered' where id='00000000-0000-4000-8000-0000000000f8'
$sql$);
select 'T13-assert|status=' || status
from public.orders where id='00000000-0000-4000-8000-0000000000f8';
select 'T13-earn|' || coalesce(txn_type||'='||amount::text,'NO-ROW')
from public.bonus_ledger where order_id='00000000-0000-4000-8000-0000000000f8';

-- T14: suspended account -> hold row, no evaluator error, status persists.
select 'T14-deliver|' || test_exec($sql$
  update public.orders set status='delivered' where id='00000000-0000-4000-8000-0000000000fa'
$sql$);
select 'T14-status|' || status from public.orders where id='00000000-0000-4000-8000-0000000000fa';
select 'T14-hold|' || coalesce(status||'/'||error_reason,'NO-ROW')
from public.bonus_pending_entitlements where order_id='00000000-0000-4000-8000-0000000000fa';
select 'T14-nolearn|rows=' || count(*)
from public.bonus_ledger where order_id='00000000-0000-4000-8000-0000000000fa';

-- T15: min_order_value above order -> no earn, no error.
select 'T15-deliver|' || test_exec($sql$
  update public.orders set status='delivered' where id='00000000-0000-4000-8000-0000000000f9'
$sql$);
select 'T15-assert|rows=' || count(*) from public.bonus_ledger
 where order_id='00000000-0000-4000-8000-0000000000f9';

-- ═══════════════════════ T17/T18 post-fix snapshots ═══════════════════════
select 'T17-COLS', string_agg(column_name, ',' order by ordinal_position)
from information_schema.columns where table_schema='public' and table_name='bonus_rules_v2';
select 'T18-ACL', coalesce(array_to_string(p.proacl, ','), '(default)')
from pg_proc p join pg_namespace n on p.pronamespace=n.oid
where n.nspname='public' and p.proname in ('bonus_check_rule_v2','bonus_evaluate_order_earn')
order by 2, p.proname;
select 'T18-PROSRC_MD5', p.proname, md5(p.prosrc) from pg_proc p
join pg_namespace n on p.pronamespace=n.oid
where n.nspname='public' and p.proname in ('bonus_check_rule_v2','bonus_evaluate_order_earn') order by 2;
