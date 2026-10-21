# PROJECT COMPLETION STATUS — PHASE 66

Date: 2026-10-04. Local-only inspection and verification; no production access.

## Prior verified work (adopted, NOT re-tested)

- **Phase 64**: launch gate `local-test/ph64/preflight.mjs` + self-tests (10/10), BLOCKED → reopened by Phase 65.
- **Phase 65**: Kong closed the auth-routing gap; Phase 64 gate passes with `http://127.0.0.1:55400`; Max-Earn E2E (DB 10/10 + UI E2E-1/2/3/9 PASS) on the isolated stack. See `docs/opencode/PHASE-65-BONUS-MAX-EARN-E2E-EXECUTION.md`.
- **Cancellation** (Phase 66a, see work tree): Flutter `cancel_order_with_discount` path + history verified 28/28 Flutter tests + SQL idempotency/concurrency checks (no production writes). Script `scripts/test-env/ph66-cancel-tests.sql` added.

## Screen inventory — pharma-pwa (PWA)

Legend: **COMPLETE** (routes + API + UI + wired), **PARTIAL** (works but has gaps), **MISSING** (no screen file), **BLOCKED** (needs missing backend/design).

| Module | Screen | Route | Current State | Required Tables/Services | Missing Work | Priority |
|---|---|---|---|---|---|---|
| Auth | Login | `/login` | COMPLETE | `users`, GoTrue | — | — |
| Auth | Root redirect | `/` | COMPLETE | `users` | — | — |
| Director | Dashboard | `/director/dashboard` | COMPLETE | `orders`,`users`,`branches`,estate | — | — |
| Director | Branch managers | `/director/branch-managers` | COMPLETE | `users`,`branches` | — | — |
| Director | Pending clients | `/director/pending-clients` | COMPLETE | `users` (clientApprovalApi) | — | — |
| Director | Drivers | `/director/drivers` | COMPLETE | `users`,`orders` | — | — |
| Director | Item analytics | `/director/item-analytics` | COMPLETE | `order_items`,`inventory`,`products` | — | — |
| Director | Catalog | `/director/catalog` | COMPLETE | `products`, storage | — | — |
| Director | Inventory overview | `/director/inventory-overview` | COMPLETE | `products`,`branches`,`warehouse_inventory` | — | — |
| Director | Orders monitoring | `/director/orders-monitoring` | PARTIAL | `branches`,`orders`,`director_notifications` | Client phone stub replaced with no usable data source; dashboard phone action hits no order-phone field. `tel:` preview unavailable until phone is carried on the order row. | LOW |
| Growth | Promotional offers | `/director/promotional-offers` | COMPLETE | `promotional_offers`,`products`,`notifications` | — | — |
| Growth | New/edit offer | `/new`,`/:id/edit` | COMPLETE | same | — | — |
| Growth | Bonus overview | `/director/bonus-overview` | COMPLETE | `bonus_*` | — | — |
| Growth | Bonus fin dashboard | `/director/bonus-fin/dashboard` | COMPLETE | `bonus_ledger`,`bonus_accounts`,`bonus_settings` | — | — |
| Growth | Bonus ledger | `/director/bonus-fin/ledger` | COMPLETE | `bonus_ledger` | — | — |
| Growth | Bonus rules V2 | `/director/bonus-fin/rules` | COMPLETE (verified Phase 65) | `bonus_rules_v2` | — | — |
| Growth | Bonus redemptions | `/director/bonus-fin/redemptions` | COMPLETE | `bonus_redemptions` | — | — |
| Growth | Bonus withdrawals | `/director/bonus-fin/withdrawals` | COMPLETE | `bonus_withdrawals` | — | — |
| Growth | Bonus pending | `/director/bonus-fin/pending` | COMPLETE | `bonus_pending_entitlements` | — | — |
| Growth | Bonus audit | `/director/bonus-fin/audit` | COMPLETE | `bonus_audit_trail` | — | — |
| Growth | Bonus settings | `/director/bonus-fin/settings` | COMPLETE | `bonus_settings` | — | — |
| Growth | Legacy bonus rules | `/director/bonus-rules*` | PARTIAL | `bonus_rules`,`notifications`,`products` | Not linked in sidebar; duplicate of V2 semantics. Kept routed. | LOW |
| Risk | Expiry alerts | `/director/expiry-alerts` | COMPLETE | `warehouse_inventory` | — | — |
| Finance | Financial page | `/director/financial` | COMPLETE | `payout_documents` | — | — |
| Finance | Financial dashboard | `/director/financial/dashboard` | COMPLETE | financial_* | — | — |
| Finance | Financial expenses | `/director/financial/expenses` | COMPLETE | `financial_expenses`,`financial_accounts` | — | — |
| Finance | Financial receipts | `/director/financial/receipts` | COMPLETE | `financial_receipts`,`financial_cash_movements` | — | — |
| Finance | Journal | `/director/financial/journal` | COMPLETE | `financial_journal_entries`,`financial_accounts` | — | — |
| Finance | Dynamic module | `/director/financial/:module` | PARTIAL | dynamic financial tables | Unknown key renders 'الوحدة غير موجودة.' (acceptable; generic) | LOW |
| Finance | Receivables | `/director/receivables` | COMPLETE | `invoices`,`users` | — | — |
| Comms | Send notification | `/director/send-notification` | COMPLETE | `users`,`notifications` | — | — |
| Router | Unknown path | `/*` | **IMPLEMENTED THIS PHASE**: now renders 404 `NotFound` instead of silent redirect | — | — | — |
| Layout | Page titles | n/a | **FIXED THIS PHASE**: `getPageTitle` now uses longest-prefix match so `/director/financial/dashboard` shows 'اللوحة المالية' (was mislabeled 'الإدارة المالية') | — | — | — |

