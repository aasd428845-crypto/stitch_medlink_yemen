# PHASE 8 — TEST ENVIRONMENT ARCHITECTURE (design only, 2026-09-30)

**Type:** Architecture / precheck. **Writes made:** none (no DDL, no data, no project created).
**Unblocks:** `PHASE-7-EARN-ENGINE-TEST-DESIGN.md` §R ("BLOCKED — TEST ENVIRONMENT REQUIRED").
**Consumes:** PHASE-5/6 live prechecks, `docs/REWARDS_SYSTEM_MASTER_STATUS.md`, migration audit of `supabase/migrations/` (23 files) and `Medlik-Waap/supabase/migrations/` (16 files).

## 0. Executive verdict

| Question | Answer |
|---|---|
| Is there any safe place to test the Earn Engine today? | **No.** One live project, no staging, no local stack, no seed file. |
| Recommended target | **Option C — disposable "scratch" Supabase project** (same org), bootstrapped from a **read-only production schema snapshot + the repo migration tail**, loaded with `TEST_` fixtures, then **destroyed**. |
| Why not production fixtures | The ledger is append-only *by trigger* (§2 M1), director dashboards sum it globally (§2 M2) and product inserts broadcast notifications to real users (§2 M3). Test rows in prod are **permanent and visible**. |
| Isolation level required | **Project level**, not row level. Marker/tag filtering is rejected as the primary control (§3 Option E). |
| Reset mechanism | **Schema drop-and-replay / project destroy**, never `DELETE` of financial rows (§7). |
| Hard blocker to fix first | CLI is **not authenticated** and **Docker is absent** (§1 F8/F9). |
| Approval gates before any write | (1) project/branch creation, (2) schema dump out of prod, (3) DDL apply into the scratch DB (§8, §9). |

## 1. Current environment facts (evidence)

| # | Fact | Evidence |
|---|---|---|
| F1 | Exactly **one** Supabase project exists: `lmkomzqioneuyvatzsov` ("موريد الادويه"), org `vercel_icfg_DXdo2xd55rXv0SZFfPrVLlZJ` ("MOAMMAR's projects"), Postgres 17.6.1.155, region ap-northeast-1 | `supabase/.temp/project-ref`, `supabase/.temp/linked-project.json`, `supabase/.temp/pooler-url`, `supabase/.temp/postgres-version` |
| F2 | The repo is **already linked to production**: running `supabase db push` from `supabase/` targets prod | `supabase/.temp/project-ref` = `lmkomzqioneuyvatzsov` |
| F3 | The web app's Supabase config also names production | `Medlik-Waap/supabase/config.toml:1` (`project_id = "lmkomzqioneuyvatzsov"`; file contains only `verify_jwt` entries) |
| F4 | **No `seed.sql`, no root `config.toml`, no fixture SQL** anywhere in repo (`find` for `seed.sql`/`config.toml` → only the submodule config) | repo scan |
| F5 | Two migration sources, **not** in dependency order relative to each other: root `supabase/migrations` 0001–0023, web `Medlik-Waap/supabase/migrations` 0001–0016 | `ls` of both dirs |
| F6 | Two filenames exist in **both** dirs with **different content**: `0015_product_images_storage.sql`, `0016_bonus_inventory_allocation_safety.sql` | `diff -q` → "Files … differ" |
| F7 | Edge Functions are split across the two roots: root has `manage-driver-account`; web has `fetch-exchange-rates`, `manage-branch-manager-account`, `manage-client-account`, `_shared` | `ls supabase/functions/`, `ls Medlik-Waap/supabase/functions/` |
| F8 | Supabase CLI **2.117.0** installed (`~/.local/bin/supabase`), but **not logged in**: `~/.supabase/` contains only `telemetry.json` + `traces/`, no access token → `projects`/`branches` (Management API) commands cannot run until `supabase login` | `supabase --version`, `ls -la ~/.supabase/` |
| F9 | **Docker is not installed** → `supabase start`, `supabase db reset --local`, `supabase db diff` against a local DB are impossible | audit earlier this phase; also no root `config.toml` for a local stack (F4) |
| F10 | Web client reads env vars but **falls back to hardcoded production** URL + publishable key | `Medlik-Waap/artifacts/pharma-pwa/src/lib/supabaseClient.ts:5-6` |
| F11 | Flutter client has **no env indirection**: production URL + publishable key are `const` | `medlink_app/lib/utils/constants.dart:10-12`; init in `medlink_app/lib/services/supabase_bootstrap.dart` |
| F12 | Live data at last read-only check (2026-09-21): users 8, branches 22, products 1, orders 2, **all `bonus_*` tables 0 rows** | `PHASE-7-EARN-ENGINE-TEST-DESIGN.md` §C |
| F13 | Live schema contains objects that the **root** migration set never creates (the whole `financial_*` accounting chain, `invoices`, `warehouse_inventory`) | root `create table` map vs `Medlik-Waap/supabase/migrations/0004_phase4_expiry_and_receivables.sql`, `0006_financial_core.sql` |
| F14 | No `uuidv7` convention exists in the repo (grep across `docs/` + migrations) → fixtures may use `gen_random_uuid()` | grep |

