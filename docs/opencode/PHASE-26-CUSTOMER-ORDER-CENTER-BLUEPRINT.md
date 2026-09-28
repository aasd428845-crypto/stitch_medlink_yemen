# PHASE 26 — CUSTOMER ORDER CENTER BLUEPRINT (design only, verified against code)

## 1. Executive Summary
Extend — don't replace: `orders_tab` becomes the filterable Order Center, `order_detail` gains timeline/cancel/invoice/discount blocks, all within existing routes, design system, and controllers. True gaps requiring backend: cancel execution (0021 unapplied), invoice reads (RLS), status history (no source — only `created_at`/`scheduled_delivery_at` exist), edit path (new design), payment (no model). Bonus stays a subordinate block, never the organizing principle.

## 2. Current Order Architecture
Client shell tabs → cart → checkout (`OrderController.submitOrder` → `create_order_with_items`) → success → orders list (`loadClientOrders` → all own orders) → detail (status chip, items, totals, map, rating, reorder, discount section). Branch side allocates/bills; statuses flow pending→assigned→in_progress→delivered/cancelled via direct writes. Design system: `ClientCard/SectionTitle/IconBadge/GlassBackground`, `ClientColors`, l10n-driven strings, provider controllers, go_router nesting.

## 3. Existing Screens
| Screen | File | Route | Has | Lacks |
|---|---|---|---|---|
| Cart | cart_screen.dart | `cart` | edit cart | — |
| Checkout | checkout_screen.dart | `checkout` | address/notes/submit | nothing (correct) |
| Success | order_success_screen.dart | `order-success/:id` | badge, go-detail | actions (by design) |
| Orders list | orders_tab.dart | (home tab) | full list, chips, pull-refresh | filters, actions |
| Detail | order_detail_screen.dart | `order/:id` | content, map, rating, reorder, discount | timeline, cancel, invoice |
| Wallet/history/etc. | bonus_*_screen.dart | `bonus-*` | ledger labels incl. ORDER_DISCOUNT | order-link drill-in |

## 4. Existing Routes
No new routes needed: filters live in-tab; cancel = sheet on detail; receipt = optional future route only. Files later touched: `orders_tab.dart`, `order_detail_screen.dart`, routers only if receipt viewer added.

## 5. Order Status Model (DB-verified: pending/assigned/in_progress/delivered/cancelled)
- pending: created, untouched — actions: view, discount, cancel (post-0021). Forbidden: reorder, rating.
- assigned: with branch, pre-dispatch — view only (client pending-only cancel per H1).
- in_progress: driver assigned, live map — view + map. Forbidden: cancel/edit/discount.
- delivered: terminal success — view, reorder, rate. Forbidden: cancel/discount.
- cancelled: terminal — view only (+reason when backend stores it; BACKEND DATA GAP today).
Center tabs map 1:1 (All + five statuses, or grouped Active/Delivering/Done). No invented statuses.

## 6. Customer Order Center Architecture
Extend `orders_tab.dart` (already the wired host): filter tabs [All|Pending|Assigned|On the way|Delivered|Cancelled] over the existing `loadClientOrders` fetch (client-side filter; counts from the loaded list), per-row action slot (pending → discount hint/cancel entry point later; delivered → reorder shortcut). No duplicate screen, no new route.

## 7. Order List Design (card fields, all exist today)
Order number (id 8-char), date (`created_at`), status chip, product count (items length — EXISTS via order items), total (`total_amount`), discount indicator (BACKEND DATA GAP: join to own ledger ORDER_DISCOUNT rows for the order — readable today via `fetchMyLedger`, needs UI join, no backend change), delivery label (address label), last-update (BACKEND DATA GAP: no `updated_at` on orders).

## 8. Order Details Design
Header (number/date/chip — exists) + Timeline (new block, §9) + Products with Free-Y badges (exists) + Financial Summary: subtotal/total (exists), Bonus Discount row (exists for pending; extend to show POSTED discount read-only for later states), delivery fee (ABSENT everywhere — BACKEND DATA GAP), final payable (informational, server values) + Delivery (address/branch/driver — exists) + Actions (§5 matrix).

