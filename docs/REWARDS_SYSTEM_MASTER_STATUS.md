# MedLink Yemen — Rewards System Master Status

> AUDIT ONLY — generated 2026-09-28 by repository + live read-only inspection.
> Nothing was modified. Claims cite exact files/live queries. Where verification
> was impossible, this states so explicitly. Live project: `lmkomzqioneuyvatzsov`.

## 1. Executive Summary

Two parallel bonus models coexist. **Legacy Buy-X-Free-Y** (`bonus_rules`, free order lines, cart math, branch allocation of physical units) is fully built across DB, Flutter, and Web. **Financial Bonus** (ledger-based wallet: earn/redemption/withdrawal/discount/reversal/expiry, rules V2, pending entitlements, audit) is fully built in DB + Flutter + Web UI, with all core RPCs verified live. What is NOT done: no live-DB behavioral tests exist anywhere (all tests are offline), earn-engine live behavior is untested, several UI actions are display-or-dead-ends (manual earn/expire buttons exported but uncalled), the two models share only ledger-adjacent concepts and are easily confused in docs, one live trigger (`trg_financial_bonus_inventory`) has no repository source, and the financial module's 27 tables are LIVE ONLY with no creating migrations. Open business gates: BD-2 (cancel taxonomy), D4/GL direction, company-identity ownership (BD-COMPANY-01–11), invoice linkage, payment model.

## 2. Architecture

- **Flutter** (`medlink_app/`): provider-based (`BonusWalletController`, `OrderController`, `BranchController`, `CartController`, `CatalogService`); services call Supabase RPCs directly; offline unit/widget tests with fake services.
- **Web/Admin** (`Medlik-Waap/artifacts/pharma-pwa/`, git submodule): React PWA, director-only (`company_director` + active account enforced in `AuthContext.tsx:8,54`); two API layers — `bonusRulesApi.ts` (legacy) and `bonusFinancialApi.ts` (financial); no test harness at all.
- **Supabase/PostgreSQL**: 22 local migrations (0001–0022); SECURITY DEFINER RPCs with fixed `search_path`; RLS deny-by-default with owner/director SELECT policies and no client write policies on financial tables; UNIQUE idempotency keys; append-only ledger guarded by trigger.
- **Two ledgers, two truths**: operational truth = `order_items` split (paid vs `is_bonus`); financial truth = `bonus_ledger` (POSTED/REVERSAL). They meet only at: allocation (physical units incl. free), invoice math (paid lines minus posted discounts), and earn evaluation (reads order lines).

## 3. Completed Features

- Legacy rules CRUD + cart free-line math + checkout validation + allocation of physical units (0016/0017, `CartController`, 7 cart unit tests, web `BonusRules*` pages).
- Financial account/wallet/history UI (Flutter wallet/history/requests screens; web financial dashboard + ledger with reversal action).
- Redemption request/approve/fulfill/cancel + withdrawal full lifecycle (request/review/approve-or-reject/pay/complete/cancel) in DB + both UIs.
- Order discount apply/cancel RPCs (0020, live-verified) + Flutter checkout integration + idempotent retry (11 tests).
- Order cancel with compensating reversal + history table (0021/0022, live-verified) + branch + customer UI wiring (7 + 10 tests).
- Earn engine (0019: evaluator + delivered trigger + pending processor + rule validator trigger), live-present.
- Expire/reverse/audit-trail primitives + director audit viewer + settings KV editor.
- RLS + grants posture verified live (SELECT-only, authenticated EXECUTE, in-function authz).

## 4. Implemented but Not Verified

- Earn-engine live behavior (valuation, stacking, caps, pending replay, holds) — present live, zero behavioral tests; prior test design concluded BLOCKED for lack of staging.
- Allocation RPC live behavior, invoice math with discounts, reversal-after-delivery guards — code-reviewed only.
- Web `earnBonus`, `expireBonus`, `getBonusRuleV2` exports — no UI callers; server functions exist, end-to-end path unexercised.
- Redemption REJECTED path — badge exists in UI, no reject RPC wired (server-side-only or missing — not verified which).
- Bonus settings keys/value schemas — UI renders generically; authoritative key list not verified against live rows in this audit.
- `bonus_rules_v2_validate_trigger` (referenced by web comment) — existence assumed from migration filename pattern, not re-verified live here.
- Full test suite green (29 Flutter tests) but 100% offline — nothing above is behaviorally proven.

## 5. Partially Implemented Features

