# PHASE 52 — BONUS FIX PRODUCTION READINESS REVIEW

> Type: read-only documentation review. No database connection was opened, no SQL executed, no migration applied, no file modified except this report. Sources: PHASE-47 §A–K, PHASE-50 §§0–9, PHASE-51 §§1–8 (read in full), `0018:133`, `0019:171,172,377,378`, `0023` (read in full in the prior session).

## 1. What Phase 51 proved (from its report, not from summary)

VERIFIED — all 18 PHASE-47 §G tests executed green in isolated Postgres 17 (`ph51_pg`, no host ports, scratch-only) after a 36-file interleaved replay: validator accept/reject/NULL (T1–T3), full PWA payload (T4), update + status toggle (T5–T6), cap enforcement 500→200 (T7), NULL unlimited (T8), equality boundary (T9), zero-earn silence (T10), PER_UNIT + PER_PRODUCT caps (T11), idempotent re-delivery (T12), delivery persistence (T13), suspended hold (T14), non-match skip (T15), Flutter 39/39 + 4 pre-existing infos (T16), identical column fingerprint (T17), identical ACLs (T18). The pre-fix defect was reproduced in-scratch (`42703` on rule write), then eliminated post-0023 (0/3 `max_bonus`, 3/3 `max_earn` per function). Scratch DB dropped afterward; `ph51_before` untouched.

## 2. What isolated tests cannot prove about production

- That production's function bodies match the reviewed file (live `prosrc` last fingerprinted in earlier phases, not re-measured at apply time).
- That no concurrent production write collides with the apply window (isolated run had zero contention).
- That the manual apply itself is byte-correct (paste/encoding risk in SQL Editor unaddressed).
- That a restore point exists or restores (never verified — see §3).
- Volume/latency behaviour (scratch held single-row fixtures; no load profile exists).
- That owner intent covers first-time cap activation (a business acknowledgement, not a technical property).

## 3. Restore-point checklist (verification method only — nothing created here)

| # | Item | Source expected | Date required | How to verify restorability (future, read-only first) |
|---|---|---|---|---|
| R1 | Full production backup exists | Supabase dashboard → Backups (project `lmkomzqioneuyvatzsov`) | Dated **before** any apply, retained through verification | List backups via dashboard; record ID + timestamp + size |
| R2 | Backup is restorable | Same dashboard / documented restore drill | Drill result on record, not assumed from existence | Owner confirms a prior successful restore (any project) or schedules a drill |
| R3 | Pre-apply catalog snapshot | `pg_attribute` (`bonus_rules_v2`), `pg_proc.prosrc` + `proacl` (both functions), `pg_trigger`, row counts (`bonus_rules_v2`, `bonus_ledger`, `bonus_pending_entitlements`, `bonus_earn_allocations`) | Immediately pre-apply | Read-only SELECTs; compare post-apply (AC1/AC12–AC14 pattern) |
| R4 | Post-apply diff | Same snapshot queries | Immediately post-apply | Only the two intended bodies differ; everything else byte-identical |

Status of all four today: PENDING OWNER APPROVAL (R1/R2 never verified per PHASE-5 §M; R3/R4 are procedural steps awaiting execution).

## 4. Future live verification steps (specified, NOT executed — no connection opened here)

1. `prosrc` occurrence counts for both functions (`max_bonus`→0, `max_earn`→3 each) — read-only `pg_proc` SELECT.
2. Signature/attribute check (`returns`, `security definer`, `search_path`, `plpgsql`) unchanged.
3. ACL check: `proacl` identical to PHASE-47 §E.3 values for both functions.
4. Trigger inventory unchanged (`trg_bonus_rules_v2_validate`, `trg_bonus_on_order_delivered`, ledger guard).
5. Row counts unchanged by the apply itself (migration contains no data statements — AC14).
6. Functional smoke (owner-gated, post-restore-point only): create-then-delete... NO — ledger-adjacent writes are append-only; smoke must use a rule INSERT followed by explicit rule DELETE (rules table has no immutability trigger — verify first) or accept the created rule as a real (if inert, zero-earn) row with owner sign-off. Do not assume deletability; confirm trigger coverage on `bonus_rules_v2` delete path before planning cleanup.

