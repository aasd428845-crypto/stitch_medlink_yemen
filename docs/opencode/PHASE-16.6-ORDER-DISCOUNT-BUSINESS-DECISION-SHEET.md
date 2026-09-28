# PHASE 16.6 — ORDER DISCOUNT BUSINESS DECISION SHEET (decision sheet only — no code/SQL/DB changes)

## 1. Executive Summary
This sheet presents every business/financial decision the owner must make before Migration 0020, with options verified against the local repository and PHASE 16.5 contract. No option is ranked or recommended. Statuses: D1, D2-scope, D3-mode, D5, D6 = OWNER DECISION REQUIRED; D4 = FINANCIAL OWNER REQUIRED; D2-override and D8-snapshot = ALREADY CONTRACTED (not re-asked); D7 = OWNER DECISION REQUIRED (ownership assignment). No code, SQL, migration, RLS, role, or UI change is made in this phase.

## 2. Sources Inspected
PHASE-16, 16.1, 16.2, 16.3, 16.4, 16.5 (local, read in full). Code verification this phase: `0018:58` (`ORDER_DISCOUNT` in ledger CHECK), `0018:143` (`allow_discount` on `bonus_rules_v2`), `AuthContext.tsx:8,54` (sole enforced role `company_director`), migration list tail (latest = `0019`, next = `0020`). CONTRACT / CODE DIVERGENCE: none — contract claims confirmed verbatim against current files.

## 3. Current Technical Facts
- Discount type exists (`ORDER_DISCOUNT`), no RPC creates it yet; rule gate exists (`allow_discount`, default false); allocation is oldest-first with remainder caps; ledger has UNIQUE idempotency + `reverses_id`; audit trail has who/what/old/new/reason but no version column; settings KV has no history.
- Discount applies before `branch_allocate_order` (invoice snapshots total at allocation); item prices immutable; Free-Y path separate; only `company_director` enforced — no finance role; manual-amount `createInvoice` bypass exists (`branch_service.dart:508` ← `branch_controller.dart:216` ← sheet `:55`).

## 4. Decision Rules
- OWNER DECISION: business/financial value choice — only the owner (or financial owner for D4) may fill it. This sheet states effects, never preferences.
- TECHNICAL INVARIANT / ALREADY CONTRACTED: fixed by architecture or PHASE 16.5 contract — recorded, not re-asked.
- IMPLEMENTATION DETAIL: resolved inside Migration 0020 design within contract bounds — not an owner question.
- No scores, rankings, recommendations, winners, or preferred options appear in this sheet.

## 5. D1 — Zero Order
Question: may Bonus Discount cover 100% of an order (remaining = 0)? Status: OWNER DECISION REQUIRED. Key (contracted): `discount.allow_zero_order` (boolean, Global only).
- D1-A — ALLOW_ZERO_ORDER: Technical effect: applied amount may equal order total (`applied <= total`); zero-total orders flow onward to allocate/invoice. Financial/business effect: zero-receivable orders exist in records; downstream reporting must handle 0-amount payables. Order lifecycle: unchanged states, zero-total permitted. Invoice: invoice amount may be 0 where order-linked. Cancellation/reversal: reversal restores full amount under either D3 mode. Compatibility: additive; no existing rows affected (no discount path exists today).
- D1-B — REQUIRE_POSITIVE_REMAINING: Technical effect: applied amount strictly below total (`applied < total`); full-cover requests rejected or capped below total. Financial/business effect: every discounted order retains a positive receivable. Order lifecycle: additional rejection path at discount time. Invoice: order-linked invoices always positive. Cancellation/reversal: unchanged mechanics, smaller amounts. Compatibility: additive; same as D1-A regarding existing rows.