- Order Center: flat list + full detail + reorder/buy-again/rating/map/discount-section exist; filters, timeline history, cancel entry, invoice block, notification linking do not (designs exist, Phases 25–27).
- Cancellation history: table + RLS + RPC insert live; reads exist only in customer detail; no branch/director surfaces, no reporting.
- Notifications: generic table + center + manual sender exist; zero order/bonus linkage (no `related_order_id`; offers use `related_offer_id` precedent).
- Analytics: `get_order_product_distribution` RPC exists (0017:247); paid/bonus/total separation implemented server-side; no dedicated bonus-analytics UI/backend beyond client-side dashboard sums.
- Invoice/receipt client view: icons only; invoices branch-visible, unlinked (no `order_id`), no items table.
- Payment: stub table live (`payments`: invoice/client/amount only); no provider, status, settlement, or withdrawal linkage.

## 6. Missing Features

Live-DB behavioral tests (all kinds); staging environment; bonus analytics backend; client invoice/receipt reads + linkage ruling (H2); payment model; status-history trail; order edit path; notification order-linking + emission; `parentOrderId` semantics; company-identity plumbing (all BD-COMPANY items); GL bridge + D4 treatment; BD-2 cancel taxonomy values; director cancel/history surfaces; F6-class follow-up index review (noted, unexecuted).

## 7. Database Migrations

| Migration | Purpose | Status | Dependencies | Notes |
|---|---|---|---|---|
| 0001_initial_schema | users/branches/roles, helper fns | local file; live objects consistent | none | role enum + branch assignment live |
| 0002_catalog_inventory_orders | catalog, orders, items, invoices RLS | local file | 0001 | orders statuses; manager update policy |
| 0003_bonus_commission_approval_notifications | legacy `bonus_rules` + RLS + notifications | local file; legacy table live | 0001/0002 | Buy-X-Free-Y model root |
| 0004–0008 | access/RLS/chat/location fixes | local files | prior | non-bonus infra |
| 0009_branch_manager_operations | `branch_allocate_order` v1 + invoice RLS | local file; fn live | 0002 | superseded in behavior by 0016 |
| 0010–0015 | settings/inventory-batch/requests/addresses/images | local files | prior | non-bonus infra |
| 0016_bonus_inventory_allocation_safety | allocation rewrite: physical units, paid-only invoice | local file | 0009, items | oldest-first? No — physical allocation; audited via prior phases |
| 0017_bonus_order_integrity_and_analytics | `create_order_with_items`, distribution RPC | local file | 0016 | server-side totals; Free-Y validation |
| 0018_bonus_financial_system | ledger/accounts/rules_v2/redemption/withdrawal/settings/audit + 16 RPCs | local file; 11/11 sampled RPCs live | 0017 | append-only ledger + idempotency core |
| 0019_bonus_earn_engine | pending entitlements, evaluator, delivered trigger, processor, rule validator | local file; 6/6 sampled objects live | 0018 | priority ASC wins; non-stackable stops |
| 0020_order_discount | ORDER_DISCOUNT debit + lot allocation + snapshot | local file; body-identical live (prior gate) | 0018/0019 | oldest-first reuse |
| 0021_order_cancellation_with_discount | atomic cancel + compensating reversal | local file; live-confirmed | 0020 | MANUAL-snapshot fail-closed |
| 0022_order_cancellation_history | history table + RPC integration | local file; live-verified (0 rows) | 0021 | no backfill by design |
| (financial module DDL) | 27 financial_* tables + journal RPCs | MISSING from repo; LIVE ONLY | unknown | provenance unknown — docs gap |

## 8. Database Objects

- **Tables**: `bonus_rules` (legacy), `bonus_rules_v2`, `bonus_accounts`, `bonus_ledger`, `bonus_earn_allocations`, `bonus_redemptions`, `bonus_withdrawals`, `bonus_settings`, `bonus_audit_trail`, `bonus_pending_entitlements`, `order_cancellations`, plus `financial_*` (27, live-only), `invoices`, `payments` (stub), `orders/order_items`.
- **Functions/RPCs** (verified live present): `create_order_with_items`, `get_order_product_distribution`, `branch_allocate_order`, `bonus_account_funds`, `bonus_allocate_spend`, `bonus_credit_remaining`, `open_bonus_account`, `post_opening_balance`, `post_legacy_migration`, `earn_bonus`, `request/approve/fulfill/cancel_redemption`, `request/cancel/start_review/review/mark_paid/complete_withdrawal`, `reverse_bonus_txn`, `expire_bonus`, `bonus_check/validate_rule_v2`, `bonus_evaluate_order_earn`, `bonus_on_order_delivered`, `bonus_process_pending`, `apply/cancel_order_discount`, `cancel_order_with_discount`, `create/post_financial_journal_entry`; live-only `trg_financial_bonus_inventory` (no repo source — provenance gap).
- **Triggers**: `trg_bonus_rules_v2_validate`, `trg_bonus_on_order_delivered`, ledger immutability guard, journal posted-mutation guards, auth user bootstrap.
- **Policies**: SELECT-only owner/director patterns on all financial tables; no client write policies; EXECUTE to `authenticated` with in-function role checks.
- **Constraints**: CHECK status enums (ledger POSTED/PENDING; redemption 5-state; withdrawal 6-state incl. UNDER_REVIEW); UNIQUE idempotency keys; FK RESTRICT/SET NULL on history/reversal links.
- **Indexes**: account/time, account/status, reverses-unique partial, order lookup (F6-class), history order index.