## 9. Timeline Design
Derivable TODAY (no backend): Created (`created_at`) → Scheduled (`scheduled_delivery_at`, if set) → current status node. NOT derivable (no timestamps, no history table): per-status transition times, cancellation time/reason. Full timeline needs backend: either status-history table or audit-derived trail (design decision, future phase). Never fabricate times.

## 10. Cancellation Design (0021 file-local, unapplied — design only)
Cancel button visible ONLY on pending orders (mirrors H1-B-NARROW + RPC gate). Flow: sheet → optional reason (F1 REQUIRES `p_reason`; UI must collect or send a fixed default — l10n string) → confirm → new service/controller method → `cancel_order_with_discount` → success: status reload + wallet reload (reversal restores funds) → show reversal via history labels. No-discount: status flips, NULL return, same UX minus reversal row. Failure (incl. MANUAL-snapshot abort): error string, status unchanged (fail-closed), retry safe. Result display reuses existing error/snackbar + controller patterns.

## 11. Edit Order Analysis
Verdict: C — must become Cancel + New Order (or a future versioned-amendment RPC), NEVER direct item patch. Proof: totals are server-set at creation; allocation math, Free-Y validation, discount caps, and issued invoices all derive from frozen lines; no update path exists in schema or RLS. Dormant affordance: `parent_order_id` exists but is referenced NOWHERE (code + migrations) — a future cancel-and-recreate flow could link child→parent through it, but that is a business-policy + backend design decision (BUSINESS POLICY REQUIRED for whether edited orders keep history linkage at all).

## 12. Reorder / Buy Again Analysis
Both exist and are NOT duplicates: Reorder (detail, delivered) = refill cart with payable items at CURRENT catalog prices via `fetchCurrentProducts` (no stale-price risk — re-fetched; Free-Y re-evaluated at new checkout; discount starts fresh — correct isolation). Buy Again (home shelf) = pick individual past products into cart (last-3-orders source). Neither needs changes; the Center should surface both entry points. No identical-order cloning exists or is needed (creation RPC re-validates everything anyway).

## 13. Bonus / Discount Integration
Apply/remove live on pending detail (Phase 21); list rows gain a discount marker via own-ledger join (app-only); history labels exist (incl. REVERSAL kind marker). Display rules: show server-recorded amounts verbatim; never alter item prices; payable = informational. On cancel: reversal row appears in history automatically (no UI work — labels exist). Bonus visibility states: earned/used (EXISTS via wallet/history), discount (EXISTS), reversed (EXISTS via REVERSAL rows), per-order attribution lots (BACKEND DATA GAP for lot-level display — allocations readable only via director RLS; client lot drill-in needs RLS decision).

## 14. Invoice / Receipt Future Design
CURRENT: no client invoice surface; branch-only RLS; no order linkage (no `order_id`); no receipt/PDF/share. FUTURE placement: detail block "Receipt" (post-RLS) showing server invoice rows for the order (needs linkage ruling H2 first) + optional viewer route + share via platform share sheet. Backend needs: client invoice read policy + order linkage decision + receipt payload shape. PDF/download: FUTURE-deferred (no requirement evidence today).

## 15. Notification Future Design
Contract only: events Created/Assigned/Out-for-delivery/Delivered/Cancelled/Discount-applied/Discount-reversed with `{order_id, status, amount?}` payloads. Backend needs: order_id in notification rows/payloads + emission points (creation RPC, allocate, status writes, discount/cancel RPCs). No new system — extend the existing notification table + center.

## 16. Support Future Design
Concept: "Help with this order" button on detail → support/chat entry with `order_id` context attached (FUTURE BACKEND REQUIRED: context column/args, agent-side order lookup, optional reason/category + ticket vs chat ruling). Existing chat/help screens are the host; only the order context is missing.

## 17. Payment Future Design
PAYMENT BACKEND REQUIRED (no model exists): future Payment Status (unpaid/partial/paid/refunded) must be INDEPENDENT of order status, displayed in Financial Summary, sourced from payment records — never derived client-side. Nothing to design in UI until the model exists.

