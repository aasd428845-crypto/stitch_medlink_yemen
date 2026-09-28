# PHASE 17.1 — MIGRATION 0020 DEEP REVIEW (review only — nothing modified)

## 1. Executive Summary
0020 reviewed line-by-line against working-tree 0017/0018/0019 and contracts 16.4/16.5/16.7. The custom allocator faithfully reproduces 0018 semantics plus the contracted narrow-only filter; ledger/reversal/idempotency/concurrency paths are safe with constraint-level backstops (`bonus_ledger_reverses_uniq`, UNIQUE idempotency_key). No CRITICAL or HIGH findings. Five LOWs + four INFOs, all with exact lines and fixes. Two positive discoveries strengthen the verdict: the partial unique reversal index covers 0020's REVERSAL rows, and every competing spend path serializes on the same account lock. Recommendation: PASS WITH FINDINGS — safe for final human review; fixes optional before apply.

## 2. Migration Inventory
`supabase/migrations/0020_order_discount.sql` (413 lines): §1 settings seeds (43-50); `apply_order_discount(uuid,numeric,text)` (56-305); `cancel_order_discount(uuid,text,text)` (311-406); grants (412-413). No tables/columns/indexes/RLS/policy changes. Name/signature match 16.4 §7 literally.

## 3. Line-by-Line Findings
- 43-50: six seed keys exactly matching 16.5 contract names; `on conflict do nothing` preserves configured values. Product defaults (false/ALL/AUTO/null×3) match 16.7 locks. PASS.
- 70-71, 326-327: key derivation `DISCOUNT:{order}` / `REVERSAL:DISCOUNT:{order}`, overridable, blank-safe. PASS (see F3 for caller-key caveat).
- 93-101, 333-340: auth/role/input guards before any I/O. PASS.
- 105-107, 342-344: replay check pre-lock — safe but non-graceful under race. F1.
- 112-125, 346-354: order lock + ownership + `pending`-only + positive total. `pending` verified as sole pre-allocation state (0017:218 inserts pending; 0016:53 requires pending). Cancelled/assigned/delivered rejected by apply; cancel rejects only delivered. PASS.
- 129-135: single-discount guard. PASS.
- 138-202: six policy reads, each type-validated, unknown shapes raise, absent → product default. Matches 16.5 key-for-key. PASS.
- 206-207: funds via `bonus_account_funds` (server-side + account lock). PASS.
- 210-227: `effective=min(requested,total,available,policy caps)`; D1 `>=total` reject; floor check. Server-authoritative. PASS.
- 231-244: snapshot v1 with all contracted fields; accounting null-marker, no invented value. PASS.
- 247-252: PENDING ORDER_DISCOUNT debit, existing CHECK type, rule_id null (multi-lot; lots via allocations). PASS.
- 261-285: inline allocator (see §4). PASS with F-noise none.
- 289-295: POSTED flip rowcount-guarded; trigger-compatible (old row PENDING). PASS.
- 297-302, 399-403: audit rows, UPPER_SNAKE style (`DISCOUNT_APPLY` new-in-style; `REVERSAL` exact reuse with kind marker). PASS.
- 356-365: latest-POSTED-debit lookup; single-discount invariant makes it deterministic. PASS.
- 368-373: one-effective-reversal guard + 0018:171 partial unique index backstop. PASS.
- 377-387: snapshot parse with re-raise; non-AUTO snapshot → manual-settlement raise. PASS.
- 391-397: full-amount compensating credit; original untouched. PASS.
- 412-413: grants mirror 0018 convention exactly. PASS (see F5).

## 4. Custom Lot Allocation Review
Compared against `bonus_allocate_spend` (0018:475-546) + `bonus_credit_remaining` (0018:437-473) + `bonus_earn_allocations` (0018:357-368):
- A eligibility: only POSTED positive same-account lots; narrow-only filter can only exclude (rule-less credits eligible under ALL — documented design choice). No ineligible-lot path. PASS.
- B ownership: `l.account_id = v_caller` on every lot; debit/allocations same account. PASS.
- C relationship: allocations reference existing credit ids; helper locks each credit row. PASS.
- D remaining: identical helper, remainder-capped takes, shortfall raises. PASS.
- E negatives: `v_rem<=0 → continue`; takes are `least(positive,positive)`; CHECK(amount>0) backstops. PASS.
- F zero: zero remainder skipped; zero take impossible (loop exits at v_left<=0). PASS.
- G consumed lots: remainder 0 → skipped. PASS.
- H partial: `least(rem,left)` takes the tail correctly. PASS.
- I multi-lot: loop continues until covered; single debit, N allocation rows. PASS.
- J shortfall: raise → full-transaction rollback (nothing partial survives: debit, allocations, audit all uncommitted). PASS.

