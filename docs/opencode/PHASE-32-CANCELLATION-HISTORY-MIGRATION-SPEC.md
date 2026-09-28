# PHASE 32 — CANCELLATION HISTORY MIGRATION SPEC (specification only, no SQL)

## 1. Executive Summary
BD-1 locked as OPTION B: a dedicated cancellation-history record. Next migration number verified as 0022 (tail today: 0019/0020/0021; zero 0022 files). Design: one new table (order-linked event rows, 1:N future-proof), written ONLY inside the cancel transaction (future OR REPLACE of the 0021 function in the NEW file; 0021 file untouched), read via owner/director RLS mirroring bonus-table convention, no backfill, additive-only. 0021 proven live (Phase 31 read-only proof: F1 + F2 + index present), so 0022 extends a live function rather than a draft.

## 2. Locked Product Decision
BD-1 = SEPARATE CANCELLATION RECORD. Rationale carried (not reopened): product needs an expandable cancel history (attempts, actors, reasons, future reopen/appeal semantics). The event/record split is strict: order state lives in `orders.status`; everything about the cancellation act lives in the new record + existing audit.

## 3. Current Architecture
Cancel executes in 0021's `cancel_order_with_discount` (live): lock → authorize (client-owner-pending / own-branch manager / director) → detect POSTED discount → snapshot-gated reversal → status flip → dual audit → id-or-NULL, fully atomic. Reason accepted as param, persisted only in audit rows on success. No history store, no reason taxonomy, no status-history source. Roles: client/branch_manager/driver/company_director (driver excluded from cancel paths). Timestamps convention: `timestamptz NOT NULL DEFAULT now()`, server authority (never client time).

## 4. Migration Number Verification
Local tail: `0019…`, `0020…`, `0021_order_cancellation_with_discount.sql`; `ls | grep -c 0022` = 0. Next: 0022. Name suggested (not created): `0022_order_cancellation_history.sql`.

## 5. Cancellation Record Model
Proposed name (not created): `order_cancellations` — one row per cancellation ATTEMPT THAT COMMITS (failed attempts persist nothing, §16 matrix). Event record, not order snapshot: no customer/order/item/price duplication.

