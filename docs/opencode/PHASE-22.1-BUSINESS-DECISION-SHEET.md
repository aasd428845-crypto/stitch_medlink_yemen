# PHASE 22.1 — H1/H2/H3 BUSINESS DECISION SHEET (read-only)

## 0. Verbatim extraction (Phase 22 §15H, not paraphrased)
- **H1**: "owner-client cancel rights"
- **H2**: "manual-invoice scope (standalone-only vs order-linkable)"
- **H3**: "MANUAL-snapshot cancel posture (fail-closed recommended)"
Supporting exact text: §7 "open business decision whether owner-client cancel"; §12G "Path-2 linkage … avoidable by ruling"; §5 "MANUAL-snapshot discount + cancel request → abort with explicit error … alternative (cancel + review flag) needs a flag store"; §16 R2 "fail-closed cancel may surprise branch UX under MANUAL tenants". NOTE: the task prompt's §5/§6 detail hints are swapped relative to these definitions (§5 hints describe H3's area, §6 describe H2's). This sheet follows the TRUE Phase-22 IDs; all hinted analysis points are covered under their correct decision.

## 1. H1 — owner-client cancel rights
Business question: may a client cancel their own order (and thereby trigger the automatic discount reversal), or does cancellation stay a branch/director-only act? Why owner: it creates a new client capability with operational/financial side effects (self-service refunds of consumed bonus). Options: H1-A status quo (no client cancel; branch/director cancel via new RPC, reversal automatic whoever cancels); H1-B owner-client may cancel own non-final orders via the new RPC (same atomic reversal); H1-C narrow (client cancel only when no POSTED discount exists on the order; discounted orders require branch/director). Technical per-option: A = role check excludes client in new RPC; B = owner check `order.client_id=auth.uid()` + cancellable-state gate; C = B plus pre-check rejecting discounted orders with directed error. Impacts: Client (A: none; B: new self-service power + stranded-risk removed; C: partial), Branch (B/C reduce cancel workload), Director (unchanged oversight), DB (role-check lines only), Bonus (B: client-triggered reversals restore funds — ledger-safe by construction), Invoice (none — cancel precedes/follows billing per existing flows), Cancellation (uniform RPC path in all options), Audit (actor recorded from auth.uid in all), SaaS (capability varies per company appetite — future company toggle candidate). Changeable later without migration? NO as coded (role check is code); YES if shipped behind a settings key (recommend noting, not building). Global vs company: today global behavior (no tenant store); natural future company-specific operational setting. Existing data: zero impact (no live discounts; additive capability). Financial owner: NO (operational access-control, not accounting).

## 2. H2 — manual-invoice scope
Business question: may a hand-typed invoice settle (or reference) a specific order, or must manual invoices remain standalone non-order billing? Why owner: it decides whether a bypass channel to discount-aware billing stays open and whether schema (order linkage) is ever built. Options: H2-A standalone-only (manual invoices must never reference an order; enforced by policy/UI wording, no schema); H2-B order-linkable (add linkage + discount-aware computation for linked invoices); H2-C hybrid (unlinked allowed as today + linked allowed with invariant enforcement). Technical: A = zero code/schema (convention + UI hint); B = `invoices.order_id` FK (new migration) + computation rules + backfill impossible (history has no link — new rows only); C = B plus keeping the unlinked path. Impacts: Client (none directly), Branch (A restricts current habit — managers may today bill orders manually, unknowable from code since no link exists: RISK), Director (B/C give reconcilable books), DB (A: none; B/C: ALTER + index), Bonus (B/C close the bypass for linked invoices), Invoice (core subject), Cancellation (none), Audit (B/C add link traceability), SaaS (billing discipline varies per company — strong company-specific candidate). Changeable later: A→B/C needs migration (one-way structural step); B→A is policy-only. Existing data: A changes nothing; B/C affect new rows only. Financial owner: ADVISORY — required only if linkage is deemed to touch revenue recognition per tenant; the neutral mechanics need no accountant.

## 3. H3 — MANUAL-snapshot cancel posture
Business question: when an order carrying a MANUAL-mode discount is cancelled, does the system refuse (fail-closed) or cancel anyway and leave money for later settlement? Why owner: it trades branch UX smoothness against temporary financial inconsistency, under a policy a future tenant explicitly chose. Options: H3-A fail-closed (abort cancel, explicit error + director-escalation path); H3-B cancel-without-reversal plus review flag (needs a flag store — schema or audited review queue); H3-C route to director settlement queue without changing order status (hold-pending-review). Technical: A = raise inside new RPC before any write (fully atomic, zero schema); B = status write + flag write in one txn (needs store); C = no status change, review row (needs store or reuses notifications infra). Impacts: Client (A: cancel denied with reason; B/C: cancel accepted, funds pending), Branch (A: friction + escalation call; B/C: smooth), Director (B/C create review workload), DB (A: none; B/C: new store), Bonus (A: never inconsistent; B/C: bounded inconsistency window), Invoice (none — pre/post-billing orthogonal), Cancellation (uniform vs two-track), Audit (all options fully logged), SaaS (risk appetite differs per company — company-operational candidate). Changeable later: YES via new migration (behavioral lines); snapshot mechanics themselves fixed by 0020. Existing data: zero (no MANUAL snapshots can exist — global default is AUTO and no discounts exist live). Financial owner: NO.
Policy snapshot note (prompt §5): MANUAL posture does NOT need a new snapshot — the snapshot already carries `cancellation_mode` (0020); the decision only selects the enforcement branch. No new snapshot fields for any option.