## 5. Ledger Review
Chain Earn → lot → ORDER_DISCOUNT debit → allocations → REVERSAL(reverses_id) → new re-spendable credit is fully traceable with no side ledger. Reversal does NOT delete allocation rows (matches `reverse_bonus_txn` semantics): consumed lots stay attributed, the compensation is a fresh credit — no double restoration, no negative lot, no broken trace. 0019 earn evaluator reads order_items only (0019:320-360), so discount/reversal rows cannot perturb earn computation; reversal-after-delivery is blocked, consistent with earn-at-delivery.

## 6. Allocation Review
Covered in §4 A-J: all PASS. UNIQUE(debit,credit) + shortfall raise + helper row locks reproduce 0018 guarantees.

## 7. Idempotency Review
Keys created at 70-71/326-327; uniqueness from existing UNIQUE(idempotency_key). Retry-after-commit → same id returned. Timeout-then-retry → blocks on order lock, then replays or proceeds correctly. Rollback-then-retry → clean re-execution (no row written). Same order from two devices → serialized, one wins, loser gets explicit already-discounted error (F1). Cancellation/reversal double-execution → second raises (exists-check) or hits `bonus_ledger_reverses_uniq` (F2). No path creates a second transaction for the same logical request.

## 8. Concurrency Review
Locks: order `FOR UPDATE` (112,346), account row via funds() (206), credit rows via helper (274), debit row (362). Matrix: discount×discount → serialized, single winner (no double-spend; LOW UX note F1). Discount×redemption/withdrawal → all funnel through `bonus_account_funds` account lock (verified: redemption path + withdrawal 0018:1089) → serialized, loser sees post-commit funds (no negative balance). Discount×cancel → serialized on order lock; ordering determines raise-vs-proceed, both safe. No lost updates (inserts only + guarded flip). No duplicate allocation (UNIQUE). No duplicate reversal (guard + partial unique index). No CRITICAL/HIGH/MEDIUM; two LOWs (F1, F2).

## 9. Reversal Review
Compensating REVERSAL only — no UPDATE/DELETE of POSTED rows (trigger would block anyway). `reverses_id` set; full debit compensation (`-amount` of negative debit = positive credit); audit with reason; idempotent key; snapshot-gated mode. Lot accounting verified in §5. PASS.

## 10. Policy Review
Six keys = 16.5 set exactly, no extras. D1 enforced post-cap server-side. D2 ALL ≠ unrestricted (balance/expiry/suspension/rule-gate/allocation all still apply). NARROW_ONLY proven: filter conjunction can only remove lots; Global MONETARY × rule allow-PRODUCT ⇒ excluded (268-270) — no widening path exists. D3 AUTO default with snapshot override honored. D4: zero GL/accounting content. Precedence implemented as Order caps > Rule filter > Global > defaults.

## 11. Security Review
Definer + fixed search_path on both functions; EXECUTE to authenticated with in-function authorization (apply: client-only, ownership; cancel: owner-or-director + ownership for clients). Authenticated caller on another's order → rejected at 115-117/349-351. Director cannot apply (locked: no override). Direct ledger/allocation/settings writes unchanged (no grants/RLS touched). No privilege escalation found. F4/F5 are convention-parity observations, not gaps.

## 12. Transaction Atomicity
Single implicit transaction per RPC: validation → locks → policy → funds → debit → allocations → flip → audit → return. Failure anywhere before return rolls back everything (verified: no autonomous transactions, no EXCEPTION swallow — the one EXCEPTION block re-raises). Ledger-without-allocation, allocation-without-ledger, and audit-without-commit states are all impossible.

## 13. Free-Y Isolation
`order_items`, `unit_price`, `is_bonus`, `bonus_rule_id` appear only in a header comment (line 21, documentation of non-contact). Zero reads/writes. Financial path uses ledger + allocations + rules_v2 exclusively. PASS.

## 14. Invoice Boundary
`branch_allocate_order`, `createInvoice`, invoice sheet untouched (no references outside comments). 0020 changes neither `orders.total_amount` nor allocate behavior, so no new invoice contradiction is introduced. Classification: FOLLOW-UP AFTER 0020 (retained) — not a blocker. No app wiring calls the new RPCs yet either (§15/F7).

## 15. Tenant Gap
No tenant objects fabricated (verified: no company/tenant/GL identifiers in code lines). Global keys implement product defaults; per-tenant configuration remains a future extension. Non-blocking for this migration.

