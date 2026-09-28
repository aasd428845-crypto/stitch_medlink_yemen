# PHASE 16.1 — ORDER DISCOUNT DECISION IMPACT (analysis only, no code/SQL/DB changes)

## 1. Scope
Impact analysis of 7 discount decisions against verified repo contracts (0016/0017/0018/0019 files, Flutter order/invoice services, no live writes).

## 2. Files inspected
`0016_bonus_inventory_allocation_safety.sql` (branch_allocate_order + invoice issue), `0009_branch_manager_operations.sql` (original), `0017` (order creation), `0018` (ledger types, allocate_spend, idempotency, settings), `0019` (earn engine), `branch_service.dart` (allocate + standalone createInvoice), order status CHECK (`0002:132-133`).

## 3. Current architecture
Order created → branch_allocate_order issues invoice from order total at allocation time (`0016:145-148`); standalone invoices also exist (`branch_service:508`). Order statuses: pending/assigned/in_progress/delivered/cancelled. No discount concept anywhere.

## 4. Decision 1 impact — zero-total orders
- A (allow): needs explicit zero-acceptance; invoice amount 0 rows appear; receivable 0; delivery/audit unaffected structurally. Technical change: allow + document.
- B (positive minimum): needs a minimum rule (setting or CHECK);انقطاع? — simply reject below threshold.
- Current code: no zero-guard found on invoice amount → A requires no schema change, only policy + validation.

## 5. Decision 2 impact — funding rule types
- A (any positive lot): works with existing `bonus_allocate_spend` + lot linkage as-is.
- B (MONETARY only): requires filtering lots by originating rule type → needs rule-type trace on lots (currently lots link to EARN rows, rule traceable via EARN's rule_id — feasible, extra join).
- No new field strictly required for A; B needs documented derivation, not necessarily new columns.

## 6. Decision 3 impact — cancellation
- A (auto reversal): reuses REVERSAL pattern + existing `reverses_id` linkage; safe under current constraints.
- B (block + admin settlement): needs order-status guard before cancel (new check in cancel path, future code).
- Post-fulfillment cancellation: unsettled — requires decision, no mechanism exists.

## 7. Decision 4 accounting impact
- Settlement model: Dr Bonus Liability / Cr Receivable — needs liability account (missing) + bridge.
- Revenue-reduction model: Dr Revenue|Discount / Cr Receivable — needs discount account (missing) + bridge.
- Either way: bridge + accounts are future builds; current ledger suffices for trace (order_id link exists on ledger rows).

## 8. Decision 5 impact — minimums
- Eligibility minimums (min_order/min_quantity on rules_v2) exist and are evaluated at earn, not at spend. A spend-time minimum is a new setting (settings table supports new keys without schema change).
- Maximum: cap = min(requested, total, available) — no new field needed.

## 9. Decision 6 impact — one-shot design
Single `DISCOUNT:{order_id}` key enforces one discount per order (verified pattern from earn idempotency). Top-up later would need key versioning — document as excluded by design.

## 10. Decision 7 impact — priority
No priority/reservation concept among spend methods today (first-come via row locks). Any priority = new policy + enforcement code. None assumed.

## 11. branch_allocate_order integration analysis
1. Discount must apply BEFORE allocate/invoice (invoice snapshots order total at line 145-148).
2. Invoice issued from order total at allocation → discount must already be reflected or invoice diverges.
3. Standalone `createInvoice` path bypasses any order-level discount → must be handled or restricted.
4. Discount as separate RPC (not inside allocate): avoids mixing inventory allocation with financial logic — recommended.
5. Merging into allocate risks coupling stock logic to bonus finance — documented against.

## 12. Dependencies
0017 (order totals), 0018 (ledger/allocations/idempotency/settings), 0019 (earn lots), invoice flow (branch_allocate + standalone).

## 13. Data integrity risks
Zero-total invoices polluting receivables aging; uncapped discount bypassing available (prevented by min() cap); double-apply via retry (prevented by idempotency key); allocation without lot linkage (prevented by reusing allocate_spend).

## 14. Idempotency risks
Single key per order is safe; concurrent double-submit serialized by order row lock (required in new RPC); key must include order scope only.

## 15. Accounting risks
Discount without GL bridge leaves subledger-only truth (acceptable interim, must be labeled); revenue vs liability choice changes future bridge, not current tables.

## 16. Implementation prerequisites
Decisions 1–4 locked; liability/discount accounts defined (future); no 0017/0018 changes needed.

## 17. BUSINESS DECISIONS REQUIRED
| ID | Decision | Option A | Option B | Technical consequence |
|---|---|---|---|---|
| D1 | Zero-total allowed? | Allow zero | Positive minimum | A: validation + docs; B: new setting + check |
| D2 | Funding rule scope | Any positive lot | MONETARY-only (rule-type trace) | B needs derivation logic |
| D3 | Post-discount cancel | Auto reversal | Block + admin settle | A reuses REVERSAL; B needs guard |
| D4 | Accounting nature | Liability settlement | Revenue reduction | Determines accounts + bridge |

Extra options only where found (monthly caps mirror withdrawal policy if desired — noted, not added).

## 18. NO CODE / NO SQL / NO DB CHANGES
This report performed zero modifications. No migration created. No Supabase writes executed.
