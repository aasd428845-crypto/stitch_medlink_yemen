# PHASE 17 — MIGRATION 0020 IMPLEMENTATION REPORT (local only — NOT applied)

## 1. Executive Summary
`supabase/migrations/0020_order_discount.sql` created locally: 6 product-default settings seeds + `apply_order_discount` + `cancel_order_discount` + 2 EXECUTE grants. No 0017/0018/0019 change, no app change, no live-DB execution. One blueprint-vs-code divergence found and resolved inside 0020's allowed scope (inline lot walk; 0018 untouched). Static validation: 17/17 checks pass. No blocker.

## 2. Files Changed
- NEW `supabase/migrations/0020_order_discount.sql` (413 lines).
- NEW `docs/opencode/PHASE-17-MIGRATION-0020-IMPLEMENTATION-REPORT.md` (this file).
- Nothing else. `git status` confirms 0020 is untracked-new; the 45-line `0018` working-tree diff predates this phase (prior hardening) and was not touched here.

## 3. Migration Path
`0019_bonus_earn_engine.sql` → `0020_order_discount.sql` (next number verified via sorted migration list; name follows `NNNN_snake_case` convention). Purely additive: 1 data seed + 2 functions + 2 grants. No backfill, no delete, no alter of existing objects.

## 4. Architecture Reviewed
Read in full: PHASE-16 → 16.7; `0017` (order create/total/pending); `0018` (settings:285-310, ledger:53-75, audit:313-324, alloc:357-368, funds:393, credit_remaining:437, allocate_spend:475, redemption lifecycle:793-1000, reverse:1332, grants:1489-1507); `0019` (earn engine fns); orders table (`0002:126-135`, statuses pending/assigned/in_progress/delivered/cancelled); `0016` allocate (pending-required, invoice snapshot:145-148); manual invoice path (`branch_service.dart:508`, `branch_controller.dart:216`, sheet `:55`).

## 5. Database Objects Added
Settings data keys (6, `on conflict do nothing`): `discount.allow_zero_order=false`, `discount.funding_scope="ALL_ELIGIBLE_LOTS"`, `discount.cancellation_mode="AUTOMATIC_REVERSAL"`, `discount.max_amount/max_percent/min_amount=null`. Functions: `apply_order_discount(uuid,numeric,text)`, `cancel_order_discount(uuid,text,text)`. No tables, no columns, no indexes, no RLS/grant changes to existing objects.

## 6. Policy Implementation
All reads server-side from `bonus_settings` with type validation (unknown shapes raise); absent keys fall back to locked product defaults. D1 post-cap check (`applied >= total` rejected unless allow_zero). D2 scope validated to 2 values + narrow-only rule filter. D5 caps folded into `min()` (amount, then percent-of-total). D6 floor check. D4: nothing stored except `accounting_treatment: null` marker — accounting-neutral.

## 7. Order Discount RPC
`apply_order_discount` (name/signature per 16.4 §7): auth → client-role → idempotent replay → order lock + ownership + `pending`-only + positive total → single-discount guard → policy reads → `bonus_account_funds` (server funds + account lock) → effective calc → PENDING ORDER_DISCOUNT debit → inline allocation → POSTED flip (rowcount-guarded) → `DISCOUNT_APPLY` audit → return ledger id. Atomic single transaction; any failure rolls back everything.

## 8. Idempotency
Keys `DISCOUNT:{order_id}` / `REVERSAL:DISCOUNT:{order_id}` (custom key overridable via param), enforced by existing UNIQUE(idempotency_key). Replay returns existing id (pattern matches `request_redemption`/`reverse_bonus_txn`). Second distinct discount on one order rejected (cancel-then-reapply). No UI flags involved.

## 9. Concurrency
Order row `FOR UPDATE` + account row lock (via `bonus_account_funds`, same lock redemption/withdrawal take) serialize competitors; ledger UNIQUE key is the backstop. No new locking model invented. Double-spend prevented by funds pre-check + shortfall-raising allocation; duplicate entries prevented by key guards + single-discount check.

## 10. Ledger Integration
Reuses `bonus_ledger` with existing `ORDER_DISCOUNT` type (0018:58) — no enum added. PENDING→POSTED reservation mirrors `request_redemption`/`fulfill_redemption`; permitted by `trg_bonus_ledger_immutable` (old row is PENDING). Original rows never mutated; corrections only via REVERSAL.

## 11. Lot Allocation
DIVERGENCE (documented, not blocking): 16.4 §11 assumed `bonus_allocate_spend` reuse, but working-tree 0018 hard-gates it to REDEEM_PRODUCT/CASH_WITHDRAWAL. Resolved inside 0020 scope: inline walk with identical oldest-first/remainder/shortfall semantics via existing `bonus_credit_remaining()`, plus narrow-only filter (`allow_discount` rule gate; MONETARY restriction under MONETARY_ONLY; rule-less opening/legacy credits eligible under ALL). 0018 unmodified. Allocations land in `bonus_earn_allocations` — no parallel table.

## 12. Policy Snapshot
`discount_policy_v1` JSON in `notes`: version, allow_zero/funding/cancel/limits in force, accounting null-marker, order/requested/available/applied totals. Storage choice (notes text) is the 16.5-deferred build decision, now fixed and documented.

