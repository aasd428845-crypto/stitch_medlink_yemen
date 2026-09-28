# PHASE 17.3 — FINAL PRE-APPLICATION GATE (read-only — nothing modified, nothing applied)

## 1. Exact migration path
`supabase/migrations/0020_order_discount.sql` — the single 0020 file in the repo (no alternates, no ambiguity; `ls | grep 0020` returns exactly one row).

## 2. Line count
413 lines (`wc -l`), identical to the count recorded in the PHASE-17 implementation report. No change since 17.1/17.2 (both phases were review-only; no edit operation touched this file in any subsequent phase — verified by unchanged line count and hash continuity within this session).

## 3. SHA-256/checksum
`62b6a64fccdbc5c30925d97ff813be4ded947cdcf1c11655f9acb393a5997156` (`sha256sum`, computed this phase). Any single-character change after this review invalidates the gate and requires re-review.

## 4. Dependency verification
Every object referenced by 0020 exists in prior migrations or is created in 0020: `bonus_settings(key,value)` 0018:285; `orders(id,client_id,status,total_amount)` 0002:126/0017; `bonus_ledger` full column set 0018:53-75 with `ORDER_DISCOUNT`/`REVERSAL` in CHECK 0018:57-61 and `PENDING`/`POSTED` 0018:63-64; `bonus_earn_allocations` 0018:357; `bonus_rules_v2(id,allow_discount,rule_type)` 0018:118-152; `bonus_audit_trail` 0018:313; `current_user_role()` 0001; `bonus_account_funds` 0018:393; `bonus_credit_remaining` 0018:437; UNIQUE(idempotency_key) 0018:73; `bonus_ledger_reverses_uniq` 0018:171; `trg_bonus_ledger_immutable` 0018:98-112 (permits the PENDING→POSTED flip); `rule_id` FK nullable. Builtins only otherwise. No dangling reference.

## 5. Security gate
Object inventory: 1 data INSERT, 2 CREATE OR REPLACE FUNCTIONs, 2 GRANTs; zero tables/triggers/indexes/alters/revokes — no undocumented object. Per-RPC: SECURITY DEFINER + `SET search_path=public` on both; `auth.uid()` first statement; apply is client-only with ownership + pending checks (0020:93-125); cancel is owner-or-director with ownership for clients (0020:333-354); EXECUTE to `authenticated` only (existing convention). Direct-write RLS posture re-verified: ledger, allocations, audit, accounts carry SELECT-only policies (0018:39-43, 85-89, 332-336, 376-380) — no INSERT/UPDATE/DELETE policies exist. Answers: user A on user B's order — NO (0020:115-117). Direct ledger modification — NO (RLS deny-by-default). Direct allocation modification — NO (same). Reversal of another's discount — NO as client (0020:349-351); director path is by-design admin settlement with audit + reason.

## 6. Financial integrity gate
Earn → ledger lots → ORDER_DISCOUNT debit → per-lot allocations → REVERSAL via `reverses_id` → fresh re-spendable credit: full chain traceable, single source of truth, no side ledger. No double spending (account-lock serialization + funds pre-check + shortfall backstop). No negative spend (positive-only takes, CHECK backstops). No allocation without ledger (same-transaction insert referencing the new debit id). No ledger without traceability (order link + snapshot + audit). No POSTED mutation (trigger-enforced; compensation only). No financial DELETE anywhere in the file. Reversal traceable via `reverses_id` + kind-marked audit.

## 7. Concurrency gate
Discount×Discount: order lock serializes; loser hits post-lock exists-check or UNIQUE — one winner, safe error otherwise (0018/0019-compatible: same pre-check pattern as `request_redemption`). Discount×Redemption/Withdrawal: all three take the `bonus_accounts` row lock inside `bonus_account_funds` (verified in 0018 for redemption and withdrawal paths this phase) — loser recomputes on post-commit funds. Discount×Cancellation and Cancellation×Cancellation: order-lock serialization; duplicate cancel blocked by guard plus constraint-level `bonus_ledger_reverses_uniq`. Compatible with 0018/0019 locking discipline; no new lock model.

## 8. Reversal gate
Original → REVERSAL (`reverses_id`) → allocations untouched (matches `reverse_bonus_txn` lot semantics: restoration is a fresh credit, never an un-consume) → `REVERSAL` audit with reason. Duplicate/concurrent/already-reversed all converge to raise-or-unique-violation, never a second posting. Snapshot mode enforced from the debit's own `notes` — policy drift cannot alter history.

