# PHASE 33 — MIGRATION 0022 IMPLEMENTATION (local only, never executed)

## 1. Migration path
`supabase/migrations/0022_order_cancellation_history.sql` (223 lines).

## 2. Migration number verification
Local tail 0019/0020/0021; zero 0022 files pre-existed. 0022 is the correct next number.

## 3. Objects created
`order_cancellations` table; `order_cancellations_order_idx`; 3 SELECT policies; OR REPLACE `cancel_order_with_discount` (0021 file untouched); grant restatement. Nothing else.

## 4. Columns
id PK / order_id FK RESTRICT NOT NULL / reason text NOT NULL / reason_code NULL / note NULL / cancelled_by → users SET NULL / cancelled_at + created_at timestamptz default now() NOT NULL / previous_status NOT NULL / source NOT NULL / reversal_ledger_id → bonus_ledger RESTRICT NULL / idempotency_key NULL. No CHECKs (no invented taxonomy), no tenant columns.

## 5. Constraints
PK, FK×3 (RESTRICT/RESTRICT/SET NULL), NOT NULLs per contract. No UNIQUE (state-convergence dedup, no parallel mechanism). No CHECK (BD-2 values undecided — constraints would invent policy).

## 6. Foreign Keys
order_id → orders RESTRICT (history outlives rows); cancelled_by → users SET NULL (audit precedent); reversal_ledger_id → bonus_ledger RESTRICT (chain protection). All targets verified existing.

## 7. Indexes
`order_cancellations_order_idx(order_id)` only — detection-adjacent + history reads. cancelled_at/actor/code indexes deferred per contract (additive later, zero breakage).

## 8. RLS
Enabled; 3 SELECT policies (owner-via-orders / branch unscoped-mirror / director); zero write policies for any role (definer-only writes). No PUBLIC/anon grants; no orders RLS touched.

## 9. Grants
EXECUTE cancel fn to authenticated (restated, identical). Table needs none (RLS + definer pattern).

## 10. Function changes
Single OR REPLACE of `cancel_order_with_discount`, signature IDENTICAL (reason_code/note stay NULL until BD-2; documented). Opcode diff vs 0021: 4 INSERT ops only (2 flag declares, 2 flag sets, history block) — zero other changes. 0021 file untouched.

## 11. 0021 integration
History INSERT fires iff this call flipped status and/or created a reversal; pure replays write nothing (0020 precedent). Same transaction → status+reversal+audit+history all-or-nothing. No cancelled-without-record / record-without-cancel reachable.

## 12. Atomicity
Single implicit txn; any failure rolls back all four object families. Fail-closed paths unchanged from 0021 (abort pre-write).

## 13. Idempotency
State convergence (order lock → existing-or-NULL replay) + reversal UNIQUE backstop, unchanged. History follows convergence (no independent key system). Duplicate/timeout/concurrent all converge with zero new rows on replay.

## 14. No-backfill verification
Grep-verified: no INSERT into orders/ledger outside transactional paths; history starts empty; old cancels remain status+audit (sufficient proof). ADDITIVE ONLY.

## 15. Static verification
16/16 effective PASS (2 checker hits investigated on the spot: `drop policy if exists` = 0018-convention re-run guards on own new policies; `insert into public.order…` = prefix-substring false alarm on the history insert). Dollar balance, object counts, definer/search_path, grant coverage, signature identity, no alter/drop-data/delete/ledger-update/tenant/GL/invoice-contact.

## 16. Contract checklist (§23)
1:N history ✓ (non-unique FK) / order FK ✓ RESTRICT / reason model ✓ (text + reserved code/note, no values) / reason_code flexible ✓ (nullable, no CHECK) / actor ✓ (auth.uid + role literal) / previous status ✓ / source ✓ (role literal) / reversal reference ✓ (RESTRICT FK) / audit reference ✓ (existing dual audits + key in reference) / idempotency ✓ (state convergence) / RLS ✓ (mirror precedent) / SELECT access ✓ / no direct INSERT ✓ (zero write policies) / atomicity ✓ / no backfill ✓ / no tenant ✓ / 0021 untouched ✓ (file diff empty).

## 17. Errors / timeouts / corrections
One spurious "No such file" on the part-2 append (file verified complete immediately after: 223 lines, both parts present — filesystem race, no content lost). Two static-checker false alarms investigated with evidence (§15). No timeouts, no live contact, no real corrections to file content.

## 18. Remaining Business Policy BD-2
Taxonomy values only (code list vs free-text discipline vs code+note rule). Structure accepts all three without alteration. Nothing else gated.

PHASE 33 COMPLETE — MIGRATION 0022 WRITTEN LOCALLY
NO DATABASE CHANGES
NO REMOTE SQL EXECUTED
0021 NOT MODIFIED
NO BACKFILL
NO COMMIT
NO PUSH