**Consequence of F12+F13:** production is today's *only* schema oracle, and its schema is **not fully reproducible from the repo alone** (§5).


## 2. Why "just use production with test rows" fails (six mechanisms)

| ID | Mechanism | Evidence | Effect if tested on prod | Reversible? |
|---|---|---|---|---|
| M1 | **Ledger immutability is enforced by trigger** | `supabase/migrations/0018_bonus_financial_system.sql:50` ("append-only financial truth") + `:111` `before update or delete on public.bonus_ledger` trigger; same pattern in `Medlik-Waap/supabase/migrations/0008_financial_audit_immutability.sql:24,35,41-48` ("Posted journal entries are immutable; use a reversal") | Test EARN rows cannot be deleted or edited; the only in-model correction is a **reversal**, which itself writes **more** ledger rows | **No** |
| M2 | **Director KPIs aggregate the whole ledger with no exclusion** | `bonusFinancialApi.ts:108-111` (`listLedger` = `.select('*')`, no filter); `BonusFinancialDashboardPage.tsx:50` (`listLedger(500)`, `listBonusAccounts()`), `:61` (`if (amount > 0) earned += amount`), `:73,77` (`earned`, `outstanding = earned - spent`) | Every positive test row inflates "earned"/"outstanding" on the director dashboard (capped only by the newest-500 window); `listBonusAccounts()` inflates the accounts KPI | **No** |
| M3 | **Product inserts broadcast notifications to real users** | `Medlik-Waap/supabase/migrations/0014_product_catalog_sync.sql:78` `insert into public.notifications (title, body, target_role, created_by)` fired from a catalog trigger | Creating a `TEST_` product pushes an in-app notification to **every** client/director (role-targeted broadcast) | Rows may be deletable; users already saw them |
| M4 | **Audit trail is write-only** | `bonus_audit_trail` (`0018`), written by director RPCs | Test RPC calls (rule create, processor run, reversal) leave permanent evidence indistinguishable from real operations | **No** |
| M5 | **Shared idempotency + rule scope** | `SALES_EARN:{order}:{rule}` key format (PHASE-6 §L); the 0019 trigger evaluates **any** order that reaches `delivered` | A real customer order delivered mid-test can earn real bonus under a test rule | Only by reversal (adds rows, M1) |
| M6 | **Client-visible balances** | `medlink_app/lib/services/bonus_wallet_service.dart` reads the real account/ledger; `bonus_account_funds` feeds M2 | A test account looks real to the client app, and its reserved/spent figures feed director KPIs | No |

**Design conclusion:** M1/M2/M4 are *irreversible by design*, so cleanup-based strategies (A/E) cannot be made safe. Isolation must move **out of the production database**.

## 3. Options evaluated

