# PHASE 60 — LOCAL SUPABASE STACK PREPARATION PLAN (plan only)

> Nothing created, started, stopped, or modified. All resources below are PROPOSED names/ports only.

## 1. Resource review (observed, untouched)

| Resource | State | Conflict assessment |
|---|---|---|
| `ph51_pg` (running, 5432/tcp internal only) | healthy, holds `ph51_before` | NO conflict if new resources use distinct names/ports/network; must never be stopped, restarted, or attached to |
| `medlink_ph51_test` (exited, parallel track) | untouched | NO conflict; do not start/remove (foreign ownership) |
| `ph51_pgdata` volume | in use by ph51_pg | new stack needs its OWN volume |
| bridge network (only ph51_pg attached) | no port collisions on host (54321/54322/54323/54324/8000/3000/5173 all free) | new stack gets its OWN network |
| Host tooling | Docker 28.1.1, no host psql (unchanged) | no change |

## 2. Local stack design (for max_earn UI→DB only)

Required services (proven by code usage): **PostgreSQL 17** (Supabase image, RLS + pgcrypto + `auth`/`storage` platform objects), **PostgREST** (all PWA data access is PostgREST incl. RPC), **GoTrue** (RLS session context; director-gated writes need a real JWT, GUC stubs are insufficient for UI runs). Optional: **Storage** (only `getPublicUrl` string-building is used in bonus-adjacent pages — no upload in test scope; include minimal service or omit with documented skip), Kong gateway (optional; direct PostgREST port is enough for tests), Studio (omit).
Out of scope: Edge Functions (only account-management invokes; not bonus flows), Realtime (no `.channel(` usage found), SMTP/push (must stay absent).

Proposed isolated names/ports (NOT created): containers `ph60_db`, `ph60_rest`, `ph60_auth` (+optional `ph60_storage`); network `ph60_net` (no attachment to bridge/default); volume `ph60_pgdata`; host ports DB `55432`, API `55421`, Auth `55999` — chosen clear of defaults (54322/54321/54329), of ph51 (internal-only), and of app dev ports. JWT secret: fresh random per build, never committed, never reused from any project.

## 3. Production-connection prevention gate

Verified hazard: `supabaseClient.ts` falls back to production URL + hardcoded publishable key when `VITE_*` are absent; `.env.local` does not exist. Gate design (to be implemented at build phase, specified here): a preflight module executed before the first network call AND before each test file asserting ALL of: (a) `supabaseUrl` string-equals the configured local API URL literally (no substring/contains logic); (b) anon key equals a `TEST-LOCAL-` prefixed sentinel recorded at stack build (proves key provenance, not just non-production shape); (c) `supabaseUrl` does not contain `supabase.co` or any known project ref (denylist incl. both production refs); (d) DNS/container check that the URL host resolves to the `ph60_net` gateway or localhost mapping. ANY failure → hard abort with message naming the offending value class (never printing secrets). `.env.local` presence alone is explicitly INSUFFICIENT (a stale/prod-pointing file would pass it) — hence (a)–(d).

## 4. Migration chain + scaffolding

Reuse the proven Phase 51 method: 36-file interleaved order (root 0001–0008, web 0001–0004, root 0009, web 0005, root 0010–0014, web 0006–0014, root 0015/0016 with the `0013`-tail and storage notes, root 0017–0022, then 0023 last for the after-state). Scaffolding deltas vs Phase 51: GoTrue provides REAL `auth.users`/`auth.uid()` (drop the GUC stubs); platform `storage`/`realtime` objects come with the stack (drop those stubs); keep synthetic `TEST_*` fixtures + drop/recreate cleanup. No migration file is modified in any step.

## 5. Verification sequence (pre-first-query, in order)

1. Container inventory: only `ph60_*` on `ph60_net`; `ph51_pg` untouched/running; no new host listeners except the three assigned ports.
2. URL gate (§3 a–d) green, logged with redacted values.
3. Database identity: fresh DB shows zero user tables pre-replay; post-replay object inventory matches the expected set; `bonus_*` row counts are 0.
4. Auth check: GoTrue signup works locally; director/client test users exist only in the local auth schema.
5. Negative control: with the gate forcibly pointed at a blocked URL in a dry run, execution aborts before any socket opens.
Only then may E2E-1 run; each subsequent case re-asserts (a).

## 6. Classification summary

VERIFIED (by inspection): resource inventory, port freedom, service requirements from code, env-fallback hazard, migration order, scaffolding deltas. AVAILABLE (if built): all Docker primitives needed. CONFLICT: none created (parallel resources avoided by naming/network/port separation; coordination still advised). MISSING: the stack itself, `.env.local`, keys, replayed DB, gate implementation, fixtures. NOT EXECUTED: everything above (by mandate).

PHASE 60 COMPLETE — PREPARATION PLAN ONLY
NO PRODUCTION CONNECTION FOR TESTING
NO DATABASE WRITES
NO EXISTING RESOURCES MODIFIED
NO APPLICATION FILES MODIFIED EXCEPT REPORT
NO COMMIT
NO PUSH
NO DEPLOYMENT
