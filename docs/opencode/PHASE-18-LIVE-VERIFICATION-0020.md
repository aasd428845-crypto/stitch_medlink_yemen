# PHASE 18 — LIVE VERIFICATION OF MIGRATION 0020 (read-only — nothing changed, nothing applied)

## 1. Target Project
TARGET VERIFIED: `lmkomzqioneuyvatzsov` — CLI `projects list` shows link marker ● on `موريد الادويه`, Northeast Asia (Tokyo). Second project `hhqhoqwpebnmfuhwhllw` (وصل) untouched; no query addressed it. All reads via `supabase db query --linked` (SELECT-only statements).

## 2. Application Confirmation
Operator applied `supabase/migrations/0020_order_discount.sql` manually. This phase proves application by live-catalog fingerprint, not by migration history (manual-apply project, same as the 0019 precedent). Local file hash (17.3): `62b6a64f…`; live body diff performed in §5.

## 3. Migration Object Inventory
Live present, matching local 0020 exactly: `apply_order_discount(uuid,numeric,text)`, `cancel_order_discount(uuid,text,text)` — both owner postgres, volatile, SECURITY DEFINER. Six `discount.*` settings rows (no `accounting.*` rows). No new tables/indexes/triggers (by design). Grants: EXECUTE to authenticated on both (in-function authorization carries access control).

## 4. Configuration Verification
Live `bonus_settings`: `discount.allow_zero_order=false`, `discount.funding_scope="ALL_ELIGIBLE_LOTS"`, `discount.cancellation_mode="AUTOMATIC_REVERSAL"`, `discount.max_amount/max_percent/min_amount=null`. All six match the 16.7 product locks. No LIVE CONFIGURATION MISMATCH.

## 5. Function Verification
Arguments/returns/definer/owner match local 0020 verbatim (§3 queries). Body fingerprint: live `prosrc` pulled as JSON and diffed line-by-line against the local file — the only deltas are extraction-boundary artifacts (leading newline + trailing `end` keyword); zero content hunks. search_path live: `[search_path=public]` on both. Verdict: LIVE DEFINITIONS IDENTICAL TO LOCAL 0020.

## 6. Security Verification
- Direct `INSERT bonus_ledger` as authenticated: NO — live RLS shows SELECT-only policies (`bonus_ledger_client_select`, `bonus_ledger_director_select`), no write policies.
- Direct `bonus_earn_allocations` write: NO — SELECT-only policies likewise.
- Unauthorized order discount: blocked in-RPC (client-only + ownership + pending; verified in live body markers).
- Unauthorized cancellation: blocked in-RPC (owner-or-director + ownership for clients).
- Note: `anon` EXECUTE=true on both new functions — parity-checked live against `request_redemption`, `reverse_bonus_txn`, `bonus_account_funds` (all true). Pre-existing platform convention (Postgres PUBLIC default), not a 0020 regression; anon callers fail at `auth.uid() is null`. INFO only.

## 7. Ledger Verification
Live CHECK `bonus_ledger_txn_type_check` contains the full 10-type array including `ORDER_DISCOUNT` — intact, unmodified by 0020 (no DDL on the table was in the file).

## 8. Allocation Verification
`bonus_earn_allocations` table present; `bonus_allocate_spend` + `bonus_credit_remaining` present (1/1 each) — the exact helpers 0020's inline walk relies on (`bonus_credit_remaining` for remainder math; oldest-first/shortfall semantics reproduced inline per 17.1 review). `bonus_ledger_reverses_uniq` index present live — covers 0020's REVERSAL rows (predicate matches `reverses_id` + `REVERSAL`).

## 9. 0017 Compatibility
`create_order_with_items` present (1/1). 0017 file untouched in working tree; order lifecycle (pending-only discount gate) consistent with 0017 insert state and 0016 allocation requirements.

## 10. 0018 Compatibility
All 0020 dependencies present with expected definitions: funds/remaining/allocate-spend helpers, ledger/alloc/settings/audit/alloc tables, UNIQUE idempotency, immutability trigger, reversal unique index. `reverse_bonus_txn` live body retains director guard + effective-reversal dedup markers. No 0018 behavior altered (0020 is purely additive; 0018 working-tree diff predates Phase 17).

## 11. 0019 Compatibility
`earn_bonus` present (1/1). 0019 reads `order_items` for earn evaluation and counts only `txn_type='EARN'` rows for usage limits; its PENDING lifecycle lives in the separate pending-entitlements table — 0020's ORDER_DISCOUNT/REVERSAL rows are invisible to every 0019 predicate (re-validated live in 17.2, unchanged since).

