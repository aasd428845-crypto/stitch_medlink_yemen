# PHASE 16 — ORDER DISCOUNT DESIGN (analysis only, no code/SQL)

## 1. Current architecture
Order creation is a single atomic RPC: `create_order_with_items` (0017) — validates address/items/prices/bonus lines server-side, computes `v_total` from paid lines only, picks first branch, inserts order (`pending`) + items, returns id. Client path: cart → checkout → `order_service.createOrder` → RPC. No other creation path.

## 2. Existing backend primitives (all verified in-repo)
- Ledger txn types include `ORDER_DISCOUNT` (0018 CHECK) — type exists, **no RPC creates it**.
- Lot allocation (`bonus_allocate_spend`), idempotency keys, reservation PENDING→POSTED lifecycle, audit trail — all reusable patterns.
- Free-Y path (`is_bonus`/`bonus_rule_id` in items, price forced 0) must stay untouched.

## 3. Existing order flow
Cart estimate client-side → checkout confirm → RPC authoritative total → order pending → branch allocate → delivery → (0019 trigger earns on delivered). Invoice/payment separate (branch-side).

## 4. Existing Bonus flow
Earn happens at delivery via 0019 evaluator + trigger; wallet/history/redemption/withdrawal UI connected; discount application point does not exist.

## 5. Proposed Order Discount architecture
New RPC (future migration, e.g. `apply_order_discount(p_order_id, p_amount, p_idempotency_key)`), callable only on the client's own `pending` order before allocation:
1. Lock order + account rows; verify order belongs to caller, status `pending`, no discount already applied (idempotency key `DISCOUNT:{order_id}`).
2. Cap amount at `min(requested, order.total_amount, available funds)` — order can reach zero but never negative.
3. Insert `ORDER_DISCOUNT` ledger debit (negative, PENDING→POSTED with order link) + lot allocation via existing `bonus_allocate_spend`.
4. Record discount on order (new nullable column, future migration) — do NOT mutate item prices (Free-Y separation).
5. Audit row. Return applied amount.
- Cancellation: order cancel → reverse discount entry (compensating, mirroring reversal pattern); never delete.
- Failure before order insert: nothing persisted (single transaction). Timeout retry: same idempotency key → existing row returned.

## 6. Financial flow
Discount debit reduces available balance at apply time; invoice (branch-created later) reflects the discounted total read from order; receivable = total − discount; revenue recognition unchanged in timing (existing invoice flow).

## 7. Idempotency strategy
Key `DISCOUNT:{order_id}` (single discount per order by design) + UNIQUE; concurrent applies serialize on order+account locks; second attempt returns existing.

## 8. Failure/cancellation cases
Apply-fail → no rows (atomic). Order-cancelled-after-discount → compensating reversal entry (same pattern as bonus reversal). Timeout → same-key retry. Amount-change → new key only via cancel+reapply (no in-place edit).

## 9. UI flow
Checkout: toggle "use bonus" → show available → input amount (capped display) → confirm sheet → RPC → success shows applied discount + new total → order continues normal flow. Read-only wallet/history patterns reused.

## 10. Security/RLS
Caller = order owner enforced inside RPC (`auth.uid()` vs order.client_id); director override excluded; no direct writes (existing RLS has no client insert policies on ledger).

## 11. Database impact
Future migration only: nullable `discount_amount` + `discount_ledger_id` on orders (or join via ledger.order_id — preferred, no schema change to orders); no 0017/0018 modifications.

## 12. Business decisions required
1. Max discount: full order value allowed (zero-total orders)?
2. Which rule types fund discounts (MONETARY only? any positive lot?)?
3. Cancellation-after-use policy (mirror consumption rules)?
4. Does discount reduce revenue or settle liability? (accounting, post-bridge)

## 13. Exact implementation phases after approval
P1: decisions 1–4 → P2: discount RPC migration → P3: checkout UI → P4: cancel/retry paths → P5: readout verification (no staging: manual test protocol).

## FINAL VERDICT
**PHASE 16 COMPLETE — DESIGN READY FOR BUSINESS DECISIONS.** No code/SQL written, no DB touched.
