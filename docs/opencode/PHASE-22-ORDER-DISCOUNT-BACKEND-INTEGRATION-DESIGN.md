# PHASE 22 — ORDER DISCOUNT BACKEND INTEGRATION DESIGN (read-only)

## 1. Current cancellation architecture
Exactly one cancel path exists: branch manager UI `branch_order_actions.dart:159` → `BranchService.updateOrderStatus` (`branch_service.dart:122-130`) → direct `orders` status write. No cancel RPC exists anywhere. RLS `orders_manager_update` (0002:156) permits branch_manager, company_director, or assigned driver to write ANY status with no transition guards. Actual actors: branch manager only (client has zero cancel code; web `OrdersMonitoringPage` reads + transfers + notifies, never writes status; driver has no cancel UI). Transaction boundary: single-row update, no bonus contact, no audit beyond app logs.

## 2. Current invoice architecture
Path 1 — allocate: `branch_allocate_sheet.dart:179` → `allocateOrder` (service:464-471) → `branch_allocate_order` (0016:106+) which RECOMPUTES the invoice total from allocated paid lines (`v_total += least(allocated,paid) × price`, 0016:128-136) and inserts `invoices(client,branch,amount,status,due)` (0016:145-148) in the same txn that flips pending→assigned. Correction to earlier phrasing: it re-derives, not snapshots, `orders.total_amount` — outcome identical for discount purposes (ledger ignored). Path 2 — manual: sheet hand-amount → `createInvoice` (service:508-527) → direct insert; RLS `invoices_branch_manager_insert/update` (0009:78-95) restricts to own-branch managers. Structural discovery: `invoices` has NO creation migration (table predates the chain) and NO `order_id` column (inserts never include one) — order-linkage is structurally impossible without schema change. No other invoice paths exist.

## 3. Financial source of truth
"Reversible discount?" = one query, no new state: POSTED `bonus_ledger` row with `txn_type='ORDER_DISCOUNT'`, `order_id=X`, and no POSTED `REVERSAL` with `reverses_id` = that id (constraint-backed by `bonus_ledger_reverses_uniq`). No duplicate/order-level financial columns proposed or needed. `orders.total_amount` semantics (verified 0017:205,218): gross paid-lines total at creation, Free-Y excluded, no other discounts inside, no net field anywhere — so: Invoice == Gross − POSTED discount holds exactly against current reality.

