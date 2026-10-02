# PHASE 54 — BONUS FIX PRODUCTION APPLY PLAN & RESTORE GATE

> Type: planning only. No database contact (per mandate — Phase 53 evidence reused, not re-queried), no SQL, no migration change, no other files touched. 0023 hash re-verified this phase: `f3d17a750d9dd607…` (match).

## Executive Summary

All technical evidence is in place and green (isolated T1–T18; live baseline matches the buggy state with zero drift; zero live data at risk). The single open gate is restore evidence, which cannot be produced from inside the repository. This plan sequences the apply into verifiable steps with explicit stop conditions, separates four independent approvals, and defines what a rollback can and cannot undo.

## Evidence from PHASE 53 (reused, not re-queried)

- Target proven: linked project IS `lmkomzqioneuyvatzsov` (موريد الادويه); second project never touched.
- `max_earn` present / no `max_bonus` column; both functions SECURITY DEFINER with `max_bonus` 3× + `max_earn` 0× each (0023 NOT applied, no drift).
- ACLs byte-identical to recorded baseline; counts 0/0/0 (rules/ledger/pending).
- Restore: NO verified backup on record (unchanged since PHASE-5 §M).

## Restore Gate Checklist

| # | Requirement | Owner evidence needed | Status |
|---|---|---|---|
| R1 | Backup/restore point exists pre-apply | Dashboard screenshot or export: project `lmkomzqioneuyvatzsov`, backup ID, timestamp, size/scope | PENDING OWNER EVIDENCE |
| R2 | Restorability proven | Prior successful restore record, or documented restore procedure + scheduled drill result | PENDING OWNER EVIDENCE |
| R3 | Scope covers schema + functions + triggers + ACLs + data | Backup type confirmation (full project backup, not table export) | PENDING OWNER EVIDENCE |
| R4 | Restores without overwriting anything except by explicit operator action | Named responsible person + written restore runbook reference | PENDING OWNER EVIDENCE |

**RESTORE GATE: BLOCKED** until R1–R4 are furnished. Dashboard presence alone is explicitly insufficient (restorability must be evidenced, not assumed).

## Migration Review (0023, file state verified this phase)

Two `CREATE OR REPLACE FUNCTION` bodies (validator + evaluator), six identifier renames `max_bonus`→`max_earn` (message text included), three restated privilege statements, zero DDL/data/trigger/policy/RLS changes, 0019 untouched, no submodule copy. Hash `f3d17a75…78c7fa` matches the reviewed artifact. No collateral surface: signatures, callers (triggers by name), and ACLs preserved by construction.

## Proposed Apply Sequence (future, NOT executed)

1. Re-confirm target project identity immediately pre-apply (linked ref + dashboard project match).
2. Re-confirm migration-history state (0023 absent from applied set; 0019 present).
3. Re-read the full 0023 file; diff function bodies against 0019 originals (expect exactly the six renames).
4. Record pre-apply fingerprint (column list, both `prosrc` marker counts, both ACLs, trigger defs, row counts).
5. Apply manually via SQL Editor ONLY (never `db push`), post-0019 semantics, after all approvals below.
6. Post-apply: `max_bonus` 0/0, `max_earn` 3/3, signatures/definer/path unchanged, ACLs identical, triggers identical.
7. Confirm `max_bonus` absent from both affected bodies (and still absent everywhere else).
8. STOP on any deviation: halt, preserve evidence, do not proceed to functional smoke.
9. Rollback reality (see below) — know before starting what cannot be undone by reversal.

## Pre-Apply Verification (all must be green at apply time)

Live re-confirmation of §Evidence (state can change — Phase 53 is a snapshot, not a standing guarantee) + R1–R4 + owner approvals (§Owner Approval Checklist) + push/reset ban restated to the operator.

## Post-Apply Verification

Marker counts, signature/definer/path/ACL/trigger identity, row-count stability, then a single rule-lifecycle smoke ONLY with explicit owner sign-off on the created row's disposition (verify rule-row deletability first — `bonus_rules_v2` has no immutability trigger per current evidence, but re-confirm; never assume).

## Stop Conditions

Halt on: missing/invalid restore evidence; target mismatch; live drift vs reviewed baseline; any push/reset executed; counts showing new rules/ledger rows unreviewed; any post-apply marker mismatch; missing owner authorization. Each stop preserves evidence and requires re-gating — never "retry and continue".

## Rollback and Recovery Boundaries

Reversing the migration (re-applying `max_bonus` bodies) restores code but CANNOT undo: any rule created post-fix, any earn posted post-fix (append-only ledger — reversal writes more rows, never deletes), any delivery unblocked by the fix. True recovery to pre-apply state requires the RESTORE POINT — which is exactly why the gate is non-negotiable. Forward-fix is the only in-model correction; restore is the only true rollback.

## Owner Approval Checklist (four independent approvals)

| Approval | Meaning | Status |
|---|---|---|
| CAP ACTIVATION APPROVAL | first-time cap effect acknowledged | VERIFIED (recorded prior) |
| RESTORE EVIDENCE | R1–R4 furnished | PENDING OWNER EVIDENCE → gate BLOCKED |
| APPLY-TIME TARGET CONFIRMATION | re-confirm project at the window | PENDING (at apply time) |
| PRODUCTION MIGRATION AUTHORIZATION | explicit standalone go for 0023 on prod | PENDING EXPLICIT AUTHORIZATION |

Cap approval is explicitly NOT migration authorization (restated per mandate).

## Current Blockers

1. Restore evidence absent (R1–R4) — BLOCKED.
2. Explicit production-migration authorization absent — PENDING EXPLICIT AUTHORIZATION.
3. Apply-time re-confirmation not yet due — PENDING (scheduled at window).

## Item classification summary

VERIFIED: isolated tests, file integrity, live baseline match, ACLs, zero data risk, cap-activation approval. PENDING OWNER EVIDENCE: restore existence/restorability/scope/owner. PENDING EXPLICIT AUTHORIZATION: migration go-ahead. BLOCKED: overall apply readiness (by restore gate). NOT EXECUTED: everything in §§Proposed Apply Sequence onward.

PHASE 54 COMPLETE — PLAN ONLY — PRODUCTION UNCHANGED
NO MIGRATION APPLIED
NO DATABASE WRITES
NO COMMIT
NO PUSH
NO DEPLOYMENT
