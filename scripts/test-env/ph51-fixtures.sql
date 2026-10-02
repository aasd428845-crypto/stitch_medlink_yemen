-- PHASE 51 synthetic fixtures for the isolated scratch DB.
-- NO production data is copied. All names/emails are TEST_ markers only.
-- Fixed UUID literals in a reserved TEST block keep runs deterministic.
-- public.users rows are written directly (ON CONFLICT UPDATE) so fixtures
-- remain valid after a drop-schema reset, when the auth trigger is recreated
-- but auth.users already holds the ids.

insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-4000-8000-0000000000d1','medlink-test+director@invalid','{"name":"TEST_DIRECTOR","role":"company_director"}'::jsonb),
  ('00000000-0000-4000-8000-0000000000c1','medlink-test+client@invalid','{"name":"TEST_CLIENT_A","role":"client"}'::jsonb),
  ('00000000-0000-4000-8000-0000000000c2','medlink-test+clientb@invalid','{"name":"TEST_CLIENT_B","role":"client"}'::jsonb)
on conflict (id) do nothing;

insert into public.users (id, email, name, role, branch_id) values
  ('00000000-0000-4000-8000-0000000000d1','medlink-test+director@invalid','TEST_DIRECTOR','company_director', NULL),
  ('00000000-0000-4000-8000-0000000000c1','medlink-test+client@invalid','TEST_CLIENT_A','client', NULL),
  ('00000000-0000-4000-8000-0000000000c2','medlink-test+clientb@invalid','TEST_CLIENT_B','client', NULL)
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
  ('00000000-0000-4000-8000-0000000000a1','00000000-0000-4000-8000-0000000000c1','TEST_ADDR','test street','TEST_GOV'),
  ('00000000-0000-4000-8000-0000000000a2','00000000-0000-4000-8000-0000000000c2','TEST_ADDR_B','test street b','TEST_GOV')
on conflict do nothing;
