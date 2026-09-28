# PHASE 16.2 — ORDER DISCOUNT FINAL DECISIONS (decisions only, no code/SQL/DB changes)

## Architectural fact (locked)
Order Discount = separate future RPC applied BEFORE `branch_allocate_order` (invoice snapshots order total at allocation, `0016:145-148`). `branch_allocate_order` untouched. `0017/0018/0019` untouched.

## createInvoice bypass analysis
- Location: `branch_service.dart:508` (`createInvoice`), called via `branch_controller.dart:216` from `branch_invoice_create_sheet.dart:55`.
- Production path (branch manager creates standalone invoices by entering amount manually).
- YES, it can bypass any order-level discount: it writes `invoices` directly with a hand-entered amount, disconnected from orders.
- Not legacy/dead. Future requirement: either gate it against discounted orders or reconcile invoice vs order-discount records. No fix applied now.

## TECHNICALLY RESOLVED (locked, no decision needed)
1. Standalone discount RPC (not inside allocate). 2. Apply-before-allocate ordering. 3-5. No changes to 0017/0018/0019. 6. Idempotency key `DISCOUNT:{order_id}`. 7. Original item prices immutable. 8. Discount visible/auditable via `bonus_ledger`. 9. No GL bridge in this phase. 10. No Free-Y mixing.

## D1 — Zero Order
Q: May discount cover 100% (total = 0)?
- Allow: zero-amount invoices/receivables appear; delivery/audit unaffected structurally.
- Prevent: needs a positive-minimum rule.
- Current constraints affecting it: none found blocking zero (no CHECK located on invoice amount).
- **USER DECISION REQUIRED.**

## D2 — Funding Scope
Q: Any positive lot (A) or MONETARY-only (B)?
- A: works with existing allocation as-is.
- B: requires rule-type tracing per lot (derivable via EARN→rule_id links, extra join, no new column strictly needed).
- **USER DECISION REQUIRED.**

## D3 — Cancellation
Q: Auto compensating reversal (A) or block + admin settlement (B)?
- Pre-allocation cancel: reversal is trivially safe either way.
- Post-allocation/delivery cancel: A needs reversal RPC path; B needs an order-status guard.
- **USER DECISION REQUIRED.**

## D4 — Accounting Treatment
Q: Liability settlement (A) or revenue reduction (B)?
- Must-preserve data regardless: discount amount, order link, ledger link, timestamps, actor.
- GL accounts/bridge deferred to post-decision phase.
- **USER DECISION REQUIRED (+ accountant).**

## Decision table
| Decision | Option A | Option B | What changes technically |
|---|---|---|---|
| D1 | Allow zero | Positive minimum | A: validation+docs; B: new minimum setting+check |
| D2 | Any positive lot | MONETARY-only | B adds rule-type derivation |
| D3 | Auto reversal | Block + admin | A: reversal path; B: status guard |
| D4 | Liability settlement | Revenue reduction | Future accounts + bridge design |

## USER DECISION REQUIRED
Implementation is stopped until D1–D4 are approved. No migration, RPC, code, SQL, or DB change was made in this phase.
