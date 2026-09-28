# PHASE 24.1 — MIGRATION 0021 DEEP REVIEW (read-only; zero modifications)

## 1. Executive result
F1 traced line-by-line against 0020/0018 semantics: safe. F2 proven equal to 0016's `branch_allocate_order` by opcode diff — exactly 2 INSERT ops (declare + delimited delta), 0 replacements/deletions. Financial core (no POSTED mutation, single compensation, fail-closed ordering) verified. Concurrency converges via order-lock serialization + guards + constraints. Two security subtleties investigated to proof: null-role path is UNREACHABLE (signup trigger 0001:47-50 guarantees a users row; helper 0001:52-64 returns NULL, never raises — also proving F1's DECLARE-time branch lookup safe for clients). Findings: 0 A, 0 B, 1 C (defense-in-depth null-role guard for the NEW function only), plus D/E dispositions. No file modified, no SQL executed.

## 2. F1 line-by-line review (0021:34-172)
- 45-51 auth/key derivation: `auth.uid()` null-reject (59); no user_id param; `CANCEL:{order}` + `REVERSAL:DISCOUNT:{order}` key families, unmixed with `DISCOUNT:` keys.
- 64-66 role gate: client/branch_manager/director only. Residual null-role edge (NULL `NOT IN` → skip) proven unreachable in §5 below; matches 0018/0020 convention.
- 68-70 order lock FIRST (`FOR UPDATE`), before any decision — correct ordering; every overlapping path (0020 apply, 0016 allocate) also locks the order row first: single global lock order, no deadlock cycle.
- 73-83 H1 authorization: client→ownership; manager→branch match with null-branch reject (fail-closed); director→open. All server-side.
- 85-87 delivered reject for all roles (earn consistency).
- 92-97 client pending gate with already-cancelled exemption (replay/converge path).
- 101-108 detection: latest POSTED ORDER_DISCOUNT, locked; ledger-as-truth, no duplicate state.
- 114-148 reversal: pre-check (114-117) → snapshot parse with immediate re-raise (121-131, H3 abort pre-write) → full-amount POSTED REVERSAL with `reverses_id` + existing UNIQUE key (134-141) → 0020-style audit (143-147). Original never selected for write.
- 152-167 status flip with rowcount guard + `order`/`CANCEL` audit carrying actor/reason/keys/reversal id. Skipped when already cancelled (converge, silent like 0020 replays).
- 169 returns reversal id or NULL. Step order validated: validate → lock → authorize → gate → detect → guard → money → status → audit. No step can be reordered into a race (all shared-state reads occur under the order lock or row locks).

## 3. F2 comparison (opcode-proven)
`SequenceMatcher` over both bodies: 128 vs 160 lines, opcodes = 2 INSERTs only (declare `v_discount`; delta block 309-338). Classification: REQUIRED DELTA (all 31 content lines — netting query, two guards, subtraction) + cosmetic separator; UNRELATED DELTA: none; POSSIBLE BUG: none; EXACT COPY: everything else (signature, security, locks, inventory deduction, invoice accumulation, status flip, insert, grant). "Identical except delta" is therefore proven, not asserted.

## 4. Financial integrity
Originals: never selected FOR UPDATE for write; no UPDATE/DELETE on `bonus_ledger` anywhere in 0021 (grep-verified). REVERSAL: new POSTED row, amount = `-debit.amount` (exact compensation by construction — cannot exceed, cannot compound). v_total math: no-discount → identical (coalesce-neutral); discount → total−net; multi-debit → summed once (no double count; single-debit enforced upstream by 0020); reversed → nets to zero via linked-REVERSAL subtraction scoped to this order's debits (foreign reversals excluded by construction); negative/over-total → abort (330-336), so no invalid invoice amount can persist. Inventory/allocation/paid/Free-Y quantities: untouched lines (proven §3).

