# PHASE 42 — COMPANY IDENTITY & FINANCIAL OWNERSHIP AUDIT (read-only)

## A. Executive Summary
No company-ownership path exists from Customer/Order/Bonus to any company row. The operational side (users/orders/branches/products/bonus) carries ZERO company identifiers — it is single-company by absence. The financial module is multi-company by structure (13 tables with `company_id`, `financial_companies` exists) but accepts no company at posting RPC time and references bonus nowhere. Critical answer (§19): NOT DERIVABLE. No implementation proposed.

## B. Company Architecture Inventory
| Object | Type | Repository | Live | PK | company_id | FK to Company | Status |
|---|---|---|---|---|---|---|---|
| financial_companies | TABLE | MISSING (zero migration matches) | EXISTS | UNKNOWN (not inventoried) | N/A (is the target) | — | LIVE ONLY |
| branches | TABLE | EXISTS (0001:3-11: location fields only) | EXISTS | uuid | none | none | EXISTS (company-less) |
| users | TABLE | EXISTS (0001:13+: role-based, no company) | EXISTS | uuid | none | none | EXISTS (company-less) |
| tenants/organizations | — | MISSING | MISSING | — | — | — | MISSING |
| Flutter/Web company models | — | MISSING (zero matches) | N/A | — | — | — | MISSING |

## C. Financial Company Identity
`company_id` present live on: accounts, bank/cash accounts, branch_profitability, budgets, cost_centers, documents, fiscal_years, general_ledger, journal_entries, suppliers, trial_balance (+ payout_documents outside finance). Absent from: journal_lines (lines inherit via entry), periods, exchange_rates, currencies, payments, invoices, receipts/expenses/bills. FK detail not inventoried per column (out of scope for the bridge question); `company_id` presence alone does NOT equal tenancy (no tenant RLS/RPC evidence gathered — recorded as UNKNOWN, not claimed).

## D. Customer Company Identity
| Entity | company_id? | FK? | Derived Through | Live Evidence | Status |
|---|---|---|---|---|---|
| users/client | none | none | nothing | zero-column match | MISSING |
Multi-company possibility: schema neither forbids nor represents it — a client row is global by absence. No code path assigns customers to companies (zero matches).

## E. Order Company Identity
orders → client_id (users), branch_id (branches), no company columns (verified live zero-match). Path ORDER→COMPANY: MISSING (both hops company-less). No RPC derives company from orders (journal create takes date/description/lines only — verified signature).

## F. Branch Company Identity
Branches are locations (name/governorate/address/geo, 0001:3-11), not companies: no company link, no org parent. Verdict on the three readings: Company Location (supported: geo + address fields); Company or Independent Entity (unsupported — no evidence either way; recorded UNKNOWN, not selected).

## G. Product Company Identity
`manufacturer` is free TEXT (0002:16), not a company FK. Kept distinct as mandated: Manufacturer (text label) vs Financial Company (company row) vs Supplier (financial_suppliers table, no product FK found) vs Tenant (nonexistent). No product→company path exists.

## H. Bonus Account Ownership
`bonus_accounts` keyed by user: EXPLICIT RELATION account→customer only. One-account-per-customer enforced by PK (user_id). No company column, no implicit ownership (nothing in code consults company for bonus). Deriving company from "previous orders" is DERIVABLE BUT NOT IMPLEMENTED (orders→branch exists, branch→company does not — chain breaks one hop short). No such derivation exists in any RPC.

## I. Bonus Ledger Ownership
Graph 1 (ledger→account→customer): COMPLETE via account_id FK. Graph 2 (ledger→order→branch/company): BROKEN at branch→company (no link). Attribution columns (rule/redemption/withdrawal/reverses/order ids) all resolve within the company-less operational graph. No source field points outside it.

## J. Bonus Event Ownership
Earn/discount/redemption/withdrawal paths verified in prior phases: Purchase→Order→Customer→Account→Ledger is fully traversable; company identity is determinable at NO point (every hop company-less). Reversal/cancel paths identical (actor recorded, never a company).

## K. Invoice Company Identity
Invoices carry client/branch/amount/status only (live columns queried) — no company_id, no order_id. Paths Invoice→Order and Invoice→Company: both MISSING (separate gaps, both carried).

