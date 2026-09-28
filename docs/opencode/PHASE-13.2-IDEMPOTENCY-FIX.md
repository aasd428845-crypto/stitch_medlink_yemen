# PHASE 13.2 — IDEMPOTENCY FIX

## A. Root Cause
Client submits carried no `p_idempotency_key`; backend lookup-then-return existed but was never fed. Only in-memory `_isSubmitting` guarded, which dies with the attempt — timeout retry minted a second row.

## B. Backend Contract Verified (from 0018 source, unchanged)
- `request_redemption(p_product_id, p_quantity, p_idempotency_key=null)` / `request_withdrawal(p_amount, p_method=null, p_notes=null, p_idempotency_key=null)` → uuid; lookup-first-return-existing on both tables; `idempotency_key text unique` on both tables.
- Retry with same key = same id returned, no duplicate. Unused by UI until this fix.

## C. Files Changed
- `medlink_app/lib/services/bonus_wallet_service.dart` (optional `idempotencyKey` params on both submit methods)
- `medlink_app/lib/services/bonus_wallet_controller.dart` (key lifecycle + `newIdempotencyKey()` + discard methods)
- `medlink_app/test/bonus_idempotency_key_test.dart` (new)
- `docs/opencode/PHASE-13.2-IDEMPOTENCY-FIX.md` (this report)

## D. Idempotency Key Generation
`newIdempotencyKey()`: `client-{microseconds}-{64 random hex bits}` via `dart:math Random.secure` (SDK only, no new dependency, no project precedent to follow). Not timestamp-alone, not amounts, never user-entered.

## E. Redemption Retry Behavior
Key minted on first submit of a (product,quantity) operation; retained across failures; cleared only on success or param change. Timeout retry → same key → server returns existing id.

## F. Withdrawal Retry Behavior
Same, keyed on (amount,method,notes). UI retry button reuses; deliberate new submit (changed params) mints fresh.

## G. Security / Financial Safety
No money math added; no RLS/RPC/state changes; keys carry no payload; ownership still enforced server-side.

## H. Tests
- `flutter test test/bonus_idempotency_key_test.dart`: 3/3 passed (uniqueness×500, no payload, consecutives differ).
- Full suite: **11/11 passed**. `dart analyze`: 4 pre-existing infos, 0 new.

## I. Remaining Limitations
- Key lifecycle is in-memory per controller instance (app restart loses pending keys; server-side uniqueness still prevents duplicates only if same key resent — a restart generates a fresh key, so a timeout straddling a restart could still duplicate; documented).
- No integration test against live RPC (no staging env).

## J. Final Verdict
**FIX COMPLETE.**
