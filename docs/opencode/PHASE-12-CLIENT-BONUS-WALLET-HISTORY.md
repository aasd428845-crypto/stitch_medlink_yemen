# PHASE 12 — CLIENT BONUS WALLET & HISTORY

## A. Client Architecture
Flutter role tabs (`client_home_shell.dart:30` — Home/Catalog/Orders/Account); services (`*_service.dart` + `ChangeNotifier` controllers) registered in `main.dart` MultiProvider; go_router nested `/client/*` routes; Supabase via `supabase_bootstrap.dart`; l10n via arb + generated localizations (flutter snap blocked, so new keys added to arb files AND mirrored manually in generated dart files following exact generator patterns).

## B. Files read
PHASE-9/10/10.1/11/11.1 reports; `account_tab.dart`, `orders_tab.dart` (list/error/retry pattern), `order_detail_screen.dart`, `order_service.dart` (SUPABASE_DEBUG pattern), `order_controller.dart` (controller pattern), `app_router.dart`, `main.dart`, `client_design.dart` (`ClientCard/IconBadge/SectionTitle`), `order_status_chip.dart`, `theme.dart` (`ClientColors`), l10n arb + generated files.

## C. Files modified
- `medlink_app/lib/main.dart` (service+controller register/dispose)
- `medlink_app/lib/routing/app_router.dart` (2 routes)
- `medlink_app/lib/screens/client/account_tab.dart` (wallet summary card)
- `medlink_app/lib/l10n/app_{ar,en}.arb` (+22 keys each) + generated `app_localizations{,_ar,_en}.dart` (mirrored getters)

## D. Files created
- `medlink_app/lib/services/bonus_wallet_service.dart` (RPC `bonus_account_funds` + ledger select, current-user-id only)
- `medlink_app/lib/services/bonus_wallet_controller.dart` (loading/error state)
- `medlink_app/lib/screens/client/bonus_wallet_screen.dart` (hero + recent 5 + view-all)
- `medlink_app/lib/screens/client/bonus_history_screen.dart` (filter chips + list + bottom-sheet details)
- `docs/opencode/PHASE-12-CLIENT-BONUS-WALLET-HISTORY.md` (this report)

## E. Wallet
Hero card (available big, reserved tappable → history), recent-5 activity, view-all link, pull-to-refresh + appbar refresh. Balance exclusively from `bonus_account_funds` RPC — zero client-side math.

## F. History
Type/status filter chips (client-side over latest 100, documented), list rows, bottom-sheet details (type/status/reference/order/rule/notes/account). Unknown future txn types fall back to raw value (never hidden).

## G. Transaction Details
`showModalBottomSheet` with handle, amount header, key/value rows; shows only client-visible fields (no actor/internal ids beyond order/rule refs).

## H. API/Backend Mapping
`fetchMyFunds` → `bonus_account_funds(p_user_id=current user)`; `fetchMyLedger` → `bonus_ledger` select own rows (RLS). No other RPCs. No writes.

## I. RLS/Security
Current-user id only, never parameterized from UI; RLS owns row scoping; routes under authenticated `/client` tree.

## J. Navigation
Routes `/client/bonus-wallet`, `/client/bonus-history` (same pattern as siblings); wallet entry as summary card in AccountTab (no tab-bar change).

## K. Interactive UX
Tappable hero/reserved pill, filter chips, pull-to-refresh, retry buttons, bottom sheet. All backed by real data paths.

## L. Loading/Empty/Error
Full coverage: initial spinner, inline refresh, error + retry, empty cards, auth-error propagation via service throw.

## M. Responsive behavior
Same ListView/Card patterns as sibling tabs; works on all Flutter targets without new framework.

## N. Legacy Free-Y separation
Zero references to `bonus_rules`/`bonus_rule_id`; copy uses "المحفظة/رصيد البونص" only.

## O. Business Gaps (UNRESOLVED, safe)
Stored values displayed verbatim; no cancel-custom flows; customer_type untouched.

## P. Tests
`dart analyze`: **4 info issues, all pre-existing** in untouched files (branch/client deprecation notices) — 0 in new/modified files. `flutter_test`/`dart test` unavailable (snap-blocked flutter; `package:test` absent) — pre-existing environment limitation, documented.

## Q. Build/Analyze/Typecheck
Analyze PASS (above). No Flutter build possible in this environment (documented). l10n arb+generated files kept in sync manually (generator pattern mirrored; next `flutter gen-l10n` run will reproduce equivalents).

## R. Known Limitations
- History filter operates on latest 100 fetched rows (documented in empty-state-adjacent code comment).
- Reserved pill navigates to history (no per-reservation breakdown RPC exists).
- l10n additions need a future `flutter gen-l10n` sanity run.

## S. Recommended Next Step
Phase 13: client redemption + withdrawal flows (RPCs verified), then Order Discount only when backend lands.

---

**Summary**: modified 5 files (+l10n), new 5 files (4 code + 1 report), 2 screens + 1 account section, 2 backend operations (funds RPC + ledger select), 0 unsupported, 3 gaps (documented), analyze 4 pre-existing infos, build N/A (env), tests N/A (env). **Final Verdict: WALLET BATCH COMPLETE.**
