# PHASE 16.4 — ORDER DISCOUNT IMPLEMENTATION BLUEPRINT (design only — no code/SQL/DB changes)

## 1. Locked architecture (verified, not re-decided)
Standalone discount RPC applied BEFORE `branch_allocate_order` (invoice snapshots total at allocation, `0016:145-148`); no changes to 0017/0018/0019 files; item prices immutable; Free-Y (`order_items.bonus_rule_id`) separate; ledger = truth; idempotency `DISCOUNT:{order_id}`; no GL in this scope.

## 2. Lot ordering — RESOLVED BY CODE (not a gap)
Existing `bonus_allocate_spend` (`0018:525-544`) already walks oldest-first (`ORDER BY created_at, id`) with remainder caps and shortfall exception. Discount reuses it verbatim — no new ordering to invent.

## 3. Order total source
`v_total` = Σ(paid_qty × server price), bonus lines excluded (`0017:205`), stored at order insert (`0017:218`). Discount base = stored `orders.total_amount` (server-accepted, never client-sent).

## 4. Database changes (future migration 0020 — NOT created)
- `bonus_settings` keys: `discount.allow_zero_order`, `discount.funding_scope`, `discount.cancellation_mode`, `discount.min_amount` (data rows only).
- Optional `orders.discount_ledger_id → bonus_ledger(id)` nullable FK (vs join via `ledger.order_id` — prefer join, avoid column unless queries prove need).
- No 0017/0018/0019 file edits; new objects only.

## 5. Policy storage
Global keys in `bonus_settings` (existing RLS: director manage); rule flags already on `bonus_rules_v2` (`allow_discount` exists); precedence: order caps > rule flags > global > defaults; invariants non-overrideable.

## 6. Accounting
No GL objects in this scope. Required preserved data for future bridge: amount, order/discount links, timestamps, actor, policy snapshot. D4 stays UNDECIDED.

## 7. RPC design (names per convention `apply_*`/`cancel_*`)
`apply_order_discount(p_order_id, p_amount, p_idempotency_key?)` → validates owner + pending status + caps + allocates via existing primitive + inserts ORDER_DISCOUNT debit + audit; `cancel_order_discount(p_order_id)` → compensating REVERSAL linked via `reverses_id`. Definer + fixed search_path + authenticated grants (existing pattern).

## 8. Transaction boundary
Single RPC txn: lock order + account rows → validate → allocate → insert → audit. Never spans allocate/invoice calls. Cross-call consistency via idempotency key + status guards.

## 9. Idempotency
Key `DISCOUNT:{order_id}` UNIQUE-guarded; retry returns existing; concurrent second caller blocks on row locks then hits conflict-guard; top-up excluded by design (cancel+reapply instead).

## 10. Cancellation
Mode-driven (D3): auto path reuses REVERSAL+`reverses_id`; manual path = status guard + admin action. Unconsumed-discount cancel trivially safe (no fulfillment side effects yet).

## 11. Lot allocation reuse
Existing primitive covers multi-lot, partial, reversal-adjusted remainders. No new allocation logic.

## 12. Zero order
Parameterized by policy key; code path identical (cap allows equality only if enabled).

## 13. Funding scope
Parameterized: ANY_LOT (default path, current primitive) vs MONETARY_ONLY (filter lots by originating `rule_id`→`rule_type`; trace exists via EARN rows).

## 14. createInvoice remediation (future, not now)
File: `branch_service.dart:508` + sheet `:55`. Risk: manual amount bypasses discount. Options later: read order final total when order-linked, or restrict to non-order billing with audit. Backward compatible: keep standalone use, add order-link check.

## 15. UI blueprint (future)
Director: settings keys editor extension + discount review in order monitoring. Client: checkout toggle + confirm + status (reuse wallet/history patterns). No screens built now.

## 16. API blueprint (future)
`requestOrderDiscount/cancelOrderDiscount` in wallet service style; controller busy guards; error mapping; retry with same key.

## 17. RLS/security blueprint (future)
Definer RPCs + owner checks + existing table RLS (no client writes); settings writes director-only (existing policy).

## 18. Audit blueprint (future)
Apply/cancel/policy-use rows in `bonus_audit_trail` with key + snapshot references; no table change.

## 19. Versioning/snapshot (future)
Policy snapshot (JSONB) stored on discount ledger row `notes`/dedicated column decision at build; effective-dating via settings history if needed later.

## 20. Migration sequence (future)
`0020` discount core (settings keys + RPC + optional link column; depends on D1–D4) → UI → verification protocol. Latest local migration today: `0019`.

## 21. Test blueprint (future)
Eligible/ineligible/zero/partial/insufficient/expired/suspended/duplicate/timeout-retry/multi-lot/cancel/reversal/invoice-match/Free-Y-separation/RLS/permissions.

## 22. Stages (future)
A foundation (settings keys) → B discount RPC → C cancel/reversal → D invoice path → E web → F Flutter → G verification. Each gated on D1–D4.

## 23. Business decisions gate
D1–D4 UNDECIDED (blocking). No other blocker: all technical paths resolved above.

## 24. ARCHITECTURAL FLAG
None new: prior flags (createInvoice bypass, no accountant role, no staging) already recorded and carried forward, not re-litigated.

IMPLEMENTATION STATUS:
BLUEPRINT COMPLETE — NO CODE — NO SQL — NO DATABASE CHANGES
