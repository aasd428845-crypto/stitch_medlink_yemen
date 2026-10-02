# PHASE 57 — BONUS RULE CONFIGURATION AUDIT (max_earn UI → DB)

> Type: code-trace audit only. No live tests, no DB writes, no app modifications. Live facts below are inherited from Phases 53/56 (explicitly marked), not re-queried here.

## 1. UI input → save trace (VERIFIED in code)

| Stage | Location | Behavior |
|---|---|---|
| Field | `BonusRulesV2Page.tsx:616-624` | text input (type=number, min=0, step=0.01), label "الحد الأقصى للكسب (ر.ي)", string state (`:48,80`), change handler `:622` |
| Read-back | `:116` | `max_earn != null ? String : ''` — round-trips null↔empty correctly |
| Client validation | `:159-160` | empty allowed; non-empty requires `Number(v) > 0`, else Arabic error; non-numeric (`NaN`) also rejected since `NaN > 0` is false |
| Mapping | `:195` + `toInput` helper | empty → `null`, else `Number(v)` |
| API payload | `bonusFinancialApi.ts:177` | `max_earn: input.max_earn ?? null` |
| Save paths | create `:207`, update `:217`, status toggle `:225` | all via PostgREST table writes → DB BEFORE trigger validates |

## 2. NULL handling — VERIFIED

Empty input → `null` at three independent layers (form mapper, API payload, DB column nullable with no default). Evaluator guards with `is not null` (0023), so NULL means unlimited by construction. Isolated T3/T8 proved it behaviorally.

## 3. Zero/negative validation — VERIFIED (contract match)

UI rejects `<= 0` and non-numeric; DB validator rejects `<= 0` with message naming `max_earn` (0023:142-143). Both layers agree exactly; neither layer contradicts the other. No CHECK constraint exists (live-verified earlier) — enforcement is trigger + UI, both present and consistent.

## 4. DB → functions trace — VERIFIED (code + isolated execution)

Column `numeric(12,2)` nullable → validator (`max_earn <= 0` reject) → evaluator (cap iff `is not null and earned > cap`, strict `>`). Post-fix live bodies confirmed identical to file (Phase 56). Unlimited vs capped divergence proven in isolation (T7: 500→200; T8: 500→500).

## 5. Test coverage map

| Behavior | Proven by | Scope |
|---|---|---|
| UI validation rules | code read only — no web tests exist | NOT VERIFIED at runtime |
| Payload shape acceptance | T4 (faithful key set, DB-level) | backend only |
| DB validator + cap logic | T1–T3, T5–T11 (isolated execution) | backend only |
| Idempotency/delivery/hold/skip | T12–T15 (isolated) | backend only |
| UI→DB end-to-end (form submit → trigger → earn) | nothing | NOT VERIFIED |
| Production behavior | nothing (forbidden) | NOT VERIFIED |

## 6. Gaps (documented, not fixed)

1. TECHNICAL GAP: no automated test asserts the UI validation + payload + trigger chain as one path (T4 covers keys, not the running UI).
2. TECHNICAL GAP: non-numeric input relies on `Number()` coercion agreement between TS and the DB trigger — aligned today, untested jointly.
3. NOT VERIFIED: any production behavior (standing rule — no live functional tests).
4. BUSINESS POLICY: none involved — cap semantics are locked contract; UI label matches it.

## 7. Classification summary

UI trace, NULL handling, zero/negative contract, DB trace, unlimited-vs-capped logic: VERIFIED (code + isolated execution). End-to-end UI→DB path, production behavior: NOT VERIFIED. Gaps 1–2: TECHNICAL GAP. No BUSINESS POLICY items.

PHASE 57 COMPLETE — AUDIT ONLY
NO DATABASE WRITES
NO FILES MODIFIED EXCEPT REPORT
NO COMMIT
NO PUSH
NO DEPLOYMENT