| | A. Prod fixtures + cleanup | B. Local Supabase (Docker) | **C. Scratch project (snapshot + migration tail)** | D. Preview branch of prod | E. Prod + `TEST_` markers + query filters |
|---|---|---|---|---|---|
| Financial rows land in prod | **Yes** (fatal) | No | No | No | **Yes** (fatal) |
| Director dashboard stays clean | No (M2) | Yes | Yes | Yes | only after changing every aggregate |
| Real users see anything | **Yes** (M3) | No | No (own auth users, no SMTP configured) | No (separate URL/keys) | **Yes** |
| Schema fidelity | 100% | Low (root chain alone misses web-owned objects, F13) | **High** — copied from a live dump | **Highest** — forks live schema + data | 100% |
| Reset cost | impossible (M1) | seconds (`db reset`) | ~minutes (drop schema + replay tail) | seconds–minutes (reset branch) | n/a |
| PII exposure | n/a | none | none (fixtures created from scratch) | **Full prod PII/financial copy into a 2nd project** | n/a |
| Money | 0 | 0 (needs Docker install) | free/same-org project | **measured 0.01344 USD/hour** (~9.7 USD/month left running) | 0 |
| Hard blockers | ethics/accounting | **F9 Docker absent**, F4 no root `config.toml` | F8 CLI not logged in → `supabase login`, or use the authenticated Supabase MCP path | F8 + data-governance approval | must change production financial reporting code |
| Verdict | **Reject** | blocked now; best long-term dev loop | **RECOMMENDED** | fallback when real `financial_*` fixtures are needed | **Reject** |

**Recommendation:** build **C** now; keep **D** as fallback for any PHASE-7 case needing real accounting fixtures; schedule **B** (Docker + root `config.toml`) as the permanent dev loop so later phases stop needing a cloud DB.

## 4. Recommended architecture (Option C)

```
        REPO (source of truth)                       CLOUD
  ┌───────────────────────────────┐        ┌──────────────────────────────┐
  │ supabase/migrations 0001..0023│        │ PROD  lmkomzqioneuyvatzsov   │
  │ Medlik-Waap/supabase/migr.    │        │  (read-only during Phase 8)  │
  │ supabase/functions/*          │        └───────────┬──────────────────┘
  └───────────────┬───────────────┘                    │ 1. db dump (schema-only,
                  │                                    │    operator-approved)
                  │ 3. apply tail 0017..0023           ▼
                  │ 4. deploy functions        artifacts/test-env/prod-schema.sql
                  │ 5. load TEST_ fixtures            │ (git-ignored, deleted after use)
                  ▼                                   ▼
        ┌─────────────────────────────────────────────────────────┐
        │ SCRATCH PROJECT  (new ref, same org, disposable)        │
        │  schema = prod snapshot + repo tail   ← parity check    │
        │  data   = TEST_ fixtures ONLY (no prod rows, no PII)    │
        │  auth   = own users; SMTP/push NOT configured           │
        │  keys   = own publishable + service key (never in git)  │
        └───────────────┬─────────────────────────────────────────┘
                        │ 6. apps pointed via env / --dart-define
        pharma-pwa .env.local  +  flutter --dart-define=SUPABASE_URL=...
                        │ 7. run PHASE-7 matrix (TEST 1..N)
                        ▼
        8. reset between suites (drop schema + replay tail)
        9. DESTROY project at campaign end
```

Proposed repo additions in the *implementation* phase (not created here — this phase writes no code):

| Path | Purpose |
|---|---|
| `scripts/test-env/build-test-db.sh` | dump → apply → deploy → parity-check, always with **explicit** `--db-url`/`--project-ref`, never `--linked` |
| `scripts/test-env/reset-test-db.sh` | `drop schema public cascade` + replay tail (§7) |
| `scripts/test-env/fixtures/*.sql` | Idempotent `TEST_` fixture sets, one file per PHASE-7 test group |
| `scripts/test-env/.env.test` (git-ignored) | `TEST_PROJECT_REF`, `TEST_DB_URL`, `TEST_PUBLISHABLE_KEY` |
| `artifacts/test-env/` (git-ignored) | Schema dumps / parity diffs — **must never be committed** (full production schema; any data dump contains PII) |