## 5. Concurrency
A/B double-cancel: serialize on order `FOR UPDATE`; loser sees committed state → returns existing reversal id or NULL, or raises already-reversed. No double REVERSAL (guard + `bonus_ledger_reverses_uniq` partial index, live-verified in Phase 18). Cancelled-twice status: single flip (guarded update). Reversal-without-cancellation: impossible (same txn, status flip rowcount-guarded). Cancellation-without-reversal: only via H3 abort — which rolls back the status too (fail-closed, §6). Cross-path (apply/allocate/cancel/discount-remove): all take the order lock first; losers hit status gates. F2 adds only shared-read SELECTs (no new lock order, no deadlock vector). Null-role escalation: DISPROVEN as live risk — `handle_new_user` trigger (0001:47-50) guarantees every auth user a `users` row, so `current_user_role()` cannot return NULL for any live session; residual theoretical only (finding C-1 as defense-in-depth for F1).

## 6. H3 fail-closed trace
Validation order proven by line sequence: snapshot parse + mode check (121-131) → ledger INSERT (134) → audit (143) → status UPDATE (153) → status audit (161). Failure at any point → implicit-transaction rollback → final DB state: zero new rows, original status, original ledger — identical to pre-call. Failure→rollback→state verified for: MANUAL/missing snapshot, pre-reversed race loser (unique violation), status-flip anomaly, insufficient stock (F2 path). No swallowed financial errors: the single EXCEPTION block (121-126) re-raises immediately as a directed error; no other handlers exist.

## 7. Idempotency
Discount keys untouched. Cancel: `CANCEL:{order}` stored on the status audit reference (convergence is state-based, not key-lookup — documented, sufficient); money key `REVERSAL:DISCOUNT:{order}` UNIQUE-backed. First-success → rows; lost-response retry → existing id/NULL, zero new rows; duplicate concurrent → one winner; pre-reversed → converge. No double financial effect in any traced interleaving.

## 8. Security
Definer + fixed `search_path=public` on both functions; all objects schema-qualified (`public.`); no dynamic SQL (zero EXECUTE/format with identifiers); params are uuid/text/boolean/date/jsonb with safe casts only (`::numeric`, `::jsonb` inside guarded re-raise); jsonb inputs (`p_allocations`) flow through the 0016-validated `jsonb_to_recordset` shapes. Grants: EXECUTE to `authenticated` only (F1 new, F2 restated) — no PUBLIC/anon grant added; anon can invoke (Postgres PUBLIC default, same as all 0018/0020 functions live-verified in Phase 18) but dies at `auth.uid() IS NULL` before any read. RLS untouched and unbypassed in effect: definer writes carry in-function authorization stronger than the replaced direct-update path. No user-controlled identifiers, no unsafe casts.

## 9. H1/H2/H3 compliance + isolation boundaries
H1: pending-owner branch + wider branch/director gates implemented exactly as locked. H2: zero linkage objects, zero manual-path contact, boundary comment in-file. H3: abort-before-write proven (§6). Free-Y: `is_bonus`/`bonus_rule_id` occur ONLY inside the proven-identical 0016 reproduction; F1/delta reference neither; paid-vs-free split logic untouched. Policy snapshot: parsed from the 0020-written debit `notes`, never recomputed from live globals; F2 reads no policy at all. Invoice boundary: manual path byte-identical (proven §3 opcodes outside delta).

## 10. F6 index review
Required, not removable: no existing index covers `order_id` (0018 has account_time, account_status, reverses_uniq only — re-verified). Predicate `WHERE order_id IS NOT NULL` is correct (detection query binds non-null order ids; partial index stays small since most ledger rows are order-less). Serves F1 detection + 0020 order lookups. Cost negligible; no over-indexing. Verdict: KEEP (not SHOULD REMOVE).