## 4. Cancellation design (options ranked by architecture fit)
Recommended: C — new `cancel_order_with_discount(p_order_id,p_reason,p_idempotency_key?)` (name illustrative) doing, in ONE definer txn: authorize caller (branch_manager of order's branch OR director OR — decision §17 — owner-client) → lock order → require cancellable state → set `cancelled` → detect reversible discount (§3 query) → if present and snapshot=AUTO: inline reversal with 0020's exact guards (POSTED-only, one-effective, full compensation, REVERSAL key, audit) → audit status change. No 0017-0020 file touched (0020 logic duplicated in small, documented).
- A app-level call: REJECTED — branch_manager is refused by `cancel_order_discount` (0020:334); two calls/two actors = the stranded-discount race by design.
- B modify existing cancel RPC: N/A — none exists.
- D trigger on orders: NOT RECOMMENDED — runs on every orders write, reason/audit ergonomics poor, auth-context subtleties, harder to test and to fail-closed with clear UX; trigger WHEN-clause alternative documented but ranked below C.
- E internal helper: accepted as implementation detail INSIDE the new migration (shared reversal block), not as the interface.
Atomicity answer (§5): stranded `cancelled + consumed discount` is possible TODAY on every cancel (reversal never attempted) — the inconsistency the design closes. Fail-closed rule: MANUAL-snapshot discount + cancel request → abort with explicit error (no silent cancel-without-reversal); alternative (cancel + review flag) needs a flag store = schema = heavier; recommended fail-closed.

## 5. Atomicity design
Single RPC transaction: locks → status → reversal → audits → commit. Any failure rolls all back: no partial cancelled-without-reversal, no reversal-without-cancel. Requires the new RPC (§4C); current two-step app flow cannot be made atomic without it. Proposed signature only (no SQL): `cancel_order_with_discount(p_order_id uuid, p_reason text, p_idempotency_key text default null) returns uuid` (returns reversal id or null when no discount existed).

## 6. Idempotency design
Status write is naturally idempotent (cancelled→cancelled). Reversal reuses 0020 machinery: default key `REVERSAL:DISCOUNT:{order}`, pre-check + `bonus_ledger_reverses_uniq` backstop — no parallel financial system invented. Cancel-once/twice/timeout/concurrent all converge: first wins, rest raise-or-replay, never a second posting or double restoration.

## 7. Authorization design
Cancel permission stays where it is (branch_manager of branch / director; RLS unchanged) — reversal is an automatic CONSEQUENCE of an authorized cancel, not a separate permission (definer authority, actor=`auth.uid()` recorded). No user_id/actor_id parameters anywhere (current code has none; design adds none). Open business decision: whether owner-clients may cancel their own pending orders through the new RPC (they can hold discounts but today cannot cancel at all).

## 8. Invoice invariant
Order-linked: `invoice.amount = recomputed paid total − POSTED ORDER_DISCOUNT sum(order)`. No-discount: unchanged value (subtract zero/NULL → identical; zero behavior change for all existing flows, provable). Manual/unlinked: path untouched and functional. Invariants preserved: no unit_price/product/Free-Y/GL changes; client never the source (allocate computes server-side as today).

## 9. Invoice security
Client cannot create invoices (no insert policy for client; 0009 gate is branch_manager + branch match) and cannot set amounts anywhere (allocate computes; manual is manager-typed). Controller trusts UI amount only on the standalone manager path — by design for non-order billing, not a bypass once order-linked billing is separated by ruling. Order authorization is server-side in allocate (branch scope) and RLS. No client bypass vector found; required fix is the Path-1 computation change (§8), not an auth fix.

## 10. Allocation interaction
Locked order holds structurally: discount RPC requires `pending` (0020:118) and allocate requires `pending` before flipping to `assigned` (0016:53,141-143) — discount MUST precede allocation, proven from both gates. Invoice is written inside the allocate transaction (0016:145-148), so the discount-aware computation lands in exactly one place with no cross-call consistency problem. No allocation modification.

## 11. Failure matrix
| Scenario | Current | Desired | Backend change |
|---|---|---|---|
| cancel without discount | status flips, nothing else | same | new RPC (uniform path) |
| cancel with discount | stranded POSTED debit | atomic status + reversal | new RPC §4C |
| cancel twice | same write twice | same + no second reversal | guards + unique index (exist) |
| cancel timeout | unknown outcome | retry-safe same result | idempotency keys (exist) |
| concurrent cancel | last-write-wins | serialized, one reversal | order lock in new RPC |
| invoice without discount | paid-lines total | identical | none (coalesce-neutral) |
| invoice with discount | ignores discount | total − posted discount | allocate computation in new migration |
| invoice manual/unlinked | works standalone | works standalone | none (by ruling) |
| invoice duplicate | allocate re-run guarded by status gate | unchanged | none |
| unauthorized cancellation | RLS role check only | same + in-RPC check | new RPC carries checks |
| unauthorized invoice | RLS branch check | unchanged | none |

## 12. Migration blueprint (design only, no SQL)
Suggested `0021_order_discount_backend` (next number): (a) NEW function cancel RPC (§5 signature) + EXECUTE to authenticated; (b) `CREATE OR REPLACE branch_allocate_order` (identical signature) adding discount subtraction + comment, in the NEW file (0016 file untouched); (c) optional F6 index `bonus_ledger(order_id)`; (d) optional `invoices.order_id` FK only if owner wants linkage (no backfill possible — history has no link). Dependencies: 0020 live (already). RLS: none changed. Rollback: re-runnable OR REPLACE; new function droppable; allocate change is behavior-neutral when no discounts exist. 0017–0020 files: untouched by rule.

## 13. Application impact
Phase-21 code needs small swaps after backend lands: branch cancel action calls the new RPC instead of direct status update (new `BranchService`/`BranchController` methods mirroring existing patterns); order-detail discount UI unchanged; invoice UI unchanged (optional order-link only if column added). No service/controller redesign; no new screens.

## 14. Test blueprint (backend, designed not executed)
Cancel: 1 no-discount cancel (status only, null return); 2 discount+cancel (atomic reversal, funds restored); 3 twice (one reversal); 4 timeout+retry (same result); 5 concurrent (one winner); 6 pre-reversed (clean raise); 7 unauthorized role (branch of other branch / anon → raise); 8 wrong ownership (client other's order → raise). Invoice: 9 no discount (identical amount); 10 partial (total−applied); 11 full available; 12 over-request clamped server-side; 13 manual amount untouched; 14 unlinked manual allowed; 15 re-run allocate blocked by status gate; 16 manager other-branch denied by RLS. Financial: 17 lots restored via fresh credit (no un-consume); 18 single compensation (unique index); 19 POSTED immutable (trigger); 20 Free-Y lines price-stable.

## 15. Decision gate
A. New migration? YES (0021 suggested). B. Modify existing cancel RPC? N/A — none exists. C. New cancel RPC? YES (§4C recommended). D. Trigger? NOT RECOMMENDED (ranked, §4). E. Invoice backend change? YES for allocate computation; manual needs owner ruling not code. F. Phase-21 app changes? YES, small swaps (§13). G. Without schema change? Cancel YES; invoice Path-1 YES; Path-2 linkage NO (needs `order_id` column) — avoidable by ruling. H. New business decisions? YES: (H1) owner-client cancel rights; (H2) manual-invoice scope (standalone-only vs order-linkable); (H3) MANUAL-snapshot cancel posture (fail-closed recommended). D1–D4 unchanged, no new financial decisions.

## 16. Risks and unresolved gaps
R1: `invoices` table has no creation migration — any ALTER should be preceded by a fossil-record review (columns known by usage only). R2: fail-closed cancel may surprise branch UX under MANUAL tenants — needs an announced error string + director escalation path. R3: no staging env — backend tests need an isolated identity/rollback protocol before live execution. R4: transfer→pending re-opens the discount window (PHASE 19) — cancel RPC should consider transferred orders explicitly. Open: H1–H3 rulings; F6 index timing; GL/tenant tracks untouched.

## Operation log
No live queries this phase (nothing to re-prove post-18). No timeouts/auth errors (local reads only). One aborted shell call (empty combined grep, pre-restart) + one post-restart workdir typo — both retried successfully with corrected commands. Discrepancy corrected: allocate invoice is RE-DERIVED from paid lines (0016:128-136), not a snapshot of `orders.total_amount` — outcome for discounts identical, mechanics recorded precisely here.

PHASE 22 STATUS:
BACKEND INTEGRATION DESIGN COMPLETE
NO CODE CHANGES
NO SQL CHANGES
NO DATABASE CHANGES
NO MIGRATION CHANGES
