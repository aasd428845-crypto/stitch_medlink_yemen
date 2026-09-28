# PHASE 13 — CLIENT REDEMPTION & WITHDRAWAL

## A. Scope
Client financial flows backed only by real RPCs: product redemption (`request_redemption`/`cancel_redemption`) and cash withdrawal (`request_withdrawal`/`cancel_withdrawal`) + request tracking. No discount, earn, Free-Y, or backend changes.

## B. Backend Contract Reviewed (real RPCs used)
- `request_redemption(p_product_id, p_quantity)` → uuid; server checks funds/product; `cancel_redemption(p_redemption_id)` (PENDING, own row).
- `request_withdrawal(p_amount, p_method?, p_notes?)` → uuid; policy-gated server-side (enabled/min/max/percent/monthly); `cancel_withdrawal(p_withdrawal_id)` (PENDING/UNDER_REVIEW).
- All use `auth.uid()` internally — no user_id parameter exists to abuse. RLS: client-select-own on both tables.

## C. Files Changed
- `medlink_app/lib/services/bonus_wallet_service.dart` (+4 RPC methods, +2 models, +2 list methods)
- `medlink_app/lib/services/bonus_wallet_controller.dart` (submit/cancel with double-submit guard + request lists)
- `medlink_app/lib/screens/client/bonus_wallet_screen.dart` (entry buttons)
- `medlink_app/lib/routing/app_router.dart` (3 routes)
- l10n arb×2 + generated dart×3 (+29 keys; one duplicate `bonusNotesLabel` created and removed during build)

## D. Redemption Implementation
`bonus_redeem_screen.dart`: product search over `CatalogController.products` (active only), quantity stepper, server-computed value shown as labeled estimate, confirm bottom sheet, `submitRedemption` → navigates to requests. Double-submit blocked via controller flag.

## E. Withdrawal Implementation
`bonus_withdraw_screen.dart`: amount/method/notes form, confirm sheet, `submitWithdrawal`. All limits/approval enforced server-side; backend errors surfaced verbatim.

## F. API/Service Architecture
Extended Phase-12 service/controller in place (no duplication); widgets never call Supabase; error mapping via rethrow + controller message.

## G. Security
Current-user-only throughout; no user_id inputs; no service keys; no direct writes; no director actions in client code. Backend is final authority (status-gated cancels).

## H. Navigation
Routes `/client/bonus-redeem`, `/client/bonus-withdraw`, `/client/bonus-requests` (nested pattern); wallet buttons + requests screen with cancel confirmations. No existing routes touched.

## I. Localization
29 new keys in arb+generated files (mirrored manually, generator pattern). Verified present in all 5 files.

## J. UX / Design System
ClientCard/theme/l10n/bottom-sheet/confirm-dialog patterns reused; loading/empty/error/retry/disabled states; no new visual system.

## K. Financial Integrity
Zero client-side money math (estimate display only, labeled); server validates funds/product/policy; idempotency via RPC design.

## L. Legacy Free-Y Separation
Zero `bonus_rules`/`bonus_rule_id` references in new code (verified by grep).

## M. Business Gaps
Unchanged and unassumed (unit, cancellation-after-consumption, customer_type, discount).

## N. Tests / Verification
- `dart analyze`: 4 info issues, all pre-existing in untouched files; 0 in new/modified code (2 self-found issues fixed during build: duplicate l10n key, unused import).
- `flutter test`: **8/8 passed** (7 cart-bonus + 1 placeholder).

## O. Known Limitations
- Estimate display is not the final server value (labeled as such).
- Method field is free text (backend accepts text; no enum exists).
- No per-request detail view beyond status lists (history covers ledger detail).

## P. Final Verdict
**PHASE 13 COMPLETE.**
