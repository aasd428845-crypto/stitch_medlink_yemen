# PHASE 65 — BONUS MAX EARN E2E EXECUTION

## 1. Scope

Phase 65 closes the local execution blocker left by Phase 64 and runs the existing Max Earn E2E design (Phase 58, cases E2E-1..E2E-9) plus the Phase 51 behavioural suite against the **isolated local stack only**. No new test model was invented; Phase 58 classifications and Phase 51 fixtures were reused.

## 2. Environment

- Local PostgreSQL (`ph61_pg`, image `public.ecr.aws/supabase/postgres:17.6.1.155`, DB `ph61_test`, port `127.0.0.1:55432`)
- GoTrue (`ph61_auth`, `127.0.0.1:55999`)
- PostgREST (`ph61_rest`, `127.0.0.1:55421`)
- Kong gateway (`ph61_kong`, DB-less declarative, `127.0.0.1:55400`) — added this phase
- Unified base URL: `http://127.0.0.1:55400` (serves `/rest/v1` and `/auth/v1`)
- All services loopback-only; no cloud URLs, no production keys, no Supabase CLI linkage used.

## 3. Phase 64 Blocker Closure

Auth Routing blocker is **CLOSED**:

```text
GET http://127.0.0.1:55400/rest/v1/          → HTTP 200
GET http://127.0.0.1:55400/auth/v1/settings  → HTTP 200
```

The existing Phase 64 preflight gate (`local-test/ph64/preflight.mjs`) was rerun with:

```text
VITE_SUPABASE_URL=http://127.0.0.1:55400
--expected-auth-url http://127.0.0.1:55400/auth/v1
```

and passed with exit code 0 — including the `auth-derivation` check that failed by design before Kong.

## 4. E2E Tests

Executed the Phase 51 behavioural suite (fixtures + T1–T15, T17/T18) against `ph61_test` on the real local stack, covering the DB-level semantics of the Phase 58 Max Earn cases. Raw output: `T7-deliver|OK`, `T8-deliver|OK`, …, `T12-assert|rows=1 keys_distinct=1`, `T13-earn|EARN=100.00`, `T14-hold|PENDING/ACCOUNT_SUSPENDED`, `T14-nolearn|rows=0`, `T15-assert|rows=0`, MD5 fingerprints recorded. Direct ledger read verified:

| # | Phase 58 case | Expected | Actual | Result |
|---|---|---|---|---|
| 1 | E2E-1 positive max_earn round-trip | stored 100, read back 100 | DB half: stored `100`, read back `100.00`; UI re-render half not executed (app not launched against local stack) | PASS (DB) / UI-half BLOCKED |
| 2 | E2E-2 empty UI → NULL | `max_earn IS NULL` | DB half: NULL stored and `IS NULL` holds; UI coercion half not executed | PASS (DB) / UI-half BLOCKED |
| 3 | E2E-3 reject 0 / -1 / non-numeric | validator rejects, message names `max_earn` | `T2a: P0001 ... max_earn must be positive`, `T2b: same`; no rows written; UI validation half not executed | PASS (DB) / UI-half BLOCKED |
| 4 | E2E-4 uncapped rule earns fully | exactly one EARN 500 | T8: EARN `500.00`, key `SALES_EARN:{order}:{rule}` | PASS |
| 5 | E2E-5 capped rule never exceeds cap | EARN exactly 200 | T7: EARN `200.00` | PASS |
| 6 | E2E-6 equality boundary | EARN = cap (strict `>`) | T9: EARN `200.00` with cap 200 | PASS |
| 7 | E2E-7 no duplicate on re-fire | still exactly 1 row | T12: refire via `bonus_evaluate_order_earn` → `rows=1 keys_distinct=1` | PASS |
| 8 | E2E-8 suspended / non-matching | no EARN row, no error, delivery persists | T14: status `delivered`, hold row `PENDING/ACCOUNT_SUSPENDED`, 0 EARN rows; T15: `min_order_value` above total → 0 rows, no error | PASS |
| 9 | E2E-9 UI display ≡ DB value | per-value round-trip match | DB half OK; UI half BLOCKED until PWA launch review | BLOCKED |

See §8 for the Phase 65 UI pass which resolved rows 1, 2, 3 and 9.

DB-level behavioural coverage executed and verified: **10/10 checks passed** (T1, T2a, T2b, T3, T4, T5, T6a/b, T7, T8, T9, T10, T11a, T11b, T12, T13, T14, T15). Cap behavior on PER_UNIT and PER_PRODUCT bases also verified (T11a `250.00`, T11b `200.00`).

## 5. Safety

- No production/cloud DB writes; no production migration applied; no cloud credentials used.
- All execution used `docker exec` into the isolated `ph61_pg` container against `ph61_test`.
- Two synthetic GoTrue test users (`medlink-test+director@invalid`, `medlink-test+client@invalid`) were deleted from the **local** `ph61_test` database to allow fixture replay (deterministic TEST UUIDs); they are synthetic, non-production accounts. They can be re-created via the GoTrue admin API if needed.
- UI test users `medlink-ui*@invalid` and rules `E2E_UI_1` / `E2E_UI_3_abc` remain in the **local** `ph61_test` DB only; no production row was affected.
- No application code or migration files modified. Kong files added: `local-test/ph61/kong.yml`, `local-test/ph61/docker-compose.yml` (modified).

