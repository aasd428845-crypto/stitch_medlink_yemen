# PHASE 49 — BONUS ACCOUNTING DECISION MATRIX

**Type:** read-only analysis + documentation. No implementation, no execution, no policy selection.
**Repository:** `stitch_medlink_yemen` (root migration root `supabase/`, web migration root `Medlik-Waap/supabase/`, Flutter client `medlink_app/`).
**Date of evidence:** 2026-09-30 (repository reads). Live-database facts are **carried** from PHASE-41 / PHASE-46 and are labelled wherever used.
**Predecessors used:** PHASE-41 (financial architecture audit), PHASE-45 (company architecture decisions), PHASE-46 (bonus current-state audit), PHASE-47 (rule contract fix design), PHASE-8 (test environment architecture), `docs/REWARDS_SYSTEM_MASTER_STATUS.md`.

---

## 0. Document control

### 0.1 Purpose

This document converts the scattered accounting evidence of PHASE-41 / PHASE-45 / PHASE-46 into a **decision matrix**: for every bonus money operation it states, with repository line-level evidence:

1. what business event occurs,
2. what the bonus subledger records,
3. whether any accounting integration exists (it does not),
4. whether any general-ledger object is written (it is not),
5. which parts are already built, which are technical gaps, which are open business policy, and which could not be verified in this phase,
6. exactly which decision a future, separately-authorised phase would depend on.

### 0.2 What this document is not

- It is **not** a design, a specification, or a migration plan.
- It **does not select** an accounting policy, an account code, a posting rule, a timing convention, a tax treatment, or an integration architecture.
- It contains **no** language of preference ("best", "recommended", "should", "preferred", "optimal"). Where alternatives exist they are enumerated as an **option space** and left unselected.
- It does not re-open decisions recorded as settled in PHASE-46 §M (discount policy D1–D8, cancellation shape BD-1, H1/H2/H3 locks, automatic-reversal default, per-company deployments, central products + branch stock, branch-manager fulfilment ownership).

### 0.3 Scope

In scope: every code path that writes a row to `public.bonus_ledger`, every path that writes a bonus-related physical movement, and the boundary between those paths and the `financial_*` (general-ledger) layer.

Out of scope: the legacy Buy-X-Free-Y catalogue mechanism except where it produces a movement row (§3 E12); the Flutter/PWA user interface as such; deployment, hosting, cost; the test database (PHASE-8, deliberately untouched).

### 0.4 Classification legend (applies to every row of every matrix below)

| Class | Meaning |
|---|---|
| **EXISTING** | The behaviour is implemented in code that exists in the repository, at the cited line. |
| **TECHNICAL GAP** | A required object, column, link, writer, or call does not exist. Building it is an engineering act with no policy content. |
| **BUSINESS POLICY** | The behaviour cannot exist until an owner states a rule. No amount of engineering substitutes for the statement. |
| **BUSINESS POLICY REQUIRED** | Marker applied to any row that also involves a business-policy dependency, i.e. the row is **not resolvable in code alone**. |
| **NOT VERIFIED** | Evidence available to this phase is insufficient to assert the fact. Explicitly not a synonym for "missing". |

### 0.5 Evidence conventions

- `file:line` refers to the repository as read on 2026-09-30.
- A claim derived from a **read-only database query in an earlier phase** is prefixed **LIVE (carried)**, naming the originating phase and section. **No database query was executed in PHASE 49.**
- A claim derived from a file read or grep in this phase needs no prefix; the `file:line` is the evidence.
- Contradictions with predecessor reports are recorded as such rather than silently resolved (§2.4).

---

## 1. Executive summary

### 1.1 The single structural fact

The bonus subledger is **complete and self-contained**, and it is **completely absent from the accounting system**. Measured in this phase over the eight migrations that constitute the bonus money chain (`supabase/migrations/0016`–`0023`), occurrences of the string `financial_` are **0, 0, 0, 0, 0, 0, 0, 1** — and that single occurrence is a comment inside `0023` that names `0018` as a file, not a reference to a financial object (`0023_bonus_rule_max_earn_contract_fix.sql:8`).

Further, repository-wide:

- no bonus RPC body calls `fn_financial_auto_entry`, `create_financial_journal_entry`, or `post_financial_journal_entry`;
- no bonus RPC body inserts into `financial_documents`, `financial_journal_entries`, or `financial_journal_lines`;
- no `bonus_*` table declares a foreign key, column, or comment referencing a `financial_*` table, and none is declared in the reverse direction.

This is consistent with the independent live findings of PHASE-41 §C/§G/§N and PHASE-46 §I.2 (0 FKs, 0 body references, 0 UI references, 0 journal rows referencing bonus).

### 1.2 The consequence for every row of this matrix

Every accounting column below therefore reads **"no journal entry exists"** — not "wrong journal entry", not "unposted journal entry". The accounting question in MedLink today is not a defect to repair; it is a **policy vacuum to fill**, and only then a build task.

### 1.3 What exists on the accounting side, and its real wiring

| Object | Where it exists | What it is actually wired to |
|---|---|---|
| 27 `financial_*` tables | DDL in the **web migration root** `Medlik-Waap/supabase/migrations/0006`–`0013` (+ `Medlik-Waap/supabase/financial_installer.sql`); **LIVE (carried, PHASE-46 §I.1)** | Manual director/accountant bookkeeping |
| Seeded chart of accounts (14 codes) | `Medlik-Waap/supabase/migrations/0007_financial_setup_rls.sql:38-59`; later additions `0009:18-24` (6110), `0011:17-23` (126000) | — |
| `fn_financial_auto_entry` | `Medlik-Waap/supabase/migrations/0009_financial_auto_posting.sql:35` | Invoice insert (`0009:108-133`), driver commission paid (`0009:141-181`) |
| `trg_financial_bonus_inventory` | `Medlik-Waap/supabase/migrations/0009_financial_auto_posting.sql:184-220` | `order_items.is_bonus` → `financial_inventory_movements` type `'bonus'` (**quantity only — legacy Free-Y; writes no journal**) |
| Manual journal RPCs | `Medlik-Waap/supabase/migrations/0010_financial_simple_entries.sql:278,308` | Director-initiated only |
| `trg_financial_invoice_auto_journal` | `Medlik-Waap/supabase/migrations/0009_financial_auto_posting.sql:108-139` | Every insert into `invoices` → draft journal 1130 / 4000 |

The only object in the system whose name contains both "financial" and "bonus" is that legacy quantity trigger. **No object anywhere bridges the financial bonus subledger to accounting.**

### 1.4 The structural blocker (carried, unresolved)

`financial_journal_entries.company_id` is `not null` → `financial_companies` (`Medlik-Waap/supabase/migrations/0006_financial_core.sql:154`), while the bonus side has **no company concept**: `bonus_accounts`, `bonus_ledger`, `bonus_rules_v2`, `bonus_redemptions`, `bonus_withdrawals` carry no company column (`supabase/migrations/0018_bonus_financial_system.sql:22-75,118-135,189-235`). PHASE-41 §Q and PHASE-46 §I.3 recorded this as the single structural fault line; PHASE-45 left BD-01…BD-11 undecided. Nothing in this phase changes that: **every posting target is company-scoped; the source event is not.**

### 1.5 Counts produced by this phase

| Class | Count of distinct items | Sections |
|---|---|---|
| EXISTING (subledger behaviour, fully evidenced) | 12 operations/flows | §3 |
| EXISTING (accounting behaviour reachable by a bonus event) | 0 | §3, §4 |
| TECHNICAL GAP | 11 | §4–§9 |
| BUSINESS POLICY REQUIRED (unresolvable in code alone) | 14 | §4, §5, §8, §9, §11 |
| NOT VERIFIED in this phase | 6 | §2.3, §5.2, §9.3 |

**Nothing in this document was decided, implemented, or executed.** Policy selection is deferred to the owner gate in §13.

---

## 2. Evidence base and method

### 2.1 Objects inventoried in this phase

**Bonus side (root migration root, `supabase/migrations/`):**

| Migration | File | Financial relevance |
|---|---|---|
| 0016 | `0016_bonus_inventory_allocation_safety.sql` | Allocation safety (dual copy with the web root — §2.2) |
| 0017 | `0017_bonus_order_integrity_and_analytics.sql` | Order integrity, `is_bonus` handling |
| 0018 | `0018_bonus_financial_system.sql` | **The subledger core**: `bonus_accounts`, `bonus_ledger`, `bonus_rules_v2`, `bonus_redemptions`, `bonus_withdrawals`, `bonus_settings`, `bonus_audit_trail`, `bonus_earn_allocations`, 16 RPCs, immutability trigger, reversal uniqueness index |
| 0019 | `0019_bonus_earn_engine.sql` | Earn engine, rule validation, delivery trigger, pending processor, expiry/usage-limit semantics |
| 0020 | `0020_order_discount.sql` | Order discount apply/cancel, discount policy settings keys |
| 0021 | `0021_order_cancellation_with_discount.sql` | Cancellation + compensating reversal, invoice-total netting |
| 0022 | `0022_order_cancellation_history.sql` | Cancellation history table with `reversal_ledger_id` FK |
| 0023 | `0023_bonus_rule_max_earn_contract_fix.sql` | Untracked, unapplied rule-contract fix (PHASE-47 output) |

**Accounting side (web migration root, `Medlik-Waap/supabase/migrations/`):** `0006_financial_core.sql` (tables, views, posting helper), `0007_financial_setup_rls.sql` (company/fiscal-year/period seed + 13-code chart of accounts + RLS), `0008_financial_audit_immutability.sql` (posted-entry immutability), `0009_financial_auto_posting.sql` (account 6110 + `fn_financial_auto_entry` + three triggers), `0010_financial_simple_entries.sql` (cash/bank seeds + 4 RPCs), `0011_financial_doctors_payouts.sql` (account 126000), `0012`–`0013` (receipts columns, exchange rates).

**Clients:** `Medlik-Waap/artifacts/pharma-pwa/src/lib/bonusFinancialApi.ts` (director surface), `Medlik-Waap/artifacts/pharma-pwa/src/pages/director/BonusFinancialDashboardPage.tsx`, `medlink_app/lib/services/bonus_wallet_service.dart` (customer surface).

### 2.2 Repository-topology caveat (must precede every account-code reading)

There are **two migration roots with overlapping numeric prefixes** and they are not the same timeline. The accounting layer exists **only** in the web root (`Medlik-Waap/supabase/migrations/`), while the bonus money chain exists **only** in the root (`supabase/migrations/`). Root-only replay therefore cannot produce the accounting layer at all. This is PHASE-8's finding (an interleaved 37-file chain is required; `0015`/`0016` exist as divergent duplicates). It is the reason source traceability in §6 is expressed with an explicit root prefix.

### 2.3 What could not be established in this phase (NOT VERIFIED)

| # | Item | Why not | Effect on this document |
|---|---|---|---|
| N1 | Whether the live database matches the web root's `0006`–`0013` exactly | No database access in PHASE 49; PHASE-46 §I.1 verified object *presence*, not body-by-body equality, and recorded 3 views with no DDL anywhere | Account-mapping rows are labelled *repository-defined*, not *live-confirmed* |
| N2 | Which of the two `0016` copies is live | No database access; PHASE-8 R2 requires the production dump to answer | Does not affect any accounting row (neither copy is accounting-bearing) |
| N3 | Whether `fn_financial_auto_entry` currently succeeds at runtime on production | It resolves the company by `order by created_at limit 1` (`0009:57-60`) and raises if none exists; the failure path is swallowed into `financial_audit_logs` (`0009:125-128`) | §5.2 records both branches as possible; nothing is asserted |
| N4 | Whether any manual journal entry has ever referenced a bonus event | Requires reading production journal content | §6 states repository-level absence only |
| N5 | Whether the views/functions with no repository DDL (PHASE-46 §I.1) include a posting path | No repository source exists for them | Could in principle change §4; recorded as an open item, and **not** assumed to be a bridge |
| N6 | Business volume of each operation today | Requires production data reads | The financial-impact matrix §7 is expressed per unit, not in aggregate |

