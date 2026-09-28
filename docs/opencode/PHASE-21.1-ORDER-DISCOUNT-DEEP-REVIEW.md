# PHASE 21.1 — DEEP CODE REVIEW OF ORDER DISCOUNT INTEGRATION (read-only)

## Executive Summary
Phase-21 code is correct and contract-compatible: service params match 0020 exactly, controller idempotency mirrors the redemption pattern line-for-line in behavior, UI gates on pending with server-as-authority, and no financial-integrity violation exists. The translation incident is forensically bounded (§3). Four LOW code findings (all UX/test-grade, none financial) + two MEDIUM known gaps (cancel/invoice wiring, both backend-blocked by design, not code defects). Verdict: A) SAFE TO CONTINUE TO BACKEND DESIGN.

## Git Diff Audit
Tracked modifications: pre-existing (Medlik-Waap pointer, LIVE-VERIFICATION-REPORT, main.dart, app_router.dart, account_tab.dart, pubspec.lock, 0018 hardening — all M before Phase 21) + Phase-21 (arb ×2, generated l10n ×3, order_detail_screen +11). Untracked: all phase reports (pre-existing pattern) + bonus client stack (pre-existing) + Phase-21 widget/test. Classification: EXPECTED — service, controller, order_detail, arb/l10n additions, widget, test. INCIDENTAL — arb recovery splice + gen-l10n output (justified, §3). PRE-EXISTING — everything else. UNEXPECTED — none. Migrations 0017/0019/0020 untouched; 0018 diff predates Phase 17.

## Translation Incident Verification
Claim under test: "51 keys restored byte-identical from generated dart files; only @descriptions lost." Forensics: (a) arb-vs-HEAD diff = 120 additions + exactly 2 deletions, both proven comma-only adjustments (previous-last-entry `branchNotAssignedMessage` ±comma, en+ar) — zero content deletions; (b) all 363 arb keys ↔ 363 generated getters, no duplicates, and every getter value matches its arb entry with 0 runtime mismatches (the single apparent diff, `noAccountYet`, is a regex artifact: arb `Don't` vs Dart-source `Don\'t` — identical runtime strings); (c) added set = exactly the 51 previously-present `bonus*` keys + 8 new `orderDiscount*` keys — no other key touched; (d) zero escapes/placeholders/plurals/selects among added values, and zero parameterized getters anywhere, so no placeholder/plural metadata could have existed to lose. Honest boundary: byte-identical recovery is NOT provable from git (lost content was never committed); what is proven is consistency-by-construction (values sourced from the generated files the lost arb itself produced) plus key-name match to live UI consumers (e.g. `l10n.bonusWalletTitle`). Key ORDER did change (appended at end) — cosmetically, functionally irrelevant. Consequence: no semantic translation change is possible for simple string getters; `flutter gen-l10n` runs clean. No repair needed or performed.

## Service Review
`requestOrderDiscount` (service:285-311) and `cancelOrderDiscount` (313-343) verified against live 0020 signatures: `apply_order_discount(uuid,numeric,text)` ← (String,double,String?) with `data as String` return — exact; `cancel_order_discount(uuid,text,text)` ← same, with empty-reason omission correctly falling through to the server default. Real RPC names, no invented endpoints, no direct ledger/allocation writes (grep-clean), no balance math, no user_id parameter (auth.uid server-side), errors logged+rethrown per project pattern, retry safe via passed-through keys. Architecture pattern identical to `requestRedemption`/`requestWithdrawal`.

## Controller Review
`submitOrderDiscount`/`removeOrderDiscount` replicate the redemption/withdrawal key lifecycle exactly: mint-once per signature (`discountOperationSig(order,amount)`), retain on failure, reuse on retry, clear on success, fresh key on parameter change, `_isSubmitting` double-submit guard returning null. Matches 0020's server-side replay design; no policy logic client-side.

## Idempotency Review
Creation: once per logical op; retention: failures keep, success clears; retry: same key (proven by test); param change: new key; rebuild/navigation: controller is app-scoped provider (main.dart:144-146), keys survive navigation, cleared only on success/discard — same semantics as existing flows. Duplicate tap: second call returns null while submitting. Timeout+retry: same key → server dedupes (triple cover proven in 17.x). No deviation from the Redemption/Withdrawal precedent.

## UI Review
`OrderDiscountSection` (260 lines): renders only for pending (parent gate + internal shrink; server re-validates regardless); funds shown verbatim from `fetchMyFunds`; amount is a request string, never a decision; payable display uses server values only (`total + negative ledger amount`); no order_items/invoice/Free-Y contact; ClientCard/SectionTitle/Colors/spacing + full l10n (8 new keys, zero hard-coded strings); loading (progress + disabled buttons), error (inline + snackbar duplication noted INFO-4), success (clear + parent reload), retry (same amount → same key). Trace UI→controller→service→RPC verified line-by-line with no bypass.

## Financial Integrity
Proven by grep + read: no `bonus_ledger`/`bonus_earn_allocations` insert/update/delete from app code; no `unitPrice`/`totalAmount` assignment outside freezed boilerplate; no client-side authoritative balance (funds verbatim, payable labeled display); no `bonus_rule_id` contact in new/changed files; no GL/tenant/accounting content; no price/total mutation. Server remains sole financial authority.

