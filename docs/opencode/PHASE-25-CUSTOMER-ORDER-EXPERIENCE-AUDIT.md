# PHASE 25 — CUSTOMER ORDER EXPERIENCE AUDIT (read-only)

## 1. Executive Summary
The client HAS a working order loop (catalog → cart → checkout → success → orders list → detail with tracking/rating/reorder) but NO order management: no cancel, no edit, no filters, no invoice/receipt view, no order-linked notifications/support, no payment or cancel-reason data anywhere. Discount (Phase 21) is wired only on the detail screen for pending orders. Backend supports more than the UI exposes (cancel RPC in 0021 file, ledger history), and supports nothing for edit/invoice-view/client-cancel-today. Web PWA is director-monitoring only.

## 2. Existing Order Screens (inventory with evidence)
- `screens/client/cart_screen.dart` — cart editing (controller `CartController`).
- `screens/client/checkout_screen.dart` — address + notes + submit (`_submit:50-69` → `OrderController.submitOrder` → `create_order_with_items`); Free-Y governorate sync only bonus touch.
- `screens/client/order_success_screen.dart` — success badge + order id + go-to-detail/home; no actions.
- `screens/client/orders_tab.dart` (full read, 173 lines) — ONE unfiltered list via `OrderController.loadClientOrders` → `fetchClientOrders` (all own orders, newest first); per-row: number, date, status chip, address label, total; tap → detail. No tabs/filters/search/actions.
- `screens/client/order_detail_screen.dart` — header + status chip, address, schedule, driver map (in_progress only), items (paid + Free-Y badge), notes, totals, reorder button (delivered only), rating (delivered only), NEW pending-only `OrderDiscountSection`.
- `screens/shared/notifications_screen.dart` — generic list (fetch/mark-read); zero order-specific matches.
- `screens/shared/help_support_screen.dart` + `chat_room_screen.dart` — support exists with zero order linkage.
- Absent (repo-wide search): order tracking screen (map is inline in detail), cancel UI, edit UI, invoice/receipt screen, payment UI.

## 3. Existing Routes (all under `/client`)
`cart`, `checkout`, `order-success/:id`, `order/:id`, `bonus-*` (5), `notifications` (shared `/notifications`), addresses, support via shared screens. No `/client/orders/filter`, no cancel/edit/receipt routes. Entry: home shell tabs + success screen + orders list rows.

## 4. Current Order Lifecycle (code-proven)
checkout submit → `create_order_with_items` (pending, server total, Free-Y validated) → success screen → detail; branch `allocateOrder` → assigned (+server invoice, client-invisible); status updates (in_progress/delivered/cancelled) via direct writes; in_progress shows `DriverLocationMap`; delivered unlocks rating + reorder-to-cart; cancelled is terminal display. Discount window: pending-only via detail section → `apply_order_discount`. Cancel path for discounts: 0021 RPC exists in repo file, unwired, unapplied.

## 5. Customer Order Capabilities
View all orders (list), view detail (full), reorder-to-cart (delivered, payable items only), rate driver (delivered), apply/remove bonus discount (pending, Phase 21), live driver map (in_progress), support chat (unlinked), notifications (unlinked). Cannot: cancel, edit, filter/search, view invoice, pay online (no payment model at all), see cancel reasons (no such column).

## 6. Cancellation Status
UI: MISSING (zero cancel widgets/calls client-side; branch-only path exists elsewhere). Backend today: direct status writes (no RPC). Backend designed: 0021 `cancel_order_with_discount` (client pending-owner branch specified, file-local, NOT applied, NOT live). Who may cancel per actor: client — nothing today; branch — direct write; director — RLS allows, no UI.

## 7. Reorder Status
EXISTS_AND_WORKING in two distinct shapes: (a) detail `reorderAddedToCart` — refills cart with payable items (Free-Y excluded); (b) home `reorderSuggestions` — `fetchRecentReorderProducts` (last 3 orders → ≤8 products). Neither clones an order; both create NEW carts/orders normally. No "repeat identical order" exists.

