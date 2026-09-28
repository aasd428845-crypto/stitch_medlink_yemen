# PHASE 16.7 — PRODUCT-SALE DECISION LOCK & MIGRATION 0020 GATE (lock only — no code/SQL/DB changes)

## 1. Executive Summary
Product-sale defaults are locked as global product defaults, each tenant-configurable where the 16.5 contract allows: D1 REQUIRE_POSITIVE_REMAINING, D2 ALL_ELIGIBLE_LOTS, override NARROW_ONLY, D3 AUTOMATIC_REVERSAL, D4 tenant financial configuration (no value locked), D5 NO_ADDITIONAL_POLICY_CAP, D6 NO_MINIMUM, D7 tenant-specific financial owner (not built), D8 snapshot-at-discount-time. No conflict with the 16.5 contract (it left values UNDECIDED for the owner; this phase records the owner's lock). One architectural gap: no tenant infrastructure exists — settings are global today. No blocker for Migration 0020 design; `createInvoice` stays FOLLOW-UP AFTER 0020.

## 2. Product-Sale Model
PRODUCT MODEL = MULTI-TENANT COMMERCIAL PRODUCT. No single company's business policy is hard-coded: every locked value below is a PRODUCT DEFAULT shipped in configuration, overridable per tenant wherever the contract marks "Tenant Configurable = YES". Tenant-specific storage does not exist yet (see §5 gap) — until it does, the product default is also the effective value, changed only through the same audited configuration path, never by code edit or redeploy. Financial decisions stay under financial-owner control per tenant; the operational director never inherits them by default.

## 3. Sources Inspected
PHASE-16, 16.1, 16.2, 16.3, 16.4, 16.5, 16.6 (local, read in full). Code verification this phase: `0018:22-32` (`bonus_accounts` per-user, YER), `0018:282-310` (settings global KV, director-manage RLS, conservative-disabled seed keys), `0018:58` (`ORDER_DISCOUNT` type), `0018:143` (`allow_discount`), `0018:525-544` (oldest-first allocation), `0016:128-148` (allocate-then-invoice snapshot), `branch_service.dart:508` / `branch_controller.dart:216` / sheet `:55` (manual invoice path), `AuthContext.tsx:8,54` (sole role). Full-text search for `tenant` across migrations + auth + constants: zero hits. No `company_id`/`tenant_id` column in any bonus object. CONTRACT / CODE DIVERGENCE: none. CONTRACT CONFLICT with 16.5: none (see §4).

## 4. D1 Final Product Decision
D1 = REQUIRE_POSITIVE_REMAINING (product default). Applied discount must remain strictly below the order total; full-cover requests are rejected or capped below total inside the future RPC's post-cap check. This is a PRODUCT DEFAULT, not an invariant: the chain is PRODUCT DEFAULT → TENANT CONFIGURATION (`discount.allow_zero_order`) → ORDER EXECUTION, so a tenant may later enable zero-cover through audited configuration where its business requires it. Consistent with 16.5 (scope Global, boolean key, default UNDECIDED-for-owner — now locked by owner) and with the codebase's conservative-default precedent (seed keys ship disabled: `0018:303-307`). No contract conflict.

## 5. D2 Final Product Decision
D2 = ALL_ELIGIBLE_LOTS (product default). Discount may draw on any eligible bonus lot under system rules — never MONETARY-only at product level. Respected unchanged: `bonus_earn_allocations` attribution, existing oldest-first walk, ledger integrity, lot availability (balance/expiry/suspension), existing redemption/withdrawal competition (shared pool, ledger truth governs), rule eligibility (`allow_discount` gate + status/window/customer filters). Tenant-configurable to MONETARY_ONLY via `discount.funding_scope` where desired. Consistent with 16.5 §6 (both scopes implementable; D2-C recorded there as not-a-global-value). No contract conflict. ARCHITECTURAL GAP (tenant): lots/accounts/rules carry no tenant discriminator — per-user accounts (`user_id` PK) isolate customers within today's single-company schema, but nothing isolates Company A from Company B because no second-company construct exists. Documented, not built.

## 6. D2 Override Contract
OVERRIDE MODEL = NARROW_ONLY (invariant, carried from 16.5 §7 and 16.6 §7 ALREADY CONTRACTED). Global policy sets the upper boundary; rule policy restricts inside it; a rule never widens global (Global MONETARY_ONLY × rule allow-PRODUCT ⇒ excluded; Global ALL × rule disallow ⇒ excluded; invalid combos resolve to exclusion). Migration 0020 must implement this direction with no widening path. Tenant Configurable: NO — the direction itself is product architecture, not policy.

## 7. D3 Final Product Decision
D3 = AUTOMATIC_REVERSAL (product default). On cancellation of a discounted order: a compensating REVERSAL row is created against the original ORDER_DISCOUNT debit via `reverses_id` (existing `reverse_bonus_txn` pattern); the POSTED original is never edited; an audit entry is written; lot attribution remainders recompute through existing credit-remaining logic; idempotency keys govern retries (`DISCOUNT:{order_id}` family / reversal key per 16.4 design); no bonus is created from nothing (reversal amount ≤ original applied amount; later competing spends already posted stand under ledger ordering). Governing policy is the SNAPSHOT captured at discount time (§12), never the current global — a Day-1 AUTO discount cancelled under a Day-5 MANUAL tenant policy still auto-reverses. Tenant-configurable to MANUAL_REVIEW via `discount.cancellation_mode`.

## 8. D4 Financial Configuration Boundary
D4 = TENANT FINANCIAL CONFIGURATION under FINANCIAL OWNER CONTROL. Neither CUSTOMER_OBLIGATION_SETTLEMENT nor REVENUE_REDUCTION is adopted as a product-global policy — a commercial product cannot impose one accounting substance on all tenants. The identifier (`accounting.discount_treatment`, reserved namespace) is set per tenant, versioned, effective-dated, and approval-gated when that tenant's finance ownership exists. The operational director cannot change it without explicit financial authority in the future role model; until then the director surface renders it hidden or read-only. Migration 0020 stays accounting-neutral: it records amount, links, timestamps, actor, and snapshot (consumable by a future GL bridge) and posts no GL interpretation. FINANCIAL OWNERSHIP GAP: no finance role exists in code (sole enforced role `company_director`); no role created here.

## 9. D5 Final Product Decision
D5 = NO_ADDITIONAL_POLICY_CAP (product default). No `max_amount`/`max_percent` is shipped in 0020 (keys remain null = absent). The discount is still bounded by three hard caps: requested amount, order total, available eligible bonus (`applied = min(requested, total, available)`), then the D1 positive-remaining check. A tenant may later add amount/percent caps through configuration (effective cap = min of the two when both present, per 16.5 §10). Nothing in the contract requires a cap to exist; silence here is the explicit "none" state the RPC implements.

## 10. D6 Final Product Decision
D6 = NO_MINIMUM (product default). No commercial floor on the applied discount amount is shipped (`discount.min_amount` null = absent). Order constraints, available bonus, eligibility, and the D1 zero-order rule still apply to every discount. A tenant may later set a floor through configuration. Minimum order amount and minimum remaining amount are not introduced (out of scope unless a tenant-owner requests them).

## 11. D7 Financial Ownership Model
D7 = FINANCIAL OWNER IS TENANT-SPECIFIC. Each company using the product designates its own financial authority under its own permission model; the product ships no global finance principal. CURRENT CODE GAP: Financial Owner role is not currently represented (verified: `AuthContext.tsx` enforces `company_director` only; Flutter mirrors the same role set). No role created, no permission changed, `AuthContext` untouched. Consequence: D4 values and any GL bridge stay blocked per tenant until that tenant's ownership is designated outside this codebase phase.

## 12. D8 Snapshot Contract
D8 = POLICY SNAPSHOT AT DISCOUNT TIME (invariant, carried from 16.5 §8 / 16.6 §13 ALREADY CONTRACTED). Each discount transaction is bound to the policy in force at application: funding scope, zero-order flag, cancellation mode, max/min values, rule set, and (once decided) accounting identifier/version. Later company policy changes never reinterpret old transactions — this governs cancellation, reversal, funding-scope disputes, zero-order behavior, limits, and future accounting posting alike. Storage location (ledger `notes`/`reference` JSONB vs dedicated columns) is a 0020 implementation detail within this invariant.

## 13. Product Defaults Table
| ID | Product Default | Tenant Configurable | Financial Owner Required |
|---|---|---|---|
| D1 | REQUIRE_POSITIVE_REMAINING | YES | NO |
| D2 | ALL_ELIGIBLE_LOTS | YES | NO |
| D2 Override | NARROW_ONLY | NO | NO |
| D3 | AUTOMATIC_REVERSAL | YES | NO |
| D4 | TENANT FINANCIAL CONFIGURATION | YES | YES |
| D5 | NO_ADDITIONAL_POLICY_CAP | YES | NO |
| D6 | NO_MINIMUM | YES | NO |
| D7 | TENANT-SPECIFIC FINANCIAL OWNER | YES | YES |
| D8 | SNAPSHOT_AT_DISCOUNT_TIME | NO | NO |

## 14. Tenant Configuration Boundary
Tenant-configurable (operational, director-level within a tenant once multi-tenancy exists): D1 flag, D2 scope, D3 mode, D5 caps, D6 floor — each versioned, effective-dated, audited (who/what/old/new/reason). Tenant-configurable under financial owner only: D4 treatment. Never tenant-configurable (NON-CONFIGURABLE, §15): isolation, ledger truth, allocation integrity, idempotency, audit append-only. Because no tenant store exists today, these boundaries are contractual for 0020's design (global keys implement the product defaults; per-tenant rows/columns are a later architecture extension), not schema built now.

## 15. Tenant Isolation Invariants
TENANT ISOLATION IS NON-CONFIGURABLE. No commercial setting — present or future — may disable, bypass, or weaken: order/account ownership checks; RLS policies; ledger isolation (one account's lots never fund another account's discount); account isolation; rule isolation (a tenant's rules never qualify another tenant's lots); audit isolation (a tenant's administrators never rewrite another tenant's trail). Migration 0020 must add only additive, same-isolation objects; any future tenant discriminator must default-deny across tenants. Theoretical cross-tenant hazards that 0020 must not introduce: reading another tenant's settings; spending another tenant's bonus; applying another tenant's rule; reusing another tenant's policy snapshot; posting a reversal to another company's account; cross-tenant ledger allocation rows. None are possible today (single-company schema) and none may become possible by accident.

## 16. Free-Y Isolation
Financial Bonus and legacy Free-Y stay fully separate: `order_items.bonus_rule_id` / `is_bonus` lines remain the Free-Y representation (price forced 0 at creation); the discount path must never read, write, or reinterpret those columns. Discount lots and free units never mix in allocation, ledger, or audit; verification must assert both can coexist on one order (discounted paid lines + free lines) without either path acknowledging the other.

## 17. Ledger Invariants
`bonus_ledger` = financial source of truth; `bonus_earn_allocations` = lot attribution. Order Discount reuses both responsibilities unchanged: one POSTED ORDER_DISCOUNT debit (+ optional PENDING reservation per final RPC design) per discount, allocation rows per funding lot, compensating REVERSAL linked by `reverses_id` on cancel. No new ledger architecture, no direct client writes, no POSTED mutation, no idempotency weakening.

## 18. Invoice Boundary
Carried from 16.5: createInvoice remediation = FOLLOW-UP AFTER 0020. Migration 0020 readiness check: no IMPLEMENTATION BLOCKER found. Reason: the locked design applies discount before `branch_allocate_order`, so the allocate path snapshots the already-discounted order state and invoice/ledger cannot contradict through that path; the standalone manual `createInvoice` path writes invoices disconnected from orders by construction and therefore neither contradicts nor confirms any discount — it is untouched scope, not a contradiction 0020 introduces. Future invariant (unchanged): an order-linked invoice must correspond to the order's final discounted total; standalone manual billing stays permissible only when not linked to a discounted order, with audit. No file touched here.

## 19. Migration 0020 Readiness
D1 = LOCKED (REQUIRE_POSITIVE_REMAINING). D2 = LOCKED (ALL_ELIGIBLE_LOTS). D3 = LOCKED (AUTOMATIC_REVERSAL). D5 = LOCKED (NO_ADDITIONAL_POLICY_CAP). D6 = LOCKED (NO_MINIMUM). D8 = LOCKED (SNAPSHOT_AT_DISCOUNT_TIME). D2-override = LOCKED invariant (NARROW_ONLY). D4 = TENANT FINANCIAL CONFIGURATION (not a fixed value; 0020 proceeds accounting-neutral). D7 = TENANT-SPECIFIC FINANCIAL OWNER (not built; blocks only D4/GL, not discount core). All 16.6 gate items requiring business values are now satisfied at product-default level; tenant overrides remain future configuration, not 0020 schema.

## 20. Final Gate
No architectural blocker found: single-tenant schema is today's reality (gap documented, not blocking — product defaults ship globally and become tenant rows when tenancy lands); invoice interaction verified non-contradictory; all invariants reusable without touching 0017/0018/0019.

PHASE 16.7 STATUS:
PRODUCT-SALE DECISIONS LOCKED — READY FOR MIGRATION 0020 DESIGN/IMPLEMENTATION
NO CODE — NO SQL — NO DATABASE CHANGES