### 2.4 Contradictions and corrections carried forward

| # | Conflict | Resolution adopted here |
|---|---|---|
| C1 | PHASE-40 says "zero financial objects"; PHASE-41/46 say 27 live tables | **Superseded**: true for the Flutter app and the root migration files, false for the live database (PHASE-41 §A/§S). This document follows PHASE-41/46. |
| C2 | `docs/REWARDS_SYSTEM_MASTER_STATUS.md:74` calls `trg_financial_bonus_inventory` "live-only (no repo source — provenance gap)" | **Corrected in this phase**: the source exists at `Medlik-Waap/supabase/migrations/0009_financial_auto_posting.sql:184-220`. PHASE-46 §I.1 had already located it; the status document is stale on this point. |
| C3 | PHASE-46 §I.2 records `accounting_treatment: null` "in the 0020 snapshot (0020:250)" | **Not reproducible**: a repository-wide grep for `accounting_treatment` over `*.sql`/`*.ts`/`*.tsx`/`*.dart` returns no match. What `0020` actually stores is a JSON snapshot of `order_total`/`requested`/`available`/`applied` (`0020:236-245`). The *substance* of PHASE-46's conclusion stands; the citation does not. Corrected to: **the discount snapshot carries no accounting field of any kind.** |
| C4 | PHASE-46 §L lists the `max_bonus`/`max_earn` defect as L1 | Unchanged and still open; `0023` is an untracked local file and must not be applied without the PHASE-47 §K.4 preconditions. It has **no accounting content**. |

### 2.5 Method

1. **Enumerate writers.** Every `insert into public.bonus_ledger` in the repository was located and its enclosing function identified; the set is closed (§3).
2. **Enumerate the enum.** The `bonus_ledger.txn_type` CHECK list (`0018:57-61`) was compared against the writers found, to separate implemented operations from declared-but-unwritten types.
3. **Trace outward.** For each writer the body was read in full for any call into the `financial_*` layer, and a per-file occurrence count of `financial_` was taken across the bonus chain.
4. **Trace the accounting side inward.** `fn_financial_auto_entry`, the three auto-posting triggers, and the manual journal RPCs were read to determine which business tables are wired, and whether any of them is a bonus table.
5. **Classify.** Each row received one §0.4 class; any row with a policy dependency additionally carries **BUSINESS POLICY REQUIRED**.
6. **Assert nothing about production.** Live facts are quoted, attributed, and never extended.

---

## 3. Business event → Bonus subledger → Accounting integration → GL

### 3.1 The four-column convention

Every row is read left to right as a **chain that terminates**:

`BUSINESS EVENT` → `BONUS SUBLEDGER (what is written)` → `ACCOUNTING INTEGRATION (the call that would move money into accounting)` → `GL (the journal/document row produced)`.

In the current repository the third and fourth columns are empty for **every** bonus event. The rows below therefore state *what the third column would have to be* — which is exactly why each row carries a policy dependency.

### 3.2 The closed set of ledger writers

Writers of `public.bonus_ledger`, exhaustive (each `insert` located and attributed):

| Writer | Line | `txn_type` written | Status written |
|---|---|---|---|
| `post_opening_balance` | `0018:657-660` | `OPENING_BALANCE` | `POSTED` |
| `post_legacy_migration` | `0018:725-728` | `LEGACY_MIGRATION` | `POSTED` |
| `earn_bonus` | `0018:777-780` | `EARN` | `POSTED` |
| `request_redemption` | `0018:851-854` | `REDEEM_PRODUCT` | `PENDING` |
| `request_withdrawal` | `0018:1123-1126` | `CASH_WITHDRAWAL` | `PENDING` |
| `reverse_bonus_txn` | `0018:1393-1399` | `REVERSAL` | `POSTED` |
| `expire_bonus` | `0018:1466-1471` | `EXPIRATION` | `POSTED` |
| `bonus_evaluate_order_earn` (delivery trigger) | `0019:397-402` | `EARN` | `POSTED` |
| `apply_order_discount` | `0020:247-252` | `ORDER_DISCOUNT` | `PENDING` → then flipped to `POSTED` |
| `cancel_order_discount` | `0020:391-401` | `REVERSAL` | `POSTED` |
| `cancel_order_with_discount` | `0021:134-138` (and `0022:166-172`) | `REVERSAL` | `POSTED` |

Declared in the CHECK constraint but **never written by any code path**: `REFUND`, `ADJUSTMENT` (`0018:57-61`). This matches PHASE-46 §D rows 8–9 exactly.

### 3.3 E1 — Bonus earn from a delivered order (automatic)

| Stage | Content | Evidence | Class |
|---|---|---|---|
| Business event | An order transitions to `delivered` | Trigger `trg_bonus_on_order_delivered` (`0019:507-513`, `after update of status` with `when OLD.status is distinct from 'delivered' and NEW.status = 'delivered'`) | EXISTING |
| Trigger function | `bonus_on_order_delivered` — diverts to a hold row when the account is `suspended`, otherwise calls the evaluator | `0019:463-501` | EXISTING |
| Evaluation | Per active rule: eligible slice recomputed from non-bonus `order_items` at `order_items.unit_price`; min-value and min-quantity gates; usage limit counted from POSTED `EARN` rows net of `REVERSAL`s | `0019:318-347` | EXISTING |
| Amount composition | `PER_ORDER` → `bonus_value`; `PER_UNIT` → `eligible_qty × bonus_value`; `PER_PRODUCT` → Σ `qty × product_values[product]`; `MONETARY` → `eligible_value × bonus_percent / 100`; then capped by `max_bonus` | `0019:353-379` | EXISTING (the cap is currently unreachable — §2.4 C4 / PHASE-47) |
| Subledger write | One `EARN` row, `POSTED`, positive amount, `order_id` set, `rule_id` set, `actor` = customer, idempotency key `SALES_EARN:{order}:{rule}` | `0019:386,397-402` | EXISTING |
| Failure handling | Containable per-rule failures → `bonus_pending_entitlements`; config errors raise loudly and roll back the status change for a safe retry | `0019:404-455,463-501` | EXISTING |
| Accounting integration | **none** — no call to any `financial_*` function exists in the file (`financial_` occurrences in `0019`: **0**) | grep this phase | TECHNICAL GAP + **BUSINESS POLICY REQUIRED** |
| GL | **no journal entry, no document, no source reference** | grep this phase; LIVE (carried) PHASE-46 §I.2 | — |
| Question that must be answered first | Is a granted bonus a liability at grant time, an expense at grant time, or nothing until redemption? At what amount — the rule value, or the catalogue cost of the future redemption? | — | **BUSINESS POLICY REQUIRED** |

### 3.4 E2 — Bonus earn posted manually by the director

| Stage | Content | Evidence | Class |
|---|---|---|---|
| Business event | Director posts a discretionary credit | PWA `earnBonus` → RPC `earn_bonus` (`Medlik-Waap/artifacts/pharma-pwa/src/lib/bonusFinancialApi.ts:239`; `0018:741`) | EXISTING |
| Preconditions | Actor must be `company_director`; target account must exist and be `active` | `0018:753-770` | EXISTING |
| Subledger write | `EARN`, `POSTED`, positive, optional `rule_id`, `reference` + `reason` stored, optional idempotency key | `0018:777-780` | EXISTING |
| Accounting integration | **none** | `0018` contains 0 occurrences of `financial_` | TECHNICAL GAP + **BUSINESS POLICY REQUIRED** |
| GL | none | — | — |
| Reachability note | PHASE-46 §L19 records `earnBonus` as exported with zero UI callers; the RPC is granted to `authenticated` (`0018:1495`) and therefore callable from any director-side script or ad-hoc RPC call | carried | EXISTING (reachable) / NOT VERIFIED (actually used) |

### 3.5 E3 — Cash withdrawal: request

| Stage | Content | Evidence | Class |
|---|---|---|---|
| Business event | Customer asks for bonus as cash | Flutter `bonus_wallet_service.dart` (customer surface); PWA `requestWithdrawal` → `0018:1045` | EXISTING |
| Policy gate | Reads `bonus_settings.withdrawal_policy`; the seeded value is `{"enabled": false, "approval_required": true}`, so the path **raises by default**; optional `min_amount` / `max_amount` caps | `0018:1074-1086`; seed `0018:305` | EXISTING (policy-driven) |
| Funds gate | `bonus_account_funds` must report sufficient available balance | `0018:1088-1093` | EXISTING |
| Subledger write | `CASH_WITHDRAWAL`, **`PENDING`**, negative amount, `withdrawal_id` linked, idempotency key optional | `0018:1123-1126` | EXISTING |
| Lot attribution | `bonus_allocate_spend` attributes the reservation to specific credit lots, oldest first | `0018:1130`; allocator `0018:475-546` | EXISTING |
| Accounting integration | **none at request time.** No accrual, no liability reclassification, no memo document | `0018` grep = 0 | TECHNICAL GAP + **BUSINESS POLICY REQUIRED** |
| GL | none | — | — |
| Question that must be answered first | Is the request an accounting event at all, or only the settlement? If only settlement, how is a request that sits `PENDING` across a period close represented? | — | **BUSINESS POLICY REQUIRED** |

### 3.6 E4 — Cash withdrawal: approval, payment, completion

| Stage | Content | Evidence | Class |
|---|---|---|---|
| `start_withdrawal_review` | `PENDING` → `UNDER_REVIEW`, actor recorded | `0018:1148-1176` | EXISTING |
| `review_withdrawal` | Approve → `APPROVED`; reject → `REJECTED` **and the PENDING ledger reservation is deleted** | `0018:1185-1235` (approve `1213-1217`; reject `1228-1231`, reservation release `1226`) | EXISTING |
| `mark_withdrawal_paid` | Requires a non-blank payment reference; flips the `PENDING` ledger row to `POSTED` (exactly one row must flip or it aborts); sets `PAID`, `paid_by`, `paid_at`, `payment_reference`, `receipt_url` | `0018:1244-1291` | EXISTING |
| `complete_withdrawal` | `PAID` → `COMPLETED` (terminal bookkeeping only) | `0018:1296-1325` | EXISTING |
| Settlement leg | **No `financial_cash_movements` row, no `financial_bank_movements` row, no journal.** The only artefact of paying money out is a text reference string inside `bonus_withdrawals` | read of `0018:1244-1291`; agrees with PHASE-46 §D.1 and PHASE-41 §J | **TECHNICAL GAP** |
| Accounting integration | none | — | TECHNICAL GAP + **BUSINESS POLICY REQUIRED** |
| GL | none | — | — |
| Consequence | Cash leaves the business with a bonus-ledger debit as the only record, and the accounting cash/bank balance is not reduced by this path. Whether the cash account is `1110`/`1120` and what the contra account is remains undecided; the codes exist (`0007:44-45`) but no bonus path references them | — | **BUSINESS POLICY REQUIRED** |

### 3.7 E5 — Product redemption: request and approval

