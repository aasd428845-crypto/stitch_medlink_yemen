# PHASE 51 — BONUS ISOLATED TEST RESULTS (0023 max_earn contract fix)

> Type: executed isolated-environment test run. All SQL ran inside Docker container `ph51_pg` (scratch databases only) via `docker exec` psql. No Supabase CLI write command was issued. No production contact of any kind.

## 1. Tools, versions, Docker state

| Item | Evidence |
|---|---|
| Docker | 28.1.1 (Engine + buildx + compose v2.35.1); daemon running |
| Supabase CLI | 2.117.0 at `~/.local/bin/supabase` (not updated) |
| Test Postgres | `ph51_pg`, image `public.ecr.aws/supabase/postgres:17.6.1.155`, healthy; **no host port bindings**; volume `ph51_pgdata`; repo bind-mounted read-only at `/work` |
| SQL client | `psql` inside the container (no host psql, no drivers needed) |
| Flutter/Dart | `/snap/bin/flutter`, suite runs offline |
| Pre-existing `ph51_before` DB | 12 tables (branches/products/warehouse/financial refs), 0 rows, **never written by this phase** |

## 2. Isolation proof (safety gate — all six conditions)

1. Target is local/isolated: fresh `ph51_test` database inside `ph51_pg`; container has no host ports, dedicated volume, empty tables at start.
2. Connection is local-only: every statement ran via `docker exec` over the container-internal socket. No TCP to any external host; no credentials exist for production anywhere reachable (`~/.supabase/access-token` absent, zero relevant env vars).
3. No push/reset path used: zero `supabase db` write commands (`push`, `reset`, `db diff --linked`, `db query --linked`, `migration up`) were issued in this phase; the CLI link to production was never exercised for writes (or at all).
4. Neither `lmkomzqioneuyvatzsov` nor `hhqhoqwpebnmfuhwhllw` referenced in any command, connection string, or fixture.
5. No production data copied: all fixtures synthetic (`TEST_*` names, `medlink-test+*@invalid` emails, fixed UUIDs); row counts in `ph51_before` untouched.
6. Gate verdict: **ISOLATION PROVEN — execution authorised by the phase mandate.**

## 3. Test-database creation method

- Fresh `ph51_test` (+ drop/recreate cycles during bootstrap).
- Scratch-only scaffolding (never in repo, never a migration): minimal `auth` schema (`users(id)`, `uid()`/`role()` backed by `app.test_uid`/`app.test_role` GUCs), empty `supabase_realtime` publication, minimal `storage.buckets`/`objects` stubs matching the columns 0015 touches.
- Replay: 36-file interleaved chain per PHASE-8 §5.2 (root 0001–0008, web 0001–0004, root 0009, web 0005, root 0010–0014, web 0006–0014, root 0015/0016, root 0017–0022; 0023 held back for the before/after split).
- Bootstrap findings (all in scratch, none touching repo files): `auth.role()` stub required; `0013` repo file ends with a stray `</content>` line (pre-existing defect — its two policy statements applied, the garbage tail failed; file NOT modified); `storage` schema/tables stubbed minimally.
- Baseline (pre-0023): both functions contain `max_bonus` 3× / `max_earn` 0×; defect reproduced live-in-scratch: rule INSERT → `record "p_rule" has no field "max_bonus"` (trigger chain).
- Column fingerprint `b246bd4c…` and ACL fingerprint `dfda960b…` snapshotted pre-0023.

## 4. Executed tests and results (PHASE-47 §G)

