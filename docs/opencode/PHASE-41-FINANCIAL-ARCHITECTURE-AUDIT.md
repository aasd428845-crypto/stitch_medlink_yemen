# PHASE 41 — FINANCIAL ARCHITECTURE AUDIT (read-only forensic)

## A. Executive Summary
Conflict resolved: Phase 40's "zero financial objects" holds ONLY for the Flutter app + migration files — LIVE Supabase carries 27 `financial_*` tables + 4 journal RPCs, served by the web PWA financial module (zero bonus references anywhere in it). Provenance: no repo migration creates any financial table (grep-empty) → LIVE ONLY objects of unknown application origin (dashboard-created or externally applied; not determinable read-only). Decisive finding: ZERO Bonus↔GL linkage exists at any layer (no FKs, no RPC cross-references, no UI references, no source columns). Blocking asymmetry: journals are company-scoped (`company_id`, `financial_companies`) while bonus is company-less — naive bridging is structurally impossible. Invoices lack `order_id`/discount fields; `payments` is minimal invoice-linked with no withdrawal/order ties.

## B. Repository vs Live Financial State
Repo: bonus chain (0017–0022) + Flutter wallet UI + PWA financial UI text; NO financial DDL, NO posting calls from bonus code, NO bonus imports in financial UI/API. Live: bonus chain (fingerprinted across phases) + full financial module (27 tables, 4 RPCs, CoA seeded). Delta = entire GL module is LIVE ONLY. Confidence: high (catalog queries, not history — manual-apply provenance limitation carried from prior phases).

## C. Financial Objects Inventory
TABLES live (27, §B list verified): accounts, audit_logs, bank_*/cash_* (accounts/movements/reconciliations), budgets(+lines), companies, cost_centers, currencies, documents, exchange_rates, expenses, fiscal_years, fixed_assets, inventory_movements, journal_entries, journal_lines, periods, receipts, stock_counts(+lines), supplier_bills/payments/suppliers. FUNCTIONS live: `create/post_financial_journal_entry` + 2 posted-mutation guard triggers — bodies bonus-free (verified). TRIGGERS: journal immutability only. POLICIES/SERVICES: PWA `financialApi.ts` (54 lines, zero bonus refs), Journal/Expenses/Receipts/Financial pages. POSTING ENGINE: exists as manual/director-driven entry creation — NO automatic posting from any business event. MODELS: no shared ledger↔journal link object anywhere. All type STATUS: LIVE ONLY except bonus-side rows (EXISTS both).

## D. Chart of Accounts
Live sample (queried, Arabic names): 1110 الصندوق (cash), 2100 suppliers/payables, 4000 الإيرادات (revenue), 5000 تكلفة المبيعات (COGS). Parent/type columns not inventoried (out of scope for the linkage question); existence proves a real seeded CoA, not a stub. No bonus-specific accounts identified (no code search performed for account purpose — recorded as UNKNOWN, not missing).

## E. Posting Engine
EXISTS as human-operated entry creation (`create_` + `post_` RPCs with immutability guards). NOT FOUND: any automatic posting from orders, invoices, payments, or bonus events (both journal bodies bonus-free; no triggers on business tables referencing journals — trigger inventory shows only the two posted-mutation guards). Posting = manual director action, nothing else.

## F. Bonus Subledger
Complete and self-contained (accounts/ledger/rules_v2/redemptions/withdrawals/settings/audit/allocations + earn/cancel engines), company-less, app-integrated, live-verified across Phases 18/34. Zero outbound references to financial objects (grep + live FK scan empty).

## G. Bonus → GL Integration
Per-event verdicts — EARN / ORDER DISCOUNT / REDEMPTION / WITHDRAWAL / REVERSAL / EXPIRATION: Bonus Ledger YES (all six), Accounting Event NO, Journal Entry NO, Journal Lines NO, GL Link NONE. Status for all six: subledger-complete, GL-MISSING. No link invented, none found.

## H. Invoice Architecture
| Capability | Exists? | Evidence | Status |
|---|---|---|---|
| Invoice table | YES live | columns queried (id/client/amount/status/due/paid/created/branch) | EXISTS |
| Invoice items | NO | no table live | MISSING |
| Order linkage | NO | no order_id column | TECHNICAL GAP (standing) |
| Bonus discount linkage | NO | no discount columns; allocate math pre-linkage | TECHNICAL GAP |
| Revenue posting | NO | no auto-posting ( §E) | MISSING |
| Receivable posting | NO | payments minimal, manual | MISSING |
| Journal linkage | NO | no FKs/refs | MISSING |

## I. Payment Architecture
`payments` EXISTS live but minimal (invoice_id/client/amount/created_at — no status/method/order/withdrawal linkage). No payment provider, no settlement engine, no order-payment state. Verdict: a payment RECORD stub, not architecture. Nothing to integrate against yet.

