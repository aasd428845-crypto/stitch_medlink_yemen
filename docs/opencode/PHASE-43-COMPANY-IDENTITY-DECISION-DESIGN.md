# PHASE 43 — COMPANY IDENTITY DECISION DESIGN (read-only, no selection)

## A. Executive Summary
Operational company identity is NOT DERIVABLE; financial company identity EXISTS (single live company row) but participates in nothing operational. Six ownership options (A–F) are laid out with evidence-bound consequences and no ranking. Ten business decisions (BD-COMPANY-01–10) and five technical questions gate any bridge. The dependency order is fixed: company model → ownership → scope → invoice/payment scope → accounting policy → integration. Nothing is chosen, built, or applied.

## B. Confirmed Current Architecture
Operational graph (users/orders/branches/products/bonus, 0017–0022 + Flutter) is fully company-less (zero identifiers repo-wide and live). Financial module (27 tables, 4 RPCs, seeded CoA, exactly ONE `financial_companies` row) is company-scoped but bonus-blind and RPC-company-parameter-free. PWA financial UI/API contain zero bonus references and no company picker found. Posting is human-operated only. No link object exists between the graphs.

## C. Company Identity Problem
Financial posting requires company context; no operational event can supply one (no column, no derivation chain, no RPC parameter). The gap is structural, not a missing mapping — mapping presumes endpoints that do not exist on one side.

## D. Company Semantics
`financial_companies(id, name, legal_name, base_currency_code, is_active, created_at)`, 1 row live. `legal_name` + currency suggest Legal/Accounting Entity; single row suggests single-company operation in practice. Purpose unproven beyond columns (no charter/settings/report evidence gathered) → SEMANTICS UNKNOWN with a lean, explicitly marked as inference, not fact. Tenant/Business-Unit readings have zero supporting evidence.

## E. Company Ownership Options (neutral, evidence-bound)
OPTION A — ownership on Customer: forces one-company-per-customer (unproven need) or multi-account complexity; accumulated bonus would need company-splitting rules (none exist); old orders unattributable; incompatible with current global-customer schema without migration + backfill policy.
OPTION B — ownership on Order: earn could take company from order (needs the column first); order-less events (withdrawal, expiration, reversal, opening, adjustment, legacy) still need independent attribution — the option is incomplete on its face for 6 of 10 event types.
OPTION C — ownership on Bonus Account: account already 1:1 with customer (PK); scoping it by company forks wallets per company (earn-routing, withdrawal-routing, discount-routing all need rules); cross-company balances become a first-class problem.
OPTION D — ownership per ledger event: finest granularity, heaviest write path (every RPC gains company resolution); handles order-less events uniformly; heaviest audit surface.
OPTION E — through Branch: branches are locations (geo/address, no company link); a future Branch→Company relation is structurally possible but entirely absent — recorded as future-only, never assumed.
OPTION F — explicit accounting context: no such concept exists anywhere (NOT EXISTING); would be new architecture, not reuse.

## F. Bonus Ownership Matrix
| Decision | A Customer | B Order | C Account | D Event | Current Evidence | Business Decision |
|---|---|---|---|---|---|---|
| Account ownership | 1 co. per customer | n/a | scoped wallets | n/a | PK=user_id, global | required |
| Ledger ownership | via customer | via order (gaps) | via account | per-row company | company-less | required |
| Earn | customer co. | order co. | account co. | event co. | none coded | required |
| Redemption | same open set | order-less gap | account co. | event co. | none coded | required |
| Withdrawal | same open set | NO order link | account co. | event co. | none coded | required |
| Discount | customer/order | order co. | account co. | event co. | none coded | required |
| Reversal | follows original | follows original | follows original | needs original link | reverses_id exists | required |
| Expiration | customer co. | NO order link | account co. | event co. | none coded | required |

## G. Company Propagation Matrix
| Layer | Company Identity | Explicit | Derived | Missing | Policy |
|---|---|---|---|---|---|
| Customer/Order/Branch | none | — | — | all | ownership model |
| Bonus Account/Ledger/Event | none | — | — | all | scope model |
| Accounting Event | company_id | column exists | — | emission rules | accounting policy |
| Journal Entry/Lines | company_id | column exists | via entry | posting rules | accounting policy |

## H. Bonus Events Without Order
Types in CHECK: EARN, REDEEM_PRODUCT, ORDER_DISCOUNT, CASH_WITHDRAWAL, REFUND, REVERSAL, ADJUSTMENT, EXPIRATION, OPENING_BALANCE, LEGACY_MIGRATION. Order-less or order-optional: OPENING_BALANCE, ADJUSTMENT, EXPIRATION, REVERSAL (inherits), CASH_WITHDRAWAL, REFUND, LEGACY_MIGRATION — for each, company is COMPANY IDENTITY REQUIRED (no order to inherit from; no alternative source exists). Order-bearing (EARN/discount/redeem) still lack company for lack of order→company. Stated, not solved.

