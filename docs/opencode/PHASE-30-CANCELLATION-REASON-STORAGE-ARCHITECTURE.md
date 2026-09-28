# PHASE 30 — CANCELLATION REASON STORAGE ARCHITECTURE (read-only analysis)

## 1. Executive Summary
BD-1 compares a nullable `orders` column (A) against a dedicated `order_cancellations` table (B); metadata (C) is excluded on evidence — no mechanism exists anywhere. Cardinality analysis favors append-friendly shapes only if multi-attempt history is ever wanted; today's state machine (terminal cancelled, no reopen) needs exactly one reason per order. Audit already carries reason on success but is not queryable per order and cannot persist aborts. No selection made; owner decision recorded in §17.

## 2. Current Facts
`orders` columns (0002:126-144): id/client/branch/parent/targets/status/address/driver/total/scheduled/notes/created_at — no reason, no timestamps beyond created/scheduled, no history table anywhere (repo-wide search empty). `bonus_audit_trail` (0018:313-324): entity/entity_id/action/actor/at_time/old/new/reason/reference — reason persisted by 0021 on success paths only. RLS: client cannot update orders at all (0002:156-161: branch_manager/director/assigned-driver); client reads own rows. 0021 requires non-empty `p_reason`, single-transaction cancel+conditional-reversal, fail-closed. Model `OrderModel` mirrors schema 1:1 (incl. dormant `parentOrderId`).

## 3. Option A — Column (conceptual `orders.cancellation_reason`)
Storage: nullable `text`, Unicode-native, length unbounded (or CHECK-capped); single value per order. Query: trivial filtering/grouping/export via existing order reads; joins unnecessary. RLS: inherits orders policies — client SELECT own (sufficient for display), branch/director read per existing rights; NO new policy needed since writes flow through the definer RPC, never direct UPDATE. Model: +1 nullable field (`order.dart`, freezed rerun). API: reason already a 0021 param; reads surface it automatically. 0021 compatibility: zero signature change; RPC would SET the column alongside status (one line in new migration's OR REPLACE — noted as future, not done). Audit: column is the readable store, audit remains the history proof (reason duplicated on success rows by current code). Multiple attempts: last-write-wins (today's machine has no reopen, so sufficient — with the caveat below).

## 4. Option B — Table (conceptual `order_cancellations`)
Logically required fields and why: `order_id` FK unique-or-not (WHY: linkage; unique enforces one-row; non-unique permits attempts-history); `reason` text (WHY: the payload); `cancelled_by` uuid→users (WHY: actor beyond audit convenience); `cancelled_at` timestamptz default now (WHY: orders lacks timestamps); `previous_status` text (WHY: from-state for analytics); `source` text client/branch/director (WHY: channel reporting); `note` nullable text (WHY: code+note format support). All fields NEW (nothing suitable exists). Costs: table + PK/FK + RLS (select own / manage roles) + model + reads + migration. Gains: attempt history, appeal/reopen readiness, clean reporting.

## 5. Metadata Exclusion
OPTION C — NOT SUPPORTED BY CURRENT ARCHITECTURE. No JSONB metadata column, no EAV table, no settings-per-entity mechanism exists in schema, models, or services (verified by absence across all three). Any "metadata" path would be new architecture, not reuse. Excluded on evidence.

## 6. Cardinality
State machine today: exactly one terminal cancelled per order, no reopen transition in code/RLS/RPC. Case 1 (one reason): guaranteed by the machine — both options serve it. Case 2 (multiple attempts): only via retries of the same logical cancel (idempotent; same reason) — column overwrites identically, table would log duplicates unless keyed (needs idempotency-key column to dedupe: design note, not selection). Case 3 (reopen → re-cancel): IMPOSSIBLE today (no transition, no RPC path, no UI); IF ever introduced, column loses history (last wins) while table keeps it; `parentOrderId` (dormant, schema+model only) is the natural relink affordance for cancel-and-recreate flows. Audit covers all cases as append-only proof regardless of option.

## 7. Multi-Company Analysis
NO TENANT STRUCTURE EXISTS (re-verified). Column: company reason sets would need either shared codes (uniform) or a companion config post-tenancy; localized labels live in app l10n per code (client-side concern, no schema). Table: same, plus per-company reporting partitions naturally if tenancy ever lands. Either option ships global-today; per-company configurability is a FUTURE ARCHITECTURAL DEPENDENCY for both (codes catalog, not storage shape, is the real dependency). No tenant system invented or assumed.

## 8. Reporting Comparison
| Reporting Need | Column | Separate Table | Current Support |
|---|---|---|---|
| cancellation count | trivial GROUP BY | trivial | none (no store) |
| by reason | GROUP BY reason | GROUP BY reason | none |
| per customer/branch/period | join-free (row carries keys) | join to orders | none |
| discount-linked cancels | join to ledger (order_id) | same join | none |
| reorder-linked cancels | via parentOrderId (dormant) | same | none |
| multi-attempt history | overwrites (lossy) | full (if non-unique) | audit only (unqueryable per order) |
| future analytics | sufficient for single-value | sufficient + history | none |

