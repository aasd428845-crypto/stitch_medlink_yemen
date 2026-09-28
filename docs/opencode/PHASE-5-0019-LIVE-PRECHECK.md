# PHASE 5 — 0019 LIVE PRECHECK (read-only, 2026-09-21)

## A. Target Project
`lmkomzqioneuyvatzsov` only. No other project touched.

## B. Migration History
CLI history table absent (manual-apply project — established). Local files end at `0019_bonus_earn_engine.sql`; no later local migration. Live state proven by fingerprints below, not by history table.

## C. 0017 Fingerprint — APPLIED, INTACT
`order_items.bonus_rule_id` present; price check present; both RPCs present with correct signatures/definer/search_path/grants; direct-insert policies gone (0 rows). Verified in prior rounds, unchanged.

## D. 0018 Fingerprint — APPLIED, INTACT
8/8 tables, 20/20 functions, RLS 8/8, 19 policies (14 new + legacy incl. manual), immutability trigger, late FKs, settings seed keys (4). Verified in prior rounds, unchanged.

## E. Existing Data Compatibility — CLEAN
All six bonus tables: **0 rows**. No mode violations possible. No existing rules to conflict with new validation. No legacy data to migrate.

## F. Existing Orders Compatibility — CLEAN
2 orders, both `pending`. Trigger fires only on future UPDATE→delivered; no retroactive processing possible by design.

## G. Products Compatibility
`products.id` + `is_active` present (verified in schema reads). No rule product references exist yet (0 rules).

## H. Users / Customer Context
`users.role` present (verified). Governorate resolves via branches/client_addresses (verified schemas). `customer_type`: no backing column — recorded GAP, validator rejects such rules loudly by design.

## I. Function & Trigger Collision — NONE
Live `bonus_*` routines: exactly the 3 expected 0018 helpers. Zero 0019 names. Zero 0019 triggers. Revokes/grants in file target only its own objects.

## J. RLS & Security Compatibility — CLEAN
8/8 RLS on; 19 policies read-only for clients + director-manage; no allow-all on bonus tables; new pending table gets 2 select-only policies; 5 internal revokes + 1 processor grant match file.

## K. Extensions / Dependencies — CLEAN
`pgcrypto` present (gen_random_uuid). No other extension needed. All referenced tables/columns verified present.

## L. Idempotency / Re-run Analysis
File is re-runnable: IF NOT EXISTS tables/indexes, DROP+CREATE policies/triggers, OR REPLACE functions, conditional ADD COLUMN, ON CONFLICT seeds/grants. Non-idempotent-by-nature parts (ALTER DROP/ADD CHECK) are re-runnable statements. Partial-failure resume: safe to re-run whole file (worst case: replays completed DDL, no data written — settings seed is conflict-guarded).

## M. Backup / Recovery Evidence — UNKNOWN
Cannot prove snapshot/PITR/backup existence via read-only CLI inspection. **Stated explicitly: no backup verified.** Recommend operator confirms a restore point before manual apply. This is procedural, not a migration defect.

## N. Migration Order
`0017 → 0018 → 0019` confirmed; no later local migration; no forward dependencies missing.

## O. BLOCKERS
None technical.

## P. WARNINGS
W1: No verified backup (M). W2: `customer_type` rules will fail loudly until a backing column exists (by design). W3: Several transient CLI timeouts during inspection, all retried successfully — no evidence of DB-side issues.

## Q. FINAL PRECHECK
**READY TO APPLY 0019**
