# PHASE 50 — BONUS FIX PRE-TEST READINESS REVIEW

> **Type:** Read-only readiness review + stakeholder report. **One file created** (this report). No migration modified, no SQL executed, no database connection, no Supabase login, no environment created, no `db push` / `db reset` / commit / push / deploy.
> **Date:** 2026-09-30
> **Question answered:** can migration `0023_bonus_rule_max_earn_contract_fix.sql` be tested **safely using a test environment that already exists**, without creating a new one and without touching production?
> **Inputs:** `docs/opencode/PHASE-47-BONUS-RULE-CONTRACT-FIX-DESIGN.md` (§G test plan, §K.4 preconditions), `docs/opencode/PHASE-8-TEST-ENVIRONMENT-ARCHITECTURE.md` (§1 environment facts F1–F14), `docs/opencode/PHASE-49-BONUS-ACCOUNTING-DECISION-MATRIX.md`, `supabase/migrations/0023_bonus_rule_max_earn_contract_fix.sql`, `scripts/sql/bonus-invariants-regression.sql`.
> **Method:** filesystem, git, process, port, package and CLI *presence* inspection only (`find`, `ls`, `stat`, `sha256sum`, `grep`, `sed`, `awk`, `ps`, `ss`, `snap list`, `command -v`, `supabase --version`, `supabase status`, `supabase start --help`). No credential value was printed; no pg/SQL command was issued.
> **Artifact under review (unchanged, re-fingerprinted):** `supabase/migrations/0023_bonus_rule_max_earn_contract_fix.sql` — 18,111 bytes, 388 lines, mtime `2026-09-29 19:28:05 +0300`, `sha256 = f3d17a750d9dd607865777d2ccf7e213416e88fee49807dee4608c37c878c7fa`, git state `??` (untracked).

---

## 0. Executive verdict

| # | Question | Answer |
|---|---|---|
| Q1 | Does an isolated / local / scratch test database **already exist**? | **NO.** No PostgreSQL engine, no container runtime, no local Supabase stack, no second test project, no seed data. Evidence in §1. |
| Q2 | Can the PHASE-47 §G tests (T1–T18) be executed today? | **Only four of them.** T16 (Flutter regression) is offline-executable; T1–T15, T17, T18 require a database and are **blocked**. Mapping in §3. |
| Q3 | Can behaviour be *proved* without a database? | **NO.** Only contract-level *static* checks (S1–S12, §2) can run — they re-verify the file, not the runtime semantics. |
| Q4 | Is any test at risk of reaching the production project `lmkomzqioneuyvatzsov`? | **Not in practice, but the repository is aimed at it by default.** The CLI link points at production, and both apps fall back to production URLs. Controls are enumerated in §4. |
| Q5 | Was an environment created, or tools installed, in this phase? | **NO.** Nothing was created or installed (as instructed). The blocker is formally recorded in §6. |
---

## 1. Existing-environment inventory (measured evidence)

### 1.1 Database engines — none present

| Probe | Result |
|---|---|
| `command -v psql postgres pg_ctl initdb pg_dump pg_restore createdb` | **all NOT FOUND** |
| `ls -d /usr/lib/postgresql/*` , `ls -d /var/lib/postgresql/*` , `ls /etc/postgresql` | no such directories |
| `find / -maxdepth 4 -type f \( -name initdb -o -name postgres -o -name pg_ctl \)` | **0 results** |
| `ps -eo pid,cmd \| grep -iE '[p]ostgres\|[p]ostmaster'` | **no PostgreSQL process running** |
| `ss -ltnp \| grep -E '5432\|54321\|54322\|8000'` | **none of those ports listening** |
| `ls /var/run/postgresql` , `ls /tmp/.s.PGSQL*` | no socket directory, no socket file |
| Alternative clients `pgcli usql dbeaver pgadmin4 dbmate flyway migrate` | **all NOT FOUND** |
| Driver binding: `python3 -c "import psycopg2"` | **ModuleNotFoundError** |

**Conclusion:** the machine has **no PostgreSQL server, no PostgreSQL client and no PostgreSQL driver of any kind.** Even if a database existed elsewhere on the network, there is currently *no tool in this environment able to open a connection to it*.

### 1.2 Container runtimes — none present