## 12. Free-Y Isolation
`order_items.bonus_rule_id` column present live (1/1); no new coupling — 0020 references no order_items columns (verified in file review; nothing to create coupling live since no financial rows exist, §15).

## 13. GL Isolation
Zero GL/journal tables live (targeted name scan, 0 rows). No `gl_entry_id`-style columns. D4 accounting-neutral posture intact.

## 14. Tenant Boundary
Zero `tenant_id`/`company_id`/`gl_entry_id` columns across all `bonus_*` tables live (0 rows). No tenant infrastructure fabricated. Future-product gap stands, unchanged.

## 15. Initial Data State
`bonus_ledger` rows with `txn_type='ORDER_DISCOUNT'`: 0. Allocations referencing ORDER_DISCOUNT debits: 0. `DISCOUNT_APPLY`/`DISCOUNT_REVERSAL` audits: 0. Migration created configuration + code objects only — no financial data generated by application. Clean initial state.

## 16. Verification Matrix
| Check | Local Expected | Live Actual | Result |
|---|---|---|---|
| Migration file | 0020 (413 lines) | applied by operator | PASS |
| Config keys | 6 discount.* | 6 present | PASS |
| Config values | locked defaults | all match 16.7 | PASS |
| apply_order_discount | exists, definer, uuid | exact + body-identical | PASS |
| cancel_order_discount | exists, definer, uuid | exact + body-identical | PASS |
| Security posture | SELECT-only RLS, in-RPC auth | verified live | PASS |
| Grants | authenticated EXECUTE | true/true, search_path public | PASS |
| ORDER_DISCOUNT type | in CHECK | present in live def | PASS |
| Reversal index | exists | present | PASS |
| 0018 compatibility | helpers intact | present + markers | PASS |
| 0019 compatibility | independent | predicates unaffected | PASS |
| Free-Y isolation | intact | column present, uncoupled | PASS |
| GL isolation | intact | 0 objects | PASS |
| Tenant boundary | intact | 0 columns | PASS |
| Initial financial state | unchanged (0 rows) | 0/0/0 | PASS |

## 17. Errors/Timeouts/Corrections
All attempts, including failures, recorded (nothing hidden):
1. `discount.*` settings SELECT — Attempt 1: timed out at 120s, no output. Correction: retried with `statement_timeout='30s'` + `timeout 100` wrapper. Final: success, 6 rows.
2. Anon-parity SELECT (4 functions) — Attempt 1: returned only init line, no rows, exit 0 (indeterminate). Correction: re-ran minimal single-function probe (success), then full 3-function parity query (success, all true).
3. Function-marker query (`pg_get_functiondef` ×2 with 4 `position()` calls) — Attempt 1: timed out at 180s. Correction: replaced with lighter `length(prosrc)` + `md5(prosrc)` per function (success), then full JSON body pull + local diff (success, identical modulo extraction boundaries).
4. `ORDER_DISCOUNT` ledger count — Attempt 1: timed out at 180s. Correction: retried with `statement_timeout='120s'` + 240s wrapper. Final: success, 0.
5. Combined GL-name scan — Attempt 1: tool execution interrupted, no result. Correction: re-ran as targeted IN-list query. Final: success, 0 rows.
6. Tenant-column scan — Attempt 1: transient pooler auth failure (`FATAL: password authentication failed for cli_login_postgres`, Management-API temp role). Correction: plain retry. Final: success, 0 rows. Same transient hit the allocation-count query once; retry succeeded (0).
No query beyond SELECT was ever issued; no retry altered data (all statements read-only).

## 18. Findings
- No mismatch, drift, or defect found. Live objects are identical to the reviewed local file.
- INFO (parity, not a finding): anon EXECUTE=true matches all pre-existing 0018 functions; authorization remains in-function + RLS.
- Operational note: the linked-query path shows intermittent latency/auth flakes (3 timeouts + 2 transient auth failures across ~15 queries); all resolved by retry. Future live phases should budget retry wrappers and statement timeouts.

## 19. Blockers
None.

## 20. Final Status
Schema, functions, configuration, security, dependencies, isolation boundaries, and empty initial financial state all verified against the reviewed local 0020. No application code touched, no migration pushed, no data written by this phase.

PHASE 18 STATUS:
0020 LIVE VERIFIED
NO APPLICATION CODE CHANGES
NO MIGRATION DRIFT DETECTED
