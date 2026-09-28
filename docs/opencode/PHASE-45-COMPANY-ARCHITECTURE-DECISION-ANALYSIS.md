# PHASE 45 — COMPANY ARCHITECTURE DECISION ANALYSIS (read-only, no selection)

## A. Executive Summary
Six models (A single-company, B branch-link, C order-link, D customer-link, E explicit context, F hybrid) analyzed against verified evidence with trade-offs, dependencies, and gaps — no ranking, no choice. Cross-cutting results: no model is implementable without prior business decisions; order-less bonus events defeat all inheritance models (B/C/D); only A and E/F cover the full event set; history backfill is unprovable for every model; the single live company row constrains nothing architecturally. Gate verdict: NOT READY (decisions, not evidence, are missing).

## B. Current Architecture
User (role + optional branch assignment) → Branch (geo location) → Order (client + branch + items + server total) → Bonus (account per customer → ledger events with optional order links; earn evaluator order-bound; discount/reversal order-linked; redemption/withdrawal/expiry/opening mostly order-less). Financial: one `financial_companies` row; company-keyed accounts/journals/budgets/suppliers; manual posting RPCs without company params; zero bonus references; all journal source fields NULL live. PWA financial UI has no company picker and no bonus surfaces.

## C. Current Operational → Financial Gap
Company identity EXISTS at: journal entries/lines (via entry), accounts, budgets, suppliers, fiscal years. MISSING at: users, branches, products, inventory, orders, items, all 8 bonus tables, invoices, payments. DERIVABLE: nowhere (every candidate chain breaks at a missing link). Data present: single company row + seeded CoA. Theory-only: everything downstream of attribution (no emission, no mapping, no UI).

## D. Architecture Models A–F (no ranking; TRADE-OFF / DEPENDENCY / TECHNICAL GAP / BUSINESS POLICY REQUIRED only)
MODEL A — Single Company: everything posts to the one live company. Data needed: none new (company row exists). Unchanged: all ops code, all bonus mechanics, all RLS. Bonus/invoice/payment/GL impact: attribution soluble by constant; journals keep working manually. Risks: silently wrong the day a second company appears (no guardrails exist to detect it); cross-company questions become unanswerable retroactively. History: no backfill (nothing to attribute). Depends on: BUSINESS POLICY REQUIRED (single-company declaration).
MODEL B — Branch → Company: derivation status NOT DERIVABLE (branches carry no company link; users carry branch, not company). Needs: new branch↔company relation + backfill-by-policy + propagation rules. Order-less events still orphaned (branch irrelevant to expiry/adjustment). Risks: branches-as-locations vs branches-as-entities confusion baked into schema. Depends on: relation + BD-08 + per-event fallback.
MODEL C — Order → Company: derivation status NOT DERIVABLE (orders carry no company). Needs: order company column/FK + earn/discount/invoice/payment reads. Fails 6–7 of 10 event types (withdrawal/expiry/opening/adjustment/legacy/reversal-inherited-only). Historical orders unattributable without policy default. Depends on: BD-03 + order-less event rule.
MODEL D — Customer → Company: derivation status NOT DERIVABLE (users carry no company). Multi-company customers fork wallets/accounts (PK=user_id today — schema collision). Old bonus unattributable without split rules. Depends on: BD-04 + wallet-scope + balance-split policy.
MODEL E — Explicit Accounting Context: status NOT EXISTING anywhere. Covers all events uniformly (context supplied at posting). Needs: new concept + RPC params + UI surfaces + audit. Heaviest build, cleanest semantics. Depends on: full context-model decision set.
MODEL F — Hybrid (branch context → order → account → GL context): analyzed because evidence supports its pieces (branch assignment exists, order links exist, journal manual context exists) — but the JOINS between pieces do not exist. Same gaps as B+C+D combined, plus composition complexity. No basis to prefer it; recorded for completeness.

## E. Ownership Propagation Matrix
| Entity | Current Company Identity | Possible Source | Derivable? | Required Decision | Downstream |
|---|---|---|---|---|---|
| User | none | company row (future FK) | NO | BD-04 | all customer flows |
| Customer (=user) | none | same as User | NO | BD-04 | wallet scope |
| Branch | none | company row (future FK) | NO | BD-08 | order/inventory attribution |
| Product | none (manufacturer text) | company row (future) | NO | BD-07 | catalog/COGS scope |
| Inventory | branch-keyed only | via branch (needs BD-08) | NO | BD-08 | stock ownership |
| Order | none | company row / branch / customer | NO | BD-03 | earn/discount/invoice |
| Bonus Account | none (PK=user) | customer/company | NO | BD-05 | wallet scope |
| Bonus Ledger | none | per-event rule | NO | BD-10 | posting input |
| Redemption | none | account/order | PARTIAL (order only when linked) | BD-10 | stock/revenue |
| Withdrawal | none | account + payout target | NO | BD-10 + payment | cash/bank |
| Invoice | none | order/company | NO | H2 + BD scope | revenue/receivable |
| Payment | stub, none | invoice/company | NO | payment model | settlement |
| Journal Entry | company_id EXISTS | — (present) | YES | posting rules | GL books |