## 9. Flutter Implementation

Cart (`CartController`, 7 unit tests) → checkout (`submitOrder`) → `create_order_with_items` → success → orders list → detail (map, rating, reorder, discount section with retained-key idempotency) → branch allocate sheet → invoice (branch-visible). Wallet/history/redeem/withdraw/requests screens read RPCs; cancel flows (client detail section, branch dialog with reason field) call the cancel RPC. All money math server-side; UI displays verbatim. 29 tests, all offline with fake services; `flutter analyze` clean except 4 pre-existing infos.

## 10. Web/Admin Implementation

- 🟢 IMPLEMENTED AND VERIFIED (code-read; live behavior not executed): bonus overview/rules CRUD (legacy), financial dashboard, ledger browser + reversal action, rulesV2 CRUD, redemptions lifecycle pages, withdrawals full-lifecycle pages, pending queue processor, audit viewer, settings editor — all director-gated.
- 🟡 IMPLEMENTED BUT NOT VERIFIED: everything above at runtime (no web tests, no staging); settings key schemas; rejection path existence.
- 🟠 PARTIALLY IMPLEMENTED: dashboard aggregates client-side (code comment notes missing server aggregate RPC); redemption page lacks reject action.
- 🔴 NOT IMPLEMENTED: bonus analytics, order-discount UI, cancellation UI/history UI, invoice linkage UI, payment UI, notification-bonus linkage.
- 🔵 ARCHITECTURE / PLANNED ONLY: GL bridge UI (journal pages operate manually, bonus-blind).

## 11. Financial Rewards Architecture

Ledger append-only (POSTED debits/credits, REVERSAL compensations via `reverses_id`, EXPIRATION contra entries); lots attributed oldest-first via `bonus_earn_allocations`; balances derived (earned − used − reserved), never stored. Lifecycles as coded: redemption PENDING→APPROVED→FULFILLED (CANCEL path; REJECTED badge without wired action); withdrawal PENDING→UNDER_REVIEW→APPROVED→PAID→COMPLETED (REJECTED/CANCELLED branches); discount PENDING→POSTED with snapshot; cancel → REVERSAL + history row atomically. Audit `bonus_audit_trail` on every mutation. Settings KV (global). No GL posting anywhere — journal RPCs accept only manual entries.

## 12. Inventory Integration

Free-Y lines consume physical units 1:1 at allocation (`branch_allocate_order` aggregates paid + bonus quantities, deducts once); stock checked per branch/product with row locks; shortfall aborts atomically. Financial bonus never touches inventory (discount/reversal/earn are ledger-only). Verified in 0016 text; live behavior untested.

## 13. Order Integration

Creation RPC validates Free-Y lines (zero price, rule match) and computes server totals from paid lines; allocation requires pending→assigned with full physical coverage; invoice = paid-lines total minus posted discounts (netting added in 0021-file revision path — verify which revision is live before relying: 0016 vs 0021-file allocate body differ; live `branch_allocate_order` body not diffed in this audit); cancel flips status + reverses + records history atomically. Discount never mutates item prices. Free-Y and financial discount coexist on one order by construction (separate columns/rows).

## 14. Analytics

`paid_sales_quantity` vs `bonus_quantity` vs `total_distributed_quantity`: separated server-side in creation validation + `get_order_product_distribution`; invoice math excludes free units. Client dashboard sums are display-only. No dedicated analytics backend; correctness of separation is code-reviewed, not test-proven. Cancelled-order demand exclusion depends on status filtering at query time (convention, not constraint).

## 15. Security / RLS

