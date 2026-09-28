# PHASE 23 — MIGRATION 0021 FINAL SPECIFICATION (design only, no SQL)

## 0. Lock basis
Implements 22.3 locks (H1=B-NARROW pending-only owner-client cancel; H2=A independent manual invoices; H3=A fail-closed+escalation) within the 22 backend design. Code anchors re-verified: 0020 RPCs (:56/:311); allocate signature `(uuid,boolean,date,jsonb)` + grant (0016:13,155) + row locks (:45,:114); branch cancel = confirm dialog → direct update (`branch_order_actions.dart:150-160`, NO reason captured today); invoice inserts carry no order link (0009:187, 0016:146).

## 1. Object inventory
TABLES: none (no new tables; no `bonus_reversals` — reversals stay REVERSAL rows in `bonus_ledger`). COLUMNS: none (H2-A forbids linkage; F6 index needs no column). FUNCTIONS: (F1) NEW `cancel_order_with_discount` (spec §2); (F2) OR REPLACE `branch_allocate_order` — identical signature `(p_order_id uuid, p_issue_invoice boolean, p_expected_delivery_date date, p_allocations jsonb) returns uuid`, identical security/grant posture, single added behavior: subtract POSTED ORDER_DISCOUNT sum for the order from the computed invoice total (floor at zero with explicit abort-if-negative guard). TRIGGERS: none. INDEXES: (I1) optional F6 `bonus_ledger(order_id)` btree for the discount-detection + cancel lookups (non-unique; serves §2 step 5 + 0020 lookups); no others. RLS: no new tables → no new policies; existing SELECT-only ledger/alloc policies unchanged; write path stays definer-only. GRANTS: EXECUTE on F1 to `authenticated` (in-function role checks); F2 grant restated unchanged. No revokes, no role changes.

## 2. Cancellation RPC specification (F1)
Signature: `cancel_order_with_discount(p_order_id uuid, p_reason text, p_idempotency_key text default null) returns uuid` — returns reversal ledger id, or NULL when no discount existed (status still flipped + audited). SECURITY DEFINER, `search_path=public`, single-transaction boundary. Steps: (1) identify order by `p_order_id` (sole key; no user_id param — actor from `auth.uid()`); (2) ownership: branch_manager of order's branch OR director OR (H1) owner-client with status=pending — all server-side via `current_user_role()`/branch helpers; (3) pending-or-otherwise-cancellable gate: client path requires `pending`; branch/director accept any non-final state (delivered excluded from reversal but cancellable? NO — delivered orders are never cancelled by this RPC: reject; keeps earn/reversal consistency); (4) `SELECT … FOR UPDATE` on order + (if discount) debit row; (5) detect: latest POSTED ORDER_DISCOUNT for order (I1 serves this); (6) duplicate: already-cancelled + (no discount OR effective reversal present) + matching key → return existing (replay); already-cancelled WITHOUT prior reversal attempt → proceed to reversal only (no status rewrite needed); (7) reversal: duplicate 0020's guard block inline (snapshot parse → must equal AUTOMATIC_REVERSAL else H3-A abort; one-effective check vs `bonus_ledger_reverses_uniq`; full-amount POSTED REVERSAL credit with `reverses_id`, same key family `REVERSAL:DISCOUNT:{order}`) — inline duplication justified: 0020 is immutable and its role gate rejects branch_manager; (8) set `cancelled`; (9) dual audit (`order_cancelled` on orders entity + `REVERSAL` on ledger, actor/reason/keys/snapshot-mode); (10) any failure → full rollback; (11) no discount → status + audit only, return NULL; (12) non-pending client cancel → reject (H1 invariant); branch/director non-final → proceed; delivered → reject for all; (13) reversal-impossible → H3-A abort pre-write with distinct error (MANUAL mode / missing snapshot / pre-reversed-without-key-match); (14) concurrent cancels serialize on order lock; loser replays or raises safely.
Errors (named): unauthenticated / forbidden-role / foreign-order / order-not-found / non-cancellable-state / no-discount-to-reverse (only when caller explicitly demanded reversal — default path treats absence as NULL-success) / manual-settlement-required / already-reversed / reversal-shortfall-impossible. Never: POSTED UPDATE/DELETE (trigger would block; design never attempts).

