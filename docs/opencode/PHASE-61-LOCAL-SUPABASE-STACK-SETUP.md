# PHASE 61 — LOCAL SUPABASE STACK SETUP & ISOLATION VERIFIED

> Read-only where mandated; only NEW isolated resources created. No migrations applied, no tests run, no existing resource touched.

## A. Resource Inventory Before / After

Before: `ph51_pg` healthy (untouched throughout — still healthy at close); parallel `medlink_ph51_test` exited (untouched); bridge network with ph51_pg only; no ph61_* anything.
After (new only): network `ph61_net`, volume `ph61_pgdata`, containers `ph61_pg` (healthy), `ph61_auth` (up), `ph61_rest` (up); host ports 127.0.0.1:55432/55999/55421; config dir `local-test/ph61/` (compose + 4 mode-600 env files + 2 raw secret files). Pre-existing resources verified unmodified (statuses re-checked at close).

## B. Local Service Health

| Service | Address (loopback-only) | Health evidence |
|---|---|---|
| PostgreSQL 17.6.1.155 | 127.0.0.1:55432, DB `ph61_test` (auto-created, 0 public tables) | container healthy; fresh empty DB confirmed |
| GoTrue v2.197.0 | 127.0.0.1:55999 | `/health` + `/settings` HTTP 200; own migrations ran (auth schema populated) |
| PostgREST v14.5 | 127.0.0.1:55421 | `/` HTTP 200; unknown table returns PGRST205 (proves it serves the local empty DB) |

Setup notes (scratch-only, documented not repeated): fresh JWT + DB secrets generated locally; `ALTER SCHEMA auth OWNER` + `GRANT supabase_auth_admin TO postgres` + `API_EXTERNAL_URL` fix were required for GoTrue bootstrapping against the stock image (image ships `postgres` non-superuser with pre-seeded auth objects). No production material involved at any step.

## C. Production Isolation Evidence

1. Target URL nowhere configured: all env files + compose grepped — zero `supabase.co`/project-ref hits.
2. Container env audit (`ph61_pg/auth/rest`): zero cloud references in every variable.
3. Secrets are fresh random hex (DB password, JWT) generated this phase; no production key, password, or token exists on this machine path (prior phases: no access token, no env creds).
4. Network isolation: dedicated `ph61_net`; services bind 127.0.0.1 only; no route to cloud required or configured.
5. Fallback analysis (static, app NOT run): PWA `supabaseClient.ts` falls back to production URL + hardcoded key when `VITE_*` absent — therefore NO app run is authorized until an explicit `.env.local` exists AND a preflight assertion (per Phase 60 §3) passes. Fallback NOT disabled in code (modification forbidden this phase) → recorded as the standing technical gap below.
6. CLI link to production untouched and unused (zero `db push/reset/query --linked` issued).

## D. Database State

DB `ph61_test`: auto-created empty (0 public tables); GoTrue wrote only its own auth-schema objects. Roles present per image default. NO migrations applied (0001–0023 untouched on disk and unapplied here); NO bonus tables/rows; NO fixtures. Schema work is deferred to a later migration-bootstrap phase.

## E. Blockers

1. **App fallback to production (TECHNICAL GAP, carries forward):** code defaults to prod URL+key; no app run permitted until `.env.local` + preflight gate exist. No fix applied (forbidden).
2. **No migrations applied** (by mandate): E2E runs remain blocked on a future bootstrap phase.
3. Parallel-track resources (`medlink_ph51_test`, `scripts/test-env/`) untouched; coordination still advised before port/volume expansion.

## F. Next-Phase Readiness

**PARTIALLY READY** — stack + isolation proven; migration bootstrap + fallback gate + tests remain. NOT "READY" (that word requires the §E gaps closed and is not claimed).

PHASE 61 COMPLETE — LOCAL STACK SETUP AND ISOLATION VERIFIED
NO PRODUCTION CONNECTION FOR TESTING
NO CLOUD DATABASE WRITES
NO MIGRATIONS APPLIED
NO BONUS TESTS EXECUTED
NO EXISTING DOCKER RESOURCES MODIFIED
NO APPLICATION CODE MODIFIED
NO COMMIT
NO PUSH
NO DEPLOYMENT