Deny-by-default; SELECT own-rows (client) / all-rows (director); branch scoped by branch checks in RPCs; no INSERT/UPDATE/DELETE policies on ledger, allocations, history, redemptions, withdrawals; SECURITY DEFINER + fixed `search_path` on all RPCs; ownership + status + idempotency enforced inside functions; UNIQUE keys backstop races; POSTED immutability trigger. Live grants spot-checked in prior gates (authenticated EXECUTE; anon parity with RLS denial).

## 16. Known Gaps / Risks

Technical: zero live-DB behavioral tests; no staging; live-only trigger + 27-table financial module with no repo provenance; uncalled UI exports (`earnBonus`, `expireBonus`, `getBonusRuleV2`); missing reject wiring; missing aggregate RPC (client-side sums); no invoice linkage/columns; payment stub; no status-history source; no timeline/notification linkage; `parentOrderId` dormant. Business: BD-2 taxonomy; D4/GL direction; company-ownership BD-COMPANY-01–11; H-approvals; invoice scope; payment model; edit semantics. Structural risk: two bonus models + two invoice-computation revisions (0016 vs 0021-file allocate body) coexist in repo history — live body matched the 0021 revision at the prior live gate (Phase 31); not re-fingerprinted in this audit, so re-verify before building on invoice math.

## 17. Required Verification

Live-behavior suites for: earn valuation/stacking/caps/replay/holds; allocation atomicity + shortfall; discount caps/zero-migration; cancel/reversal/history atomicity (already reasoned, never executed); redemption/withdrawal lifecycles incl. rejection; RLS denial probes; expiry sweep; concurrent idempotency races; invoice math (both allocate revisions); analytics separation; notification emission. Requires staging with isolated identities — the single largest infrastructure gap.

## 18. Remaining Development Phases

- Phase A — Database Contract Synchronization: adopt the live-only financial module + trigger into versioned migrations (or formally declare them out-of-scope); reconcile 0016 vs 0021-file allocate body as the single live truth. Why: current repo cannot reproduce live DB.
- Phase B — Pending Entitlements: wire deferred-earn processing (UI exists, processor exists, end-to-end untested). Why: earned-but-unprocessed balances are invisible risk.
- Phase C — Rewards Financial Integrity: live-behavior tests for ledger/allocation/reversal/idempotency invariants. Why: all currently reasoned, none executed.
- Phase D — Product Redemption: rejection path + inventory/COGS linkage design. Why:FULFILL-vs-stock and REJECTED gaps.
- Phase E — Order Discount: discount-aware invoice verification live + list-level discount markers. Why: core money path partially proven.
- Phase F — Cash Withdrawal: payout linkage (cash/bank/payment model). Why: terminal state is status-only today.
- Phase G — Inventory Integration: live allocation + Free-Y + invoice reconciliation tests. Why: physical/financial truth meet here.
- Phase H — Analytics: dedicated backend for paid/bonus/distributed + cancellation exclusion. Why: decisions need queryable truth.
- Phase I — Notifications: order/bonus event linkage + emission. Why: UX + audit completeness.
- Phase J — Full End-to-End Testing: staging scenarios incl. all §17 items. Why: nothing above is proven without it.
- Phase K — Production Hardening: RLS probes, race tests, rollback drills, owner approvals (BD-2, D4, H-, company). Why: gate to scale.

## 19. Dependencies Between Phases

A → everything (contract first). C needs staging (J infra) for full value — run C's design now, execution in J. D/F need accounting policy (K-gated D4) for settlement legs; lifecycle mechanics can proceed. E needs A (invoice truth). G needs E + D. H needs G. I needs event sources (B–G) defined. K gates production use of all.

## 20. Final Status

- 🟢 Complete: legacy bonus loop; financial wallet/redemption/withdrawal/discount/cancel/history mechanics + UIs; RLS/grants posture; offline test suite (29).
- 🟡 Implemented / Needs Verification: earn engine, allocation, invoice math, reversals, all lifecycles at runtime, web actions at runtime.
- 🟠 Partial: Order Center, history surfaces, notifications linkage, analytics, payment, invoice linkage.
- 🔴 Missing: live behavioral tests, staging, GL bridge, payment model, status history, edit flow, receipt viewer, taxonomy values.
- 🔵 Planned: company-identity plumbing, accounting policy + posting design, notification emission, analytics backend.

*Uncertainty log: live list queries intermittently return empty (pooler flakiness; mitigated with count-based re-queries — all material claims above were confirmed on successful reads). `bonus_rules_v2_validate_trigger` and settings-key schemas not re-verified live in this pass (marked accordingly). No code, DB, or docs (other than this file) were modified.*