## 6. Fields (REQUIRED / OPTIONAL / NOT REQUIRED / FUTURE + why)
- `id uuid PK default gen_random_uuid()` — REQUIRED (row identity; matches every table convention).
- `order_id uuid NOT NULL → orders(id) ON DELETE RESTRICT` — REQUIRED (linkage; RESTRICT because financial history must never evaporate with an order row; orders themselves are never deleted in current flows).
- `reason text NOT NULL` — REQUIRED (the BD-1 payload; non-empty enforced to mirror the RPC's existing requirement).
- `reason_code text NULL` — OPTIONAL (reserved for BD-2 taxonomy without forcing it; NULL until taxonomy decided).
- `note text NULL` — OPTIONAL (code+note shape support; NULL until needed).
- `cancelled_by uuid → users(id) ON DELETE SET NULL` — REQUIRED (actor; SET NULL preserves rows if accounts are pruned, matching audit convention 0018:318).
- `cancelled_at timestamptz NOT NULL DEFAULT now()` — REQUIRED (server time; orders has no usable timestamp for this).
- `previous_status text NOT NULL` — REQUIRED (from-state; analytics + reopen logic need it; cheap at write time).
- `source text NOT NULL` — REQUIRED as the caller role string (`client`/`branch_manager`/`company_director`, from `current_user_role()` already in hand — no new enum invented; NOT a gap, just record-what-exists).
- `reversal_ledger_id uuid NULL → bonus_ledger(id) ON DELETE RESTRICT` — REQUIRED NULLABLE (direct join discount-cancel→compensation; NULL when no discount; RESTRICT protects financial chain).
- `idempotency_key text NULL UNIQUE-concept` — REQUIRED NULLABLE (dedupes retried history inserts; see §16; unique where-not-null or application-checked — decided at authoring).
- `created_at timestamptz NOT NULL DEFAULT now()` — REQUIRED (convention; equals cancelled_at in practice, kept for uniformity).
- NOT REQUIRED: customer snapshot, totals, items, prices, branch copy (all reachable via order join; duplicating them would create drift vectors). FUTURE: `company_id` (only if tenancy ever lands — column-additive then, no redesign: §19).

## 7. Cardinality
Order 1 → N cancellation records (non-unique `order_id`). Why: today's machine needs exactly one, but the product decision explicitly buys future history (attempts, reopen-then-cancel, appeals). Single-row enforcement today comes from the STATE MACHINE (terminal cancelled + idempotent converge), not from a UNIQUE constraint — uniqueness would foreclose the very future being purchased. `parentOrderId` (dormant) stays out of this design.

## 8. Relationship
`order_cancellations.order_id → orders(id)`: ON DELETE RESTRICT (history outlives operational rows; nothing deletes orders today, but the rule must be explicit), ON UPDATE CASCADE (uuid PKs never change in practice; harmless default). Orphan prevention: FK NOT NULL + RESTRICT + writes only inside the cancel transaction (no direct client INSERT — §13). Existing-orders compatibility: zero backfill (history starts at 0022; old cancels remain status-only + audit, which is sufficient proof).

## 9. Reason Model
Store free-text `reason` (REQUIRED, non-empty — mirrors live RPC contract) with NULLABLE `reason_code` + `note` reserved for BD-2 taxonomy. No taxonomy values invented here. Code-only vs text-only vs code+note is a BD-2 business call; the schema supports all three without alteration. Company-specific reasons: NO tenant store exists — recorded as FUTURE TENANT DEPENDENCY for the CATALOG only, never for this table's shape. Localization lives app-side (l10n pattern, codes map to strings).

## 10. Actor Model
`cancelled_by` = `auth.uid()` at write time (uuid, never client-supplied — no user_id params exist anywhere in the cancel path). Role is separately recorded in `source` (client/branch_manager/company_director — the exact role strings the system already uses; driver cannot reach the writer). No role enum invented; no new auth concept.

## 11. Source Model
No `source` enum exists anywhere today — but none is needed: the writer already holds `v_role` and records its literal value. NOT a design gap (nothing to invent); the column is `text NOT NULL` with application-level value discipline matching current role strings. Future source kinds (system/scheduler) would extend values, not schema.

## 12. Timestamp
`cancelled_at` + `created_at`: `timestamptz NOT NULL DEFAULT now()` — server clock exclusively (project convention, 0018:32-33). Client timestamps never accepted (no such parameter exists and none is proposed).

## 13. RLS Contract (design only, nothing altered)
Following the bonus-table convention exactly (client-own SELECT 0018:215-216, director SELECT 0018:218-220, zero write policies anywhere): `order_cancellations_client_select` (client reads own orders' rows — via `order_id IN (own orders)` or account linkage per authoring), `order_cancellations_director_select` (company_director, all rows). INSERT/UPDATE/DELETE: NO policies for any role — writes happen ONLY inside the definer cancel transaction (direct client INSERT must be denied; authors must not add a permissive insert policy to "make it work"). Branch manager reads: NO precedent on bonus tables; branch sees cancellation via the order row it already reads (status) — explicit boundary: branch history reads are OUT unless a later decision adds a branch-scoped policy. Recorded, not built.

## 14. 0021 Integration (flow with history write)
Customer/branch → `cancel_order_with_discount()` → lock → authorize → state gate → detect discount → snapshot-gated reversal → INSERT history row (same txn, after reversal, before/after status flip — authoring choice, both atomic) → status flip → dual audit → COMMIT. Atomicity rule: history-write failure rolls back status + reversal (no `cancelled`-without-record state, mirroring the existing no-partial-money rule). 0021's FILE stays untouched; the function body is OR REPLACE'd inside the NEW 0022 file (established convention for F2 in 0021 itself).

## 15. Idempotency
Current 0021 protection (order lock + state convergence + reversal UNIQUE) already prevents double money; history follows the same convergence: replay finds existing reversal-or-NULL path and writes NO second history row. Retry-after-timeout carries the same reason; column/table both converge identically. New mechanism needed ONLY if history rows become non-unique AND retried inserts could double (decided at authoring: unique partial index on `(order_id)` where single-active, or idempotency-key column — the spec requires one of the two, not both, and not a parallel system).

## 16. Failure Atomicity Matrix
| Scenario | History row? | Order | Ledger | Audit |
|---|---|---|---|---|
| Auth fail | none | unchanged | unchanged | none (error surfaces) |
| Non-pending (client) | none | unchanged | unchanged | none |
| Reversal impossible (MANUAL) | none | unchanged (fail-closed) | unchanged | none |
| DB failure mid-txn | none (rolled back) | unchanged | unchanged | none |
| Success no-discount | 1 row | cancelled | unchanged | status audit |
| Success + discount | 1 row (+reversal link) | cancelled | +1 REVERSAL | dual audit |
Rule: a history row exists IFF the cancel committed. No `cancelled`-without-record and no record-without-cancel are reachable.

## 17. Indexes (REQUIRED / OPTIONAL / FUTURE + why)
- `(order_id)` btree — REQUIRED (detection-adjacent reads + per-order history; the F6 ledger index does not cover this table).
- `(cancelled_at DESC)` — OPTIONAL (period reports scan acceptably at product scale; add when reporting lands).
- `(cancelled_by)` — FUTURE (per-actor reports only).
- `(reason_code)` — FUTURE (only if BD-2 taxonomy ships; skipped until then).
- Unique/dedup guard — REQUIRED in one of the two forms noted in §15.

## 18. Historical Reporting (future queries, no reports built)
Per-order (order_id index), per-customer (join orders.client_id), per-branch (join orders.branch_id), per-actor (cancelled_by), per-reason (reason/reason_code GROUP BY), per-date (cancelled_at range), discount-linked (reversal_ledger_id NOT NULL + ledger join), reorder-following (join via dormant parentOrderId when its semantics land). All served by §§6+17 shapes.

## 19. Multi-Company Compatibility
No `company_id`/`tenant_id` today and none proposed. IF tenancy ever lands, it arrives as an additive nullable column + index on this table (and siblings) — the 1:N history shape, FK discipline, and RLS pattern (owner-scoped reads) extend without redesign. The table is therefore tenant-ready in structure while tenant-free in fact. No tenant system invented, assumed, or required.

## 20. Migration Safety
Additive-only: one table, two indexes max, two RLS SELECT policies, one function OR REPLACE (in the new file). No destructive change, no old-data modification, NO BACKFILL REQUIRED (history starts empty; old cancels remain status+audit, which is sufficient proof). 0017–0021 files untouched by rule. Failure handling: object-level `IF NOT EXISTS`/OR REPLACE re-runnability; forward-fix only on production, never destructive rollback.

## 21. Testing Specification (future, isolated identities)
T01 no-discount cancel → status + 1 history row, NULL reversal. T02 discount cancel → +1 REVERSAL linked, funds restored. T03 duplicate → single history row. T04 timeout+retry → convergence, no doubles. T05 non-pending → reject, zero writes. T06 foreign order / wrong role → forbidden. T07 MANUAL snapshot → abort, zero writes. T08 history-insert failure (simulated) → full rollback incl. status. T09 client reads own history only (RLS probe). T10 branch/director reads per §13 boundary. T11 atomicity triple (status+reversal+history) under fault injection. T12 Free-Y order → allocation math untouched. T13 POSTED rows byte-identical post-run. Plus: RLS direct-INSERT probe denied for all roles.

## 22. Implementation Boundary
0022 creates: table + indexes + 2 SELECT policies + OR REPLACE'd cancel function + grant restatement. Backend changes: function body only (history INSERT inside txn). Flutter later: reason control + history display (reads via existing seams). Order Center later: cancel entry + history block. Nothing else moves.

## 23. Final Object Contract
Migration: 0022 (`0022_order_cancellation_history.sql` suggested, not created). Table: `order_cancellations` (proposed name). Relationship: Order 1 → N records. Write Authority: cancel transaction only (definer; no direct writes). Read Authority: owner-scoped + director (branch excluded by precedent, recorded). History: preserved from 0022 forward. Backfill: none. Old migrations modified: none. Undecided items: reason taxonomy shape (BD-2), `reason_code` usage, dedup-guard form (§15 alternative), branch history reads (explicitly out). Nothing marked DECISION REQUIRED beyond those four — all else specified.

## 24. Evidence / File References
Tail 0019/0020/0021, zero 0022; 0021-live proof carried from Phase 31 (F1 count, F2 body match, F6 present); RLS convention 0018:214-220; timestamp convention 0018:32-33; audit shape 0018:313-324; roles constants.dart:24-28; RLS no-client-update 0002:156-161; OrderModel parentOrderId dormant. Transport note: two empty-call ECONNRESETs; all content delivered in smaller chunks, none lost.

## 25. Final Status
No timeouts on executed commands; no corrections beyond chunked delivery; no discrepancies vs cited sources.

PHASE 32 COMPLETE — CANCELLATION HISTORY MIGRATION SPECIFICATION
NO CODE MODIFIED
NO DATABASE CHANGES
NO SQL EXECUTED
NO MIGRATION CREATED
NO COMMIT
NO PUSH