## 3. H1/H3 app integration notes (no code changed)
Current branch cancel captures NO reason (dialog true/false only) — the app swap must add a reason input (or a fixed default string) since F1 requires `p_reason`. Client has no cancel UI; H1-B needs a pending-order cancel entry (order detail) calling F1, not direct updates. Director gains F1 automatically via role (no UI required now). Flutter must never write status directly once F1 lands on the cancel path (else bypasses reversal).

## 4. Reversal reuse (0020 semantics, duplicated minimally)
ORDER_DISCOUNT debit → POSTED REVERSAL credit (`-amount`) → `reverses_id` → fresh spendable lot (no un-consume; allocation rows intact); `bonus_credit_remaining` untouched; idempotency via existing UNIQUE + `bonus_ledger_reverses_uniq`; snapshot parsed from debit `notes`. Every object referenced exists; nothing assumed.

## 5. Atomicity scenarios (expected states)
A pending/no-discount → cancelled, NULL return, status audit only. B pending/discount → cancelled + REVERSAL + dual audit, funds restored. C already-cancelled retry → replay (existing reversal id or NULL-path confirmation, no new rows). D non-pending client → rejection, zero writes. E concurrent → one winner, loser safe. F reversal failure (MANUAL/missing/pre-reversed) → abort pre-write; order status UNCHANGED (fail-closed); a `cancel_rejected` audit row is written (§10) but NO ledger writes; error surfaces. G duplicate key → existing result. H pre-reversed → clean raise (or replay if key matches). I manual-invoice order → cancel proceeds (invoice layer orthogonal; H2-A). J no-invoice order → identical to A/B. Ledger/audit always: all-or-nothing per attempt.

## 6. Manual-invoice boundary (H2-A enforced by absence)
0021 contains zero invoice-linkage objects, zero order_id references, zero changes to the manual path. `FOLLOW-UP: future invoice-order linkage` requires: fossil-table column review, `order_id` FK migration, linked-row computation rules, no-backfill policy, financial-owner advisory — explicitly NOT in 0021.

## 7. Security model
auth.uid only; role+ownership+state gates in F1; definer+fixed search_path; grant authenticated (least privilege, pattern-consistent); no client ledger/allocation/status-direct writes introduced (branch cancel migrates INTO the RPC); RLS untouched; ledger SELECT policies unchanged. Client cannot: write ledger, mint REVERSAL, mutate POSTED, cancel foreign/non-pending orders.

