# PHASE 19 — POST-0020 INTEGRATION AUDIT (read-only — no changes of any kind)

## 0. Scope and method
Repo-wide search for every 0020 touchpoint (`apply_order_discount`, `cancel_order_discount`, `ORDER_DISCOUNT`, `DISCOUNT:`, `allow_discount`, `discount.*`), plus lifecycle traces (creation → allocation → invoice → delivery → cancellation) in current local files. Result: backend RPCs exist live and verified (PHASE 18) but have zero callers; display labels exist; no service/controller/route/button/auto-trigger references them. Classification: Backend Ready / UI Missing, with invoice-bypass and unwired-cancel as recorded follow-ups.

## A. Order creation
Client: `checkout_screen.dart:50-63` → `OrderController.submitOrder` (`order_controller.dart:138-150`) → `OrderService.createOrder` (`order_service.dart:146-168`) → RPC `create_order_with_items` (0017). Order inserted `pending` (0017:218); total server-computed from paid lines only. Checkout touches bonus solely via Free-Y governorate sync (`checkout_screen.dart:31-42` → `CartController.setBonusGovernorate`) — no discount toggle, amount input, or preview. Discount window (pending, pre-allocate) exists structurally but is unreachable from any UI.

## B. Discount application wiring
Repo-wide grep for `apply_order_discount|cancel_order_discount`: matches ONLY in `0020_order_discount.sql` (definition + grants) and in docs/opencode reports. Zero matches in `medlink_app/lib` and `Medlik-Waap/.../src`. Answers: (1) no UI calls it; (2) `BonusWalletService` methods are funds/ledger/redemption/withdrawal/cancels only (`bonus_wallet_service.dart:149-309`) — no discount method; no controller/repository exists; (3) no route/button/action; (4) client cannot apply it today; (5) director cannot apply it (RPC is client-only by lock); (6) no automatic trigger; (7) proven by the repo-wide search above plus the service method inventory. Display-only references exist and are correctly read-only: `bonus_wallet_screen.dart:17` + `bonus_history_screen.dart:28` (Flutter labels), `BonusLedgerPage.tsx:12` + `BonusFinancialDashboardPage.tsx:29` + `bonusFinancialApi.ts:12` (web labels/type). Web `BonusSettingsPage.tsx:10` mentions `discount` solely as a redemption-methods hint key — no discount policy UI.

## C. Order lifecycle position
Verified chain: `create_order_with_items` (pending) → [DISCOUNT WINDOW: no caller] → `allocateOrder` (`branch_service.dart:464-471` → RPC `branch_allocate_order`, pending→assigned + invoice snapshot) → delivery/cancel via direct status updates. Discount-before-allocate ordering holds structurally; nothing in the live path contradicts it, and nothing invokes it.

## D. Invoice paths (all paths, current local state)
Path 1 — allocation invoice: `branch_service.allocateOrder` (branch_service.dart:464-471) → `branch_allocate_order` RPC → `invoices` row snapshotting the order total (0016:145-148). Source: `orders.total_amount`; 0020 never writes that column, so no new inconsistency is introduced — but a future discount likewise will NOT be reflected in the invoice without follow-up work. Path 2 — manual invoice (bypass CONFIRMED still present): `branch_invoice_create_sheet.dart:48-66` reads a hand-typed amount (`_amountCtrl`) → `BranchController.createInvoice` → `branch_service.createInvoice` (branch_service.dart:508-527) → direct `invoices` insert with manual `amount`, no order link, no total read, no discount awareness. It can bypass any order discount by construction; the discount ledger does not affect it. Classification: FOLLOW-UP AFTER 0020 (retained from 16.5/16.7/17.x) — not a blocker to the migration itself, blocking to end-to-end discount correctness.

## E. Cancellation paths
Client has no cancel path (`order_service.dart`/`order_controller.dart`: zero cancel matches). Branch cancel: `branch_order_actions.dart:159` → `branch_service.updateOrderStatus` (branch_service.dart:122-130) → direct `orders` status update to `cancelled`, no RPC, no bonus contact. Consequences: (a) `cancel_order_discount` has no automatic caller — D3-AUTO cannot fire today; (b) if a discount is ever applied, a later status-cancel leaves the POSTED ORDER_DISCOUNT stranded with no compensating reversal (documented risk, fix is wiring not schema); (c) transfer resets status to pending (branch_service.dart:132-137), which would re-open the discount window on a transferred order — noted for the wiring phase. No lifecycle point currently invokes the cancel RPC.

## F. Financial integrity (app-side)
Verified by search: no app code writes `order_items.unit_price` for discounts (prices server-set at creation); no client-side balance computation for spending (all spends are RPCs reading server funds); no mixing of `bonus_rule_id` (Free-Y) with the financial path (checkout uses it only for free-line submission per 0017 rules); no GL objects in app or DB (PHASE 18 live scan: 0); no tenant/company structures anywhere. Integrity posture intact.

