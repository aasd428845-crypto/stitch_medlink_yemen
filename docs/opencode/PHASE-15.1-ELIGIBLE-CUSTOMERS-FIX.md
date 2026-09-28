# PHASE 15.1 — ELIGIBLE_CUSTOMERS FIX

## 1. Root Cause
`toInput()` hardcoded `eligible_customers: null` and `RuleForm`/`toForm()` never carried the field, so every edit overwrote the stored value with null — even when the user changed only priority/description/status.

## 2. Exact files changed
- `Medlik-Waap/artifacts/pharma-pwa/src/pages/director/BonusRulesV2Page.tsx` only:
  - `RuleForm` += `eligible_customers: string[] | null` (passthrough, no UI editor)
  - `EMPTY_FORM` += `eligible_customers: null` (create behavior unchanged)
  - `toForm()` += `eligible_customers: r.eligible_customers ?? null` (edit loads stored value)
  - `toInput()` passes `f.eligible_customers` through (API layer already forwards non-empty arrays, null otherwise)

## 3. Exact fix
Preservation, not UI: the stored value round-trips edit→save untouched. No new selector, no semantics change, no API contract change.

## 4. Before / After behavior
- Before: rule with customers `[A,B]` + edit priority → saved with `null` (data loss).
- After: same flow → saved with `[A,B]`; create flow still sends null; empty→null normalization preserved by existing `toDbPayload`.

## 5. Test coverage
No web test suite exists in repo (verified); no suite added. Verified by code trace (openEdit→toForm→handleSave→toInput→update) + `tsc` clean.

## 6. Analyze / Typecheck / Build results
- `pnpm run typecheck` (`tsc -p tsconfig.json --noEmit`): **PASS, 0 errors** (Node v22).
- No build run needed (single-file logic change, type-safe); no timeouts/errors encountered.

## 7. Remaining limitations
- No UI to *view/edit* the customer list itself (out of scope; documented, not faked).
- `customer_type` free-text behavior unchanged.

**PHASE 15.1 COMPLETE — ELIGIBLE_CUSTOMERS PRESERVED**