| Stage | Content | Evidence | Class |
|---|---|---|---|
| Business event | Customer exchanges bonus value for a catalogue product | `bonus_redeem_screen.dart` / PWA `BonusRedemptionsPage`; RPC `request_redemption` (`0018:793`) | EXISTING |
| Valuation | Reads `products.unit_price` **under a row lock** and stores `bonus_value = unit_price × quantity` as an immutable snapshot on the request | `0018:825-834` | EXISTING |
| Funds gate | Available ≥ `bonus_value` | `0018:836-841` | EXISTING |
| Subledger write | `REDEEM_PRODUCT`, **`PENDING`**, negative, `redemption_id` linked | `0018:851-854` | EXISTING |
| Lot attribution | Reservation attributed to specific credit lots | `0018:857` | EXISTING |
| Approval | `approve_redemption`: `PENDING` → `APPROVED`; no ledger change | `0018:873-902` | EXISTING |
| Rejection | **absent** — `REJECTED` is a legal status (`0018:198`) with no writer | carried, PHASE-46 §D.1 | **TECHNICAL GAP** |
| Accounting integration | none | — | TECHNICAL GAP + **BUSINESS POLICY REQUIRED** |
| GL | none | — | — |

### 3.8 E6 — Product redemption: fulfilment (the physical/valuation split)

| Stage | Content | Evidence | Class |
|---|---|---|---|
| Ledger leg | `fulfill_redemption` flips the `PENDING` reservation to `POSTED`; aborts unless exactly one row flips | `0018:908-948` (`931-937`) | EXISTING |
| Physical leg | **Nothing.** No `inventory` update, no `financial_inventory_movements` insert, no delivery or order record | read of `0018:908-948`; agrees with PHASE-46 §D.1 and PHASE-41 §K | **TECHNICAL GAP** |
| Accounting integration | none | — | TECHNICAL GAP + **BUSINESS POLICY REQUIRED** |
| GL | none | — | — |
| Type-exists note | `financial_inventory_movements` **does** accept a `'bonus'` movement type (`0009:26-32`), but that type is written **only** by the legacy Free-Y trigger on inserting an `is_bonus` order line (`0009:184-220`) — never by redemption fulfilment | read of both files | EXISTING (type) / TECHNICAL GAP (redemption writer) |
| Consequence | At the moment stock leaves the shelf and a bonus liability is extinguished, neither the inventory ledger nor the accounting ledger records it: goods leave at **zero recorded cost** and the liability disappears with **no contra entry** | — | **BUSINESS POLICY REQUIRED** (cost basis and treatment) |

### 3.9 E7 — Order discount: apply

| Stage | Content | Evidence | Class |
|---|---|---|---|
| Business event | Customer spends bonus to reduce the payable value of a pending order | Flutter `order_discount_section.dart`; RPC `apply_order_discount` (`0020:56`) | EXISTING |
| Policy gate | Reads six `bonus_settings` keys seeded by `0020`: `discount.allow_zero_order` (`false`), `discount.funding_scope` (`"ALL_ELIGIBLE_LOTS"`), `discount.cancellation_mode` (`"AUTOMATIC_REVERSAL"`), `discount.max_amount` (`null`), `discount.max_percent` (`null`), `discount.min_amount` (`null`) | seed `0020:43-49`; reads `0020:138-196` | EXISTING (policy-driven) |
| Value composition | Effective discount = min of requested, order total, per-order and per-percent caps; a JSON snapshot of `order_total` / `requested` / `available` / `applied` is written into the ledger row's `notes` | `0020:236-245` | EXISTING |
| Subledger write | `ORDER_DISCOUNT`, negative, `order_id` linked, idempotency key `DISCOUNT:{order}`, status `PENDING` on insert then flipped to `POSTED` in the same transaction | `0020:247-252`; flip `0020:289-295` | EXISTING |
| Lot funding filter | Lots from rules with `allow_discount = false` are excluded; under `MONETARY_ONLY` only `MONETARY`-rule lots qualify; rule-less credits (opening balance, legacy migration) remain eligible under `ALL_ELIGIBLE_LOTS` | `0020:262-285` | EXISTING |
| Accounting integration | **none** | `0020` grep for `financial_` = 0 | TECHNICAL GAP + **BUSINESS POLICY REQUIRED** |
| GL | none at apply time | — | — |
| Note | The snapshot has **no accounting field** (§2.4 C3), so a future posting design cannot read a treatment marker from it | — | TECHNICAL GAP |

### 3.10 E8 — Order discount: effect on the invoice and the receivable

| Stage | Content | Evidence | Class |
|---|---|---|---|
| Where the discount becomes money | When the branch allocates the order, the discount is netted off the invoice total: `v_total := v_total − net POSTED discount`, where net = Σ `−amount` of POSTED `ORDER_DISCOUNT` rows for the order **minus** the POSTED `REVERSAL`s pointing at them | `0021:308-338` | EXISTING |
| Invoice creation | `insert into public.invoices (client_id, branch_id, amount, status, due_date)` with the **netted** total | `0021:345-349` | EXISTING |
| Automated accounting consequence | Because the invoice amount is smaller, the invoice auto-post trigger creates a smaller receivable and a smaller revenue figure — 1130 debit / 4000 credit for `NEW.amount` | `Medlik-Waap/supabase/migrations/0009_financial_auto_posting.sql:108-133` | **EXISTING — and this is the only accounting effect the bonus system has today** |
| What is *not* posted | No line recognises that part of the invoice value was settled with bonus rather than cash; the liability is never credited and the receivable is reduced as if the customer had simply been charged less | `0009:118-122` (exactly two lines) | **BUSINESS POLICY REQUIRED** |
| Guards | Netting raises if the net discount is negative or exceeds the invoice total; the invoice trigger **skips** invoices whose amount ≤ 0 or whose status is `cancelled` | `0021:330-337`; `0009:111` | EXISTING |
| Linkage | `invoices` has no `order_id`; order→invoice traceability is absent by construction, so a posting cannot be tied back to the order that produced it | carried, PHASE-46 §J | TECHNICAL GAP |
| Policy question | Whether revenue should be the gross order value with the bonus recognised as a separate settlement, or the net figure as posted today | — | **BUSINESS POLICY REQUIRED** |

### 3.11 E9 — Discount reversal on cancellation (automatic)

| Stage | Content | Evidence | Class |
|---|---|---|---|
| Business event | An order carrying a `POSTED` discount is cancelled | `cancel_order_with_discount` (`0021:36`; extended in `0022:64`) | EXISTING |
| Detection | The RPC looks up the order's `ORDER_DISCOUNT` ledger rows and computes the effective discount | `0021:101-126`; history variant `0022:133-175` | EXISTING |
| Compensation write | A `REVERSAL` row, `POSTED`, `reverses_id` pointing at the original debit, amount equal to the debit, idempotency key `REVERSAL:DISCOUNT:{order}` | `0021:134-138`; `0022:166-172` | EXISTING |
| Idempotency and race safety | Partial unique index on `reverses_id`; a concurrent cancellation hits the index instead of double-reversing | `0021:145-152` | EXISTING |
| History record | `order_cancellations` row carrying `reversal_ledger_id` FK to the reversal | `0022:19-27,214-216` | EXISTING |
| Manual-invoice lock | H2-A: manual invoices stay independent; cancellation does not touch any invoice row | `0021:311-313` (comment) confirmed by body read | EXISTING (as decided) |
| Accounting integration | **none — and there is nothing to reverse.** No journal was written at apply time, so no compensating journal is written now | `0021`/`0022` grep for `financial_` = 0 | **BUSINESS POLICY REQUIRED** (only if a posting is ever introduced) |
| GL | none | — | — |

### 3.12 E10 — Manual reversal by the director

| Stage | Content | Evidence | Class |
|---|---|---|---|
| Business event | Director compensates a ledger entry (manual earn, opening balance, an earn that should not have happened) | PWA `reverseBonusTxn` → `reverse_bonus_txn` (`bonusFinancialApi.ts:256`; `0018:1332`) | EXISTING |
| Guards | Director only; non-blank reason required; only `POSTED` rows can be reversed; a `REVERSAL` cannot itself be reversed; a second effective reversal of the same row is refused | `0018:1351-1378` | EXISTING |
| Cap rule | Credit rows are capped at the attributable remainder (`bonus_credit_remaining` = amount − allocations − prior compensations) so a reversal cannot fabricate value; debit rows compensate in full | `0018:1380-1390` | EXISTING |
| Subledger write | `REVERSAL`, `POSTED`, negative of the cap, `reverses_id` set, ledger/order/withdrawal/redemption/rule references copied from the original, optional idempotency key | `0018:1393-1399` | EXISTING |
| Accounting integration | **none** | `0018` grep = 0 | TECHNICAL GAP + **BUSINESS POLICY REQUIRED** |
| GL | none | — | — |
| Note | The PWA reverse dialog is the surface PHASE-46 §D row 9 records as the "ADJUSTMENT" UI; it writes `REVERSAL`, and `ADJUSTMENT` still has no writer | carried | EXISTING (UI) / TECHNICAL GAP (`ADJUSTMENT`) |

### 3.13 E11 — Expiration

| Stage | Content | Evidence | Class |
|---|---|---|---|
| Business event | Aged, unconsumed earn lots are extinguished | RPC `expire_bonus(p_asof date)` (`0018:1413`) | EXISTING |
| Preconditions | Director only; `bonus_settings.expiry_policy.expiry_days` must be configured and > 0 or the call raises; **no seed value exists** for this key (`0018:303-308` seeds only `redemption_methods`, `withdrawal_policy`, `notifications`, `currency`) | `0018:1430-1439`; seed `0018:303-308` | EXISTING (raises until configured) |
| Scope of one run | `EARN` rows, `POSTED`, aged beyond the window, with no existing `EXPIRATION` row; computed per lot from `bonus_credit_remaining` so only the leftover is expired | `0018:1441-1461` | EXISTING |
| Subledger write | One `EXPIRATION` row per lot, `POSTED`, negative, `reverses_id` = the lot, with `on conflict (reverses_id) do nothing` for concurrent-run safety | `0018:1466-1474` | EXISTING |
| Scheduling | **none** — no scheduler exists in the repository; PHASE-46 §D row 7 records the same for the live database | carried | **TECHNICAL GAP** |
| Accounting integration | **none.** An expired liability that disappears generates no entry | `0018` grep = 0 | TECHNICAL GAP + **BUSINESS POLICY REQUIRED** |
| GL | none | — | — |
| Policy question | Whether an expired bonus is written back (other revenue) or simply dropped, and whether the write-back belongs to the expiry date or the period close | — | **BUSINESS POLICY REQUIRED** |

### 3.14 E12 — Opening balance, legacy migration, and the legacy Free-Y line

| Operation | Subledger effect | Accounting effect | Evidence | Class |
|---|---|---|---|---|
| `post_opening_balance` | `OPENING_BALANCE`, `POSTED`, positive; moves the account's `mode` to `OPENING_BALANCE`; idempotency key honoured | **none** | `0018:605-668` (rows `657-660`); grant `0018:1493` | EXISTING / TECHNICAL GAP (accounting) |
| `post_legacy_migration` | `LEGACY_MIGRATION`, `POSTED`, positive; sets `mode`; requires an approval reference | **none** | `0018:673-737` (row `725-728`); grant `0018:1494` | EXISTING / TECHNICAL GAP (accounting) |
| Mode reclassification guard | An account already carrying a real mode cannot be silently reclassified; the message states an explicit audited path is "not yet defined — intentionally blocked here" | — | `0018:570-579,703-712` | EXISTING (guard) / **BUSINESS POLICY** (the undefined path) |
| Legacy Free-Y order line | Inserting an `order_items` row with `is_bonus = true` writes a `financial_inventory_movements` row: type `'bonus'`, quantity **negative**, `unit_cost` = the product's `unit_price`, `reference_type='order_items'` | **Quantity only — no journal, no valuation entry, and it uses sale price rather than cost** | `Medlik-Waap/supabase/migrations/0009_financial_auto_posting.sql:184-220`; type allowed at `0009:26-32` | EXISTING (movement) / **TECHNICAL GAP** (valuation) |
| Cross-reference | This trigger is the **only** object that touches both a bonus-flagged row and a `financial_*` table. It belongs to the legacy Free-Y mechanism, not the financial wallet, and creates no liability and no expense | — | read of `0009` | EXISTING (fact) / must not be mistaken for a bridge |

