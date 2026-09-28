# PHASE 27 — CUSTOMER ORDER CENTER IMPLEMENTATION PLAN (plan only, no code)

## 1. Executive Summary
Build the Center by extending `orders_tab` (filters + slots) and `order_detail` (timeline-derived, cancel post-0021, invoice/support/notification blocks as backends land), reusing existing controllers, routes, and design system. Hard facts constraining the plan: `parentOrderId` exists in schema AND model but is referenced nowhere else; cancel reason exists nowhere; payment exists nowhere; notifications carry `related_offer_id` (precedent) but no `related_order_id`; no code writes `order_items` post-creation anywhere. Edit = cancel+recreate; reorder/buy-again stay as-is.

## 2. Current Order Architecture
Shell tabs → cart → checkout → success → orders list → detail; branch allocates/bills; statuses via direct writes; discount section (pending, Phase 21); wallet/history labels; generic notifications/support. Controllers: `OrderController` (orders/cart/addresses), `BonusWalletController` (funds/ledger/submits), `CartController`, branch/driver controllers separate. Routes nested under `/client` + shared `/notifications`.

## 3. Order Center Components
| Component | Actual File | Current Responsibility | Keep | Modify | New |
|---|---|---|---|---|---|
| OrdersTab | screens/client/orders_tab.dart | unfiltered list + nav | Yes | add filters/slots | — |
| OrderContent/detail | screens/client/order_detail_screen.dart | full detail | Yes | add blocks | — |
| DiscountSection | screens/client/order_discount_section.dart | pending discount | Yes | list-marker reuse | — |
| Success | order_success_screen.dart | confirmation | Yes | — | — |
| Checkout/cart | checkout/cart_screen.dart | creation | Yes | — | — |
| Tracking | inline DriverLocationMap | in_progress map | Yes | timeline block | — |
| Rating/reorder | detail sections | delivered actions | Yes | — | — |
| Services | order/bonus_wallet_service.dart | RPC seam | Yes | +cancel-order, +reads | — |
| Controllers | order/bonus_wallet_controller.dart | state | Yes | +actions | — |
| Routes | routing/app_router.dart | nesting | Yes | only if receipt route | — |
| Models | models/order.dart (+parentOrderId) | shapes | Yes | — | — |
| l10n | lib/l10n/*.arb | strings | Yes | +keys per phase | — |

## 4. Order List Plan
Extend `orders_tab.dart`: status filter tabs (All/Pending/Assigned/On-the-way/Delivered/Cancelled — client-side over `OrderController.orders`, zero backend); per-row discount marker (join own ledger ORDER_DISCOUNT rows — app-only); per-row slot for future cancel entry; pull-refresh retained.
| Requirement | Existing File | Existing Logic | Change Required | Backend Required | Translation Required |
|---|---|---|---|---|---|
| Filters | orders_tab.dart | none | tab bar + filter | No | Yes (status labels exist via chip) |
| Counts | — | none | computed from list | No | No |
| Discount marker | order_discount_section logic | ledger read exists | reuse join | No | No |
| Cancel entry | — | none | post-0021 button | 0021 applied | Yes |
| Navigation | InkWell push | exists | unchanged | No | No |

## 5. Order Details Plan
EXISTS: header/chip, address, schedule, map, items+Free-Y, notes, totals, reorder, rating, discount section. IMPLEMENTATION REQUIRED (app-only): timeline block (derived), cancel entry + reason sheet (post-0021), discount marker for non-pending states. BACKEND REQUIRED: cancel execution, invoice reads, history source, cancel-reason store. FUTURE: receipt viewer, payment block.

## 6. Timeline Plan
Build from `created_at` + `scheduled_delivery_at` + current status ONLY. Provable events: Created, Scheduled (if set), Current-state. Unprovable: every transition time, canceller identity/time, delivery time. Status history needs backend (table or audit-derived — decision deferred, not selected here).
| Event | Source | Timestamp? | Now? | Backend? |
|---|---|---|---|---|
| Created | orders.created_at | Yes | Yes | No |
| Scheduled | orders.scheduled_delivery_at | Yes/null | Yes | No |
| Assigned/dispatch/delivered/cancelled times | none | No | No | Yes (history source) |

## 7. Cancellation Plan
Caller file: `branch_service.dart` (+`cancelOrderWithDiscount` RPC method; branch cancel action swaps direct update → RPC) + future client detail entry calling the same RPC via `BonusWalletService` (+method) / controller (+action). Button visible: pending orders only (client); branch per current action. Forbidden states: assigned+ for client (server gate concurs), delivered for all. Reason: RPC REQUIRES `p_reason` — collect via sheet (new l10n) or fixed default string (decision at build). Validation: non-empty reason. Loading: existing busy/error patterns. Retry: idempotency keys retained per controller pattern (server `CANCEL:`/`REVERSAL:` backstops). Success: reload order + list + wallet. Error: fail-closed strings. No new RPC; 0021 unmodified.

## 8. Cancellation Reason
TECHNICAL GAP (zero matches for cancel_reason/cancellation_reason/reason in models, UI, and migrations). Future needs a store; options without selection: column on orders vs separate table vs audit-reference JSON (note: audit `reference` already carries the idempotency key; reason field carries the text on success paths — aborts cannot persist rows). Decision deferred to backend phase.

## 9. Edit Order Plan (Cancel + Reorder, never patch)
Flow: detail (delivered or eligible state) → Reorder refills cart via existing `_reorder` (payable items, CURRENT prices via `fetchCurrentProducts`, stock rechecked at next checkout, Free-Y/discount re-evaluated fresh at new creation) → new checkout → new order. Files: existing detail/cart/catalog/service — NO new backend for the basic flow. Cancel-first variant (changing a pending order): cancel via §7 then reorder; units never edited in place. Old prices never reused (creation RPC re-prices server-side — verified pattern).

## 10. parent_order_id
Schema: EXISTS (0002:130). Model: EXISTS (`parentOrderId`, order.dart:16). Query/support: NONE (zero references elsewhere — verified). Migration needed: NO (column exists). Future uses: cancel-recreate linkage, reorder provenance, amendment chains — all require backend + business-policy decisions first. Not a gap in storage; a gap in semantics.

## 11. Reorder vs Buy Again
| Action | Current Implementation | Purpose | Keep | Modify | Duplicate Risk |
|---|---|---|---|---|---|
| Reorder | detail `_reorder` → cart refill (payable only) | rebuild an order's purchasables | Yes | add entry points | None — cart-mediated, fresh pricing |
| Buy Again | home shelf ← `fetchRecentReorderProducts` | quick pick of past products | Yes | unchanged | None — different granularity |
Functional difference: order-scoped rebuild vs product-scoped picking; both funnel through cart → creation RPC (prices/stock/Free-Y/discount always re-evaluated). No cloning, no stale prices by construction.

## 12. Invoice / Receipt
Invoice UI: NONE. Invoice APIs: branch reads only. Client access: NONE (RLS). order→invoice relation: NONE (no column). Manual path: branch-only direct inserts. Receipt inside Center needs: linkage ruling (H2) + client read policy + payload shape — EXISTS: none; TECHNICAL GAP: reads + linkage; FUTURE: viewer/share/PDF.

## 13. Order Discount
`apply_order_discount` lives in 0020 (live) called from `BonusWalletService.requestOrderDiscount` (Phase 21) surfaced in `OrderDiscountSection` (pending detail only). Verified semantics to preserve: pending-only, server idempotency, server funds, D1 gate, reversal-on-cancel (post-0021), order reload after success. No backend change in this track.

## 14. Bonus Display
Financial Bonus (ledger rows, server amounts, history labels) vs Legacy Free-Y (item badges, zero price) — separate sources, separate widgets, verified unmixed. Displayed total stays gross server total; discount shown as its own row; no new computations.

## 15. Notifications
Generic only: `NotificationModel` has title/body/targets/`related_offer_id`/reads — NO `related_order_id` (verified absent), no order emission points. TECHNICAL GAP: order linkage + event emission. Precedent to follow: the `related_offer_id` pattern for a future `related_order_id`.

## 16. Support
Generic chat/help screens exist with zero order args. TECHNICAL GAP: order context passing + agent-side lookup (+ optional category/ticket ruling). No new system proposed.

## 17. Payment
NOT IMPLEMENTED (zero payment entities/status/methods/transactions/providers in models, services, and migration tables — verified). Future integration point: independent payment-status block in Financial Summary fed by future payment records; never derived from order status. No payment design attempted here.

## 18. Order Status Actions Matrix (server enforces; UI only exposes)
| Status | View | Track | Cancel | Edit | Reorder | Buy Again | Discount | Invoice | Support |
|---|---|---|---|---|---|---|---|---|---|
| pending | EXISTS | NOT_APPLICABLE | BACKEND_REQUIRED (0021) | NOT_ALLOWED | FUTURE | EXISTS | EXISTS | FUTURE | EXISTS |
| assigned | EXISTS | NOT_APPLICABLE | NOT_ALLOWED client | NOT_ALLOWED | FUTURE | EXISTS | NOT_ALLOWED | FUTURE | EXISTS |
| in_progress | EXISTS | EXISTS (map) | NOT_ALLOWED | NOT_ALLOWED | FUTURE | EXISTS | NOT_ALLOWED | FUTURE | EXISTS |
| delivered | EXISTS | NOT_APPLICABLE | NOT_ALLOWED | NOT_ALLOWED | EXISTS | EXISTS | NOT_ALLOWED | FUTURE | EXISTS |
| cancelled | EXISTS | NOT_APPLICABLE | NOT_ALLOWED | NOT_ALLOWED | EXISTS | EXISTS | NOT_ALLOWED | FUTURE | EXISTS |

## 19. Screen Architecture (no duplicates)
`OrdersTab` (extend: tabs + slots) → rows push `order/:id` → `OrderDetailScreen` gains Timeline block + Cancel sheet entry + Invoice block slot + existing Discount block; cancel-reason as BottomSheet on detail; receipt viewer ONLY if decided (else block-in-detail). Checkout/success/cart unchanged. All within `ClientCard/SectionTitle` components.

## 20. Routing Architecture
| Destination | Existing Route | New Route? | Caller | Parameters |
|---|---|---|---|---|
| Orders center | (home tab) | No | shell tabs | none |
| Detail | `order/:id` | No | list/success | orderId |
| Cancel sheet | — (sheet) | No | detail pending block | orderId, total |
| Receipt viewer | none | Only if decided | detail invoice block | orderId |
| Notifications/support | existing | No | detail deep-link later | orderId (future) |

## 21. Backend Dependency Matrix
| Feature | Frontend Only | Existing RPC | New RPC Required | Migration Required | RLS Required | Current Status |
|---|---|---|---|---|---|---|
| Filters | Yes | — | No | No | No | ready |
| Timeline (derived) | Yes | — | No | No | No | ready |
| Timeline (history) | No | none | Yes (design) | Likely | No | gap |
| Cancellation | No | 0021 file-local | No (apply it) | 0021 application | No | blocked on apply |
| Cancel reason store | No | none | — | TBD (§8) | No | gap |
| Edit via recreate | Yes | create/cancel | No | No | No | ready (policy-gated) |
| Reorder/buy-again | Yes | reads exist | No | No | No | ready |
| Discount | Yes | 0020 live | No | No | No | ready |
| Invoice | No | none client-side | Possibly | Possibly (H2) | Yes | gap |
| Notifications link | Partial | none | Possibly | Possibly | No | gap |
| Support context | Partial | none | Possibly | Possibly | No | gap |
| Payment | No | none | Yes (new track) | Yes (new) | TBD | not implemented |

## 22. Implementation Phases (proposals only)
P-A Center UI: filters + slots + discount markers (app-only; needs l10n; tests: widget). Acceptance: all five statuses filterable, no backend touched. P-B Cancel wiring: 0021 applied + branch swap + client entry + reason sheet (needs 0021 + l10n). P-C Timeline derived + invoice/support/notification blocks as each backend lands (gated per dependency). P-D Edit semantics: policy decision first, then cancel-recreate guidance UI (no item editing ever). Blockers marked per phase; no phase starts without its gate.

## 23. Business Decisions (unresolved only; 16.7/22.3 untouched)
Cancel-reason compulsory vs optional+default; receipt/PDF requirement; notification scope; payment model (standalone track); edit-history linkage via `parent_order_id`; H1/H2/H3 owner approvals (carried). Everything else is TECHNICAL IMPLEMENTATION.

## 24. Security / Trust Checklist
Own-orders-only reads (RLS + client_id filter, existing); cancel auth + state server-side (0021 design); no client financial authority (display-only); no direct ledger writes (seam unchanged); no Free-Y/financial mixing (verified); current-price reorder (re-fetch pattern); stock revalidation at creation RPC; RLS preserved on all new reads; idempotency keys retained per controller pattern; duplicate-submit guards; stale-order handling via reload-after-action.

## 25. Implementation Freeze
LOCKED: architecture (extend, don't duplicate), statuses, server-authority, price/stock/funds revalidation, no item patching. IMPLEMENT NEXT (no new business decision): P-A filters/markers. BACKEND REQUIRED: 0021 apply, invoice reads, history source, reason store, notification/support linking. BUSINESS DECISION REQUIRED: §23 list. FUTURE: receipt viewer, payment, edit-linkage semantics. OUT OF SCOPE: new screens beyond §19, any migration/RLS/SQL now, checkout changes, GL/tenant.

## 26. Evidence / File References
All paths verified this phase: screens inventory, `app_router.dart` routes, `order_service.dart:146/223/245/330`, `order_controller.dart:109/123/138`, `OrderModel.parentOrderId` (order.dart:16), `NotificationModel` (no order link; `related_offer_id` precedent), zero cancel-reason matches, zero payment matches, zero post-creation item writes, 0021 file-local RPC, 0016/0017/0020 anchors from prior phases. Transport note: two empty-call ECONNRESETs during composition; content resent in smaller chunks, none lost.

PHASE 27 COMPLETE — CUSTOMER ORDER CENTER IMPLEMENTATION PLAN
NO CODE MODIFIED
NO DATABASE CHANGES
NO SQL EXECUTED
NO MIGRATION CREATED
NO COMMIT
NO PUSH