## I. Cross-Company Risk
Global-bonus × multi-company-GL hazards (earn-A/redeem-B liability ownership, wallet scope, migration of old balances, shared products/branches across companies, per-company liability/expense split): each recorded as a POLICY question, none answered. The risk is currently LATENT (single company row live) but STRUCTURAL (nothing would prevent it).

## J. Invoice / Payment Dependency
Invoice needs order→company→invoice→revenue/receivable chain (order and company links both missing). Payment needs payment→company→cash/bank (payment stub has neither). Withdrawal needs bonus→company→payment→cash/bank (all three links missing). No models created; dependencies recorded.

## K. Historical Data Impact
Any future company attribution faces: old orders/ledger/accounts/withdrawals/redemptions/discounts/invoices with no company data → BACKFILL REQUIRED (rules per object) or POLICY REQUIRED (default-company assignment — note: single live company row makes a default trivially available, but choosing it is policy, not fact). No backfill designed or executed.

## L. Financial Company vs Business Company
Readings with evidence grades: Legal Company (weak support: `legal_name`); Tenant (no support); Business Unit (no support); Accounting Entity (moderate: currency + CoA + journals all company-keyed). Verdict: SEMANTICS UNKNOWN — columns suggest accounting-legal entity, nothing proves it. Acting on any reading without owner confirmation would be assumption, not analysis.

## M. Architecture Decision Matrix
| Option | Company Owner | Bonus Scope | Order Scope | Multi-Company Support | Historical Impact | GL Compatibility | Technical Complexity | Business Decisions Required |
|---|---|---|---|---|---|---|---|---|
| A Customer | customer row | per-customer split | inherits | forced single/org-matrix | backfill all history | direct | migration+backfill+routing | single-vs-multi customer, balance split |
| B Order | order row | per-order attribution | extended | partial (6/10 events orphan) | backfill orders | partial | medium, incomplete | order-less event handling |
| C Account | account row | forked wallets | inherits | full via routing rules | backfill accounts | direct with rules | routing complexity | wallet scope, cross-use |
| D Event | ledger row | finest | inherits | full | backfill ledger | direct | heaviest write path | resolution rules per RPC |
| E Branch-link | future relation | inherits | inherits | indirect only | backfill branches | indirect | new relation + backfill | branch semantics |
| F Context | new concept | n/a | n/a | full | greenfield | direct | new architecture | entire model |
No scores, no ranking, no winner — columns are facts and open questions only.

## N. Hard Blockers
1. No operational company identity — TECHNICAL (nothing to map from). 2. No bonus company ownership — TECHNICAL+BUSINESS (option + values). 3. GL requires company context — TECHNICAL (posting RPCs/journal shape). 4. No Bonus→GL bridge — TECHNICAL (nothing built). 5. Invoice order/company linkage — BOTH (schema + H2 ruling). 6. Payment architecture — BOTH (model + policy).

## O. Decision Dependencies
Company Model → Ownership Model → Bonus Scope → Invoice Scope → Payment Scope → Accounting Policy → Bonus→GL Integration → Implementation. Order follows evidence necessity (each layer's inputs come from the previous); no phase executed.

## P. Business Decisions Required
BD-COMPANY-01 single vs multi company operation? (affects all; blocks bridge). BD-COMPANY-02 customer↔company cardinality? (blocks A/C). BD-COMPANY-03 wallet scope global vs company? (blocks C/D + cross-use). BD-COMPANY-04 old-balance attribution on change? (blocks backfill). BD-COMPANY-05 order↔company cardinality? (blocks B). BD-COMPANY-06 product sharing across companies? (blocks catalog scope). BD-COMPANY-07 branch↔company cardinality? (blocks E). BD-COMPANY-08 financial-account company discipline? (blocks CoA mapping). BD-COMPANY-09 per-company liability/expense split? (blocks accounting policy). BD-COMPANY-10 order-less event attribution rule? (blocks D + withdrawal/expiry posting). Each lists affected systems above; all block Bonus→GL, none block current operations.

## Q. Technical Decisions Required
TD-1 where company identity is stored (depends: BD-COMPANY-01/02). TD-2 how it propagates per event type (depends: ownership option). TD-3 resolution rule at each RPC (depends: TD-2). TD-4 cross-company prevention mechanism (depends: BD-COMPANY-03). TD-5 GL linkage shape (depends: accounting policy). Unanswered by design in this phase.

## R. Recommended Decision Sequence — DO NOT CHOOSE OPTIONS
BD-COMPANY-01 → BD-COMPANY-02/05/07 (cardinalities) → ownership option family → BD-COMPANY-03/04 (scope + history) → TD-1/TD-2 (storage + propagation) → invoice/payment scope → BD-COMPANY-08/09/10 (accounting-side) → accounting policy → TD-5 → bridge design. Sequence only; every option stays open.

## S. Final Status
Operation log: read-only SELECTs + repo greps; no timeouts, no auth failures, no hidden errors this phase. No discrepancies vs cited sources.

PHASE 43 COMPLETE — COMPANY IDENTITY DECISION DESIGN
READ-ONLY DESIGN
NO FILES MODIFIED EXCEPT REPORT
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