### 3.15 The four-column chain, summarised

| # | Business event | Bonus subledger | Accounting integration | GL |
|---|---|---|---|---|
| E1 | Order delivered → bonus granted automatically | `EARN` POSTED (`0019:397`) | **absent** | **absent** |
| E2 | Director posts a credit | `EARN` POSTED (`0018:777`) | **absent** | **absent** |
| E3 | Customer requests cash | `CASH_WITHDRAWAL` PENDING (`0018:1123`) | **absent** | **absent** |
| E4 | Director pays the cash | `CASH_WITHDRAWAL` → POSTED (`0018:1282`) | **absent**; no cash/bank movement | **absent** |
| E5 | Customer requests a product | `REDEEM_PRODUCT` PENDING (`0018:851`) | **absent** | **absent** |
| E6 | Director fulfils the product | `REDEEM_PRODUCT` → POSTED (`0018:931`) | **absent**; no stock movement | **absent** |
| E7 | Customer applies a discount | `ORDER_DISCOUNT` PENDING→POSTED (`0020:247,289`) | **absent** | **absent** |
| E8 | Branch allocates → invoice | (unchanged) | indirect: invoice total is netted | one **invoice** journal (draft) 1130/4000 for the netted amount (`0009:108-133`) |
| E9 | Order cancelled → discount reversed | `REVERSAL` POSTED (`0021:134`) | **absent** | **absent** |
| E10 | Director reverses an entry | `REVERSAL` POSTED (`0018:1393`) | **absent** | **absent** |
| E11 | Expiry run | `EXPIRATION` POSTED (`0018:1466`) | **absent** | **absent** |
| E12 | Opening balance / legacy migration / Free-Y line | `OPENING_BALANCE`, `LEGACY_MIGRATION` POSTED; a quantity movement for Free-Y | **absent** | **absent** |

**E8 is the only row with any accounting output at all, and that output is produced by the invoice trigger — not by the bonus system.** A reader must not conclude from the existence of that journal that bonus is partly integrated: the journal is blind to the fact that any part of the invoice was settled with bonus.

---

## 4. Accounting Decision Matrix

### 4.1 The seven questions asked of every event

Each bonus event is interrogated with the same seven questions. A question with **no answer in the repository** is marked **BUSINESS POLICY REQUIRED** — those are the cells an owner must fill before any posting design can begin. A question whose answer is "the mechanism does not exist" is **TECHNICAL GAP**.

- **Q1 Accounting event?** — does this moment constitute an accounting event at all?
- **Q2 Accounts?** — which accounts, from the chart that exists, would be involved?
- **Q3 Amount?** — what value, in what currency, at what precision?
- **Q4 Timing?** — when is it recognised relative to the business event?
- **Q5 Reversal?** — what compensates it, and under what conditions?
- **Q6 Source reference?** — what identifier would tie the entry back to the bonus row?
- **Q7 Company scope?** — which `financial_companies` row owns the entry?

### 4.2 Q7 first — because it blocks every other answer

| Question | Repository fact | Class |
|---|---|---|
| Which company owns a bonus entry? | Journals require `company_id NOT NULL` → `financial_companies` (`0006_financial_core.sql:154`); the standard helper resolves a company by `order by created_at limit 1` when none is supplied (`0009_financial_auto_posting.sql:57-60`) | **EXISTING (mechanism)** |
| What is the bonus side's company? | No `bonus_*` table carries a company column (`0018:22-75,118-135,189-235`); no RPC accepts one | **TECHNICAL GAP + BUSINESS POLICY REQUIRED** |
| Is there more than one company? | LIVE (carried, PHASE-45 §R): 13 `company_id` tables, 1 company row | NOT VERIFIED for today |

**Consequence:** every row of §4.3 inherits this dependency. No posting rule can be finalised while the bonus side is company-less, however the other six questions are answered. This is PHASE-41 §Q's "structural fault line" restated as a dependency edge.

### 4.3 The matrix

Legend for every row: **E** = EXISTING, **T** = TECHNICAL GAP, **P** = BUSINESS POLICY REQUIRED.

| Event | Q1 Accounting event? | Q2 Accounts | Q3 Amount | Q4 Timing | Q5 Reversal | Q6 Source reference | Q7 Company |
|---|---|---|---|---|---|---|---|
| **E1 Earn at delivery** (`0019:397`) | P — whether granting creates a liability, an expense, or nothing | P — no bonus account exists in the seeded chart (`0007:42-54`); a liability code would have to be created | P — rule value (which the ledger stores) or future redemption cost | P — at grant vs at redemption vs at expiry | P — the subledger reversal exists (`0018:1332`); its accounting mirror does not | T — `financial_documents.source_table/source_id` exist but no bonus value is ever written | P (via §4.2) |
| **E2 Director earn** (`0018:777`) | P | P | E on the subledger side (the amount is supplied and stored); P on the accounting side | P | P | T | P |
| **E3 Withdrawal request** (`0018:1123`) | P — request-level event or not | P | E on the subledger side (`p_amount`, checked > 0) | P — request vs settlement | E (cancel releases the reservation, `0018:1028-1031`); P for accounting | T | P |
| **E4 Withdrawal paid** (`0018:1282`) | P — the moment cash leaves | P — `1110`/`1120` exist (`0007:44-45`); the contra account does not | P — the paid amount is on the withdrawal row and the ledger | P | P | T — `payment_reference` is a free-text string, not a link | P |
| **E5 Redemption request** (`0018:851`) | P | P | E — `unit_price × quantity` snapshot (`0018:831`) | P | E (cancel releases, `0018:978-981`); P for accounting | T | P |
| **E6 Redemption fulfilled** (`0018:931`) | P — liability extinguished and goods released | P — `1140` inventory and `5000` COGS exist (`0007:47,53`); no bonus liability account exists | P — the redemption value is stored, but the **cost** of the goods is neither read nor written | P | P | T | P |
| **E7 Discount applied** (`0020:247`) | P | P | E — the effective discount is computed and stored | P | E (`0021:134`); P for accounting | T | P |
| **E8 Invoice after discount** (`0021:345`) | **E** — the invoice trigger fires | **E** — `1130` / `4000` (`0009:118-122`) | **E** — `NEW.amount`, i.e. the netted total | **E** — `coalesce(due_date, created_at::date)` (`0009:114`) | T — the trigger writes `draft`, and posted entries cannot be mutated (`0008:29-44`); no reversal RPC is wired to invoices | **E** — `source_table='invoices'`, `source_id=NEW.id` (`0009:117`) | **E** — resolved internally (`0009:57-60`) |
| **E9 Discount reversal** (`0021:134`) | P — only if E7 ever posts | P | E on the subledger side | P | **E** within the subledger (idempotent, capped) | T | P |
| **E10 Manual reversal** (`0018:1393`) | P | P | E — capped at the attributable remainder | P | **E** within the subledger (one per original) | T | P |
| **E11 Expiration** (`0018:1466`) | P | P | E — per-lot remainder | P | **E** within the subledger (`reverses_id` + `on conflict`) | T | P |
| **E12 Opening balance / legacy migration** (`0018:657,725`) | P — an initial grant of value from nowhere | P | E on the subledger side | P | E (reversible like any credit) | T | P |

### 4.4 What the matrix says when read as a whole

| Reading | Finding |
|---|---|
| Cells that are **EXISTING** | 12 of 84, concentrated in E8 (the invoice posting, 5 cells) and in subledger-side amount/timing facts |
| Cells that are **TECHNICAL GAP** | 13 — almost all the single source-reference column (Q6), plus the missing cost basis at E6 |
| Cells that are **BUSINESS POLICY REQUIRED** | 59 |
| Ratio of policy to code | **≈4.5 policy cells per code-only cell** — the arithmetic reason PHASE-46's "no policy selected" gate still stands |

**No cell in this matrix was filled by this phase.** The matrix exists so that one owner conversation can fill the 59 policy cells together, instead of each being discovered mid-implementation.

### 4.5 Flows with no ledger writer at all

`REFUND` and `ADJUSTMENT` are legal `txn_type` values (`0018:57-61`) referenced by no repository code (grep this phase: the only occurrences are the constraint and its comment). PHASE-46 §D rows 8–9 classify them as "UI missing / backend missing (enum-only)" and "backend missing (partial)". Their accounting rows cannot even be drafted, because there is no event to interrogate.

| Value | Finding | Class |
|---|---|---|
| `REFUND` | No writer, no UI, no RPC | **TECHNICAL GAP** (+ policy: whether a refund is a bonus-settled or a cash-settled concept) |
| `ADJUSTMENT` | No writer; the PWA "reverse" surface writes `REVERSAL` instead | **TECHNICAL GAP** (+ policy: whether an adjustment is a distinct business act) |

---

## 5. Account Mapping Matrix

### 5.1 The two account universes, and the bridge between them

There are exactly two sets of account-like codes in this system, and today **no row of the second is produced by the first**:

- **Set A — bonus-side enums.** `bonus_ledger.txn_type` (10 values, `0018:57-61`) plus the status columns. These are subledger buckets, not accounts.
- **Set B — the accounting chart of accounts.** 15 seeded codes (`0007:38-59`, `0009:18-24`, `0011:17-23`).

This matrix is written with the **accounting side as the axis**, because the accounting side is the constrained layer (company-scoped, immutable, trigger-guarded). Every "bonus writer today" cell below is empty except two indirect rows — that is the finding.

### 5.2 The seeded chart of accounts (repository-defined)

Complete inventory of every code inserted by any repository migration or installer, with its seeding statement:

| Code | Name (Arabic) | Type | Level | Postable | Normal balance | Seeded at |
|---|---|---|---|---|---|---|
| `1000` | الأصول | asset | 1 | no | debit | `0007:42` |
| `1100` | الأصول المتداولة | asset | 2 | no | debit | `0007:43` |
| `1110` | الصندوق | asset | 3 | yes | debit | `0007:44` |
| `1120` | البنوك | asset | 3 | yes | debit | `0007:45` |
| `1130` | العملاء والذمم المدينة | asset | 3 | yes | debit | `0007:46` |
| `1140` | المخزون | asset | 3 | yes | debit | `0007:47` |
| `1200` | الأصول الثابتة | asset | 2 | no | debit | `0007:48` |
| `2000` | الالتزامات | liability | 1 | no | credit | `0007:49` |
| `2100` | الموردون والذمم الدائنة | liability | 2 | yes | credit | `0007:50` |
| `3000` | حقوق الملكية | equity | 1 | yes | credit | `0007:51` |
| `4000` | الإيرادات | revenue | 1 | yes | credit | `0007:52` |
| `5000` | تكلفة المبيعات | cogs | 1 | yes | debit | `0007:53` |
| `6000` | المصروفات | expense | 1 | yes | debit | `0007:54` |
| `6110` | مصروفات عمولات المندوبين | expense | 3 | yes | debit | `0009:18-24` |
| `126000` | عمولات الأطباء المستحقة الدفع | liability | 3 | yes | credit | `0011:17-23` |

**Observations that bear directly on any future mapping:**