| # | Case | Expected | Actual | Result |
|---|---|---|---|---|
| T1 | valid cap 100 | INSERT succeeds | row created | PASS |
| T2 | cap 0 and −1 | both rejected, message names `max_earn` | both rejected, message exact | PASS |
| T3 | NULL cap | INSERT succeeds | row created | PASS |
| T4 | full PWA `toDbPayload` key set | INSERT succeeds | row created | PASS |
| T5 | UPDATE name | succeeds (BEFORE UPDATE passes) | UPDATE 1 | PASS |
| T6 | suspend→active toggle | both succeed | both succeed | PASS |
| T7 | bonus 500, cap 200 → deliver | one EARN 200, key `SALES_EARN:{order}:{rule}` | exactly 200, key exact | PASS |
| T8 | NULL cap, bonus 500 → deliver | EARN 500 | 500 | PASS |
| T9 | bonus 200, cap 200 | EARN 200 (strict `>`) | 200 | PASS |
| T10 | computed 0 | no ledger row | 0 rows, delivery persists | PASS |
| T11 | PER_UNIT 5×100 cap 250; PER_PRODUCT 5×80 cap 250 | 250 / 250 | 250 / 250 | PASS |
| T12 | re-delivery | still 1 row | 1 row, 200 | PASS |
| T13 | delivery persists with active rule | status stays delivered + earn | delivered + earn | PASS |
| T14 | suspended account | hold row, status persists, no earn/error | 1 hold, 0 ledger | PASS |
| T15 | min_order_value above order | no earn, no error | 0/0, delivered | PASS |
| T16 | Flutter suite + analyze | 39/39, 4 pre-existing infos | 39/39, 4 infos | PASS |
| T17 | no accidental DDL | identical column fingerprint | `b246bd4c…` identical | PASS |
| T18 | ACL preserved | identical proacl both functions | identical | PASS |

Before/after: pre-fix defect reproduced (`42703` on rule write); post-fix all green. No side effects observed (ledger/audit/pending counts match expectations per test; fixtures isolated per order).

## 5. Blocked tests

None. All 18 executed. (T16 Flutter noted as guard-only: the fix touches zero app files, so it proves no collateral change, not cap logic.)

## 6. Defects found

- In 0023: **none**. Markers post-apply: `max_bonus` 0/0, `max_earn` 3/3, schema+ACL fingerprints identical.
- In test path (pre-existing repo issues, NOT modified): `0013` stray `</content>` tail (statements still applied); `storage` schema absent from fresh-DB replay (stubbed in scratch); `auth.*` stubs required (documented scaffolding).
- No behavioural deviation from the PHASE-47 contract in any test, including boundary (T9), zero-earn (T10), multi-basis (T11), and hold path (T14).

## 7. Recommended next step (no execution)

The isolated run fully passes. The remaining pre-application items from prior phases are unchanged and still owner-gated: (a) verify a production restore point (PHASE-5 §M, never verified); (b) re-confirm live `prosrc`/ACL immediately before any manual apply; (c) owner acknowledgement that the cap becomes effective for the first rule created afterwards (J7); (d) apply manually via SQL Editor after 0019 semantics, never `db push`. This phase takes no position beyond reporting the green isolated run.

Cleanup performed: scratch database `ph51_test` DROPPED; `ph51_before` untouched (verified still 12 tables, no bonus schema); container left running; no repo files modified except this report.

PHASE 51 COMPLETE
PRODUCTION DATABASE UNTOUCHED
NO PRODUCTION MIGRATION APPLIED
NO COMMIT
NO PUSH

## 8. Disclosure: parallel scaffold discovered (not authored or executed here)

During final tree verification, untracked files were found that this phase did not create: `scripts/test-env/` (`replay-chain.sh`, `bootstrap-prereqs.sql`, `ph51-fixtures.sql`, `ph51-tests.sql`, timestamps 15:07–15:38 +0300 today), `supabase/config.toml` + `supabase/.gitignore` (2026-09-30). They target a different container (`medlink_ph51_test`) with equivalent isolation guards. None were executed, modified, or depended upon here — all results above come solely from `ph51_pg`/`ph51_test` via direct commands. The two tracks did not interfere (separate containers, separate databases; this track's scratch DB is now dropped). Flagged so a future reader does not misattribute authorship and so duplicate test runs can coordinate.
