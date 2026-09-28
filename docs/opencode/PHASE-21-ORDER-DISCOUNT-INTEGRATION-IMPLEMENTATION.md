# PHASE 21 — ORDER DISCOUNT INTEGRATION IMPLEMENTATION

## A. Files changed
- `medlink_app/lib/services/bonus_wallet_service.dart` (+2 RPC methods)
- `medlink_app/lib/services/bonus_wallet_controller.dart` (+sig helper, +2 actions, +key fields)
- `medlink_app/lib/screens/client/order_detail_screen.dart` (+11: import, callback plumbing, pending-gated section)
- `medlink_app/lib/l10n/app_en.arb` / `app_ar.arb` (+8 `orderDiscount*` keys each; see §P for the recovery note)
- `medlink_app/lib/l10n/app_localizations*.dart` (regenerated via `flutter gen-l10n`)

## B. Files added
- `medlink_app/lib/screens/client/order_discount_section.dart` (260 lines: funds display, amount input, apply/remove, applied-state, error+retry, pending gate)
- `medlink_app/test/order_discount_test.dart` (11 tests: sig purity, submit/remove, key-reuse, fresh-key-on-change, double-submit guard, 3 widget tests)

## C. Exact functions/methods changed
Service: `requestOrderDiscount({orderId,amount,idempotencyKey})`, `cancelOrderDiscount({orderId,reason?,idempotencyKey?})` — mirror `requestRedemption` pattern (auth guard, rpc, log/rethrow; no policy logic). Controller: `discountOperationSig()`, `submitOrderDiscount()`, `discardPendingDiscount()`, `removeOrderDiscount()` — mirror submit/withdrawal key-retention pattern. UI: `_OrderContent` gains `onDiscountChanged` → parent `_load`.

## D. Client flow
Order detail (pending only) → section shows server funds + amount field → Apply (double-submit guarded) → RPC decides → success reloads order + wallet/history; applied state shows server-recorded amount + display payable (total + negative ledger amount, verbatim values); Remove calls reversal RPC. No auto-discount; checkout untouched; `create_order_with_items` untouched.

## E. RPC integration
`apply_order_discount(p_order_id,p_amount,p_idempotency_key?)` and `cancel_order_discount(p_order_id,p_reason?,p_idempotency_key?)` called via existing Service→RPC seam. Client sends request only; sends no user_id (auth.uid server-side); director apply impossible (server role gate).

## F. Idempotency implementation
Controller mints `newIdempotencyKey()` per (order,amount) signature (established app pattern, consistent with 17.2/F3: key unique per order), retains across retries, clears on success; server default `DISCOUNT:{order_id}`/replay/UNIQUE remain the backstops. Verified by tests: retry-same-key, fresh-key-on-change, single-RPC-on-double-submit.

## G. Cancellation integration
NOT WIRED — documented gap (no safe wiring exists): the sole cancel actor (branch manager, `branch_order_actions.dart:159`) is rejected by the RPC role gate (client/director only, 0020:334); client has no cancel path; director has no cancel UI (web `OrdersMonitoringPage` has none). Wiring the branch action would fail server-side on every call. Requires backend permission decision (new migration — forbidden this phase) or a director cancel flow. Stranded-discount risk stands exactly as recorded in PHASE 19.

## H. Invoice integration
NOT CHANGED — documented gap: allocate-path invoice is written by backend RPC (unreadable/unwritable from app); manual path is a direct insert the app cannot reconcile without an order link + ledger read (branch RLS blocks ledger reads). Safe app-side part: none exists; any app computation would be fake enforcement. Requires backend read-path change (designed in PHASE 20 §D). Manual billing left fully functional.

## I. Free-Y isolation verification
New code references no `order_items` columns; grep confirms zero `bonus_rule_id`/ledger-insert contact in new/changed files. Free-Y submission path untouched.

## J. Financial integrity verification
No client-side balance math (funds displayed verbatim; payable display clearly marked non-authoritative); no direct ledger/allocation writes (grep: only RPC names + comments); no hard-coded policy values (no D1/D2/limits literals); no fake RPCs/endpoints/columns; no Tenant/GL/accounting content; no price/total mutation.

## K. Tests executed
`flutter test test/order_discount_test.dart` (11 new) + full `flutter test` (22 total). Offline fakes subclassing the real service (no network; SupabaseClient constructed with `FlutterAuthClientOptions(autoRefreshToken:false)` to avoid timers).

## L. Test results
22/22 pass. The 20-scenario blueprint maps: 1-10,16-17 covered by unit/widget tests against fakes (server-truth scenarios documented as stubbed at the service seam); 11-13 partially (client remove path; order-cancel trigger unwired — §G); 14-15,18-20 require live/staging execution (no prod writes per gate) — recorded, not executed.

## M. Build/typecheck results
`flutter analyze`: 4 infos, all pre-existing deprecations in untouched files (invoice sheet, order actions, addresses screen); zero issues in new/changed files. Web untouched → no pnpm run (nothing changed under Medlik-Waap).

## N. Remaining gaps
1. Cancel wiring blocked on RPC role gate (needs backend decision). 2. Invoice reconciliation needs backend read-path change. 3. No staging env for live-flow scenarios (14-15,18-20). 4. Director web: labels only (out of scope per §11).

## O. Known limitations
Applied-state detection reads recent ledger entries (limit 20/100); payable display is informational. Retry button reuses last amount. Branch/director roles gain no new capabilities.

## P. Failed commands / timeouts / retries / corrections
1. `write`-tool ECONNRESET on large payloads (known session issue): l10n edits applied via python, widget/tests via heredoc — same content, method fallback.
2. SELF-INFLICTED DATA LOSS + RECOVERY: `git checkout --` on arb files wiped 51 uncommitted bonus keys from prior phases. Recovered byte-identical values from the generated `app_localizations_*.dart` files (which were generated from the lost arb); re-inserted surgically (additive diff: +120/−2 across both arbs). Lost irrecoverably: `@description` metadata only (regeneration unaffected; getters show "No description provided"). Verified: all 355+8 getters covered, `flutter gen-l10n` clean, full suite green.
3. Widget-test failures, fixed: (a) notify-during-build → post-frame load; (b) pending-timer teardown → `FlutterAuthClientOptions(autoRefreshToken:false)`; (c) stream error from `raw.dispose()` → disposal removed; (d) `use_super_parameters` info → super parameter.
4. One 600s `flutter test` timeout during the broken-teardown iteration; subsequent targeted runs fast and green.
5. Migrations 0017/0018/0019/0020 untouched (0018's +45 diff predates Phase 17); no migration created; no live DB contact.

PHASE 21 STATUS:
IMPLEMENTATION COMPLETE WITH DOCUMENTED GAP

APPLICATION CODE CHANGES: YES
DATABASE CHANGES: NO
MIGRATION CHANGES: NO
LIVE DATABASE WRITE: NO