## 11. Adversarial matrix (24 scenarios; O=order, L=ledger, A=allocations, U=audit)
1 pending/no-discount → cancelled, no L change, no A change, +CANCEL audit. 2 pending/discount → cancelled + 1 REVERSAL + dual audit, funds restored. 3 non-pending client → reject, all unchanged. 4 foreign order → reject at ownership, unchanged. 5 unauthenticated → reject first line. 6 duplicate cancel → existing id/NULL, no new rows. 7 concurrent pair → one winner, loser converges. 8 duplicate reversal attempt → guard/unique blocks, single compensation. 9 pre-reversed → converge, status flips if needed, no money. 10 MANUAL snapshot → abort pre-write, status unchanged, error only. 11 ledger-insert race loser → unique violation, rollback, retry converges. 12 status-flip anomaly → rowcount raise, full rollback. 13 audit-write failure → statement error rolls back all (no partial success possible). 14 timeout/retry → state convergence, never double. 15 Free-Y only → allocation math identical, no ledger contact. 16 Free-Y + financial discount → paid lines + netted invoice, free lines untouched. 17 manual invoice → untouched path/amount. 18 no invoice (`p_issue_invoice=false`) → status-only, delta computed but unused. 19 zero discount → coalesce-neutral, identical amount. 20 multi-debit (unreachable via 0020 guard) → summed once, latest reversed. 21 already-cancelled → converge (reversal-only if stranded, else silent). 22 allocate+cancel race → serialized; loser meets status gate. 23 discount-apply+cancel race → serialized; loser meets pending gate. 24 malformed snapshot/debit → fail-closed raise, zero writes.

## 12. Findings (exact lines; nothing modified)
| ID | Class | Finding | Evidence |
|---|---|---|---|
| F-01 | C | Add explicit null-role guard in F1 (`IF v_role IS NULL THEN RAISE`) as defense-in-depth. Live risk disproven (§5 trigger proof), and 0018/0020 share the pattern (out of scope to touch), but the NEW function should not inherit even a theoretical hole. File `0021…sql`, around line 64; effect: fail-closed on impossible state; regression risk: nil (unreachable branch). | 0021:64-66; 0001:47-64 |
| F-02 | D | "Missing `cancel_rejected` audit row" is NOT a defect: a raised exception rolls back the txn, so failure audit cannot persist in-txn; failures surface as RPC errors (existing app `_logError` pattern, same as 0018/0020). Spec §10 event list should be read as success-path-only. | 0021:121-131 + txn semantics |
| F-03 | D | "Anon can EXECUTE" is convention parity (all 0018/0020 functions identical live), neutralized at line 59 before any read. | 0021:59,172; Phase 18 §6 |
| F-04 | D | "F2 changes no-discount invoices" disproven: opcode diff shows delta-only; coalesce-neutral arithmetic proven in §4. | opcode diff §3 |
| F-05 | E | `CANCEL:{order}` key is stored (audit reference) but replay converges via state, not key lookup — documented design, sufficient and simpler. | 0021:49-50,161-166 |
| F-06 | E | Multi-debit orders reverse the latest only; unreachable via 0020's single-discount guard (zero such rows live, Phase 18). | 0021:101-108 |
| F-07 | E | F2 computes the delta even when `p_issue_invoice=false` (unused result) — harmless; clarity-only observation. | 0021:309-338 vs 345 |
| F-08 | E | Client replay on already-cancelled order returns silently without audit — matches 0020 replay precedent. | 0021:152,167-169 |

## 13. Final verdict
No BLOCKER, no MUST-FIX: the migration is financially sound, concurrency-safe, idempotent, least-privilege, and contract-faithful, with its two sharp edges (F2 body, reversal path) proven by independent diff and guard analysis rather than trusted from the authoring report. Single SHOULD-FIX (F-01) is a two-line hardening for the owner to accept or defer at SQL-authoring sign-off — it does not gate correctness today.

## 14. Operation log + re-read confirmation
Local reads/greps/python-diffs only; no timeouts, no auth errors, no live contact, no SQL executed. 0021 re-read in full (lines 1-175 pre-restart session + 176-356 this session with independent opcode diff); this report re-read at completion. Zero file modifications (verified: no edit/delete tool invoked this phase).

PHASE 24.1 COMPLETE
MIGRATION 0021 DEEP REVIEW COMPLETE
NO FILE MODIFICATIONS
NO SQL EXECUTED
NO DATABASE CHANGES
