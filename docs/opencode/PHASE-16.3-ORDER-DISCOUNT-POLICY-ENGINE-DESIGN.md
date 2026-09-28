# PHASE 16.3 — ORDER DISCOUNT POLICY ENGINE DESIGN (design only — no code/SQL/DB changes)

## 1. Executive Summary
Discount policy must be configuration-driven, but only operational policy belongs to the director. Accounting treatment, security invariants, and ledger truth stay out of configurable reach. Recommended: extend `bonus_settings` (global keys) + per-rule fields on `bonus_rules_v2`, versioned application, audit-logged changes.

## 2. Repository Evidence
- Roles: web `ALLOWED_ROLE='company_director'` only (`AuthContext.tsx:8,54`); Flutter `UserRole{client,branch_manager,driver,companyDirector-blocked}` (`constants.dart:24`) — **no financial-admin role exists**.
- `bonus_settings(key PK, value jsonb, updated_by, updated_at)` + RLS (director manage / authenticated select) — existing extension point.
- `bonus_audit_trail(entity,entity_id,action,actor,at_time,old/new_value,reason,reference)` — covers who/what/old/new/reason; no version column.
- Order/invoice coupling and `createInvoice` bypass established in 16.1/16.2.

## 3. Current Architecture
Single order-creation RPC → branch allocation (invoice snapshot) → delivery; bonus earn at delivery; wallet/redemption/withdrawal connected; discount/GL absent.

## 4. Policy Categories
1. **Operational** (director-configurable): zero-order, funding scope, cancellation mode, limits. 2. **Rule-level** (per `bonus_rules_v2` row): eligibility/value/stacking mirrored for discount use. 3. **Financial/Accounting** (NOT director-configurable): liability vs revenue, breakage, GL mapping — owner: company accountant (no such role exists → GAP). 4. **Security** (immutable): RLS, definer RPCs, append-only ledger, idempotency.

## 5. D1 Policy Design
Key conceptually `discount.allow_zero_order` (boolean). Default: UNDECIDED (false = safer: rejects zero-total; requires explicit enable). Scope: Global only (branch/customer variance unjustified — no evidence for it). RPC enforces post-cap check.

## 6. D2 Policy Design
Conceptually `discount.funding_scope` ∈ {ANY_LOT, MONETARY_ONLY} + optional per-rule `allow_discount` gate (already exists on rules_v2). Trace via existing `rule_id`→lots chain; no new columns needed for ANY_LOT; MONETARY-only needs rule-type check at spend time.

## 7. D3 Policy Design
Conceptually `discount.cancellation_mode` ∈ {AUTO_REVERSAL, MANUAL_REVIEW}. Lifecycle matrix from 16.1 applies. Default: UNDECIDED.

## 8. D4 Accounting Policy Boundary
Accounting keys live under a separate namespace conceptually (`accounting.*`, owner: accountant role that does not exist → GAP documented). Director UI must not edit them. Required preserved data: amounts, links, timestamps, actors, policy version in effect (see §12).

## 9. Policy Precedence (proposed from repo reality)
Order constraints (cap = min(requested,total,available)) > Rule flags > Global settings > Defaults. Rationale: nothing in repo supports branch/customer-level overrides today (no branch settings table, no per-customer policy store); adding levels without stores would be fiction. Non-overrideable: ledger truth, RLS, append-only, idempotency.

## 10. Policy Storage Options
- A `bonus_settings`: fits (key/value + RLS + audit via updated_by/at), zero migration for keys; weakness: no versioning, flat namespace.
- B separate table: versioning natural; cost: new migration + RLS + UI.
- C per-rule fields: already exist for rule-scoped items.
- D hybrid (recommended): global keys in `bonus_settings` + rule flags in `bonus_rules_v2` + future version table only if audit needs grow. No implementation now.

## 11. Recommended Architecture
`bonus_settings` keys (`discount.*`) + rule flags + version snapshot copied into each discount ledger row's notes/reference + audit rows on settings change. Accounting namespace reserved, unwritten.