Guardrail inside the scripts: refuse to run if the resolved ref equals `lmkomzqioneuyvatzsov`. Never `supabase link` from the repo root while `supabase/.temp/project-ref` points at prod (F2) — back up and remove `supabase/.temp/`, or always pass `--db-url`.

## 5. Minimum reproducible migration chain

### 5.1 Cross-repo dependency map (measured)

| Root file | Depends on web-owned object | Evidence |
|---|---|---|
| `0009_branch_manager_operations.sql` | `warehouse_inventory`, `invoices` | `:63` `alter table public.warehouse_inventory`, `:73` `alter table public.invoices`, `:78-87` invoice policies, `:187` `insert into public.invoices` |
| `0011_branch_inventory_batch.sql` | `warehouse_inventory` | `:44` `insert into public.warehouse_inventory` |
| `0013_invoices_select_rls.sql` | `invoices` | whole file = policies on `public.invoices` |
| `0016_bonus_inventory_allocation_safety.sql` | `invoices` | `:146` `insert into public.invoices` |
| `0021_order_cancellation_with_discount.sql` | `invoices` / `warehouse_inventory` | 4 references (grep count) |
| web `0003` / `0005` / `0014` | root-owned `promotional_offers`, `notifications` | web 0003 `:15-21` `alter table public.promotional_offers`; web 0014 `:78` notifications insert |

`invoices` + `warehouse_inventory` are created **only** by `Medlik-Waap/supabase/migrations/0004_phase4_expiry_and_receivables.sql`; the `financial_*` chain only by web `0006`–`0013`. No web migration references `bonus_accounts` / `bonus_ledger` / `bonus_rules_v2` / `bonus_withdrawals` (grep) — so bonus never blocks web, only the reverse.

**Therefore replaying `supabase/migrations/0001 → 0023` on an empty DB fails at 0009** (`relation "public.warehouse_inventory" does not exist`). A combined, interleaved chain is mandatory — this is the definitive answer to the "minimum chain" question: **root-only replay is impossible.**

### 5.2 Proposed replay order (37 SQL files)

`R-` = root `supabase/migrations/`, `W-` = `Medlik-Waap/supabase/migrations/`.

| Step | File | Why here |
|---|---|---|
| 1–8 | `R-0001…R-0008` | Base: `users`, `branches`, `products`, `orders`, `order_items`, `inventory`, `promotional_offers`, `bonus_rules`, `notifications`, chat/location + role/RLS helpers. Everything roots here |
| 9 | `W-0001_phase1_foundation` | Creates no tables (verified) — safe after the root base |
| 10 | `W-0002_phase2_readonly_analytics` | Read-only analytics over base tables |
| 11 | `W-0003_phase3_offer_product_discount_columns` | `alter table promotional_offers` ← needs R-0002 |
| 12 | **`W-0004_phase4_expiry_and_receivables`** | **Creates `invoices` + `warehouse_inventory` — the hard unblocker for R-0009** |
| 13 | `R-0009_branch_manager_operations` | First consumer of those two web tables |
| 14 | `W-0005_flexible_notification_targeting` | Needs `notifications` (R-0003); any position ≥ 4 works |
| 15–17 | `R-0010`, `R-0011`, `R-0012` | R-0011 needs `warehouse_inventory` |
| 18 | `R-0013_invoices_select_rls` | Needs `invoices` |
| 19 | `R-0014_client_address_extended_fields` | Independent |
| 20–27 | `W-0006_financial_core` … `W-0013_financial_exchange_rates_live` | Accounting schema; independent of `bonus_*` |
| 28 | `W-0014_product_catalog_sync` | Needs `products` + `notifications`. ⚠ installs the broadcast trigger (§2 M3) — harmless in scratch, which is itself proof scratch is the right place |
| 29–30 | **DIVERGENCE POINT — `0015_product_images_storage`, `0016_bonus_inventory_allocation_safety`** | Exist in both roots with **different content** (F6). Adopt the variant matching live (from the dump); applying both is unsafe/undefined |
| 31–36 | `R-0017` … `R-0022` | R-0018 = `bonus_*` financial core, R-0019 = earn engine; R-0021 needs `invoices` |
| 37 | `R-0023_bonus_rule_max_earn_contract_fix` | Current tip of the Earn Engine contract |
| + | `supabase functions deploy` ×4 (F7) | SQL replay does **not** create Edge Functions |