## 9. Audit Comparison
Reason appears today ONLY in 0021's success-path audit rows (`reason` param persisted). Audit row commits with the transaction; any abort rolls everything back — failed cancellations leave NO trace by construction (consistent with 0018/0020 precedent; app surfaces the RPC error instead). Successful cancels are provable but NOT queryable per order (no order→audit read path in app code). Column/table options add queryability; neither replaces audit as history proof. No audit changes in this phase.

## 10. Failed Cancellation Analysis
A auth fail → nothing written anywhere (reject pre-lock); reason lives only in the dead request. B stale state (non-pending) → reject pre-write; same. C reversal failure → full rollback incl. status; reason unpersisted; error surfaced (H3 fail-closed). D success → reason in audit (+ future store). Rule: reason persists ONLY on commit, and only where a store exists — aborts are intentionally traceless at DB level under all options.

## 11. RPC Contract (future shape, 0021 untouched)
Current `cancel_order_with_discount(order_id, reason, [idempotency_key])` already accepts the reason — NO signature change needed under either option. What changes later: the RPC body SETs the column (A) or INSERTs the history row (B) inside the same transaction (a future OR REPLACE in a NEW migration file, never editing 0021's file). Backward compatible (same params/returns); service layer unchanged; `CREATE OR REPLACE` safe per established convention.

## 12. Idempotency
Duplicate protection lives in state + constraints (order lock, single-cancel convergence, reversal UNIQUE), not in the reason store. Retry carries the same reason; column overwrites identically, table needs key-dedup only if non-unique (noted in §6). Neither option affects idempotency machinery. No new mechanism proposed or needed.

## 13. Data Lifecycle
Retention/archival/reporting/audit: identical under both options while the machine stays single-terminal-cancel (audit is the immortal proof either way). Divergence appears ONLY if reopen/multi-attempt ever exists: column loses intermediate reasons, table keeps them. Order archival deletes would cascade both (FK discipline at build time). No selection made.

## 14. Migration Scope
| Change | Option A | Option B |
|---|---|---|
| New column | REQUIRED (nullable text) | NOT REQUIRED |
| New table | NOT REQUIRED | REQUIRED (+PK/FK) |
| Index | NOT REQUIRED (row-read path) | REQUIRED (order FK lookup) |
| RLS | NOT REQUIRED (inherits) | REQUIRED (new policies) |
| RPC change | REQUIRED (SET in future OR REPLACE) | REQUIRED (INSERT in future OR REPLACE) |
| Model | REQUIRED (+1 field) | REQUIRED (new model) |
| Repository | NOT REQUIRED (existing reads) | REQUIRED (new reads) |
| UI | REQUIRED (control + display) | REQUIRED (same + history view optional) |
| Audit | NOT REQUIRED | NOT REQUIRED |

## 15. Dependency Graph
BD-1 → Storage Contract → RPC Contract (already accepts reason; body update later) → Migration (store + RPC touch-up) → Live Verification → Flutter Service (pass-through exists once RPC lands) → Controller (busy/key/reload pattern exists) → Cancellation UI → Order Center. Without BD-1: UI skeleton + filters + derived timeline can proceed; final cancel UI + reason display + history are BLOCKED.

## 16. Owner Decision Matrix
| Criterion | Option A | Option B |
|---|---|---|
| Current architecture fit | native (row extension, no new authz surface) | new surface (table + RLS + reads) |
| Queryability | single-value reads trivial | history reads trivial |
| Auditability | audit unchanged, sufficient | same + queryable history |
| Future extensibility | capped at one value (+reopen breaks it) | open (attempts, appeals, linkage) |
| Multi-company readiness | uniform codes suffice | same + per-company partitions later |
| Reporting | single-value complete | complete + history |
| Migration scope | one column | table + index + RLS |
| RPC impact | one SET line later | one INSERT later |
| UI impact | control + display | same + optional history view |
| Multiple cancellation support | last-wins (lossy) | full (if non-unique) |
| Data lifecycle | immortal via audit either way | same |

## 17. BD-1 Owner Decision
OPTION A — COLUMN or OPTION B — TABLE: OWNER DECISION REQUIRED. The decision fixes: storage shape (§3/§4), migration contents (§14), model/API surface, and reporting depth (§8). After it: RPC body touch-up → migration → verification → Flutter pass-through → final cancel UI. Blocked until then: reason display, cancel history, reason analytics.

## 18. Evidence / File References
orders columns 0002:126-144; audit shape 0018:313-324; 0021:34-61 signature/gates, :137-166 reversal+audits; model order.dart:16; zero reason/metadata/history matches repo-wide; zero client-cancel UI; RLS 0002:156-161. Transport note: one ECONNRESET on an empty call; all content delivered in smaller chunks, none lost.

PHASE 30 COMPLETE — CANCELLATION REASON STORAGE ARCHITECTURE
NO CODE MODIFIED
NO DATABASE CHANGES
NO SQL EXECUTED
NO MIGRATION CREATED
NO COMMIT
NO PUSH
