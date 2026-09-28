# PHASE 37 — BRANCH CANCELLATION INTEGRATION

## A. Pre-Implementation State
`showRejectOrderConfirm` (`branch_order_actions.dart:132-160`) collected a boolean and called `branch.updateOrderStatus(order.id, 'cancelled')` → direct `orders` UPDATE (`branch_service.dart:122-130`). Bypassed: RPC authorization/state gates, discount detection, compensating reversal, `order_cancellations` insert, dual audit, idempotency keys, MANUAL fail-closed handling. A second caller (`branch_order_detail_screen.dart:77`) shares the same controller method for all statuses. RPC `cancel_order_with_discount(uuid,text,text)` verified live-specified in local 0021 (:64-68); reason is REQUIRED (non-empty enforced server-side).

## B. Files Changed
- `services/branch_service.dart`: +`cancelOrderWithDiscount` (RPC seam mirroring file conventions); `updateOrderStatus` gains debug assert banning `'cancelled'` (fails fast in dev if the old path is ever reused for cancels; zero release behavior change).
- `services/branch_controller.dart`: +`cancelOrderWithDiscount` (busy guard, retained per-(order,reason) idempotency key reusing the established `newIdempotencyKey`, error state, `loadOrders` refresh) + `discardPendingCancellation`.
- `screens/branch_manager/branch_order_actions.dart`: reject dialog rebuilt as `_RejectOrderDialog` (reason field, validation, busy/error states, single-submit) calling the controller RPC path; direct-cancel call REMOVED.
- `lib/l10n/app_{en,ar}.arb` (+2 keys each, surgical append) + regenerated `app_localizations*.dart`.
- `test/branch_cancellation_test.dart` (new, 7 tests).
Untouched: 0021/0022/migrations, RLS/grants, web, checkout/discount flows, Free-Y, `updateOrderStatus` for non-cancel statuses.

## C. New Runtime Flow
`_RejectOrderDialog` → `BranchController.cancelOrderWithDiscount` → `BranchService.cancelOrderWithDiscount` → RPC `cancel_order_with_discount` → (server: lock, authorize, gate, detect, reverse-or-abort, flip, history, audits) → controller reload → dialog pops. No direct orders write on this path anymore.

## D. RPC Contract
`cancel_order_with_discount(p_order_id uuid, p_reason text, p_idempotency_key text default null) returns uuid` (reversal id or NULL), SECURITY DEFINER, branch_manager admitted for own-branch orders, reason mandatory. Used verbatim; no invented signature.

## E. Reason Handling
Free-text field (required, validated client-side for UX; enforced server-side). `reason_code`/`note` untouched (NULL by server default). No taxonomy, no CHECK, no enum — BD-2 explicitly undecided and unblocked (values flow through `p_reason` whatever taxonomy later decides).

## F. Security Boundary
Direct cancel write eliminated from UI (assert-guarded in debug). RLS/grants untouched; RPC is the sole boundary; no client writes to orders/history/ledger added; director/client powers unchanged.

## G. Idempotency
Controller-retained per-(order,reason) key (established pattern) + server `CANCEL:`/`REVERSAL:` keys + UNIQUE + state convergence. Double-tap proven single-RPC; retry reuses key; reason edit mints fresh.

## H. Error Handling
RPC exception → controller `_cancelError` → inline dialog error (dialog stays open) + existing logging. Server fail-closed strings surface verbatim; no new error system (SnackBar/mapper patterns reused where they exist).

## I. Tests
7/7 pass (offline fakes, zero network): RPC-with-params + no-direct-write + refresh; key-reuse/fresh-key; single-RPC-on-concurrency; dialog confirm-once; empty-reason validation; double-tap single-RPC; failure-keeps-dialog-open. Full suite 29/29 green. `flutter analyze`: 4 pre-existing infos only.

## J. Verification
analyze 4 infos (pre-existing, untouched files); full tests 29/29; no web changes (no typecheck needed); no SQL executed; no migration touched. Incidents: (1) widget tests initially failed from a REAL lifecycle bug found by the suite (controller disposed during dialog teardown) — fixed by extracting `_RejectOrderDialog` StatefulWidget; (2) subsequent silent no-op traced to the test harness placing the provider BELOW MaterialApp (dialog routes can't see it) — fixed by mirroring main.dart (provider above app); production was never affected. One workdir typo + several transient tool timeouts, all retried clean.

## K. Remaining Gaps
BD-2 (taxonomy values — structure ready); Phase B (client cancel entry, history reads/UI, timeline); notifications (read-only service exists — TECHNICAL GAP for emission); invoice linkage (out of scope, H2); F6-style history index already live; no new gaps introduced.

## L. Findings Classification
- RPC-routed branch cancel: IMPLEMENTED. Direct-write cancel path: removed (IMPLEMENTED), guarded by debug assert.
- Reason taxonomy values: BUSINESS POLICY (BD-2 open; free text flows today).
- History reads/UI, client cancel entry, timeline: TECHNICAL GAP (Phase B; backend live and ready).
- Invoice linkage, notifications emission, payment: TECHNICAL GAP (out of scope, tracked in prior phases).
- Prior financial/security architecture: EXISTING (untouched, re-verified by green suite + analyze).

## M. Acceptance
Branch Manager no longer uses direct cancel writes (proven by Test 2 + removed call site); cancellations flow through the live financial RPC; history uses live `order_cancellations`; no migration; no DB writes by agent; no new permissions; Free-Y untouched; BD-2 undecided; existing suite unbroken (29/29); all files/changes/errors documented above.

PHASE 37 COMPLETE — BRANCH CANCELLATION INTEGRATION
NO DATABASE CHANGES
NO MIGRATION CREATED
NO SQL WRITE
NO COMMIT
NO PUSH
BD-2 NOT DECIDED
PHASE B NOT IMPLEMENTED