## G. Idempotency
`DISCOUNT:{order_id}` is generated inside the RPC default (0020:70-71); no app layer generates, passes, or stores it — there is no client capability to supply a custom key today. Retry safety therefore rests entirely on the DB UNIQUE constraint plus the in-RPC replay check (verified sound in 17.1/17.2). No app-driven duplicate-request vector exists because no app path reaches the RPC at all; when wiring lands, callers must use unique keys per order (custom-key reuse analyzed in 17.2/F3).

## H. Permissions
RPC-enforced: apply is client-only (0020:94-96) with ownership + pending gates; cancel is owner-or-director with client ownership check (0020:334-349); no `user_id` parameter exists — identity comes solely from `auth.uid()`, so no caller-controllable identity field is present. App exposure: neither operation is exposed to ANY role today (no callers), so no over-exposed surface exists. Future wiring must keep director apply excluded (locked) and route director cancel through admin review surfaces.

## I. Readiness classification
Descriptive classification per area: Backend RPCs — Ready (live-verified). Client API layer (service/controller) — Missing. Client UI (checkout toggle/preview/confirm, history display exists) — Missing. Director policy UI — Missing (settings page covers redemption/withdrawal only). Cancel wiring — Missing (no trigger point; manual status updates bypass). Invoice reconciliation — Missing, bypass present (follow-up track). Overall: Backend Ready / UI Missing. Not Partially Integrated (zero integration points exist) and not Blocked (no technical impediment found; remaining work is wiring + decisions already locked except D4/GL).

## J. Integration matrix
| Area | Current implementation | Evidence | Status | Missing piece | Risk |
|---|---|---|---|---|---|
| Order creation | RPC-only, pending, server total | order_service.dart:146-168; 0017:218 | Integrated (pre-existing) | nothing | none |
| Apply Discount | RPC live, zero callers | repo-wide grep: no app match | Backend Ready / UI Missing | service + checkout UI | dormant code, no user path |
| Invoice (allocate) | snapshots order total | branch_service.dart:464-471; 0016:145-148 | Unchanged, unaware of discount | reconciliation | future discount invisible on invoice |
| Invoice (manual) | direct insert, hand amount | branch_service.dart:508-527; sheet:48-66 | Bypass present | gate/reconcile | can ignore any discount |
| Allocation | branch RPC, untouched | branch_service.dart:460-480 | Unchanged | nothing (by design) | none |
| Cancellation | direct status update | branch_order_actions.dart:159; branch_service.dart:122-130 | Unwired | auto cancel_order_discount call | stranded POSTED discount once used |
| Idempotency | DB-enforced only | 0020:70-71,105-107 | Sound, app-absent | caller key discipline at wiring | none today |
| Security | in-RPC auth, RLS deny | 0020:93-125,333-354; PHASE 18 §6 | Enforced, unexposed | none | none |
| Client UI | wallet/history labels only | bonus_wallet_screen.dart:17; checkout: no toggle | Labels ready, flow missing | checkout integration | none (read-only labels) |
| Director UI | labels + redemption settings only | BonusLedgerPage.tsx:12; BonusSettingsPage.tsx:10 | Labels ready, policy UI missing | discount policy section | none |

## K. Next-phase candidates (not selected)
1. Client checkout discount integration — prereq: none (backend ready). Files: `bonus_wallet_service.dart` (+2 methods), `bonus_wallet_controller.dart`, `checkout_screen.dart`, `order_detail_screen.dart`. No backend change, no business decision, no live DB change.
2. Cancel-path wiring — prereq: decision on trigger point (status-update hook vs explicit action). Files: `branch_service.dart`/`branch_order_actions.dart` + RPC call. No backend change; no live DB change; D3 already locked AUTO.
3. Invoice reconciliation/remediation — prereq: owner ruling on manual-invoice scope. Files: `branch_invoice_create_sheet.dart`, `branch_service.createInvoice`, possibly allocate read path. Backend change possible; live DB change only if Link column/index chosen (F6).
4. Director discount controls — prereq: none (keys exist). Files: web Bonus settings/rules pages + `bonusFinancialApi.ts`. No backend/live-DB change.
5. Earn interplay confirmation — prereq: none. 0019 verified independent; only re-confirmation after first live discount + delivery cycle. No code change.

## L. Discrepancies / transport log
No data discrepancies found between reports and current local files (invoice bypass re-confirmed in present code, not assumed from old reports). Execution log: the `write` tool failed repeatedly with transport ECONNRESET on large payloads (5+ attempts across this session); the report was therefore composed via shell heredoc in 5 appended parts — content identical to plan, method fallback documented here per the phase's transparency rule. No timeouts/auth errors on reads this phase (no live queries were needed; PHASE 18 already established live state).

PHASE 19 STATUS:
POST-0020 INTEGRATION AUDIT COMPLETE
NO CODE CHANGES
NO SQL CHANGES
NO DATABASE CHANGES
NO MIGRATION CHANGES