1. **No customer-bonus liability account exists.** `2100` is explicitly scoped to suppliers/payables ("الموردون والذمم الدائنة"); `126000` is doctor commissions. No `2xxx` code refers to customer loyalty, rewards, or bonus.
2. **A purpose-specific liability sub-code is already an established pattern** — `126000` sits under the `2000` liability branch. That is evidence the chart is extensible; it is **not** evidence that any particular extension is decided.
3. **There is no bonus/loyalty code anywhere**, and no code between `1140` and `1200`.
4. **Only `1110`, `1120`, `1130`, `4000`, `6110` are written by any automated posting today** (`0009:118-122`, `0009:156-157`; `1110`/`1120`/`1130`/`6000` also by the simple-entry RPCs `0010:66-81,260-261`, `0012:80-81`; `126000` by the payout RPC `0011:174-178`).

### 5.3 The Account Mapping Matrix

For each accounting account: the bonus events that would touch it, and whether any code path writes it today.

| Account | Purpose in the existing design | Bonus event that would map here | Any bonus writer today? | Class |
|---|---|---|---|---|
| `1110` الصندوق | Cash on hand | **E4** cash withdrawal paid from the till | **No** — the only `1110` writers are the driver-commission trigger (`0009:157`) and the cash-side simple-entry RPCs (`0010:78-81,261`) | **BUSINESS POLICY REQUIRED** (whether cash settlement uses the till or the bank) |
| `1120` البنوك | Bank balances | **E4** withdrawal paid by transfer | **No** — written only by the bank-side simple-entry RPCs (`0010:73-76,261`) | **BUSINESS POLICY REQUIRED** |
| `1130` العملاء والذمم المدينة | Customer receivables | **E8** indirectly, via the invoice trigger | **Indirect only** — the invoice trigger debits it for the **netted** amount (`0009:118`); no bonus path names it | EXISTING (as invoice effect) / **BUSINESS POLICY REQUIRED** (gross-vs-net) |
| `1140` المخزون | Inventory at cost | **E6** redemption fulfilment; **E12** legacy Free-Y line | **No monetary writer at all** — the Free-Y movement is quantity-only (`0009:201-204`); `1140` is never named by any trigger | **TECHNICAL GAP + BUSINESS POLICY REQUIRED** (cost basis) |
| `1200` الأصول الثابتة | Fixed assets | — | No | Not applicable |
| `2100` الموردون والذمم الدائنة | Supplier payables | — (explicitly supplier-scoped) | No | Not applicable to bonus |
| `3000` حقوق الملكية | Equity | **E12** opening balance / legacy migration (value introduced without a counterparty) | **No** | **BUSINESS POLICY REQUIRED** (whether historical grants belong to equity or to an opening-balance path) |
| `4000` الإيرادات | Revenue | **E8** indirectly (credit side of the invoice) | **Indirect only** (`0009:119`) | EXISTING (as invoice effect) / **BUSINESS POLICY REQUIRED** (gross-vs-net) |
| `5000` تكلفة المبيعات | Cost of goods sold | **E6** redemption fulfilment (cost of goods given away) | **No** | **TECHNICAL GAP + BUSINESS POLICY REQUIRED** |
| `6000` المصروفات | Default expense bucket | possible for **E1/E2** if a grant is expensed immediately | `6000` is written by generic expense/disbursement RPCs (`0010:66-68,260`), never with a bonus source | **BUSINESS POLICY REQUIRED** |
| `6110` مصروفات عمولات المندوبين | Driver commission expense | — (explicitly driver-scoped) | Written by the commission trigger (`0009:156`), unrelated to bonus | Not applicable to bonus |
| `126000` عمولات الأطباء المستحقة الدفع | Accrued doctor commissions | — (explicitly doctor-scoped) | Written by the payout RPC (`0011:174`), unrelated to bonus | Not applicable to bonus |
| `1000`, `1100` | Asset headers (non-postable) | — | No (structural only) | Not applicable |
| **(no code exists)** | **Customer bonus / loyalty liability** | **E1, E2, E5, E7, E12** as credit side; **E4, E6, E9, E10, E11** as debit side | **No account and no writer exist** | **TECHNICAL GAP + BUSINESS POLICY REQUIRED** — the largest single omission in the mapping |
| **(no code exists)** | **Bonus expense / breakage** | **E11** (expiry write-back); **E1/E2** if recognised as expense | **No account and no writer exist** | **TECHNICAL GAP + BUSINESS POLICY REQUIRED** |

### 5.4 Why this matrix cannot be completed by engineering alone

The matrix has **15 accounting codes** and **2 missing account concepts**. Only two rows carry any bonus writer today (`1130`, `4000`), and those are produced by a trigger on `invoices` that has no knowledge of bonus. Moving any other row from blank to populated requires, simultaneously:

1. an account to be chosen or created on the accounting side (owner decision);
2. a decision on whether a grant is a liability, an expense, or nothing (owner decision);
3. the company-scope question of §4.2 to be settled (owner decision);
4. and only then a code change.

**No account code in this section is proposed, ranked, or selected.** The table lists what exists so that a decision conversation has a fixed vocabulary.

---

## 6. Source Traceability Matrix

### 6.1 What "traceability" means here

Three distinct questions are often conflated, and the answers differ:

- **T-A — subledger traceability.** Can I get from an operational row (order, withdrawal, redemption) to the ledger rows it caused? → **Yes, almost always, by FK.**
- **T-B — accounting traceability.** Can I get from a journal entry back to the bonus row that caused it? → **No, because no such journal entry exists.**
- **T-C — reconstruction traceability.** Given only the repository (not a backup), could an engineer rebuild the live schema including the accounting layer? → **No** — the two roots do not reproduce each other (§2.2).

### 6.2 Subledger traceability (T-A) — complete

Every link below is **EXISTING** and declared as a real constraint in the file cited.

| From | To | Mechanism | Declared at | Class |
|---|---|---|---|---|
| `orders` | `bonus_ledger` (earn) | `bonus_ledger.order_id` FK → `orders(id)` on delete set null | `0018:65` | EXISTING |
| `orders` | `bonus_ledger` (discount) | same FK, written by the discount RPC | `0020:249` | EXISTING |
| `bonus_ledger` | `bonus_ledger` (compensation) | `reverses_id` self-FK on delete set null + partial unique index | `0018:68,171` | EXISTING |
| `bonus_ledger` (debit) | `bonus_ledger` (funding credit lots) | `bonus_earn_allocations(credit_ledger_id, debit_ledger_id, amount)` | `0018:357-368` | EXISTING |
| `bonus_redemptions` | `bonus_ledger` | `bonus_redemptions.ledger_id` FK; reciprocal `bonus_ledger.redemption_id` | `0018:199`, `0018:67` | EXISTING |
| `bonus_withdrawals` | `bonus_ledger` | `bonus_withdrawals.ledger_id` FK; reciprocal `bonus_ledger.withdrawal_id` | `0018:230` area, `0018:66` | EXISTING |
| `bonus_rules_v2` | `bonus_ledger` | `bonus_ledger.rule_id` | `0018:69` | EXISTING (column) / NOT VERIFIED (FK constraint) |
| `order_cancellations` | `bonus_ledger` (reversal) | `reversal_ledger_id` FK RESTRICT | `0022:27` | EXISTING |
| `bonus_accounts` | `bonus_ledger` | `bonus_ledger.account_id` FK RESTRICT → `bonus_accounts(user_id)` | `0018:55-56` | EXISTING |
| `order_items` (`is_bonus`) | `financial_inventory_movements` | trigger, `reference_type='order_items'`, `reference_id=NEW.id` | `0009:201-204` | EXISTING (legacy Free-Y only) |

### 6.3 Accounting traceability (T-B) — absent

| Direction | Object that exists | Written with a bonus value? | Evidence | Class |
|---|---|---|---|---|
| `financial_documents.source_table` / `.source_id` | columns exist (nullable) | **No.** Only two writers exist in the entire system, both in `0009`: `'invoices'`/`NEW.id` (`0009:117`) and `'driver_commissions'`/`NEW.id` (`0009:154`) | grep of both roots this phase | **TECHNICAL GAP** |
| `financial_journal_entries.source_document_id` | column exists | **No bonus-linked row is created at all** | `0006:159`; zero bonus writers | **TECHNICAL GAP** |
| `financial_journal_entries.description` | free text | No repository code writes a bonus description; LIVE (carried, PHASE-46 §I.2) a live search for `bonus`/`بونص` returned 0 rows | carried | **TECHNICAL GAP** + BUSINESS POLICY REQUIRED (whether a bonus reference must appear on an entry) |
| `bonus_ledger` → any `financial_*` id | — | **No column exists in either direction** | read of `0018:53-75` | **TECHNICAL GAP** |
| any `financial_*` → `bonus_*` id | — | **No column exists in either direction** | read of the web-root financial DDL | **TECHNICAL GAP** |
| `bonus_withdrawals.payment_reference` | free-text string required by `mark_withdrawal_paid` (`0018:1258-1260`) | Populated on payment, but it is an operator-typed string, not a structured link to a bank/cash movement (none is created) | `0018:1244-1291` | EXISTING (field) / **TECHNICAL GAP** (link) |

### 6.4 Reconstruction traceability (T-C) — the repository-level defect that affects any accounting work

| Fact | Evidence | Consequence for accounting |
|---|---|---|
| The accounting DDL lives **only** in `Medlik-Waap/supabase/migrations/` | `ls` of both roots; only the web root contains `0006`–`0013` with `financial_*` tables | A root-only replay produces a database with **no accounting layer at all** |
| The bonus DDL lives **only** in `supabase/migrations/` | `ls` of both roots; only the root contains `0016`–`0023` | A web-only replay produces a database with **no bonus layer at all** |
| `0015` and `0016` exist in both roots with **different content** | PHASE-8 F6; `0015_product_images_storage.sql` and `0016_bonus_inventory_allocation_safety.sql` exist in both | Which variant is live is NOT VERIFIED (§2.3 N2) |
| A correct rebuild requires an interleaved 37-file order | PHASE-8 §5 | A new accounting migration written today lands in one root and cannot be validated by replay without that order |
| `supabase/.temp/project-ref` links the repo's `supabase/` directory to **production** | PHASE-8 finding; `supabase/.temp/` present | A `supabase db push` from that directory targets production — a procedural hazard for any future posting migration |

**This is the reason a posting design cannot be handed straight to an engineer: there is currently no database in which the result could be verified (PHASE-8).**

### 6.5 Traceability chain, end to end

```
order ──FK──► bonus_ledger (EARN) ──FK──► bonus_earn_allocations
   │                    │
   │                    └──reverses_id──► bonus_ledger (REVERSAL / EXPIRATION)
   │
   ├──FK──► bonus_ledger (ORDER_DISCOUNT) ──► invoice.amount (netted)   ← money-visible
   │                                              │
   │                                              └──trigger──► financial_journal_entries (1130 / 4000, draft)
   │
customer ──FK──► bonus_redemptions ──► bonus_ledger (REDEEM_PRODUCT)    ← no stock, no journal
customer ──FK──► bonus_withdrawals ──► bonus_ledger (CASH_WITHDRAWAL)   ← no cash movement, no journal
```

Everything above is traceable at the subledger level. The only edge reaching accounting is the **invoice** edge, and it carries no reference to the bonus row that reduced the amount.

---

## 7. Financial Impact Matrix

### 7.1 How impact is measured here

Impact is expressed **per unit of the event** (one order, one withdrawal, one redemption) in YER, because no aggregate volume could be read in this phase (§2.3 N6). Every row states separately:

- the **subledger effect** (always a real change to the derived balance),
- the **accounting effect that exists** (almost always none),
- the **accounting effect that is currently invisible** (the exposure).

### 7.2 Balance mechanics that every row depends on

`bonus_account_funds(user)` (`0018:393-431`) computes on every read:

```
available = Σ(amount : status='POSTED' and amount > 0)     -- credits
          − Σ(−amount : status='POSTED' and amount < 0)    -- posted debits
          − Σ(−amount : status='PENDING')                  -- reservations
```