This order is a **proposal proven by execution, not by reading**: the first step of implementation must be "replay from zero, expect zero errors". Any failure means the table above is wrong and gets corrected.

### 5.3 Two bootstrap paths

| | Path A — **snapshot + tail** (recommended) | Path B — pure replay of §5.2 |
|---|---|---|
| Steps | `db dump` (schema-only) from prod → apply into scratch → apply `R-0017…R-0023` if absent from the dump → `db diff` must be empty | Run all 37 files in order → `db diff` vs prod |
| Fidelity to live | **Exact**, including objects never captured in migrations (live-only functions/policy edits/trigger changes) | Only as good as the repo; live drift is silently missing |
| Handles F13/F6 | Yes — divergence is copied, not guessed | No — 0015/0016 must be reconciled by hand first |
| Cost / risk | Dump contains the full production schema → treat as sensitive, keep out of git | Slower; can drift from prod unnoticed |
| Use when | Default for Phase 9 | Once, as a separate audit, to prove the repo chain is self-sufficient |

### 5.4 Parity verification (must pass before any fixture is loaded)

```sql
-- run in BOTH databases; the two result sets must be identical
select table_name, 'table' k   from information_schema.tables   where table_schema='public'
union all select routine_name,  'routine'                        from information_schema.routines  where routine_schema='public'
union all select trigger_name||'@'||event_object_table, 'trigger' from information_schema.triggers  where event_object_schema='public'
union all select policyname||'@'||tablename,           'policy'   from pg_policies                  where schemaname='public'
order by 2,1;
```
Plus `supabase db diff --db-url "$TEST_DB_URL"` (empty = parity) and a `bonus_*` row count proving scratch starts at **0 rows** (the F12 property we want to keep).

## 6. Fixtures and isolation strategy

### 6.1 Where isolation actually comes from

| Layer | Control | Status |
|---|---|---|
| 1. Database | Separate project ⇒ prod tables can never see a test row | **primary control** |
| 2. Credentials | Scratch publishable/service keys never shared with real apps or git | primary |
| 3. Auth | Fresh `auth.users` only; **never** reuse a real user id/email | primary |
| 4. Outbound | No SMTP / push / webhook config in scratch, and scratch Edge Functions must not call prod endpoints | must be verified, not assumed |
| 5. Naming | `TEST_` markers | **hygiene/portability only** — never presented as the safety mechanism |

### 6.2 Marker convention (hygiene)

* Names: `TEST_<case>_<thing>` (`TEST_P1_PRODUCT`, `TEST_P10_CUSTOMER_B`, branch `TEST_BRANCH_1`).
* Emails: `medlink-test+<case>@invalid` (unroutable → no accidental mail even if SMTP is enabled).
* A scratch-only registry table (plain SQL in `scripts/test-env/fixtures/000_registry.sql`, **not** a repo migration) recording `run_id, entity, uuid, name, case_id, created_at` so every run is self-describing and any later tool can bulk-clean by `run_id`.
* Ids: `gen_random_uuid()` (no `uuidv7` convention exists in this repo — F14).
* Rules must be **narrowly scoped to the test product ids** so the 0019 trigger can never match a real order (PHASE-7 §M–Q risk list), even though in scratch it could not hurt prod.

### 6.3 Fixture set (maps to PHASE-7 §D)

`TEST_` customer (auth user + `users` row, `client` role) · `TEST_` branch · `TEST_` products (active, priced, incl. one excluded + one free-bonus candidate) · `TEST_` `bonus_rules_v2` per case · `TEST_` orders **created only through the real RPC** `create_order_with_items` (PHASE-7 §A: single creation path) with a real client session · status transition to `delivered` (allowed by the 0002 CHECK at `R-0002:133`) so the 0019 trigger fires on the real code path · director/branch-manager test logins for the processor and security cases.

