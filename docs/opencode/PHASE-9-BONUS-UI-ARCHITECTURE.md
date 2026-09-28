# PHASE 9 — BONUS UI ARCHITECTURE AUDIT & SCREEN BUILD PLAN
> AUDIT + DESIGN PLAN ONLY — no code, no SQL, no RLS, no functions modified.
> Sources: local repo only (`medlink_app/`, `Medlik-Waap/artifacts/pharma-pwa/`, `supabase/migrations/0018*.sql`, `0019*.sql`, `.opencode/skills/`).

## A. Repository Architecture
- **Flutter app** (`medlink_app/`): screens by role (`auth/`, `client/`, `branch_manager/`, `driver/`, `shared/`), services layer (`*_service.dart` + controllers), `app_router.dart` (role-based routing: client/branchManager/driver/companyDirector-blocked), Supabase via `supabase_bootstrap.dart` (URL+anon key), models are Freezed+json.
- **Web Admin** (`Medlik-Waap/artifacts/pharma-pwa/`): React + react-router (`App.tsx`), `company_director`-only (`ProtectedRoute`, `AuthContext` ALLOWED_ROLE), `DirectorLayout` sidebar nav with groups, per-domain `*Api.ts` lib files calling Supabase directly.
- **Pattern rule**: new Bonus screens live in existing homes — Flutter: new tab/section under `client/` (+ shared widgets); Web: new `pages/director/Bonus*` + `lib/bonusFinancialApi.ts`, routes in `App.tsx`, nav in `DirectorLayout.tsx`. No new architecture.
- **Windows**: `medlink_app/windows|linux|macos` folders exist (Flutter desktop targets) but no Windows-specific UI code — Flutter screens are inherently cross-platform; no separate plan needed.

## B. Existing Design System (reuse, do not invent)
- **Flutter**: `utils/theme.dart` `AppColors` (dark-first navy `#071226`, cyan `#36C9F4`, teal `#71E0CA`, error/warning/success families); `widgets/medlink_design.dart` + `stat_card.dart`, `order_status_chip.dart`, `error_banner.dart`, `app_primary_button.dart`, `app_text_field.dart`; `client/client_design.dart` for client surfaces. Arabic RTL via l10n.
- **Web**: Tailwind + shadcn-style `components/ui/` (~30 primitives: button, card, dialog, table, badge, select, input, tabs, skeleton, empty...), plus `KPICard`, `StatusBadge`, `LoadingSpinner`, `ErrorMessage`, `ConfirmDialog`, `components/director/` panels. Cairo font, RTL.
- States available in both: loading spinner/skeleton, error banner/message, empty table states exist per-page (verify per screen during build).

## C. Existing Related Screens
- **Web director** (`pages/director/`): `BonusOverviewPage` + `BonusRules/New/EditBonusRule` (all bound to LEGACY `bonus_rules` table via `lib/bonusRulesApi.ts` — buy_X/free_Y model), `Financial*` (5 pages), `ReceivablesPage`, `OrdersMonitoringPage`, `DashboardPage`. Nav groups in `DirectorLayout.tsx:38-56` (المركز/التشغيل/النمو/المخاطر/المالية).
- **Flutter client**: 4 tabs (`HomeTab/CatalogTab/OrdersTab/AccountTab` in `client_home_shell.dart:30`); `AccountTab` = wallet host candidate; `OrdersTab`/`order_detail` = discount display candidate; cart/checkout = earn visibility candidate.
- **No screen today touches financial bonus tables** (`bonus_accounts/ledger/rules_v2/...`) — verified: zero references in `medlink_app/lib` and `pharma-pwa/src` outside legacy `bonus_rules`.