## 6. D2 — Funding Scope
Question: which bonus lots may fund Order Discount? Status: OWNER DECISION REQUIRED. Global key (contracted): `discount.funding_scope`; rule gate (existing): `bonus_rules_v2.allow_discount`; type derivation (existing): `rule_type` ∈ PRODUCT/MONETARY/GENERAL via EARN `rule_id` links.
- D2-A — ALL_ELIGIBLE_LOTS: Qualifying lots: any POSTED positive lot passing balance/expiry/suspension/account checks and rule gate. Allocation interaction: existing oldest-first walk unfiltered by type. PRODUCT/MONETARY/GENERAL: all types eligible where `allow_discount` permits. FIFO effect: pure oldest-first preserved. Redemption/withdrawal competition: shared pool — discount consumes lots also spendable elsewhere (ledger truth governs). Audit: funding lots traced via `bonus_earn_allocations` rows.
- D2-B — MONETARY_ONLY: Qualifying lots: only lots whose originating rule is MONETARY (plus all other eligibility checks and rule gate). Allocation interaction: type filter applied during lot selection, before any write. PRODUCT/GENERAL lots: excluded even when otherwise eligible. FIFO effect: oldest-first within the monetary subset. Competition: product/general balances untouched by discounts. Audit: same allocation trace; exclusion reason derivable from rule type.
- D2-C — RULE_CONTROLLED: NOT CURRENTLY IMPLEMENTABLE as a standalone global value — reason: PHASE 16.5 contract (§6) establishes rule control is not a third global enum value; it is the separate existing rule flag (`allow_discount`) combined with D2-A or D2-B. Rule-level narrowing/widening behavior is governed by the override boundary (§7), not by a third scope value. Recorded here, not deleted.

## 7. D2 — Override Boundary
Contract state: ALREADY CONTRACTED in PHASE 16.5 (§7, Model C narrow-only) — not an owner question; no selection recorded here.
- Locked rule: Global sets the upper boundary; Rule restricts inside it; Rule never widens Global; Order contributes caps only.
- Worked case 1 — Global MONETARY_ONLY × Rule allow(PRODUCT): lot excluded (rule cannot widen global to admit product lots).
- Worked case 2 — Global ALL_ELIGIBLE_LOTS × Rule disallow (any type): lot excluded (rule narrows global).
- Invalid combinations resolve to exclusion, never to widening.

## 8. D3 — Cancellation
Question: what happens when an order with applied discount is cancelled? Status: OWNER DECISION REQUIRED (mode only — temporal rule below is contracted). Global key (contracted): `discount.cancellation_mode`.
- D3-A — AUTOMATIC_REVERSAL: Ledger: compensating REVERSAL row linked via `reverses_id` to the original ORDER_DISCOUNT debit. Consumed lots: remainders recomputed by existing credit-remaining logic; restored availability follows ledger truth. Automatic: yes, inside the cancel path. Audit: new audit entry per reversal. Already-spent-elsewhere: reversal restores ledger balance; competing spends already posted stand (no retroactive claw-back; ledger ordering governs). Insufficient balance for reversal: reversal is a compensating credit to the account — it does not require a positive balance to post (it increases availability); structural caps do not block it. Snapshot effect: the mode captured at discount time governs (§13 CONTRACTED).
- D3-B — MANUAL_REVIEW: Ledger: no automatic compensation; original discount stands until an audited admin action settles it. Consumed lots: unchanged until settlement. Automatic: no; status guard blocks auto-compensation. Audit: review/settlement entries when actioned. Already-spent-elsewhere: same ledger-truth position as D3-A; settlement decision is administrative. Insufficient balance: not applicable until settlement action defines it. Snapshot effect: same contracted snapshot rule — the captured mode (MANUAL) is what requires review.

## 9. D4 — Accounting
Question: what is the accounting substance of the discount? Status: FINANCIAL OWNER REQUIRED. Concept (reserved, never a director setting): `accounting.discount_treatment`.
- D4-A — CUSTOMER_OBLIGATION_SETTLEMENT: Accounting meaning: discount settles a pre-existing bonus liability owed to the customer. Future GL implication: posts against the bonus liability balance; requires liability/expense-side accounts and a journal bridge at a later phase. Required owner: financial owner (absent — see GAP). 0020 neutrality: 0020 can record amount/links/timestamps/actor/snapshot without posting GL interpretation.
- D4-B — REVENUE_REDUCTION: Accounting meaning: discount reduces recorded sales revenue on the order. Future GL implication: posts as sales-discount/revenue-reduction lines tied to order revenue; requires revenue-side mapping and a journal bridge at a later phase. Required owner: financial owner (absent — see GAP). 0020 neutrality: same as D4-A — record now, interpret later.
- FINANCIAL OWNERSHIP GAP: no accountant/finance role exists in the codebase (verified: sole enforced role is `company_director`). No role is created, assigned, or assumed here.