## 0020 Contract Compatibility
Arguments/types/returns map 1:1 (§Service Review); error paths surface server exceptions unmodified; pending restriction assumed by UI but enforced by RPC (0020:118-120); auth via `auth.uid()` with no client identity input; policy (caps/scope/zero/snapshot/ledger/allocation) entirely server-side. D1/D2/D3/D5/D6/D8 untouched; no literals of policy values in UI.

## Cancellation Gap
Proof of unwirability: the only cancel executor is branch manager (`branch_order_actions.dart:159` → direct status write); the RPC admits only `client`/`company_director` (0020:334) — a branch-manager call raises server-side on every attempt. Client has no cancel path; web `OrdersMonitoringPage` has no cancel action (repo-wide cancel grep). Backend need (future phase): either extend the cancel RPC role set (new migration) or route branch cancels through a permitted actor + auto-call; plus trigger-point decision (status-hook vs explicit action). No app code can bridge this safely today.

## Invoice Gap
Proof: allocation invoice is written inside backend RPC (0016:145-148, app cannot alter the amount); manual invoice is a direct insert of hand-typed amount with no order linkage (`branch_service.dart:508-527`, sheet:48-66); branch RLS blocks ledger reads (PHASE 18 live: client-own + director SELECT only), so the app cannot even reliably display the discount to the billing actor. Minimum future requirement: backend allocate read-path (total − POSTED discount via ledger join, no schema strictly required) + manual-path order-link-or-restrict decision (owner ruling). No app-only workaround exists that is not fake enforcement.

## Test Review
11 tests, each with real assertions: 3 sig-purity, 5 controller (success/error-clear, key-reuse-on-retry, fresh-key-on-change, single-RPC-on-double-submit, removal path) via offline fake subclass (all network methods overridden; client constructed connectionless with auto-refresh off). 3 widget (render+apply-once, invalid-submits-nothing, non-pending-renders-nothing). Honest test gaps (LOW-1, LOW-2): service RPC-name strings are bypassed by the fake (a typo would pass tests, fail at runtime — review-verified here instead); applied/remove UI branch untested (fake ledger returns []). Full suite 22/22 green; analyze shows only the 4 pre-existing infos.

## Web/PWA Review
Verified untouched: git shows only the pre-existing submodule pointer change; zero file changes under `Medlik-Waap/artifacts`. Web remains label-only for ORDER_DISCOUNT (ledger/dashboard pages) with no discount flow — consistent with the phase scope (§11: no new financial controls).

## Security Review
No privilege escalation (roles enforced server-side; UI adds no capability); no user_id injection (no such parameter); no client-side authorization substituting DB checks (pending gate is display-only, documented as such in code); no direct financial mutation; no RPC bypass (single seam Service→RPC); ledger exposure unchanged (existing `fetchMyLedger` only, own rows via RLS); no unnecessary disclosure (applied detection uses already-visible own ledger rows).

## Findings Matrix
| Finding | Severity | Evidence | PHASE 21 blocker? | Required future phase |
|---|---|---|---|---|
| Translation splice integrity | INFO | 120+/2-comma-only diff; 363↔363 keys; 0 value mismatches; §Translation | No (verified bounded) | none |
| RPC-name strings untested | LOW | fake bypasses `_client.rpc`; typo would pass suite | No (review-verified) | mocktail rpc-name test |
| Applied/remove UI branch untested | LOW | fake ledger returns []; remove-button path never pumped | No | widget test with seeded ledger rows |
| Retry-after-remove submits apply | LOW | widget `_retry` uses `_lastRequested` regardless of error source | No | track last op type; fix before production use |
| Invalid input silent no-op | LOW | `_apply` returns on bad parse with no feedback | No | inline validation message |
| Cancel unwired (role mismatch) | MEDIUM | branch actor vs 0020:334 gate; no alternative caller | No (backend scope) | backend permission decision + wiring |
| Invoice unaware of discount | MEDIUM | backend-written invoice; RLS blocks app reads | No (backend scope) | allocate read-path + owner ruling |
| Duplicate error display | INFO | snackbar + inline text on apply failure | No | cosmetic dedup (optional) |

## Final Verdict
A) SAFE TO CONTINUE TO BACKEND DESIGN. Phase-21 code is sound, tested (22/22), analyzed clean, and introduces no financial, security, or contract risk. The two MEDIUMs are absence-of-wiring gaps requiring backend decisions, not code defects; the four LOWs are UX/test polish for the pre-production hardening list. Files needing future attention: `branch_service.dart` + `branch_order_actions.dart` (cancel hook, pending RPC role decision), `branch_invoice_create_sheet.dart` + allocate read path (invoice invariant), `order_discount_section.dart` (retry-op tracking, input feedback), `test/order_discount_test.dart` (rpc-name + applied-branch coverage).

## Recommended Next Phase
Backend cancel/invoice decision phase: (1) owner ruling on cancel-RPC role extension vs director-mediated flow; (2) owner ruling on manual-invoice scope; (3) allocate invoice read-path design (join-based, no schema preferred); (4) then wire + harden LOWs + staging verification. No further client feature work needed first.

PHASE 21.1 STATUS:
DEEP REVIEW COMPLETE
NO CODE CHANGES
NO SQL CHANGES
NO DATABASE CHANGES
NO MIGRATION CHANGES