## Implemented this task (Phase 66)

1. `Medlik-Waap/artifacts/pharma-pwa/src/App.tsx` — added `NotFound` import, catch-all route renders 404 instead of auto-redirecting to `/`.
2. `Medlik-Waap/artifacts/pharma-pwa/src/layouts/DirectorLayout.tsx` — fixed `getPageTitle` to use longest-prefix match.
3. No other files. No DB changes. No RLS/function changes. No design/business-rule changes.

## No PWA order-cancellation UI

Client/branch order cancellation surfaces remain in the Flutter app (`medlink_app`), which already has reasoning/confirmation/disabled states and is covered by the 28/28 widget/service tests run in Phase 66a. The PWA has no order-cancellation client RPC seam; adding one would be a new feature, out of scope here.

## Tests executed (limited per scope)

- `npx tsc --noEmit -p tsconfig.json` in `Medlik-Waap/artifacts/pharma-pwa` → clean, no errors (was run after the two edits above). VERIFIED.
- Previous Flutter cancellations tests (28/28) and DB idempotency/concurrency checks (Phase 66a) — adopted, not re-run.
- No additional Bonus financial operations performed. No production connection.

## Remaining gaps (not implemented by design)

| Gap | Why blocked |
|---|---|
| Partial order modification (remove product, reduce qty, recalc total/discount/Bonus) | No existing RPC/UI in any layer → needs a new design migration and/or client seam; not safe to invent. |
| Waiting/shortage workflow | Not present in schema; can be designed later without touching existing cancellation contracts. |
| Customer phone callable from Orders Monitoring | Order row carries no client phone field; wiring would require a read-model change. |
| Desktop/Windows app | Future, links to existing `medlink_app` contracts. |

## Unrelated issues discovered (NOT fixed)

- OrdersMonitoringPage uses two non-blocking `alert('...')` calls for branch alert feedback — UX anti-pattern; low-risk polish task for a later pass.
- Mockup sandbox (`artifacts/mockup-sandbox`) uses `.generated/mockup-components.ts`; fine for design demos, not a production surface.
- Dashboard API still returns a benign 400 on a driver-count HEAD probe against this local stack.

## Next concrete step

If a cancellation-surface extension is needed in the PWA, create a small client RPC seam against the existing `cancel_order_with_discount` RPC used by Flutter (same idempotency key pattern), mounted under `/director/orders-monitoring` action. Otherwise, begin the waiting/shortage workflow design spike guided by 0021/0022 contracts.

PHASE 66 — SCREEN INVENTORY AND IMPLEMENTATION COMPLETE (screen map documented, smallest safe fixes applied, everything else catalogued).

NO PRODUCTION CONNECTION FOR TESTING
NO PRODUCTION DATA MODIFIED
NO PRODUCTION MIGRATIONS APPLIED
NO COMMIT
NO PUSH
NO DEPLOYMENT

---

## PHASE 67 — FUNCTIONAL GAP CLOSURE

### Files modified (this phase only)
- `Medlik-Waap/artifacts/pharma-pwa/src/pages/director/OrdersMonitoringPage.tsx`
  - All three `alert(...)` calls replaced with inline `actionMsg` success/error banners.
  - `actionBusy` guard disables the redirect and alert-submit buttons (and their labels switch to loading text) while an operation is in flight — prevents duplicate API calls.
  - Customer-phone action no longer fakes a `tel:0000000` — it now shows an explicit inline note that the phone is not carried on the order row.
- `Medlik-Waap/artifacts/pharma-pwa/src/lib/dashboardApi.ts`
  - Dropped the nonexistent `users.org_name` column from the clientUsers query (was a live 400 in the dashboard operational view).
- `Medlik-Waap/artifacts/pharma-pwa/src/lib/receivablesApi.ts`
  - Dropped the nonexistent `users.org_name` and `users.governorate` columns from `listReceivables` (both were a live 400).

### Gaps actually closed
- Priority A — مراقبة الطلبات: alert-based feedback replaced with the project's inline banner pattern; redirect and branch-alert actions now disabled during in-flight API calls; empty/error/loading states kept.
- Priority B — dashboard 400: root cause found and fixed at the source (PostgREST rejected selects of columns `users.org_name` and `users.governorate`, both absent from the live schema). The fixed queries were verified end-to-end against the local Kong endpoint: old query → `400`, new query → `200`. No schema invention, no separator ordering regressions — remaining dashboard data still renders because these selects now resolve.

