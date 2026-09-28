# PHASE 22.3 — PRODUCT POLICY LOCK (read-only)

## 0. Authority
Locks the 22.2 recommendations as buildable product defaults: H1=B-NARROW, H2=A, H3=A. Sources: 22.1 (definitions/options), 22.2 (recommendations), 22 (backend design), 20/21/21.1 (integration + review), 0017–0020 + live code paths (cancel: `branch_order_actions.dart:159`; allocate/invoice: 0016:53/128-148; role gate 0020:334; no `order_id` on invoices; no tenant store). These are DEFAULTS FOR IMPLEMENTATION, not applied configuration — nothing is built or applied in this phase.

## 1. H1 LOCK — B-NARROW (owner-client cancel of own PENDING orders only)
- "Pending" is a FIXED safety condition (Security Invariant, §4): pending = pre-allocation, pre-invoice, pre-fulfillment — cancellation has zero operational side effects by construction. Client can NEVER cancel assigned / in_progress / delivered / already-cancelled (server state gate, non-overrideable).
- Discount + reversal impossible (e.g. MANUAL snapshot, pre-reversed, delivered): the operation FAILS CLOSED with explicit error + escalation — never cancel-without-settlement. Consistency with H3-A is deliberate: H1's client path inherits H3's posture.
- Atomicity: cancellation + compensating reversal in one RPC transaction; POSTED never touched; no stranded bonus/discount state permitted.
- No capability creep: holding a discount grants no wider states; branch/director powers unchanged.
- Future-configurable: cancellable states and eligible roles per company (operational key when tenancy exists). Invariant forever: ownership check, role check, state gate, atomic reversal-or-abort — all server-side from auth context, no client-supplied identity.

## 2. H2 LOCK — A, INDEPENDENT MANUAL INVOICE
- Why safe: zero schema/behavior change across unknown tenant histories; every current flow keeps working; the one-way structural step (linkage) is deferred to adopters. No linkage assumed, built, or implied anywhere.
- Honest boundary: TODAY nothing structural prevents a manager from hand-typing an order's amount into a manual invoice — A is policy + UI wording, not enforcement. Stated plainly so no later phase assumes a guard that doesn't exist. Mitigation track: director-level ledger-vs-invoices reconciliation (future read-only report), NOT fake app-side enforcement.
- Future company choice: YES — a company may adopt order-linked manual billing, but ONLY after: (1) `invoices.order_id` FK migration (+ fossil-table review, R1); (2) discount-aware computation rules for linked rows; (3) backfill policy (history has no links — new rows only). Until then linkage is not offered.
- H2 stays a company-operational choice; it becomes accounting-adjacent (needs financial-owner review) ONLY if a tenant's linkage carries revenue-recognition meaning. No Tenant System invented; no tenant branches in any rule.

## 3. H3 LOCK — A, FAIL-CLOSED + ESCALATION
- Fail-closed boundary: the RPC must refuse BEFORE any write when it cannot complete the full money-safe sequence (MANUAL snapshot, missing snapshot, pre-existing effective reversal, delivered state, undetectable discount state). No invented reversals, no POSTED mutation, no deletes, no success responses for incomplete work.
- Stop conditions (exact): snapshot mode ≠ AUTOMATIC_REVERSAL; snapshot unparsable/missing; effective reversal already present; order delivered; caller unauthorized. Each raises a distinct, announced error string.
- Required audit on abort AND success: actor (auth.uid), order, discount ledger id (if any), snapshot mode/version in force, reason, idempotency keys of both operations, failure cause on abort. Abort rows are audit-only (no ledger writes on failure paths).
- Future-configurable: posture per company (flag/queue machinery only for tenants that demand it). Invariant under ANY policy: snapshot-governs (never reinterpret history), POSTED immutability, one-effective-reversal, idempotent keys, full audit.

## 4. Product architecture (four layers, explicit)
1. Product Default (§1–§3): ships with the product when nothing is configured.
2. Tenant Configurable (future): H1 states/roles, H2 linkage adoption, H3 posture — per-company operational keys ONLY after real tenant configuration exists. No key names invented here to avoid speculative API.
3. Security Invariant (never overrideable by director, tenant, or policy): ownership/role/state gates; RLS deny-by-default; append-only POSTED ledger; snapshot-governs-history; one-effective-reversal; idempotency; auth from server context only.
4. Accounting Policy (never an operational setting): D4 treatment, GL mapping, revenue meaning of invoice linkage — financial-owner domain, absent role unchanged.

