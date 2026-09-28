# PHASE 28 — CUSTOMER CANCELLATION CONTRACT (read-only)

## 1. Executive Summary
Cancellation execution is fully specified (0021 file-local, unapplied): atomic cancel + conditional reversal with fail-closed semantics. The ONLY missing piece for final UI is a queryable, governed cancellation-reason store — the RPC demands `p_reason` and persists it in audit rows on success, but audit is write-only history (no order-level readback, no taxonomy, nothing on abort paths). Client has zero cancel UI; branch cancels via direct writes today. `parentOrderId` exists in schema + model but is referenced nowhere else. No code/DB changes made.

## 2. Current Cancellation Facts
A. 0021 `cancel_order_with_discount(p_order_id uuid, p_reason text, p_idempotency_key text default null) returns uuid`: auth.uid-first; roles client(owner, pending-only)/branch_manager(branch-match, null-branch reject)/director; delivered rejected for all; order `FOR UPDATE` first; latest POSTED ORDER_DISCOUNT detection; one-effective-reversal guard + unique-index backstop; H3 abort pre-write on non-AUTO/missing snapshot; full-amount POSTED REVERSAL with `reverses_id` + `REVERSAL:DISCOUNT:{order}` key; rowcount-guarded status flip; dual audit; returns reversal id or NULL; full rollback on any failure. Unmodified since review (hash-gated in 24.2).
B. Reason storage: NOTHING exists — zero matches for cancel_reason/cancellation_reason/reason/note/metadata/status-metadata/order-history across schema, migrations, models, services, controllers, UI, and translations. `orders.notes` is creation-time notes (never written post-creation; branch service has zero notes writes). Therefore: TECHNICAL GAP — NO CANCELLATION REASON STORAGE EXISTS (beyond 0021's own audit writes, see §12).

## 3. Product Policy Check (22.3/27 vs code)
Pending-only client cancel, server-authoritative, atomic reversal, POSTED immutability, compensating-only reversal, fail-closed, no direct ledger writes — all hold in 0021's text (verified line-by-line in 24.1). No report-vs-code conflict found.

## 4. Cancellation Reason Options (analysis only)
OPTION A — `orders.cancellation_reason` (+ maybe `cancelled_at`, though `created_at` exists and no `updated_at` does): minimal schema (one nullable text), RLS inherits orders policies, model +1 field, API transparent via existing order reads, one additive migration, audit unchanged (RPC already logs reason). Con: free-text only unless paired with taxonomy; reason on abort paths still unpersistable.
OPTION B — `order_cancellations` table (order FK unique, reason, cancelled_by, cancelled_at, previous_status): full history shape, extensible (appeals, partial cancels), heavier (table + RLS + model + reads). Nothing like it exists today.
OPTION C — JSON/metadata: NO metadata mechanism exists anywhere in the project (verified absent) — not viable without inventing one; rejected as a path (would be new architecture disguised as reuse).

## 5. Cancellation Reason Decision Matrix
| Option | Existing Support | New Schema | RLS Impact | Model Impact | Auditability | Future Extensibility | Status |
|---|---|---|---|---|---|---|---|
| A column | none (notes is creation-only) | 1 nullable column | inherits orders | +1 field | success paths already logged | low (single value) | REQUIRES MIGRATION |
| B table | none | new table + FK + RLS | new policies | new model + reads | richest | high (history, appeals) | REQUIRES MIGRATION |
| C metadata | none exists | invent mechanism | unknown | unknown | poor | misleading | TECHNICAL GAP (no mechanism) |

## 6. Reason Policy (business vs technical)
Undecided and needed before final UI: fixed list vs director-configurable vs free text vs list+note vs code+label. This is a BUSINESS POLICY decision; storage (A/B) is TECHNICAL IMPLEMENTATION. Either storage supports any taxonomy shape except open-ended history (B only). No selection made.

## 7. Product-Sale Analysis
Fixed product-level reason set ships safely today (zero schema for the taxonomy itself — codes as constants); company-configurable reasons need tenant configuration that DOES NOT EXIST — recorded as FUTURE ARCHITECTURAL DEPENDENCY, no tenant system built or implied. Director-configurable without tenancy would leak across future companies; therefore defer configurability, ship fixed-or-free-text per business decision.

## 8. Cancellation UX Contract (design only)
Detail (pending) → Cancel entry → confirmation sheet → reason control (shape per §6 decision; RPC rejects empty) → final confirm → service/controller call (new methods mirroring discount pattern: busy guard, retained idempotency key) → success: reload order+list+wallet, show reversal via history → error: fail-closed message, state unchanged, safe retry. Button visible pending-only; hidden otherwise (server re-validates). Stale-pending race (branch allocates first): server rejects, UI surfaces error + reloads — no client prediction. Timeout/duplicate: same-key retry converges server-side. Discount: informational pre-confirm (applied amount from ledger); no client math. No-discount: same flow minus reversal row.

## 9. Concurrency Analysis
Pending-at-open → branch allocates/updates first: 0021 serializes on the order lock; loser meets the state gate (client non-pending → reject; branch proceeds). Invoice issuance mid-flight changes nothing about cancel mechanics (invoice orthogonal per H2-A). No client-side assumptions permitted — every race resolves server-side with at-most-once money effects (guard + unique index + single txn).

## 10. Bonus Discount Interaction
Without discount: status + audit only, NULL return. With discount: same + compensating REVERSAL (fresh credit, allocations intact, funds restored). UI performs zero Bonus computation, zero ledger writes, zero manual reversals — verified absent from Flutter (only RPC names referenced). Reversal visibility comes free via existing history labels.

## 11. Reorder Interaction (Edit = Cancel + Reorder)
Old order: cancelled (reason stored per §4 outcome), discount reversed if present, history preserved. New order: rebuilt via existing refill-cart → creation RPC (current prices/stock/Free-Y/discount re-evaluated; old prices never reused). `parentOrderId` linkage of new→old is possible but undecided (business policy + backend write path needed).

## 12. parentOrderId Analysis
Schema: EXISTS (0002:130). Model: EXISTS (+freezed boilerplate). Reads: NONE. Writes: NONE. Repository/query support: NONE. Verdict: CURRENTLY UNUSED. No migration needed for storage; semantics + write path are the actual gap.

## 13. Audit Analysis
0021 writes: `REVERSAL` ledger audit (actor, reversed id, kind, amount, reason) + `order`/`CANCEL` audit (actor, old/new status, reversal id, reason, idempotency key in reference). Actor/order/discount/reason/outcome all covered on success. Abort paths persist nothing (rollback-imposed; failures surface as RPC errors for app logs — same precedent as 0018/0020). Reason is therefore stored but NOT queryable per order (audit is append-only history); adding reason readback needs §4 storage. No audit changes in this phase.

## 14. Final Backend Contract
Customer → Order Details → Cancel Request → Required reason (§6 shape) → `cancel_order_with_discount` (auth.uid → role/ownership → pending gate (H1) → order lock → discount detect → snapshot gate (H3) → atomic cancel+reversal → dual audit → id-or-NULL) → UI reload. Mapping: UI (future detail entry) → service/controller (future methods) → RPC (0021 file-local, unapplied) → `orders` + `bonus_ledger` + `bonus_audit_trail` (all existing).

## 15. Migration Boundary
Reason store (A or B): MIGRATION REQUIRED (object + constraints + index + RLS + model/reads) — not created here. 0021 application itself: no new migration (file exists; needs human apply). Nothing else outstanding for cancel execution.

## 16. Phase Dependencies
Buildable now (no backend): Center filters, status grouping, derived timeline, existing reorder/buy-again, discount display. Needs backend contract: final cancel UI + reason store + reason taxonomy. Future: payment, order-linked notifications, invoice architecture, edit-linkage semantics.

## 17. Business Decisions Required
BD-1 reason shape (fixed list / configurable later / free text / list+note / code+label; blocks final cancel UI; storage independent). BD-2 reason compulsory vs optional-with-default (RPC requires non-empty; UI default string is a policy call). BD-3 reorder-history linkage via `parentOrderId` (needs backend write path if yes). BD-4 cancel-reason visibility (who reads it: client/branch/director/auditor).

## 18. Evidence / File References + Final Freeze
0021:34-38 signature, :61 reason requirement, :137-147 reversal+audit, :161-166 status audit; 0002:130 parent id; order.dart:16 model field; zero reason/metadata matches repo-wide; zero client cancel matches; zero post-creation item writes; audit `reason` column 0018:322. Transport note: one ECONNRESET on an empty call; content resent intact.
FROZEN: 0021 semantics, H-locks, server-authority, no item patching. No BUSINESS selection made (§6/BD open). Nothing built, applied, or modified.

PHASE 28 COMPLETE — CUSTOMER CANCELLATION CONTRACT
NO CODE MODIFIED
NO DATABASE CHANGES
NO SQL EXECUTED
NO MIGRATION CREATED
NO COMMIT
NO PUSH