## 16. 20 Scenario Matrix
| # | Scenario | Expected | Actual (code inspection) | Verdict |
|---|---|---|---|---|
| 1 | Discount < balance | applied in full | min() → requested; allocated, POSTED | PASS |
| 2 | Discount ≈ total (below) | applied, positive remainder | allowed when effective < total | PASS |
| 3 | Discount would zero order | rejected (D1) | raise at 222-224 | PASS |
| 4 | Requested > available | capped to available | min() then floor/D1 gates | PASS |
| 5 | Requested > total | capped to total | min(); D1 may then reject full-cover | PASS |
| 6 | Multiple lots | split across oldest-first | loop 261-281 | PASS |
| 7 | Partial lot | tail consumed | least(rem,left) | PASS |
| 8 | Fully consumed lot | skipped | rem<=0 continue | PASS |
| 9 | No eligible lot | full rollback + error | shortfall raise 283-285 | PASS |
| 10 | Duplicate request | same id returned | replay check 105-107 | PASS |
| 11 | Concurrent duplicate | one wins, no double | serialized; loser raises (F1) | PASS* |
| 12 | Discount then cancel | compensating reversal | cancel path, snapshot AUTO | PASS |
| 13 | Duplicate cancel | single reversal | guard + uniq index (F2) | PASS* |
| 14 | Discount+redemption race | serialized, loser sees fresh funds | shared account lock | PASS |
| 15 | Discount+withdrawal race | same as 14 | funds() lock verified | PASS |
| 16 | Foreign order | rejected | ownership checks | PASS |
| 17 | Non-pending order | rejected | status gates both RPCs | PASS |
| 18 | Policy changed after discount | old tx unaffected | snapshot captured at write | PASS |
| 19 | Reversal after policy change | snapshot mode governs | parse-and-enforce 377-387 | PASS |
| 20 | Failure mid-allocation | nothing persisted | atomic rollback | PASS |
*PASS with LOW UX note (error instead of graceful replay).

## 17. Findings by Severity
- F1 LOW — Replay check precedes locks (0020:105-107; same class 342-344): concurrent first-time duplicates serialize then the loser raises instead of replaying. Safe; fix: re-check idempotency_key after acquiring the order lock and return existing.
- F2 LOW — Concurrent duplicate cancel raises 'already has an effective reversal' (0020:368-373) instead of returning the existing reversal id; constraint backstop verified (0018:171-173). Fix: select-and-return existing reversal.
- F3 LOW — Caller-supplied custom key reused across different orders would replay the wrong order's id. Same exposure as 0018 precedent; fix: document caller key-uniqueness contract at wiring time.
- F4 INFO — Null-role comparison edge matches 0018 convention; unreachable for real authenticated callers (users row required).
- F5 INFO — No REVOKE FROM PUBLIC; identical to 0018 convention; authorization is in-function.
- F6 LOW — No index on `bonus_ledger(order_id)`: apply exists-check (129-132) and cancel lookup (356-365) scan without index support (existing indexes: account_time, account_status). Fix: follow-up index migration (kept out of 0020 to preserve its additive-minimal scope).
- F7 INFO — Cancel path unwired: no trigger/caller invokes `cancel_order_discount` on order cancellation yet (no cancel RPC exists in migrations at all). Expected per staged plan (app wiring is a later stage); must precede production use.
- F8 INFO — `v_reserved` (0020:76,206) read but unused; harmless (available already nets reservations).
- F9 INFO — Snapshot in `notes` TEXT requires JSON parsing by future readers; accepted build decision, documented.

## 18. Blockers
None. No CRITICAL/HIGH financial, concurrency, or security issue found. F6/F7 are pre-production follow-ups, not apply-blockers for a reviewed staging apply.

## 19. Required Fixes
None required before final human review. Recommended (any order, all small): F1 re-check-after-lock; F2 return-existing-reversal; F6 order_id index (separate or amended migration); F3 key-contract note in wiring docs; F7 app wiring of cancel path before production use. F4/F5/F8/F9 need no action.

## 20. Final Recommendation
The custom allocator is sound and the surrounding guards (snapshot gating, narrow-only filter, atomicity, dual backstops on reversal) meet the locked contracts. Cleared for final human review and subsequent staging-apply decision by the owner.

PHASE 17.1 STATUS:
PASS WITH FINDINGS — 5 LOWs + 4 INFOs, no blocker; custom allocator verified equivalent to 0018 semantics plus contracted filter
NO LIVE DATABASE CHANGES
NO MIGRATION APPLIED