## 13. Reversal
`cancel_order_discount` (client-owner or director; delivered orders rejected): replay guard → one-effective-reversal guard (mirrors `reverse_bonus_txn`) → snapshot mode must be AUTOMATIC_REVERSAL (MANUAL-era rows raise) → full-amount POSTED REVERSAL with `reverses_id` → `REVERSAL` audit with reason. `reverse_bonus_txn` itself untouched (director-only; not reused).

## 14. Audit
`bonus_audit_trail` only; actions follow UPPER_SNAKE convention (`DISCOUNT_APPLY` new-in-style, `REVERSAL` exact reuse with `kind:ORDER_DISCOUNT` marker). Rejections surface as RPC errors (rolled back, hence unauditable — same as existing code). Replays write no audit row (matches `reverse_bonus_txn` precedent).

## 15. RLS / Grants / Security
New functions: SECURITY DEFINER + fixed `search_path=public` + EXECUTE to `authenticated` (exact 0018 convention); authorization lives in-function (client-only apply; owner-or-director cancel; ownership checks). RLS untouched; no client INSERT/UPDATE path to ledger or allocations created.

## 16. Free-Y Isolation
`order_items.unit_price`/`is_bonus`/`bonus_rule_id` never read or written; discount is ledger+allocations only. Coexistence (discounted paid lines + free lines) changes neither path.

## 17. Invoice Boundary
`branch_allocate_order`, `createInvoice`, invoice sheet untouched — FOLLOW-UP AFTER 0020 retained. No inconsistency introduced: allocate snapshots exactly what it snapshots today; discount is a separate pre-allocate ledger entry. No IMPLEMENTATION BLOCKER.

## 18. Tenant Gap
CURRENT GAP: Tenant architecture is not currently represented in the repository (zero `tenant` hits; no company discriminator). Nothing fabricated: no tenant tables/columns/isolation layer; global keys implement product defaults and accept future per-tenant rows without redesign.

## 19. Static Validation
No live DB, no `db push`/`migration up`/SQL execution (per gate). Python structural check: 17/17 PASS (dollar balance, 2 functions, definer×2, search_path×2, grant coverage, no create/alter/drop/delete, no orders/settings updates, no tenant/GL fabrication, no existing-RPC redefinition, ORDER_DISCOUNT usage, key formats, snapshot version, 6 seed keys, conflict guard). Full file re-read completed (§21 source). No local Postgres exists and `0015` needs Supabase `storage` schema, so scratch-DB execution was not possible — stated, not substituted.

## 20. Test Results
No live-DB tests executed (forbidden). Static checks §19 pass. Flutter/Web suites untouched by this phase (no app files changed); no test run required for a local-only SQL artifact. Execution-against-staging remains future work after owner approval.

## 21. Requirement Compliance Matrix
| Requirement | Implemented? | Evidence |
|---|---|---|
| D1 REQUIRE_POSITIVE | YES | 0020:222-224 + seed false |
| D2 ALL_ELIGIBLE | YES | 0020:151-154, 261-271 + seed |
| Override NARROW_ONLY | YES | 0020:268-270 (filter can only exclude) |
| D3 AUTO_REVERSAL | YES | cancel fn 0020:311-406 + seed; snapshot-gated 377-387 |
| D4 boundary (neutral) | YES | no GL objects; snapshot accounting null (231-244) |
| D5 no cap | YES | null seeds; min() folds caps only when configured (211-217) |
| D6 no minimum | YES | null seed; floor only when configured (225-227) |
| D8 snapshot | YES | discount_policy_v1 in notes; cancel parses debit snapshot |
| Idempotency | YES | DISCOUNT:/REVERSAL: keys + UNIQUE + replay returns |
| Lot allocation | YES | inline oldest-first + remainder + shortfall via bonus_credit_remaining |
| Audit | YES | DISCOUNT_APPLY / REVERSAL rows |
| RLS/security | YES | definer+search_path+grants+in-function checks; RLS untouched |
| Free-Y isolation | YES | no order_items contact |
| Invoice boundary | YES | allocate/createInvoice untouched; follow-up retained |
| No 0017/18/19 touch | YES | git diff: phase adds 0020 + this report only |

## 22. Known Gaps
Scratch-DB execution impossible here (no Postgres binaries; storage-schema dependency) — mitigated by 17 static checks + full re-read. `jsonb → text → boolean/numeric` casts follow standard PG semantics (no direct jsonb-scalar casts used). Null-role edge matches existing 0018 convention (authenticated callers carry users rows).

## 23. Blockers
None. Blueprint divergence (§11) resolved within allowed scope; invoice path verified non-contradictory; tenant gap documented, non-blocking.

## 24. Final Status
Migration created and self-reviewed locally; awaiting owner review before any apply decision. No application, Flutter, Web, Edge Function, RLS, grant, invoice, or live-database change made.

PHASE 17 STATUS:
MIGRATION 0020 CREATED LOCALLY — STATICALLY VERIFIED — NOT APPLIED
NO LIVE DATABASE CHANGES