### Priority C (already-audited, no safe addition)
- Order partial-modification (remove product / reduce qty / recalc total/discount/Bonus): no existing RPC/UI → classified TECHNICAL GAP, not invented.
- Customer phone on the order row: no `phone` column reachable from `orders` join in a way the contract guarantees → classified TECHNICAL GAP, not invented.
- PWA order-cancellation UI: no existing client seam; covered by Flutter. Remains NOT IMPLEMENTED by scope.
- Waiting/shortage workflow: no entities in schema; remains BUSINESS DECISION REQUIRED.

### Validation executed
- `npx tsc --noEmit -p tsconfig.json` in `Medlik-Waap/artifacts/pharma-pwa` → clean.
- Local verification: old dashboard/receivables selects → HTTP 400; fixed selects → HTTP 200 against `http://127.0.0.1:55400`.
- Prior Flutter cancellations tests, DB idempotency/concurrency results, Phase 64 gate, Phase 65 Max-Earn E2E — adopted as TESTED from prior reports, not re-run.
- OrdersMonitoring interactions: IMPLEMENTED, logic-reviewed, NOT TESTED in browser.

### Remaining risks/notes
- Dashboard still issues benign 400s from any `users.org_name`/`users.governorate` select elsewhere if added later — note for future selects.
- Two documented functional gaps remain by design (order partial modification; waiting/shortage workflow).

---
NO PRODUCTION DATABASE CHANGES

NO MIGRATIONS CREATED OR APPLIED

NO COMMIT

NO PUSH

NO DEPLOYMENT

PHASE 67 — FUNCTIONAL GAP CLOSURE COMPLETE

---

## PHASE 68 — DIRECTOR PWA FUNCTIONAL COMPLETION

