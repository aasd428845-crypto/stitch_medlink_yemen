# PHASE 16.5 — FINAL ORDER DISCOUNT CONFIGURATION CONTRACT (contract only — no code/SQL/DB changes)

## 1. Executive Summary
Order Discount becomes configuration-driven in exactly two places: global operational keys in `bonus_settings` and per-rule flags on `bonus_rules_v2`. Accounting treatment is excluded from director configuration (owner absent — GAP). Security/integrity rules are immutable. All business values (D1–D4, limits) stay UNDECIDED; the contract fixes names, scopes, precedence, versioning, and snapshot shape so a future Migration 0020 can execute without inventing business rules. Key code finding: ledger `txn_type` already includes `'ORDER_DISCOUNT'` and rules already carry `allow_discount` — no new enum/flag strictly required for the base path.

## 2. Sources Inspected
Reports (local, read in full): PHASE-16, 16.1, 16.2, 16.3, 16.4. Schema/code (local, read): `supabase/migrations/0018_bonus_financial_system.sql` (settings:285-290, rules:118-152, ledger:53-75, audit:313-324, alloc:357-368, allocate loop:525-544); `0017_bonus_order_integrity_and_analytics.sql` (order create/total); `0016_bonus_inventory_allocation_safety.sql` (allocate+invoice snapshot:128-148); `0019_bonus_earn_engine.sql`; migration list (latest = 0019, so next = 0020); `medlink_app/lib/services/branch_service.dart:508`, `branch_controller.dart:216`, `branch_invoice_create_sheet.dart:55`; `AuthContext.tsx:8,54`; `constants.dart:38,54`.

## 3. Current Architecture Evidence
- Order total is server-computed (`v_total` = paid qty × server price, bonus lines excluded) and stored at insert — discount base is stored `orders.total_amount`, never client-sent.
- Allocation/invoice coupling: `branch_allocate_order` snapshots order total into `invoices` at allocation (`0016:145-148`) — hence discount-before-allocate ordering is locked.
- Spend primitive `bonus_allocate_spend` walks oldest-first (`ORDER BY created_at, id`, remainder-capped, shortfall exception) — lot ordering is resolved, reused verbatim.
- Ledger is guarded (CHECK types, `amount <> 0`, UNIQUE idempotency_key, `reverses_id` self-FK); allocation rows are UNIQUE(debit,credit) with cascade on debit — reversal/allocation integrity primitives exist.
- `bonus_settings(key PK, value jsonb, updated_by, updated_at)` with authenticated-select RLS is the existing global KV store; `bonus_rules_v2` already has `rule_type` (PRODUCT/MONETARY/GENERAL), `allow_discount`, `cash_min/max`, stackability — rule-level gate + monetary tracing both derivable.
- Roles: only `company_director` is enforced anywhere (web gate + Flutter enum); no accountant/financial role exists in code.
- Bypass: `createInvoice` writes `invoices` with a hand-entered amount via controller from the invoice sheet — disconnected from orders by construction.

## 4. Configuration Principles
1. Least scope: Global + Rule only; no Branch/Customer/Order policy stores exist, so no such levels are introduced.
2. Narrow-only override: a lower level may restrict, never widen, a higher level unless explicitly permitted (none permitted in this contract).
3. Policy permits; ledger decides: every configurable value is validated against immutable financial guards server-side.
4. No retroactivity: the policy in force at discount time governs that discount forever (snapshot), regardless of later edits.
5. Accounting and security are not settings: D4 lives outside director reach; invariants are not configurable at any level.

## 5. D1 Contract
- Setting key (namespace per 16.4 convention, snake_case + dotted scope): `discount.allow_zero_order` — Type: boolean. Allowed: `true` (ALLOW_ZERO) / `false` (REQUIRE_POSITIVE_REMAINING). Meaning: whether applied discount may equal the full order total.
- Enforcement point (future): post-cap check inside discount RPC — `applied < total` when false; `applied <= total` when true. No item-price change.
- Default: UNDECIDED (business decision; technical fail-safe leans false but is NOT adopted without owner approval).
- Scope: Global only. Branch/Rule/Order variance rejected: no backing store, no business case evidenced, per-order variance would be a financial hole.

