# PHASE 38 — CUSTOMER CANCELLATION INTEGRATION DESIGN (read-only)

## A. Current Customer Order Flow
`orders_tab` (list via `OrderController.loadClientOrders`) → `order/:id` detail (`_load()` → `fetchOrderDetails`, retry + `onDiscountChanged: _load` reload hook EXISTS as reuse pattern) → pending-only `OrderDiscountSection` (funds display, apply/remove via `BonusWalletController`, applied-state detected from own ledger rows by `orderId` match). No cancel action, no timeline, no invoice, no notifications linkage anywhere client-side (verified by keyword + method inventory).

## B. Current Cancellation Capability
Client: none (zero cancel calls/methods/UI). Branch: RPC-routed since Phase 37. Discount-removal (`removeOrderDiscount` → 0020 RPC) exists but is NOT order cancellation (order stays open) — must not be confused in design. Server 0021 admits owner-client pending cancels today, uncalled.

## C. PHASE 37 Reusable Contract
REUSABLE as-is: RPC signature + reason-required + fail-closed + idempotent semantics; controller busy-guard + retained per-(order,reason) key + error-state + reload pattern; dialog state machine (validate → submit → spinner → inline error → pop-on-success); error-mapping via existing mapper; no-direct-write rule enforced by construction. Branch-only elements (branch-scoped auth, manager sheets) stay branch-side.

## D. Customer Cancellation Contract
Admitted caller: owner-client, own order, `pending` only (server gate concurs; UI pre-gates on status but never enforces). Reason: required by RPC; free-text field (BD-2 undecided — no taxonomy). Failure modes surface server strings (non-pending, foreign order, MANUAL-snapshot abort, auth). Idempotent retries converge. No policy invented.

## E. Cancellation History Read Model
Table live with owner-SELECT RLS; no service/controller/UI exists → all three NOT IMPLEMENTED (design only). Contract: `fetchOrderCancellationHistory(orderId)` (service: RLS SELECT newest-first) → model mirroring columns → controller list state → detail/history display. Ordering: `cancelled_at` desc (1:N-ready though live flow yields ≤1).

## F. Order Details Integration
Pending block gains: Cancel entry (sheet → reason → confirm → RPC → reloads) + cancellation-status display when cancelled (status chip exists; add reason/time/actor-role/reversal-presence from history + ledger rows). No invented fields; all displayable data exists or is readable post-§E.

## G. Timeline Integration
TECHNICAL GAP — TIMELINE MODEL NOT PRESENT (zero matches repo-wide). Minimum viable: derived nodes (created/scheduled/current) + `CANCELLED` node from `order_cancellations.cancelled_at` when present. No invented timestamps; full history needs backend timestamps that do not exist (deferred, not designed here beyond the gap statement).

## H. Notification Integration
TECHNICAL GAP: service is read/mark-read only; model has no order linkage; no emission points. Cancel flow must NOT depend on notifications (ordering: RPC → reloads → optional notify later). Emission design deferred to a notification phase; not a cancel blocker.

## I. Invoice Boundary
Cancel needs no invoice handling (orthogonal, H2-A). Manual path untouched; no linkage assumed. Invoice display remains BUSINESS POLICY + RLS-gated future work. No migration.

## J. Bonus / Free-Y Boundary
Cancel path touches ledger-sourced discount/reversal rows only (server-side). UI reuses the existing applied-detection (`txnType/orderId` match); `bonus_rule_id`/free-line logic untouched. No mixing by construction.

## K. Idempotency
Mirror Phase 37 exactly (REUSABLE): per-(order,reason) retained key in controller; busy guard blocks double-tap; rebuild-safe (key in controller, not widget); server `CANCEL:`/`REVERSAL:` keys + UNIQUE + state convergence backstop. No new mechanism (code proves sufficiency).

## L. Security Boundary
Customer UI → controller → service → RPC ONLY. No direct `orders` UPDATE (client RLS denies anyway), no history INSERT (zero write policies), no ledger mutation (no seam exists). Verified absent today; design preserves absence. Discount-removal stays a separate scoped action, never a cancel substitute.

## M. Error Contract
RPC failure → service rethrow (logged) → controller error state → inline dialog/sheet message (dialog stays open; existing pattern). Cases: not-allowed (stale pending), already-cancelled (info + reload), MANUAL-abort (escalate message, untouched order), auth (login flow), timeout (same-key retry), unknown (verbatim server string, never "success" before resolve).

## N. State Refresh Contract
On success: reload order detail (`_load` hook exists) + orders list (`loadClientOrders` exists) + wallet (`loadWallet` exists — reversal restores funds). Notifications reload NOT assumed (no linkage). Follow existing reload-after-action behavior; no speculative refreshes.

## O. Test Plan (design only, unexecuted)
Allowed-state cancel calls RPC once with (orderId, reason, key); rejected-state never calls; double-submit single RPC; failure shows error + keeps sheet; success triggers the three reloads; empty history renders empty; one event renders fields incl. optional reason/note absence; ordering newest-first; no direct-update/insert/mutation paths exist to abuse (structural assertions + grep review).

## P. Implementation Boundary
IMPLEMENT (Phase 39): service cancel method (REUSABLE shape from branch service), controller action + history read state, detail cancel entry + sheet, history display block, l10n keys, tests. EXISTING (reuse): RPC, RLS, reload hooks, error mapper, idempotency pattern, discount display. TECHNICAL GAP: timeline source, notification emission, invoice reads. BUSINESS POLICY: BD-2 values, receipt scope, edit semantics.

## Q. Technical Gaps
History read stack (service/controller/UI); cancel entry + reason sheet; timeline source model; notification order-linkage + emission; invoice reads + linkage ruling; BD-2 taxonomy values. None block each other except: cancel UI needs BD-2 shape decision (structure ready regardless).

## R. Business Decisions Required
BD-2 (values only); H-approvals carried; receipt/payment/edit scopes carried. Cancel wiring itself needs no new decision (all contracts locked).

## S. PHASE 39 Readiness Matrix
| Capability | Status |
|---|---|
| Cancel action + sheet | READY FOR IMPLEMENTATION (all contracts + patterns exist) |
| History reads/display | READY FOR IMPLEMENTATION (RLS live, seams proven) |
| Timeline derived nodes | READY FOR IMPLEMENTATION |
| Timeline history source | TECHNICAL GAP (deferred) |
| Notifications/invoice | TECHNICAL GAP / BUSINESS POLICY (deferred) |
| Idempotency/security/errors | REUSABLE as specified |

PHASE 38 COMPLETE — CUSTOMER CANCELLATION INTEGRATION DESIGN
READ-ONLY DESIGN
NO FILES MODIFIED EXCEPT REPORT
NO DATABASE CHANGES
NO SQL WRITE
NO MIGRATION CREATED
NO COMMIT
NO PUSH
BD-2 NOT DECIDED
PHASE 39 NOT IMPLEMENTED
