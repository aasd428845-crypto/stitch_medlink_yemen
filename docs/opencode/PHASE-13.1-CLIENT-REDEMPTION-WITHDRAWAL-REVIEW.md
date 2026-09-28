# PHASE 13.1 — CLIENT REDEMPTION & WITHDRAWAL REVIEW (read-only)

## A. Executive Summary
Phase 13 client flows verified against real backend. One HIGH finding: UI never sends `p_idempotency_key`, so retry-after-timeout can duplicate requests (only in-memory guard exists). All money authority stays server-side. No blockers to a fix-forward, but idempotency gap is HIGH.

## B. Files Reviewed
`bonus_wallet_service.dart` (extended), `bonus_wallet_controller.dart`, `bonus_redeem_screen.dart`, `bonus_withdraw_screen.dart`, `bonus_requests_screen.dart`, `app_router.dart` (3 routes), l10n arb×2 + generated×3, `0018` RPC bodies (request/cancel ×2), RLS policies, prior reports PHASE-9 through 12.1.

## C. Backend RPC Verification
| RPC | Exists | Args match | Auth | Financial guard | UI usage |
|---|---|---|---|---|---|
| `request_redemption` | yes (0018:793) | product_id/quantity/(key) | auth.uid=client only | funds check, active product, row lock | submit + confirm |
| `request_withdrawal` | yes (0018:1045) | amount/method?/notes?/(key) | auth.uid=client only | policy gates + funds | submit + confirm |
| `cancel_redemption` | yes (0018:951) | id only | client-own or director, PENDING only | status + ownership | cancel button PENDING only |
| `cancel_withdrawal` | yes | id only | client-own or director, PENDING/UNDER_REVIEW | status + ownership | cancel button on those states |

## D. Redemption Financial Review — PASS with note
Real product catalog; value displayed as labeled estimate; server computes/stores `bonus_value`; quantity validated both sides. No local balance math.

## E. Withdrawal Financial Review — PASS
Amount/method/notes collected, no invented constraints; min/max/approval fully server-side; backend errors surfaced. No status mutation possible from client.

## F. Cancellation Review — PASS
UI gating matches RPC guards exactly (verified lines 951-1024); backend re-validates status+ownership; race resolved server-side (second cancel errors, surfaced via alert).

## G. Client Ownership / Auth — PASS
Every method uses `auth.currentUser.id` internally; no user_id parameter exists in any call path. RPCs bind `account_id = auth.uid()`.

## H. RLS Review — PASS
Client policies are SELECT-only (`*_client_select`); the only FOR ALL policies are `company_director`-gated. No client INSERT/UPDATE/DELETE grants exist.

## I. State Machine Review — PASS
UI states mirror schema enums; no invented states; cancel buttons match server-allowed states.

## J. API Architecture — PASS
Service/controller separation kept; no widget-level Supabase calls; unified error mapping; double-submit guarded per controller instance.

## K. Phase 12 Regression — PASS
Wallet/history untouched in behavior; new routes additive; l10n additive.

## L. Legacy Free-Y Separation — PASS
Zero references to `bonus_rules`/`bonus_rule_id`/legacy flows in new code (grep verified).

## M. UX / Design System — PASS
ClientCard/theme/l10n/bottom-sheet/confirm patterns reused; loading/empty/error/retry/disabled/success states present.

## N. Localization — PASS
All 29 new keys present in arb×2 and generated dart×3; analyze confirms no missing getters.

## O. Tests / Verification
`flutter analyze`: 4 pre-existing info deprecations, 0 from Phase 13. `flutter test`: 8/8 passed. No new tests added (consistent with repo which has cart-only tests).

## P. Findings
| ID | Severity | File:Line | Problem | Evidence | Impact | Blocks next? |
|---|---|---|---|---|---|---|
| F-01 | HIGH | `bonus_wallet_service.dart` (request_* methods) | `p_idempotency_key` never sent; retry/timeout/app-restart can duplicate financial requests | grep: zero `idempotency` in service; RPC supports key (0018:796,1049) | duplicate redemption/withdrawal rows + double reservation | No (fix-forward: uuid per submit) |
| F-02 | LOW | requests screens | cancel button hidden (not disabled) for non-cancellable states | `cancellable` ternaries | minor discoverability | No |
| F-03 | GAP | — | bonus_value unit, customer_type, post-consumption cancel, discount, GL | unchanged from prior phases | none new | No |

## Q. Final Verdict
**PASS WITH NON-BLOCKING FINDINGS** — one HIGH (idempotency key unused) recommended for fix-forward before production use; no BLOCKER.