## 18. Trust Layer (each item bound to real data)
Number/date/status/items/prices/discounts/total/address — EXISTS. Timeline full history, cancel reason, payment proof, receipt, delivery fee — BACKEND DATA GAPS (listed, not fabricated). Trust rule for build: every displayed fact cites its source column/RPC; gaps render as absent sections, never placeholders.

## 19. Actions Matrix (status × action; backend is the enforcer, UI only exposes)
| Status | View | Cancel | Edit | Reorder | Buy Again | Receipt | Support |
|---|---|---|---|---|---|---|---|
| pending | EXISTS | BACKEND_REQUIRED (0021 unapplied) | NOT_ALLOWED (→cancel+recreate, BUSINESS_POLICY) | FUTURE (allowed technically; UX-deferred) | EXISTS (home shelf) | FUTURE (RLS+linkage) | EXISTS (unlinked) |
| assigned | EXISTS | NOT_ALLOWED client (H1); branch path exists | NOT_ALLOWED | FUTURE | EXISTS | FUTURE | EXISTS |
| in_progress | EXISTS (+map) | NOT_ALLOWED | NOT_ALLOWED | FUTURE | EXISTS | FUTURE | EXISTS |
| delivered | EXISTS (+rate) | NOT_ALLOWED | NOT_ALLOWED | EXISTS | EXISTS | FUTURE | EXISTS |
| cancelled | EXISTS | NOT_ALLOWED (terminal) | NOT_ALLOWED | EXISTS (recreate) | EXISTS | FUTURE | EXISTS |

## 20. Backend Dependency Matrix
| Feature | Current Backend | Missing Backend | Migration? | App Only? |
|---|---|---|---|---|
| List/detail | reads exist | — | No | Yes (filters) |
| Cancellation | 0021 file-local | apply 0021 + wire | 0021 application (no new file) | No |
| Edit | none | new path or cancel-recreate policy | Likely | No |
| Reorder/buy-again | reads exist | — | No | Yes |
| Discount | 0020 live | — | No | Done (Phase 21) |
| Reversal display | ledger rows | — | No | Yes (labels exist) |
| Invoice | branch-only, unlinked | client reads + linkage ruling | Possibly (H2) | No |
| Notifications | generic | order payloads + emission | Possibly | Partial |
| Support context | chat exists | order_id context | Possibly | Partial |
| Payment | no model | full track | Yes (new) | No |

## 21. Required Business Decisions
Edit semantics (recreate vs amend vs forbidden); cancel-reason compulsory vs optional; receipt/PDF requirement; notification scope; payment model existence; H1/H2/H3 owner approvals (carried from 22.2 §8 — unchanged by this blueprint).

## 22. Implementation Phases (proposals, unapproved)
P-A Center UI (filters + slots, app-only). P-B cancel wiring (post-0021-apply). P-C discount list markers (app-only join). P-D timeline backend + UI. P-E invoice reads + block. P-F notification/support linking. P-G edit-flow backend + UI (last). Payment standalone.

## 23. Files Expected to Change (future)
`orders_tab.dart`, `order_detail_screen.dart`, `order_discount_section.dart` (list marker reuse), `bonus_wallet_service/controller` (cancel-order method), `notification_service` + screens, `order_service` (history/invoice reads), new migration only for decided backend (timeline/edit/payment/linkage), `app_router` only if receipt route added.

## 24. Risks
Building cancel UI before 0021 is applied strands discounts (documented since Phase 19); invoice work without the H2 ruling wastes effort; edit-by-patch would corrupt financial truth — must stay forbidden; payment absence caps trust; timeline without backend timestamps invites fabricated UX (forbidden by §9 rule).

## 25. Explicit Out of Scope
No screens/routes/migrations/RLS/SQL/backend/payment/tenant built or changed in this phase. Bonus remains a subordinate block (Order → Products/Delivery/Financials/Bonus/Actions — never Bonus-first). This blueprint authorizes nothing; §§21–22 await owner decisions.

ORDER CENTER BLUEPRINT COMPLETE
NO CODE MODIFIED
NO DATABASE CHANGES
NO MIGRATION CREATED
NO SQL EXECUTED
NO COMMIT
NO PUSH
