# PHASE 17.2 — MIGRATION 0020 LOW FINDINGS DISPOSITION (analysis only — nothing modified)

## 1. Executive Summary
All 17.1 findings re-analyzed from primary code (not from the prior report's conclusions). Count correction: 17.1 §17 labels four items LOW (F1, F2, F3, F6); its "5 LOWs" status line is a counting error, recorded here. The fifth analysis slot goes to F7 (unwired cancel path), the only INFO with production-gating character. Replay-before-lock traced request-by-request and proven safe (serialization + post-lock exists-check + UNIQUE backstop). No finding can produce duplicate financial state, incorrect balances, or bonus loss. Disposition: four C (safe to defer) + one C-with-use-gate (F7). No A, no B.

PHASE 17.2 STATUS:
NO MUST-FIX FINDINGS — 0020 CAN PROCEED TO FINAL PRE-APPLICATION REVIEW
NO LIVE DATABASE CHANGES

## 2. Five LOW Findings
- LOW-1 = F1: replay check precedes locks (`0020:105-107`; same class `0020:342-344`).
- LOW-2 = F2: duplicate cancel raises instead of returning existing reversal (`0020:368-373`).
- LOW-3 = F3: caller-supplied custom idempotency key reused across orders replays the wrong id.
- LOW-4 = F6: no index on `bonus_ledger(order_id)` for the exists-check (`0020:129-132`) and cancel lookup (`0020:356-365`).
- LOW-5 = F7 (elevated from INFO for full analysis): no caller/trigger invokes `cancel_order_discount` yet; D3-AUTO is unrunnable until app wiring lands.

## 3. Detailed Risk Analysis
- LOW-1: root cause — replay SELECT runs before `FOR UPDATE` acquisition. Actual risk: loser of a concurrent duplicate gets an explicit error instead of the winner's id. Business impact: retry UX friction only. Financial/security/concurrency impact: none — no second row can exist (proven §4). Production occurrence: possible under double-submit; outcome is a safe error, retry succeeds. No incorrect state, no duplicate, no loss. Performance/UX only: yes.
- LOW-2: root cause — cancel re-checks existence but returns no id on the duplicate path. Same impact profile as LOW-1; double reversal impossible (guard + `bonus_ledger_reverses_uniq`, 0018:171-173; worst case is a unique_violation error). No financial risk. UX only.
- LOW-3: root cause — custom keys are caller-scoped strings with no order binding enforced. Occurs only if a caller reuses one custom key across orders (default keys embed the order id and are safe). Cannot duplicate finance (UNIQUE forces collision→error, never a second posting for the same key; cross-order replay returns an id but writes nothing). Impact: wrong-id response + caller confusion. UX/contract only.
- LOW-4: root cause — 0020 kept additive-minimal scope, no indexes. Affects two low-frequency discount-path queries only. Correctness: zero (planner correctness never depends on the index). At expected volumes the tables are small and these queries run at most twice per discounted order. Performance only.
- LOW-5: root cause — staged plan puts app wiring after the DB stage; no order-cancel RPC exists anywhere in migrations. Cannot corrupt finance (dormant function; nothing calls it). Impact: D3-AUTO unenforced in production until wired — a use-gate, not a migration defect.

## 4. Replay/Lock Analysis
Can two simultaneous requests pass the replay check before locking? Yes — both can read "no row" (0020:105-107). Full trace: A and B pass replay; B blocks on `orders … FOR UPDATE` (0020:112-113) while A holds it; A inserts debit (247-252), allocates, flips, audits, commits; B unblocks and — critically — does NOT re-check the key but DOES run the post-lock exists-check (129-132), which now sees A's committed POSTED row and raises 'already has an applied discount'. If A rolled back instead, B proceeds cleanly. Outcomes possible: exactly one ledger row, or zero rows + two errors. Duplicate ledger: impossible (lock serialization + exists-check + UNIQUE(idempotency_key) triple cover). Duplicate allocation/reversal/balance error: impossible — all writes live inside the winner's single transaction. Verdict: safe serialization proven from code; residual is UX-only. NOT a MUST FIX.

## 5. Idempotency Analysis
Default key `DISCOUNT:{order_id}` (0020:70-71): distinct per order, distinct namespace from reversal keys (`REVERSAL:DISCOUNT:`), enforced by the pre-existing UNIQUE constraint — no collision with redemption/withdrawal/earn keys (different formats/prefixes). Single-discount-per-order is the locked product design (16/16.4: cancel-then-reapply for amount changes), so one key per order is sufficient, not deficient; multiple independent discounts per order are not a supported business shape and the key correctly prevents them. Cancellation/reversal use their own key space with their own guards. Custom keys preserve all guarantees only under caller uniqueness — a wiring-time documentation item (LOW-3/C).

## 6. Index Analysis
Queries using order_id: apply exists-check (129-132: order_id + txn_type + status) and cancel latest-debit lookup (356-365: same + ORDER BY created_at). The planner needs no index for correctness. Expected table scale at launch is small; each discounted order triggers at most two such queries. Absence affects latency only, marginally. Adding `CREATE INDEX IF NOT EXISTS … (order_id)` inside 0020 would be safe (additive, brief lock, no CONCURRENTLY possible or needed inside a migration transaction), but keeping 0020 frozen post-review has value too. Recommendation: fold the index into the pre-apply amendment batch alongside any accepted F1/F2 polish, or ship as a tiny follow-up migration. Category C either way. No index added in this phase.

## 7. Positive Findings Revalidation
- A. `bonus_ledger_reverses_uniq` (0018:171-173, re-read verbatim): partial unique on `(reverses_id)` where `reverses_id is not null and txn_type in ('REVERSAL','EXPIRATION')`. 0020's reversal sets `reverses_id` + `txn_type='REVERSAL'` (0020:391-397) — squarely inside the predicate. Coverage confirmed from primary sources; concurrent double-cancel cannot physically commit twice.
- B. 0019 independence re-verified: earn reads `order_items` for eligibility/value (0019:320-360) and counts only `txn_type='EARN'` rows for usage limits (0019:341-352); its inserts are POSTED EARN credits with `on conflict (idempotency_key) do nothing` (0019:397-405, 575-585); its PENDING lifecycle lives in the separate `bonus_pending_entitlement` table (0019:58-59, 537-538) — it never sweeps ledger PENDING reservations, and 0020's PENDING debit exists only intra-transaction. 0020 rows (ORDER_DISCOUNT/REVERSAL) are invisible to every 0019 predicate. No interference in either direction.
- C. Shared account lock re-verified: apply (via `bonus_account_funds`, 0020:206-207) and request_redemption (0018:~830) and request_withdrawal (0018:1089, verified this phase) all funnel through `bonus_account_funds`, which takes `bonus_accounts … FOR UPDATE`. Earn inserts credits without consuming ( ordering vs earn is conservative-safe); expiry (0018:1430+) locks credit rows (`for update of l`, verified) and posts compensations the remainder math already accounts for. All spend paths serialize; no double-spend vector found.

## 8. Final Disposition Matrix
| Finding | Severity | Category | Production Risk | Financial Risk | Decision | Reason |
|---|---|---|---|---|---|---|
| LOW-1 replay-before-lock | LOW | UX/robustness | loser gets explicit error; retry succeeds | none (proven §4) | C | safe serialization; graceful-replay is polish |
| LOW-2 dup-cancel return | LOW | UX/robustness | error instead of existing id | none (guard + uniq index) | C | no double reversal possible |
| LOW-3 custom key reuse | LOW | caller contract | wrong-id response on key misuse | none (UNIQUE; writes nothing) | C | default keys safe; document at wiring |
| LOW-4 order_id index | LOW | performance | marginal latency at scale | none | C | correctness unaffected; batch later |
| LOW-5 unwired cancel | LOW* | sequencing | D3-AUTO unenforced until wired | none (dormant code) | C | gates production USE, not migration apply |

## 9. Required Fixes
None required (no A/B findings). Optional pre-apply polish specs (NOT implemented here): (a) F1 — file `0020_order_discount.sql`, `apply_order_discount`, after 0020:113 re-SELECT `bonus_ledger` by `v_key` and `RETURN v_existing` if found; effect: graceful replay; regression risk: negligible (read-only re-check). (b) F2 — `cancel_order_discount`, at 0020:368-373 return the existing reversal id instead of raising; effect: idempotent cancel responses; risk: negligible. (c) F6 — index spec in §6; effect: lookup latency; risk: negligible (additive). (d) F3 — one wiring-doc line on key uniqueness; F7 — app wiring stage must land before production use.

## 10. Deferred Findings
LOW-1, LOW-2, LOW-3, LOW-4 deferred as safe polish/documentation; LOW-5 deferred to the app-wiring stage with an explicit production-use gate (do not operate discounts in production before the cancel path is wired and exercised). All deferred items are recorded with exact locations above and require no redesign.

## 11. Final Gate
No finding meets the MUST-FIX bar (no financial-duplication or incorrect-balance vector under any traced race). 0020 proceeds to final pre-application review at the owner's discretion.

PHASE 17.2 STATUS:
NO MUST-FIX FINDINGS — 0020 CAN PROCEED TO FINAL PRE-APPLICATION REVIEW
NO LIVE DATABASE CHANGES