## 10. D5 — Maximum Discount
Question: does the system need a policy cap beyond order-total and available-bonus caps? Status: OWNER DECISION REQUIRED. Keys (contracted, nullable = absent): `discount.max_amount`, `discount.max_percent`. Only these shapes exist — nothing else is offered.
- D5-A — NO ADDITIONAL POLICY CAP: Calculation: `applied = min(requested, order_total, available_bonus)`. Order-total interaction: structural cap remains. Availability interaction: ledger cap remains. Zero-order interaction: governed solely by D1. Rule interaction: rule gate still narrows.
- D5-B — MAX_DISCOUNT_AMOUNT: Calculation: `applied = min(requested, order_total, available_bonus, max_amount)`. Other interactions as D5-A plus amount ceiling.
- D5-C — MAX_DISCOUNT_PERCENT: Calculation: ceiling = total × percent/100; `applied = min(requested, order_total, available_bonus, ceiling)`. Other interactions as D5-A plus percent ceiling.
- D5-D — BOTH AMOUNT AND PERCENT: Calculation: policy cap = min(amount cap, percent ceiling); then as D5-B/C. Owner must still supply both numbers (or this option cannot be implemented).

## 11. D6 — Minimum Discount
Terminology (contracted): minimum discount = floor on the applied discount amount; minimum order amount = floor on order value (NOT introduced); minimum remaining order amount = floor on post-discount remainder (NOT introduced — D1 covers the zero boundary). Status: OWNER DECISION REQUIRED. Key (contracted, nullable): `discount.min_amount`. Only these options exist.
- D6-A — NO MINIMUM DISCOUNT: any positive applied amount passes (subject to D1/D5/caps).
- D6-B — MINIMUM_DISCOUNT_AMOUNT: applied amounts below the floor are rejected (owner supplies the number).

## 12. D7 — Financial Owner
Question: who owns financial decisions (D4, accounting namespace, future GL)? Status: OWNER DECISION REQUIRED. No role is created and no permission changed here; the director is not assumed to be the financial owner.
- D7-A — Existing project role: UNAVAILABLE AS A FACT — verification shows the only enforced role is `company_director` (web gate + Flutter enum); no accountant/finance role exists in code to assign.
- D7-B — External/accounting ownership: ownership held outside the current role model (named individual/function designated by the owner at approval time).
- D7-C — UNDECIDED: ownership deferred; D4 value and any GL work stay blocked meanwhile.

## 13. D8 — Policy Snapshot
State: ALREADY CONTRACTED in PHASE 16.5 (§8) — not an owner question; recorded here, no checkbox for a new decision.
- CONTRACTED: POLICY SNAPSHOT AT DISCOUNT TIME (D8-A) governs. The funding scope, zero-order flag, cancellation mode, and max/min values captured with the discount transaction control that discount's later cancellation/reversal forever; the current global policy at cancellation time (D8-B) applies only to discounts created after the change. D8-B is therefore not offered.

## 14. Technical Invariants Already Locked
Discount-before-allocate ordering; standalone RPC (never inside `branch_allocate_order`); 0017/0018/0019 untouched; item prices immutable; Free-Y separation; ledger as truth; oldest-first allocation reuse; `DISCOUNT:{order_id}` idempotency; narrow-only override; snapshot-governs-cancellation; server-side recomputation; ownership checks; RLS/definer/search_path; POSTED immutability; allocation/reversal integrity; append-only audit; no direct client ledger writes. None require owner approval.