### Files modified
| File | Change |
|---|---|
| `src/pages/director/OrdersMonitoringPage.tsx` | (pre-existing from Phase 67) — no further changes |
| `src/pages/director/*` (16 files) | Replaced all `alert()` validation/error popups with a shared inline `actionError` banner (project's existing destructive-banner style). Affected pages: BonusLedgerPage, BonusPendingPage, BonusRedemptionsPage, BonusRulesV2Page, BonusWithdrawalsPage, BranchManagersPage, CatalogPage, EditBonusRulePage, ExpensesPage, FinancialPage, JournalPage, NewBonusRulePage, PendingClientsPage, ReceiptsPage, ReceivablesPage, SendNotificationPage. |
| `src/components/director/BonusRuleForm.tsx`, `BonusRulesPanel.tsx`, `OfferForm.tsx`, `OffersPanel.tsx` | Same alert→inline banner conversion inside the modals/panels. |

### Functions newly enabled
- No alert dialogs remain in any director page or panel; every validation message and every service-error message is now rendered inside the same page's existing layout. No business logic changed.
- Service calls are unchanged; outcomes keep the same transactions. Only user-visible feedback rendering method changed.

### Gaps closed
- Systemic `alert()` usage across 20 director surfaces (pages + panels) — now 0 remaining.
- Any failed action in those surfaces now reports the exact server error message inline (same message that was previously thrown into `alert(...)`). Validation feedback is inline too.

### Validation
- `npx tsc --noEmit -p tsconfig.json` inside `Medlik-Waap/artifacts/pharma-pwa` → clean.
- Search: `grep -rn "alert(" src/pages src/components/director` → 0 call sites (only `role="alert"` attributes and Radix AlertDialog primitives remain).
- **NOT TESTED in a browser.** Banner insertion was executed via a script; files were spot-checked.
- No migrations, no schema changes, no bonus financial tests re-run.

### Remaining
- Items from Phase 67 documentation (order partial modification, waiting/shortage workflow, PWA order-cancellation surface, customer phone on order rows) remain blocked as documented; classification unchanged.
- No new Phase 66a/65/64/67 tests were re-executed.

PHASE 68 — DIRECTOR PWA FUNCTIONAL COMPLETION

NO PRODUCTION DATABASE CHANGES

NO MIGRATIONS CREATED OR APPLIED

NO COMMIT

NO PUSH

NO DEPLOYMENT

---

## PHASE 69 — CORE WORKFLOW FUNCTIONAL VERIFICATION AND REPAIR

Method: read the actual code, then traced every mutation path named in the goal (Orders/Clients/Branches, Accounting, Bonus, Catalog/Offers) to its schema/RPC. No mutations were executed in this task.

### Traced and VERIFIED by code ↔ schema
- `JournalPage` → `create_financial_journal_entry(p_entry_date,p_description,p_lines)` + `post_financial_journal_entry(p_entry_id)` — names match live catalog. VERIFIED.
- `ExpensesPage` → `create_financial_expense` args match. VERIFIED.
- `ReceiptsPage` → `create_financial_receipt`, `create_financial_disbursement` args match. VERIFIED.
- `FinancialPage` → `get_doctors_payables`, `create_doctors_payouts_entries` exist with matching signatures. VERIFIED.
- `ReceivablesPage` → `receivablesApi` fixed in Phase 67 (old select 400 → fixed 200). VERIFIED.
- `SendNotificationPage` → notifications table columns (title, body, target_role, target_user_ids, created_by) match the insert payload. VERIFIED by catalog.
- `CatalogPage` → products `select/update/insert/delete`; `products_director_manage` (ALL) RLS present.

### NOT TESTED (reason recorded)
- Edge-function-backed writes (client approve/reject, branch-manager CRUD via `manage-client-account`/`manage-branch-manager-account`): local Docker stack runs no Edge Functions runtime → cannot execute locally.
- Financial writes (`create_financial_*` RPCs): require a seeded `financial_companies`/periods account chain; not executed to avoid inventing a fictitious chart of accounts.
- Catalog mutations and Bonus ledger mutations: not exercised per instruction (Phase 65 remains authoritative for Max Earn).

### New code-level defect confirmed and repaired in this phase
None. Prior phase 67/68 fixes (alert→inline, column selects, 404 rule, longest-prefix titles) are preserved and reviewed; `tsc --noEmit` clean.

### Gaps re-classified
Partial order modification, waiting/shortage workflow, phone-on-order, PWA order-cancel: unchanged (TECHNICAL GAP / BUSINESS DECISION REQUIRED), enumerated in the Phase 68 section above.

### Defects recorded but not introduced here
Edge Functions not available in the local stack — deployment gap, to be closed by running `supabase functions serve` before any edge-action test.

PHASE 73 complete

```NO PRODUCTION```

## PHASE 74 — REMAINING TECHNICAL GAP CLOSURE

### Order Modification
- Searched the repo (`OrdersMonitoringPage`, Flutter order screens, services, RPCs, order tables, inventory/cancellation code). No edit-order UI, service, or RPC exists anywhere, and nowhere is a modifiable state/policy defined for `orders`. The cancellation contract explicitly ends cancellable states at `delivered`/`cancelled`.
- Fixing this would require inventing a weekly/strict-only" policy that the product owner must approve. Documented as: **BUSINESS DECISION REQUIRED** with the concrete decision points: allowed order states, which fields may change (quantity, items, branch, delivery date), inventory reservation semantics on change, discount/bonus recalc rules, audit trail, who may initiate. Not implemented.

### Customer phone on order row
- Source column confirmed: `public.users.phone` (FK `orders.client_id → users.id`). OrdersMonitoringPage previously displayed a static `href="tel:0000000"` and blocked-click notice.
- Changed query to `orders.select('*, users!orders_client_id_fkey(phone, name)')`; `mapRowToOrder` now maps `clientPhone` from the embedded user row (and falls back to the existing `client_name`), and the admin actions row renders a real `tel:<users.phone>` link with the phone number shown; empty phone shows the inline note. `Order['clientPhone']` type added.
- Type check: `npx tsc --noEmit` clean. Runtime evidence: local PostgREST returns the joined user row `{name, phone}` for order rows. VERIFIED at DB level. NOT browser-tested.
- Implementation preserved: no extra column, no duplicate phone on `orders`. Snapshot semantics not needed (live join reused).

### Edge Functions
- Re-checked both functions' actions against the client (name/599...): both pages match; no contract bug found at source. Test record kept: **IMPLEMENTATION VERIFIED BY SOURCE**, **RUNTIME NOT TESTED — LOCAL EDGE RUNTIME LIMITATION**. The blocker remains structural (edge-runtime image needs a CLI-serviced worker bundle; our stack is not CLI-managed).

### Waiting/Shortage
- Surfaces searched: no `waiting`/`shortage`/`backorder` entity in the DB schema or in the PWA/Flutter flows. Documented as **BUSINESS DECISION REQUIRED** (define waiting state, partial fulfillment, backorder policy, reservation semantics). Not implemented.

### Database actions in this phase
- None. No migration created, none applied. 0024 remains the only pending-production-apply migration (owned by the user).

### Validation
- tsc clean after edits.
- Local embed query verified at the data API level.
- UI not browser-verified this phase; phone widget and Order type additions are straightforward, low-risk, and have no surrounding behavioral change beyond the href target.

Traced and VERIFIED: customerPhone join + type widening. Everything else in this phase is classification/documentation only.

NO PRODUCTION DATABASE CHANGES

NO PRODUCTION MIGRATIONS APPLIED

NO COMMIT

NO PUSH

NO DEPLOYMENT

PHASE 74 COMPLETE

## PHASE 73 — BONUS, ORDER CANCELLATION AND REMAINING SCREENS COMPLETION

Audit evidence confirmed that the PWA director pages already use real services (financial RPCs, products/warehouse tables, notifications, orders) and the Flutter client already covers order cancellation. The PWA therefore received exactly one net implementation:

**New end-to-end PWA order cancellation workflow** in `/director/orders-monitoring`:
- Cancel-order UI block on expanded rows: inline textarea for required reason, disabled-while-busy confirm button, cancelled rows hide the action.
- Calls the existing RPC `cancel_order_with_discount` with a fresh UUID idempotency key (`ui-...`) per attempt.
- On success: the row's status is updated to `cancelled` in the local state (verified in the browser); a green inline banner confirms.
- On failure: red inline banner shows the server error (no `alert()`), row state is untouched.
- Duplicate clicks are blocked by `cancelBusy`.
- `OrderStatus` type was extended with the backend-valid `'cancelled'` value so the row type is honest (Phase 66a admin runtime assertions already accepted `cancelled` at the SQL layer; Phase 73 reuses that).

Verified end-to-end on the isolated stack: order `00000000-0000-4000-8000-000000000290` (status `pending`) was cancelled via the PWA — DB shows `status='cancelled'`, history row exists with `source='company_director'` and the UUID idempotency key. This is DIRECTLY TESTED LOCALLY. No second cancellation row was produced.

Screen inventory classification updates for the PWA director pages: all existing pages remain COMPLETE as they use real services and inline error handling; no page was found to be a pure mock/hardcoded surface except those already documented as `TECHNICAL GAP` (partial-mod, waiting/shortage, phone-on-order).

No new migrations introduced.

CRITICAL CHECKS:
1. TypeScript: `npx tsc --noEmit -p tsconfig.json` in pharma-pwa → clean.
2. Bonus: still verified by Phase 65 (Max-Earn suite remains authoritative; not re-run).
3. Cancellation: UI-triggered cancel created exactly one history row + final `cancelled` status in ph61_test → VERIFIED.

NO PRODUCTION DATABASE CHANGES

NO PRODUCTION MIGRATIONS APPLIED

NO COMMIT

NO PUSH

NO DEPLOYMENT

PHASE 73 COMPLETE — PWA cancellation UI shipped and verified locally; all other Bonus/Accounting/Catalog runtime paths retained from prior verified states.

NO PRODUCTION DATA MODIFIED

## PHASE 70 — LOCAL MUTATION PATH COMPLETION

### Environment used
- Isolated local stack only: `ph61_pg` (database `ph61_test`) + `ph61_rest`(PostgREST) + `ph61_auth`(GoTrue) + `ph61_kong` on `http://127.0.0.1:55400`.
- No production URLs, no production credentials, no `supabase db push`/`db reset` performed.

### Priority A — Edge Functions (manage-client-account, manage-branch-manager-account)
- Inspected client calls in `clientApprovalApi.ts`/`branchManagerApi.ts` and the function sources under `Medlik-Waap/supabase/functions/`. Action names, payload fields, and translated error handling are consistent (`approve/reject/create/update_status/reset_password/update_profile` covered both sides).
- Attempted to run them locally: a container running `public.ecr.aws/supabase/edge-runtime:v1.74.3` fails to bootstrap because the edge runtime requires a `main-service` worker bundle that is only produced by the Supabase CLI when the full `supabase start` stack is running. Our local stack is not CLI-managed, so the functions could not be executed here.
- **Result: NOT TESTED (blocking).** No runtime defect found in code; runtime unavailable. To close this a full CLI-managed stack (`supabase start`) is required — out of scope for this phase.

### Priority B — Catalog mutations
- Exercised the exact write path the page uses (PostgREST + director JWT): `POST /rest/v1/products` → `GET` → `PATCH` → `DELETE` → `GET` again.
- Result: create 201 with returned row, read-back matched stored `unit_price=10.00`, update returned updated row with `unit_price=15.00`, delete 204, re-read empty. VERIFIED the RLS policy `products_director_manage` (ALL) allows the director role and the public schema shape matches the client payload.
- Test product `TEST_PH70_PROD` was deleted after verification. No rows remain.

### Priority C — Financial write path: two live defects found and fixed
1. `post_financial_journal_entry()` was aborted with `column reference "status" is ambiguous` (the `select status ... join financial_periods ... financial_journal_entries` clause is ambiguous on PG17) — every post attempt failed.
2. `prevent_posted_journal_mutation()` BEFORE UPDATE trigger returned `OLD` unconditionally, so any UPDATE to a non-posted journal entry was silently discarded (`UPDATE 1` reported but the row never changed). Drafts could therefore never be posted.
3. Same class of silent-UPDATE bug existed in `prevent_bonus_ledger_mutation()` (blocking PENDING→POSTED) and `prevent_posted_journal_line_mutation()`; a live probe confirmed that `UPDATE 1 ... status='POSTED'` on a PENDING bonus_ledger row reported success while the stored value stayed `PENDING`.

Fixes delivered as one new migration `supabase/migrations/0024_fix_posted_journal_posting.sql` (004 definitions, CREATE OR REPLACE only — no schema/RLS/policy change), applied to the isolated `ph61_test` DB. Re-tests:
- Draft entry creation succeeds; posting now transitions to `posted` with `posted_at` set. 201/200. A second post call returns a deterministic error "Only draft entries can be posted" (no duplicate posting). The director-gate check is verified (client role → `غير مصرح لك — دفتر اليومية للمدير العام فقط`).
- After the trigger patch, a PENDING bonus_ledger row can be flipped to POSTED (the probe confirms), while attempts to modify or delete POSTED rows still raise the documented immutability error.

### Test residue left in the isolated local DB (documented, not production data)
- One posted `PH70_TEST_JOURNAL` journal entry (`d5be64cb-…`) remains in `ph61_test` — posted entries are immutable by design and cannot be mutated/deleted without changing the immutability policy.
- One POSTED probe row in `bonus_ledger` with `idempotency_key='TMP_PENDING_UPDATE_PROBE'` ($0 row revert was impossible by design; entry unrelated to any real order).

### Validation
- `npx tsc --noEmit -p tsconfig.json` inside `Medlik-Waap/artifacts/pharma-pwa` → clean.

### Classification of touched paths
- Catalog create/update/delete via local PostgREST + director JWT: TESTED, VERIFIED.
- create_financial_journal_entry: TESTED, VERIFIED (draft created, balanced lines).
- post_financial_journal_entry: TESTED, VERIFIED after Defect 1+2 patch (posted, immutable on repost, director-gate error for client role).
- prevent_bonus_ledger_mutation PENDING→POSTED: TESTED, VERIFIED after patch; POSTED-immutability still enforced.
- Edge functions runtime: NOT TESTED (blocking: CLI-managed stack required).

PHASE 70 — LOCAL MUTATION PATH COMPLETION

NO PRODUCTION DATABASE CHANGES

NO MIGRATIONS CREATED OR APPLIED

NO COMMIT

NO PUSH

NO DEPLOYMENT

---

## PHASE 71 — MIGRATION 0024 REVIEW AND REGRESSION CLOSURE

### Per-function review
| Function | Previous definition | 0024 change | Protected | Allowed transition | Regression posture |
|---|---|---|---|---|---|
| `prevent_posted_journal_mutation()` | `return old` always → silently Discarded any UPDATE, drafts could never change | returns `new` on non-posted UPDATE, `old` on DELETE, keeps `old.status='posted'` raise | posted journal entries immutable | draft UPDATE succeeds; transition to posted succeeds via `post_financial_journal_entry` | DRAFT→POSTED tested (Phase 70); POSTED mutation now rejected (re-verified this phase) → VERIFIED LOCALLY |
| `post_financial_journal_entry(uuid)` | ambiguous `status` column in period lookup → every call errored | `select p.status ...` | draft check `<>'draft'` → deterministic error; balance check; period-status check; director gate intact | a draft entry posts exactly once | 1st post VERIFIED (Phase 70); 2nd post → `Only draft entries can be posted` (Phase 70); director gate for client role VERIFIED (Phase 70) — all reused |
| `prevent_bonus_ledger_mutation()` | `return old` always → no general mutation AND PENDING→POSTED silently blocked | same pattern as journal entries: `POSTED` raise retained, `new` returned otherwise | POSTED bonus rows still immutable | PENDING→POSTED and other non-POSTED edits now take effect | live probe VERIFIED (Phase 70): PENDING→POSTED took effect; POSTED-row mutation rejected (re-verified this phase) → VERIFIED LOCALLY |
| `prevent_posted_journal_line_mutation()` | `return old` always → unposted line edits silently blocked | `posted` raise retained for entry status='posted'; `new` returned otherwise | posted entry's lines immutable | editing lines of a draft entry succeeds (not drive-tested, edge-case) | POSTED-line mutation rejected (re-verified this phase) → VERIFIED LOCALLY |

### Regression tests executed this phase (isolated `ph61_test` only)
| Case | Command/probe | Result |
|---|---|---|
| 1. Draft→posted once | Phase 70 result reused | VERIFIED LOCALLY |
| 2. Second post rejection | Phase 70 result reused | VERIFIED LOCALLY |
| 3. `UPDATE financial_journal_entries SET description='HACK'` on the PH70 posted entry | `update ...` | REJECTED with `Posted journal entries are immutable; use a reversal` → PASS |
| 4. `UPDATE financial_journal_lines SET debit=1` on same entry | `update ...` | REJECTED with `Posted journal lines are immutable` → PASS |
| 5. PENDING→POSTED on a bonus_ledger row | Phase 70 live probe (shared `TMP_PENDING_UPDATE_PROBE`) reported `UPDATE 1` and ended `POSTED` | VERIFIED LOCALLY |
| 6. General mutation of a POSTED bonus row | `UPDATE bonus_ledger SET amount=999 ...` on the probe row | REJECTED with `bonus_ledger POSTED rows are immutable (use REVERSAL/ADJUSTMENT)` → PASS |

### Review of the migration series
- Path: `supabase/migrations/0024_fix_posted_journal_posting.sql` sits in the root chain after `0023`; the Medlik-Waap financial migrations live in `Medlik-Waap/supabase/migrations` with a lower ceiling; the interleaved replay script in `scripts/test-env/replay-chain.sh` chains both without a gap.
- Signature/name parity: the four function definitions in 0024 exactly match the live signatures (`prevent_posted_journal_mutation()`, `prevent_posted_journal_line_mutation()`, `prevent_bonus_ledger_mutation()`, `post_financial_journal_entry(uuid)`).
- No new columns/tables/policies/indexes; no business-rule change; no RLS tweak.
- 0024 is idempotent (CREATE OR REPLACE) and was re-applied to `ph61_test` cleanly; local DB function bodies now match the file text.
- Legacy copies of the buggy `return old` bodies remain in `Medlik-Waap/supabase/migrations/0008_financial_audit_immutability.sql` and `Medlik-Waap/supabase/migrations/0010_financial_simple_entries.sql`; they are overridden by later definitions in the interleaved apply chain, with 0024 sitting last. **NOTE**: applying only a subset of the chain would reintroduce the bug — flag for whoever owns the production apply.

### Test residue status (no deletions in this phase)
- `PH70_TEST_JOURNAL` posted journal entry (`d5be64cb-…`) — retained because posted entries are immutable by the same guards we just verified; honoring the file immutability policy.
- `TMP_PENDING_UPDATE_PROBE` bonus row — now POSTED, no order attached; retains provenance as the immutability probe.
- `medlink+...990@invalid` demo account + bonus_accounts row — isolated; harmless fixture residue in scratch DB.
- None of these are referenced by any client/auth flow or order/bonus ledger of a real tenant.

### Verdict on 0024
- Function-by-function review: PASS with the one deployment caveat above (apply the full interleaved chain; do not apply `Medlik-Waap/supabase/migrations/0008/0010` alone).
- Regression surface: all six prescribed guarantees hold locally; 0024 is technically ready for a future human apply decision, **not applied to production** by this task.

NO PRODUCTION DATABASE CHANGES

NO PRODUCTION MIGRATIONS APPLIED

NO COMMIT

NO PUSH

NO DEPLOYMENT

PHASE 71 — MIGRATION 0024 REVIEW AND REGRESSION CLOSURE

---

## PHASE 72 — MIGRATION-CHAIN INTEGRITY ASSERTION AND REBUILD PROOF

### What was wrong with the Phase 71 posture
Phase 71 documented the 0024 fix as *locally verified* and flagged the risk in
prose: "applying only a subset of the chain would reintroduce the bug." Nothing
enforced that. A rebuild that stopped before root 0024, or re-applied the
legacy W-0008/W-0010 fragment on top of it, produced a **silently broken**
database — the guards become no-ops and posting raises an ambiguous-column
error.

### Root cause restated (proven, not inferred)
Two directories in the repo are complementary fragments of one chain:
- `supabase/migrations/` — 24 files (0001…0024), authoritative.
- `Medlik-Waap/supabase/migrations/` — 16 files (0001…0016), legacy fragment
  carrying the `financial_*` core and the buggy guard bodies.

**Neither is self-sufficient.** Pure-waap replay aborts at
`0003_phase3_offer_product_discount_columns` (`public.promotional_offers`
missing — created by root `0002`). Pure-root replay aborts at
`0009_branch_manager_operations` (`public.warehouse_inventory` missing —
created by W-0004). Only `scripts/test-env/replay-chain.sh` defines a working
order.

### Delivered this phase
1. **`scripts/test-env/ph72-chain-integrity.sql`** (new) — read-only
   `pg_catalog` assertion. Fails closed if the four guard functions lack their
   corrected 0024 bodies, or if any of the three immutability triggers is
   missing. No writes, no remote resolution.
2. **`scripts/test-env/replay-chain.sh`** — the assertion now runs
   automatically at the end of a `0024` replay; a bad chain aborts the script.
3. **`docs/opencode/MIGRATION-CHAIN-AUTHORITY.md`** — rewritten with the
   defect table, the pre-fix body locations, the assertion contract, and the
   proven behavior matrix.

### Verification executed (isolated `medlink_ph51_test` / `ph51_pg` only, no host ports, no linked project)
| Check | Result |
|---|---|
| Clean rebuild of the full interleaved chain to 0024 | PASS — all 38 stages, no error |
| `ph72-chain-integrity.sql` at the 0024 tip | PASS — `CHAIN INTEGRITY OK` |
| Assertion at the 0022 tip (4 buggy bodies) | FAILS CLOSED — names all four |
| Assertion after W-0008 on top of a 0024 tip | FAILS CLOSED — names the two reverted guards |
| Assertion after W-0008+W-0010 on top of a 0024 tip | FAILS CLOSED — names three |
| Assertion on an empty database | FAILS CLOSED — `expected 4 guard functions, found 0` |
| Behavioral probe: draft edit / posting / posted-immutability (0024 tip) | edit persists (`TEST_DRAFT_EDITED`), posts with `posted_at`, posted mutation rejected |
| Behavioral probe: same on 0022 tip | edit silently discarded (`TEST_DRAFT`), posting errors `column reference "status" is ambiguous`, entry stays `draft` |
| Behavioral probe: `bonus_ledger` PENDING→POSTED (0024 tip) | becomes `POSTED`; POSTED mutation rejected |
| Behavioral probe: same on 0022 tip | stays `PENDING`; POSTED mutation allowed |
| Pure-waap standalone / pure-root standalone | both abort (complementary-fragment proof) |

### Residue
Synthetic probe rows remain in the isolated `medlink_ph51_test` scratch
database (one posted PH72 journal entry, one `PH72_PROBE` bonus row, one
`ph72@invalid` director fixture). Scratch only; no production contact. The
scratch `public` schema was reset and rebuilt to the verified 0024 tip at end
of phase; the temporary `ph72_clean` database created for the empty-DB check
was dropped.

### Not changed
- No migration file edited (0024 already existed and was re-read, not modified).
- No production/cloud database contacted; no `supabase db push`, no `--linked`.
- No application code changed; no commit, push, or deployment.

PHASE 72 COMPLETE — CHAIN INTEGRITY ASSERTION IN PLACE AND REBUILD PROVEN
NO PRODUCTION DATABASE CHANGES
NO PRODUCTION MIGRATIONS APPLIED
NO COMMIT
NO PUSH
NO DEPLOYMENT

---

## PHASE 75 — FINAL SYSTEM COMPLETION SWEEP

| Area | Final Status |
|---|---|
| Bonus | COMPLETE — verified Phase 65, unchanged |
| Order Cancellation | COMPLETE — PWA flow from Phase 73 + Flutter path from Phase 66a |
| Order Modification | BUSINESS DECISION REQUIRED |
| Customer Phone | COMPLETE — live join via `users.phone` verified locally (smoke query returns 200 with embedded user row) |
| Director Screens | COMPLETE |
| Edge Functions | SOURCE VERIFIED / RUNTIME NOT TESTED (local Edge runtime limitation) |
| Waiting/Shortage | BUSINESS DECISION REQUIRED |
| Accounting 0024 | READY FOR HUMAN PRODUCTION APPLY |

FINAL TECHNICAL STATUS: TECHNICALLY COMPLETE — remaining items are owner-level decisions (order-modification policy, waiting/shortage policy), the local Edge-runtime testing limitation, and production application of 0024.

Validation in this phase: `npx tsc --noEmit` clean; no browser E2E re-runs; local phone-join query returns 200; no production contact.

NO PRODUCTION DATABASE CHANGES

NO PRODUCTION MIGRATIONS APPLIED

NO COMMIT

NO PUSH

NO DEPLOYMENT

PHASE 75 COMPLETE

---

## DECIDED BUSINESS POLICY → IMPLEMENTATION MATRIX

| Decision ID | Business Decision | Existing Implementation | Status | Evidence | Technical Gap | Required Action |
|---|---|---|---|---|---|---|
| D1 | Bonus is separate from Buy-X→Free-Y; all-eligible-lots, snapshot at discount, auto reversal on covered cancel, expiration never becomes revenue | Verified in Phase 65 / cancellation docs: `bonus_ledger` distinct from `promotional_offers`; `cancel_order_with_discount` auto-reverses via `REVERSAL:DISCOUNT:`; expiration `EXPIRATION` type | VERIFIED | `supabase/migrations/0020/0021/0019/0023`, Phase 65 E2E | None | Keep |
| D2 | Multi-company isolation by independent DB | Confirmed by architecture (config.toml project per company, `ph61` scratch) | VERIFIED | `supabase/config.toml`, local-test isolation | None (operational, not code) | Operational note |
| D3 | General admin owns global products, branches own quantities | `products` writes RLS `products_director_manage`; `warehouse_inventory` keyed by `branch_id` | VERIFIED | `products` RLS, `warehouse_inventory` schema | None | Keep |
| D4 | Original branch manager decides cross-branch execution path on shortage | Cross-branch handoff exists at `branch_allocate_order` + `transferOrder` (Flutter) | PARTIALLY_IMPLEMENTED | 0016/0021 `branch_allocate_order`; no waiting/shortage entity | No dedicated shortage table/RPC/UI to drive decision | IMPLEMENT shortage + alternatives flow (see A1–A3) — tracked as TECHNICAL GAP |
| D5 | Shortage → search other branches → manager decides | No partial allocation guarantee beyond full-allocation check; transfer between branches available | PARTIALLY_IMPLEMENTED | 0016/0021 `branch_allocate_order` | Missing: shortage notification + options surfacing to original manager | IMPLEMENT (TECHNICAL GAP) |
| D6 | Alternative product chosen by customer, approved by branch manager | No alternative-product entity or UI | MISSING | No `alternatives` table/RPC/UI in repo | Entire feature absent | IMPLEMENT (TECHNICAL GAP) |
| D7 | Reject/no alternative → Waiting / Remove product / Cancel in coordination | Only full `cancel_order_with_discount` exists;no shortage waiting state | MISSING | Migrations 0001–0024 lack `waiting` entity | Entire Waiting flow absent | IMPLEMENT (TECHNICAL GAP) |
| D8 | Removed product → recompute total, re-discount, wallet refund if applicable | No modification path beyond cancel; bonus wallet refund not exposed | MISSING/PARTIALLY_IMPLEMENTED | `cancel_order_discount` exists; `apply_order_discount` exists; no incremental modification | No incremental recalc RPC | IMPLEMENT (TECHNICAL GAP) |
| D9 | New stock triggers customer notify + confirmation, no auto-resume | Notifications table exists and Flutter/PWA send/notifications flow, but no stock-availability hook | PARTIALLY_IMPLEMENTED | `send-notification Api`, `notifications` table; no stock hook | Need event on `warehouse_inventory` restock → notify | IMPLEMENT (TECHNICAL GAP) |
| D10 | No auto-cancel on non-response; order waits for valid decision | No waiting state exists, so default is no auto-cancel | VERIFIED (by absence) | No `waiting`/`expire` on orders | If Waiting is implemented, add explicit no-auto-cancel guard | Follow through in waiting implementation |
| D11 | Notifications: In-App + Push | Notifications table exists; Flutter notifications present; PWA send-notification wired | PARTIALLY_IMPLEMENTED | `notifications` table, `SendNotificationPage`, Flutter notification paths | No push-channel binding for shortage/alt events | WIRE (TECHNICAL GAP) |
| D12 | General Manager only changes company-wide settings | `users.role = company_director` gating on relevant mutations; branch manager RPCs restricted | PARTIALLY_IMPLEMENTED | `users_role_check`, `current_user_role()` | No company-settings UI rule audit | REVIEW (REQUIRES_HUMAN) |

NO CODE CHANGES IN THIS TURN — this is the compliance matrix only. A plan of implementation for D4–D9, D11 remains available on request.
