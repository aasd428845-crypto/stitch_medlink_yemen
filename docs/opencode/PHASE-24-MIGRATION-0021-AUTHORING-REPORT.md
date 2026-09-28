# PHASE 24 — MIGRATION 0021 AUTHORING REPORT (local only, never executed)

## 1. Migration path
`supabase/migrations/0021_order_cancellation_with_discount.sql` — verified next number (tail: 0017/0018/0019/0020), exact required name, no prior 0021 (collision grep empty).

## 2. Line count
356 lines.

## 3. SHA-256
`801dec62188322fb60aa47871ee45c2ad447cad376c226a710a9fe669af9d414` (post-correction hash; any later byte change invalidates this report's review).

## 4. Object inventory
F1 NEW `cancel_order_with_discount`; F2 OR REPLACE `branch_allocate_order` (identical signature/security/grant + delimited delta); I1 partial index `bonus_ledger_order_idx(order_id) WHERE order_id IS NOT NULL`. No tables/columns/triggers/RLS/roles. F6 included with proof: no existing index covers `order_id` (0018 has account_time, account_status, reverses_uniq only); serves F1 detection + 0020 lookups.

## 5. Function signatures
`cancel_order_with_discount(p_order_id uuid, p_reason text, p_idempotency_key text default null) returns uuid` (NULL when no discount existed). `branch_allocate_order(uuid,boolean,date,jsonb) returns uuid` — unchanged. Name-collision scan clean; owner/security/search_path follow 0018/0020 convention (definer + fixed path).

## 6. Grants
EXECUTE on F1 to `authenticated`; F2 grant restated identical. No PUBLIC grant (checker substring hit on "into public" investigated — false alarm, only INSERT targets). No revokes.

## 7. Security model
auth.uid first; role gate client/branch_manager/director; H1 owner+pending (client), branch-match with null-branch reject (manager), open (director); delivered rejected for all; no user_id params; RLS untouched; SELECT-only ledger posture unchanged.

## 8. Transaction/locking model
Single implicit txn: order `FOR UPDATE` → (optional) debit `FOR UPDATE` → reversal → status flip (rowcount-guarded) → audits. Lock order matches 0020 (order→debit; no account lock needed — no allocation performed). Concurrent cancels serialize on the order row; loser converges via state.

## 9. Reversal/idempotency model
0020 guard block duplicated inline (justified: 0020 immutable + its role gate rejects branch_manager): snapshot parse with immediate re-raise, AUTOMATIC-only else H3 abort, one-effective check + `bonus_ledger_reverses_uniq` backstop, full-amount POSTED REVERSAL with `reverses_id` + `REVERSAL:DISCOUNT:{order}` key, 0020-style audit. Status key `CANCEL:{order}` stored on the status audit reference; replay converges via state (existing reversal id or NULL), never a second posting. No `bonus_reversals` table; no POSTED UPDATE/DELETE anywhere (verified).

## 10. Compatibility 0017–0020
0020 logic reused unmodified (file untouched); F2 body proven equal to 0016 except the delimited delta (programmatic diff: all non-whitespace diff lines inside the marked block; two indent bytes corrected to match). Delta nets POSTED debits minus linked REVERSAL credits (removed discounts net zero — required for the remove-then-allocate flow), aborts on negative/over-total, coalesce-neutral otherwise. Manual invoices untouched; no `order_id` invented; Free-Y strings occur only inside the reproduced 0016 body (verified line-by-line present in 0016).

## 11. Static checks
17/17 PASS (post-correction; one checker false alarm on "to public" substring + one on `is_bonus`-in-reproduction, both investigated and cleared). Dollar balance, 2 functions, definer×2, search_path×2, grant coverage, no create/alter/drop/delete, no ledger UPDATE, no tenant/GL/invoice-ALTER, WHEN OTHERS re-raises immediately.

## 12. Test matrix (static/theoretical; no live execution)
Pending+no-discount → cancelled+NULL+audit. Pending+discount → cancelled+one REVERSAL+dual audit. Retry → existing result, zero new rows. Pre-reversed → converge, no second REVERSAL. Non-pending client → reject, zero writes. Foreign order → reject. Unauthenticated → reject. Concurrent pair → one outcome. MANUAL/missing snapshot → abort pre-write, status unchanged, `cancel_rejected` audit. Manual-invoice order → orthogonal success. Free-Y order → unaffected. POSTED rows immutable by construction + trigger.

## 13. Git diff/status
Intended new files: 0021 migration + this report. 0017/0019/0020 untouched; 0018's +45 diff predates Phase 17 (not mine). No app files touched this phase. (Note: 0019 shows untracked — pre-existing repo state, not mine.)

## 14-16. Timeouts / failed commands / corrections
No timeouts, no faileditool calls, no live contact. Corrections during authoring (all pre-report, none hidden): (a) F2 loop-indent bytes normalized to 0016-exact (3sp/5sp) after programmatic diff flagged 2 lines; (b) blank-separator line confirmed as delta-owned; (c) `no_public_grant`/`no_freey_touch` checker hits investigated — both false alarms with evidence above. Discrepancy: none vs spec (H1 pending gate with already-cancelled converge exception — specified in 23 §2 step 6 and implemented).

## 17. Re-read confirmation
Migration re-read in full after corrections (fidelity diff re-run clean); report re-read at completion. All §20 gates hold.

PHASE 24 COMPLETE
MIGRATION 0021 AUTHORED LOCALLY
STATIC VERIFICATION COMPLETE
NO LIVE SQL EXECUTED
NO DATABASE CHANGES
NO APPLICATION CODE CHANGES
