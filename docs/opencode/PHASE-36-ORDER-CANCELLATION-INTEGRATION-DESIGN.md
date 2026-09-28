# PHASE 36 — ORDER CANCELLATION INTEGRATION DESIGN (read-only analysis)

## 1. Executive Summary
One cancel path exists (branch direct status write) and it bypasses everything financial; zero UI calls the live cancel RPC; zero code reads the live history table. The design wires: detail/branch cancel entries → reason sheet → RPC (existing) → reloads → history/timeline display via new reads. No new backend needed except BD-2 values; no migration needed at all. Branch alignment needs no permission change (branch_manager already admitted by the RPC gate) — only the call swap.

## 2. Current Order Center
`orders_tab` (flat list, §Phase 25), `order/:id` detail (content + map + rating + reorder + Phase-21 discount section), `OrderController` (orders/cart/addresses), `BonusWalletController` (funds/ledger/submits with retained-key idempotency), go_router nesting. No cancel entry, no filters, no timeline, no invoice block — all established in prior audits.

## 3. All Current Cancellation Paths
| Current Path | Caller | Role | Backend Used | Financial Safe? | History Recorded? |
|---|---|---|---|---|---|
| Branch action dialog | `branch_order_actions.dart:139-159` → `BranchController.updateOrderStatus` (:262) → `BranchService.updateOrderStatus` (:122, direct `orders` write) | branch_manager | direct status UPDATE, no RPC | NO (strands discounts; no reversal) | NO |
| Branch detail status | `branch_order_detail_screen.dart:77` → same controller method | branch_manager | same direct write | NO (same bypass) | NO |
| Discount removal (NOT order cancel) | `order_discount_section.dart:107` → `removeOrderDiscount` → 0020 `cancel_order_discount` | client (own pending) | 0020 reversal-only RPC | YES (scoped) | N/A (order stays open) |
| Client order cancel | none (zero matches) | — | — | — | — |
| Web cancel | none (no monitoring page with cancel; director pages are bonus/financial/admin) | — | — | — | — |
Bypass anatomy (`branch_order_actions:159`): file → controller → service → raw UPDATE skips: pending/ownership/reversal logic (exists only in RPC), `order_cancellations` insert, dual audit, idempotency keys, fail-closed MANUAL handling. Bonus Discount impact: POSTED debit stays consumed with zero compensation. History impact: zero rows (live count 0 confirms). Audit impact: no `CANCEL`/`REVERSAL` rows from these paths.

## 4. Customer Cancellation Contract (unchanged policy)
H1-B-NARROW (own pending only), reason required (RPC rejects empty), fail-closed, atomic reversal-or-abort, server-decided. UI does not exist; when built it mirrors the discount-section pattern (busy guard, retained key, reload-on-success, error mapping). IMPLEMENTATION GAP (not policy gap).

## 5. Cancellation History Read Model
Backend: table + 3 SELECT policies live; NO RPC, NO view, NO helper for reads (reads are direct SELECTs under RLS — sufficient, no RPC needed). Repository: NOT IMPLEMENTED (no service method). Controller: NOT IMPLEMENTED (no state). UI: NOT IMPLEMENTED. RLS (live-verified): owner-own / branch-unscoped / director-all; zero write policies. Read path needs no backend work — only app reads.

## 6. Order Details Integration (requirements only)
On successful cancel display from existing + new-readable data: status cancelled, `cancelled_at`, `previous_status`, reason (+code when BD-2 lands), source/actor-role (never user identity beyond role), reversal amount + id when `reversal_ledger_id` set (informational, from ledger row). Customer-visible: status/time/reason/reversal-presence. Director-only: actor id, idempotency keys, snapshot references (already in ledger/audit notes). Financial/internal: lot attribution, remainders (never surfaced). No invented fields.

## 7. Timeline Integration
`ORDER CANCELLED` node sourced from `order_cancellations.cancelled_at` (correct source — NOT invented timestamps). 1:N handled by rendering all rows newest-first even though the live workflow yields at most one; no reopen workflow created. Derived nodes (created/scheduled/current) unchanged.

## 8. Branch Cancellation Analysis
Current (§3) vs required: swap the direct write for `cancel_order_with_discount` (reason input added — the dialog currently collects none). No permission change needed: branch_manager of the order's branch is ALREADY admitted by the RPC gate (verified in 0021 text); RLS needs nothing. So: NOT a BUSINESS POLICY question for the standard branch flow — it is pure wiring. Edge: null-branch orders reject fail-closed (director path covers). BUSINESS POLICY REQUIRED only if: cross-branch cancels, delivered-state cancels, or branch visibility beyond current unscoped reads is ever wanted — none proposed.

## 9. Invoice Interaction
Cancel wiring needs NO invoice handling (orthogonal per H2-A; invoices reference no order). Classification: manual path EXISTING + untouched; order-linked invoicing remains BUSINESS POLICY (H2 future). No migration.

