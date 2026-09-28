# PHASE 22.2 — PRODUCT-SALE DECISION RECOMMENDATION (read-only)

## 0. Basis
Definitions and options are taken verbatim from 22.1 §0–§3 (H1 owner-client cancel rights; H2 manual-invoice scope; H3 MANUAL-snapshot cancel posture). Code anchors re-verified this phase: sole cancel path `branch_order_actions.dart:159`; allocate gate + invoice write 0016:53/128-148; RPC role gate 0020:334; no `order_id` on invoices; no tenant store. Nothing below applies anything — all three remain OWNER APPROVAL REQUIRED (§7).

## 1. H1 — extraction, effects, recommendation
Options (22.1): A status quo (no client cancel); B owner-client cancel of own orders via atomic RPC; C client cancel only undiscounted orders. Operational: B adds self-service pre-fulfillment cancellation with automatic reversal; financial: client-triggered reversals restore funds through the same guarded path as branch cancels (no new money mechanics); Order Discount: B/C route every cancel through the reversal-aware RPC (A leaves client-held discounts stranded until branch acts); SaaS: pre-fulfillment self-cancel is standard multi-tenant commerce, branch workload falls; permissions: ownership + role + state checked server-side from auth context, no client-supplied identity; 0021: role-check lines only; UX: fewer support tickets, one extra capability surface; edge: assigned/in-progress/delivered must stay non-client-cancellable (fulfillment side effects).
RECOMMENDED PRODUCT DEFAULT: **B-narrow — owner-client may cancel own PENDING orders only** (tighter than 22.1's "non-final": pending has zero fulfillment side effects; wider states stay branch/director). Why SaaS-fit: safe under every tenant's operations (nothing to fulfill yet), ledger-safe by construction, removes the stranded-discount case for the most common cancel. Future-configurable: cancellable states/roles per company (operational key when tenancy lands). Security-fixed: ownership, role, and state gates server-side, non-overrideable. Mitigates: stranded discounts, branch ticket load, inconsistent cancel rights across tenants. Adds: new capability surface — mitigated by pending-only gate + full audit + idempotent RPC.

## 2. H2 — extraction, effects, recommendation
Options (22.1): A standalone-only (policy/UI, zero schema); B order-linkable (`order_id` FK + invariant); C hybrid. Operational: A preserves today's manager billing untouched; financial: no mechanics change under any option (neutral amounts); Order Discount: A leaves the bypass technically open, B/C close it for linked invoices; SaaS: billing discipline is the most company-variable area found — fossil `invoices` table (no creation migration) makes schema steps company-sensitive; permissions: RLS unchanged in all options; 0021: A needs nothing, B/C need ALTER + rules; UX: A zero disruption, B/C add link steps; edge: unknowable current habit of billing orders manually (no link exists to measure — the central risk of A being merely policy).
RECOMMENDED PRODUCT DEFAULT: **A — manual invoices are standalone billing only** (by stated policy + UI wording; order-linked billing arrives exclusively through allocate). Why SaaS-fit: zero schema/behavior risk across unknown tenant histories; keeps every current flow working; defers the one-way structural step until a tenant actually needs linkage. Future-configurable: company billing discipline (linkage migration per adopter, not forced globally). Security-fixed: branch-scoped RLS + no client invoice rights, non-overrideable. Mitigates: fossil-table ALTER risk, invoice disruption, forced complexity. Adds: bypass remains physically possible — mitigated by director monitoring (ledger-vs-invoices reconciliation as a future read-only report) and by H2 staying re-decidable per company. Accounting: stays restricted — linkage later must pass financial-owner review IF deemed revenue-relevant (advisory gate recorded, not triggered today).

## 3. H3 — extraction, effects, recommendation
Options (22.1): A fail-closed (abort + escalate); B cancel + review flag (new store); C hold for director review (queue). Operational: A single-track ops, B/C two-track with review workload; financial: A never inconsistent, B/C bounded inconsistency window; Order Discount: snapshot already carries the mode — only the enforcement branch is decided; SaaS: MANUAL tenants explicitly bought control, and no tenant uses MANUAL today (global AUTO, zero live discounts) so A costs nothing now; permissions: enforcement server-side from snapshot, not caller-chosen; 0021: A = raise lines, B/C = new stores; UX: A adds branch friction; edge: delivered orders already excluded from reversal everywhere (consistent).
RECOMMENDED PRODUCT DEFAULT: **A — fail-closed with explicit error + director escalation**. Why SaaS-fit: a multi-tenant product must never ship "temporarily wrong money" as the DEFAULT, especially for a mode nobody uses yet; zero schema; fully auditable refusal. Future-configurable: per-company posture (B/C machinery built only for tenants that demand it). Security-fixed: snapshot-governs-cancellation is non-overrideable (0020 invariant). Mitigates: ambiguous funds, dual-track operations, unaudited drift. Adds: branch friction — mitigated by a clear error string and the existing director role as escalation target (R2 carried).

## 4. Standing distinctions (unchanged)
Product Default (above) ≠ tenant policy later ≠ Security Invariants (ownership/role/state gates, RLS, append-only ledger, idempotency, snapshot-governs — never configurable) ≠ Accounting Policy (D4/GL/revenue meaning — never director-decided; H2-linkage passes advisory review only if revenue-relevant). No recommendation touches D1–D4.

## 5. Compatibility check (vs 0017/0018/0019/0020 and architecture)
All three recommendations execute inside existing contracts: pending-gate aligns with 0020:118 + 0016:53; reversal reuses 0020 guards + `bonus_ledger_reverses_uniq` + trigger immutability (POSTED never mutated — compensation only, verified pattern); idempotency keys unchanged; `create_order_with_items`/`bonus_allocate_spend`/`earn` paths untouched; RLS untouched; Free-Y (`bonus_rule_id`, 0017:12) untouched; no GL/tenant objects. H2-A adds literally nothing. No conflict with 22/22.1 found (re-read §7 below).

## 6. Migration 0021 impact (support list only, no SQL)
Under recommended defaults 0021 needs: NEW cancel RPC (H1-B pending-owner branch + H3-A abort branch + shared 0020-style guards + dual audit); `CREATE OR REPLACE branch_allocate_order` (discount subtraction, coalesce-neutral); EXECUTE grant for the cancel RPC; optional F6 `bonus_ledger(order_id)` index. NOT needed: `invoices.order_id` (H2-A), review/flag stores (H3-A), RLS changes, trigger, any 0017–0020 edit, accountant role.

## 7. Final table
| Decision | Current Options | Product Default | Future Configurable? | Security Fixed? | Accounting Restricted? | Reason |
|---|---|---|---|---|---|---|
| H1 | A status quo / B owner-cancel / C undiscounted-only | B-narrow (own PENDING only) | Yes — states/roles per company | Yes — ownership+role+state server gates | N/A (no accounting content) | Universal pre-fulfillment self-service; ledger-safe; kills stranded discounts |
| H2 | A standalone / B linkable / C hybrid | A standalone-only | Yes — company billing discipline (+migration if linkage) | Yes — RLS unchanged, non-overrideable | Advisory gate if linkage later deemed revenue-relevant | Zero schema/behavior risk; defers one-way step to adopters |
| H3 | A fail-closed / B flag / C hold | A fail-closed + escalate | Yes — posture per company | Yes — snapshot enforcement non-overrideable | N/A | Never ships inconsistency as default; zero schema; mode unused today |

## 8. OWNER APPROVAL REQUIRED
H1 = [ ] A status quo (clients never cancel) / [ ] B-narrow (own PENDING only — recommended: standard self-service, atomic reversal) / [ ] C undiscounted-only (branch handles discounted cancels).
H2 = [ ] A standalone-only (recommended: no change, bypass closed by policy + future monitoring) / [ ] B order-linkable (needs `order_id` schema + rules) / [ ] C hybrid (both paths, most machinery).
H3 = [ ] A fail-closed (recommended: abort + escalate, never ambiguous money) / [ ] B cancel + review flag (needs store) / [ ] C hold for director review (needs queue).
Approving the recommended row in each line unblocks the 0021 support list in §6 with no further business input; any other row re-scopes §6 accordingly (still no D1–D4 impact).

## 9. Re-read verification + gaps
Re-read full report: no conflict with 22 (options/rankings/§15H text) or 22.1 (definitions, impacts, no-selection rule respected — this phase recommends defaults per its distinct mandate; selection stays with the owner in §8). All recommendations executable in multi-tenant SaaS without inventing tenancy (global code rules + named future key points, no tenant branches). No POSTED-mutation path introduced anywhere. GAPs/UNKNOWNs: (G1) current manager habit of manual order billing — unknowable from code, the core residual risk of H2-A; (G2) no staging env for backend tests; (G3) no tenant store/keys yet (by design); (G4) accountant role absent (unchanged, untriggered). Operation log: local reads only; no timeouts/auth errors; no live queries; no discrepancies vs cited sources.

PHASE 22.2 COMPLETE
PRODUCT-SALE DEFAULTS DEFINED
H1/H2/H3 READY FOR OWNER APPROVAL
NO CODE CHANGES
NO SQL CHANGES
NO DATABASE CHANGES
NO MIGRATION CHANGES