## 6. D2 Contract
- Global key: `discount.funding_scope` — Type: text enum. Allowed: `ALL_ELIGIBLE_LOTS` / `MONETARY_ONLY`. (`RULE_CONTROLLED` is not a third global value; rule control is the separate rule flag below.)
- Rule flag: existing `bonus_rules_v2.allow_discount` (boolean, default false in schema) is the rule-level gate — reused, no new column required. Monetary derivation uses existing `rule_type` via EARN `rule_id` links at spend-filter time.
- Precedence: Order caps (total/available) > Rule gate (`allow_discount=false` excludes lots from that rule) > Global scope > safe default. Combination matrix:
  - Global ALL + Rule allow → lot eligible (subject to balance/expiry/suspension).
  - Global ALL + Rule disallow → lot excluded (rule narrows).
  - Global MONETARY_ONLY + Rule allow + rule is MONETARY → eligible; rule is PRODUCT/GENERAL → excluded.
  - Global MONETARY_ONLY + Rule allow(PRODUCT) → still excluded: rule NEVER widens global. Invalid combination = treated as excluded, never as exception-to-widen.
- Filter timing: during lot selection (inside allocation walk), not after — ineligible lots are never written to `bonus_earn_allocations`, preserving traceability (every allocation row links debit→credit→rule implicitly via credit's `rule_id`).

## 7. Override Rule (locked)
Model adopted: **Model C with narrow-only semantics** — Global sets the upper boundary; Rule sets detail strictly inside it; Order contributes only hard constraints (total, availability), never policy preference. Model A (full override) rejected: would let a rule silently re-open a globally closed funding source. Model B alone rejected as underspecified: C states both the boundary and the direction. No widening override is permitted anywhere in this contract.

## 8. D3 Contract
- Global key: `discount.cancellation_mode` — Type: text enum. Allowed: `AUTOMATIC_REVERSAL` / `MANUAL_REVIEW`.
- Scope: Global only (per-order mode shopping would let callers pick their own refund behavior — rejected as financial risk; per-rule mode has no evidenced use case).
- Temporal rule (locked): **snapshot governs**. The `cancellation_mode` captured at discount time controls that discount's cancellation forever. Rationale: Day-1 AUTO discounts cancelled on Day-6 under Day-5 MANUAL policy must still auto-reverse; reinterpreting old money under new policy breaks auditability. Current-policy reads apply only to discounts created after the change.
- Mechanics: AUTO path = compensating REVERSAL row linked via `reverses_id` to the original ORDER_DISCOUNT debit (+ allocation remainder recomputed by existing `bonus_credit_remaining` logic); MANUAL path = status guard blocking auto-compensation, leaving settlement to an audited admin action. Pre-allocation cancel is trivially safe under either mode (no fulfillment side effects yet).

## 9. D4 Accounting Boundary
- Concept identifier (reserved, NOT a director setting): `accounting.discount_treatment` ∈ {`CUSTOMER_OBLIGATION_SETTLEMENT`, `REVENUE_REDUCTION`} — value stays UNDECIDED — FINANCIAL OWNER REQUIRED.
- FINANCIAL OWNERSHIP GAP: no accountant/finance role exists in the codebase (verified §3); therefore no owner, no editor, no UI, and no default are assigned in this contract.
- Future home: separate `accounting.*` namespace (not `discount.*`), owned by a finance principal that does not yet exist; requires effective-date + version + explicit approval at build time. Director UI must render it read-only or hidden — never editable.
- Snapshot requirement: the treatment identifier/version in force (once decided) must be captured per discount transaction so the future GL bridge can post correctly; until decided, the snapshot field is reserved but unwritten.

## 10. Discount Limits Contract
- Three distinct caps (never conflated): (a) Order-total cap = `orders.total_amount` (hard, structural); (b) Available-bonus cap = `bonus_account_funds` minus in-flight locks (hard, ledger-derived); (c) Policy cap = configurable maximum (soft, director-owned).
- Policy keys: `discount.max_amount` (numeric, nullable = no policy cap) and optionally `discount.max_percent` (numeric 0–100, nullable). Both or either may exist; when both exist the effective policy cap is their minimum. Minimum: `discount.min_amount` (numeric, nullable) — rejected below this amount (distinct from minimum order amount and minimum remaining amount; those two are NOT introduced — documented as out of scope unless owner requests).
- Conceptual result (no values fixed): `applied = min(requested, order_total, available_bonus, policy_max)` then D1 zero-check then `min_amount` floor-check.
- Interaction example (illustrative only, not adopted behavior): total 1000 / available 800 / policy-max 500 / requested 900 → candidate 500, subject to D1/min gates.

## 11. Policy Precedence (final, per setting)
Order constraints > Rule configuration > Global operational policy > System safe default. Per-setting matrix:
- Zero-order: Global source `discount.allow_zero_order`; Rule source none; Order constraint `applied vs total`; Default UNDECIDED; overrides: none permitted.
- Funding scope: Global `discount.funding_scope`; Rule `allow_discount` (+`rule_type` derivation); Order caps; Default UNDECIDED; Rule may narrow only.
- Cancellation: Global `discount.cancellation_mode`; Rule none; Order status/age constraints; Default UNDECIDED; snapshot (not current) governs old rows.
- Max/min: Global `discount.max_*`/`min_amount`; Rule `cash_max`-style per-rule ceiling where semantically mapped at build (no new rule column decided here); Order caps dominate; Default none (null = no cap) pending owner.
- Precedence itself and all invariants: not overrideable by anyone.

## 12. Defaults
- Technical defaults (adopted for compatibility/safety): missing global key = most restrictive safe behavior — zero disallowed-equivalent (reject full-cover until owner enables), funding = effectively ALL_ELIGIBLE_LOTS only insofar as existing allocation already behaves that way (no behavior change), cancellation = no auto-compensation without explicit mode (block + require review until owner picks). These preserve current behavior (no discount path exists today) and are compatibility statements, not business choices.
- Business defaults: D1 value, D2 scope, D3 mode, D4 treatment, max/min numbers — all UNDECIDED, owner-required. No invented numbers appear in this contract.

## 13. Versioning
Required: every policy change creates a new version — fields conceptually `version, effective_from, effective_to, active, created_by/updated_by`. Current `bonus_settings.updated_at` alone is insufficient (single-row overwrite loses history — documented gap). Mechanism deferred to Migration 0020 design (versioned settings rows vs history table), but the contract mandates: (a) immutable history, (b) exactly one active version per key, (c) `effective_from` set at write time, (d) old discounts never reinterpreted.

## 14. Snapshot (minimum required per discount)
Per applied discount, captured atomically with the ledger insert: policy version/identifier in force; `funding_scope` value used; `allow_zero_order` value used; `cancellation_mode` value used; max/min values used; `rule_id`(s) of funding lots; requested / policy-capped / available / applied amounts; order total before/after; funding lot list (via `bonus_earn_allocations` rows, not duplicated); timestamp + actor. Storage location deferred to build (ledger `notes`/`reference` JSONB vs dedicated columns) — decision at Migration 0020 time, not here. Anything less breaks future audit/GL; anything more is optional.

## 15. Rule-level Configuration
Reuse-first: `allow_discount` (gate), `rule_type` (monetary derivation), `cash_max`/`cash_monthly_limit` (per-rule ceiling semantics precedent), `status/start/end/eligible_customers` (eligibility precedent). No new `bonus_rules_v2` column is mandated by this contract; if build proves a rule-specific discount ceiling distinct from cash semantics is needed, it is flagged then — not invented now.

## 16. Global Configuration
All five operational keys (`discount.allow_zero_order`, `discount.funding_scope`, `discount.cancellation_mode`, `discount.max_amount`, `discount.max_percent`, `discount.min_amount`) fit `bonus_settings` KV + JSONB: scalar values, no indexing/querying need, validation at RPC read-time, audit via `updated_by/at` + `bonus_audit_trail`. Typed-column alternative rejected for these: adds migration surface with no query/index benefit. Versioning (when built) sits beside — not inside — the KV row.

## 17. Director Configuration Boundary
Future Director UI (not built): Order Discount Policy section with enable/state display, zero-order toggle, funding-scope select, cancellation-mode select, max/min numeric inputs — each with type/allowed-values validation, explicit confirmation for tightening/loosening, and mandatory audit row (who/what/old/new/reason). Accounting treatment: hidden or read-only with financial-sensitivity banner. No settings beyond the keys above may appear without a contract amendment.

## 18. Financial Ownership Boundary
Director may change: the six operational keys above (§16). Finance owner (once role exists) owns: `accounting.*` treatment, effective dates, approvals. System (no human may change): server-side calculation, ownership checks, RLS, definer/search_path, POSTED immutability, idempotency, allocation/reversal integrity, audit append-only, no direct client ledger writes. GAP — FINANCIAL OWNER NOT REPRESENTED IN CURRENT ROLE MODEL: no finance role is created, assigned, or assumed here.

## 19. Security / Integrity Invariants (non-configurable)
Server-side amount recomputation; order-ownership validation; RLS deny-by-default on writes (all writes via SECURITY DEFINER RPCs with fixed `search_path`); immutable POSTED ledger (corrections only via linked REVERSAL); UNIQUE idempotency; allocation integrity (remainder-capped, shortfall-raising); reversal integrity (one compensation per original pattern); append-only audit; no client ledger/allocation writes. Policy values are inputs to — never substitutes for — these guards.

## 20. Backward Compatibility
With no discount keys present, behavior is unchanged: existing orders, Free-Y lines (`bonus_rule_id` path), redemptions, withdrawals, and invoices behave exactly as today. Migration 0020 must be purely additive (new keys default-absent = restrictive-safe; new RPCs uncalled by existing flows; no CHECK tightening on existing columns; no RLS reduction). Existing rows are never backfilled with discount data.

## 21. Final Configuration Contract Table
| Setting | Scope | Type | Allowed Values | Default | Owner | Rule Override | Order Override | Versioned | Snapshotted | Audit |
|---|---|---|---|---|---|---|---|---|---|---|
| zero-order policy (`discount.allow_zero_order`) | Global | boolean | true/false | UNDECIDED | director (operational) | no | constraint only (applied vs total) | yes | yes | yes |
| funding scope (`discount.funding_scope`) | Global+Rule | enum + rule flag | ALL_ELIGIBLE_LOTS/MONETARY_ONLY × `allow_discount` | UNDECIDED | director (operational) | narrow only | caps only | yes | yes | yes |
| cancellation policy (`discount.cancellation_mode`) | Global | enum | AUTOMATIC_REVERSAL/MANUAL_REVIEW | UNDECIDED | director (operational) | no | status constraints only | yes | yes (snapshot governs) | yes |
| maximum discount (`discount.max_amount`, `discount.max_percent`) | Global | numeric(12,2)/numeric(5,2) nullable | amount ≥ 0 / 0–100 | UNDECIDED (null = no cap pending owner) | director (operational) | narrow only (if mapped) | caps dominate | yes | yes | yes |
| minimum discount (`discount.min_amount`) | Global | numeric(12,2) nullable | ≥ 0 | UNDECIDED | director (operational) | no | n/a | yes | yes | yes |
| accounting treatment (`accounting.discount_treatment`) | System | enum (reserved) | CUSTOMER_OBLIGATION_SETTLEMENT/REVENUE_REDUCTION | UNDECIDED — FINANCIAL OWNER REQUIRED | GAP (no finance role) | no | no | yes | reserved | yes |
| policy precedence (§11) | System | rule | Order > Rule > Global > Default | locked as stated | architect | no (invariants) | n/a | n/a | n/a | n/a |

## 22. Business Decisions Required
D1 zero value, D2 scope, D3 mode, D4 treatment + financial-ownership assignment, max/min numbers — all UNDECIDED and owner-gated. D1–D3 are convertible to configuration without picking values today (keys + enforcement points are fully specified above); D4 is not convertible to a director setting under any circumstance.

## 23. Migration 0020 Contract (for the future implementer — NOT executed)
- Tables: no existing table altered in structure except additive objects; `bonus_settings` receives data keys only; optional version-history object only if §13 mechanism requires it; optional discount↔order link column only if join-via-`ledger.order_id` proves insufficient (prefer join).
- Columns/constraints/indexes: none mandated now; any new UNIQUE (idempotency `DISCOUNT:{order_id}` enforcement) rides on the existing `idempotency_key` UNIQUE — no new index presumed.
- RPCs (future): one apply RPC + one cancel/compensation RPC reusing `bonus_allocate_spend` / `reverse_bonus_txn` / audit patterns, definer + fixed search_path + authenticated grants + in-RPC director/owner checks.
- Grants/RLS: additive EXECUTE only; no existing policy weakened; settings writes stay director-gated.
- Audit: apply/cancel/policy-change rows in `bonus_audit_trail` with snapshot references; no table alteration.
- Compatibility: zero behavior change when keys absent (§20).

## 24. Implementation Readiness
READY (technically finalizable without owner): key names, scopes, types, precedence, narrow-only rule, snapshot-governs-cancellation, versioning/snapshot shape, storage choice, security boundaries, compatibility rule. BLOCKED: all D1–D4 values + max/min numbers + finance-role existence. BUSINESS DECISION REQUIRED: D1, D2, D3, D4, limits, financial ownership. Migration 0020 design may be drafted against this contract but must ship with UNDECIDED values unresolved — RPC must read policy, never hard-code it.

## 25. Final Gate
- ARCHITECTURAL FLAG: none new. Prior flags carried forward unchanged: manual-amount `createInvoice` bypass (`branch_service.dart:508` + sheet `:55`); absent finance role; no staging environment. None block contract completion; `createInvoice` handling is classified FOLLOW-UP AFTER 0020 (standalone manual billing is a live production path — it must be gated/reconciled, but gating it is not a precondition for building the order-linked discount RPC, which existing order flows will call before allocate).
- createInvoice constraint (future invariant): an order-linked invoice must correspond to the order's final discounted total; standalone manual invoices remain permissible only when not linked to a discounted order, with audit. Remediation file/function/point identified in §3; no change made here.

PHASE 16.5 STATUS:
CONFIGURATION CONTRACT COMPLETE — NO CODE — NO SQL — NO DATABASE CHANGES

NEXT PHASE:
PHASE 17 / MIGRATION 0020 IMPLEMENTATION — gated on BUSINESS DECISION REQUIRED items above; the implementer must treat UNDECIDED values as blocking for those behaviors and must not invent defaults.
