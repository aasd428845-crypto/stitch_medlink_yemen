-- PHASE 66 — focused cancellation behavior tests (isolated local DB only).
\set ON_ERROR_STOP off

-- fixtures
insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-4000-8000-000000000a61','medlink+director66@invalid','{"name":"D66","role":"company_director"}'::jsonb),
  ('00000000-0000-4000-8000-000000000a62','medlink+client66@invalid','{"name":"C66","role":"client"}'::jsonb),
  ('00000000-0000-4000-8000-000000000a63','medlink+branch66@invalid','{"name":"B66","role":"branch_manager"}'::jsonb)
on conflict (id) do nothing;
insert into public.users (id, email, name, role, branch_id) values
  ('00000000-0000-4000-8000-000000000a61','medlink+director66@invalid','D66','company_director', null),
  ('00000000-0000-4000-8000-000000000a62','medlink+client66@invalid','C66','client', null),
  ('00000000-0000-4000-8000-000000000a63','medlink+branch66@invalid','B66','branch_manager', '00000000-0000-4000-8000-0000000000b1')
on conflict (id) do update set role = excluded.role;
insert into public.client_addresses (id, client_id, label, address_text, governorate)
values ('00000000-0000-4000-8000-000000000a00','00000000-0000-4000-8000-000000000a62','ADDR66','x','TEST_GOV')
on conflict (id) do nothing;

-- orders: f101 normal (client), f102 normal (branch), f103 bonus (customer), f104 bonus (branch)
insert into public.orders (id, client_id, branch_id, delivery_address_id, status, total_amount) values
  ('00000000-0000-4000-8000-000000000211','00000000-0000-4000-8000-000000000a62','00000000-0000-4000-8000-0000000000b1','00000000-0000-4000-8000-000000000a00','pending',100),
  ('00000000-0000-4000-8000-000000000212','00000000-0000-4000-8000-000000000a62','00000000-0000-4000-8000-0000000000b1','00000000-0000-4000-8000-000000000a00','pending',100),
  ('00000000-0000-4000-8000-000000000213','00000000-0000-4000-8000-000000000a62','00000000-0000-4000-8000-0000000000b1','00000000-0000-4000-8000-000000000a00','pending',500),
  ('00000000-0000-4000-8000-000000000214','00000000-0000-4000-8000-000000000a62','00000000-0000-4000-8000-0000000000b1','00000000-0000-4000-8000-000000000a00','pending',200)
on conflict (id) do nothing;
insert into public.order_items (order_id, product_id, quantity, unit_price, is_bonus) values
  ('00000000-0000-4000-8000-000000000211','00000000-0000-4000-8000-000000000001',1,100,false),
  ('00000000-0000-4000-8000-000000000212','00000000-0000-4000-8000-000000000001',1,100,false),
  ('00000000-0000-4000-8000-000000000213','00000000-0000-4000-8000-000000000001',5,100,false),
  ('00000000-0000-4000-8000-000000000214','00000000-0000-4000-8000-000000000001',2,100,false)
on conflict do nothing;

insert into public.bonus_accounts (user_id, mode, status) values
  ('00000000-0000-4000-8000-000000000a62', 'SALES', 'active')
on conflict (user_id) do nothing;

insert into public.bonus_ledger
  (account_id, txn_type, amount, status, order_id, actor, reference, notes, idempotency_key)
values
  ('00000000-0000-4000-8000-000000000a62','ORDER_DISCOUNT',-200,'POSTED','00000000-0000-4000-8000-000000000213','00000000-0000-4000-8000-000000000a62','TEST_DISCOUNT_213','{"version":"discount_policy_v1","cancellation_mode":"AUTOMATIC_REVERSAL","order_total":500,"applied":200}','TEST_DISCOUNT_213'),
  ('00000000-0000-4000-8000-000000000a62','ORDER_DISCOUNT',-50,'POSTED','00000000-0000-4000-8000-000000000214','00000000-0000-4000-8000-000000000a62','TEST_DISCOUNT_214','{"version":"discount_policy_v1","cancellation_mode":"AUTOMATIC_REVERSAL","order_total":200,"applied":50}','TEST_DISCOUNT_214');