## 8. Idempotency (F1)
`p_idempotency_key` optional; derived default `CANCEL:{order_id}` for the status attempt (stored on the status audit's reference — audit has `reference` column) and `REVERSAL:DISCOUNT:{order_id}` for money (existing UNIQUE). Retry/timeout/concurrent-duplicate converge via §2 step 6 + constraints. Discount keys (`DISCOUNT:{order}`) untouched and unmixed.

## 9. 0020 compatibility + invoice mechanics (no past-file edits)
`apply/cancel_order_discount`, ledger/allocations/remaining, oldest-first, snapshots, D-defaults, Free-Y, 0017–0019: all untouched and behavior-preserving. F2's OR REPLACE lives in the NEW file. Invoice mechanics (verified, not repeating the old error): allocate re-derives paid-lines total (0016:128-136); discount applies strictly before allocation (both gates require pending); F2 subtracts POSTED discount sum at insert time with negative-floor abort; no-discount orders produce byte-identical amounts (coalesce-neutral).

## 10. Audit events (all via `bonus_audit_trail`)
`order_cancelled` (order entity: actor, old/new status, reason, key, discount-present flag), `REVERSAL` (ledger entity: 0020-style, + cancelling actor), `cancel_rejected` (entity order: actor, cause, snapshot mode where relevant), `cancel_replay` optional lightweight row on key replay (decided at authoring; default: silent replay matching 0020 precedent). No parallel audit system.

## 11. Policy boundary (no tenancy)
Product defaults H1/H2/H3 locked; future tenant homes documented only: H1 states/roles + H3 posture → future company-operational keys; H2 linkage → company structural adoption + financial advisory. No key names, tables, or branches invented.

## 12. Migration order inside 0021
1. Prerequisites (0020 live — already). 2. Optional I1 index (no dependency). 3. No columns/constraints. 4. F1 function, then F2 OR REPLACE (either order safe; F1 first). 5. No policies/triggers. 6. Grants (F1 new; F2 restated). 7. Verification (§14).

## 13. Rollback/failure analysis (no SQL)
Failure points: I1 lock wait on hot ledger (mitigate: ordinary CREATE INDEX, brief lock; no CONCURRENTLY inside migration txn); F2 signature drift vs callers (mitigate: identical signature, verified §0); duplicate-key collisions on first live cancel (impossible pre-0021-use: zero discount rows live). Pre-apply checks: 0020 live (PHASE 18 evidence), no competing 0021 file, function-name collision scan. Post-apply irreversibility: ledger/audit rows from live cancels are financial history (never deleted); code objects re-runnable/droppable. No destructive rollback proposed on production — forward-fix only.

## 14. Test specification (0021)
Setup uses isolated test identities; each states setup/action/expected-result/financial-state: authorized client pending+discount → cancelled+reversal+restored; client foreign order → forbidden, zero writes; client non-pending → rejected; branch own-branch → success; branch other-branch → RLS/forbidden; no-discount cancel → status only; pre-reversed → raise/replay; duplicate key → same result; concurrent pair → single reversal; MANUAL snapshot → abort, status unchanged; missing snapshot → abort; invoice no-discount identical; invoice partial/full subtracted exactly; manual invoice untouched; Free-Y order cancel unaffected; POSTED rows byte-identical post-run; RLS direct-write probes denied; audit rows complete with actor/reason/keys.

## 15. Object contract (sole reference for SQL authoring)
| Object | Type | New/Existing | Purpose | Security | Dependencies |
|---|---|---|---|---|---|
| `cancel_order_with_discount` | FUNCTION (SECURITY DEFINER, search_path=public) | New | atomic cancel + conditional reversal + audits | EXECUTE authenticated; in-function role/owner/state checks | orders, bonus_ledger, bonus_earn_allocations(read), bonus_rules_v2(read), bonus_settings(read), bonus_audit_trail, `bonus_ledger_reverses_uniq`, immutability trigger |
| `branch_allocate_order` | FUNCTION OR REPLACE (identical signature/security/grant) | Existing body, revised in new file | discount-aware invoice total | unchanged (authenticated + in-function branch checks) | + `bonus_ledger` POSTED-discount read |
| `bonus_ledger(order_id)` index | INDEX btree non-unique (optional F6) | New | discount detection + cancel lookups | none (index) | bonus_ledger |
| settings/audit/RLS/triggers/columns/tables | — | None created or altered | — | — | — |

## 16. Final gates + log
Gates: no tenancy/GL ✓; 0017–0020 untouched ✓; no Free-Y contact ✓; no direct client writes ✓; POSTED never mutated ✓; compensation-only ✓; H1=B-NARROW (pending-owner branch in F1) ✓; H2=A (zero linkage objects) ✓; H3=A (abort-before-write + escalation error) ✓; manual independent ✓; idempotency/concurrency/audit/RLS explicit ✓. Each object appears once (§15); dependencies consistent; nothing invented (every name resolves to §§0–1 sources). No conflict found — no BLOCKER/GAP beyond carried items (H-owner approvals pending per 22.2 §8; G1–G4 carried). Operation log: local reads/greps only; no timeouts/auth errors; no live queries; no SQL written; report composed via heredoc (write-tool transport history documented in prior phases).

PHASE 23 COMPLETE
MIGRATION 0021 FINAL SPECIFICATION COMPLETE
OBJECT CONTRACT COMPLETE
CANCELLATION ARCHITECTURE COMPLETE
FINANCIAL ATOMICITY VERIFIED
SECURITY CONTRACT COMPLETE
TEST SPECIFICATION COMPLETE
READY FOR SQL AUTHORING
NO CODE CHANGES
NO SQL CHANGES
NO DATABASE CHANGES
NO MIGRATION CHANGES