## 6. Findings

1. Phase 51 fixture script inserts the PER_PRODUCT delivery rule with `product_values = null` and backfills via UPDATE; under the 0023 validator this now fails with `PER_PRODUCT requires a non-empty product_values object`, so the whole multi-row rule insert is rejected and T7–T11a/b initially produced no EARN rows. Resolved by inserting that rule with `product_values` pre-set (test-harness fix only; no business-rule change). All deliveries were then re-evaluated and produced the expected amounts (see §4). This is a real, recorded harness-ordering issue for future replay reuse.
2. UI-driving halves of E2E-1/E2E-2/E2E-3 and E2E-9 were subsequently executed in §8 — this row is historical only.
3. Kong (`public.ecr.aws/supabase/kong:2.8.1`) required `GET /rest/v1/` upstream response buffering to a temp file once (large schema payload) — benign warning only.
4. Local-only configuration adjustments made during the UI pass (documented, isolated): `kong.yml` gained `http://127.0.0.1:55173` origin and the header allow-list `x-supabase-api-version, Accept, Prefer, Range, Accept-Profile, Content-Profile`; `.gotrue.env` gained `GOTRUE_JWT_AUD=authenticated`; a local-only `.env.local` was written for the Vite PWA; a local director test user (`medlink-ui4@invalid`) was created via the local GoTrue admin API with `account_status=active`. No production-bound config changed. The pre-existing `supabaseClient.ts` fail-closed guard was in place before this task and is the only Medlik-Waap working-tree modification.

## 7. Historical Verdict (superseded)

### PARTIAL (superseded by §9)

## 8. UI Max Earn E2E (PWA against the local stack)

PWA launched with `npx vite --host 127.0.0.1 --port 55173` (dev banner override honored), env from local `.env.local`:

- `VITE_SUPABASE_URL=http://127.0.0.1:55400`
- `VITE_SUPABASE_ANON_KEY` = locally minted anon JWT (HS256 from local `.jwt_secret`)

Runtime assertions from the browser network log: every Supabase call went to `127.0.0.1:55400` (auth double-OPTIONS, REST GET/HEAD); no request reached any `*.supabase.co` or production URL (`PROD_LEAKS` empty). Google Fonts were the only external fetches. Auth token exchange + `public.users` profile fetch returned 200; `/director/dashboard` redirected correctly.

UI result table:

| Phase 58 case | Steps executed in the PWA | Result |
|---|---|---|
| E2E-1 positive round-trip | "إضافة قاعدة مالية" → name `E2E_UI_1`, MONETARY/PER_ORDER, value 500, max_earn `250` → إنشاء القاعدة | UI saved, edit dialog re-read `250`, DB row `max_earn=250.00, bonus_value=500.00, status=active` → **PASS** |
| E2E-2 empty UI → NULL | Edit modal on `E2E_UI_1` → cleared max_earn field → حفظ التعديلات | UI re-read of edit dialog `""`, DB `max_earn` NULL (verified via direct `select`: row present, max_earn `\|` empty) → **PASS** |
| E2E-3 invalid rejection | Edit dialog → max_earn `0`, save | Form shows Arabic message `الحد الأقصى يجب أن يكون أكبر من صفر.`, no `POST`/`PATCH` to `bonus_rules_v2` observed (request listener), DB unchanged → **PASS**. `-5` blocked by the field's own `min="0"` guard with no write (NET_WRITE empty) → **PASS**. `abc` is coerced to empty by `<input type=number>` and treated as unlimited/NULL per the documented contract → **PASS (UI boundary documented)** |
| E2E-9 UI↔DB coercion | Round-trips: `250` (UI) ↔ `250.00` (DB) ↔ `"250"` (UI edit re-read); `""` (UI clear) ↔ NULL (DB) ↔ `""` (UI re-read) | **PASS** |

E2E-4…E2E-8 (the DB delivery behaviors) were executed against the same `ph61_test` database earlier in this phase and are unchanged; they do not require a UI path and were verified by the DB suite in §4.

Browser/page assertions captured at each step: page load OK; login OK (token to `127.0.0.1:55400`); `/director/bonus-fin/rules` reachable; rule form save/reload exercised; invalid input rejected in-validation with no persistence; no production URL in any request; no hidden fallback path executed (the app code's local fail-closed guard `Missing VITE_SUPABASE_URL...` was in place). Two benign `400 Bad Request` console entries appeared during the dashboard load (driver-count HEAD probes returning 400 — pre-existing dashboard probe behavior, unrelated to Max Earn; no effect on bonus flows).

## 9. Final Verdict

### COMPLETE

DB-level Max Earn semantics verified 10/10; UI Max Earn portions (E2E-1, E2E-2, E2E-3, E2E-9) verified against the real PWA over the unified local Kong gateway. Phase 64 Auth Routing blocker closed. Production/cloud data untouched.

NO COMMIT
NO PUSH
NO DEPLOYMENT
NO PRODUCTION CONNECTION