## D. Bonus Backend Inventory (from 0018/0019 files + live RLS)
- **Tables**: `bonus_accounts`, `bonus_ledger`, `bonus_rules_v2`, `bonus_redemptions`, `bonus_withdrawals`, `bonus_settings`, `bonus_audit_trail`, `bonus_earn_allocations` (0018) + `bonus_pending_entitlements` (0019).
- **Client-callable RPCs** (granted to `authenticated`, role-checked inside): `bonus_account_funds`, `request_redemption`, `cancel_redemption`, `request_withdrawal`, `cancel_withdrawal`. Director-only inside: `open_bonus_account`, `post_opening_balance`, `post_legacy_migration`, `earn_bonus`, `approve/fulfill_redemption`, `start/review/mark/complete_withdrawal`, `reverse_bonus_txn`, `expire_bonus`, `bonus_process_pending`. Internal: `bonus_allocate_spend`, `bonus_credit_remaining`, `bonus_evaluate_order_earn`, validators, trigger fns.
- **RLS**: client `SELECT` own rows (`account_id = auth.uid()`); director full select/manage; settings readable when authenticated; direct writes effectively RPC-only (no insert/update/delete policies for clients on financial tables).
- **Statuses (from schema, use verbatim)**: redemptions `PENDING/APPROVED/REJECTED/FULFILLED/CANCELLED`; withdrawals `PENDING/UNDER_REVIEW/APPROVED/REJECTED/PAID/COMPLETED/CANCELLED`; ledger `POSTED/PENDING`; accounts `active/suspended` × mode `NONE/OPENING_BALANCE/LEGACY_MIGRATION/SALES`; rules_v2 `active/suspended/archived`.
- **Legacy Free-Y** stays on `bonus_rules` + `order_items.bonus_rule_id` — untouched.

## E. Role & Permission Matrix
| Role | UI home | Bonus read | Bonus write path |
|---|---|---|---|
| client (Flutter) | AccountTab/wallet | own account/ledger/history (RLS) | request/cancel redemption+withdrawal RPCs only |
| company_director (Web) | new Bonus section | all (RLS) | all lifecycle RPCs (approve/review/pay/post/reverse/expire/process) |
| branch_manager/driver | — | — | none (no bonus UI) |

## F. Director Screens (new, `pages/director/Bonus*`)
1. `BonusFinancialDashboardPage` — totals (earned/redeemed/withdrawn/pending/reserved via `bonus_account_funds` aggregates + recent ledger). **Outstanding liability**: COMPUTABLE (sum available across accounts) — allowed.
2. `BonusRulesV2Page` (+New/Edit) — CRUD on `bonus_rules_v2` (direct table writes permitted by `director_manage` policy; validation trigger exists DB-side).
3. `BonusLedgerPage` — read-only ledger table w/ filters.
4. `BonusRedemptionsPage` — list + Approve/Fulfill/Reject(cancel) via RPCs.
5. `BonusWithdrawalsPage` — list + start_review/review/mark_paid/complete/cancel via RPCs.
6. `BonusPendingPage` — pending list + `bonus_process_pending` (director).
7. `BonusAuditPage` — read-only audit trail.
8. `BonusSettingsPage` — `bonus_settings` key/value editor (only keys present in schema).
9. Keep legacy `BonusOverview/Rules` pages untouched (different table/model).

## G. Client Screens (Flutter, `screens/client/`)
1. **Wallet section** in `AccountTab` (or new 5th tab only if tab bar allows — default: section): balance/available/reserved via `bonus_account_funds`; history via ledger select; uses `stat_card.dart` + theme tokens.
2. **Redemption flow**: product picker → `request_redemption` → status tracking → `cancel_redemption` while PENDING.
3. **Withdrawal flow**: amount form → `request_withdrawal` → status tracking → `cancel_withdrawal` while PENDING/UNDER_REVIEW.
4. **History screen**: ledger entries list (read-only).
5. **Order Discount**: **NO UI** — no completed backend workflow exists (no discount RPC/engine in 0018/0019) — building it would fake success.