### 6.4 Alternative: UUID mapping (only for Option D / copied prod data)

If a branch of prod is used (§3 D), prod ids must be rewritten into a reserved test id block and every fixture recorded in the registry; that also drags real PII and financial history into the second project, which is why it is the fallback rather than the default.

## 7. Reset strategy (this resolves PHASE-7 §M)

### 7.1 The decision PHASE-7 left open

PHASE-7 §M asked: delete the test financial rows, or label them as permanent test artifacts?

**Decision: neither — the rows are destroyed together with the database.**
* Deleting `bonus_ledger` / `bonus_audit_trail` rows is impossible in prod (trigger-blocked, M1) and therefore cannot be the designed cleanup path of a financial engine.
* Labelling test rows as permanent artifacts is unacceptable **in production** because M2 (KPI inflation) and M4 (audit pollution) make them visible to directors and unretractable.
* Both options become non-decisions when the rows live in a project that is deleted: cleanup fidelity is 100%, and the append-only invariant is never violated or bypassed in a real ledger.

**Rule adopted:** *reversal is not cleanup.* Calling `reverse_bonus_txn` to "undo" a test creates two more ledger rows; it is a business operation, not a delete.

### 7.2 Reset levels

| Level | Operation | Duration | Use |
|---|---|---|---|
| L0 | `UPDATE` of rule/config state only (soft-disable rules) | seconds | Between adjacent cases inside one group |
| L1 | Truncate **non-financial** fixtures (`orders`, `order_items`, `products`, `notifications`, registry) + reload fixture file | ~1 min | Repeat runs of a non-financial group |
| L2 | `drop schema public cascade` → recreate → replay schema (dump or tail) → regrant → `notify pgrst,'reload schema'` → reload fixtures | ~minutes | **Default between PHASE-7 test groups** (unit basis / eligibility / stacking / idempotency / security) |
| L3 | Destroy and recreate the project (or reset the branch) | ~10 min + cost | After the campaign, after any suspicion of contamination, or before re-running the security cases |

L2 sketch (scratch only, executed by `reset-test-db.sh`):

```sql
drop schema public cascade;
create schema public;
grant usage on schema public to postgres, anon, authenticated, service_role;
alter default privileges in schema public grant all on tables    to postgres, anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to postgres, anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to postgres, anon, authenticated, service_role;
notify pgrst, 'reload schema';
```
(`auth` and `storage` schemas survive; test auth users must therefore be removed separately or the auth users re-seeded — recorded as a known rough edge of L2, which is why L3 is preferred at campaign boundaries.)

### 7.3 Admin-bypass rule (the one exception, and where it is legal)

In a **scratch** project the operator holds `postgres`, so `truncate … restart identity cascade` or dropping the immutability triggers is technically possible and is **permitted only there**, provided the script refuses to run unless `TEST_PROJECT_REF` resolves and ≠ `lmkomzqioneuyvatzsov`. The same statements must never appear in a repo migration, a `scripts/` file that can target a linked project, or a documented runbook step for prod.

## 8. Implementation plan (each ⛔ = explicit human approval before execution)

