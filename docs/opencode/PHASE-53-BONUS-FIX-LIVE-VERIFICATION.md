# PHASE 53 — BONUS FIX LIVE VERIFICATION & RESTORE READINESS

> Type: read-only live verification + restore-point assessment. SELECT-only catalog queries against the linked project. No DDL/DML, no migration, no backup created, no login performed, no files modified except this report.

## 1. Target verification

`supabase projects list` shows the ● linked marker on `lmkomzqioneuyvatzsov` (موريد الادويه, Tokyo). All queries ran `--linked` (that project only). `hhqhoqwpebnmfuhwhllw` never referenced. Read path note: `supabase db query --linked` works from this machine (Management/API auth present — a change since Phase 50 recorded no access token; no login was performed by this phase and none was needed).

## 2. Restore-point assessment

- Local backup files: none found (repo-wide search for dumps/backups/restore artifacts — empty, consistent with Phase 50).
- Dashboard backup list / restore drill: NOT verifiable from here (requires owner dashboard access; not requested, not performed).
- Verdict: **no verified restore point exists on record** (PHASE-5 §M still stands). What the owner must supply: backup ID + timestamp + size from the project dashboard, plus evidence of restorability (prior successful restore or scheduled drill). **BLOCKED item — unchanged.**

## 3. Live function verification (read-only)

| Check | Expected (baseline) | Live actual | Result |
|---|---|---|---|
| `bonus_rules_v2.max_earn` column | numeric(12,2), nullable, no default; no `max_bonus` anywhere | exact match | VERIFIED |
| Both functions exist | 2 | 2 | VERIFIED |
| SECURITY DEFINER | both true | 2/2 | VERIFIED |
| Live bodies: `max_bonus` count | 3 + 3 (buggy baseline) | 3 + 3 | VERIFIED (0023 NOT applied; no drift) |
| Live bodies: `max_earn` count | 0 + 0 | 0 + 0 | VERIFIED |
| ACLs (`proacl`) | Phase-47 §E.3 values | byte-identical both functions | VERIFIED |
| Row counts (rules/ledger/pending) | 0/0/0 (no retro risk) | 0/0/0 | VERIFIED |

No divergence from PHASE-46/47/52 evidence on any item. No smoke test executed (forbidden); no rule created/modified/deleted; no cleanup attempted.

## 4. Condition classification

| Condition | Status | Evidence |
|---|---|---|
| Isolated tests green (T1–T18) | VERIFIED | Phase 51 report |
| File under review unchanged (0023 hash) | VERIFIED | Phase 52 (hash-gated chain intact) |
| Live matches buggy baseline, no drift | VERIFIED | §3 table above |
| ACLs/signatures/definer intact | VERIFIED | §3 table above |
| Zero live data at risk | VERIFIED | counts 0/0/0 |
| Owner cap-activation approval | VERIFIED | owner decision recorded in task brief (MAX_EARN CAP ACTIVATION: APPROVED) |
| Restore point verified + restorable | **BLOCKED** | §2 — nothing on record, unverifiable from here |
| Live re-confirmation immediately pre-apply | PENDING LIVE VERIFICATION | must rerun §3 at apply time (live state can change) |
| Manual-apply execution + post-apply checks | PENDING OWNER ACTION | future gated step |

## 5. Divergences / risks

None found in code, schema, ACLs, or data. Residual risks (unchanged, owner-owned): `db push`/reset hazard under the production CLI link (procedural ban restated, not enforced by tooling); first-cap-activation is approved but remains the first observable financial effect — release-note worthy; live counts are time-sensitive (re-confirm at apply).

## 6. Verdict

**BLOCKED** — on the single remaining gate: a verified, restorable production backup (plus apply-time re-confirmation). Everything technically verifiable from the read-only side passes with zero divergence. No approval of the apply itself is issued here; the next action belongs to the owner: furnish restore evidence, then authorize the manual apply window.

PHASE 53 COMPLETE
NO MIGRATION APPLIED
NO DATABASE WRITES
NO COMMIT
NO PUSH
