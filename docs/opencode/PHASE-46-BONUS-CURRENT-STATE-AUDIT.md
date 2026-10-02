# PHASE 46 — BONUS CURRENT STATE AUDIT (Phase 0, read-only)

> **Scope:** READ-ONLY investigation + implementation roadmap. No application file, migration, or database state was changed.
> **Audit date:** 2026-09-29
> **Repository audited (local working tree):** `/home/adman/stitch_medlink_yemen` (main, HEAD `8e30112`) **and** its git submodule `Medlik-Waap` (HEAD `5c0314f`).
> **Live database:** Supabase project `lmkomzqioneuyvatzsov` — inspected **read-only** through catalog `SELECT` queries only (`information_schema`, `pg_proc`, `pg_trigger`, `pg_policies`, `pg_indexes`, `pg_attribute`, `pg_constraint`, plus `count(*)` on bonus/finance tables).
> **Method note:** "VERIFIED LIVE IN THIS AUDIT" means a catalog/read query was actually executed against `lmkomzqioneuyvatzsov` during this task. Anything not proven that way is marked accordingly and never upgraded by inference.

---

## A. Executive Summary

### A.1 What is actually built (code evidence + live catalog evidence)

1. **A complete, well-guarded financial Bonus subledger exists** in the main repository migrations `0018`–`0022` and is **present in the live database** (10 `bonus_*` tables + `order_cancellations`, 34 `SECURITY DEFINER` RPCs, 3 integrity triggers, 23 RLS policies, 3 uniqueness/index guarantees). Balance is **derived only** — `bonus_accounts` has no amount column (live-verified); `bonus_account_funds` sums POSTED/PENDING rows.
2. **Bonus earning is wired end-to-end** at delivery: `trg_bonus_on_order_delivered` → `bonus_evaluate_order_earn` → `bonus_ledger` EARN (live trigger definition verified), with a snapshot pending-entitlements fallback (`bonus_pending_entitlements`, `bonus_process_pending`).
3. **Order discount is fully implemented** server-side (`0020 apply_order_discount` / `cancel_order_discount`) and is reflected in the invoice total inside the live `branch_allocate_order` body (verified: the live body contains the `v_discount` net-delta that exists only in the `0021` revision).
4. **Order cancellation is atomic + financially safe**: the live `cancel_order_with_discount` contains the client pending-state gate, the snapshot-governed compensating REVERSAL, and the `order_cancellations` history insert (verified by body markers).
5. **Both apps call these RPCs**: Flutter (`BonusWalletService`, `OrderService`, `BranchService`) and the director PWA (`bonusFinancialApi.ts`), with idempotency keys minted and retained across retries in `BonusWalletController` / `OrderController` / `BranchController`.
6. **Ledger immutability is enforced live**: `trg_bonus_ledger_immutable` BEFORE UPDATE/DELETE raising on POSTED rows; no INSERT/UPDATE/DELETE policy exists for any role on any bonus table.
7. **PostgreSQL-level idempotency exists live**: `bonus_ledger_idempotency_key_key` (UNIQUE) and partial unique index `bonus_ledger_reverses_uniq` (one compensation per original).

### A.2 What is NOT built (proven by exhaustive negative search)

- **Zero Bonus → General Ledger linkage at any layer.** No FK, no RPC cross-call, no `source_type`/`source_id` value, no UI reference. Live query on `financial_documents`/`financial_journal_entries` for bonus references → 0 rows; repository grep for bonus inside the financial module → 0 matches.
- **No order-edit / partial-change / product-removal path** → therefore no discount recalculation and no "excess bonus return" path for edited orders.
- **No waiting-order state.** Live `orders_status_check` = `pending|assigned|in_progress|delivered|cancelled` only. No reactivation, no client confirmation, no availability notification, no reservation table.
- **No cross-branch inventory search, no substitute-product workflow, no availability notification templates, no push channel.**
- **No live-behavioural test of any Bonus invariant.** The entire test suite is offline fakes (`flutter test` → 39/39, run in this audit).
- **No `max_bonus` column exists** while the live earn engine reads `max_bonus` → a proven runtime defect (§E.4).

### A.3 Classification legend

| Class | Meaning |
|---|---|
| EXISTING | Found in current code **or** live catalog with a citable path/name. |
| IMPLEMENTED BUT UNVERIFIED | Code exists; behaviour never executed in this audit. |
| REQUIRES LIVE VERIFICATION | Cannot be proven read-only (needs a write or a user session). |
| VERIFIED LIVE IN THIS AUDIT | Catalog/read `SELECT` executed in this task. |
| CONFLICT | Code/live/report disagree; documented, not fixed. |
| TECHNICAL GAP | Function absent or incomplete, proven by search. |
| BUSINESS POLICY REQUIRED | Owner decision not found in code or docs. |
| UNKNOWN | Insufficient evidence. |

**Headline finding:** the subledger mechanics are strong and live; the accounting layer is entirely absent; and the earn engine carries a **column-name defect (`max_bonus` vs `max_earn`)** proven in the live database that will abort rule validation and delivery-trigger evaluation at runtime.

---

## B. Repository and Evidence Inventory

### B.1 Repository topology (local files)

| Path | Role | Evidence |
|---|---|---|
| `/home/adman/stitch_medlink_yemen/` | Main repo, git `main`, HEAD `8e30112` | `git log`, `git ls-files` |
| `supabase/migrations/0001…0022` | Canonical DB history (22 files) | `ls supabase/migrations` |
| `medlink_app/` | Flutter client (Android/iOS/Web/Windows/Linux/macOS) | `pubspec.yaml`, `lib/**.dart` |
| `medlink_app/test/` | 6 Dart test files | `ls medlink_app/test` |
| `Medlik-Waap/` | **Git submodule** (`160000 5c0314f`) — director PWA + its own migration chain | `git ls-files -s Medlik-Waap` |
| `Medlik-Waap/artifacts/pharma-pwa/src` | React/TS director PWA (123 files) | file listing |
| `Medlik-Waap/supabase/migrations/0001…0016` | **Second, different** migration chain targeting the same DB | `ls`, `diff` (§C.3) |
| `docs/opencode/` | 60+ phase reports (PHASE-4.3 … PHASE-45) | `ls docs/opencode` |
| `docs/REWARDS_SYSTEM_MASTER_STATUS.md` | Untracked prior audit (dated 2026-09-28) | `git status` shows `??` |
| `AGENTS.md`, `README.md` | Project instructions (**at main-repo root only**; absent in the submodule) | file read |
| `.opencode/skills/`, `.opencode/agents/` | 12 skills, 5 subagents (supabase-specialist, medlink-architect, …) | `find .opencode` |

**Scope correction:** the task described one repository. In fact the Bonus system lives in the **main repo** (migrations 0016–0022 + Flutter) while the director PWA lives in the **submodule**, which carries an *incompatible duplicate* of migration `0016`. Both were audited.

### B.2 Prior reports reviewed (all in `docs/opencode/`)

| Report | Used for | Agreement with current code/live |
|---|---|---|
| `PHASE-34-LIVE-VERIFICATION-0022.md` | 0022 live confirmation | Consistent (table + RPC still present) |
| `PHASE-35-POST-0022-STATE-AUDIT.md` | Cancel RPC unwired at that time | **Superseded** — client + branch now call it (§G) |
| `PHASE-36/37/38/39` | Cancel design, then wiring | Consistent with current Flutter code |
| `PHASE-40-POST-CANCELLATION-STATE-AUDIT.md` | "zero financial objects" | **CONFLICT** — 27 `financial_*` tables are live (re-verified this audit) |
| `PHASE-41-FINANCIAL-ARCHITECTURE-AUDIT.md` | GL absent; company-scoped journals | Consistent (re-verified) |
| `PHASE-42-COMPANY-IDENTITY-AUDIT.md` | No company identity in operational tables | Consistent |
| `PHASE-43/44/45` | Company architecture decision set | Consistent; BD-01..11 still undecided |
| `PHASE-16.x / 17 / 18 / 21` | Discount policy locks D1–D8 | Consistent with `0020` code and the live `bonus_settings` rows |
| `docs/REWARDS_SYSTEM_MASTER_STATUS.md` | Broad prior status | Mostly consistent; its "29 tests" figure is superseded — **39 pass today** |
| `ACCOUNTING AUDIT COMPLETE`, `BONUS ACCOUNTING INTEGRATION ANALYSIS COMPLETE` | — | **NOT FOUND** anywhere in the repository (grep over all `*.md` = 0 hits) |