## 10. Notifications
Current: generic table + center, `related_offer_id` precedent, zero order linkage. Needed for cancel events: `related_order_id`-style payload + emission on cancel success. Classification: TECHNICAL GAP (payload + emission points), no new system. Not designed further here.

## 11. API/Repository Contract (future, unimplemented)
`cancelOrderWithDiscount({orderId, reason, idempotencyKey?}) → reversalId?`: service wraps the live RPC (auth guard + log/rethrow per `BranchService`/`BonusWalletService` patterns); controller holds busy/error + retained key + reloads (mirror discount submit). `getOrderCancellationHistory(orderId) → rows`: direct RLS SELECT ordered newest-first; no RPC. Auth context: session user; server owns identity/ownership/state/money. Errors propagate verbatim (fail-closed strings). Source of truth: RPC result + ledger/audit/history rows — never client state.

## 12. Error UX Contract
Already-cancelled → info + reload (converged). Non-cancellable → error + reload (state changed under the user). Reversal-impossible (MANUAL) → escalate-to-director message, order untouched. Auth failure → login flow. Timeout → same-key retry (safe by server convergence). Duplicate tap → busy guard + retained key. Rule: success text ONLY after RPC resolves; displays derive from returned ids + re-reads, never optimistic writes.

## 13. Idempotency
Reuse the proven lifecycle (redemption/withdrawal/discount submits in `BonusWalletController`): mint per logical op → submit → retain on transient failure → clear on success. Server backstops: order lock, state convergence, reversal UNIQUE. Cancel needs the same shape, nothing new.

## 14. Security Boundary
Customer: read own orders + own history; cancel own pending via RPC; nothing else. Branch: read (existing scope); cancel via RPC (same gates as today plus money safety); read history per policy. Director: read all; cancel via RPC; full audit/history visibility. No new grants; no role invented; director-apply and client-write paths stay closed.

## 15. Free-Y Separation
New UI touches ledger-sourced discount/reversal rows only; `bonus_rule_id`/free-line logic untouched; paid/free split displays unchanged. Verified pattern from Phase 21 holds for all proposed surfaces.

## 16. Database Requirements
None. Table, policies, index, RPC, grants all live and verified. BD-2 values are data/policy, not schema. Explicitly: no 0023 needed for any §11–§13 item.

## 17. Implementation Boundary
Frontend files (future): branch actions/detail screens, `BranchService`/`BranchController` (+methods), client detail + wallet service/controller (+methods), order service (+history read), l10n keys. Backend: EXISTS (wiring only). Database: NO changes. Tests: service param-mapping (offline fakes), controller key/guard tests, widget state tests — established Phase-21 patterns, no live writes.

## 18. Future Implementation Phases (derived, unapproved)
Phase A — branch swap (reason input + RPC call; kills the bypass). Phase B — client cancel entry + sheet (pending detail). Phase C — history reads + detail/timeline display. Phase D — notification emission + linking. Phase E — regression/E2E (offline + staging protocol). Order: A before B (branch path is the live money risk); C needs only A/B done; D independent.

## 19. Readiness Matrix
| Capability | Backend | Frontend | DB | Policy | Status |
|---|---|---|---|---|---|
| Customer Cancellation | EXISTS live | MISSING | EXISTS | locked H1/H3 | READY FOR IMPLEMENTATION |
| Cancellation History | EXISTS live | MISSING | EXISTS | locked | READY FOR IMPLEMENTATION |
| Order Timeline | derived EXISTS | MISSING | EXISTS | locked | READY FOR IMPLEMENTATION |
| Branch Cancellation | EXISTS live | MISSING (bypass live) | EXISTS | locked (no change needed) | READY FOR IMPLEMENTATION |
| Reversal | EXISTS live | MISSING (trigger) | EXISTS | locked | READY FOR IMPLEMENTATION |
| Audit | EXISTS live | MISSING (display) | EXISTS | locked | READY FOR IMPLEMENTATION |
| Notifications | TECHNICAL GAP | MISSING | TECHNICAL GAP | — | NOT READY |
| Invoice | TECHNICAL GAP | MISSING | BUSINESS POLICY | H2 open | NOT READY |

## 20. Open Business Decisions
BD-2 taxonomy values (final cancel UX/reporting only). H-owner approvals (carried, defaults locked). Invoice linkage, payment, edit semantics (carried, unrelated to cancel wiring). Nothing in §§11–18 requires a new decision first.

## 21. Errors / Timeouts / Corrections
No timeouts, auth flakes, or failures this phase. No corrections; no report-vs-code discrepancies (branch path re-verified line-level; zero-caller claims re-grepped).

PHASE 36 COMPLETE — ORDER CANCELLATION INTEGRATION DESIGN
READ-ONLY ANALYSIS
NO FILES MODIFIED
NO DATABASE CHANGES
NO SQL WRITE
NO MIGRATION CREATED
NO COMMIT
NO PUSH