| Probe | Result |
|---|---|
| `command -v docker podman docker-compose nerdctl` | **all NOT FOUND** |
| `ls -la /var/run/docker.sock` | no such file |
| `systemctl is-active docker` | `inactive` |
| `systemctl list-unit-files \| grep -iE 'docker\|podman'` | no matching unit files |
| `snap list` | 17 snaps, **no Docker/Podman snap** (flutter, code, brave, core20/22/24/26, gnome-42-2204, gtk-common-themes, snapd, bare, antigravity-ide-snap, codex) |

This independently **confirms PHASE-8 F9 ("Docker is not installed")** and removes the only mechanism by which `supabase start` (the local stack) could work.

### 1.3 Local Supabase stack — impossible today

| Probe | Result |
|---|---|
| `supabase status` | `Linked Project: موريد الادويه (lmkomzqioneuyvatzsov)` then `failed to inspect container health: docker: command not found (podman also not found)` |
| `supabase start --help` | "Start containers for Supabase local development" — container-based by definition |
| Root `supabase/config.toml` | **does not exist** (only `Medlik-Waap/supabase/config.toml`) — no local-stack definition |
| `grep -rn 'localhost:54321\|127.0.0.1:54321\|localhost:54322'` repo-wide | **0 hits** — no local stack was ever configured |
| `~/.supabase/` (user CLI state) | only `telemetry.json` + `traces/` (4 ndjson files, 2026-09-24 → 09-28); **no `access-token`**, no local stack data |

### 1.4 Supabase CLI — installed, unauthenticated, pointed at production

