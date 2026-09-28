# PHASE 39 — CUSTOMER CANCELLATION & HISTORY INTEGRATION

## A. Scope
Implemented: customer cancel entry + reason sheet on order detail (pending only), cancellation-history read stack (service → controller → UI block), 10 tests. Reused: live `cancel_order_with_discount` RPC (exact signature from `0021_order_cancellation_with_discount.sql`, not the differently-named file cited in the task — discrepancy documented), retained-key idempotency + busy-guard patterns (Phase 37/21), reload hooks, error mapper, design system. Untouched: migrations, RLS, RPCs, web, checkout/discount/Free-Y flows.

## B. Files Modified
- `lib/models/order_cancellation.dart` (new): read-only row model mirroring ledger-entry style; no write methods.
- `lib/services/order_service.dart`: +`cancelOrder` (RPC seam) + `fetchOrderCancellationHistory` (RLS SELECT, newest-first).
- `lib/services/order_controller.dart`: +`cancelOrder` (busy guard, retained per-(order,reason) key, error, reloads orders + history), +`discardPendingCancellation`, +`loadCancellationHistory`.
- `lib/screens/client/order_cancel_section.dart` (new): pending-gated cancel button + `_CancelSheet` (reason field, validation, spinner, inline error) + history block (reason/date/reversal marker, empty-aware).
- `lib/screens/client/order_detail_screen.dart` (+3 lines): import + section insert after discount block.
- `lib/l10n/app_{en,ar}.arb` (+5 keys each, surgical append) + regenerated localizations.
- `test/order_cancellation_test.dart` (new, 10 tests).

## C. Cancellation Flow
`OrderCancelSection` (pending only) → sheet (reason) → `OrderController.cancelOrder` → `OrderService.cancelOrder` → RPC `cancel_order_with_discount` → (server: lock, authorize, gate, detect, reverse-or-abort, flip, history, audits) → controller reloads orders + history → detail `_load` via `onChanged` → wallet refresh on next wallet read. Matches §38 design verbatim.

## D. History Flow
`order_cancellations` → `fetchOrderCancellationHistory` (RLS SELECT) → `OrderController.cancellationHistory` → section block (reason/date/reversal marker; empty → no block). No model mutation, no write path.

## E. Reused Components
RPC + key families + UNIQUE/state convergence (server); busy-guard/retained-key/error/reload controller shape (Phase 37 branch + Phase 21 wallet patterns); `mapAuthErrorToMessage`; ClientCard/SectionTitle/IconBadge; `BonusWalletService.newIdempotencyKey` import (no duplicated generator); detail `_load`/`onChanged` reload hook.

## F. Security Verification
No direct `orders` UPDATE (client RLS denies anyway; grep-clean); no history INSERT/UPDATE/DELETE anywhere in app (grep-clean; RLS has zero write policies); no ledger contact (grep-clean); no user_id params (auth.uid server-side); no new permissions/roles; Free-Y path untouched (sole `bonus_rule_id` hit is pre-existing creation code).

## G. Idempotency Verification
Per-(order,reason) retained key, cleared on success; busy guard blocks double-tap (tested); reason edit mints fresh; server `CANCEL:`/`REVERSAL:` keys + UNIQUE + state convergence backstop. Retry/timeout/concurrent converge with zero duplicate money (server-proven in 24.1; client never invents keys per request).

## H. BD-2
BD-2 NOT DECIDED. Free-text reason only; `reason_code`/`note` untouched (NULL by server default); no taxonomy, CHECK, enum, or labels invented.

## I. Technical Gaps (code-proven only)
Timeline source model; notification order-linkage + emission; invoice reads + linkage ruling (H2); payment (no model); edit-linkage semantics; BD-2 values. None block the built flow.

## J. Tests
Before: 29 (22 existing + 7 branch-cancel). After: 39, all green. New: 5 controller (invoke/params/key, refresh+history load, busy guard, error+key-retain, history filtering) + 5 widget (pending entry, non-pending shrink, history render, single-RPC confirm, empty-reason validation). `flutter analyze`: 4 pre-existing infos, zero new (one introduced lint fixed during the phase). No web changes (no typecheck needed). Incidents: one server restart mid-phase (artifacts verified intact after); one workdir typo (no-op, corrected); no test failures at completion.

## K. Files NOT Modified
Migrations (0017–0022 byte-identical; `git diff --stat -- supabase/` empty for this phase), database (no SQL executed), RPC definitions, RLS, grants, invoice schema, web, checkout/discount/Free-Y flows.

## L. Final Status
Discrepancy handled: task cited `0021_order_cancellation_integration.sql`; actual file is `0021_order_cancellation_with_discount.sql` — integration targets the real signature. No conflicting evidence found between §§38/37, code, migrations, or tests.

PHASE 39 COMPLETE — CUSTOMER CANCELLATION & HISTORY INTEGRATION
BD-2 NOT DECIDED
NO DATABASE CHANGES
NO MIGRATION CREATED
NO SQL WRITE
NO COMMIT
NO PUSH