## 8. Edit Order Status
MISSING entirely (no UI, no RPC, no update path for items post-creation). Architecturally: editing paid lines post-creation would break server totals, allocation math, Free-Y validation, discount caps, and issued invoices — requires a new cancel-and-recreate or versioned-amendment flow, NOT an item patch. Verdict: needs a new backend path; direct `order_items` edits must stay forbidden.

## 9. Tracking Status
EXISTS_BUT_INCOMPLETE: inline `DriverLocationMap` for in_progress + status chips everywhere + dates; no timeline component, no status-history view, no push-linked order events.

## 10. Invoice/Receipt Status
MISSING client-side (only receipt ICONS in list/detail/success rows). Backend invoices exist but are branch-visible only (RLS). No receipt data, no payment records, no delivery-fee model found anywhere.

## 11. Bonus/Discount Integration
Detail-screen section (pending): server funds display, amount request, apply/remove, applied-state with server-recorded amount + informational payable; history screens already label ORDER_DISCOUNT rows. Server remains truth; prices untouched; Free-Y separate. Gap: list rows show gross total without discount indication; no discount visibility post-allocation.

## 12. Customer Order Center Gap Analysis
A single "My Orders" surface EXISTS (`orders_tab`) but is a flat list: no status tabs/filters, no counts, no per-status actions, no search. It is the correct future host (already wired to `loadClientOrders`), needing filter tabs + action slots, not a new screen.

## 13. Trust/UX Gap Analysis
Present: order number (8-char), status chip, dates, items+quantities, prices, delivery address, totals, Free-Y badges, discount section (pending). Absent (verified in model + schema + UI): payment method/records, delivery fees, cancel reasons, status timeline/history, invoice/receipt, order-linked notifications/support context. Trust is therefore transactional (what happened) without provenance (why/when-paid/proof).

## 14. Backend Dependencies
Have: order CRUD-reads, discount RPCs (0020 live), cancel RPC (0021 file-local). Need for full experience: cancel RPC applied + wired; invoice read access for clients (RLS decision); status-history source (none exists — needs design); edit flow (new path); notification order-linking (payload convention).

## 15. Missing Screens
None strictly required as NEW screens: orders_tab (filters), order_detail (cancel entry when backend lands; timeline block; invoice block), notification/support (order context args), checkout (nothing — correctly discount-free). New screen only if: dedicated receipt viewer (optional) or cancel-reason sheet (when cancel backend lands).

## 16. Missing Backend Capabilities
Client cancel execution (0021 specified, unapplied/unwired); client invoice/receipt reads (RLS + maybe API); status-history trail (no source); order edit path (new design); order-linked notification payloads; payment records (no model at all — largest structural gap for trust).

## 17. Recommended Screen Architecture (concept, no code)
Keep current architecture; extend `orders_tab` → My Orders [All | Active | Delivering | Delivered | Cancelled] (client-side filter over existing fetch; counts optional). Detail gains: Status Timeline (derived from status + timestamps; history needs §16 backend), Cancel entry (pending, post-0021), Invoice block (post-RLS), Discount block (exists). No new routes except optional receipt viewer. This reuses rather than replaces the proven structure.

## 18. Recommended Implementation Phases (unordered proposals, not approved)
P1: orders_tab filters + per-status action slots (UI-only, no backend). P2: 0021 apply + cancel wiring (backend + app swap + reason input). P3: client invoice reads (RLS decision + UI block). P4: timeline/history backend + UI. P5: notification/support order-linking. P6: edit-flow design (new path, last — highest risk). Payment records are a standalone track.

## 19. Files for later modification
`orders_tab.dart`, `order_detail_screen.dart`, `order_discount_section.dart`, `branch_service.dart` + `branch_order_actions.dart` (cancel swap), `bonus_wallet_service.dart` (cancel-order method already added in Phase 21), `notification_service.dart` + screens, `order_service.dart` (invoice/history reads), RLS migrations (new file when decided), app_router (only if receipt route added).