## 4. Product-sale principle (no selection made)
- H1: today necessarily A-fixed-in-code or B-fixed-in-code (D in effect: role capability). No tenant store exists, so company-specific (C) is future-only; nothing here is financial (not E). Simplest shippable: a global code rule; extensible: a future operational key.
- H2: A is convention (B-policy-like without a settings object); B/C are structural + company appetite (future C-financial-adjacent). Not E by itself; becomes E-adjacent only if linkage carries revenue meaning per tenant.
- H3: behavioral branch in code (A today cheapest); B/C are heavier operational machinery. Future company-operational setting candidate. Never E (no accounting content).
Guidance recorded without choosing: prefer the option that ships safely global today while leaving the company-specific door open (keys/namespaces, not hard-coded tenant branches).

## 5. Invoice architecture re-verification (from current files)
Confirmed: no `order_id` on `invoices` (inserts in 0009:187, 0016:146 carry client/branch/amount/status/due only); no creation migration for the table (fossil object — ALTER needs care, R1); allocate re-derives paid-lines total (0016:128-136); `orders.total_amount` = gross paid-lines at creation (0017:205,218); discount outside total; Free-Y anchored at 0017:12 `bonus_rule_id`. Alternatives: A add `order_id` (enables linkage + invariant; one-way schema step); B different relation (e.g. order→invoice memo table — heavier, no benefit found); C order-only invoices (kills standalone billing — rejected implicitly by current manager workflows); D standalone-only (zero change, bypass stands); E hybrid (A for linked + D preserved). What 0021 needs decided: link-vs-standalone ruling (H2) before any invoice code.

## 6. Cancellation architecture re-check (H-impact on each step)
New-RPC skeleton (design, not code): lock order → authorize (H1 decides the client branch) → verify cancellable state → detect reversible discount (ledger query, no new state) → branch on snapshot mode (H3 decides MANUAL branch) → compensating reversal (0020 guards) → set cancelled → dual audit → commit; any failure rolls all back. H1 alters step 2 only. H2 alters nothing here. H3 alters the MANUAL branch only (A aborts pre-write; B/C add flag/queue writes). Idempotency/concurrency (existing UNIQUE + locks) unaffected by all options.

## 7. Migration 0021 gate inventory (expected, no SQL written)
New: function `cancel_order_with_discount` (+EXECUTE to authenticated); optional F6 index `bonus_ledger(order_id)`; optional `invoices.order_id` FK + index (ONLY under H2-B/C); optional review-flag store (ONLY under H2... under H3-B/C). Modified-in-new-file: `branch_allocate_order` OR REPLACE (discount subtraction). Grants: cancel-RPC execute; nothing revoked. RLS: untouched. Triggers: none. Files 0017/0018/0019/0020: untouched by rule. Rollback: droppable function, re-runnable OR REPLACE, neutral-when-no-discount allocate math.

## 8. Decision table
| ID | Business question | Option | Technical effect | SaaS impact | Financial owner needed? | Can change later? |
|---|---|---|---|---|---|---|
| H1 | May owner-clients cancel own orders? | A status quo | role check excludes client | uniform, restrictive | No | Yes (new migration; or key if built so) |
| H1 | same | B allow + atomic reversal | owner check + same reversal path | self-service per company appetite | No | same |
| H1 | same | C allow only undiscounted | B + discount pre-check + directed error | middle ground | No | same |
| H2 | May manual invoices settle orders? | A standalone-only | convention + UI hint, zero schema | uniform discipline | No | Yes (policy); A→B needs migration |
| H2 | same | B order-linkable | order_id FK + invariant computation | reconcilable books | Advisory if revenue-linked | New rows only |
| H2 | same | C hybrid | B + preserved unlinked path | company choice | same as B | same as B |
| H3 | MANUAL-discount cancel posture? | A fail-closed | abort pre-write, escalate | uniform safety | No | Yes (migration) |
| H3 | same | B cancel + review flag | status + flag in one txn (new store) | bounded inconsistency window | No | Yes (migration) |
| H3 | same | C hold for director review | no status change, queue entry | smooth ops, review load | No | Yes (migration) |

## 9. BUSINESS OWNER MUST CHOOSE
H1: Question: may owner-clients cancel their own orders (triggering automatic reversal)? Option A: No — cancellation stays branch/director-only. Option B: Yes — owner-client cancel via the atomic RPC. Option C: Yes, but only orders without an applied discount.
H2: Question: may hand-typed invoices settle a specific order? Option A: No — manual invoices are standalone billing only. Option B: Yes — with order linkage and discount-aware amounts (needs schema). Option C: Both — unlinked allowed as today, linked allowed with enforcement.
H3: Question: when a MANUAL-mode discount meets cancellation? Option A: Refuse the cancel with explicit error + director escalation. Option B: Cancel now, flag for later settlement (needs review store). Option C: Hold without cancelling, route to director review.

## 10. Operation log
No live queries (nothing to re-prove post-18). No timeouts/auth errors (local reads only). No discrepancies vs Phase 22 (all citations re-verified: RLS 0002:156, invoice RLS 0009:78-95, allocate 0016:128-148, total 0017:205/218, Free-Y 0017:12, RPC gate 0020:334, H-text §15H). Prompt §5/§6 swap discrepancy recorded in §0 and handled.

PHASE 22.1 STATUS:
BUSINESS DECISION SHEET COMPLETE
WAITING FOR OWNER DECISION
NO CODE CHANGES
NO SQL CHANGES
NO DATABASE CHANGES
NO MIGRATION CHANGES