## 5. Critical compatibility audit (vs code + 0017–0020)
Checked each: `create_order_with_items` (untouched, pending entry intact); `apply_order_discount` (pending gate + keys reused as-is); `cancel_order_discount` (guards reused/duplicated by new RPC, never modified); `bonus_ledger` (CHECK/UNIQUE/trigger all relied upon, none altered); `bonus_earn_allocations` (allocation rows only read + fresh-credit compensation, never un-consumed); `bonus_credit_remaining` (remainder math reused); `branch_allocate_order` (pending gate + invoice computation point identified); cancel path (single branch path confirmed, no competing writer); invoice paths (both mapped, manual untouched); RLS (all gates preserved); idempotency (keys + constraints carry over); Free-Y (`bonus_rule_id`, 0017:12 — zero contact). NOTE on the prompt's term "`bonus_reversals`": no such table/function exists — reversals are `REVERSAL` rows in `bonus_ledger` linked by `reverses_id`; the lock uses that exact mechanism, and no new reversal store is created.
Scenarios: (1) POSTED immutability — trigger + compensation-only, all locks comply. (2) Compensating reversal — full-amount credit, fresh spendable lot, traceable chain. (3) Concurrent cancellation — order lock serializes; one winner. (4) Duplicate cancellation — guard + partial unique index; raise-or-replay. (5) Discount idempotency — unchanged 0020 machinery. (6) Cancel after allocation — allowed for branch/director via new RPC (reversal restores funds; fulfillment side effects are the actor's operational call, unchanged semantics). (7) Cancel without discount — status-only path, null reversal. (8) Manual invoice without `order_id` — fully functional under H2-A, as today. No conflict found; no BLOCKER.

## 6. Migration 0021 boundary (no SQL written)
MUST HAVE: new cancel RPC (H1-B gate + H3-A abort + 0020-style guards + dual audit + EXECUTE grant); allocate discount subtraction (OR REPLACE in new file, coalesce-neutral). SHOULD HAVE: F6 `bonus_ledger(order_id)` index; announced error-string catalog for fail-closed paths. FOLLOW-UP: `invoices.order_id` linkage (only on future H2-B/C adoption); review/flag stores (only on future H3-B/C); ledger-vs-invoices reconciliation report; Phase-21 app swaps (branch cancel call, optional UI). OUT OF SCOPE for 0021: any 0017–0020 file edit; RLS changes; triggers; GL/tenant/accountant objects; order-linkage enforcement without schema; client cancel beyond pending; manual-invoice restriction beyond policy wording.

## 7. Final contract + lock
| Decision | Product Default | Tenant Configurable Later | Security Invariant | Accounting Restricted | Migration 0021 |
|---|---|---|---|---|---|
| H1 | B-NARROW (own pending only) | states/roles per company | ownership+role+state gates; atomic reversal-or-abort | N/A | cancel RPC role branch |
| H2 | A independent manual invoice | linkage adoption per company (+migration) | RLS unchanged; no fake enforcement | Advisory if linkage deemed revenue-relevant | nothing (policy only) |
| H3 | A fail-closed + escalation | posture per company | snapshot-governs; POSTED immutable; one reversal; audit | N/A | abort branch (no store) |

PRODUCT POLICY LOCK — H1 = B-NARROW; H2 = A — INDEPENDENT MANUAL INVOICE; H3 = A — FAIL-CLOSED + ESCALATION. Proposed defaults for build; NOT tenant configuration (none exists); NOT applied anywhere.

## 8. Owner approval note + verification
These locked defaults await owner approval before 0021 specification; approving §7 unblocks §6 MUST/SHOULD with no further business input. Full re-read performed: H1/H2/H3 match 22.1 definitions and 22.2 recommendations; no 22/22.1 conflict; no Tenant System invented (future points named, never built); 0017–0020 untouched; zero SQL/code/DB changes. Operation log: local reads only; no timeouts/auth errors; no live queries; one corrected citation (`bonus_reversals` → ledger REVERSAL rows, §5 NOTE).

PHASE 22.3 COMPLETE
PRODUCT POLICY LOCK COMPLETE
H1/H2/H3 LOCKED AS PRODUCT DEFAULTS
READY FOR MIGRATION 0021 SPECIFICATION
NO CODE CHANGES
NO SQL CHANGES
NO DATABASE CHANGES
NO MIGRATION CHANGES