**Rule applied:** no prior report was accepted as proof. Every claim below was re-derived from the current tree or re-queried live.

---

## C. Migration and Database Object Inventory

### C.1 Main-repo migrations (the authoritative Bonus history)

| Migration | Purpose | Objects created/changed | Related Bonus operations | Dependencies | Local evidence | Live status |
|---|---|---|---|---|---|---|
| `0001_initial_schema` | users/branches/roles + helper fns | `branches`, `users`, `current_user_role()`, `current_user_branch_id()` | all (authorization backbone) | — | file head | EXISTS LOCALLY + objects live |
| `0002_catalog_inventory_orders` | catalog/orders/items/inventory | `products`, `inventory`, `orders` (status CHECK), `order_items` | legacy Free-Y + earn inputs | 0001 | `0002:126,165` | EXISTS LOCALLY + live (status CHECK re-verified) |
| `0003_bonus_commission_approval_notifications` | **legacy Buy-X-Free-Y root** | `bonus_rules`, `notifications`, `driver_commissions` | BONUS PRODUCT REDEMPTION (legacy) | 0001/0002 | `0003:5,78` | EXISTS LOCALLY + table live |
| `0004…0015` | access/RLS/chat/settings/inventory batches/addresses/images | branches, settings, addresses, images | infra | prior | files | EXISTS LOCALLY |
| `0016_bonus_inventory_allocation_safety` | rewrite `branch_allocate_order`: full physical demand incl. free units; invoice = paid units only | `branch_allocate_order` | INVENTORY + INVOICE at allocation | 0009/0017 | `0016:13-156` | EXISTS LOCALLY; **superseded in body by 0021** (live body has the discount delta) |
| `0017_bonus_order_integrity_and_analytics` | server-side order creation + distribution analytics | `order_items.bonus_rule_id`, `order_items_bonus_price_check`, **`create_order_with_items`**, `get_order_product_distribution`; drops direct-insert policies | ORDER CREATION, legacy bonus validation | 0016 | `0017:11,28,247` | EXISTS LOCALLY + functions live |
| `0018_bonus_financial_system` | **the subledger core** | `bonus_accounts`, `bonus_ledger`, `bonus_rules_v2`, `bonus_redemptions`, `bonus_withdrawals`, `bonus_settings`, `bonus_audit_trail`, `bonus_earn_allocations`; 16 RPCs; immutability trigger; `bonus_ledger_reverses_uniq` | EARN, REDEEM, WITHDRAW, REVERSAL, EXPIRATION, OPENING_BALANCE, LEGACY_MIGRATION | 0017 | `0018:22,53,118,189,225,285,313,357,393…1507` | EXISTS LOCALLY + **all 8 tables, trigger, index and RPCs VERIFIED LIVE** |
| `0019_bonus_earn_engine` | sales earn at delivery | `bonus_pending_entitlements`, `bonus_check_rule_v2`, `bonus_validate_rule_v2`, `bonus_rules_v2_validate_trigger`, `bonus_evaluate_order_earn`, `bonus_on_order_delivered` + trigger, `bonus_process_pending`; alters `bonus_accounts.mode`, `bonus_rules_v2.value_basis/product_values` | BONUS EARN | 0018 | `0019:47,88,198,220,463,518` | EXISTS LOCALLY + **all 6 functions + trigger VERIFIED LIVE**; carries the `max_bonus` defect (§E.4) |
| `0020_order_discount` | order discount engine | `apply_order_discount`, `cancel_order_discount`; 6 `discount.*` settings seeds | BONUS ORDER DISCOUNT | 0018/0019 | `0020:43,56,311` | EXISTS LOCALLY + functions live + settings rows live |
| `0021_order_cancellation_with_discount` | atomic cancel + discount-aware allocate | `cancel_order_with_discount` (new), `bonus_ledger_order_idx`, `branch_allocate_order` (OR REPLACE with discount delta) | ORDER CANCELLATION, INVOICE | 0020 | `0021:26,34,181` | EXISTS LOCALLY + **live allocate body contains the delta (VERIFIED)** |
| `0022_order_cancellation_history` | cancellation event history | `order_cancellations` + 3 SELECT policies; `cancel_order_with_discount` (OR REPLACE, + history insert) | ORDER CANCELLATION history | 0021 | `0022:17,64,211` | EXISTS LOCALLY + **table and history insert VERIFIED LIVE** |

### C.2 Live-only database objects (no creating migration in the main repo)

| Object group | Count | Evidence | Status |
|---|---|---|---|
| `financial_*` tables | 27 (incl. `financial_companies`, `financial_journal_entries`, `financial_journal_lines`, `financial_general_ledger`, `financial_trial_balance`, `financial_branch_profitability`, `financial_inventory_movements`) | `information_schema.tables` query | **EXISTS IN LIVE DB.** DDL exists only in the *submodule* (`Medlik-Waap/supabase/migrations/0006–0013`). `financial_general_ledger`, `financial_trial_balance`, `financial_branch_profitability` have **no DDL anywhere in either repo** → provenance gap |
| `create_financial_journal_entry`, `post_financial_journal_entry` | 2 | `pg_proc` query | VERIFIED LIVE; bodies contain no bonus reference |
| `trg_financial_bonus_inventory`, `fn_financial_auto_entry`, `trg_financial_invoice_auto_journal`, `trg_financial_commission_auto_journal(_update)` | 4 triggers / 3 functions | `pg_trigger` + `pg_proc` | VERIFIED LIVE; source is **submodule `0009_financial_auto_posting.sql`**, not the main repo |

### C.3 CONFLICT — two incompatible copies of migration 0016

- `supabase/migrations/0016_bonus_inventory_allocation_safety.sql` (5,825 bytes) — contains the "Full physical allocation required" gate and the `v_allocated_any` check.
- `Medlik-Waap/supabase/migrations/0016_bonus_inventory_allocation_safety.sql` (3,505 bytes) — **lacks** that gate (`grep -c "Full physical allocation required"` = 0) while its header claims it is "intentionally identical" to the sibling file. It is not.
- The live `branch_allocate_order` **does** contain the full-demand gate **and** the 0021 discount delta ⇒ the live body follows the **main-repo** lineage, not the submodule copy.
- **Consequence:** replaying the submodule chain would silently weaken inventory safety. Documentation/provenance defect — **not fixed in this phase**.

### C.4 Live inventory of data (read-only counts executed this audit)

| Table | Rows | Note |
|---|---|---|
| `bonus_ledger` | 0 | no financial history at all |
| `bonus_accounts` | 0 | |
| `bonus_rules_v2` | 0 | |
| `bonus_rules` (legacy) | 0 | |
| `bonus_redemptions` / `bonus_withdrawals` / `bonus_earn_allocations` / `bonus_pending_entitlements` / `bonus_audit_trail` | 0 / 0 / 0 / 0 / 0 | |
| `order_cancellations` | 0 | |
| `orders` / `order_items` | 2 / 2 | the only non-financial data present |
| `invoices` | 0 | |
| `financial_journal_entries` / `financial_general_ledger` | 0 / 0 | no GL activity |
| `bonus_settings` | 10 | the only populated bonus table |

**Consequence for the whole audit:** the live database holds **zero** Bonus transactions. Every behavioural statement about earn / discount / cancel / reversal is therefore code-level only; none can be corroborated by live data.

---

## D. Bonus Operations Matrix

Path key: **UI → Controller → Service → Repository → RPC → Source table → Ledger → Order/Invoice/Inventory → GL**