## F. Bonus Architecture (per-flow: source, evidence, missing, dependency)
Earn (order→evaluator→ledger): source would be order; MISSING order→company; depends BD-03 + order-less fallback. Redemption (lots→reservation→fulfillment): source would be account/order; PARTIAL order linkage only; inventory/COGS/revenue unmapped; depends BD-10 + stock policy. Discount (order→debit→invoice-math): source would be order; MISSING company; invoice/receivable unmapped; depends BD-03 + H2. Withdrawal (lots→request→payout status): NO order, NO payout target, NO money movement in code; depends BD-10 + payment model. Reversal (link to original): inherits IF original attributed, else orphaned too; depends on original's rule. Expiration (lots→expiry rows): NO order, NO target; depends BD-10.

## G. Cross-Company Matrix (all cells POLICY REQUIRED where undecided)
| Scenario | Company A | Company B | Allowed? | Accounting Problem | Required Policy |
|---|---|---|---|---|---|
| Earn A → Redeem A | same | same | POLICY REQUIRED | none if scoped | scope model |
| Earn A → Redeem B | earner | spender | POLICY REQUIRED | liability owner? | BD-06 |
| Earn A → Discount B | earner | order co. | POLICY REQUIRED | revenue/receivable owner? | BD-06 + H2 |
| Earn A → Withdrawal B | earner | payout co. | POLICY REQUIRED | cash/bank owner? | BD-06 + payment |
| Order A → Invoice B | order co. | billing co. | POLICY REQUIRED | revenue owner? | H2 + BD scope |
| Branch A → Order B | branch co. | order co. | POLICY REQUIRED | attribution conflict | BD-08 |
No cell answered; same-company row is trivially consistent but undeclared as policy.

## H. Invoice Architecture
Verified: no order link, no company link, no discount fields, no items table, manual standalone creation, branch-scoped RLS. Dependency chain Company→Order→Invoice→Payment→GL: broken at every arrow today. Gap owner: H2 (linkage ruling) + BD scope (company) + payment model. No fix in this phase.

## I. Payment Architecture
Present: stub table (invoice/client/amount, no status/method/order/withdrawal links). Absent: engine, settlement, money movement, company ownership, provider. Status-only flows (withdrawal COMPLETED) prove workflow, never finance. Company Architecture cannot complete payment attribution until a payment model exists — recorded dependency, not a new design.

## J. Historical Data
Present data: orders/branches/users/inventory/bonus-ledger+accounts/financial rows (counts unmeasured — out of scope for the decision). Per model: A needs nothing (constant); B needs branch attribution (UNPROVABLE from geo fields — backfill impossible without policy default); C needs order attribution (same); D needs customer/account splits (same); E needs per-event context (only forward-fillable); F inherits all. Backfill-possible claims require a proven source per object — none exists; every model therefore needs POLICY REQUIRED (default or rule) before any backfill statement.

## K. Single Company Current-State Analysis
LIVE DATA CURRENTLY SHOWS ONE FINANCIAL COMPANY — and that constrains nothing: one row is a datum, not a declaration. Knowable: current postings (all manual) belong to it trivially. NOT knowable: whether operations are single-company by policy, whether a second company may appear, whether bonus economics assume singularity. BUSINESS MODEL REMAINS UNDECIDED — stated exactly as mandated.

## L. Multi-Company Requirements (minimum, unbuilt)
Company identity source; ownership anchors per domain; propagation rules per event; historical ownership policy; cross-company allow/forbid matrix; financial-account scope; journal scope; invoice scope; payment scope; bonus scope (wallet fork vs global). Listed, not designed.

## M. Architecture Decision Matrix
| Model | Company Source | Bonus Compatibility | Invoice Compatibility | Payment Compatibility | GL Compatibility | Historical Impact | Missing Decision |
|---|---|---|---|---|---|---|---|
| A Single | constant (1 row) | full (no routing) | full (as today) | full (as today) | direct | none | single-company declaration |
| B Branch | future relation | partial (order-less orphan) | via order | via branch | indirect | unprovable backfill | relation + BD-08 + fallback |
| C Order | future column | partial (6/10 orphan) | direct | via order | direct-ish | unprovable backfill | column + BD-03 + fallback |
| D Customer | future column | fork complexity | via order | via customer | direct with rules | split policy needed | cardinality + BD-04/05 |
| E Context | new concept | full | full | full | direct | forward-only | entire model |
| F Hybrid | combined futures | combined gaps | combined | combined | indirect | combined | all of the above |
No scores, no ranking, no winner.

## N. Technical Blockers (proven only)
| Blocker | Evidence | Affects | Can Proceed Without Decision? |
|---|---|---|---|
| No operational company identity | zero identifiers repo+live | every attribution | NO (mapping needs endpoint) |
| No bonus ownership rule | no columns/rules | all 10 event types | NO |
| GL needs company context | journal shape + manual RPCs | bridge input | NO |
| No Bonus→GL bridge | zero links all layers | posting | NO |
| Invoice linkage gap | no order/company cols | revenue/receivable | NO for linked billing; standalone unaffected |
| Payment model gap | stub table only | settlement | NO for payout flows |
Gaps that are NOT blockers (analysis can and did proceed): CoA purpose mapping, UI picker absence, journal source emptiness.

