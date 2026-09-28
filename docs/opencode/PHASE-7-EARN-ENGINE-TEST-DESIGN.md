# PHASE 7 — EARN ENGINE TEST DESIGN (design/precheck only, 2026-09-21)

## A. Current Architecture
Order path (single, verified in repo): `checkout_screen:63` → `order_controller.submitOrder:138` (requires delivery address) → `order_service.createOrder:146` (auth + non-empty items + address required) → RPC `create_order_with_items(p_delivery_address_id, p_items[{product_id,quantity,unit_price,is_bonus,bonus_rule_id}], p_notes)` → branch resolved server-side → order + items inserted atomically → status flow pending → … → delivered → 0019 trigger fires earn evaluation. No other creation path (web creates no orders).

## B. Existing Test Infrastructure
Flutter: `test/cart_controller_bonus_test.dart` (cart math only) + `test/widget_test.dart`. No SQL test harness, no staging project, no sandbox env found in repo (`supabase/config.toml`, `.replit`, `replit.md` contain no staging references).

## C. Safe Test Environment Assessment
Live counts (read-only): users 8, branches 22, products 1, orders 2, all bonus tables 0 rows. **No separate test environment exists. Live testing would write financial rows (ledger/pending/audit) plus test users/branches/products/rules/orders — NOT safe without an isolation + approved cleanup plan.**

## D. Required Test Fixtures (to create only upon approval)
TEST_ customer (auth user + users row, clearly named), TEST_ branch, TEST_ product (active, priced), TEST_ v2 rules per case, TEST_ orders via real `create_order_with_items` RPC, then status → delivered to fire trigger. All linked so cleanup can reverse them.

## E–L. Test Matrix (each: Setup / Action / Expected / Evidence / PASS / Cleanup)
- TEST 1 PER_ORDER: rule value 500, eligible order → exactly one EARN 500.
- TEST 2 PER_UNIT: qty 5 × X → 5X, Free-Y lines excluded from qty.
- TEST 3 PER_PRODUCT: map values → SUM(qty×value) eligible-only.
- TEST 4 excluded product → zero earn from it. TEST 5 included-only → others earn nothing.
- TEST 6 Free-Y separation: paid+bonus lines → financial earn ignores bonus lines.
- TEST 7/8 minimums: below/at/above boundaries.
- TEST 9 max cap: calculated > max → capped value.
- TEST 10 stacking: A+B stackable sum; non-stackable stops later rules (ineligible non-stackable does not stop).
- Usage limit: limit 1 → second eligible event skipped (ledger-derived count).
- Idempotency: re-fire same order+rule (re-delivery attempt, processor retry, concurrent) → single EARN row (UNIQUE key).
- Pending: transient failure → snapshot row (rule/product/computed/key), PROCESSED retained, ledger linked.
- Suspended: SUSPENDED-HOLD, no snapshot, re-evaluated on activation.
- Processor: director-only, attempts/ledger_id recorded, snapshot authority (no live-rule re-read).
- Security: client direct INSERT ledger/pending denied; internal RPCs revoked from PUBLIC; processor director-gated.
- Accounting boundary: no GL objects expected in any test.

## M–Q. Cleanup, Gaps, Risks, Order
Cleanup reverse order: ledger compensation-free delete? No — test ledger rows are POSTED financial history; cleanup = cancel test withdrawals/redemptions properly or document test rows as permanent test artifacts in an isolated account. **Unresolved until approved:** deletion would violate append-only design → cleanup strategy itself needs a decision (dedicated test account whose rows are labeled, or full scratch project).
Gaps: bonus_value unit, cancellation-after-consumption, customer_type (may block specific eligibility tests — run the rest).
Risks: writing financial rows to prod; trigger firing on real delivered orders during test window (new rules must be narrowly scoped to test customer/products); concurrent delivery retries.
Order: fixtures → unit-basis tests → eligibility → stacking/usage → idempotency/pending → security → cleanup decision → accounting-boundary assertion.

## R. FINAL VERDICT
**BLOCKED — TEST ENVIRONMENT REQUIRED.** No isolated staging exists; live execution would create real financial rows. Design complete; awaiting either a scratch project or an approved isolated-fixture + cleanup plan.