| # | Operation | UI entry | Controller | Service | RPC / Function | Ledger event | Inventory | GL | Tests | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **BONUS EARN** | none (automatic) | — trigger-driven | — | `bonus_evaluate_order_earn` (0019:220) ← `bonus_on_order_delivered` (463) ← `trg_bonus_on_order_delivered` | `EARN` POSTED, key `SALES_EARN:{order}:{rule}` | none | none | key-gen only | **IMPLEMENTED BUT INCOMPLETE** — live `max_bonus` defect (§E.4); zero behavioural tests |
| 2 | **BONUS LEDGER (read)** | `bonus_history_screen.dart`, `bonus_wallet_screen.dart`, PWA `BonusLedgerPage` | `BonusWalletController.loadHistory` | `BonusWalletService.fetchMyLedger` (direct `.from('bonus_ledger')`) | — | read-only | none | none | none | **IMPLEMENTED AND VERIFIED IN CODE** (+ RLS live-verified) |
| 3 | **BONUS ORDER DISCOUNT** | Flutter `order_discount_section.dart` (pending only); **PWA: no UI** | `BonusWalletController.submitOrderDiscount` / `removeOrderDiscount` | `requestOrderDiscount` / `cancelOrderDiscount` | `apply_order_discount` (0020:56), `cancel_order_discount` (0020:311) | `ORDER_DISCOUNT` −PENDING→POSTED; `REVERSAL` | none at apply | netted in the invoice total at allocation (0021 delta, live-verified) | `order_discount_test.dart` (11) | **IMPLEMENTED AND VERIFIED IN CODE**; PWA **UI MISSING**; behaviour **REQUIRES LIVE VERIFICATION** |
| 4 | **BONUS PRODUCT REDEMPTION** | `bonus_redeem_screen.dart`; PWA `BonusRedemptionsPage` | `BonusWalletController.submitRedemption` | `requestRedemption` / `cancelRedemption` | `request_redemption` (0018:793), `approve_redemption` (873), `fulfill_redemption` (908), `cancel_redemption` (951) | `REDEEM_PRODUCT` −PENDING→POSTED | **none — fulfillment does not move stock** | none | none | **PARTIALLY INTEGRATED** — no REJECTED transition |
| 5 | **BONUS CASH WITHDRAWAL** | `bonus_withdraw_screen.dart`; PWA `BonusWithdrawalsPage` | `BonusWalletController.submitWithdrawal` | `requestWithdrawal` / `cancelWithdrawal` | `request_withdrawal` (0018:1045), `start_withdrawal_review` (1148), `review_withdrawal` (1185), `mark_withdrawal_paid` (1244), `complete_withdrawal` (1296), `cancel_withdrawal` (1000) | `CASH_WITHDRAWAL` −PENDING→POSTED | none | **none — no cash/bank movement** | none | **PARTIALLY INTEGRATED** — state machine complete, settlement leg missing; live `withdrawal_policy.enabled = false` |
| 6 | **BONUS REVERSAL** | PWA `BonusLedgerPage` reverse dialog; **Flutter: none** | — | `bonusFinancialApi.reverseBonusTxn` | `reverse_bonus_txn` (0018:1332); discount reversal inline in 0020:398 and 0021 | `REVERSAL` POSTED + `reverses_id` | none | none | none | **IMPLEMENTED AND VERIFIED IN CODE** (POSTED-only, one-per-original, capped at `bonus_credit_remaining`) |
| 7 | **BONUS EXPIRATION** | **no UI anywhere** (`expireBonus` exported in the PWA, zero callers) | — | — | `expire_bonus` (0018:1413) | `EXPIRATION` −POSTED per lot | none | none | none | **BACKEND EXISTS / UI MISSING**; also **never scheduled** (no cron / Edge Function) |
| 8 | **BONUS REFUND** | none | — | — | **no writer**; `REFUND` exists only in the CHECK enum | enum value never written | none | none | none | **UI MISSING / BACKEND MISSING (enum-only)** |
| 9 | **BONUS ADJUSTMENT** | PWA reverse dialog (writes `REVERSAL`, not `ADJUSTMENT`) | — | — | **no writer**; enum value only | enum value never written | none | none | none | **UI EXISTS / BACKEND MISSING (partial)** |
| 10 | **ORDER CANCELLATION (branch)** | `branch_order_actions.dart` → `_RejectOrderDialog` | `BranchController.cancelOrderWithDiscount` (283) | `BranchService.cancelOrderWithDiscount` (145) | `cancel_order_with_discount` (0022:64) | `REVERSAL` when a discount existed | **no stock return** | none | `branch_cancellation_test.dart` (7) | **IMPLEMENTED AND VERIFIED IN CODE**; live body markers verified; behaviour untested |
| 11 | **ORDER CANCELLATION (client)** | `order_cancel_section.dart` (pending only) + reason sheet | `OrderController.cancelOrder` (185) | `OrderService.cancelOrder` (357) | `cancel_order_with_discount` | same | same | none | `order_cancellation_test.dart` (10) | **IMPLEMENTED AND VERIFIED IN CODE**; PWA has **no cancel surface** |
| 12 | **PARTIAL ORDER CHANGE** | none | — | — | **NOT FOUND** | — | — | — | none | **NOT FOUND / TECHNICAL GAP** |
| 13 | **PRODUCT REMOVAL FROM ORDER** | none (cart-level removal only, pre-order: `cart_controller.dart:83`) | — | — | **NOT FOUND** | — | — | — | none | **NOT FOUND / TECHNICAL GAP** |
| 14 | **ORDER REACTIVATION AFTER WAITING** | none | — | — | **NOT FOUND** — no `waiting` status exists (live `orders_status_check`) | — | — | — | none | **NOT FOUND / TECHNICAL GAP** |
| 15 | **BONUS RECONCILIATION** | PWA `BonusAuditPage` / `BonusPendingPage` | — | `listAudit`, `listPending`, `processPending` | `bonus_process_pending` (0019:518) | replay of snapshotted `EARN` | none | none | none for the processor | **BACKEND EXISTS / UI PARTIAL** — audit viewer is read-only; no ledger↔allocation↔balance reconciliation report exists |
| 16 | **OPENING_BALANCE / LEGACY_MIGRATION** | **no UI** | — | — | `post_opening_balance` (0018:605), `post_legacy_migration` (0018:673) | `OPENING_BALANCE` / `LEGACY_MIGRATION` POSTED | none | none | none | **BACKEND EXISTS / UI MISSING** — reachable only by a director RPC call |

### D.1 Additional confirmed findings

- **Redemption has no `REJECTED` writer.** `bonus_redemptions.status` CHECK includes `REJECTED` (0018:198, live-verified) and the PWA shows a status badge, but only `approve / fulfill / cancel` RPCs exist (0018:873/908/951). A director can never reject a redemption. **TECHNICAL GAP.**
- **Fulfillment never moves stock.** `fulfill_redemption` (0018:908) flips the ledger row and the status only; it never touches `inventory` or `financial_inventory_movements`. **TECHNICAL GAP** — physical and financial truth diverge on fulfillment.
- **Withdrawal never touches cash.** `mark_withdrawal_paid` (0018:1244) records a reference string only; no `financial_cash_movements` / `financial_bank_movements` row is created. **TECHNICAL GAP.**
- **No `ADJUSTMENT` or `REFUND` writer exists** despite both being legal `txn_type` values in the live CHECK constraint.
- **`expire_bonus` is never scheduled** — no `pg_cron`, no Edge Function, no client caller anywhere.
- **No repository layer exists anywhere.** Flutter and the PWA both call Supabase RPCs/tables directly from services; there is no DAO abstraction in either app. Recorded so a "missing repository" is not later mistaken for a defect.
- **Cancellation does not return stock.** `cancel_order_with_discount` touches `orders`, `bonus_ledger`, `order_cancellations`, `bonus_audit_trail` — never `inventory` (full 0022 body read). If the order was already `assigned`, stock is never restored.

---

## E. Bonus Subledger Integrity Audit

### E.1 How the balance is computed

