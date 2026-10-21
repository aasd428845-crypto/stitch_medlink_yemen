# MIGRATION CHAIN AUTHORITY — PHASE 72

Two migration directories exist in the repository. They are **complementary
fragments of one chain, not interchangeable alternatives**: neither can be
applied alone (proven below, §D).

| Directory | Contents | Role in chain |
|---|---|---|
| `supabase/migrations/` | 24 files, 0001…0024 | **Authoritative.** Current chain tip. New migrations go here. |
| `Medlik-Waap/supabase/migrations/` | 16 files, 0001…0016 | Legacy/mirror fragment. Holds financial-core objects (`invoices`, `warehouse_inventory`, full `financial_*` schema) that root migrations depend on. |

Interleaving (how local scratch databases are built) is defined
**only** at `scripts/test-env/replay-chain.sh`:

- Root 0001–0008 → W-0001–0004 → R-0009 → W-0005 → R-0010–0014 → W-0006–0014 → R-0015,R-0016 → R-0017…R-0022 → optional R-0023 → optional R-0024.

## A. The defect and its fix

Four PL/pgSQL functions were defined with a `BEFORE UPDATE` trigger body that
ended `return old;` unconditionally. A BEFORE UPDATE trigger returning OLD
replaces the candidate row with the old row, so every UPDATE against a
non-protected row was **silently discarded**.

| Function | Pre-fix defect | Fixed by |
|---|---|---|
| `prevent_posted_journal_mutation()` | `return old` always → any UPDATE to a draft journal entry was discarded; drafts could never be edited or posted | root 0024 |
| `prevent_posted_journal_line_mutation()` | same pattern → edits to lines of a draft entry discarded | root 0024 |
| `prevent_bonus_ledger_mutation()` | same pattern → the PENDING→POSTED commit of an `ORDER_DISCOUNT` reservation was discarded | root 0024 |
| `post_financial_journal_entry(uuid)` | selected an unqualified `status` from a join of `financial_periods` and `financial_journal_entries` → `42702 column reference "status" is ambiguous` aborted **every** posting attempt | root 0024 |

Root `0024_fix_posted_journal_posting.sql` corrects all four with
`create or replace` only — no schema, RLS, policy, or grant change.

## B. Where the pre-fix bodies live

The legacy fragment still contains the buggy bodies and must never be applied
after root 0024:

- `Medlik-Waap/supabase/migrations/0008_financial_audit_immutability.sql`
  → `prevent_posted_journal_line_mutation`, `prevent_posted_journal_mutation`
- `Medlik-Waap/supabase/migrations/0010_financial_simple_entries.sql`
  → `post_financial_journal_entry`
- `supabase/migrations/0018_bonus_financial_system.sql`
  → `prevent_bonus_ledger_mutation` (root 0024 overrides it)

## C. Fail-closed assertion

`scripts/test-env/ph72-chain-integrity.sql` is a read-only `pg_catalog` check.
It raises `CHAIN INTEGRITY FAIL` if, at the fixed tip, any of the four guard
functions lacks its corrected body or any of the three immutability triggers
(`trg_financial_journal_immutable`, `trg_financial_journal_line_immutable`,
`trg_bonus_ledger_immutable`) is missing. `scripts/test-env/replay-chain.sh 0024`
runs it automatically at the end of the replay, so a rebuild that stops early
or applies the legacy fragment on top aborts instead of producing a silently
broken database.

## D. Proven behavior (isolated scratch only)

All runs below were against the isolated `medlink_ph51_test` container /
`ph51_pg` scratch; no production or cloud project was contacted.

| Observation | Pre-0024 tip | 0024 tip |
|---|---|---|
| Draft entry edit persists | discarded (`TEST_DRAFT`) | persists (`TEST_DRAFT_EDITED`) |
| Posting a balanced draft | `ERROR: column reference "status" is ambiguous`, entry stays `draft` | posts, `posted_at` set |
| Mutating a posted journal entry | allowed (guard no-op) | rejected (`Posted journal entries are immutable; use a reversal`) |
| `bonus_ledger` PENDING→POSTED | stays `PENDING` | becomes `POSTED` |
| Mutating a POSTED bonus row | allowed (guard no-op) | rejected (`bonus_ledger POSTED rows are immutable`) |

**Standalone-fragment proof.** The pure-waap chain (all 16 files alone) aborts
at `0003_phase3_offer_product_discount_columns` — `public.promotional_offers`
is created by root `0002`. The pure-root chain (all 24 files alone) aborts at
`0009_branch_manager_operations` — `public.warehouse_inventory` is created by
W-0004. Neither directory is self-sufficient; only the interleaved order works.

**Wrong-order proof.** Applying W-0008 (and W-0010) on top of a 0024 tip
reverts the bodies; `ph72-chain-integrity.sql` then fails closed naming the
affected functions.

## E. Operator rule

If a local database must be rebuilt, use the interleaved script:

```
scripts/test-env/replay-chain.sh 0024
```

Do **not** run `supabase db push` against either directory alone, and do not
apply the W-series after root 0024.

NO PRODUCTION MIGRATIONS APPLIED