There is no stored balance column (`0018:16-18`: "no mutable balance. Balance is ALWAYS derived"). Consequences for impact analysis:

| Property | Consequence |
|---|---|
| Append-only ledger; a `before update or delete` trigger refuses any change to a `POSTED` row (`0018:98-112`) | History cannot be rewritten; there is no "correct the balance" shortcut, only compensation |
| PENDING rows are deletable (the trigger permits it, `0018:103-105`) | Reservations can vanish without a compensating row — deliberate, and it means the reservation history is **not** an audit trail |
| No DB-level floor on the derived balance | PHASE-46 §L20 already recorded this as a defence-in-depth gap; the only guard is the RPC pre-checks |
| All ledger amounts are `numeric(12,2)` (`0018:62`) | Any accounting layer using `numeric(18,2)` (`0006:176-177`) would need an explicit rounding convention |

### 7.3 Impact per event

| Event | Subledger impact (per unit) | Accounting impact that exists | Accounting impact currently invisible | Class |
|---|---|---|---|---|
| **E1 Earn at delivery** | `available += earned`; `reserved` unchanged | **none** | The whole granted amount. Neither a liability nor an expense is recognised | **BUSINESS POLICY REQUIRED** |
| **E2 Director earn** | `available += amount` | **none** | The whole granted amount, posted by a human with no accounting trace of who authorised what value | **BUSINESS POLICY REQUIRED** |
| **E3 Withdrawal request** | `available −= amount`; `reserved += amount` | **none** | A movement between two derived figures, invisible to accounting; a request spanning a period close accrues nothing | **BUSINESS POLICY REQUIRED** |
| **E4 Withdrawal paid** | the `PENDING` row becomes `POSTED`, so the amount moves from the reserved bucket to the posted-debit bucket; the net derived balance is unchanged | **none — no cash or bank movement row, no journal** | **Cash leaving the business.** The accounting cash/bank balance is not reduced and the liability is extinguished with no contra entry — the largest unrecorded cash exposure in the bonus system | **TECHNICAL GAP + BUSINESS POLICY REQUIRED** |
| **E5 Redemption request** | `available −= value`; `reserved += value` | **none** | Same as E3, at the request level | **BUSINESS POLICY REQUIRED** |
| **E6 Redemption fulfilled** | the `PENDING` row becomes `POSTED`; the net derived balance is unchanged | **none — no stock movement, no COGS** | **Goods leaving inventory.** Physical stock and accounting inventory both understate the outflow; no cost figure exists at all, because the snapshot uses `products.unit_price` (`0018:831`), a sale price | **TECHNICAL GAP + BUSINESS POLICY REQUIRED** |
| **E7 Discount applied** | `available −= effective`; the debit becomes POSTED within the same transaction, so it settles as a posted debit rather than sitting reserved | **none at apply** | The bonus spent to reduce an order. It becomes visible only through E8's smaller invoice | **BUSINESS POLICY REQUIRED** |
| **E8 Invoice after discount** | (no ledger change) | **Yes** — a `draft` journal: debit `1130`, credit `4000`, amount = netted total (`0009:118-122`) | Whether the reduction was a bonus settlement or a commercial discount; the journal cannot distinguish them | EXISTING (posting) / **BUSINESS POLICY REQUIRED** (gross-vs-net) |
| **E9 Discount reversal** | `available += reversed` (the debit is compensated, freeing the funded lots) | **none** | Nothing was posted at apply, so nothing needs reversing; but the invoice created in E8, if any, keeps the netted amount (H2-A lock) and is never adjusted here | EXISTING (subledger) / **BUSINESS POLICY REQUIRED** (invoice staleness) |
| **E10 Manual reversal** | credit reversal: `available += reversed_amount`; debit reversal: the consumption is compensated in full | **none** | Value restored or removed with no accounting counterpart | **BUSINESS POLICY REQUIRED** |
| **E11 Expiration** | `available −= leftover` | **none** | A liability disappearing. No breakage or write-back is recorded anywhere | **BUSINESS POLICY REQUIRED** |
| **E12 Opening balance / legacy migration** | `available += amount` | **none** | Value created inside the bonus system from outside it, with a text reference as the only justification | **BUSINESS POLICY REQUIRED** |
| **E12b Legacy Free-Y order line** | (no ledger change — the wallet is not involved) | `financial_inventory_movements` row: type `'bonus'`, negative quantity, `unit_cost` = the product's `unit_price` (`0009:201-204`) | The monetary value of goods given away under the legacy scheme; the `unit_cost` stored is a sale price, not a cost | **TECHNICAL GAP** (valuation) + **BUSINESS POLICY REQUIRED** |

### 7.4 The three unrecorded exposures, stated plainly

| # | Exposure | Why it is unrecorded | Evidence |
|---|---|---|---|
| **X1** | **Cash paid out on withdrawals** | `mark_withdrawal_paid` writes a reference string and flips a ledger row; it creates no `financial_cash_movements` or `financial_bank_movements` row and no journal | `0018:1244-1291` |
| **X2** | **Inventory released on redemption fulfilment** | `fulfill_redemption` flips a ledger row and a status; it never touches `inventory` or `financial_inventory_movements` | `0018:908-948` |
| **X3** | **Outstanding bonus liability** | No account exists to hold it; the only record is the derived sum inside `bonus_ledger`, which no accounting report reads | `0007:38-59` (no such code); `0009`/`0010` (no such writer) |

**X3 makes X1 and X2 worse:** because the liability is invisible, a cash settlement or a stock release that fails to remove it produces no visible inconsistency in any accounting report. The error is detectable only by someone who reads the bonus ledger directly.

### 7.5 What this matrix does not claim

- It does **not** quantify exposure in YER: no volume could be read (NOT VERIFIED).
- It does **not** rank exposures by materiality: ranking requires volume.
- It does **not** state a valuation direction, because both were observed and neither is decided: `0018:831` uses `unit_price` for redemption valuation; `0009:197-198` uses `unit_price` as `unit_cost` for the legacy movement; no cost column is read anywhere.

---

## 8. Timing Matrix

### 8.1 The two clocks

| Clock | Where it exists | Precision available |
|---|---|---|
| **Operational clock** | `orders.created_at` (`0002:172`); `bonus_ledger.created_at` (`0018:74`, default `now()`); `bonus_audit_trail.at_time` (`0018:319`); withdrawal/redemption request, decision and payment timestamps (`0018:200-215,233-250`) | `timestamptz`, second-or-better |
| **Accounting clock** | `financial_journal_entries.entry_date` (`date`, `0006:156`); `period_id` → `financial_periods` (`0006:157`); fiscal year 2026 open (`0007:15-20`); 12 monthly periods (`0007:22-35`) | **one calendar day**, plus a period bucket |

**No column anywhere maps a `bonus_ledger` row to an accounting period.** Any future bridge would have to derive `entry_date` from something — the ledger `created_at`, a delivery moment, `paid_at`, or an expiry run's `p_asof` — and that choice is a policy decision, not a technical one.

### 8.2 Timing facts per event

| Event | Operational timestamp that exists | Candidate accounting date | Chosen? | Class |
|---|---|---|---|---|
| **E1 Earn at delivery** | `bonus_ledger.created_at` (written inside the delivery transaction). The order row carries **no delivery timestamp column** — `0002` defines only `created_at` (line 172); `scheduled_delivery_at` is set at allocation (`0021:340-343`) | ledger `created_at`; or the true delivery moment (would need a new column); or the order's period | **No** | **BUSINESS POLICY REQUIRED** + **TECHNICAL GAP** (no delivery timestamp column) |
| **E2 Director earn** | `bonus_ledger.created_at` | ledger `created_at` (day of the manual post) | **No** | **BUSINESS POLICY REQUIRED** |
| **E3 Withdrawal request** | `bonus_withdrawals.requested_at` (`0018:233`) | none — whether a request is an event at all is open (§4.3 E3) | **No** | **BUSINESS POLICY REQUIRED** |
| **E4 Withdrawal paid** | `bonus_withdrawals.paid_at` (`0018:1283-1284` writes `paid_at = now()`) | `paid_at` is the natural candidate — but using it requires the settlement leg to exist first (X1) | **No** | **BUSINESS POLICY REQUIRED** |
| **E5 Redemption request** | `bonus_redemptions.created_at`; `bonus_ledger.created_at` | none | **No** | **BUSINESS POLICY REQUIRED** |
| **E6 Redemption fulfilled** | the ledger flip is **not timestamped** — the `PENDING → POSTED` update writes only `status` (`0018:931-933`); `bonus_redemptions.updated_at` is refreshed (`0018:939-941`) | there is **no reliable fulfilment timestamp on the ledger row**; a bridge would have to rely on `updated_at` or `bonus_audit_trail.at_time` | **No** | **TECHNICAL GAP** (missing event timestamp) + **BUSINESS POLICY REQUIRED** |
| **E7 Discount applied** | `bonus_ledger.created_at`; the `notes` snapshot carries no timestamp (`0020:236-245`) | ledger `created_at` | **No** | **BUSINESS POLICY REQUIRED** |
| **E8 Invoice after discount** | `invoices.due_date`; `invoices.created_at` | **already chosen**: `coalesce(NEW.due_date, NEW.created_at::date)` (`0009:114`) | **Yes — existing** | EXISTING |
| **E9 Discount reversal** | `bonus_ledger.created_at` of the `REVERSAL` row; `order_cancellations` timestamps | day of cancellation | **No** | **BUSINESS POLICY REQUIRED** |
| **E10 Manual reversal** | `bonus_ledger.created_at` of the `REVERSAL` row | day of reversal | **No** | **BUSINESS POLICY REQUIRED** |
| **E11 Expiration** | the RPC receives `p_asof date` explicitly (`0018:1413`); the row's `created_at` is the run time | `p_asof` or the run time — these differ if a run is replayed for a past date | **No** | **BUSINESS POLICY REQUIRED** (which of the two) |
| **E12 Opening balance / legacy migration** | `bonus_ledger.created_at`; the operator supplies a free-text `reference` (`0018:620-624`) | day of posting | **No** | **BUSINESS POLICY REQUIRED** |

### 8.3 Period-boundary consequences

| Situation | Current behaviour | Accounting consequence | Class |
|---|---|---|---|
| A withdrawal is requested before a month end and paid after | The `PENDING` row spans the boundary; the paid state is written with `paid_at = now()` | No entry in either period, so nothing can be mis-dated — but nothing is captured either | **BUSINESS POLICY REQUIRED** |
| An earn arises from a delivery that spans a period close | The ledger row is written inside the delivery transaction with `created_at = now()` | No entry exists, so no cut-off error can occur today; the risk appears the moment postings are introduced | **BUSINESS POLICY REQUIRED** |
| A discount is applied to an order allocated in the following period | The ledger debit is POSTED in period 1; the invoice (and therefore the existing journal) is created in period 2 | **Today this produces a netted invoice in period 2 with no trace of the period-1 bonus movement** | **BUSINESS POLICY REQUIRED** |
| `expire_bonus` is run for a past `p_asof` | Rows are created with `reverses_id` and `created_at = now()`, not with `p_asof` | Backdated expiries are indistinguishable from current ones by timestamp | **TECHNICAL GAP** + **BUSINESS POLICY REQUIRED** |
| A period is closed | `post_financial_journal_entry` refuses to post into a closed period (`0010:333-339`) | Any future automatic posting must decide the closed-period behaviour (fail, park, or post into the next open period) | **BUSINESS POLICY REQUIRED** |

### 8.4 The reversal-timing property that would transfer unchanged