| Question | Answer | Evidence |
|---|---|---|
| Stored balance column? | **None.** `bonus_accounts` has no amount column (live columns: `user_id, mode, status, currency, opened_at, opened_by, note, created_at, updated_at`). | **VERIFIED LIVE** |
| Derived from ledger? | **Yes — single source of truth.** `bonus_account_funds` (0018:393): `available = Σ(POSTED, amount>0) − Σ(POSTED, amount<0) − Σ(PENDING)`; `reserved = Σ(PENDING)`. | 0018:418-430; signature VERIFIED LIVE |
| Both? | **Derived only** — no cache, no materialized view, no client-side recomputation (`bonus_wallet_service.dart:6-7`: "Never calculated in UI code"). | code + live schema |
| Negative-balance guard | **Structural, not a constraint.** Prevented by `bonus_account_funds` pre-checks + `for update` account locking (0018:412, 0019:264). There is **no** CHECK preventing a negative derived balance. | 0018:412 / 837-842 |

### E.2 Idempotency

| Mechanism | Location | Live status |
|---|---|---|
| `bonus_ledger.idempotency_key` UNIQUE | 0018:73 | `bonus_ledger_idempotency_key_key` — **VERIFIED LIVE** |
| `bonus_ledger_reverses_uniq` partial unique | 0018:171 | **VERIFIED LIVE** |
| `bonus_earn_allocations` unique `(debit, credit)` | 0018:367 | **VERIFIED LIVE** |
| Keys on redemptions / withdrawals / pending | 0018:204, 246; 0019:57 | columns live |
| Replay-by-key pattern | 0018:644, 712, 771, 821, 1357; 0019:402; 0020:107, 340 | code |
| Deterministic order keys | `DISCOUNT:{order}` (0020:88), `REVERSAL:DISCOUNT:{order}` (0020:330), `CANCEL:{order}` (0021:50), `SALES_EARN:{order}:{rule}` (0019:386) | code |
| Client key minting + retention on retry | `newIdempotencyKey()` (`bonus_wallet_controller.dart:10`) | offline-tested |

### E.3 Immutability, reversal and audit

| Control | Evidence | Classification |
|---|---|---|
| POSTED rows cannot be updated/deleted | `prevent_bonus_ledger_mutation` (0018:98) + `trg_bonus_ledger_immutable` (0018:110) | EXISTING + **VERIFIED LIVE** (definition read from `pg_trigger`) |
| PENDING rows are mutable by design | trigger raises only when `old.status = 'POSTED'` | EXISTING (documented) |
| No direct client writes | no INSERT/UPDATE/DELETE policy on any bonus table | EXISTING + **VERIFIED LIVE** (23 policies; all SELECT except two director `ALL` policies on `bonus_rules_v2` and `bonus_settings`) |
| Compensation instead of mutation | `reverse_bonus_txn` (0018:1332); discount reversals (0020:398, 0021) | EXISTING |
| Reference to the original operation | `reverses_id` FK + `bonus_audit_trail` row per RPC | EXISTING (columns live) |
| Reversal cannot fabricate money | credit reversals capped by `bonus_credit_remaining` (0018:1383) | EXISTING |
| Append-only audit | `bonus_audit_trail` has no UPDATE/DELETE policy | EXISTING + **VERIFIED LIVE** |

### E.4 CONFLICT — the live earn engine reads a column that does not exist

This is the most important finding of the audit.

| Item | Value | Source |
|---|---|---|
| Column that exists | `bonus_rules_v2.max_earn numeric` | 0018:133 + live `information_schema` |
| Column the code requires | `max_bonus` | 0019:171, 172, 377, 378 |
| Live check | `pg_attribute` count for `max_bonus` on `public.bonus_rules_v2` → **0** | **VERIFIED LIVE IN THIS AUDIT** |
| Live function bodies | `bonus_check_rule_v2` contains `p_rule.max_bonus` (body offset 3593); `bonus_evaluate_order_earn` contains `v_rule.max_bonus` (offset 6411) | **VERIFIED LIVE IN THIS AUDIT** |
| PWA writes | `max_earn` (`bonusFinancialApi.ts:56,86,177`; `BonusRulesV2Page.tsx:48,116,195,621`) | code — the UI writes the column the engine ignores |
| Flutter | references neither | grep = 0 |

**Static impact derived from the verified facts:**
1. `trg_bonus_rules_v2_validate` is `BEFORE INSERT OR UPDATE` and calls `bonus_check_rule_v2`; because `p_rule` is a composite type, `p_rule.max_bonus` cannot resolve at runtime ⇒ **every rule insert/update fails** — the director PWA rules form is non-functional.
2. `bonus_evaluate_order_earn` reads `v_rule.max_bonus` inside the earn loop and also calls `bonus_check_rule_v2` ⇒ **the `orders` AFTER UPDATE trigger would abort and roll back the status flip**, so marking an order `delivered` fails.

Not fixed here (Phase 0 is read-only). Highest priority in §L.

### E.5 Concurrency and race coverage

| Category | Coverage |
|---|---|
| Concurrent double-submit (client) | offline — `branch_cancellation_test.dart:149`, `order_discount_test.dart:170` |
| Idempotency-key reuse on retry | offline — `branch_cancellation_test.dart:130` |
| Key uniqueness | `bonus_idempotency_key_test.dart` (3 tests) |
| **Database-level race behaviour** | **NONE** — no test, script, or staging environment exists |
| **Live RLS denial probes** | **NONE** in this audit (requires an authenticated session; out of read-only scope) |
| **Atomicity of cancel/reversal/history under failure** | **NONE** |

---

## F. Order Discount Audit

| Scenario | Current implementation | Evidence | Missing behaviour | Tests | Status |
|---|---|---|---|---|---|
| Create order | `create_order_with_items` computes `total_amount` server-side from `products.unit_price`; client prices ignored | 0017:205, 229 | — | `cart_controller_bonus_test.dart` (7, legacy Free-Y math) | EXISTING + function **VERIFIED LIVE** |
| Apply discount | client-only RPC; `effective = least(requested, total, available)` then policy caps | 0020:96-240 | — | 11 offline | EXISTING; behaviour **REQUIRES LIVE VERIFICATION** |
| Funding source | oldest-first lot walk via `bonus_credit_remaining`, excluding lots whose rule has `allow_discount = false`; `MONETARY_ONLY` option | 0020:262-300 | — | none | EXISTING |
| Consumption record | `bonus_earn_allocations` row per lot | 0020:296 | — | none | EXISTING |
| Snapshot | full policy JSON in `bonus_ledger.notes` incl. `order_total`, `applied`, `accounting_treatment: null` | 0020:241-256 | accounting treatment still null (D4) | none | EXISTING |
| Idempotency | UNIQUE key + replay-by-key + explicit duplicate rejection | 0020:107, 130-135 | — | offline | EXISTING |
| Double-discount prevention | second POSTED `ORDER_DISCOUNT` rejected; cancel-then-reapply only | 0020:130-135 | no in-place amount edit | none | EXISTING |
| Link to order | `order_id` FK + `bonus_ledger_order_idx` partial index (0021:26) | **VERIFIED LIVE** | — | none | EXISTING |
| Invoice effect | allocate subtracts `net discount = Σ ORDER_DISCOUNT − Σ linked REVERSAL`, with negative / over-total guards | 0021 delta (live body has `v_discount`) | no `invoices.order_id` → the invoice is not traceable to the order | none | EXISTING + **VERIFIED LIVE** |
| Order total display | `orders.total_amount` is **not** updated by the discount; the UI subtracts locally | 0020 (no UPDATE on orders) | no server-side "payable" on the order row | offline | **PARTIALLY INTEGRATED** |
| Remove discount | `cancel_order_discount` — full compensating credit governed by the snapshot | 0020:369-402 | — | offline | EXISTING |
| Recalculate after item removal | **no such path** — orders are immutable after creation | §D rows 12-13 | recalculation + excess-bonus return | none | **TECHNICAL GAP** |
| Recalculate after order edit | **no such path** | §D row 12 | — | none | **TECHNICAL GAP** |
| PWA discount surface | ledger page shows `ORDER_DISCOUNT` rows generically; no dedicated screen | `BonusLedgerPage.tsx` | analysis/filter surface | none | **PARTIALLY INTEGRATED** |

