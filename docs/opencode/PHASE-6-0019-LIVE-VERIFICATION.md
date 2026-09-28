# PHASE 6 — 0019 LIVE VERIFICATION (read-only, 2026-09-21)

## A. Application Confirmation
Manual apply of `supabase/migrations/0019_bonus_earn_engine.sql` reported by operator. Verified below via live catalog reads only. No writes executed by verifier.

## B. Migration Identity
Objects proven present live that exist ONLY in 0019: `bonus_pending_entitlements` table, 6 routines (`bonus_check_rule_v2`, `bonus_validate_rule_v2`, `bonus_evaluate_order_earn`, `bonus_on_order_delivered`, `bonus_process_pending`, `bonus_rules_v2_validate_trigger`), 2 triggers, `value_basis`/`product_values` columns, SALES mode. Migration history CLI table absent (manual-apply project) — identity proven by fingerprints, not history.

## C. Tables — 1 new table + 2 altered
`bonus_pending_entitlements` present (16 attrs). No other new tables (by design).

## D. Columns
Pending: 16/16 attrs incl. snapshots, idempotency_key, attempts, ledger_id. `bonus_rules_v2.value_basis` + `product_values` present. Mode CHECK = NONE/SALES/OPENING_BALANCE/LEGACY_MIGRATION (literal def match).

## E. Constraints
Late FKs, unique idempotency keys, status CHECKs verified at file level in prior static review; live constraint spot-checks (mode def literal) match.

## F. Functions — 6/6
All present with correct names; `BONUS_CONFIG_ERROR` sentinel present in live evaluator definition; snapshot replay + hold paths present in live processor definition (verified via position() on live pg_get_functiondef).

## G. Triggers
`trg_bonus_on_order_delivered` + `trg_bonus_rules_v2_validate` present live.

## H. RLS
Pending table: exactly 2 SELECT-only policies (client own / director). No write policies.

## I. Grants / Security
Processor executable by authenticated (director check inside, verified live). 5 internal revokes in file (static-verified; revokes are no-ops if never granted — safe).

## J. Exception Handling
Zero `SQLERRM LIKE` in live 0019 routines (queried, 0 rows). Classification via SQLSTATE triple + sentinel + re-raise, matching file.

## K. Pending Lifecycle
Table + statuses + attempts/error/link columns present; processor logic verified in live definition (snapshot replay, PROCESSED never deleted).

## L. Idempotency
`SALES_EARN:{order}:{rule}` key format in live evaluator definition; UNIQUE on idempotency_key columns; exact-key (never latest-row) linkage in processor.

## M. Value Basis
PER_ORDER/UNIT/PRODUCT branches + Free-Y exclusion + stacking stop + usage count + mode promotion readable in file (static); live behavior untestable without writes (recorded, not a defect).

## N. Stacking
Priority ASC + created/id tiebreak + stop-on-first-non-stackable readable in file text.

## O. Usage Limits
Ledger-derived count + account row lock readable in file text.

## P. Account Modes
SALES in live CHECK; promotion/preservation logic in file text.

## Q. 0017 Compatibility
`create_order_with_items` present (EXISTS). 0017 objects intact; file untouched (git status clean for 0017 — verified separately).

## R. 0018 Compatibility
8 tables / 20 functions / trigger / settings seed verified in prior rounds, unchanged. No 0018 file modification in this round.

## S. GL Boundary
No GL tables/columns/RPCs from 0019 (name scan: 0). No expiration→revenue. No discount engine.

## T. Local vs Live Comparison
File ↔ live definitions spot-matched (guards, sentinels, replay paths): MATCH on all sampled markers. Full byte-diff of definitions not performed (not required; sampled markers cover the security-critical paths).

## U. Unexpected Differences
None found.

## V. Business Gaps (unchanged, recorded)
bonus_value unit; cancellation-after-full-consumption; customer_type source.

## W. Final Verdict
**0019 LIVE VERIFIED**