## 12. Versioning
Required: policy version + effective_from + active flag (discount applied under changing caps demands it). Mechanism (future): versioned settings rows or snapshot-in-ledger; current `updated_at` alone insufficient — documented gap, no build now.

## 13. Snapshot / Audit Requirements
Per discount: policy version/identifier, rule, requested/capped/applied amounts, available/total before, funding lots, cancellation mode in force. `bonus_audit_trail` covers who/what/old/new/reason; add version linkage at build time.

## 14. Director Permissions
Director reads/edits operational keys (existing RLS allows). Financial keys: no qualified role exists → GAP; do not widen director silently — needs explicit owner decision.

## 15. Financial Permissions
Same as §14: accountant role absent from codebase (only `company_director` enforced anywhere). FLAG: any financial-permission design must first resolve role existence.

## 16. createInvoice Interaction
Bypass confirmed (16.2). Future invariant candidate: invoice must reference order final total where order-linked; standalone manual invoices remain director prerogative with audit. No change now.

## 17. Order Discount Lifecycle
Created → eligibility/policy/funds checks → allocation → ledger POSTED → allocate → invoice → (cancel → mode-based compensation) — each boundary in-call atomic; cross-call consistency via idempotency key + status guards (future build).

## 18. Transaction Boundaries
Discount application atomic with its own RPC txn; never spans into allocate/invoice (separate calls, separate keys). Cross-boundary failure = pending/cancel states, never partial money movement (design constraint for build).

## 19. Failure Scenarios
Timeout→same-key retry; duplicate→UNIQUE guard; insufficient→reject pre-write; expired/suspended→reject pre-write; policy-changed-mid-flight→snapshot governs already-applied, fresh reads for new; invoice-failure→discount stands, reconciled via cancel path; allocation-failure→no ledger row (atomic); cancel-retry→idempotent reversal key; reversal-retry→same.

## 20. Security Model
Definer RPCs + fixed search_path (existing pattern); authenticated callers, director checks inside; RLS deny-by-default on writes; settings reads for authenticated, writes director-only. No new principals.

## 21. Migration Requirements — DESIGN ONLY
Future: settings keys (data, not schema), optional version table, optional `gl_entry_id`-style link columns — none created.

## 22. RPC Requirements — DESIGN ONLY
One discount-apply RPC + one cancel/compensation RPC reusing allocate/idempotency/audit patterns. No code written.

## 23. UI Requirements — DESIGN ONLY
Director: settings editor extension + discount review list. Client: checkout toggle + confirm + status. Read-only where backend lacks ops.

## 24. Open Business Decisions
D1 default, D2 scope, D3 mode, D4 full accounting treatment, accountant role existence, version-table need.

## 25. Open Technical Decisions
Snapshot field list finalization at build; `gl_entry_id`-style link timing (with bridge, not now).

## 26. Implementation Sequence
Decisions → accounts/roles → migration (settings keys + link columns if needed) → discount RPC → cancel path → checkout UI → director UI → verification protocol.

## 27. NO CODE / NO SQL / NO DATABASE CHANGES
This file is the only artifact. Nothing executed, migrated, or deployed.

## Decision table
| ID | Decision | Configurable? | Owner | Scope | Default | Override Allowed? | Audit Required? |
|---|---|---|---|---|---|---|---|
| D1 Zero Order | UNDECIDED | yes | director | Global | UNDECIDED | n/a | yes |
| D2 Funding Scope | UNDECIDED | yes | director | Global+rule | UNDECIDED | rule narrows only | yes |
| D3 Cancellation | UNDECIDED | yes | director | Global | UNDECIDED | n/a | yes |
| D4 Accounting Treatment | UNDECIDED | **no** | accountant (GAP: role absent) | System | UNDECIDED | no | yes |
| Discount Limit | UNDECIDED | yes | director | Global | UNDECIDED | n/a | yes |
| Minimum Discount | UNDECIDED | yes | director | Global | UNDECIDED | n/a | yes |
| Policy Precedence | decided above §9 | n/a | architect | System | n/a | no (invariants) | n/a |

## IMPLEMENTATION STATUS
**DESIGN ONLY — NO CODE — NO SQL — NO DB CHANGES**