**Policy state:** D1–D8 are settled in PHASE-16.x and the live `bonus_settings` rows match the locked defaults exactly (`allow_zero_order=false`, `funding_scope=ALL_ELIGIBLE_LOTS`, `cancellation_mode=AUTOMATIC_REVERSAL`, all caps `null`) — **VERIFIED LIVE**. No discount policy was invented or altered here.

---

## G. Cancellation and Waiting-Order Audit

| # | Flow | Current path | Source of truth | Bonus effect | Order status effect | Inventory effect | Notification | Idempotency | Gap |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Cancel by branch manager | `branch_order_actions` dialog → `BranchController.cancelOrderWithDiscount` (283) → `BranchService` (145) → `cancel_order_with_discount` | server RPC (0022:64) | compensating `REVERSAL` when a POSTED discount exists | `pending/assigned/in_progress` → `cancelled` (delivered excluded) | **none** | none | `CANCEL:{order_id}` + state convergence | — |
| 2 | Cancel by client | `order_cancel_section.dart` (pending only) → `OrderController.cancelOrder` (185) → `OrderService.cancelOrder` (357) → same RPC | server RPC | same | client may cancel only `pending` (gate verified live) | **none** | none | same key space | no cancel surface in the PWA |
| 3 | Record reason | `p_reason` **mandatory**; stored in `order_cancellations.reason` | `order_cancellations` (0022:212) | — | — | — | — | — | `reason_code` / `note` always NULL (BD-2 open) |
| 4 | Prevent double cancel | status guard + replay convergence; re-execution writes no new rows | RPC | no second reversal | — | — | — | key + guards | — |
| 5 | Reverse bonus of the order | inline REVERSAL in 0021/0022 (deliberate: `0020`'s role gate rejects branch managers) | snapshot `cancellation_mode` | full compensating credit | — | — | — | `REVERSAL:DISCOUNT:{order_id}` | — |
| 6 | Remove product / reduce quantity | **NOT FOUND** | — | — | — | — | — | — | **TECHNICAL GAP** |
| 7 | Recalculate discount after edit | **NOT FOUND** | — | — | — | — | — | — | **TECHNICAL GAP** |
| 8 | Return excess bonus to wallet | **NOT FOUND** (only whole-order reversal exists) | — | — | — | — | — | — | **TECHNICAL GAP** |
| 9 | Order → waiting when stock unavailable | **NOT FOUND** — allocate raises `Insufficient stock` and aborts (0016:116) | — | — | — | — | — | — | **TECHNICAL GAP** |
| 10 | Notify client when product available | **NOT FOUND** | — | — | — | — | — | — | **TECHNICAL GAP** |
| 11 | Await client confirmation before reactivation | **NOT FOUND** | — | — | — | — | — | — | **TECHNICAL GAP** |
| 12 | Re-check inventory before reservation | partial: `for update` + quantity check at allocate (0016:111-119) | `inventory` row lock | — | — | deduction at allocation | — | — | no reservation concept |
| 13 | Handle shortage after confirmation | **NOT FOUND** | — | — | — | — | — | — | **TECHNICAL GAP** |
| 14 | Guard concurrent / duplicate execution | order `for update` (0022), unique reversal index, status convergence | server | one reversal per original | one flip | — | — | key + unique index | untested at DB level |

**Bypass check (exhaustive):** the only direct `cancelled` write in `medlink_app/lib` is guarded by a Dart `assert` at `branch_service.dart:127` that **bans** `status == 'cancelled'` in `updateOrderStatus` ("Use cancelOrderWithDiscount for cancellations, never a direct write"). `updateOrderStatus` is forward-only elsewhere. No direct `order_cancellations` INSERT/UPDATE/DELETE exists in either app, and no INSERT policy exists on that table (**VERIFIED LIVE**). **No bypass found.**

**Critical inventory finding:** cancelling an already-allocated order never restores `inventory` and never reverses the issued `invoices` row — a real stock/money divergence path, not a design choice.

---

## H. Product and Cross-Branch Inventory Audit

| Capability | Existing code | Data model | Workflow | Tests | Status | Missing work |
|---|---|---|---|---|---|---|
| Central product master | `products` (0002:10); PWA `CatalogPage`, `CatalogImportDialog` | `products` | import + edit | none | EXISTING | — |
| Per-branch stock | `inventory` (0002:38) + `warehouse_inventory` batches (submodule `0011`) | `inventory(branch_id, product_id, quantity)` | branch inventory tab, batches | none | EXISTING | no reservation/hold table |
| Search across branches | **NOT FOUND** (no RPC, query or UI) | — | — | — | **TECHNICAL GAP** | search endpoint + UI |
| Split an order across branches | **NOT FOUND** — `create_order_with_items` assigns the order to the **first branch by `created_at`** (0017:208-212) | single `orders.branch_id` | — | — | **TECHNICAL GAP / CONFLICT** | multi-branch order model |
| Insufficient stock | allocate raises and aborts the whole allocation (0016:116) | — | allocate sheet shows availability chips | none | EXISTING (hard failure) | waiting path |
| Substitute products | **NOT FOUND** (grep `substitute`/`alternative` = 0) | — | — | — | **TECHNICAL GAP** | whole feature |
| Waiting for availability | **NOT FOUND** (no `waiting` status; live CHECK = 5 statuses) | — | — | — | **TECHNICAL GAP** | status + lifecycle |
| Notify general manager | **NOT FOUND** | — | — | — | **TECHNICAL GAP** | escalation |
| Branch approval of a client-chosen substitute | **NOT FOUND** | — | — | — | **TECHNICAL GAP** | approval workflow |
| Re-check stock after confirmation | **NOT FOUND** | — | — | — | **TECHNICAL GAP** | tied to the waiting flow |
| Safe reservation | **NOT FOUND** — allocation deducts immediately under a row lock | — | — | none | **TECHNICAL GAP** | reservation semantics |
| Recalculate bonus after change | **NOT FOUND** | — | — | — | **TECHNICAL GAP** | tied to §F |
| Free-Y units consume physical stock | **YES** — full-demand allocation includes `is_bonus` lines (0016:57-80, 0021:226-249) | `order_items.is_bonus` | allocate sheet | offline only | EXISTING + **VERIFIED LIVE** (gate present in the live body) | live test |

### H.1 Recorded business decisions vs. current code (decisions respected, not re-opened)

| Decision already settled | Reflection in code |
|---|---|
| Central product master, branch-owned quantities | **Reflected** — `products` central, `inventory` per branch |
| Branch manager chooses the fulfilment path on shortage | **Not implemented** — no shortage workflow exists |
| Search other branches, show options | **Not implemented** |
| Client picks a substitute → branch manager approves | **Not implemented** |
| Client declines → wait / remove item / cancel by agreement | **Not implemented** (wait and remove both absent) |
| Removing a product requires discount recalculation + a traceable, replay-protected bonus return | **Not implemented** — no edit path exists |
| Availability messages use customisable templates | **Not implemented** — `notifications` is flat, no template table |
| Channels: in-app + push | In-app exists (`notifications`, `notification_reads` — 0003:78/89); **no push integration** (no FCM/APNs code in either app) |
| Notify client first, wait for confirmation | **Not implemented** |
| No auto-cancel on client silence | Trivially satisfied (no waiting flow) |
| Re-check stock after confirmation | **Not implemented** |
| Shortage → notify branch manager, re-search | **Not implemented** |
| Do not mix Bonus with legacy Buy-X-Free-Y | **Respected** — `bonusFinancialApi.ts:3-7` states the separation; disjoint tables and RPCs; confirmed by grep |

**CONFLICT to record:** `create_order_with_items` (0017:208-212) hard-assigns every order to the first branch by `created_at`, with no client or catalogue choice. Any cross-branch requirement conflicts with this as written.

---

## I. Accounting and General Ledger Audit

### I.1 What exists

| Object | Where | Status |
|---|---|---|
| 27 `financial_*` tables | live DB; DDL only in the **submodule** chain `0006_financial_core` (+`0007`,`0008`,`0010`–`0013`) | **VERIFIED LIVE**; provenance partly missing |
| `create_financial_journal_entry` / `post_financial_journal_entry` | live DB | **VERIFIED LIVE** — manual, director-driven, company-scoped, bonus-free |
| `fn_financial_auto_entry` | submodule `0009_financial_auto_posting.sql:35` | **VERIFIED LIVE** — auto-posts **invoices** and **driver commissions** only |
| `trg_financial_bonus_inventory` | submodule `0009:184-220` | **VERIFIED LIVE** — writes a `financial_inventory_movements` row of type `bonus` on inserting an `is_bonus` order line. **This is legacy Free-Y, not the financial Bonus system.** |
| PWA financial module | `financialApi.ts`, `FinancialPage`, `JournalPage`, `ExpensesPage`, `ReceiptsPage` | EXISTING — **zero bonus references** (grep) |

### I.2 Bonus → Accounting traceability

| Bonus event | Accounting event | Journal entry | Journal lines | Source reference | Reversal reference | Idempotency | Status |
|---|---|---|---|---|---|---|---|
| EARN (0019) | none | none | none | none | none | ledger key only | **MISSING** — BUSINESS POLICY REQUIRED (D4) |
| ORDER_DISCOUNT (0020) | none | none | none | `accounting_treatment: null` in the snapshot (0020:250) | n/a | `DISCOUNT:{order}` | **MISSING** — BUSINESS POLICY REQUIRED |
| REDEEM_PRODUCT (0018) | none | none | none | none | none | key on request | **MISSING** — no COGS/stock leg either |
| CASH_WITHDRAWAL (0018) | none | none | none | none | none | key on request | **MISSING** — no cash-account leg |
| REVERSAL (0018/0020/0021) | none | none | none | none | n/a | `REVERSAL:{…}` | **MISSING** — nothing exists to reverse |
| EXPIRATION (0018) | none | none | none | none | `reverses_id` | unique index | **MISSING** |
| Legacy Free-Y line | inventory movement only | none | none | `reference_type='order_items'` | none | none | **PARTIAL** — quantity movement, **no monetary entry** |

**Proof of absence (this audit):**
- Live query joining `financial_journal_entries → financial_documents` filtering `source_table`/`description` for `bonus` / `بونص` → **0 rows**.
- `grep -ri bonus` over `financialApi.ts`, `Financial*.tsx`, `JournalPage.tsx` → **0 matches**.
- No FK from any `bonus_*` table to any `financial_*` table (live column inspection).
- `financial_journal_entries.source_document_id` and `financial_documents.source_table/source_id` exist (**VERIFIED LIVE**) but **no Bonus value is ever written into them**.

**Consequence:** the financial Bonus liability is entirely off-book — no balance-sheet position, no expense, no revenue effect. Largest open item; **BUSINESS POLICY REQUIRED (D4)**, consistent with PHASE-41/45.

### I.3 Structural blocker for any future bridge

Journals are **company-scoped** (`financial_journal_entries.company_id` → `financial_companies`, **VERIFIED LIVE**); the Bonus side has **no company concept at all** (no company column in any of the 9 bonus tables, **VERIFIED LIVE**). `create_financial_journal_entry` takes no company parameter. A bridge is therefore not a mapping exercise — it depends on the undecided BD-01..BD-11 set (PHASE-45). **No accounting policy, account code or posting rule was chosen in this audit.**

---

## J. Source Traceability Matrix

| From | To | Link mechanism | Exists? | Evidence | Status |
|---|---|---|---|---|---|
| `order` | `bonus_ledger` (EARN) | `bonus_ledger.order_id` FK, set by the evaluator | YES | 0018:65; 0019:397-401 | EXISTING (column live) |
| `order` | `bonus_ledger` (ORDER_DISCOUNT) | `order_id` FK | YES | 0020:262 | EXISTING |
| `order` | `order_cancellations` | FK `order_id` RESTRICT | YES | 0022:19 | EXISTING + **VERIFIED LIVE** |
| `order_cancellations` | `bonus_ledger` (REVERSAL) | `reversal_ledger_id` FK RESTRICT | YES | 0022:27, 216 | EXISTING + **VERIFIED LIVE** (column live) |
| REVERSAL | original debit | `reverses_id` FK + partial unique index | YES | 0018:68/171 | EXISTING + **VERIFIED LIVE** |
| debit | credit lots | `bonus_earn_allocations` (credit_ledger_id, debit_ledger_id) | YES | 0018:357-368 | EXISTING + **VERIFIED LIVE** |
| redemption / withdrawal | ledger row | FKs `bonus_ledger.redemption_id / withdrawal_id` (RESTRICT) | YES | 0018:266-279 | EXISTING + **VERIFIED LIVE** |
| rule | ledger | `bonus_ledger.rule_id` FK | YES | 0018:177-183 | EXISTING |
| `order` | `invoices` | **no column** (invoices carry client_id/branch_id/amount/status only) | **NO** | live column inspection | **TECHNICAL GAP** |
| `invoice` | `payments` | `payments.invoice_id` | YES | live table | EXISTING (stub only) |
| **`bonus_*` (any)** | **`financial_journal_entries` / `financial_general_ledger`** | **none** | **NO** | 0 FKs, 0 body references, 0 UI references, 0 rows | **TECHNICAL GAP + BUSINESS POLICY REQUIRED** |
| `financial_documents.source_table / source_id` | a bonus row | column exists, never written | **NO** | live query = 0 | **TECHNICAL GAP** |

**Chain summary:** `ORDER → BONUS ACCOUNT → BONUS LEDGER → (discount | redemption | withdrawal | reversal | expiration)` is fully traceable. The chain then **stops**: no edge from any bonus event to an invoice, a payment, a financial document or a journal entry exists.

---

## K. Test and Verification Results

### K.1 Commands actually executed in this audit (real outcomes)

| # | Command | Result |
|---|---|---|
| 1 | `cd medlink_app && flutter test --reporter compact` | **All tests passed — 39/39** (final line `02:17 +39: All tests passed!`, exit code 0). Breakdown: `order_cancellation_test.dart` (10), `order_discount_test.dart` (11), `branch_cancellation_test.dart` (7), `cart_controller_bonus_test.dart` (7), `bonus_idempotency_key_test.dart` (3), `widget_test.dart` (1) |
| 2 | `cd medlink_app && flutter analyze` | **4 issues, all `info`, all pre-existing deprecations**, 0 errors / 0 warnings: `branch_invoice_create_sheet.dart:127`, `branch_order_actions.dart:46`, `branch_order_actions.dart:104`, `addresses_screen.dart:498` |
| 3 | Read-only catalog `SELECT`s against `lmkomzqioneuyvatzsov` | All succeeded (§C.2, §C.4, §E.3, §E.4, §I.2). One transient MCP error ("Connection closed") on a multi-statement query; retried successfully — no data affected |
| 4 | `git status` (both repos) | Main repo: `M Medlik-Waap` (submodule pointer) + untracked docs. Submodule: no application modifications. No pre-existing local application edits were found before this audit |

### K.2 What was NOT run, and why

| Not run | Reason |
|---|---|
| Any test touching the live database | Forbidden by the read-only mandate; all existing tests are offline fakes by design |
| Live RLS denial probes | Require an authenticated session and would be behaviour-changing |
| Executing `expire_bonus`, `earn_bonus`, `apply_order_discount`, `cancel_order_with_discount` | All are write RPCs — explicitly forbidden |
| Web/PWA typecheck & build | No web code was changed; `package.json` has no `test` script — **there is no web test harness at all** |
| SQL / pgTAP tests | None exist in the repository (`find . -name '*.sql'` → migrations + installer + queries only) |
| `supabase db push` / migration application | Forbidden |

### K.3 Coverage assessment

| Area | Unit/widget coverage | Live/behavioural coverage |
|---|---|---|
| Idempotency-key generation | 3 tests | none |
| Discount apply/remove + widget | 11 tests | none |
| Client cancel + history UI | 10 tests | none |
| Branch cancel + dialog | 7 tests | none |
| Legacy Free-Y cart math | 7 tests | none |
| **EARN valuation / stacking / caps / pending replay** | **0** | **0** |
| **Redemption / withdrawal lifecycles** | **0** | **0** |
| **Expiration sweep** | **0** | **0** |
| **Reversal correctness and caps** | **0** | **0** |
| **Ledger immutability trigger** | **0** | **0** |
| **Concurrency / duplicate idempotency at DB level** | **0** | **0** |
| **Allocation + invoice math** | **0** | **0** |

**Note on prior reports:** earlier phases reported 22/22, 28/28 and 29 tests. Those were accurate for their time; the current tree has **39** and all 39 pass today. No prior result was reused as a current result.

---

## L. Technical Gaps

Ordered by dependency and operational risk. No accounting-policy ranking is implied.

| # | Gap | Class | Evidence | Blocks |
|---|---|---|---|---|
| **L1** | **`max_bonus` vs `max_earn`** — the live earn engine and rule validator read a non-existent column | **CONFLICT / runtime defect** | §E.4 (live `pg_attribute` = 0; live bodies contain `max_bonus`) | Rule creation (PWA form) and order delivery |
| **L2** | **No staging / isolated test database** | TECHNICAL GAP | nothing in the repo provisions one; all tests are fakes | Every behavioural verification below |
| **L3** | **Zero behavioural tests** of earn, discount, cancel, reversal, expiry, allocation, invoice math | TECHNICAL GAP | §K.3 | Confidence in the whole money path |
| **L4** | **No order-edit / item-removal path** → no discount recalculation, no excess-bonus return | TECHNICAL GAP | §F, §G rows 6-8 | A recorded business decision |
| **L5** | **Cancellation does not restore inventory or reverse the invoice** | TECHNICAL GAP | full 0022 body read | Stock accuracy after cancellation |
| **L6** | **Redemption fulfillment moves no stock; no COGS leg; no `REJECTED` transition** | TECHNICAL GAP | §D.1 | Physical/financial consistency |
| **L7** | **Withdrawal settlement records no cash/bank movement** | TECHNICAL GAP | 0018:1244 | Cash reconciliation |
| **L8** | **No waiting-order state, availability notification, client confirmation, or reactivation** | TECHNICAL GAP | §H | An entire recorded decision set |
| **L9** | **No cross-branch stock search, no multi-branch order split, no substitutes** | TECHNICAL GAP | §H; 0017:208-212 CONFLICT | Fulfilment policy as recorded |
| **L10** | **`orders.branch_id` assigned by `created_at` at creation** | CONFLICT | 0017:208-212 | Any branch-selection design |
| **L11** | **`expire_bonus` never scheduled; `ADJUSTMENT` and `REFUND` have no writer** | TECHNICAL GAP | §D rows 7-9 | Expiry and manual correction |
| **L12** | **No push-notification channel** (in-app only) | TECHNICAL GAP | no FCM/APNs code | Recorded channel decision |
| **L13** | **No notification templates / no order-linked notifications** | TECHNICAL GAP | `notifications` shape (0003:78) | Recorded template decision |
| **L14** | **No PWA surfaces for order discount, cancellation, or cancellation history** | TECHNICAL GAP | grep = 0 in `pharma-pwa/src` | Director-side operations |
| **L15** | **No reconciliation report** (ledger vs allocations vs balances vs pending) | TECHNICAL GAP | audit/pending pages are raw views | Operational control |
| **L16** | **Invoices not linked to orders** (no `order_id`); cancelling leaves them stale | TECHNICAL GAP | live column inspection; §G | Order→invoice→accounting chain |
| **L17** | **Two divergent copies of migration `0016`**, one missing the full-demand gate | CONFLICT | §C.3 | Reproducibility of the live schema |
| **L18** | **Financial module provenance split**: 27 live tables whose DDL lives only in the submodule; 3 have no DDL at all | TECHNICAL GAP | §C.2 | Any accounting work |
| **L19** | **`earnBonus` / `expireBonus` / `getBonusRuleV2` exported with zero UI callers** | Dead export | grep over `*.tsx` | Director manual earn/expire |
| **L20** | **No DB-level guard against a negative derived balance** | TECHNICAL GAP | §E.1 | Defence in depth |

---

## M. Business Policies Still Required

Only decisions that are **not** already settled are listed. Settled decisions (per-company deployments, central products + branch stock, branch-manager fulfilment ownership, discount policy D1–D8, BD-1 cancellation shape, H1/H2/H3 locks, automatic reversal default) are **not** re-opened.

| ID | Decision required | Why still open | Blocks |
|---|---|---|---|
| **D4** | Accounting treatment of every Bonus event (earn, discount, redemption, withdrawal, reversal, expiration): accounts, timing, liability vs expense | No treatment code exists; `accounting_treatment` is explicitly `null` in the 0020 snapshot (0020:250) | The entire GL bridge |
| **BD-01…BD-11** | Company model and ownership anchoring (single vs multi; customer/order/branch/context anchor; wallet scope; cross-company rules; historical ownership; non-order event context) | PHASE-45 §Q lists all eleven undecided | Any bridge — journals are company-scoped, Bonus is company-less |
| **BD-2** | Cancellation reason taxonomy (`reason_code` values, `note` semantics) | Columns exist and are always NULL (0022:21-22); PHASE-29/31/32.1 left the values open | Final cancellation UX and reporting |
| **H2** | Invoice↔order linkage scope; whether cancellation voids an issued invoice | `invoices` has no `order_id`; H2-A deferred linkage | Invoice accuracy, L5/L16 |
| **PAY** | Payment model (provider, status lifecycle, settlement, link to withdrawal) | `payments` is a stub (`invoice_id`, `client_id`, `amount` only) | Withdrawal settlement (L7) |
| **EDIT** | Order-edit semantics: who may edit, what recalculation applies, how excess bonus returns | Recorded as a decision; no code path exists | L4 |
| **WAIT** | Waiting-order policy: waiting-state expiry, auto vs manual reactivation, substitute approval authority | Flow entirely absent | L8 / L9 |
| **FIN-OWNER** | A named owner for accounting decisions (absent throughout the documentation) | No owner recorded in any report | Sign-off on D4 |
| **LEGACY-MIG** | Whether/when legacy Free-Y exposure is migrated into the financial wallet | `post_legacy_migration` exists (0018:673) with no UI and no data | Wallet history completeness |

**No policy was selected, recommended, or implied in this report.**

---

## N. Dependency Map

```
L1 (max_bonus fix) ───────────────────────────────► earn engine usable ──► any earn testing
                                                          │
L2 (staging DB) ──► L3 (behavioural tests) ────────────┤
                                                          │
L4 (order edit) ──► discount recalculation ──► excess-bonus return   [needs EDIT]
   │
L5 (cancel ↔ stock / invoice) ── needs H2 (+ PAY)
   │
L6 (redemption stock + COGS) ─┐
L7 (withdrawal settlement) ───┼──► needs D4 + BD-01..11 (company identity)
L11 (expiry scheduling) ──────┘
                                                          │
L17/L18 (provenance reconciliation) ──► reproducible schema ──► any future migration
                                                          │
L8/L9 (waiting, cross-branch, substitutes) ── needs WAIT policy + L10 branch-model fix
                                                          │
L12/L13 (push + templates) ── needs a notification-model decision
                                                          │
L14 (PWA surfaces)          ── independent, startable now
L15 (reconciliation report) ── independent, read-only, high value
L19/L20 (dead exports, balance guard) ── small, independent
```

**Hard ordering rules:**
1. **L1 before anything earn-related** — a broken earn engine makes every downstream earn test meaningless.
2. **L2 before L3** — without an isolated database, behavioural tests can be written but not trusted.
3. **L17/L18 before any new migration** — writing `0023` while two divergent `0016` copies and 3 undocumented live tables exist compounds the drift.
4. **BD-01…BD-11 and D4 before L6/L7 and any GL work** — these are owner decisions, not engineering tasks.
5. **L4 needs the EDIT policy; L8/L9 need the WAIT policy** — neither may be "just built" without risking a policy invention.

---

## O. Recommended Execution Sequence

**Nothing below was executed.** Each phase states its technical justification.

| Phase | Scope | Technical justification | Preconditions |
|---|---|---|---|
| **1 — Defect repair: `max_bonus` → `max_earn`** | One migration aligning the two live functions with the UI contract, plus a regression guard | The single defect that makes rule creation and order delivery fail. Every earn-related phase is blocked by it, and it is cheap to fix correctly: the intended semantics are unambiguous (cap the earned amount) and the UI already writes `max_earn`. | none — do first |
| **2 — Database contract reconciliation** | Adopt or explicitly declare out-of-scope the 27 `financial_*` tables; reconcile the two `0016` copies; document the 3 tables with no DDL; make the repo reproduce the live schema | The repo cannot currently reproduce production. Until fixed, every new migration carries unmeasurable drift risk. | none; before any new migration |
| **3 — Staging database + behavioural test harness** | Provision an isolated project; port earn / discount / cancel / reversal / expiry / allocate scenarios as executable tests | Converts every "implemented but unverified" row into proven or refuted, and is the precondition for trusting all later work. | Phase 1 |
| **4 — Behavioural verification of the existing money path** | Run the §K.3 scenarios against staging: earn valuation/stacking/caps, pending replay, suspension hold, discount caps and zero-order rule, cancel atomicity, reversal caps, expiry sweep, allocation and invoice math, concurrency races | These paths are coded but entirely unproven. Verification may reveal defects that would otherwise surface after real money moves. | Phase 3 |
| **5 — Internal consistency fixes found by Phase 4** | e.g. redemption stock movement, withdrawal cash leg, `ADJUSTMENT`/`REFUND` writers, expiry scheduling, negative-balance guard | Depends on what Phase 4 proves; sequencing after verification avoids speculative changes. | Phase 4; L6/L7/L11/L20 partly need D4 |
| **6 — Read-only reconciliation reporting** | Director report: per-account balance vs allocations, lot remainder, pending entitlements, unreversed events | Pure read-only, no policy needed, immediately useful for control, reuses the existing `BonusAuditPage` surfaces. | parallel with 3-5 |
| **7 — PWA parity surfaces** | Director views for order discounts, cancellations and cancellation history (read-only first) | The backend already exists and is live; this is a UI gap, not a design gap. Closes L14 with no new migration and no new policy. | Phase 1 (so the displayed data is trustworthy) |
| **8 — Order edit + discount recalculation** | Item removal / quantity change, discount recompute, traceable excess-bonus return | Implements the recorded decision that removal requires recalculation and a replay-protected return; it cannot be designed without the EDIT policy and depends on a working earn/discount cycle. | EDIT policy; Phase 4 |
| **9 — Cancellation ↔ inventory and invoice consistency** | Restore stock on cancel after allocation; void or credit the invoice | L5 is a real money/stock divergence. Scope depends on H2. | H2 |
| **10 — Waiting-order and cross-branch fulfilment** | Waiting status, availability search, notification, client confirmation, reactivation, substitutes | Largest unbuilt area and the one with the most recorded decisions. Requires resolving L10 first: a cross-branch flow on top of a `created_at`-ordered single branch would be unsound. | WAIT policy; L10 decision; Phase 3 |
| **11 — Notification channels and templates** | Push delivery, template table, order/bonus event linking | Recorded decisions; depends on the event sources defined in Phases 5-10. | Phases 5-10 |
| **12 — Accounting integration (GL bridge)** | Design only until D4 + BD-01..BD-11 are decided; then per-event posting, reversal and company mapping | Company-less Bonus cannot be posted into company-scoped journals; this is a decision gate, not an engineering one. Building first would invent accounting policy. | **D4 + BD-01..BD-11 + FIN-OWNER** |

---

## P. Phase 0 Acceptance Checklist

| # | Item | Status | Evidence of completion |
|---|---|---|---|
| 1 | Working directory and repository confirmed | ✅ | `/home/adman/stitch_medlink_yemen` main repo + `Medlik-Waap` submodule identified via `git ls-files -s` |
| 2 | Project instructions read | ✅ | `AGENTS.md`, `README.md` (main-repo root), `.opencode/skills` (12), `.opencode/agents` (5) |
| 3 | Project structure mapped (Flutter, Web PWA, migrations, RPCs, services, Bonus/Order/Invoice/Inventory surfaces) | ✅ | §B.1, §C.1, §D |
| 4 | Git state inspected read-only; no reset / checkout / clean executed | ✅ | `git status`, `git log`, `git branch` only |
| 5 | Prior reports reviewed | ✅ | §B.2 (14 report families read; 2 named reports confirmed NOT FOUND) |
| 6 | Reports compared against current code; differences recorded | ✅ | §B.2 conflict rows; §C.3; §E.4 |
| 7 | Migrations 0016/0017/0018/0019/0020/0021/0022 read by content, not by number | ✅ | §C.1 with line references |
| 8 | Migration dependency table produced | ✅ | §C.1 |
| 9 | All 14 requested operations traced end-to-end | ✅ | §D (16 operations, incl. 2 extra) |
| 10 | Bonus subledger integrity controls audited (12 questions) | ✅ | §E.1, E.3, E.5 |
| 11 | Order discount audited (apply → invoice → balance → recalculation) | ✅ | §F |
| 12 | Cancellation / partial change / waiting audited (14 flows) | ✅ | §G |
| 13 | Refund / reversal / expiration / adjustment / opening / legacy separated | ✅ | §D rows 6-9, 16; §G row 5; §J |
| 14 | Financial Posting Engine and GL searched and assessed | ✅ | §I |
| 15 | Inventory and cross-branch capabilities inventoried | ✅ | §H |
| 16 | Recorded business decisions respected, not re-asked | ✅ | §H.1, §M preamble |
| 17 | Tests inspected; safe tests executed; unsafe ones documented as not run | ✅ | §K.1, §K.2 |
| 18 | Every finding classified with the mandated vocabulary | ✅ | §A.3 legend applied throughout |
| 19 | No application / migration / database file modified | ✅ | §Q |
| 20 | This report is the only file created | ✅ | new file under `docs/opencode/` |

---

## Q. Final Status

**Audit result: COMPLETE.**

What is genuinely in place and evidenced: a derived-balance, append-only, RLS-locked, idempotent financial Bonus subledger (live), an order-discount engine (live, reflected in the invoice calculation), an atomic cancellation with compensating reversal and history (live), and app wiring on both Flutter and the director PWA for discount, cancellation, redemption and withdrawal — with 39 passing offline tests.

What is not in place: the accounting layer (no Bonus↔GL link of any kind), the entire order-edit / waiting / cross-branch fulfilment area, push notifications and templates, reconciliation reporting, PWA discount/cancel surfaces, and — most urgently — a **live runtime defect** in the earn engine (`max_bonus` vs `max_earn`).

### Constraints that remain unverified after this audit

| Constraint | Why it stays unverified |
|---|---|
| Live behaviour of every Bonus RPC | The live database contains **zero** bonus rows; executing the RPCs would be a write, which is forbidden |
| RLS enforcement under a real session | Requires an authenticated client session; only policies were read from the catalog |
| Concurrency and race behaviour | Requires writes; no staging environment exists |
| Immutability trigger behaviour at runtime | The trigger *definition* is verified live; its runtime effect on an attempted mutation was not exercised |
| Whether the `max_bonus` defect manifests exactly as statically derived | The derivation is rigorous (live body + live column list), but no function was called to observe the error |
| Financial module DDL provenance | 3 live `financial_*` tables have no DDL in either repository; the creation method is not determinable read-only |
| Push / templates / waiting / edit features | Not present in code at all — nothing to verify |

**No corrective action was taken for any finding in this report.** All gaps in §L and all policies in §M remain pending the owner's decision on sequencing.

---

*Report generated in Phase 0 (read-only). Repository state at the time of writing: main repo `8e30112` (unmodified), submodule `5c0314f` (unmodified), live database untouched.*

**PHASE 46 — BONUS CURRENT STATE AUDIT COMPLETE**