## 5. max_earn activation impact (technical facts vs owner decision)

Technical facts (VERIFIED in isolation): today the cap branch is dead code — no rule can exist (writes rejected), so no earn has ever been capped; post-fix, the FIRST rule created with a non-null `max_earn` will cap at that value, and the first active rule of any kind re-enables deliveries that currently roll back. Zero retroactive effect is guaranteed structurally (0 rules, 0 ledger rows at last live count — re-confirm counts pre-apply since production is live and counts may have changed). Owner decision required (PENDING OWNER APPROVAL): acknowledge that applying the fix simultaneously (a) unblocks rule management and deliveries and (b) activates capping for the first time — intended contract behavior, but the first observable financial effect, and therefore a release note, not a silent migration.

## 6. db push / db reset risks under the production CLI link

The repo CLI remains linked to `lmkomzqioneuyvatzsov` (verified in prior phases; not re-checked here per no-login rule — treat link as PRESENT). Consequences: `supabase db push` from this tree would apply the working-tree migration state to production, including the divergent/duplicate pairs documented in Phase 8 (0015/0016 exist in both chains with different content) and any stray local files; `db reset` against linked is destructive. Controls (unchanged from prior phases, restated not implemented): never run push/reset/linked-write commands from this tree; apply 0023 ONLY via manual SQL Editor paste; keep `SUPABASE_ACCESS_TOKEN` unset; never rely on `supabase/.temp` state. Risk rating: procedural, high-severity if violated, fully avoidable by the mandated manual path.

## 7. Go / no-go conditions

PROCEED to application only when ALL hold (else STOP):
1. R1–R2 restore point verified (owner evidence, §3). — PENDING OWNER APPROVAL
2. R3 pre-apply snapshot recorded; live counts re-confirmed (0-rule assumption is time-sensitive). — PENDING LIVE VERIFICATION
3. Owner acknowledgement of first-time cap activation (§5). — PENDING OWNER APPROVAL
4. Manual-apply path confirmed (SQL Editor, post-0019 semantics, paste-verified byte count). — PENDING OWNER APPROVAL
5. Post-apply §4 checks executed green (AC1–AC18 pattern). — PENDING LIVE VERIFICATION
6. `db push`/reset ban restated to the operator immediately before the window. — procedural, at apply time

STOP conditions (any one blocks): no verified restore point; live counts show rules/ledger rows appeared without review; prosrc already differs from the reviewed baseline (means live drifted — re-audit first); any push/reset executed against production; owner acknowledgement missing.

## 8. Item classification

| Item | Status |
|---|---|
| 0023 file correctness (rename-only, 6 identifiers) | VERIFIED (isolated execution + static gates) |
| Cap semantics (accept/reject/NULL/cap/equality/zero/multi-basis/idempotent/hold/skip) | VERIFIED (T1–T15) |
| No schema/ACL drift from the fix | VERIFIED (T17/T18 fingerprints) |
| App regression | VERIFIED (T16, 39/39 + 4 pre-existing infos) |
| Restore point existence + restorability | PENDING OWNER APPROVAL |
| Live prosrc/ACL/counts at apply time | PENDING LIVE VERIFICATION |
| First-cap-activation acknowledgement | PENDING OWNER APPROVAL |
| Manual-apply execution + post-apply checks | PENDING OWNER APPROVAL (future phase) |
| db push/reset ban enforcement | procedural control, restated |
| PHASE-48 report (cited by §§50/51, absent from docs/) | documentation gap noted — does not block (its claimed content is covered by §§50/51 evidence) |

No final production approval is issued: isolated success is necessary but not sufficient; the gate is the §7 checklist, owned by the system owner.

PHASE 52 COMPLETE
NO DATABASE CONNECTIONS
NO SQL EXECUTED
NO MIGRATION APPLIED
NO COMMIT
NO PUSH