## 15. Decision Matrix
| ID | Decision | Options | Owner | Status | Technical Impact |
|---|---|---|---|---|---|
| D1 | Zero Order | D1-A ALLOW_ZERO / D1-B REQUIRE_POSITIVE | Business Owner | OWNER DECISION REQUIRED | Post-cap check inside future RPC; zero-total orders permitted or rejected |
| D2 | Funding Scope | D2-A ALL / D2-B MONETARY / D2-C recorded-not-implementable | Business Owner | OWNER DECISION REQUIRED | Lot filter during selection; monetary derivation via rule_type where chosen |
| D2-O | Override | narrow-only (Model C) | — | ALREADY CONTRACTED | Rule excludes only; invalid combos resolve to exclusion |
| D3 | Cancellation | D3-A AUTO_REVERSAL / D3-B MANUAL_REVIEW | Business Owner | OWNER DECISION REQUIRED | Compensating REVERSAL via reverses_id, or status guard + admin settlement |
| D4 | Accounting | D4-A LIABILITY / D4-B REVENUE_REDUCTION | Financial Owner | FINANCIAL OWNER REQUIRED | No GL in 0020; snapshot reserved; bridge blocked until decided |
| D5 | Maximum Discount | D5-A none / D5-B amount / D5-C percent / D5-D both | Business Owner | OWNER DECISION REQUIRED | Policy cap folded into min() before D1/min gates |
| D6 | Minimum Discount | D6-A none / D6-B floor amount | Business Owner | OWNER DECISION REQUIRED | Floor-check after caps |
| D7 | Financial Owner | D7-A unavailable / D7-B external / D7-C undecided | Owner | OWNER DECISION REQUIRED | Unblocks D4/GL only; changes nothing technically until a role exists |
| D8 | Policy Snapshot | D8-A snapshot governs | — | ALREADY CONTRACTED | Old discounts never reinterpreted under new policy |

## 16. Owner Approval Form
ORDER DISCOUNT OWNER APPROVAL (copy, fill, return):
- D1 Zero Order: [ ]
- D2 Funding Scope: [ ]
- D2 Override: LOCKED BY TECHNICAL CONTRACT (narrow-only; no selection)
- D3 Cancellation: [ ]
- D4 Accounting Treatment: [ ] (plus approver name/authority: [ ])
- D5 Maximum Discount: [ ] (shape + numbers, if any)
- D6 Minimum Discount: [ ] (shape + number, if any)
- D7 Financial Owner: [ ]
- D8 Policy Snapshot: LOCKED BY TECHNICAL CONTRACT (snapshot-at-discount governs; no selection)

## 17. Acceptance Rules
- An approval is executable only when: D1 filled; D2 filled (A or B — C is not selectable); D3 filled; D5 shape filled (A/B/C/D, numbers where the shape requires them); D6 filled (A/B, number where B); D7 filled (B with a named owner, or C explicitly deferring — D7-A cannot be selected as it does not exist).
- D4 may remain UNDECIDED only while Migration 0020 stays accounting-neutral (record-only, no GL posting); any GL bridge work additionally requires D4 filled by the financial owner named in D7.
- D5/D6 are mandatory questions (the owner must at least select "none") because the contract defines null as an explicit state the RPC must implement — silence is not implementable.
- Selections must be returned in this sheet's option IDs; free-text substitutes are not acceptable as approval.

## 18. Migration 0020 Start Gate
- BLOCKED UNTIL: D1 + D2 + D3 + D5 + D6 filled per §17; D7 filled (B or explicit C); if any GL posting is in scope, D4 filled by the D7-named financial owner.
- ALREADY LOCKED (no approval needed): §14 invariants + D2-override + D8-snapshot + storage choice (settings KV + rule flags) + precedence + compatibility rule.
- Partial start permitted: with D1+D2+D3+D5+D6+D7 resolved and D4 explicitly deferred, the discount-core RPC may proceed accounting-neutral; the GL bridge remains separately blocked.

## 19. Out of Scope
FOLLOW-UP AFTER 0020 (carried from 16.5, unchanged): `createInvoice` manual-amount remediation (gate order-linked invoices against final discounted totals or reconcile explicitly); finance-role introduction; GL accounts/bridge; staging-environment introduction. None block the discount-core decision gate.

## 20. Final Status
No business decision was taken inside OpenCode in this phase. All values above remain unfilled pending owner return of §16.

PHASE 16.6 STATUS:
BUSINESS DECISION SHEET COMPLETE — AWAITING OWNER APPROVAL
NO CODE — NO SQL — NO DATABASE CHANGES