## H. Screen → Backend Mapping
| Screen | Data Source | RPC | RLS Role | Write Operation |
|---|---|---|---|---|
| Fin.Dashboard | `bonus_ledger` select + `bonus_account_funds` | none (read) | director | none |
| RulesV2 CRUD | `bonus_rules_v2` direct | none | director_manage | direct insert/update (policy allows) |
| Ledger | `bonus_ledger` select | none | director/client-own | none |
| Redemptions mgmt | `bonus_redemptions` select | approve/fulfill/cancel_redemption | director | RPC only |
| Withdrawals mgmt | `bonus_withdrawals` select | start/review/mark/complete/cancel | director | RPC only |
| Pending | `bonus_pending_entitlements` select | `bonus_process_pending` | director | RPC only |
| Audit | `bonus_audit_trail` select | none | director/own | none |
| Settings | `bonus_settings` | none (direct per policy) | director manage | direct update |
| Client wallet/history | `bonus_account_funds` + ledger select | none | client-own | none |
| Client redeem/withdraw | forms | request_*/cancel_* | client | RPC only |
| Order Discount UI | — | — | — | **NOT IMPLEMENTED — UI MUST NOT FAKE SUCCESS** |

## I. Navigation Plan
- Web: extend `navItems` in `DirectorLayout.tsx` (new group or under النمو/المالية) + routes in `App.tsx` (`bonus-fin/*`); breadcrumbs via existing `getPageTitle` (line 68 pattern).
- Flutter: wallet as `AccountTab` section (no router change); history/redemption/withdrawal as pushed routes following `order_detail_screen` precedent; no tab-bar change unless approved.

## J. Responsive Plan
- Web: existing Tailwind grid (`grid-cols-1 sm:2 lg:4` as in BonusOverview) + tables with `overflow-x-auto` — reuse.
- Flutter: same widgets render on Android/iOS/desktop/web/Windows (no separate layouts in repo) — reuse `medlink_design` responsive patterns.

## K. UX States (per screen)
loading (spinner/skeleton) / empty (table empty-state) / error (banner + retry) / permission-denied (router guard + message) / success (confirm + refetch, never optimistic-fake) / pending (status chips from schema values) / disabled (invalid form state) / retry (refetch buttons).

## L. Legacy Free-Y Separation
UI labels must distinguish: legacy = "عروض البونص/اشترِ واحصل" (`bonus_rules`, `order_items.bonus_rule_id`); financial = "محفظة/رصيد البونص" (`bonus_ledger`, rules_v2). Separate pages, separate API files (`bonusRulesApi.ts` vs new `bonusFinancialApi.ts`), never shared components that mix the models.

## M. Business Gaps Affecting UI
- `bonus_value` unit: UNRESOLVED — redemption value display must show stored `bonus_value` verbatim, never recompute.
- Cancellation-after-full-consumption: UNRESOLVED — UI exposes only RPC-available transitions; no custom cancel-full-consumed button.
- `customer_type`: UNRESOLVED — rules UI must not offer customer-type targeting beyond schema fields.

## N. Missing Backend Operations (do not build UI for these)
Order Discount apply/settle RPCs; earn-rule evaluation UI triggers (auto only); GL posting bridge; reversal UI beyond `reverse_bonus_txn` (exists — usable); expiration controls beyond `expire_bonus` (exists — usable).

## O. Implementation Order
1. `lib/bonusFinancialApi.ts` (reads + RPC wrappers, mirroring `bonusRulesApi.ts` style). 2. Director read screens (Dashboard/Ledger/Audit/Pending). 3. RulesV2 CRUD. 4. Redemptions/Withdrawals management. 5. Settings. 6. Flutter wallet+history (read). 7. Flutter redeem/withdraw flows. 8. (Deferred) Discount UI — blocked on backend.

## P. Risks
- Fake-success risk if any button lacks RPC (mitigated by mapping §H).
- Legacy/financial model confusion in UI copy (mitigated by §L).
- RLS drift: UI must never use direct writes where policy denies (all writes via granted RPCs above).
- `bonus_value` unit ambiguity in display (show stored values only).

## Q. FINAL VERDICT
**AUDIT COMPLETE — READY FOR SCREEN BUILD PLAN**: 9 director screens (8 new + legacy untouched) + 4 client surfaces proposed; every action maps to an existing RPC/policy except Order Discount (explicitly excluded); build can start without backend changes, in order §O.
