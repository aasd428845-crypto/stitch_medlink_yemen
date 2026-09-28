# PHASE 44 — COMPANY IDENTITY DECISION QUESTIONNAIRE (read-only preparation)

## A. Executive Summary
Eleven owner questions (BD-COMPANY-01–10 + changes rule) cover model, ownership, scope, cross-use, and history. Standing facts: operational graph company-less; finance company-scoped with ONE live company and ZERO source-linked journals; users carry branch assignment (staff), inventory is per-branch, products are global-catalog; no tenant identifiers anywhere. Numbering note: THIS phase's BD-COMPANY-XX definitions supersede Phase 43's same-numbered items for questionnaire purposes (mapping in §P evidence; no content contradicted, only renumbered scope).

## B. Current Company Identity State
EXISTS: `financial_companies` (1 row), company_id columns (13 tables), manual journal posting, branch assignment on users, per-branch inventory. NOT DERIVABLE: any operational→company path (customer/order/branch/product/bonus). UNKNOWN: company semantics beyond columns (legal-name lean, unproven). All journals source-less (`source_document_id` all NULL live — queried).

## C. Company Decision Questionnaire
### BD-COMPANY-01 — Company model
Question: single company, multi company, multi-with-shared-ops, or multi-with-isolated-finance? Options differ in: meaning (one books set vs N), changes (none today — single row operates), tables affected later (company-keyed objects only under multi), bonus (global wallet valid ONLY under single), GL (today's shape already multi-capable), invoice/payment (need company5600 attribution under multi). OWNER DECISION REQUIRED.
### BD-COMPANY-02 — Financial ownership anchor
Options: Customer / Order / Bonus Account / Ledger Event / Branch-link / Explicit Context. Per option: source (row vs derivation vs new concept), derivability (all NOT DERIVABLE today except event-inherent data), dependence on absent data (options A–C need new columns; D needs per-RPC resolution; branch-link needs a relation that does not exist; context needs new architecture), history impact (backfill-or-policy in all cases), bonus/GL impact (defines the bridge endpoint). OWNER DECISION REQUIRED.
### BD-COMPANY-03 — One company per order?
Option A exactly-one (enforced at creation/attribution); Option B multi-company lines (needs line-level company + split logic — nothing supports this today); Option C derived context (same gap as BD-02). Current system: structurally single (one client_id + one branch_id per order) but company-meaningless. OWNER DECISION REQUIRED.
### BD-COMPANY-04 — Customer anchoring
Single-company customer / multi-company customer / company-less customer / context-derived per transaction. Effects traced per surface (orders, account, earn, redemption, discount, withdrawal, invoice, payment, GL): under single-company-customer the account graph stays intact; under multi, wallets/forks need rules; under company-less (today) nothing changes until bridge time. OWNER DECISION REQUIRED.

### BD-COMPANY-05 — Wallet scope
CURRENT STATE (verified): global single wallet per customer (`bonus_accounts` PK=user_id, no company anywhere). Options: Global / Company-scoped / Customer+Company / Order-derived / Context-derived. Downstream: scoped wallets fork earn/spend/discount/withdrawal routing; global keeps current code untouched. OWNER DECISION REQUIRED.
### BD-COMPANY-06 — Cross-company use
Earn-A → spend-B? Option A allowed (needs single liability pool + no company checks); B forbidden (needs scope enforcement at every spend RPC); C transfer/settlement-mediated (needs transfer postings — heaviest). Liability/expense/revenue/GL/invoice/traceability/settlement spelled per option in analysis. OWNER DECISION REQUIRED.
### BD-COMPANY-07 — Product ownership
Verified: global catalog products; stock per (branch, product); manufacturer free text; suppliers financial-only, product-unlinked. Questions: catalog global vs company-owned vs branch-owned vs shared; who owns inventory (branch, per unique constraint), COGS, revenue, redemption stock. OWNER DECISION REQUIRED.
### BD-COMPANY-08 — Branch anchoring
Verified: branches are geo locations; staff carry branch_id; branch managers operate own-branch scope (RLS + RPC gates); orders/inventory already branch-keyed. Questions: one-company branch vs pure location vs multi-company service. What exists vs what is policy is separated per bullet. OWNER DECISION REQUIRED.
### BD-COMPANY-09 — Financial account scope
Verified: accounts carry company_id; CoA seeded with Arabic names; no bonus-purpose mapping exists. Questions: all-accounts-company-bound vs global accounts allowed; bonus-liability company-specificity; shared vs per-company chart. Undecidable from code (no mapping table, no policy text) → NOT DERIVABLE beyond column presence. OWNER DECISION REQUIRED.
### BD-COMPANY-10 — Non-order events
Matrix (event | order? | company source today | derivable? | decision): OPENING_BALANCE no | none | NO | required; ADJUSTMENT no | none | NO | required; EXPIRATION no | none | NO | required; REVERSAL inherits-via-link | original event | PARTIAL (follows original once original is attributed) | required; REFUND case-dependent | none | NO | required; CASH_WITHDRAWAL no | none | NO | required; LEGACY_MIGRATION no | none | NO | required. OWNER DECISION REQUIRED.
### BD-COMPANY-11 (changes rule) — Relationship changes with history
Preserve-history vs future-only vs full-reassign vs explicit-transfer-event for customer/branch/product/account changes. History rows are append-only; nothing rewrites. OWNER DECISION REQUIRED.

## D. Ownership Decision Matrix
(Anchor × Customer/Order/Account/Event/Branch-payload/system readiness — all cells BUSINESS POLICY REQUIRED except the EXISTING structural facts cited above; no cell pre-filled.)

## E. Bonus Scope Decisions
Wallet/account/event scope options per §C BD-05/06/10 with current-state anchors (global wallet EXISTS; scoped variants MISSING). No selection.

## F. Order / Customer / Product / Branch Scope
Single-vs-multi questions per §§C BD-03/04/07/08 with verified current shapes (single client/branch per order row; global customers; location branches; global catalog). No selection.

## G. Non-Order Bonus Events
Table in §C BD-10; rule: no event may post to GL without an attribution rule, and no rule exists today. No selection.

## H. Cross-Company Decisions
BD-06 options with liability/expense/revenue/GL/invoice/traceability/settlement dimensions; latent risk only (single company live). No selection.

## I. Historical Data Decisions
Backfill vs no-backfill vs default-company policy vs unknown-until-model — per object class (orders/ledger/accounts/withdrawals/redemptions/discounts/invoices). Default-company assignment is available as data (one live row) but choosing it is policy. No selection.

## J. Invoice / Payment Dependencies
Invoice chain needs order+company links (both missing); payment needs model first (stub only). Neither blocks questionnaire completion; both block implementation after it.

## K. Business vs Technical Decisions
BUSINESS (owner): BD-01..11 model/ownership/scope/cross-use/history/taxonomy-adjacent/wallet/product/branch/company-changes. TECHNICAL (design-after-decision): column placement, propagation paths, RPC context plumbing, journal linkage shape, invoice/payment references, event identity preservation. No technical item implemented; none substitutes for its business parent.

## L. Decision Dependency Graph
Company Model → Company Ownership → Customer/Order/Branch/Bonus Scope → Invoice Scope → Payment Scope → Accounting Policy → Bonus→GL Architecture → Implementation. Later stages MUST NOT execute before earlier answers (each consumes the previous as input).

## M. Hard Blockers
| Blocker | Evidence | Why It Blocks | Decision Needed |
|---|---|---|---|
| No operational company identity | zero identifiers repo+live | nothing to map from | BD-01/02 |
| No bonus ownership rule | no columns/rules | every event unattributable | BD-05/06/10 |
| GL needs company context | journal shape + manual posting | bridge has no input side | BD-01 + accounting |
| No Bonus→GL bridge | zero links all layers | nothing posts | all above |
| Invoice order/company linkage | no columns | revenue/receivable unattributable | H2 + BD scope |
| Payment architecture | stub table only | settlement unmodelled | payment model |
| No status-history source | schema-verified absence | timeline/audit depth capped | backend design |

## N. Decision Readiness Matrix
| Area | Ready for Decision | Missing Information | Blocked By |
|---|---|---|---|
| Company Model | YES (options complete) | owner preference | BD-01 |
| Ownership | YES | owner preference | BD-02 |
| Bonus Scope | YES | owner preference | BD-05/06 |
| Order/Customer/Product/Branch Scope | YES | owner preference | BD-03/04/07/08 |
| Invoice/Payment Scope | PARTIAL (model gaps) | linkage + model shape | H2 + payment track |
| Accounting Scope | PARTIAL (D4 open) | treatment policy | D4 + BD-09/10 |
| Bonus→GL | NO | all of the above | full chain |

## O. Final Owner Questionnaire
BD-COMPANY-01 Model: Option A single / B multi / C multi-shared-ops / D multi-isolated-finance. Decision: "________________".
BD-COMPANY-02 Anchor: Option A customer / B order / C account / D event / E branch-link / F context. Decision: "________________".
BD-COMPANY-03 Order cardinality: Option A one-company / B multi-company lines / C derived. Decision: "________________".
BD-COMPANY-04 Customer anchoring: Option A single / B multi / C company-less / D per-transaction. Decision: "________________".
BD-COMPANY-05 Wallet: Option A global / B company-scoped / C customer+company / D order-derived / E context-derived. Decision: "________________".
BD-COMPANY-06 Cross-use: Option A allowed / B forbidden / C transfer-mediated. Decision: "________________".
BD-COMPANY-07 Products: Option A global catalog / B company-owned / C branch-owned / D shared. Decision: "________________".
BD-COMPANY-08 Branches: Option A one-company / B pure location / C multi-company service. Decision: "________________".
BD-COMPANY-09 Accounts: Option A all company-bound / B global allowed / C bonus-specific mapping. Decision: "________________".
BD-COMPANY-10 Non-order events: per-event rule (Option A attribute-to-anchor / B suspense-until-resolved — shape only, values open). Decision: "________________".
BD-COMPANY-11 Changes: Option A preserve-history / B future-only / C full-reassign / D transfer-event. Decision: "________________".

## P. Evidence Index
Migrations 0001 (branches/users/roles), 0002 (orders/inventory/products/manufacturer), 0018 (ledger CHECK, no company), 0020-22 (no company params); live: 13 company_id tables, 1 company row, 0 source-linked journals, 0 company cols on ops tables; app: role enum, branch assignment, per-branch inventory, global catalog; PWA: financial UI without company picker or bonus refs; reports 40-43.

## Q. Final Gate
PARTIALLY READY: questionnaire complete and answerable (all options + evidence present), but implementation readiness is NOT READY by rule — every build path is gated on owner answers above. No technical choice substitutes.

PHASE 44 COMPLETE — COMPANY IDENTITY DECISION QUESTIONNAIRE
READ-ONLY DECISION PREPARATION
NO APPLICATION FILES MODIFIED
NO DATABASE CHANGES
NO SQL WRITE
NO MIGRATION CREATED
NO COMPANY MODEL IMPLEMENTED
NO BONUS → GL IMPLEMENTATION
NO COMMIT
NO PUSH
ACCOUNTING POLICY NOT DECIDED
BD-2 NOT DECIDED
COMPANY OWNERSHIP POLICY NOT DECIDED
