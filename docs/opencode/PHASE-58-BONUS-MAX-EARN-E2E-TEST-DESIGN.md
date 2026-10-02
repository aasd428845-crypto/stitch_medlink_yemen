# PHASE 58 — BONUS MAX_EARN ISOLATED E2E TEST DESIGN (design only)

> Sources: PHASE-51 §§1–8 (executed T1–T18 pattern), PHASE-56 (live post-apply verification), PHASE-57 §§1–7 (UI→DB trace), 0023 file, `BonusRulesV2Page.tsx`, `bonusFinancialApi.ts`. Nothing executed here.

## 0. Design principles (binding on all cases below)

- Isolated Postgres only (container-internal socket, no host ports, no credentials to prod, synthetic `TEST_` fixtures, drop/recreate cycles). Connection target MUST be proven local (container name + no host bindings + empty-table start) before the first statement — Docker presence alone proves nothing.
- UI layer is driven, not mocked: form submit through the real `toDbPayload` shape (or the running PWA pointed at scratch via env, never defaulting to prod).
- No test touches production, creates migrations, or modifies app code. Stop rules per case are mandatory.

## 1. E2E-1 — Save positive cap, read back from DB

- Setup: isolated DB with 0001→0023 chain; director session/role.
- Input: UI form `max_earn = "250"` → submit → read row back (`SELECT max_earn ...`).
- Expected: stored `250.00 numeric`; UI re-render shows "250".
- Verification: DB value `= 250` AND UI string `= "250"` (both ends, closing the loop T4 left open).
- Cleanup: delete rule row (rules table has no immutability trigger — verify first; else suspend + annotate).
- Stop if: stored value differs in scale/rounding; UI shows stale value.

## 2. E2E-2 — Empty input becomes NULL

- Setup: as E2E-1.
- Input: clear field → submit → read back.
- Expected: `max_earn IS NULL`; UI shows empty; later delivery earns uncapped.
- Verification: `IS NULL` predicate (not 0, not empty string — column is numeric, so any non-null is a failure).
- Cleanup: as E2E-1. Stop if: NULL coerced to 0 anywhere in the chain.

## 3. E2E-3 — Reject zero, negative, non-numeric

- Setup: as E2E-1.
- Input: `"0"`, `"-5"`, `"abc"` each submitted.
- Expected: UI blocks with the Arabic validation message before any request; direct-DB attempt (bypassing UI, same isolated DB) rejected by trigger with message naming `max_earn`.
- Verification: zero new rows after all three; error text captured at both layers.
- Cleanup: none needed (nothing written). Stop if: any layer accepts (contract breach).

## 4. E2E-4 — Uncapped rule earns without artificial ceiling

- Setup: rule `bonus_value=500`, `max_earn=NULL`, matching order (paid slice ≥ 1).
- Input: deliver order through the real status path (trigger fires).
- Expected: exactly one `EARN` of 500, key `SALES_EARN:{order}:{rule}`.
- Verification: ledger row amount + key; no cap branch taken (code path, not just amount).
- Cleanup: scratch DB dropped/recreated per campaign (ledger append-only — never DELETE).
- Stop if: amount ≠ 500 or extra rows.

## 5. E2E-5 — Capped rule never exceeds cap

- Setup: rule `bonus_value=500`, `max_earn=200`.
- Input: deliver matching order.
- Expected: exactly one `EARN` of 200.
- Verification: amount = cap exactly; single row; audit row references rule + amount.
- Cleanup: per E2E-4. Stop if: 500 posted (cap ignored) or 0 rows (over-blocking).

## 6. E2E-6 — Equality boundary

- Setup: `bonus_value=200`, `max_earn=200`.
- Expected: `EARN` = 200 (strict `>` — equality is not a breach).
- Verification: amount 200 AND code-path reasoning recorded (comparison operator, not coincidence).
- Cleanup/stop: per E2E-4/5.

## 7. E2E-7 — No duplicate earn on re-execution

- Setup: delivered order from E2E-5.
- Input: re-fire delivery (status rewrite), plus concurrent double-fire if harness allows.
- Expected: still exactly one `EARN` row (UNIQUE key dedupes).
- Verification: `count(*) = 1` after each re-fire; no second audit earn row.
- Cleanup: per E2E-4. Stop if: count > 1 (idempotency broken — BLOCKED, do not proceed).

## 8. E2E-8 — Suspended / non-matching rules

- Setup: (a) rule suspended mid-campaign; (b) rule with `min_order_value` above the order total.
- Expected: (a) status toggle succeeds, rule skipped in evaluation; (b) no earn, no error, delivery persists.
- Verification: ledger empty for the order; no validator error (validator runs per candidate — must resolve, not raise).
- Cleanup: per E2E-4. Stop if: suspended rule fires or validator raises on valid-but-inapplicable rules.

## 9. E2E-9 — UI-displayed value matches stored value

- Setup: matrix of stored values (250, NULL, 0-rejected-at-entry, 199.99).
- Expected: for each, UI render ≡ DB value under the E2E-1/E2E-2 mapping (number→string, NULL→empty), both directions (display + edit round-trip).
- Verification: automated field-level assertions, not eyeballing; covers the `String()`/`Number()` coercion agreement flagged as untested in Phase 57.
- Cleanup: per E2E-4. Stop if: any asymmetry (display drift is a data-integrity bug).

## 10. Classification

| Item | Status |
|---|---|
| DB-behavioral coverage design (E2E-4–8) | EXISTING (executed as T7–T15 in Phase 51) |
| UI↔DB loop coverage (E2E-1–3, E2E-9) | TEST REQUIRED (designed here, never executed) |
| Isolated environment pattern | EXISTING (Phase 51 method: container + interleaved replay + synthetic fixtures + drop cleanup) |
| Staging/live execution of any E2E case | BLOCKED (no standing isolated env; scratch DB was dropped; re-bootstrap required) |
| Production behavior proof | NOT EXECUTED (forbidden without separate authorization) |

PHASE 58 COMPLETE — DESIGN ONLY
NO DATABASE WRITES
NO APPLICATION FILES MODIFIED
NO COMMIT
NO PUSH
NO DEPLOYMENT