## L. Payment Company Identity
PAYMENT ARCHITECTURE INCOMPLETE (stub table: invoice/client/amount, no status/method/order/withdrawal links). Zero company identity in any payment object. Nothing to bridge from.

## M. Company Identity Matrix
| Domain | Entity | Company Identity | Explicit/Derived | Source | Status |
|---|---|---|---|---|---|
| Customer | users | none | — | zero-column proof | MISSING |
| Order | orders | none | — | zero-column proof | MISSING |
| Branch | branches | none | — | location-only DDL | MISSING |
| Product | products | none (manufacturer text ≠ company) | — | 0002:16 | MISSING |
| Bonus Account | bonus_accounts | none | — | PK is user_id | MISSING |
| Bonus Ledger | bonus_ledger | none | — | 0 company cols live | MISSING |
| Redemption | bonus_redemptions | none | — | same graph | MISSING |
| Withdrawal | bonus_withdrawals | none | — | status-only terminal | MISSING |
| Invoice | invoices | none | — | live columns | MISSING |
| Payment | payments | none | — | stub columns | MISSING |
| Journal Entry | financial_journal_entries | company_id column | Explicit | live columns | EXISTS |
| Journal Line | financial_journal_lines | via entry | Derived | entry FK (standard) | EXISTS |

## N. Bonus → Company → GL Trace
CUSTOMER→ORDER→BONUS ACCOUNT→BONUS LEDGER→BONUS EVENT: all COMPLETE. Then ??????????: NO EXISTING COMPANY OWNERSHIP PATH (no link, no derivation, no RPC parameter). Then COMPANY→GL: EXISTS within finance (company_id columns). Bridge verdict: NOT DERIVABLE end-to-end.

## O. Multi-Company Risk
Schema/code neither forbids nor implements multi-company on the operational side: a customer COULD transact across branches (no constraint prevents it) but that proves nothing about companies (branches aren't companies). A bonus account CANNOT span customers (PK). Orders reference one client + one branch. No evidence of multi-company operation OR violation exists — the question is currently MEANINGLESS in-schema (no company entity participates). Recorded as UNKNOWN-by-absence, not as risk-realized.

## P. Critical Findings
1. Bridge precondition missing: any Bonus→GL design must FIRST establish company identity for bonus-side events (new decision + new plumbing, not a mapping exercise).
2. Scope guard: the financial module's company model must not be assumed to cover operations (separate provenance: LIVE ONLY, no shared migrations).
3. Journal RPC takes no company input — even finance-side posting origin needs its own audit before bridge design.
4. No finding here unblocks, alters, or re-scopes prior locks; D4/GL direction remains fully open.

## Q. Technical Gaps
Company derivation path; order/branch/customer company attribution (if ever wanted); journal company-resolution audit; invoice/payment company linkage; CoA purpose-mapping for bonus (UNKNOWN carried). All gaps, no builds.

## R. Business Policy Dependencies
Financial ownership assignment (who owns which company); whether operations stay single-company by policy; D4 treatment per company; BD-2/taxonomy unaffected. None selected.

## S. Final Architecture Graph
CUSTOMER→ORDER→BONUS ACCOUNT→BONUS LEDGER→BONUS EVENT: COMPLETE. EVENT→???: NO EXISTING COMPANY OWNERSHIP PATH. COMPANY→GENERAL LEDGER: EXISTS (finance-internal). End-to-end bridge: NOT DERIVABLE — recorded as the phase's central result.

Operation log: read-only SELECTs + repo greps only; one SQL error of mine (ORDER BY position, corrected and retried clean); no timeouts otherwise; no hidden errors.

PHASE 42 COMPLETE — COMPANY IDENTITY & FINANCIAL OWNERSHIP AUDIT
READ-ONLY
NO FILES MODIFIED EXCEPT REPORT
NO DATABASE CHANGES
NO SQL WRITE
NO MIGRATION CREATED
NO COMMIT
NO PUSH
ACCOUNTING POLICY NOT DECIDED
BD-2 NOT DECIDED
NO BONUS → GL IMPLEMENTATION