One timing property **is** already solved: every compensation row carries `reverses_id` and is written at the moment of the compensating act (`0018:1395`, `0021:134-138`, `0022:166-172`). An accounting mirror would therefore never need to "un-post" anything — it would post a compensating entry dated at the compensation. Recorded here as an **EXISTING** fact about the subledger, not as a recommendation.

---

## 9. Execution-status classification and verification status

### 9.1 Every object in the accounting boundary, classified

| Object | Class | Evidence |
|---|---|---|
| `bonus_ledger`, `bonus_accounts`, `bonus_earn_allocations`, `bonus_redemptions`, `bonus_withdrawals`, `bonus_settings`, `bonus_audit_trail`, `bonus_rules_v2` | **EXISTING** | `0018` full read |
| `bonus_pending_entitlements` | **EXISTING** | `0019:480-495` (hold write), `0019:518+` (processor) |
| `order_cancellations` with `reversal_ledger_id` | **EXISTING** | `0022:19-27` |
| Immutability trigger on `bonus_ledger` | **EXISTING** | `0018:98-112` |
| Reversal uniqueness (one compensation per original) | **EXISTING** | `0018:171` area, `0020:368-372`, `0021:145-152` |
| `financial_*` 27 tables (DDL) | **EXISTING in the web root only** | `Medlik-Waap/supabase/migrations/0006`–`0013` |
| `fn_financial_auto_entry` | **EXISTING** — invoice + driver-commission callers only | `0009:35,108,141` |
| `create_financial_journal_entry` / `post_financial_journal_entry` | **EXISTING** — manual, director-only | `0010:278,308` |
| Posted-entry and posted-line immutability | **EXISTING** | `0008:15-49` |
| `trg_financial_bonus_inventory` | **EXISTING** — legacy Free-Y quantity movement, not the financial wallet | `0009:184-220` |
| **Bonus → accounting posting (any event)** | **TECHNICAL GAP + BUSINESS POLICY REQUIRED** | §3, §4 |
| **Bonus liability account** | **TECHNICAL GAP + BUSINESS POLICY REQUIRED** | §5.2 |
| **Customer-bonus company scope** | **TECHNICAL GAP + BUSINESS POLICY REQUIRED** | §4.2 |
| **Redemption stock/COGS leg** | **TECHNICAL GAP** | `0018:908-948` |
| **Withdrawal cash/bank leg** | **TECHNICAL GAP** | `0018:1244-1291` |
| **Expiry scheduling** | **TECHNICAL GAP** | `0018` (no scheduler anywhere) |
| **`REFUND` / `ADJUSTMENT` writers** | **TECHNICAL GAP** | `0018:57-61` only |
| **Redemption `REJECTED` transition** | **TECHNICAL GAP** | `0018:198` vs the RPC set |
| **Reproducible schema (both roots)** | **TECHNICAL GAP** | §6.4; PHASE-8 |

### 9.2 What was verified in this phase, and how

| Verification | Method | Result |
|---|---|---|
| No bonus migration touches the accounting layer | per-file occurrence count of `financial_` across `0016`–`0023` | 0,0,0,0,0,0,0,1 (the 1 is a comment naming `0018`) |
| The set of ledger writers is closed | every `insert into public.bonus_ledger` enumerated and attributed | 11 writers, listed in §3.2 |
| Enum values with no writer | CHECK list vs writers | `REFUND`, `ADJUSTMENT` have no writer |
| The seeded account codes are exhaustive | every `insert into public.financial_accounts` read | 15 codes, listed in §5.2 |
| The invoice path is the only bonus-adjacent posting | read of both triggers in `0009` and of `0021:308-349` | confirmed; the trigger knows nothing of bonus |
| No `financial_` reference in bonus RPC bodies | full reads of `0018` RPCs, `0019`, `0020`, `0021`, `0022` | confirmed |
| Redemption fulfilment and withdrawal payment move nothing physical | full reads of both RPCs | confirmed |
| `accounting_treatment` does not exist in the repository | repo-wide grep, four file types | 0 matches (§2.4 C3) |

### 9.3 What was NOT verified (carried, not re-run)

| Item | Status |
|---|---|
| Live presence of tables/triggers/functions | **LIVE (carried)** from PHASE-46 §I.1 — not re-queried |
| Live journal content (0 bonus rows) | **LIVE (carried)** from PHASE-46 §I.2 — not re-queried |
| Live row counts of bonus tables | **carried** from PHASE-46 §C.4 / PHASE-47 §K.3 — not re-queried |
| Live variant of `0015`/`0016` | NOT VERIFIED (§2.3 N2) |
| Whether the DDL-less views include a posting path | NOT VERIFIED (§2.3 N5) |
| Runtime behaviour of any function | **not executed in this phase** — no SQL was run |

---

## 10. Business Policy Register — the 14 decisions that cannot be engineered

Each entry is a **question with its consequence**, never with an answer. IDs are new to this phase and are separate from PHASE-45's BD-01…BD-11 and PHASE-46's D4, which remain open and are cross-referenced rather than duplicated.

| ID | Decision required | Why it cannot be engineered | Blocks | Related open item |
|---|---|---|---|---|
| **ACC-01** | Is a granted bonus a **liability**, an **expense**, or **nothing** until redemption? | No code can choose the accounting nature of an obligation | every posting for E1, E2, E5, E7, E12 | **D4** (PHASE-46 §M) |
| **ACC-02** | At what **amount** is a liability recognised — the rule value, or the expected cost of the goods that will be redeemed? | The ledger stores the rule value (`0019:397`); catalogue cost is never read (`0018:831` reads `unit_price`) | E1, E2 | — |
| **ACC-03** | Is redemption **fulfilment** the cost-recognition point, and at which cost basis? | No cost column is read or written anywhere on the redemption path | E6; `1140`/`5000` mapping | — |
| **ACC-04** | Is a cash withdrawal a **liability settlement** or a **cash purchase of the obligation**? | Both are internally consistent; the ledger only removes value | E4; `1110`/`1120` mapping | **PAY** (PHASE-46 §M) |
| **ACC-05** | Which account and timing for the **cash leg** of a withdrawal? | `1110` vs `1120`, and locked vs cleared, are different meanings | E4; exposure X1 | **PAY** |
| **ACC-06** | Is the **discounted invoice** presented **net** (as today) or **gross with a separate bonus settlement**? | Changes revenue, receivables and the bonus liability simultaneously | E8, i.e. the only posting that exists today | **H2** (PHASE-46 §M) |
| **ACC-07** | What happens on **expiry** — write-back, breakage income, or nothing? | No writer of any kind exists | E11 | **L11** (PHASE-46 §L) |
| **ACC-08** | What **period** owns an event whose operational moments span a close? | Only a human can set cut-off policy | §8.3 | — |
| **ACC-09** | What should a posting do when the target **period is closed**? | Three defensible behaviours (fail / park / next open period); the existing poster fails (`0010:333-339`) | any future automatic posting | — |
| **ACC-10** | Which **company** owns a bonus event — and is the wallet single-company or shared? | The bonus side has no company column at all | **every row** in §4.3 (Q7) | **BD-01…BD-11** (PHASE-45) |
| **ACC-11** | Are entries posted **draft for review** or **posted immediately**? | Both exist today: the invoice path writes `draft` (`0009:77-78`), the simple-entry RPCs post immediately (`0010:263`); neither is the rule for bonus | any posting | — |
| **ACC-12** | Is a **bonus reference mandatory** on every entry (source-traceability requirement)? | Determines whether §6.3's gap is a defect or an accepted limitation | §6.3 | — |
| **ACC-13** | Is the **historical** legacy Free-Y exposure to be recognised, and if so at what vintage? | The mechanism exists (`0016`/`0017`); the valuation does not | E12b | **LEGACY-MIG** (PHASE-46 §M) |
| **ACC-14** | Who is the **named accounting owner** who signs off ACC-01…ACC-13? | No owner is recorded in any report | the whole gate | **FIN-OWNER** (PHASE-46 §M) |

**No answer is supplied, implied, or ranked for any of the 14.** The register exists so that the questions can be answered once, in one place, instead of being improvised per migration.

---

## 11. Decision option space (alternatives enumerated, none selected)

Where more than one internally consistent approach exists, the options are listed so the owner can identify what is being chosen. **No option is marked preferred and no option is excluded.**

### 11.1 Where the posting is triggered

| Option | Shape | Consequence to note |
|---|---|---|
| **T-1** | Trigger on `bonus_ledger` insert — one hook covers every event, present and future | Fires inside the same transaction as the RPC; a posting failure would roll back the bonus operation unless the failure is caught and logged (the pattern `0009:125-128` already uses) |
| **T-2** | An explicit call added to each RPC as its last statement | Maximum control per event; eleven call sites to maintain; a writer added later could silently omit the call |
| **T-3** | Periodic sweep — a scheduled job reads unposted ledger rows and posts a batch | Decouples accounting from operations; introduces lag and needs a "posted" marker that does not exist today |

### 11.2 Where the source reference lives

| Option | Shape | Consequence to note |
|---|---|---|
| **R-1** | Reuse `financial_documents.source_table='bonus_ledger'` + `source_id` (columns already exist, `0006:144-145`) | No schema change; the columns are already polymorphic (`'invoices'`, `'driver_commissions'`) |
| **R-2** | Add a dedicated nullable column on `financial_journal_entries` | Cleaner join; a schema change to an accounting table |
| **R-3** | Add a nullable column on `bonus_ledger` pointing at the journal | Inverts direction; the ledger is immutable for POSTED rows (`0018:98-112`), so any later back-fill would be blocked |

### 11.3 Posting state model

| Option | Shape | Consequence to note |
|---|---|---|
| **S-1** | `draft`, human posts later — matches the existing invoice path (`0009:77-78`) | Requires a human step; unreviewed drafts could accumulate silently |
| **S-2** | Post immediately inside the transaction — matches the simple-entry RPCs (`0010:263`) | No manual step; posted entries are immutable (`0008:29-44`), so corrections require compensating entries |
| **S-3** | Post immediately for a defined subset of events only | Splits the model; the subset rule is itself a policy choice |

### 11.4 Company resolution (only reachable after ACC-10)

| Option | Shape | Consequence to note |
|---|---|---|
| **C-1** | Add a company column to the bonus tables | Schema change across 8+ tables and every RPC; makes the wallet company-aware |
| **C-2** | Map by branch → company at posting time | Requires a branch→company mapping that does not exist, and bonus events are not all branch-scoped (withdrawal and expiry are customer-scoped) |
| **C-3** | Single-company assumption, resolved as the existing helper does (`order by created_at limit 1`, `0009:57-60`) | Works only while exactly one company row exists; would silently mis-scope the day a second is added |

### 11.5 Valuation basis

| Option | Shape | What the code already does (evidence, not endorsement) |
|---|---|---|
| **V-1** | Bonus value = catalogue sale price | `request_redemption` stores `unit_price × quantity` (`0018:831`); the legacy movement stores `unit_price` as `unit_cost` (`0009:197-198`) |
| **V-2** | Bonus value = product cost | No cost column is read by any bonus path; needs a cost source and a rule for products without one |
| **V-3** | Bonus value = rule-declared value, independent of the catalogue | Rules carry `bonus_value` / `bonus_percent` (`0019:353-375`); this is how E1 is computed today, and it does not by itself reconcile to any redemption price |

### 11.6 What is deliberately absent from this section

- No cost estimates, no migration identifiers, no proposed table names, no account numbers, no trigger names.
- No sequencing recommendation: §12 lists **constraints** (what cannot precede what), not a plan.

---

## 12. Dependency constraints (ordering rules, not a plan)

These are **hard constraints** derived from the evidence. They are not a schedule and carry no estimate.