## 20. Risks
Cancel-without-backend strands discounts (already documented); invoice visibility needs an RLS decision with privacy review; edit flow is the highest-risk build (totals/allocation/invoice/discount interplay); payment absence caps trust ceiling regardless of UI polish; 0021 unapplied blocks all cancel UX.

## 21. DO NOT IMPLEMENT YET
No screens, routes, migrations, RLS, or backend changes are authorized by this audit. Specifically frozen: client cancel UI (needs 0021 applied), invoice reads (needs RLS ruling), edit flow (needs new backend design), notification/support linking (needs payload convention), payment (needs full architecture). This section overrides any reading of §§17–19 as approval.

## 22. Experience matrix (A–P) + search methodology
Searches executed: screen inventory (`ls screens/client`), route inventory (`app_router.dart` paths), `cancel/reorder/edit/track/invoice/receipt/notification/support/chat/payment` greps across `medlink_app/lib`, service method inventories (`order_service`, `order_controller`, `notification_service`), schema greps (payment/cancel_reason: zero hits), migration capability review (0017–0021 from prior phases), web comparison (`OrdersMonitoringPage`: director read + transfer only).
| A current orders | list exists, no filters | EXISTS_BUT_INCOMPLETE | orders_tab.dart:88-171 |
| B processing | chip display only | EXISTS_BUT_INCOMPLETE | OrderStatusChip, no actions |
| C delivering | inline driver map | EXISTS_BUT_INCOMPLETE | detail:323-327, no timeline |
| D completed | detail + rating + reorder | EXISTS_AND_WORKING | detail:196,474-484, reorder fn |
| E cancelled | terminal display only | EXISTS_BUT_INCOMPLETE | chip only, no reason/flow |
| F detail | full content incl. discount | EXISTS_AND_WORKING | order_detail_screen |
| G tracking | map only | EXISTS_BUT_INCOMPLETE | no timeline/history |
| H cancel | none client-side | MISSING (backend file-local) | zero client cancel matches |
| I edit | none anywhere | MISSING (needs new backend) | zero edit matches |
| J reorder | refill-cart | EXISTS_AND_WORKING | detail `_reorder`, home suggestions |
| K buy again | recent-products shelf | EXISTS_AND_WORKING | fetchRecentReorderProducts |
| L invoice/receipt | icons only | MISSING (backend branch-only) | zero receipt data matches |
| M discount/bonus | pending detail section | EXISTS_AND_WORKING | order_discount_section.dart |
| N support | unlinked chat/help | EXISTS_BUT_INCOMPLETE | shared screens, zero order refs |
| O notifications | unlinked list | EXISTS_BUT_INCOMPLETE | zero order matches in screen |
| P complaints | special-request (product availability) | EXISTS_BUT_INCOMPLETE | special_request_screen, not order-linked |

## 23. Final capability table + verdict
| Capability | UI | Backend | Status | Evidence |
|---|---|---|---|---|
| Browse orders | orders_tab | fetchClientOrders | working | §2, §22-A |
| Order detail | detail screen | fetchOrderDetails | working | §2, §22-F |
| Discount apply/remove | detail section | 0020 live RPCs | working | Phase 21 + §22-M |
| Cancel | none | 0021 file-local only | missing | §6 |
| Edit | none | none | missing | §8 |
| Reorder / buy-again | detail + home | existing reads | working | §7 |
| Tracking | inline map | status fields | incomplete | §9 |
| Invoice/receipt | none | branch-only | missing | §10 |
| Notifications/support | generic | generic | incomplete | §2 |
| Payment | none | no model | missing | schema grep zero |

PHASE 25 COMPLETE — CUSTOMER ORDER EXPERIENCE AUDIT
