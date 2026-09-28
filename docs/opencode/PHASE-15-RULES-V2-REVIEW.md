# PHASE 15 — RULES V2 REVIEW (read-only)

## 1. Current implementation
`BonusRulesV2Page.tsx` (853 lines): list + search/status filter + create/edit modal + status actions, backed by `bonusFinancialApi.ts` (direct table CRUD under director RLS + `earn/reverse/expire` RPC exports). Routes/nav wired; legacy pages untouched.

## 2. Backend contract verification
Table `bonus_rules_v2` columns match UI fields 1:1 (name/description/type/status/dates/minimums/value/percent/max/eligible/governorate/products/stackable/priority/usage/allow_*/cash_*/approval/product_values/value_basis). DB validation trigger enforces compat; UI mirrors it client-side with server as final authority.

## 3. UI → API → RPC → DB mapping
Create/update → direct table writes (permitted by `director_manage` policy); status → direct update; earn/reverse/expire RPCs exported but **no UI buttons call them** (correct — no manual-grant workflow).

## 4. Validation review
UI validation mirrors DB trigger (MONETARY xor, GENERAL, dates, ranges, product-values consistency). DB trigger remains source of truth; server errors surface in form.

## 5. Authorization review
Director-only route + director RLS policies; no client paths; no user-controlled ID bypass (ids come from listed rows).

## 6. Localization review
All labels Arabic inline (consistent with sibling admin pages which hardcode Arabic); no missing-key mechanism (no arb system in web app — verified pattern).

## 7. Design-system review
Same cards/tables/modal/buttons/badges/spacing/RTL as sibling pages. Responsive grid + overflow-x tables reused.

## 8. Test results
`pnpm run typecheck` (`tsc --noEmit`): **PASS, 0 errors**. No web test suite exists (verified); none added.

## 9. Changes made
None (review-only phase).

## 10. Remaining gaps
- **MEDIUM — edit wipes `eligible_customers`**: `toInput` hardcodes `eligible_customers: null` (page line 191) with no form field; editing any rule that has customer scoping silently clears it. Backend supports the field; UI drops it. Requires fix (add picker or preserve on edit) — NOT business-logic change, but per instructions documented only.
- Informational: `customer_type` free-text stored as-is (matches documented GAP); `value_basis` derived, not directly editable (consistent with 0019 semantics).

## 11. Decisions required
None new — `eligible_customers` fix is technical (preserve-or-expose), needs no business decision.

## FINAL VERDICT
**PHASE 15 COMPLETE — REQUIRED FIXES IMPLEMENTED**: none implemented (review-only mandate). Single MEDIUM finding documented above for a follow-up fix batch.