| # | Constraint | Why it is hard | Evidence |
|---|---|---|---|
| **DC-1** | **ACC-10 (company scope) before any posting rule can be finalised** | Journals require `company_id NOT NULL`; bonus rows have no company at all | `0006:154` vs `0018:22-75` |
| **DC-2** | **ACC-01/ACC-02 (liability vs expense, and amount) before any posting for E1/E2** | The nature and value of the obligation determine every line of the entry | §4.3 |
| **DC-3** | **ACC-06 before the E8 posting can be considered correct** | Today's invoice journal is net by construction; whether that is right *is* ACC-06 | `0021:308-338`, `0009:118-122` |
| **DC-4** | **ACC-04/ACC-05 before the withdrawal settlement leg (X1) can be built** | The leg's accounts and timing are the policy; plumbing alone would invent them | `0018:1244-1291` |
| **DC-5** | **ACC-03 before the redemption cost leg (X2) can be built** | Cost basis and recognition point are the policy | `0018:908-948` |
| **DC-6** | **Reproducible schema (PHASE-8) before any new posting migration is authored** | The repo cannot reproduce the live schema, so a new migration cannot be replayed or validated | §6.4; PHASE-8 §5 |
| **DC-7** | **An isolated database (PHASE-8 Option C/D approval) before any posting behaviour is tested** | The bonus ledger is immutable for POSTED rows (`0018:98-112`), so test data cannot be cleaned up — only discarded with the database | `0018:98-112`; PHASE-8 §7 |
| **DC-8** | **`0023` (the rule-contract fix) before any earn behaviour is trusted or measured** | The live earn engine reads a non-existent column, so every earn outcome today is unreliable | PHASE-46 §E.4; PHASE-47 §K.4 |
| **DC-9** | **A procedural guard against `supabase db push` from the linked `supabase/` directory** | That directory is linked to production | PHASE-8 step 0 |
| **DC-10** | **ACC-14 (named owner) before the §10 register can be closed** | The register is answered by a person, and no owner is recorded anywhere | PHASE-46 §M |

**Note the shape of this list:** eight of the ten constraints terminate in a **human decision**, and two terminate in the **environment work of PHASE-8**. None terminates in "write more code".

---

## 13. Owner decision gate — what must be answered before any execution phase

### 13.1 The gate is closed today

| Gate item | Status | Source |
|---|---|---|
| Accounting policy for bonus (D4) | **NOT DECIDED** | PHASE-41 §O; PHASE-46 §M |
| Company model / ownership anchoring (BD-01…BD-11) | **NOT DECIDED** | PHASE-45 §S |
| Named accounting owner (FIN-OWNER) | **NOT RECORDED** | PHASE-46 §M |
| Cancellation reason taxonomy (BD-2) | **NOT DECIDED** | PHASE-46 §M |
| Invoice↔order linkage and cancellation effect (H2) | **NOT DECIDED** (H2-A locked: manual invoices stay independent) | PHASE-46 §M |
| Payment model (PAY) | **NOT DECIDED** | PHASE-46 §M |
| Test environment (PHASE-8 Option C/D + four approvals) | **NOT APPROVED** | PHASE-8 §11 |

### 13.2 The decisions this document adds

This phase adds **ACC-01 … ACC-14** (§10). Ordered by how much surface each answer unblocks (not by importance):

| Order | IDs | Unblocks |
|---|---|---|
| 1 | **ACC-10** | every posting (via DC-1) |
| 2 | **ACC-01, ACC-02** | earn-related postings — the highest-volume event |
| 3 | **ACC-03, ACC-04, ACC-05** | the two physical/settlement legs (X1, X2) |
| 4 | **ACC-06** | whether the one posting that exists today is correct |
| 5 | **ACC-07, ACC-08, ACC-09, ACC-11, ACC-12, ACC-13** | expiry, cut-off, closed periods, draft-vs-posted, traceability, legacy |
| — | **ACC-14** | closes the register |

### 13.3 What follows the gate (stated as constraints only)

Once ACC-14 names an owner and ACC-10 plus at least ACC-01/ACC-02 are answered, the remaining work decomposes as: (a) a **design document** (not written here) turning the answers into posting rules; (b) the **environment** work of PHASE-8, a prerequisite for verification (DC-6, DC-7); (c) implementation, in a separately authorised phase. **None of (a), (b) or (c) is started, scoped, estimated, or scheduled by this document.**

### 13.4 Explicit non-actions of PHASE 49

| Not done | Confirmation |
|---|---|
| No accounting policy selected | §10, §11 — no option marked preferred anywhere in this document |
| No account code proposed or created | §5 |
| No migration authored, edited, or applied | No file under either `supabase/migrations/` was touched |
| No SQL write executed | No database statement of any kind was executed in this phase |
| No application file modified | Flutter and PWA sources were read only |
| No commit, push, or deploy | See the footer |
| PHASE-8's deferred cloud steps untouched | No `supabase login`, no project/branch creation, no dump, no `.temp/` change |

---

## 14. Evidence index

### 14.1 Files read in this phase

**Bonus chain (root):** `supabase/migrations/0018_bonus_financial_system.sql` (1-52, 53-112, 303-320, 380-1000, 1000-1500, plus targeted 475-547, 548-700, 740-793, 793-908, 1244-1332, 1332-1412, 1413-1507) · `0019_bonus_earn_engine.sql` (88-530, 340-410) · `0020_order_discount.sql` (40-50, 130-200, 236-300) · `0021_order_cancellation_with_discount.sql` (1-60, 300-356) · `0022_order_cancellation_history.sql` (targeted) · `0023_bonus_rule_max_earn_contract_fix.sql` (targeted) · `0002_catalog_inventory_orders.sql` (targeted) · `0003_bonus_commission_approval_notifications.sql` (targeted)

**Accounting chain (web root):** `Medlik-Waap/supabase/migrations/0006_financial_core.sql` (full) · `0007_financial_setup_rls.sql` (full) · `0008_financial_audit_immutability.sql` (full) · `0009_financial_auto_posting.sql` (full) · `0010_financial_simple_entries.sql` (full) · `0011_financial_doctors_payouts.sql` (targeted) · `0012_financial_receipts_columns.sql` (targeted) · `Medlik-Waap/supabase/financial_installer.sql` (targeted)

**Clients:** `Medlik-Waap/artifacts/pharma-pwa/src/lib/bonusFinancialApi.ts` (RPC inventory) · `Medlik-Waap/artifacts/pharma-pwa/src/pages/director/BonusFinancialDashboardPage.tsx` (targeted) · `medlink_app/lib/services/bonus_wallet_service.dart` (RPC inventory)

**Reports:** `docs/opencode/PHASE-41-FINANCIAL-ARCHITECTURE-AUDIT.md` (full) · `PHASE-46-BONUS-CURRENT-STATE-AUDIT.md` (§A, §D, §I, §J, §L, §M, §N) · `PHASE-47-BONUS-RULE-CONTRACT-FIX-DESIGN.md` (§K) · `PHASE-45-COMPANY-ARCHITECTURE-DECISION-ANALYSIS.md` (§R, §S) · `PHASE-8-TEST-ENVIRONMENT-ARCHITECTURE.md` (§10-12) · `docs/REWARDS_SYSTEM_MASTER_STATUS.md`

### 14.2 Measurements taken in this phase

| Measurement | Method | Result |
|---|---|---|
| `financial_` occurrences per bonus migration | per-file grep count over `0016`–`0023` | 0,0,0,0,0,0,0,1 |
| Ledger writers | grep for `insert into public.bonus_ledger` with context | 11 writers (§3.2) |
| Account seeds | grep for `insert into public.financial_accounts` in the web root | 3 seeding statements, 15 codes (§5.2) |
| `accounting_treatment` | repo-wide grep across `*.sql`/`*.ts`/`*.tsx`/`*.dart` | **0 matches** (§2.4 C3) |
| `REFUND`/`ADJUSTMENT` writers | grep across root migrations | constraint + comment only (§4.5) |
| Auto-posting callers | read of `0009` triggers + `0010` RPCs | invoices, driver commissions, manual entries — no bonus |
| Migration inventory | `ls -la` of both migration roots | 23 files (root), 16 files (web) |
| Working-tree state | `git status --short` | only untracked PHASE-46/47/8/49 docs, `0023`, `REWARDS_SYSTEM_MASTER_STATUS.md`, and the pre-existing `Medlik-Waap` entry |

### 14.3 Inherited live evidence (quoted, not re-derived)

| Fact | Origin |
|---|---|
| 27 `financial_*` tables present live; DDL only in the web root; 3 objects with no DDL anywhere | PHASE-46 §I.1 |
| 0 journal rows referencing bonus; `financial_documents.source_table/source_id` never written with a bonus value | PHASE-46 §I.2 |
| Bonus tables carry no company column; 1 company row live | PHASE-46 §I.3; PHASE-45 §R |
| Earn-engine defect (`max_bonus` vs `max_earn`) live in `pg_proc`; 0 rows in the bonus tables at audit time | PHASE-46 §E.4; PHASE-47 §K.3 |
| Repo `supabase/` linked to production; no root `config.toml`; no `seed.sql`; CLI unauthenticated; Docker absent | PHASE-8 §3-§4 |
| Test-environment cost measurement (branch 0.01344 USD/h) | PHASE-8 §R7 |

### 14.4 Open evidence gaps for a later phase

| # | Gap | How it could be closed | Needed by |
|---|---|---|---|
| E-1 | Which `0016` variant is live | production schema dump (PHASE-8 step 3) | DC-6 |
| E-2 | Whether the DDL-less objects include a posting path | live `pg_get_viewdef` / `pg_proc.prosrc` read | §4 completeness |
| E-3 | Live volume per event type | read-only counts per event | materiality ranking (§7.5) |
| E-4 | Whether `bonus_settings.expiry_policy` has ever been configured live | read-only select on `bonus_settings` | §3.13 |
| E-5 | Whether any live invoice journal covers a discounted order | read-only join `invoices` ↔ `financial_documents` | §3.10 |

**None of E-1…E-5 was attempted in this phase: they require production reads, which PHASE-49 did not perform.**

### 14.5 Verification of this document itself

| Check | Result |
|---|---|
| All cited `file:line` references resolve to the claim made | Verified by re-reading each cited region during authoring; three predecessor citations were corrected (§2.4 C2, C3) |
| No preference language applied **to a decision** | Section-wide scan for "best", "recommend(ed/ation)", "should", "preferred", "optimal": 9 hits, all accounted for — 4 are the self-imposed prohibition or its restatement (§0.2, §11, §13.4, this row); 1 is a neutral field-heading ("Open evidence gaps for a later phase"); 2 are negations ("no option is marked preferred", "not as a recommendation"); 2 are inside the text of a *question* being asked of the owner (§3.10, §10 ACC-09), which is the intended interrogative form, not a directive. **No directive or ranking language is applied to any accounting choice.** |
| No account code proposed | §5 lists only codes that exist in the repository |
| No migration, schema, or code change | §13.4; confirmed by `git status --short` and `git diff --stat` (no working-tree modification) |

---

PHASE 49 COMPLETE — BONUS ACCOUNTING DECISION MATRIX
READ-ONLY ACCOUNTING ANALYSIS
NO APPLICATION FILES MODIFIED
NO DATABASE CHANGES
NO SQL WRITE
NO MIGRATION CREATED
NO MIGRATION MODIFIED
NO COMMIT
NO PUSH
NO DEPLOY
NO BONUS → GL IMPLEMENTATION
ACCOUNTING POLICY NOT DECIDED
ACCOUNT CODES NOT SELECTED
BUSINESS DECISIONS NOT MADE
WAITING FOR OWNER REVIEW OF ACC-01 … ACC-14