## O. Decision Dependencies
Company Model → Ownership Model → Bonus Scope → Order Scope → Invoice Scope → Payment Scope → Accounting Policy → Bonus→GL → Implementation. Each arrow consumes the previous layer's answers (e.g., scope needs an anchor; policy needs scope; bridge needs policy). No stage executes in this phase.

## P. Architecture Readiness
| Area | Current State | Decision Needed | Evidence | Ready |
|---|---|---|---|---|
| Company Model | 1 live row, no declaration | BD-01 | live count + no policy text | NO |
| Company Ownership | no anchors | BD-02 family | zero-column proofs | NO |
| Order Ownership | single-row structure, no company | BD-03 | schema reads | NO |
| Customer Ownership | global users | BD-04 | role/branch fields only | NO |
| Branch Ownership | locations | BD-08 | geo DDL | NO |
| Bonus Scope | global wallet | BD-05/06/10 | PK + no company | NO |
| Invoice Scope | unlinked rows | H2 + BD | column proofs | NO |
| Payment Scope | stub | model + BD | stub columns | NO |
| GL Scope | company-keyed manual books | posting + D4 | RPC + CoA | PARTIAL (books exist) |
Readiness vocabulary only; no ranking implied.

## Q. Owner Decision Set (BD-01..BD-11, Decision left blank)
BD-01 Company Model — Question: single vs multi (shared-ops vs isolated-finance)? Options: §M row A (+multi variants). Evidence: 1 live row; no policy. Consequences: gates everything (§O). Dependencies: none (first). Decision: ______.
BD-02 Company Ownership — anchor Customer/Order/Account/Event/Branch/Context? Evidence: all anchors missing. Consequences: defines every propagation path. Dependencies: BD-01. Decision: ______.
BD-03 Order Company — one-company vs multi-line vs derived. Evidence: single client/branch columns, no company. Consequences: earn/discount/invoice attribution. Dependencies: BD-01/02. Decision: ______.
BD-04 Customer Company — single vs multi vs company-less vs per-transaction. Evidence: global users. Consequences: wallet scope, all customer flows. Dependencies: BD-01/02. Decision: ______.
BD-05 Bonus Wallet Scope — global vs scoped variants. Evidence: PK=user_id global wallet. Consequences: earn/spend/discount/withdrawal routing. Dependencies: BD-02/04. Decision: ______.
BD-06 Cross-Company Bonus — allowed/forbidden/transfer-mediated. Evidence: latent risk only. Consequences: liability/expense/revenue ownership. Dependencies: BD-05. Decision: ______.
BD-07 Product Ownership — global vs company vs branch vs shared. Evidence: global catalog, branch stock, text manufacturer. Consequences: catalog/COGS/redemption stock. Dependencies: BD-01. Decision: ______.
BD-08 Branch Ownership — one-company vs location vs multi-service. Evidence: geo DDL. Consequences: order/inventory attribution. Dependencies: BD-01. Decision: ______.
BD-09 Financial Account Scope — all-bound vs global-allowed vs bonus mapping. Evidence: company-keyed CoA, no bonus mapping. Consequences: books structure. Dependencies: BD-01 + D4. Decision: ______.
BD-10 Historical Ownership — backfill rules vs default vs forward-only. Evidence: unattributable history. Consequences: migration scope. Dependencies: all above. Decision: ______.
BD-11 Non-Order Bonus Context — attribution rule per order-less event. Evidence: 7 affected types. Consequences: posting completeness. Dependencies: BD-02 + ownership. Decision: ______.

## R. Evidence Index
Migrations 0001 (branches/users/roles), 0002 (orders/inventory/products/manufacturer), 0018 (ledger CHECK, allocation, reversal guards), 0019 (order-bound earn), 0020-22 (no company params); live: 13 company_id tables, 1 company row, 0 source-linked journals, 0 company cols on ops tables (all queried); app: role enum, branch assignment, per-branch inventory; PWA: financial pages without picker or bonus refs; reports 40-44.

## S. Final Gate
NOT READY — and precisely why: evidence is complete (no UNKNOWN blocks analysis), but every implementation path is gated on undecided business policy (BD-01..11, D4, H2). No model selected; no further analysis can substitute for owner answers.

PHASE 45 COMPLETE — COMPANY ARCHITECTURE DECISION ANALYSIS
READ-ONLY ARCHITECTURE ANALYSIS
NO APPLICATION FILES MODIFIED
NO DATABASE CHANGES
NO SQL WRITE
NO MIGRATION CREATED
NO COMPANY MODEL IMPLEMENTED
NO BONUS → GL IMPLEMENTATION
NO COMMIT
NO PUSH
ACCOUNTING POLICY NOT DECIDED
COMPANY OWNERSHIP POLICY NOT DECIDED
