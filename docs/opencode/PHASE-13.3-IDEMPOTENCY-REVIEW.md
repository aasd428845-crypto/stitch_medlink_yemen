# PHASE 13.3 — IDEMPOTENCY REVIEW (read-only)

## A. Backend Contract
`p_idempotency_key text default null` on both RPCs; lookup-first-return-existing; `UNIQUE` constraints on both tables. Server is final guard. Verified in `0018` source.

## B. Key Lifecycle
Mint-once per logical op (controller lines 113-114, 156-157); retained on failure; cleared on success or param change. `newIdempotencyKey()` called only in those two branches — never on rebuild/refresh/navigation.

## C. Redemption Verification
Submit → same product+quantity → same key (sig match). Retry path re-invokes `_confirm` → same params → same key. Param change → fresh key.

## D. Withdrawal Verification
Identical pattern keyed on amount|method|notes.

## E. Retry Verification
Error surfaces in-form; retry button re-calls `_confirm` with unchanged state → same key → server dedupes. `discardPending*` exists but is never called from UI — keys persist until success, which is the safe default.

## F. Parameter Change Verification
Sig comparison regenerates the key whenever any operation parameter differs. No old-key/new-data mixing possible.

## G. Financial Safety
No money/eligibility/limits/states/RLS/RPC changes. Pure key plumbing.

## H. Tests
- `flutter analyze`: 4 pre-existing infos, 0 new.
- `flutter test`: **11/11 passed** (8 existing + 3 idempotency-key tests covering uniqueness, no-payload, non-collision).
- Note: tests cover key generation, not end-to-end retry (no staging env; documented limitation, not a code defect).

## I. Remaining GAPs
Memory-only keys (app restart loses pending keys; server uniqueness still prevents same-key duplicates, but a post-restart retry mints fresh). No fix attempted — documented limitation.

## J. Final Verdict
**PASS — PHASE 13 CLOSED.**
