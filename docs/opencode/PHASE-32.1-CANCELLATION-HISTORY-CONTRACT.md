# PHASE 32.1 — FINAL CANCELLATION HISTORY CONTRACT (analysis only, no SQL)

## 1. Evidence
0021 file-local, reviewed (24/24.1/24.2, hash-gated, live-confirmed in Phase 31); zero app callers of `cancel_order_with_discount` (repo-wide grep, this phase); RLS: `orders_client_select` admits client-own + branch_manager/director-unscoped + assigned-driver (0002:145-150), `orders_manager_update` admits branch_manager/director/driver (0002:156-160), client has NO update right; audit shape 0018:313-324 (reason + reference columns exist); bonus-table RLS precedent = owner/director SELECT, zero write policies; no tenant identifiers anywhere.

## 2. Taxonomy Decision
TECHNICAL CONTRACT: store free-text `reason` (REQUIRED, mirrors live RPC contract) + NULLABLE `reason_code` + NULLABLE `note` reserved columns. BUSINESS POLICY REQUIRED: the code list itself (fixed codes vs free-text-only vs code+note discipline). No taxonomy table now (no source values exist anywhere to populate it); codes later attach without schema change. Nothing invented.

## 3. reason_code Decision
EXISTING: nothing. TECHNICAL CONTRACT: nullable TEXT, no CHECK (values unknown until BD-2 taxonomy lands; a CHECK today would lock in invented values). Extensible by policy rows later, not by schema rework. Status: column shape LOCKED, value set = BUSINESS POLICY REQUIRED.

## 4. Dedup / Idempotency Contract
TECHNICAL CONTRACT from 0021 mechanics: same logical request → same event identity via STATE convergence (order lock → existing-reversal-or-NULL replay → zero new rows), NOT via a stored request key. Answers: A (return same) + B (no second record) both hold simultaneously; C is moot (failed attempts persist nothing by rollback). History INSERT rides inside the same guarded transaction, so no new mechanism is needed or created. No policy choice involved.

## 5. Branch Read Contract
FINAL RLS CONTRACT (all classified): INSERT — no policy for any role (REQUIRES DESIGN: definer-only writes inside cancel txn; explicit). SELECT client-own — EXISTING pattern (mirror `orders_client_select` client clause + bonus-table owner reads). SELECT director — EXISTING pattern (role check). SELECT branch_manager — REQUIRES DESIGN but decided here as TECHNICAL CONTRACT: mirror `orders_client_select` line 148 (branch_manager reads ALL orders, unscoped) → branch reads ALL history rows; no branch-scoping invented (the codebase never scopes branch reads by branch on orders or bonus tables). Admin: no such role exists (verified role set) — N/A. UPDATE/DELETE: no policies for anyone (history immutable; corrections are new compensating rows per ledger precedent).

## 6. Actor Contract
TECHNICAL CONTRACT: `cancelled_by` = `auth.uid()` (uuid, SET NULL on user prune per audit precedent); `source` = literal caller role (`client`/`branch_manager`/`company_director`, already in hand — no enum invented). Driver cannot reach the writer (excluded from 0021 gate; no UI). No user_id parameters exist or are proposed.

## 7. Final Record Contract
| Field | Type | Nullable | Source | Purpose | Constraint | Policy Required? |
|---|---|---|---|---|---|---|
| id | uuid PK default gen_random_uuid() | No | system | identity | PK | No (TECHNICAL CONTRACT) |
| order_id | uuid → orders(id) | No | RPC param | linkage | FK RESTRICT | No |
| reason | text | No | RPC param (non-empty enforced) | BD-1 payload | non-empty (RPC) | No (shape locked; values = BUSINESS POLICY) |
| reason_code | text | Yes | RPC/future taxonomy | BD-2 codes | none today | Values = BUSINESS POLICY |
| note | text | Yes | RPC/future | code+note shape | none | Usage = BUSINESS POLICY |
| cancelled_by | uuid → users(id) | Yes* | auth.uid() | actor (*null only if user pruned) | FK SET NULL | No |
| cancelled_at | timestamptz default now() | No | server clock | event time | NOT NULL | No |
| previous_status | text | No | pre-flip read | analytics/reopen | NOT NULL | No |
| source | text | No | caller role literal | channel reporting | NOT NULL | No |
| reversal_ledger_id | uuid → bonus_ledger(id) | Yes | created-or-found reversal | money linkage | FK RESTRICT, null iff no discount | No |
| idempotency_key | text | Yes | caller or derived | dedup audit | unique-where-not-null (authoring choice) | No |
| created_at | timestamptz default now() | No | server clock | convention | NOT NULL | No |
No invented fields; every row above resolves to §1 evidence.

