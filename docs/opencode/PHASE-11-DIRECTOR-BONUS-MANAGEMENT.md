# PHASE 11 — DIRECTOR BONUS MANAGEMENT SCREENS

## A. Files read
PHASE-9/10/10.1 reports; the 4 PHASE-10 files; `ExpensesPage` (pattern); `ConfirmDialog/KPICard/LoadingSpinner/ErrorMessage` (props); `DirectorLayout` nav + icons; `App.tsx` routes; `0018` RPC guards + table columns; `0019` pending columns; `promotionalOffersApi.listActiveProducts`, `branchManagerApi.listBranches`; skills web-admin-dashboard, medlink-design-system, supabase-database, api-contracts.

## B. Files modified
- `src/lib/bonusFinancialApi.ts` (extended: redemptions/withdrawals/pending/audit/settings)
- `src/App.tsx` (5 routes)
- `src/layouts/DirectorLayout.tsx` (5 nav items + 4 icon imports)

## C. Files created
- `src/pages/director/BonusRedemptionsPage.tsx`
- `src/pages/director/BonusWithdrawalsPage.tsx`
- `src/pages/director/BonusPendingPage.tsx`
- `src/pages/director/BonusAuditPage.tsx`
- `src/pages/director/BonusSettingsPage.tsx`
- `docs/opencode/PHASE-11-DIRECTOR-BONUS-MANAGEMENT.md` (this report)

## D. Redemptions
List w/ product join, status filter/search; actions gated by status exactly as RPC guards require (PENDING→approve/cancel, APPROVED→fulfill); detail dialog with ledger link + decision info; confirms + reason-free (RPC takes no reason) + refetch.

## E. Withdrawals
Full lifecycle buttons per status: PENDING→start/cancel; UNDER_REVIEW→approve/reject(reason modal)/cancel; APPROVED→pay(reference+receipt modal); PAID→complete. Detail dialog shows all 13 reviewed columns. Backend messages surfaced verbatim on failure.

## F. Pending Entitlements
Status filter (default PENDING), snapshot viewer (product/rule JSON + key/attempts/ledger link), single-row `bonus_process_pending` with confirm; PROCESSED rows preserved, never deletable in UI.

## G. Audit Trail
Read-only table + action filter + search + JSON detail (old/new values); no edit/delete affordances by construction.

## H. Settings
Lists only existing keys with friendly labels; JSON textarea editor with parse validation; direct update per `director_manage` policy (matches project pattern of direct RLS writes, no custom RPC exists).

## I. Backend RPC Mapping
approve/fulfill/cancel_redemption; start/review(+reason)/mark_paid(+ref)/complete/cancel_withdrawal; bonus_process_pending; list*/updateSetting reads. All verified against 0018/0019 signatures. No invented operations.

## J. Permissions/RLS
Director routes + director policies; writes exclusively via granted RPCs or director policies; RLS untouched.

## K. Status Transition Handling
UI buttons rendered only for states each RPC accepts (verified line-by-line against RPC guards); backend remains the enforcer (errors alerted, never hidden).

## L. Interactive UX
Status summaries in headers, filters/search, detail dialogs, confirms, reason/reference modals, refresh/retry, success banners, busy/disabled states. No charts (transactional lists; decoration avoided).

## M. Loading/Empty/Error States
Spinner/error/empty per table; form-level errors; RPC error alerts; success banners with auto-dismiss.

## N. Legacy Free-Y separation
No reference to `bonus_rules`/`bonus_rule_id` in any new file; separate `bonus-fin/*` routes and nav group placement.

## O. Business Gaps (UNRESOLVED, safe)
`bonus_value` unit (verbatim display); cancellation-after-full-consumption (RPC transitions only); `customer_type` (stored free text, no logic).

## P. Missing Backend Operations
None encountered in this batch — every planned action had a real RPC/policy.

## Q. Tests
No web test suite exists in repo — none added (consistent).

## R. Build/Typecheck
- `pnpm run typecheck`: **PASS, 0 errors** (Node v22 via fnm).
- `pnpm run build`: **PASS** (precache generated, chunk-size warning only, pre-existing pattern).

## S. Known Limitations
- Dashboard totals pattern reused from batch 1 (client-side aggregation note stands).
- Rules form has no per-customer picker (no client-list API in web lib).
- Settings editor is raw JSON (matches key/value schema; friendly labels added).

## T. Recommended Next Step
Phase 12: Flutter client wallet + history (read) then redeem/withdraw flows; Order Discount remains blocked on backend.

---

**Summary**: modified 3 files, new 6 files (5 code + 1 report), 5 screens, 13 RPC/policy operations used, 0 unsupported operations built, 3 business gaps (documented), tests N/A, typecheck PASS, build PASS. **Final Verdict: BATCH 2 COMPLETE.**