| Probe | Result |
|---|---|
| `command -v supabase` | `/home/adman/.local/bin/supabase` |
| `supabase --version` | `2.117.0` (newer `2.118.0` exists — update **not** performed) |
| `supabase/.temp/linked-project.json` | `{"ref":"lmkomzqioneuyvatzsov","name":"موريد الادويه", …}` → **the CLI in this repository is linked to the PRODUCTION project** (confirms PHASE-8 F2) |
| `supabase/.temp/project-ref` | `lmkomzqioneuyvatzsov` |
| `supabase/.temp/pooler-url` | `postgresql://postgres.lmkomzqioneuyvatzsov@aws-0-ap-northeast-1.pooler.supabase.com:5432/postgres` (host/ref only; **no password shown or read**) |
| `~/.supabase/access-token` | **absent**; `SUPABASE_ACCESS_TOKEN` **not set** → not logged in (confirms PHASE-8 F8) |
| Env vars `SUPABASE_DB_URL`, `DATABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_URL` | **all not set** (presence checked only, values never printed) |
| `supabase/.temp/postgres-version` | `17.6.1.155` (production's served version) |
| `supabase/.temp/cli-latest` | `v2.118.0` — mtime **`2026-09-30 18:15:42`**, rewritten *today* by the CLI's own update check during this phase's read-only `--version`/`status` calls. Path is git-ignored (`.gitignore:51 supabase/.temp/`), so the tracked tree is unaffected. **Disclosed in §8.** |
### 1.5 Repository test infrastructure — designed, never built

| Expected artifact (PHASE-8 §4) | Actual state |
|---|---|
| `scripts/test-env/build-test-db.sh` | **does not exist** (`scripts/test-env/` absent) |
| `scripts/test-env/reset-test-db.sh` | **does not exist** |
| `scripts/test-env/fixtures/*.sql` | **does not exist** |
| `scripts/test-env/.env.test` | **does not exist** |
| `artifacts/test-env/` (dumps, parity diffs) | **does not exist** |
| Entire `scripts/` tree | only `medlink-audit-prompt.txt`, `sql/bonus-invariants-regression.sql`, `post-merge.sh`, `package.json`, `tsconfig.json`, `src/hello.ts` |
| `seed.sql` / `*.dump` / `*.sql.gz` / `*fixture*` repo-wide | **0 hits** |
| `.env*` files anywhere (excluding `node_modules`) | **0 hits** |

**The PHASE-8 test-environment architecture is a design document only.** Every harness script it proposes is still absent, so there is no switch to flip.

**The one pre-existing, correctly-guarded SQL harness:** `scripts/sql/bonus-invariants-regression.sql` (154 lines) — declares `-- DO NOT RUN ON PRODUCTION`, requires a scratch project with `0001→0017` applied plus operator-provisioned fixtures, takes every id as a `-v` psql variable (no hardcoded refs), and wraps everything in a transaction that **always** `rollback`s. It targets the `0016`/`0017` invariants (inventory/invoice/analytics), **not** the `max_earn` contract, and still requires a **psql binary**, which does not exist here — a reusable *pattern*, not a usable *tool* today.

### 1.6 Other projects / refs — no hidden test project

| Probe | Result |
|---|---|
| Distinct 20-char refs across `docs/opencode/` | `lmkomzqioneuyvatzsov` (33) and `hhqhoqwpebnmfuhwhllw` (**1**) |
| `hhqhoqwpebnmfuhwhllw` context | `docs/opencode/PHASE-18-LIVE-VERIFICATION-0020.md:4` → the **second production project "وصل"**, explicitly **untouched**; not a staging/sandbox project |
| Repo-wide grep for `staging` / `sandbox` / test project refs | only **documented gaps**: `PHASE-7 §R` "BLOCKED — TEST ENVIRONMENT REQUIRED", `PHASE-8 §0` "No safe place today", `docs/REWARDS_SYSTEM_MASTER_STATUS.md` (repeated "no staging") |
| `git submodule status` | `fatal: no submodule mapping found in .gitmodules for path 'Medlik-Waap'` — the web app is an **unregistered embedded repository** (pre-existing, unchanged) |

### 1.7 What *is* executable offline (capability inventory)

| Tool | Present | Consequence for testing |
|---|---|---|
| `git` | `/usr/bin/git` | diff/status/hash verification |
| `python3` | `/usr/bin/python3` | text processing; **no** `psycopg2`, `sqlparse`, `pglast` |
| `node` / `npm` / `pnpm` | present | `node_modules/` exists, but **no** SQL parser (`pgsql-ast-parser`, `node-sql-parser` → not found) |
| `flutter` / `dart` | `/snap/bin/flutter`, `/snap/bin/dart` | the Flutter widget/unit suite **can** run offline (§3, T16) |
| `ss` / `lsof` / `fuser` | present | port/socket probing |
| PostgreSQL tooling | **absent** | no SQL execution of any kind |
| Docker/Podman | **absent** | no local Supabase stack |
---

## 2. Tests possible NOW — offline static gate (no database, no SQL execution)

These checks are *not* behavioural proof. They re-verify that the artifact is what PHASE-47/48 claimed, and can be repeated at any time without touching a database.

| # | Check | Command (read-only) | Expected | Status |
|---|---|---|---|---|
| S1 | File identity | `sha256sum supabase/migrations/0023_bonus_rule_max_earn_contract_fix.sql` | `f3d17a75…78c7fa` | **PASS** (measured this phase) |
| S2 | Size / mtime | `stat -c '%s %y' …` | 18,111 bytes; unchanged mtime | **PASS** |
| S3 | Untracked, not ignored | `git status --porcelain supabase/migrations/0023…sql` | `?? …` (no `!!`) | **PASS** |
| S4 | Only two objects defined | `grep -ci 'create or replace function' …` | `2` | **PASS** |
| S5 | No DDL at statement level | `grep -niE 'alter table\|create table\|create index\|create trigger\|create policy\|drop \|grant \|revoke ' …` | only indented DML inside bodies / header comment text | **PASS** (PHASE 48) |
| S6 | No data statements at top level | `grep -niE '^(insert\|update\|delete) ' …` | none | **PASS** (PHASE 48) |
| S7 | No transaction control | `grep -niE 'begin;\|commit;\|concurrently\|vacuum\|copy ' …` | none | **PASS** |
| S8 | Rename diff vs `0019` | `sed 's/max_bonus/max_earn/g'` on `0019` vs `0023` bodies | **byte-identical modulo rename** | **PASS** (PHASE 48) |
| S9 | Old name gone from code lines | `grep -n 'max_bonus' 0023…` | only comment lines in the header | **PASS** (PHASE 48) |
| S10 | Correct name present 3 + 3 | `grep -c 'max_earn' …` per body | 3 in each function body | **PASS** |
| S11 | Signature/metadata parity | compare `returns`, `security definer`, `set search_path`, `plpgsql` against `0019` | identical | **PASS** (PHASE 48) |
| S12 | Repo-wide single source of truth | `grep -rn 'max_bonus' supabase/ docs/ Medlik-Waap/` | only `0019` (4 refs) + `0023` comments | **PASS** |

**Structural (non-SQL) checks proposed as still-static:**

| # | Check | Why it matters |
|---|---|---|
| S13 | Top-level statement segmentation | splitting on `;` at zero indent should yield exactly **2** statements (both `create or replace function`), so nothing executable hides between bodies |
| S14 | `$`-quote integrity | each body `$$ … $$`-wrapped, dollar-quote count even (4) — guards against a truncated/unclosed body |
| S15 | Trailing-newline / encoding | file ends with `LF`, UTF-8, no BOM, no CRLF (388 lines, trailing newline present) |
| S16 | Line-reference integrity | the header's cited lines (`0018:133`, `0019:171,172,377,378`) still resolve to those exact statements |

S1–S12 are **re-confirmations** of PHASE 48 (`PHASE 48 MIGRATION REVIEW COMPLETE`); S13–S16 were **not executed** in this phase.

### 2.1 T16 — the one PHASE-47 test that can really run today (application level)

`PHASE-47 §G` T16 = "Regression — Flutter suite": `flutter test` → 39/39, `flutter analyze` → 4 pre-existing infos.

| Aspect | Finding |
|---|---|
| Toolchain | `flutter` + `dart` present (`/snap/bin/…`) |
| Suites present | `medlink_app/test/`: `widget_test.dart`, `cart_controller_bonus_test.dart`, `order_discount_test.dart`, `bonus_idempotency_key_test.dart`, `branch_cancellation_test.dart`, `order_cancellation_test.dart` |
| Test-case count | **39** `test(` / `testWidgets(` declarations — matches the 39/39 baseline |
| Network safety | suites that construct a Supabase client use `'https://localhost:1'` (`branch_cancellation_test.dart:24,68,81`; `order_cancellation_test.dart:22`; `order_discount_test.dart:20`) — an intentionally unroutable host, so **no test can reach production** |
| Relevant to `0023`? | **No.** The fix changes **zero** application files, so this suite is a *guard against accidental collateral change*, not a test of the cap logic |

**Honest limitation:** T16 was **not executed in this phase** — no test-run command was authorised, and PHASE-47 §I lists it as expected to pass precisely because nothing changed. It is *executable*, not *executed*.
---

## 3. Test classification — possible / needs isolated DB / never verified

### 3.1 Class A — possible now, offline (no database)

| ID | Test | Notes |
|---|---|---|
| S1–S16 | Static contract gate (§2) | re-verifies the artifact; **does not** prove runtime semantics |
| **T16** | `flutter test` (39/39) + `flutter analyze` (4 pre-existing infos) | proves no collateral app breakage; **says nothing** about the cap |
| — | `git` diff/hash/status checks | ensures nothing else changed |

### 3.2 Class B — requires an isolated database (blocked today)

Every behavioural test in `PHASE-47 §G` T1–T15, T17, T18. All need a Postgres instance where `0001→0022` is applied, then `0023`, then fixtures created and the delivery trigger fired.

| Test | Name | Needs DB | Also needs fixtures / roles |
|---|---|---|---|
| T1 | Validator accepts a rule with a cap | yes | write path (director RLS or service role) |
| T2 | Validator rejects `max_earn = 0` and `= -1` | yes | — |
| T3 | Validator accepts `NULL` cap | yes | — |
| T4 | Full PWA payload shape accepted | yes | exact `toDbPayload` key set |
| T5 | Update path passes the BEFORE UPDATE trigger | yes | an existing rule row |
| T6 | Status-only toggle (`suspended` / `active`) | yes | an existing rule row |
| T7 | Cap applied (`bonus_value` 500, cap 200 → EARN 200) | yes | active product + branch + client + address + account |
| T8 | `NULL` cap = unlimited (EARN 500) | yes | same fixture set |
| T9 | Exactly at the cap is **not** capped (strict `>`) | yes | same fixture set |
| T10 | Zero/negative computed earn → no ledger row | yes | same fixture set |
| T11 | Cap with `PER_UNIT` / `PER_PRODUCT` basis | yes | same fixture set + product map |
| T12 | Idempotency key uniqueness on re-delivery | yes | delivery fired twice / concurrently |
| T13 | Delivery no longer rolls back (`42703` gone) | yes | same fixture set |
| T14 | Suspended-account hold path | yes | account with `status='suspended'` |
| T15 | Non-matching order → no earn, no error | yes | rule with `min_order_value` above the order |
| T17 | No accidental DDL (before/after column snapshot) | yes | catalog read access |
| T18 | ACL preserved (before/after `pg_proc.proacl`) | yes | catalog read access |

### 3.3 Class C — live verification that was **never executed** (and remains unverified)

| Item | Status | Provenance |
|---|---|---|
| Live `pg_proc.prosrc` of the two functions **re-measured today** | **NOT done** — no DB connection permitted | PHASE-46/47 evidence is *inherited*, not re-observed |
| Live ACL re-measured today (`J2`: `anon` / `authenticated` / `service_role` still hold `EXECUTE`) | **NOT done** | PHASE-47 §J2 |
| Live row counts (`bonus_rules_v2` = 0, `bonus_ledger` = 0, …) | **NOT re-measured today** | PHASE-46/47 |
| The production runtime failure itself (`record "bonus_rules_v2" has no field "max_bonus"`, SQLSTATE `42703`) | **never executed anywhere** — a *static inference* from verified catalog facts | PHASE-47 §J1 |
| Production restore point | **none verified** | PHASE-5 §M |
| Every Class B test (§3.2) | **never executed** | this report |
---

## 4. How to guarantee that no test reaches the production project

Production :`lmkomzqioneuyvatzsov` ("موريد الادويه"). The following are the **only** paths by which a test could reach it, each with its control.

### 4.1 Exposure inventory

| # | Path to production | Evidence | Current state |
|---|---|---|---|
| E1 | `supabase db push` / `db reset` / `db diff --linked` **from the repo** | `supabase/.temp/linked-project.json` + `supabase/.temp/project-ref` = `lmkomzqioneuyvatzsov` | **live risk** — the link is present and points at prod |
| E2 | `supabase start` / local stack | none | **impossible** — no Docker/Podman, no root `config.toml` |
| E3 | Web PWA hardcoded fallback | `Medlik-Waap/artifacts/pharma-pwa/src/lib/supabaseClient.ts:5-6` → falls back to `https://lmkomzqioneuyvatzsov.supabase.co` + a publishable key when `VITE_*` env vars are absent (confirms PHASE-8 F10) | **latent** — any PWA dev run without `VITE_*` hits prod |
| E4 | Flutter hardcoded constants | `medlink_app/lib/utils/constants.dart:10-12` → `supabaseUrl = 'https://lmkomzqioneuyvatzsov.supabase.co'`, publishable anon key, used by `supabase_bootstrap.dart:7` | **latent** — `initSupabase()` always targets prod unless the constants are changed |
| E5 | `psql` / any SQL client | no client installed; `SUPABASE_DB_URL` / `DATABASE_URL` unset; `~/.pgpass` and `~/.pg_service.conf` absent | **impossible today** |
| E6 | CLI management API (`projects`, `branches`, `secrets`) | `~/.supabase/access-token` absent; `SUPABASE_ACCESS_TOKEN` unset | **impossible today** — but a one-time `supabase login` would restore it |
| E7 | Pooler connection string | `supabase/.temp/pooler-url` holds the prod pooler host (ref only; **no password anywhere in the file**) | **low** — unusable without a password |
| E8 | Edge Function deploy | `supabase functions deploy` needs the same link/token | **blocked** by E6 |
| E9 | Second production project "وصل" (`hhqhoqwpebnmfuhwhllw`) | `PHASE-18:4` | **not referenced by any config** — no path to it |
| E10 | T16 Flutter suite | tests use `'https://localhost:1'` | **safe by construction** |

### 4.2 Required controls before any future execution (design only — nothing implemented here)

| # | Control | Neutralises |
|---|---|---|
| C1 | **Never** run `supabase db push`, `db reset`, `db diff --linked`, `db query --linked`, or any `--linked` flag inside this repository | E1 |
| C2 | Remove/back up `supabase/.temp/` (git-ignored) or run every command from a directory with no `.temp`, and always pass an **explicit** `--db-url` / `--project-ref` | E1, E7 |
| C3 | Hard guard in every future test script: resolve the target ref and **abort if it equals `lmkomzqioneuyvatzsov`** (or `hhqhoqwpebnmfuhwhllw`) — the same guard PHASE-8 §4 proposes for `build-test-db.sh` | E1, E9 |
| C4 | Do not run the PWA dev server without `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` set to the scratch project | E3 |
| C5 | Run Flutter integration/app builds only with `--dart-define` overrides, or restrict execution to the widget/unit suite (`medlink_app/test`), which never calls `initSupabase()` | E4 |
| C6 | Keep `SUPABASE_ACCESS_TOKEN` unset unless the Management API is genuinely needed; if ever set, `--project-ref` must be explicit on every command | E6, E8 |
| C7 | Never add a `CHECK`/`ALTER` or fixture script that can be executed from the repo root without an explicit target | E1 |

**Net effect today:** the *only* realistic production-reaching paths are E1 (CLI push/reset) and E3/E4 (apps defaulting to prod). Because no SQL tooling exists (E5) and the CLI is not authenticated (E6), that is why the actual risk of accidental production contact during the current phase is **low** — while the risk in a *future* test run is **real** unless C1–C6 are enforced.
---

## 5. Requirements to test the two functions

`0023` replaces exactly two bodies:

* **(A)** `public.bonus_check_rule_v2(p_rule public.bonus_rules_v2) returns text` — lines 59–151 (edited refs at `0023:142,143`).
* **(B)** `public.bonus_evaluate_order_earn(p_order_id uuid) returns int` — lines 153–388 (edited ref at `0023:310,311`).

The six required acceptance dimensions below are the *minimum* proof set. Each maps to the PHASE-47 tests in parentheses.

### 5.1 Required test conditions (all six)

| # | Dimension | Requirement | Test | Proof needed |
|---|---|---|---|---|
| **R1** | **Validator accepts a valid cap** | a rule with `max_earn > 0` (e.g. 100) must INSERT without error | T1 | no `42703`; row count 1 |
| **R2** | **Validator rejects non-positive cap** | `max_earn = 0` **and** `max_earn = -1` must both fail | T2 | error raised; message references `max_earn` (the renamed literal, `0023:143`) |
| **R3** | **`NULL` cap = unlimited** | INSERT with `max_earn` omitted must succeed, and delivery must earn the **uncapped** value | T3, T8 | row accepted; `EARN` = `bonus_value` (e.g. 500), i.e. `is not null` guard holds |
| **R4** | **Earn cap is enforced** | with `bonus_value` 500 and `max_earn` 200, delivery must post `EARN` = **200** | T7 | exactly one `bonus_ledger` `EARN` row, amount 200, key `SALES_EARN:{order}:{rule}` |
| **R5** | **Boundary: equality is not a breach** | `bonus_value` 200, `max_earn` 200 → `EARN` = 200 (comparison is strict `>`) | T9 | amount 200; cap branch not taken |
| **R6** | **No other behaviour changed** | — see §5.2 | T5, T6, T10–T18 | see below |

### 5.2 "No other behaviour changed" — the exact required proof set

| # | Unchanged behaviour | How it must be proven | Test |
|---|---|---|---|
| R6.1 | INSERT **and** UPDATE trigger paths both work | create a rule, then update its name; both succeed | T5 |
| R6.2 | Status-only UPDATE works (`suspended` → `active`) | toggle twice; both succeed | T6 |
| R6.3 | Zero/negative computed earn still writes **no** ledger row | rule that computes 0 → no row, no cap interaction | T10 |
| R6.4 | Cap works identically under other bases | `PER_UNIT` and `PER_PRODUCT` with caps honoured | T11 |
| R6.5 | Idempotency keys still unique | re-fire delivery → single `EARN` row | T12 |
| R6.6 | **The defect's primary symptom is gone** | `update orders set status='delivered'` **persists** and creates the earn | T13 |
| R6.7 | Suspended-account hold path intact | hold row in `bonus_pending_entitlements`, status persists, no evaluator error | T14 |
| R6.8 | Non-matching order → no earn, no error | rule above `min_order_value` → nothing happens | T15 |
| R6.9 | No schema drift | identical `pg_attribute` column set before/after | T17 |
| R6.10 | ACL preserved | identical `pg_proc.proacl` before/after | T18 |
| R6.11 | App regression clean | `flutter test` 39/39; `flutter analyze` = 4 pre-existing infos | T16 |
| R6.12 | Legacy model untouched | `create_order_with_items` / `bonus_rules` `prosrc` unchanged | PHASE-47 §I AC17 |

### 5.3 Environment requirements for R1–R6 (what must exist before execution)

| Requirement | Why | Present today? |
|---|---|---|
| An isolated Postgres 15/17 instance | run DDL + fixtures | **NO** (§1.1, §1.2) |
| The interleaved migration chain `0001→0022` applied (root **and** web migrations — root-only replay fails at `0009`, PHASE-8 §5.1) | the two functions depend on `bonus_rules_v2`, `orders`, `order_items`, `inventory`, `invoices`, `warehouse_inventory` | **NO** |
| `0023` applied **after** `0019` | R4/R6.6 are unreachable while the `max_bonus` bug is live (R4 in the risk register) | **NO** |
| A throwaway **director** identity (RLS write policy on `bonus_rules_v2` is director-only) | R1–R3, R6.1, R6.2 | **NO** |
| A throwaway active product, client + bonus account, address, base branch | R3–R6 (earn evaluation) | **NO** |
| A cleanup/reset protocol that never `DELETE`s financial rows (ledger is append-only by trigger) | re-runnability | **NO** (PHASE-7 §M open decision) |
| `psql` (or any SQL client) | execute the scripts | **NO** (§1.1) |
| A catalog-snapshot mechanism (`pg_attribute`, `pg_proc.prosrc`, `pg_proc.proacl`, `pg_trigger`) | R6.9, R6.10 | **NO** |
| A verified production restore point | precondition for any later live step (not for the isolated run) | **NO** (PHASE-5 §M) |

**Conclusion:** R1–R6 are fully *specified* and fully *unexecutable* today. Nothing in this list exists in the current environment, and this phase was explicitly forbidden from creating any of it.
---

## 6. Recorded blocker — no safe test environment exists

> **BLOCKER (formally recorded, per the phase instruction to record rather than create):**
> **No isolated test environment exists in this repository or on this machine, and none was created.**
>
> `0023_bonus_rule_max_earn_contract_fix.sql` **cannot be behaviourally tested today.** The behavioural test plan `PHASE-47 §G` T1–T15/T17/T18 is **designed but not executable**, because there is no Postgres engine, no container runtime, no local Supabase stack, no scratch project, no test harness, no SQL client, no fixtures and no seed data.
>
> The only executable items are the offline static gate (S1–S16, §2) and, technically, the Flutter regression suite (T16, §2.1) — neither of which exercises the `max_earn` cap.
>
> **Nothing was created, installed, downloaded or configured to remove this blocker.**

### 6.1 Blocker sub-items

| # | Blocker | Blocks | Resolution owner |
|---|---|---|---|
| B1 | No PostgreSQL server / client / driver | every Class B test | owner decision |
| B2 | No Docker or Podman → no `supabase start` | local-stack option | owner decision |
| B3 | No scratch/staging Supabase project | project-level isolation | owner decision |
| B4 | `scripts/test-env/*` never built (PHASE-8 design only) | repeatable harness | implementation phase |
| B5 | Root-only migration replay fails at `0009` (PHASE-8 §5.1) | any fresh DB bootstrap | needs the interleaved chain |
| B6 | Financial-fixture cleanup protocol undecided (PHASE-7 §M) | re-runnable suites | owner decision |
| B7 | CLI linked to production; `db push` must stay forbidden | E1 | procedural control C1–C3 |
| B8 | Production restore point never verified (PHASE-5 §M) | any live application | owner decision |
| B9 | Live `prosrc`/ACL not re-measured (no DB access allowed) | R4/R6.10 confidence | future live read-only gate |

---

## 7. Safe next step (one step, not a programme)

**Recommended immediate next step (no database, no risk):**

Execute the **offline static gate** in full — S1–S16 (§2) — and record its results as the artifact's frozen pre-application fingerprint (hash `f3d17a75…78c7fa`). Optionally add the one genuinely runnable PHASE-47 test, **T16** (`flutter test` + `flutter analyze`) in `medlink_app/`, and record the observed 39/39 and the 4 pre-existing infos.

This step is safe because it touches **no database, no migration and no application file**, and it converts the review into a reproducible baseline that the eventual `0023` application can be compared against (nothing must change in the app or in any other migration).

**Then, and only then**, obtain an explicit owner decision on how the Class B tests will be run. The options, with their real costs, are listed below — **none is created or started by this phase.**

### 7.1 Options for obtaining an isolated environment (owner decision — not executed here)

| Option | What it requires | Cost | Risk to production | Blocked by |
|---|---|---|---|---|
| **A. Local Supabase stack** | install Docker/Podman + create root `supabase/config.toml` + `supabase start` | medium setup, zero recurring cost | **none** (fully local) — provided C1/C2 are enforced | B2 (Docker absent), needs a root `config.toml` that does not exist |
| **B. Scratch Supabase project** (PHASE-8 Option C) | create a disposable project in the same org, bootstrap schema, apply `0023`, run T1–T18, destroy | project cost + dump/PII handling | **none** if the ref guard (C3) is present | B3, B4, B5, B6; also needs `supabase login` (E6) |
| **C. Preview branch of production** | a Supabase branch of `lmkomzqioneuyvatzsov` | branch cost; requires authenticated CLI | schema copied from prod (no data) | E6; PHASE-8 §3 evaluated and did **not** prefer it |
| **D. Production (even read-only fixtures)** | — | — | **unacceptable** — the ledger is immutable by trigger, KPIs aggregate globally, inserts broadcast notifications to real users (PHASE-8 §2 M1–M6) | rejected by PHASE-8 |

Whichever option the owner selects, the guard rails in §4.2 (C1–C7) must be in place **before** the first command runs, and `0023` must be applied **after** `0019` so that R4 (cap enforcement) and R6.6 (delivery no longer rolls back) are actually reachable.
---

## 8. Phase compliance and disclosure

| Constraint | Compliance |
|---|---|
| No file modified, no migration created | **met** — the only write is this new report; `0023` and all migrations are byte-identical (hash re-verified: `f3d17a75…78c7fa`) |
| No database connection, no SQL executed | **met** — no SQL client exists; no connection attempted; no SQL statement issued |
| No Supabase login, no production download | **met** — `~/.supabase/access-token` absent, `SUPABASE_ACCESS_TOKEN` unset; no dump/copy performed |
| No test environment created, no tools installed | **met** — no project, no Docker, no `config.toml`, no `scripts/test-env`, no package installed; CLI version left at 2.117.0 |
| No `db push` / `db reset` / commit / push / deploy | **met** — none issued |
| `0023` and earlier migrations unchanged | **met** — verified by hash + `git status` |
| Prior work preserved (including unrelated files) | **met** — see the inventory below |

### 8.1 Disclosure: the single side effect observed

`supabase --version` and `supabase status` (both **read-only** informational commands) caused the CLI to refresh its own *version-check cache*:

* file: `supabase/.temp/cli-latest` (8 bytes, content `v2.118.0`), mtime changed to `2026-09-30 18:15:42 +0300`;
* this path is **git-ignored** (`.gitignore:51` → `supabase/.temp/`), so the repository's tracked state is unaffected;
* `supabase/.temp/linked-project.json` and `supabase/.temp/postgres-version` retain their original mtimes (`2026-09-18 21:41`) — the link and version files were **not** altered;
* no network write, no authentication, no project mutation occurred.

This is reported because it *is* a change on disk, even though it is a git-ignored cache artifact.

### 8.2 State of the working tree after this phase (read-only observation)

| Entry | State | Relation to this phase |
|---|---|---|
| `?? docs/opencode/PHASE-50-BONUS-FIX-PRE-TEST-READINESS.md` | untracked | **created by this phase** |
| `?? supabase/migrations/0023_bonus_rule_max_earn_contract_fix.sql` | untracked, hash unchanged | under review; **not touched** |
| `?? docs/opencode/PHASE-46-…md`, `PHASE-47-…md`, `PHASE-49-…md`, `PHASE-8-…md` | untracked | pre-existing previous-phase reports; **not touched** |
| `?? docs/REWARDS_SYSTEM_MASTER_STATUS.md`, `?? .commandcode/` | untracked | pre-existing, unrelated; **not touched** |
| ` M Medlik-Waap` | submodule pointer dirty | pre-existing (PHASE 48 traced it to an untracked empty `Medlik-Waap/cd`); **not touched** |
| `?? supabase/.temp/cli-latest` mtime | refreshed | CLI cache side effect, disclosed in §8.1 |

### 8.3 Verification limits of this report

All conclusions are derived from **file content, git state, process/port/package inspection and CLI presence checks**. No conclusion here is based on a live database observation made in this phase; every live fact (function bodies, ACLs, row counts, column list) is **inherited evidence** from PHASE-46/47/48 and is labelled as such in §3.3.

---

## 9. Summary for the owner

1. **No test environment exists** — no Postgres, no Docker, no local stack, no scratch project, no harness, no SQL client, no fixtures. Therefore `0023` **cannot be tested** at this time, and this phase did not create anything.
2. **The blocker is formally recorded** (§6) with nine sub-items and their owners.
3. **What can be done safely right now** is the offline static gate (S1–S16) and, optionally, the Flutter regression suite (T16) — neither proves the cap.
4. **What must be decided next** is how to obtain isolation (local Docker stack vs scratch project vs preview branch); production fixtures remain rejected on irreversible-risk grounds (PHASE-8 §2).
5. **Before any application of `0023`:** isolated test run (Class B), verified restore point, live `prosrc`/ACL confirmation, and the explicit manual apply path — with `0023` applied **after** `0019`.

---

**PHASE 50 COMPLETE**

**NO FILES MODIFIED**

**NO DATABASE CONNECTIONS**

**NO SQL EXECUTED**

**NO MIGRATION APPLIED**

**NO COMMIT**

**NO PUSH**
| Q6 | Verdict | **PRE-TEST READINESS = NOT READY. TEST EXECUTION = BLOCKED (no isolated environment).** The only executable work today is the offline static gate + the Flutter suite. |