## 8. FK Contract
`order_cancellations.order_id → orders(id)` ON DELETE RESTRICT, ON UPDATE CASCADE (uuid-immutable default). RESTRICT fits history permanence; orders are never deleted in any current flow, and cascade-delete of financial history would violate append-only posture. No soft-delete exists to integrate with (verified absent).

## 9. Atomicity Contract
TECHNICAL CONTRACT (LOCKED): history INSERT sits inside the cancel transaction AFTER reversal creation and BEFORE/AFTER the status flip (adjacent, same txn — exact adjacency an authoring micro-decision with zero semantic difference). Failure anywhere → full rollback: no `cancelled`-without-record, no record-without-cancel, no reversal-without-status. Matches the existing no-partial-money rule extended to history.

## 10. Future History Compatibility
SUPPORTED NOW: single terminal cancel + reason + actor + reversal link + audit. FUTURE-COMPATIBLE (no extra work): multi-attempt rows (1:N shape), reopen-then-cancel (new rows; `parentOrderId` relink stays a separate business call), appeal annotations (note/code fields), per-order timeline reads (order_id index). No workflow invented beyond what exists.

## 11. Tenancy Compatibility
Structure carries tenancy without assuming it: a future nullable company column + index attaches additively; owner-scoped RLS pattern extends naturally; no redesign of history, FKs, or idempotency. Tenant-free in fact, tenant-ready in structure. Nothing invented.

## 12. Migration Safety
Additive-only: CREATE TABLE (new) + btree on order_id (+ optional cancelled_at) + two SELECT policies + OR REPLACE'd cancel function in the NEW file + grant restatement. No backfill (history starts empty). 0021 file untouched. Forward-fix only on production.

## 13. OR REPLACE Correction (explicit, per mandate)
"OR REPLACE" applies ONLY to FUNCTIONS (`cancel_order_with_discount` body update inside the new migration file — same convention as 0021's own F2 handling of `branch_allocate_order`). The new TABLE uses plain `CREATE TABLE` (with `IF NOT EXISTS` for re-runnability; the migration MUST fail loudly on genuine conflicts, not silently diverge — `IF NOT EXISTS` skips only true re-runs, it does not mask definition drift; reviewers must diff on re-run). No other object needs OR REPLACE. Phase 32's phrasing is corrected accordingly and superseded by this section.

## 14. Final Decision Table
| Decision | Final Contract | Status | Evidence |
|---|---|---|---|
| History Model | 1:N event table, no snapshots | LOCKED | §7 + state machine |
| Taxonomy shape | free-text + nullable code/note columns | LOCKED (shape) | RPC contract + l10n readiness |
| Taxonomy values | unset | BUSINESS POLICY REQUIRED | no source values exist |
| reason_code | nullable TEXT, no CHECK | LOCKED | §3 |
| Dedup | state convergence, no new mechanism | LOCKED | 0021 guards + constraints |
| Branch Read Access | mirror orders SELECT (unscoped) | LOCKED | 0002:148 precedent |
| Actor | auth.uid + role literal, no params | LOCKED | 0021 + role set |
| Atomicity | history inside cancel txn | LOCKED | §9 |
| Tenancy | structure-ready, tenant-free | LOCKED | §11 |

## 15. MIGRATION 0022 FINAL SPECIFICATION
Objects: `order_cancellations` (CREATE TABLE IF NOT EXISTS, §7 fields/constraints); btree `(order_id)` (+ optional `(cancelled_at)`); SELECT policies (owner + director + branch per §5); OR REPLACE `cancel_order_with_discount` (history INSERT + reason param already present); grant restatement. Relationship: 1:N, RESTRICT/CASCADE per §8. Transaction boundary: §9. Idempotency: §4 state convergence (+ optional unique-where-not-null key at authoring). No-backfill rule. No 0021-file change. RLS: §5 contract.

## 16. Remaining Business Decisions
Taxonomy values only (BD-2): code list (or free-text-only discipline or code+note rule). Everything else is TECHNICAL CONTRACT. Migration 0022 IS WRITABLE on technical grounds today; the taxonomy call affects seed content, not structure — owner may approve structure now and values in parallel.

## 17. Implementation Boundary + close
Nothing built/modified/applied. Transport note: one ECONNRESET on an empty call; content chunked, none lost. No timeouts/failures/corrections/discrepancies otherwise.

PHASE 32.1 COMPLETE — FINAL CANCELLATION HISTORY CONTRACT
NO CODE MODIFIED
NO DATABASE CHANGES
NO SQL EXECUTED
NO MIGRATION CREATED
NO COMMIT
NO PUSH