## J. Bonus Cash Withdrawal (end-to-end trace)
Request → review → approve/reject → mark-paid → complete (0018 RPC chain, app-wired). Terminal state is a STATUS (`COMPLETED`/paid markers), not money movement: no cash/bank account debited by code, no GL posting, no link to `financial_cash_*` or `payments`. "Status = PAID" proves workflow completion ONLY — recorded explicitly per mandate.

## K. Bonus Product Redemption (end-to-end trace)
Redemption reserve → approve → fulfill consumes bonus lots; fulfillment path touches reservation ledger + Free-Y-style fulfillment. No inventory deduction by redemption code, no order/invoice/COGS/revenue/journal creation found (creation RPC and allocate paths carry no redemption hooks). Redemption ends at bonus lots consumed + status fulfilled.

## L. Bonus Order Discount (end-to-end trace)
Apply (0020) → ledger debit + lots + snapshot → allocate (0021-F2 nets invoice math) → invoice row (branch-visible, client-invisible, unlinked) → cancel path reverses atomically (0021/0022). Path STOPS at the invoice row. No GL, no receivable update beyond the invoice amount itself, no revenue treatment.

## M. Cancellation Accounting Boundary
`cancel_order_with_discount` reverses the SUBLEDGER only (compensating REVERSAL + history + audit). No accounting reversal exists because no accounting entry is ever created. Order state + invoice rows are untouched by cancel (invoice staleness on cancel: TECHNICAL GAP carried, not new).

## N. Source Traceability
`source_document_id` exists on journal entries (generic, nullable) — but ZERO usage evidence links any journal to bonus_ledger ids (no FKs, bodies bonus-free, UI bonus-free). Per mandate: column presence ≠ integration; verdict NO LINK. No source_type/reference/origin columns pointing at bonus found at any layer.

## O. Business Policy vs Technical Gap
| Question | Technical Fact | Policy Needed? | Gap? |
|---|---|---|---|
| BD-2 taxonomy | no values anywhere | YES (values only) | policy |
| D4 discount treatment | no treatment coded | YES | policy |
| Earn accounting event? | none fires | YES (whether/at all) | policy + build |
| Withdrawal treatment | status-only terminal | YES | policy + build |
| Redemption treatment | lots-only terminal | YES | policy + build |
| Reversal accounting | none exists to reverse | YES (if events ever post) | policy |
| Expiration accounting | none fires | YES | policy + build |
| Invoice↔discount | unlinked rows | YES (H2) + build | both |
| Payment lifecycle | stub table only | YES (model first) | both |
No policy selected anywhere in this report.

## P. Migration Provenance
0017–0022: local files + live fingerprints consistent (prior phase gates). Financial module: NO local migration, live-only presence; application method UNKNOWN (dashboard/manual/external — not determinable read-only). Schema fingerprints used throughout, never CLI history.

## Q. Final Architecture Map
ORDER —EXISTS→ BONUS EARN —EXISTS→ BONUS SUBLEDGER (discount/redemption/withdrawal/reversal/expiration all EXISTS inside) —MISSING→ ACCOUNTING? (no events fire) —MISSING→ GENERAL LEDGER? (manual entries only, company-scoped, bonus-blind) —MISSING/PARTIAL→ INVOICE (rows exist, unlinked, manual) / PAYMENT? (stub). The single structural fault line: company-scoped GL vs company-less bonus — any future bridge must resolve identity mapping first (not designed here).

## R. Remaining Decisions
D4 + full accounting-event policy per flow; BD-2; H-approvals; invoice linkage; payment model; CoA purpose-mapping for bonus accounts (UNKNOWN today); bridge ownership/sequencing. Presented as OPTION space only where alternatives exist (manual-vs-automatic posting; subledger-mapping vs parallel books) — no option selected, no language of preference used.

## S. Verification Log
Read-only SELECTs only (catalog, columns, FK scan, body-marker checks, CoA sample). Failures, all retried to success unless noted: one transient pooler auth failure (28P01) on the journal-columns probe — retried, succeeded; zero timeouts this phase; zero hidden errors. CLI v2.118.0 notice (installed v2.117.0) — informational. One correction vs prior phases: Phase 40's "zero financial objects" is now SCOPED (true for Flutter+migrations, false live) — superseded by §A evidence, not deleted history.

PHASE 41 COMPLETE — FINANCIAL ARCHITECTURE AUDIT
READ-ONLY
NO FILES MODIFIED EXCEPT REPORT
NO DATABASE CHANGES
NO SQL WRITE
NO MIGRATION CREATED
NO COMMIT
NO PUSH
BD-2 NOT DECIDED
ACCOUNTING POLICY NOT DECIDED