-- T1: customer cancels normal order (no bonus)
set request.jwt.claims = '{"sub":"00000000-0000-4000-8000-000000000a62","role":"authenticated"}';
select 'T1_cancel_normal|' || coalesce(public.cancel_order_with_discount('00000000-0000-4000-8000-000000000211','client changed mind','K2_TK_T1_101')::text,'null');
select 'T1_status|' || status from public.orders where id='00000000-0000-4000-8000-000000000211';
select 'T1_hist|' || source || '/' || coalesce(reversal_ledger_id::text,'no-reversal') from public.order_cancellations where order_id='00000000-0000-4000-8000-000000000211';

-- T2: duplicate cancellation (same key + different key) must not duplicate
select 'T2a_dup_key|' || coalesce(public.cancel_order_with_discount('00000000-0000-4000-8000-000000000211','client changed mind','K2_TK_T1_101')::text,'null');
select 'T2b_dup_diffkey|' || coalesce(public.cancel_order_with_discount('00000000-0000-4000-8000-000000000211','client changed mind','K2_TK_T2_101')::text,'null');
select 'T2_histcount|' || count(*) from public.order_cancellations where order_id='00000000-0000-4000-8000-000000000211';
select 'T2_ledgercount|' || count(*) from public.bonus_ledger where order_id='00000000-0000-4000-8000-000000000211';

-- T3: branch manager cancels normal order
set request.jwt.claims = '{"sub":"00000000-0000-4000-8000-000000000a63","role":"authenticated"}';
select 'T3_branch_cancel_normal|' || coalesce(public.cancel_order_with_discount('00000000-0000-4000-8000-000000000212','branch shortage','K2_TK_T3_102')::text,'null');
select 'T3_status|' || status from public.orders where id='00000000-0000-4000-8000-000000000212';
select 'T3_hist|' || source from public.order_cancellations where order_id='00000000-0000-4000-8000-000000000212';

-- T4: customer cancels bonus order -> ORDER_DISCOUNT reversal
set request.jwt.claims = '{"sub":"00000000-0000-4000-8000-000000000a62","role":"authenticated"}';
select 'T4_cancel_bonus_order|' || coalesce(public.cancel_order_with_discount('00000000-0000-4000-8000-000000000213','no longer needed','K2_TK_T4_103')::text,'null');
select 'T4_status|' || status from public.orders where id='00000000-0000-4000-8000-000000000213';
select 'T4_reversal|' || txn_type || '=' || amount || ' key=' || idempotency_key from public.bonus_ledger where order_id='00000000-0000-4000-8000-000000000213' and txn_type='REVERSAL';

-- T5: duplicate cancel of bonus order must not double-reverse
select 'T5a_dup1|' || coalesce(public.cancel_order_with_discount('00000000-0000-4000-8000-000000000213','no longer needed','K2_TK_T4_103')::text,'null');
select 'T5b_dup2|' || coalesce(public.cancel_order_with_discount('00000000-0000-4000-8000-000000000213','no longer needed','K2_TK_T5_103')::text,'null');
select 'T5_reversalcount|' || count(*) from public.bonus_ledger where order_id='00000000-0000-4000-8000-000000000213' and txn_type='REVERSAL';
select 'T5_histcount|' || count(*) from public.order_cancellations where order_id='00000000-0000-4000-8000-000000000213';

-- T6: branch manager cancels bonus order -> reversal created once
set request.jwt.claims = '{"sub":"00000000-0000-4000-8000-000000000a63","role":"authenticated"}';
select 'T6_branch_cancel_bonus|' || coalesce(public.cancel_order_with_discount('00000000-0000-4000-8000-000000000214','branch correction','K2_TK_T6_104')::text,'null');
select 'T6_reversal|' || txn_type || '=' || amount from public.bonus_ledger where order_id='00000000-0000-4000-8000-000000000214' and txn_type='REVERSAL';
select 'T6_hist|' || source from public.order_cancellations where order_id='00000000-0000-4000-8000-000000000214';

-- T7: direct duplicate POSTED reversal on same reverses_id must fail (partial unique index)
select 'T7_direct_duplicate_reversal|' || (case when (test_exec($x$
  insert into public.bonus_ledger (account_id, txn_type, amount, status, order_id, reverses_id, idempotency_key)
  select account_id, 'REVERSAL', -amount, 'POSTED', order_id, id, 'TEST_DUP_REV'
  from public.bonus_ledger where idempotency_key='TEST_DISCOUNT_213'
$x$) like 'OK') then 'FAIL: duplicate allowed' else 'OK: duplicate rejected' end);
