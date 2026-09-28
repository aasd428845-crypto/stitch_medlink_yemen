# PHASE 10 — DIRECTOR BONUS UI IMPLEMENTATION (batch 1)

## A. Files read
- `docs/opencode/PHASE-9-BONUS-UI-ARCHITECTURE.md` (full)
- `Medlik-Waap/artifacts/pharma-pwa/src/App.tsx` (routes line 34)
- `layouts/DirectorLayout.tsx` (navItems 38-56, icon imports)
- `pages/director/ExpensesPage.tsx` (full — reference pattern)
- `pages/director/BonusOverviewPage.tsx` + `lib/bonusRulesApi.ts` (legacy model boundary)
- `components/{KPICard,ConfirmDialog,LoadingSpinner,ErrorMessage}.tsx` (props verified)
- `supabase/migrations/0018_bonus_financial_system.sql` (tables/RPCs/RLS)
- `supabase/migrations/0019_bonus_earn_engine.sql` (`value_basis`, `product_values` columns)
- `lib/promotionalOffersApi.ts` (`listActiveProducts` reuse), `lib/branchManagerApi.ts` (branches/governorates)
- Skills: web-admin-dashboard, medlink-design-system, supabase-database, api-contracts (loaded)

## B. Files modified
- `Medlik-Waap/artifacts/pharma-pwa/src/App.tsx` (3 routes added)
- `Medlik-Waap/artifacts/pharma-pwa/src/layouts/DirectorLayout.tsx` (3 nav items + `Layers` icon import)

## C. Files created (new)
- `Medlik-Waap/artifacts/pharma-pwa/src/lib/bonusFinancialApi.ts` (API/repository layer)
- `Medlik-Waap/artifacts/pharma-pwa/src/pages/director/BonusFinancialDashboardPage.tsx`
- `Medlik-Waap/artifacts/pharma-pwa/src/pages/director/BonusLedgerPage.tsx`
- `Medlik-Waap/artifacts/pharma-pwa/src/pages/director/BonusRulesV2Page.tsx`
- `docs/opencode/PHASE-10-DIRECTOR-BONUS-IMPLEMENTATION.md` (this report)

## D. API/Repository implementation
`bonusFinancialApi.ts`: typed rows for ledger/rules_v2; reads (`listLedger`, `listBonusAccounts`, `getAccountFunds` via `bonus_account_funds` RPC, `list/getBonusRulesV2`); writes via director RLS (`create/updateBonusRuleV2`, `setBonusRuleV2Status`) and security-definer RPCs (`earn_bonus`, `reverse_bonus_txn`, `expire_bonus`). Separate file from legacy `bonusRulesApi.ts` — models never mix. Two self-found bugs fixed during build: explicit-null `p_asof` override (now omitted) and over-complex update merge (now full-object, matching `promotionalOffersApi` pattern).

## E. Dashboard
`BonusFinancialDashboardPage` (`/director/bonus-fin/dashboard`): 4 KPICards (earned/spent-outstanding/pending+reserved/accounts) computed from ledger rows + account funds; KPI cards link to ledger; recent-8 table links to full ledger; refresh button. No charts (transactional data, decoration avoided).

## F. Ledger
`BonusLedgerPage` (`/director/bonus-fin/ledger`): type/status/search filters, table, detail dialog (all link fields), reverse-via-`reverse_bonus_txn` with mandatory reason (ConfirmDialog + inline textarea — verified component has no reason props, so composed via `message` ReactNode).

## G. Rules V2
`BonusRulesV2Page` (`/director/bonus-fin/rules`): list/search/status filter; create/edit modal covering all schema fields (type/basis-derivation/value/percent/max/priority/dates/minimums/usage/products include-exclude with exclusion-wins note/per-product values/governorate from branches/cash fields/permissions); UI validation mirrors DB trigger (MONETARY xor, GENERAL constraints, dates, ranges); status actions active/suspend/archive with confirm.

## H. RPCs used
`bonus_account_funds`, `earn_bonus`, `reverse_bonus_txn`, `expire_bonus` (+ direct table reads/writes where RLS `director_manage`/`director_select` allow). No invented RPCs.

## I. Tables used
`bonus_ledger`, `bonus_accounts`, `bonus_rules_v2` (+ `products`, `branches` for pickers). Legacy `bonus_rules` untouched.

## J. Permissions/RLS
Director-only routes (existing `ProtectedRoute`); all writes go through granted RPCs or director policies; RLS verified in migration files, no policy changes.

## K. Interactive UX
Clickable KPI cards → ledger; filters/search; detail dialog; confirm dialogs; refresh/retry; success banners; busy/disabled states. Every interaction hits real data.

## L. Loading/Empty/Error states
`LoadingSpinner`, `ErrorMessage`, per-table empty states, success banners, `alert()` for RPC failures (matches `ExpensesPage` pattern), form-level errors.

## M. Legacy Free-Y separation
Separate routes (`bonus-fin/*` vs `bonus-*`), separate API file, separate copy ("المحفظة المالية" vs "اشترِ واحصل"). Never touches `order_items.bonus_rule_id`.

## N. Business gaps (UNRESOLVED, safe behavior)
- `bonus_value` unit: displayed verbatim, never recomputed.
- Cancellation-after-full-consumption: only RPC transitions exposed.
- `customer_type`: free-text stored as-is, no targeting logic invented.

## O. Missing backend operations
Order Discount engine (no UI built — correct per plan).

## P. Tests
No web test suite exists in repo (no *.test.* under pharma-pwa) — none added (consistent with repo).

## Q. Build/Typecheck
- `pnpm run typecheck` (`tsc -p tsconfig.json --noEmit`): **PASS, 0 errors** (Node v22.23.2 via fnm; system Node v10 cannot run the toolchain — environment note).
- `pnpm run build` (`vite build`): **PASS in 17.57s** (chunk-size warning only, pre-existing pattern).
- Pre-existing issues: none encountered; dist/ output gitignored (not in status).

## R. Known limitations
- Dashboard totals computed client-side from fetched rows (exact at current scale; document recommends server aggregate RPC if ledger grows).
- Rules form has no per-customer picker (`eligible_customers` stays null) — no client-list API exists in web lib; documented, not faked.
- `customer_type` is free text (schema has no backing taxonomy).

## S. Suggested next step
Phase 11: redemptions/withdrawals management + pending/audit/settings (all RPCs already verified), then Flutter wallet batch.

---

**Summary**: modified 2 files, new 5 files (4 code + 1 report), 3 screens, 4 RPCs used (+ reads), 0 unsupported operations built, 3 business gaps (documented, safe), tests N/A (no suite), typecheck PASS, build PASS. **Final Verdict: BATCH 1 COMPLETE.**