| # | Step | Command sketch | Gate |
|---|---|---|---|
| 0 | Neutralize the prod link so no CLI command can silently hit prod | back up then remove `supabase/.temp/` (F2) | local, reversible |
| 1 | Authenticate the CLI (currently no access token, F8) | `supabase login` → `supabase projects list` | ⛔ (interactive; operator's own credentials) |
| 2 | Create the scratch project (or branch) | `supabase projects create medlink-test --org <org-slug>` / MCP `create_project`; branch alternative costs **0.01344 USD/hour** (measured against org `vercel_icfg_DXdo2xd55rXv0SZFfPrVLlZJ`) | ⛔ (creates billable cloud resource; org plan/limits unknown) |
| 3 | Capture prod schema, read-only | `supabase db dump --db-url "$PROD_DB_URL" -f artifacts/test-env/prod-schema.sql` (password from dashboard, via env var, never committed) | ⛔ (reads full production schema) |
| 4 | Build scratch schema | `psql "$TEST_DB_URL" -f artifacts/test-env/prod-schema.sql` then apply `R-0017…R-0023` if missing (Path A) — or the §5.2 chain (Path B) | ⛔ (DDL, but on scratch only) |
| 5 | Prove parity | §5.4 queries + `supabase db diff --db-url "$TEST_DB_URL"` | auto |
| 6 | Deploy Edge Functions to scratch | `supabase functions deploy --project-ref "$TEST_PROJECT_REF"` for the 4 functions in F7 | ⛔ |
| 7 | Harden scratch: email confirmations/SMTP off, no webhooks, captcha off, "site URL" not prod | dashboard settings | ⛔ |
| 8 | Load fixtures per group | `psql "$TEST_DB_URL" -f scripts/test-env/fixtures/<group>.sql` | ⛔ (writes, but scratch only) |
| 9 | Point apps at scratch | web: `.env.local` with `VITE_SUPABASE_URL/ANON_KEY` (never rely on their absence — F10 falls back to prod). Flutter: constants are `const` (F11) ⇒ needs an additive `String.fromEnvironment('SUPABASE_URL', defaultValue: <prod>)` change in `medlink_app/lib/utils/constants.dart` + `--dart-define`; **no such code change is proposed or made in this phase** | ⛔ (code change) |
| 10 | Run the PHASE-7 matrix, reset per §7.2 | — | ⛔ per group |
| 11 | Destroy | `supabase projects destroy "$TEST_PROJECT_REF"` (irreversible) + delete `artifacts/test-env/*` | ⛔ |

## 9. Security rules for the whole campaign

1. **Never** run `supabase db push`, `db reset`, `db diff --linked`, or `psql` against `lmkomzqioneuyvatzsov` during a test campaign; every command carries an explicit `--db-url`/`--project-ref` resolved from `.env.test`.
2. Service-role keys exist only in the operator's environment (or dashboard secrets) — never in a file, log, screenshot, or this repo.
3. Schema dumps and any data dumps stay out of git and are deleted after use; a data dump contains customer PII and must never be taken at all unless Option D is chosen and approved.
4. No real credentials, emails, phone numbers, order ids or product names are copied into fixtures; fixtures are synthetic.
5. Scratch project: email confirmations + SMTP disabled, no third-party webhooks, analytics/push keys absent; verify its Edge Functions do not call production endpoints before use.
6. Never reuse a production `users.id`/email in scratch (RLS/ledger links would make results misleading).
7. Test scratch's publishable key is treated as disposable but still not committed; the service key for scratch is rotated/deleted with the project.
8. Any step that needs an admin bypass of the immutability triggers (§7.3) is scratch-only and must be logged in the run record.
9. The campaign ends with L3 destroy **and** a written confirmation that production was not written to (row counts of `bonus_*` unchanged vs. the pre-campaign read).

## 10. Risks, limitations, open questions

| # | Item | Status / need |
|---|---|---|
| R1 | Repo migrations ≠ live schema (F13). Until a dump is taken we cannot enumerate what is live-only | Resolved by §8 step 3 (dump) — until then all fidelity claims are bounded |
| R2 | `0015`/`0016` exist twice with different content (F6); which variant is live is unknown | Must be answered from the dump; otherwise Path B cannot be run safely |
| R3 | CLI unauthenticated (F8) → nothing cloud-side can be created from this machine yet | `supabase login`, or the authenticated Supabase MCP path (already reaches org `vercel_icfg_DXdo2xd55rXv0SZFfPrVLlZJ`) |
| R4 | Docker absent (F9) → no local fallback loop | Installing Docker is the cheapest long-term win; also needs a root `supabase/config.toml` (F4) |
| R5 | Web app silently defaults to prod when `.env` is missing (F10) | Real footgun; recommend a later additive guard (throw in dev if env missing). Out of scope here |
| R6 | Flutter constants are hardcoded (F11) → pointing the client at scratch requires a code change | Needs its own approved micro-phase (`--dart-define` with prod defaults) |
| R7 | Project/branch creation cost and org plan limits unknown | Confirm in dashboard before step 2; branch price measured at 0.01344 USD/h |
| R8 | PHASE-7 gaps inherited: `bonus_value` unit and cancellation-after-full-consumption remain unresolved business questions; `customer_type` eligibility cases may still be untestable | Business decisions, not environment issues |
| R9 | `auth`/`storage` do not reset with L2 (§7.2) | Accept L3 at boundaries, or add auth-user cleanup to the reset script |
| R10 | A scratch project duplicates *behaviour*, not *volume*: concurrency/retry cases will not reproduce prod load | Note when interpreting idempotency results |

## 11. Decisions required from the operator (blocking Phase 9)

1. **Approve Option C** (new disposable scratch project in org `vercel_icfg_DXdo2xd55rXv0SZFfPrVLlZJ`), or Option D (preview branch of prod, ~0.01344 USD/h, copies PII) as the fallback.
2. **Approve the read-only production schema dump** (§8 step 3) and confirm where it may be stored (git-ignored path only).
3. **Approve `supabase login` / project creation** — or state that the operator creates the project manually and provides only `TEST_DB_URL` + publishable key.
4. Confirm the **campaign window and destroy date** so no orphan project keeps running (cost + PII-free but still a second live schema).

## 12. What this phase did and did not do

**Did:** audited both migration roots and both function roots, mapped every cross-repo table dependency, identified the duplicate/divergent migration pairs, measured the branch price, measured the CLI/auth/Docker state, traced the contamination paths through the director dashboard and the catalog trigger, produced the interleaved replay order, the parity check, the fixture/isolation convention, the reset matrix, and the gated command plan.

**Did not:** create/modify/delete any database object, project, branch, function, or app file; commit anything but this document; write to production; change Flutter/web configuration; install Docker.

**Verification performed for this document:** `ls`/`diff -q`/`comm` over both migration dirs; `grep -n` for every dependency claim cited (each carries a `file:line` above); `supabase --version` + `ls -la ~/.supabase/`; Docker absence; live counts quoted from PHASE-7 §C (dated 2026-09-21 — re-read them before Phase 9 starts, since production is live).

**Next phase:** `PHASE-9` = execute §8 steps 0–5 (environment build + parity proof) after the four approvals in §11, then run the PHASE-7 matrix per §7.2 and write `PHASE-9-EARN-ENGINE-TEST-RUN-REPORT.md`.

## Appendix — files inspected for this design

`supabase/migrations/0001…0023` (create-table map + targeted greps of 0002, 0009, 0011, 0013, 0016, 0018, 0019, 0020, 0021, 0023) · `Medlik-Waap/supabase/migrations/0001…0016` (0003, 0004, 0008, 0014 in detail) · `supabase/.temp/*` (link state) · `supabase/functions/` · `Medlik-Waap/supabase/{config.toml,functions,migrations}` · `Medlik-Waap/artifacts/pharma-pwa/src/lib/{supabaseClient.ts,bonusFinancialApi.ts}` · `Medlik-Waap/artifacts/pharma-pwa/src/pages/director/BonusFinancialDashboardPage.tsx` · `medlink_app/lib/utils/constants.dart` · `medlink_app/lib/services/{supabase_bootstrap.dart,bonus_wallet_service.dart}` · `docs/opencode/PHASE-5-0019-LIVE-PRECHECK.md` · `docs/opencode/PHASE-6-0019-LIVE-VERIFICATION.md` · `docs/opencode/PHASE-7-EARN-ENGINE-TEST-DESIGN.md` · `docs/REWARDS_SYSTEM_MASTER_STATUS.md` · environment: `supabase --version`, `ls -la ~/.supabase/`, Docker availability, Supabase org/branch cost lookup.
