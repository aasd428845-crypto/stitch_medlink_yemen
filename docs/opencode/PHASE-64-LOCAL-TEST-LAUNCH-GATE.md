# PHASE 64 — LOCAL TEST LAUNCH GATE

## A. Actual Connection Path

Single client factory: `Medlik-Waap/artifacts/pharma-pwa/src/lib/supabaseClient.ts` reads `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY`, falling back to hardcoded production URL + publishable key (`sb_publishable_…`). Exactly one `createClient` call site (gate-asserted). Only these two `VITE_*` vars exist repo-wide. Auth URL is derived by the SDK as `<base>/auth/v1` — no separate auth URL variable exists.

## B. Fallback Analysis

Fallback present and unremovable in this phase (app code frozen): missing/empty env → production URL + production key, silently. The gate neutralizes it by requiring every read var to be explicitly defined (an unresolved fallback fails closed). Residual risk: any future second client factory or direct-URL call would bypass these assertions — the gate re-scans the source file on every run (single-callsite check), so additions fail loudly rather than silently.

## C. Preflight Design

`local-test/ph64/preflight.mjs` (Node, zero deps): env-file parse → URL present/non-placeholder/exact-literal-match → key present/non-placeholder/≠ known-production-key → all `VITE_*` loopback-only + denylist (both prod refs) → source audit (every read var defined; single callsite) → auth-derivation equality. Any failure → `BLOCKED`, exit non-zero. Secrets never printed (length-only). Exit 2 = usage/missing-file errors.

## D. Gate Test Results (all executed, zero network)

| Case | Result |
|---|---|
| T1 derivation contract (auth = base + /auth/v1) | PASS (exit 0) — proves the pass path works |
| T1b real stack topology (GoTrue :55999, no Kong) | PASS — fails `auth-derivation` **as designed** (see §F) |
| T2 missing file / T3 missing URL / T5 missing key | PASS (reject) |
| T4 cloud URL+key | PASS (reject; output contains no secret bytes) |
| T6 conflicting var / T7 unresolved fallback / T8 auth mismatch | PASS (reject) |
| Total | **10 pass, 0 fail** |

## E. Remaining Risks

1. **Auth routing gap (found by the gate, not despite it):** with GoTrue on :55999 and no Kong, no single base URL serves both PostgREST and `/auth/v1` — any app launch today either breaks login or misroutes auth. Requires Kong (image present locally) or equivalent before UI runs; until then the gate correctly BLOCKS launches.
2. **Service-worker staleness:** `vite-plugin-pwa` `registerType: autoUpdate` mitigates but a previously installed SW could serve a stale bundle — future runs require fresh profile/incognito + SW unregister (procedural, documented here).
3. **Vite dev binds `0.0.0.0`** (`package.json` dev script) — future runs must override to loopback (`--host 127.0.0.1`); documented, not changed.
4. Parallel-track resources untouched; `scripts/test-env/` not used or modified by this phase.

## F. Launch Decision

**BLOCKED — PRODUCTION FALLBACK NOT SAFELY CONTAINED.** The gate itself works (10/10), but the honest end-to-end verdict is BLOCKED on two counts: (a) the unresolved hardcoded fallback can only be neutralized per-run, never removed, without an app-code change; (b) the auth-routing gap (§E.1) means no configuration can currently satisfy the derivation contract against the real topology. A separate app-launch review remains mandatory even after these close.

PHASE 64 COMPLETE — PREFLIGHT GATE CREATED AND TESTED
NO APPLICATION LAUNCH
NO PRODUCTION CONNECTION FOR TESTING
NO DATABASE WRITES
NO MIGRATIONS APPLIED
NO BONUS TESTS EXECUTED
NO EXISTING DOCKER RESOURCES MODIFIED
NO COMMIT
NO PUSH
NO DEPLOYMENT
