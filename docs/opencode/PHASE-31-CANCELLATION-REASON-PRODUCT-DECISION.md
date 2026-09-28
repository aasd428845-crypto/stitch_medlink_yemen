# PHASE 31 — CANCELLATION REASON PRODUCT DECISION ANALYSIS (analysis only)

## 1. Executive Summary
BD-1 (reason store: column vs table) is now the SOLE remaining gate for final cancel UI — and a live-environment check performed this phase overturned a standing assumption: full Migration 0021 IS live (F1 present; F2 body proven identical to the reviewed file modulo extraction boundary, delta marker + `v_discount` present live; F6 index present). Cancel execution, reversal, and discount-aware invoicing therefore exist in production; only reason queryability/display, taxonomy, and UI wiring remain undecided. No selection made; owner decides in §12.

## 2. Verified Facts
- `orders` has no queryable reason store (columns verified, §14 evidence).
- Audit records reason on success only (0021 reversal + status audits; aborts roll back by construction).
- No metadata mechanism exists (verified absent, all layers).
- Reopen is impossible today (no transition, path, or UI).
- Single terminal cancel per order is the effective machine.
- `parentOrderId` exists schema + model, zero I/O elsewhere.
- 0021 LIVE (this phase, read-only catalog proof): `cancel_order_with_discount` count=1; live allocate prosrc matches reviewed F2 (1 boundary-artifact diff line); `bonus_ledger_order_idx` present. Prior "unapplied" status is SUPERSEDED — recorded as the phase's key factual correction.
- No tenant/company/org identifiers exist anywhere (verified zero matches).

## 3. Product Context
Users: clients (cancel own pending, post-wiring), branches (daily cancel volume + billing), directors (oversight + MANUAL escalations), future companies (unknown policies). Reports needed eventually (counts/reasons/actors/periods/discount-linkage). No tenant store exists, so every product behavior ships global-today with company-variation as documented-future.

## 4. Option A — Column
`orders.cancellation_reason` (+optionally cancelled_at/by): client sees own reason via existing reads; branch sees assigned-branch orders; directors see all — all through CURRENT RLS, zero new policies. Reporting: single-value GROUP BY across all dimensions natively. Search/export: trivial. l10n: codes map to app strings. Future: reopen would overwrite (lossy — acceptable only while the machine stays single-terminal); multi-reason/company sets need a companion structure later. Development: smallest migration + model delta; RPC body gains one SET (future file, 0021 untouched).

## 5. Option B — Cancellation Record
Dedicated history rows (order FK, reason, actor, timestamp, previous status, source, optional note): cancel timeline per order, attempt records, appeal-ready, richest reporting (all dimensions + history depth). Costs: table + RLS + model + reads + bigger migration. Company evolution: partitions/extends cleanly post-tenancy; reason catalogs attach per company later. Nothing about it requires tenant architecture TODAY (global table, same as every bonus table).

## 6. Product Sale Compatibility
Without tenancy both options operate globally and identically in behavior; they differ only in depth, not in company logic. Reason codes/labels/requiredness can later move per-company under either storage (codes are app/data content, not schema). Tenant System is NOT a prerequisite for either option — recorded explicitly so no one blocks BD-1 on tenancy.

## 7. Migration Impact
A: 1 column (+optional 2 audit-ish columns), no index strictly needed, no RLS, RPC SET line, model +1 field, repository transparent. B: 1 table + PK/FK + order-FK index + RLS policies, RPC INSERT line, new model + reads. No SQL written here.

## 8. Operational Impact
Read path (detail/list): A immediate via existing fetches; B one extra read. Display: identical widgets fed by either source. Reports/export/support lookups: A answers single-value questions; B answers those plus history. No ranking stated.

## 9. Data Integrity
NULL: allowed only while status ≠ cancelled (invariant: reason present ⟺ cancelled; enforced at write time by the RPC body update, future migration). Rollback: reason never persists without the cancel (same txn). Duplicate/timeout: same-key retry overwrites identically (A) or dedupes via key column if B is non-unique (design note). No reason without successful cancel is persistable under either option (aborts roll back; audit carries reason only on commit).

## 10. Decision Boundary
Policy "one final cancel, no history" → column suffices technically, table is overbuild. Policy "keep cancel history for future lifecycles" → table required (column cannot serve it). The boundary is exactly this sentence — everything else (reporting depth, model weight) follows from it. No selection made.

## 11. Product-Level Tradeoff Matrix
| Criterion | Column | Separate Cancellation Record |
|---|---|---|
| Current system simplicity | single nullable field, no new authz surface | new table + RLS + reads |
| Order Details query | transparent in existing fetch | one additional read |
| Reporting | single-value complete | complete + history depth |
| Historical record | last-wins (lossy on reopen) | full (attempts, appeals) |
| Future extensibility | capped; reopen breaks it | open (linkage, workflow, analytics) |
| Multi-company evolution | uniform codes suffice | same + natural partitions later |
| Migration scope | one column (+optional timestamps) | table + index + RLS |
| RLS complexity | zero (inherits) | new policies required |
| RPC complexity | one SET line later | one INSERT later |
| Client integration | identical widgets either way | identical + optional history view |

## 12. Owner Decision
BD-1 FINAL OWNER DECISION — OPTION A — COLUMN: decide the nullable column set (`cancellation_reason` ± `cancelled_at`/`cancelled_by`) and the reason taxonomy shape (BD-2). OPTION B — SEPARATE CANCELLATION RECORD: decide the history table shape (uniqueness, actor/timestamp/source fields) and the same taxonomy. OWNER MUST SELECT ONE. Selecting either unblocks: reason-store migration design → static review → manual apply → live verification → RPC body touch-up (new file, 0021 untouched) → Flutter pass-through → final cancel UI. Nothing else is gated on BD-1 that is not listed here.

## 13. Implementation Gate
Post-decision pipeline (not started): Migration Design → Static Review → Manual Human Application → Live Read-Only Verification → Backend Integration (RPC touch-up) → UI Integration. Cancel UI, reason display, and history remain the only BD-1-blocked items; Center filters, derived timeline, reorder/buy-again, and discount display proceed independently (Phase 27 dependencies stand, updated only by the 0021-live correction: cancel EXECUTION no longer needs backend work).

## 14. Evidence / File References
0021-live proof (this phase, read-only): cancel RPC count=1; live allocate prosrc vs reviewed F2 (1 boundary-artifact line); `bonus_ledger_order_idx` present; `v_discount` + delta marker live. Schema: orders columns 0002:126-144; audit 0018:313-324; model order.dart:16. Zero tenant/company/org identifiers repo-wide. Zero reason/metadata/history matches. Operation log: 5 live SELECTs (1 timeout-free run except one empty-output retry that succeeded with body_len, plus 1 interrupted-then-retried GL-era call from the prior session — none in this phase except a single ECONNRESET on an empty call, content resent intact). No writes issued; no code/SQL/migration touched.

## 15. Final Status
No reopened decisions (16.7/22.3 intact; bonus/discount/payment/invoice scopes untouched — no direct conflict with BD-1 found).

PHASE 31 COMPLETE — CANCELLATION REASON PRODUCT DECISION ANALYSIS
NO CODE MODIFIED
NO DATABASE CHANGES
NO SQL EXECUTED
NO MIGRATION CREATED
NO COMMIT
NO PUSH
