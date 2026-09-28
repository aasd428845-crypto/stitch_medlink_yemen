# PHASE 40 — POST-CANCELLATION STATE AUDIT (read-only)

## A. Executive Summary
Cancellation is now RPC-routed on every known path: branch dialog (Phase 37) and customer detail section (Phase 39) both call `cancel_order_with_discount`; the old direct-cancel call site is gone, and the remaining `updateOrderStatus` caller only advances forward (pending→assigned→in_progress→delivered). History table is live but has zero app readers outside the new customer section. Bonus subledger is complete with no GL bridge (no financial_* objects exist anywhere). Tests 28/28 in scope, analyze clean of new issues. Open: BD-2 values, invoice linkage, payment, timeline source, notification emission.

## B. Phase 37–39 Verification
Phase 37: branch dialog → controller (busy guard, retained key) → service RPC → reload; direct call removed; debug assert bans 'cancelled' via old path. Phase 39: `OrderService.cancelOrder` + `fetchOrderCancellationHistory`, `OrderController.cancelOrder` + history state, `OrderCancelSection` (pending gate + sheet + history block), 5 l10n keys, 10 tests. Both re-read in current tree; implementation matches reports.

## C. Customer Cancellation State
UI entry (pending detail only) → reason sheet (free text, validated) → controller → RPC → reloads (order, list, wallet, history). Server owns identity/state/money/idempotency. Status: implemented, tested, unapplied-backend-independent (RPC live).

## D. Branch Cancellation State
`showRejectOrderConfirm` → `_RejectOrderDialog` → controller RPC path. Old direct-write call eliminated (grep: no `updateOrderStatus(*, 'cancelled')` remains). NO BYPASS FOUND: exhaustive search for direct orders-cancellation writes, history inserts/updates, and duplicate cancel services returns only status-chip labels, invoice filters, and the forward-only detail updater.

## E. Cancellation History State
Backend (table + RLS + RPC insert) live, 0 rows. App: customer read stack only (service/controller/UI block); branch has no history read; no reporting. WRITE = RPC ONLY, READ = new application layer — as designed.

## F. Bonus Order Discount State
0020 live; client apply/remove UI live; reversal automatic inside cancel RPC; idempotency (keys + UNIQUE + state convergence) live; lot consumption oldest-first (untouched mechanics). Application-integrated (detail section) + branch-visible via ledger labels. No direct ledger writes anywhere (grep-clean).

## G. Invoice Boundary
No `invoices.order_id` or equivalent exists (migration + code search empty); `createInvoice` remains manual/standalone; no invoice repository linking orders; no receipt/invoice UI client-side. TECHNICAL GAP — INVOICE ORDER LINKAGE confirmed, untouched per H2-A.

## H. Bonus Subledger vs General Ledger
Subledger (accounts/ledger/redemptions/withdrawals/allocations/rules_v2): live, complete, app-integrated. Accounting/GL (financial_accounts/journal/posting engine): zero objects in migrations and app code — NOT INTEGRATED by design (D4 open). No journal source/reference to Bonus exists.

## I. Bonus Financial Operations Matrix
| Operation | Bonus Subledger | Application | General Ledger | Source Trace | Status |
|---|---|---|---|---|---|
| BONUS EARN | EXISTS (trigger) | EXISTS (wallet/history) | MISSING | ledger rows | PARTIAL (no GL) |
| BONUS ORDER DISCOUNT | EXISTS (0020) | EXISTS (detail UI) | MISSING | ORDER_DISCOUNT rows | PARTIAL (no GL) |
| BONUS PRODUCT REDEMPTION | EXISTS | EXISTS (redeem UI) | MISSING | redemption + ledger links | PARTIAL (no GL) |
| BONUS CASH WITHDRAWAL | EXISTS | EXISTS (withdraw UI) | MISSING | withdrawal + ledger links | PARTIAL (no GL) |
| BONUS REVERSAL | EXISTS (0020/0021) | EXISTS (triggered via cancel) | MISSING | reverses_id chain | PARTIAL (no GL) |
| BONUS EXPIRATION | EXISTS (engine) | EXISTS (labels/alerts) | MISSING | expiration rows | PARTIAL (no GL) |

## J. Source Traceability Matrix
| Source | ID | Next Layer | Link Exists? | Evidence | Status |
|---|---|---|---|---|---|
| order cancel | order id | history row | YES (FK, live, 0 rows) | 0022 schema + RLS | EXISTS (unused) |
| history row | reversal_ledger_id | ledger REVERSAL | YES (FK, code path) | 0022/RPC text | EXISTS (untested live) |
| REVERSAL | reverses_id | ORDER_DISCOUNT debit | YES | 0020/0021 logic | EXISTS |
| ledger event | — | journal entry | NO (no GL objects) | zero financial_* matches | MISSING |
| order | — | invoice | NO (no order_id) | migration/code search empty | TECHNICAL GAP |

## K. Order → Bonus → Invoice → GL Map
ORDER —CONNECTED→ BONUS EARN —CONNECTED→ BONUS LEDGER —CONNECTED→ ORDER DISCOUNT / REDEMPTION / WITHDRAWAL —NOT CONNECTED→ INVOICE (no linkage; manual path bypasses) —NOT CONNECTED→ GENERAL LEDGER (nonexistent; POLICY REQUIRED: D4 + treatment decisions).

## L. Business Policies Still Required
BD-2 taxonomy values (cancel UX finalization only); H-approvals (carried); D4 + GL direction + timing + liability/expense + revenue/discount treatment (all BUSINESS POLICY REQUIRED, untouched); invoice linkage scope; payment model; edit-linkage semantics; notification scope. Closed: D1/D2/D3/D5/D6/D8, H-locks, BD-1 shape, cancel mechanics.

## M. Technical Gaps (code-proven)
History reads for branch/director roles; order timeline source; notification order-linkage + emission; invoice reads + linkage; payment model + records; status-history trail; staging environment for live-flow tests. No RLS/read gaps for built paths; no test gaps for built code.

## N. Not Implemented
GL bridge/posting; invoice linkage; payment; timeline backend; notification emission; edit flow; receipt viewer; BD-2-driven taxonomy UI; director cancel/history surfaces.

## O. Regression Verification
Targeted suites (order_cancellation 10, branch_cancellation 7, order_discount 11): 28/28 pass, zero failures, no retries needed. `flutter analyze`: 4 pre-existing infos in untouched files, zero new. No web changes (no typecheck required). Nothing repaired — nothing broke.

## P. Final Readiness Matrix
| Area | Current State | Blocker | Ready? | Evidence |
|---|---|---|---|---|
| Cancellation (customer+branch) | RPC-routed, tested | none | READY | §§C–D, 28/28 tests |
| History (write) | RPC-only, live | none | READY | 0 rows by design |
| History (read) | customer only | none | PARTIAL | §E |
| Discount | live + UI | none | READY | §F |
| Timeline | derived only | source model | PARTIAL | no timestamps |
| Invoice | branch-only, unlinked | H2 + RLS ruling | BLOCKED | §G |
| Accounting/GL | design only | D4 + owner | BLOCKED | §H |
| Notifications/support | generic | linkage | PARTIAL | existing screens |

PHASE 40 COMPLETE — POST-CANCELLATION STATE AUDIT
READ-ONLY AUDIT
NO FILES MODIFIED EXCEPT REPORT
NO DATABASE CHANGES
NO SQL WRITE
NO MIGRATION CREATED
NO COMMIT
NO PUSH
BD-2 NOT DECIDED