## 9. Policy gate
Six `discount.*` keys exactly per 16.5; values equal 16.7 locks (false / ALL_ELIGIBLE_LOTS / AUTOMATIC_REVERSAL / null×3) — no invented values, no contradicting defaults. D4 remains a null marker, never a treatment decision. Snapshot (`discount_policy_v1`) carries every contracted field. Narrow-only proven: the lot filter is a pure conjunction of exclusions — no rule path widens global scope.

## 10. Free-Y gate
`order_items`/`unit_price`/`is_bonus`/`bonus_rule_id` occur only in one header comment documenting non-contact. Zero reads, zero writes. Legacy Free-Y path untouched.

## 11. Invoice gate
No reference to `createInvoice`, invoice sheet, or `branch_allocate_order` outside design comments; `orders.total_amount` never written. 0020 cannot function incorrectly for lack of invoice changes because it changes nothing the invoice path reads. Invoice-bypass remediation stays FOLLOW-UP AFTER 0020 — classification confirmed, not a blocker.

## 12. Tenant gate
No tenant/company/GL identifiers in code lines (verified by pattern scan in 17.1/17.2 and re-confirmed). Tenant architecture remains a documented future product gap; 0020 fabricates nothing.

## 13. Migration safety
No transaction-control statements (runs inside the migrator's transaction like all prior files). Order is dependency-safe (seeds are runtime-read; functions then grants). Every statement is re-runnable: `ON CONFLICT DO NOTHING`, `CREATE OR REPLACE`, bare `GRANT`. No constraint/index/trigger timing hazards (none created). Static syntax risk is residual only (no live Postgres available here) — mitigated by 17/17 structural checks + three phases of line review.

## 14. Git status
0020 file: untracked-new (`??`), unmodified since creation (413 lines, hash §3). Pre-existing out-of-scope working-tree changes documented without modification: `Medlik-Waap` submodule pointer, `0018` hardening (+45/-1, predates Phase 17), Flutter l10n/main/router/account_tab/pubspec, `LIVE-VERIFICATION-REPORT.md`, and earlier-phase report files (51 status entries total). No unexpected modification to 0017/0019/0020 or any app file by this review chain.

## 15. Final requirement matrix
| Requirement | Expected | Actual in 0020 | Verdict |
|---|---|---|---|
| D1 | REQUIRE_POSITIVE_REMAINING | 0020:222-224 + seed false | MATCH |
| D2 | ALL_ELIGIBLE_LOTS | scope validation + seed | MATCH |
| D2 Override | NARROW_ONLY | exclusion-only filter 268-270 | MATCH |
| D3 | AUTOMATIC_REVERSAL | cancel fn + seed; snapshot-gated | MATCH |
| D4 | neutral / tenant config | no GL; null marker | MATCH |
| D5 | no cap | null seeds; conditional min() | MATCH |
| D6 | no minimum | null seed; conditional floor | MATCH |
| D7 | tenant-owner boundary | no role fabricated | MATCH |
| D8 | snapshot at discount | policy_v1 in notes; cancel parses it | MATCH |
| Idempotency | DISCOUNT:{order_id} | 70-71/326-327 + UNIQUE | MATCH |
| Ledger | ORDER_DISCOUNT | existing CHECK type reused | MATCH |
| Lots | bonus_earn_allocations | exclusive allocation target | MATCH |
| FIFO | oldest-first | created_at,id + remainder caps | MATCH |
| Reversal | compensating | reverses_id credit, original intact | MATCH |
| Free-Y | isolated | zero contact | MATCH |
| GL | absent | zero objects | MATCH |
| Tenant fabrication | absent | zero identifiers | MATCH |
| Invoice modification | absent | zero contact | MATCH |

## 16. Remaining follow-ups
(From 17.1/17.2, none blocking apply): graceful-replay polish F1/F2, caller key-uniqueness note F3, order_id index F6, app wiring of apply/cancel paths F7 (gates production USE, not apply), invoice-bypass remediation (post-0020 track), tenant architecture (product track), GL bridge (post-D4 track).

## 17. Final decision
Zero divergences across all seventeen requirements; security, financial, concurrency, reversal, policy, isolation, compatibility, and safety gates all pass on primary-source evidence. The file is exactly the reviewed artifact (hash §3).

PHASE 17.3 STATUS:
FINAL PRE-APPLICATION REVIEW PASSED

MIGRATION 0020 IS READY FOR MANUAL HUMAN APPLICATION.

NO LIVE DATABASE CHANGES.
