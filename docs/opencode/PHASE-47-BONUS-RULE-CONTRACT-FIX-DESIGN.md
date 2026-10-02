# PHASE 47 — BONUS RULE CONTRACT MISMATCH: INVESTIGATION AND FIX DESIGN

> **Type:** Read-only investigation + fix design. **No** database write, migration creation, or application file change was performed.
> **Date:** 2026-09-29
> **Authoritative input:** `docs/opencode/PHASE-46-BONUS-CURRENT-STATE-AUDIT.md` (§E.4 item L1)
> **Repositories inspected:** main repo `/home/adman/stitch_medlink_yemen` (HEAD `8e30112`) and git submodule `Medlik-Waap` (HEAD `5c0314f`).
> **Live database read-only inspection:** Supabase project `lmkomzqioneuyvatzsov` — catalog `SELECT` queries only (`pg_attribute`, `pg_proc`, `pg_trigger`, `pg_depend`, `information_schema`, `count(*)`). No function was executed; no INSERT/UPDATE/DELETE/DDL was issued.

---

## A. Confirmed Root Cause

### A.1 The defect in one sentence

Migration `0018` created the column **`max_earn`**; migration `0019` wrote its earn engine against a field named **`max_bonus`** that has never existed in any table, view, or type — so the rule-validation trigger and the delivery earn evaluator both reference an unresolvable composite field.

### A.2 Evidence chain

| # | Fact | Evidence | Status |
|---|---|---|---|
| 1 | The column is `max_earn numeric(12,2)` | `supabase/migrations/0018_bonus_financial_system.sql:133` | EXISTS LOCALLY |
| 2 | Live table `public.bonus_rules_v2` has `max_earn` and has **no** `max_bonus` | live `pg_attribute` scan: only `max_earn numeric(12,2)` returned | **VERIFIED LIVE IN THIS TASK** |
| 3 | No table anywhere in `public` has a `max_bonus` column | live scan of all `pg_attribute` in schema `public` for both names → single row (`bonus_rules_v2.max_earn`) | **VERIFIED LIVE IN THIS TASK** |
| 4 | `0019` never adds or renames any `max_*` column — it only adds `value_basis` and `product_values` | `0019_bonus_earn_engine.sql:31,34,37,41` (`grep -n 'max_'` → only lines 171/172/377/378) | EXISTS LOCALLY |
| 5 | `0019` references `max_bonus` exactly 4 times in the file | `0019:171`, `:172`, `:377`, `:378` (`grep -c` = 4) | EXISTS LOCALLY |
| 6 | Live `bonus_check_rule_v2` body contains `max_bonus` 3× and `max_earn` 0× | live `pg_proc.prosrc` occurrence count | **VERIFIED LIVE IN THIS TASK** |
| 7 | Live `bonus_evaluate_order_earn` body contains `max_bonus` 3× and `max_earn` 0× | live `pg_proc.prosrc` occurrence count | **VERIFIED LIVE IN THIS TASK** |
| 8 | No **other** function in any schema references either name except the two above | live scan of all `pg_proc.prosrc` for `max_bonus`/`max_earn` → 3 rows: the two functions + `create_order_with_items` (0 occurrences of both) | **VERIFIED LIVE IN THIS TASK** |
| 9 | The legacy table `bonus_rules` has neither column | live `pg_attribute` probe → `NONE` | **VERIFIED LIVE IN THIS TASK** |
| 10 | The design contract names the field `max_earn` | `docs/opencode/audit/LIVE-VERIFICATION-REPORT.md:495,615,648` (three independent statements, incl. the T3 column list) | EXISTS LOCALLY |
| 11 | The PWA writes and reads `max_earn` | `bonusFinancialApi.ts:56,86,177`; `BonusRulesV2Page.tsx:48,80,116,159,195,621,622` | EXISTS LOCALLY |
| 12 | The PWA's own client-side rule enforces the same semantic as `0019`'s validator | `BonusRulesV2Page.tsx:159` rejects `max_earn <= 0` when present; `0019:171` rejects `<= 0` when not null | EXISTS LOCALLY |

### A.3 Why the two names are the same concept (verified, not assumed)

The task explicitly forbade assuming synonymity. Each name's **actual meaning** was verified independently:

| Aspect | `max_earn` (the column) | `max_bonus` (the identifier in SQL) |
|---|---|---|
| Declared as | `numeric(12,2)`, nullable, no default, **no CHECK constraint** (live-verified) | never declared anywhere |
| Used by | written by the PWA payload (`toDbPayload`), read back into the PWA form; **never read by SQL** | read by `bonus_check_rule_v2` (reject `<= 0`) and by `bonus_evaluate_order_earn` (cap `v_earned`) |
| Business label (UI) | "الحد الأقصى للكسب (ر.ي)" — maximum earn (YER) | n/a (no UI) |
| Operational role | storage for the cap value | the cap logic itself |

There is **no other candidate source** for `max_bonus`: no column, no view attribute, no JSON key, no API field, no Flutter/TypeScript symbol (verified by exhaustive repository grep across both repos: `max_bonus` appears only in `0019`, in the live function bodies, and in the PHASE-46 report). The two identifiers therefore denote one concept — a cap on the earned bonus amount — with the column name being the only implemented one.

### A.4 Failure mechanism (derived from two independently verified live facts)

`p_rule` / `v_rule` are PL/pgSQL variables of composite type `public.bonus_rules_v2`. Field access on such a variable is resolved at statement execution against the type's attribute list. Since the type has no `max_bonus` attribute (fact A.2 #2), the statements at `0019:171` and `0019:377-378` raise **`record "bonus_rules_v2" has no field "max_bonus"`** (SQLSTATE 42703) whenever they execute.

| Path | Executed statement | Result |
|---|---|---|
| `INSERT`/`UPDATE bonus_rules_v2` | BEFORE trigger `trg_bonus_rules_v2_validate` → `bonus_rules_v2_validate_trigger` → `bonus_validate_rule_v2` → `bonus_check_rule_v2` → line 171 | error → the write is rejected |
| `orders.status → delivered` | AFTER trigger `trg_bonus_on_order_delivered` → `bonus_evaluate_order_earn` → line 377 (unconditional per-rule statement) and the validator call at line 305 | error → the whole transaction aborts → **the `delivered` status flip rolls back** |

**One documented exception inside the blast radius:** for a **suspended** bonus account, `bonus_on_order_delivered` inserts the hold row and returns `NEW` **before** calling the evaluator, so that specific delivery path does not raise.

**Not a rename or a regression:** no migration ever created `max_bonus`, so nothing was renamed away from live. The identifier was wrong when authored.

---

## B. Contract Matrix

Legend: **MISSING** = nothing exists at that layer. The submodule column is empty throughout because `Medlik-Waap/supabase/migrations/0001…0016` contains **no** `bonus_rules_v2` DDL (verified: `grep -rln bonus_rules_v2` matches only the three main-repo files).

| # | Object | Main Repo Definition | PWA Submodule Definition | Live Definition | Referenced Fields | Evidence | Finding |
|---|---|---|---|---|---|---|---|
| 1 | `bonus_rules_v2.max_earn` | **COLUMN** — `0018_bonus_financial_system.sql:133` `max_earn numeric(12,2)` | MISSING (no DDL) | present: `numeric(12,2)`, nullable, no default, no comment, **no CHECK** | written by PWA payload; read by PWA form; **never read by any SQL function** | live `pg_attribute` + live column list; `bonusFinancialApi.ts:177`; `BonusRulesV2Page.tsx:116` | **EXISTING — the authoritative field** |
| 2 | `max_bonus` | **SQL IDENTIFIER ONLY** — `0019:171,172,377,378` | MISSING | present in 2 live function bodies (3 occurrences each) | `p_rule.max_bonus` (validator), `v_rule.max_bonus` (evaluator) | live `pg_proc.prosrc` occurrence counts (3 and 3) | **CONFLICT — resolves to no attribute; runtime error** |
| 3 | `bonus_check_rule_v2(p_rule public.bonus_rules_v2)` | `0019:88-180`, returns text, SECURITY DEFINER | MISSING | live, body length 3,942 chars | 13 distinct `p_rule.*` reads | live `pg_proc` (lang plpgsql, `prosecdef=true`) + local file | **IMPLEMENTED** — exactly one field unresolvable (`max_bonus`) |
| 4 | `bonus_evaluate_order_earn(p_order_id uuid)` | `0019:220-455`, returns int, SECURITY DEFINER | MISSING | live, body length 10,161 chars | 17 distinct `v_rule.*` reads | live `pg_proc` + local file | **IMPLEMENTED** — exactly one field unresolvable (`max_bonus`) |
| 5 | `bonus_rules_v2_validate_trigger()` | `0019:198-207` | MISSING | live, BEFORE INSERT OR UPDATE trigger | delegates to #3 | live `pg_trigger` def + local file | **EXISTING** — propagates #3's failure to every write |
| 6 | `bonus_validate_rule_v2(p_rule public.bonus_rules_v2)` | `0019:183-194` | MISSING | live; body contains neither name | calls #3 | live `pg_proc` occurrence count = 0 for both names | **EXISTING — clean** |
| 7 | `bonus_on_order_delivered()` | `0019:463-504` | MISSING | live; body contains neither name | calls #4 (and inserts holds) | live `pg_proc` + `pg_trigger` | **EXISTING — clean** |
| 8 | `bonus_process_pending(p_pending_id uuid)` | `0019:518-614` | MISSING | live; body contains neither name | replays `computed_value` only | live `pg_proc` occurrence count = 0 | **EXISTING — clean; replay unaffected** |
| 9 | `create_order_with_items(...)` | `0017:28-239` | MISSING | live; 0 occurrences of both names | — | live `pg_proc` occurrence counts = 0 | **EXISTING — clean** |
| 10 | PWA API type/field `max_earn` | — | `bonusFinancialApi.ts:56` (`BonusRuleV2Row`), `:86` (`BonusRuleV2Input`), `:177` (`toDbPayload`) | matches live column name/type | `max_earn` | code | **CONSISTENT with the DB column** |
| 11 | PWA UI form field + label | — | `BonusRulesV2Page.tsx:48,80,116,195,621`; label at `:616` "الحد الأقصى للكسب (ر.ي)" | — | `max_earn` | code | **CONSISTENT — defines the business meaning** |
| 12 | PWA client validation | — | `BonusRulesV2Page.tsx:159-160` → reject when present and `<= 0` | — | `max_earn` | code | **CONSISTENT with `0019:171`'s intended rule** |
| 13 | Flutter field / model | MISSING (grep = 0 in `medlink_app/lib`) | MISSING | MISSING | — | repo grep | **NOT FOUND — Flutter is not a consumer** |
| 14 | Legacy `bonus_rules` (Buy-X-Free-Y) | `0003:5`; no `max_*` column | submodule chain | live; `max_bonus`/`max_earn` probe = `NONE` | — | live `pg_attribute` probe | **SEPARATE MODEL — unaffected** |
| 15 | JSON key / API parameter named `max_bonus` | MISSING (0 matches in any `.sql`, `.dart`, `.ts`, `.tsx`, `.json`) | MISSING | MISSING | — | exhaustive grep (34 hits total, all accounted for in §A) | **NOT FOUND — no consumer depends on the wrong name** |
| 16 | Documented contract | `docs/opencode/audit/LIVE-VERIFICATION-REPORT.md:495,615,648` names **`max_earn`**; `PHASE-7-EARN-ENGINE-TEST-DESIGN.md:22` defines "TEST 9 max cap" | — | — | — | docs | **CONTRACT = `max_earn` (cap on earned value)** |

### B.1 Completeness check — is `max_bonus` the *only* mismatch?

Every field read in `0019` was compared against the live column list:

| Side | Distinct fields read | All present in the live table? |
|---|---|---|
| `p_rule` (validator) | `bonus_percent, bonus_value, customer_type, end_date, id, max_bonus, products_exclude, products_include, product_values, rule_type, start_date, value_basis` | **11 of 12** — only `max_bonus` is absent |
| `v_rule` (evaluator) | `bonus_percent, bonus_value, eligible_customers, end_date, governorate, id, is_stackable, max_bonus, min_order_value, min_quantity, products_exclude, products_include, product_values, rule_type, start_date, usage_limit, value_basis` | **16 of 17** — only `max_bonus` is absent |

Live column list (32 columns): `allow_cash, allow_discount, allow_product, approval_required, bonus_percent, bonus_value, cash_max, cash_min, cash_monthly_limit, created_at, created_by, customer_type, description, eligible_customers, end_date, governorate, id, is_stackable, max_earn, min_order_value, min_quantity, name, priority, product_values, products_exclude, products_include, rule_type, start_date, status, updated_at, usage_limit, value_basis`.

**Conclusion:** the contract mismatch is a single identifier. There is no second, hidden mismatch in this pair of functions.

---

## C. Affected Execution Paths

Full traced path (verified in code, both apps):

```
PWA UI (BonusRulesV2Page form)
  → component submit handler        BonusRulesV2Page.tsx:316 (update) / :319 (create) / :335 (status)
  → API layer (no Repository layer) bonusFinancialApi.ts:207 createBonusRuleV2 / :217 updateBonusRuleV2 / :225 setBonusRuleV2Status
  → PostgREST table write           .from('bonus_rules_v2').insert/update(toDbPayload)
  → DB trigger                      trg_bonus_rules_v2_validate (BEFORE INSERT OR UPDATE)   [VERIFIED LIVE]
  → bonus_rules_v2_validate_trigger → bonus_validate_rule_v2 → bonus_check_rule_v2           [VERIFIED LIVE]
  → line 171: `p_rule.max_bonus`  ✗ field does not exist on the composite type
  → ERROR: record "bonus_rules_v2" has no field "max_bonus"  → write rejected
```

```
Order delivery (Flutter driver/branch, or any status write)
  → orders.status = 'delivered'
  → AFTER trigger trg_bonus_on_order_delivered                [VERIFIED LIVE]
  → bonus_on_order_delivered() → bonus_evaluate_order_earn()  [VERIFIED LIVE]
  → line 305 bonus_check_rule_v2(v_rule)                     → same field error
  → line 377 `v_rule.max_bonus` (unconditional per-rule)     → same field error
  → EXCEPTION propagates (config/fatal class, by design)      → transaction aborts
  → the delivered status flip ROLLS BACK
```

| # | Function (as specified in the task) | Exists? | Affected? | Evidence |
|---|---|---|---|---|
| 1 | **Create a Bonus rule** | EXISTS (PWA only) | **YES — blocked** | `BonusRulesV2Page.tsx:319` → `bonusFinancialApi.ts:207` → validator line 171 |
| 2 | **Edit an existing Bonus rule** | EXISTS (PWA only) | **YES — blocked** | `BonusRulesV2Page.tsx:316` → `bonusFinancialApi.ts:217` → validator line 171 |
| 3 | **Rule status toggle (suspend/activate/archive)** | EXISTS (PWA) | **YES — blocked** | `setBonusRuleV2Status` (`bonusFinancialApi.ts:225`) performs an UPDATE → BEFORE UPDATE trigger fires → validator line 171 |
| 4 | **Evaluate the rule at order delivery** | EXISTS | **YES — blocked (status flip rolls back)** | `trg_bonus_on_order_delivered` (§A.4) |
| 5 | **Compute the earned Bonus value** | EXISTS as code; **never reachable with a cap set** | **YES — incomplete**: the cap branch (line 377-378) can never execute; `max_earn` is currently inert data with **no SQL reader at all** | live `prosrc` occurrence counts (0 readers of `max_earn`) |
| 6 | **Existing rules / historical data** | n/a | **NO DATA AT RISK** | live counts: `bonus_rules_v2` = 0, `bonus_pending_entitlements` = 0, `bonus_ledger` = 0, `bonus_audit_trail` = 0 |
| 7 | **Any other Bonus operation** (redemption, withdrawal, discount, reversal, expiry, opening balance, allocation, order creation) | EXISTS | **NOT AFFECTED** | live scan: only 2 functions in the whole database contain `max_bonus`; `create_order_with_items` = 0 occurrences of either name; `bonus_process_pending` = 0 |
| 8 | **Suspended-account delivery (hold path)** | EXISTS | **NOT AFFECTED** | `bonus_on_order_delivered` returns before the evaluator call (`0019:483-495`) |
| 9 | **Pending replay / processor** | EXISTS | **NOT AFFECTED** | `bonus_process_pending` replays the stored `computed_value` and never re-reads rule fields (live body contains neither name) |
| 10 | **Flutter rule management** | **NOT FOUND** | n/a | `grep bonus_rules_v2 medlink_app/lib` = 0 — Flutter never touches v2 rules |
| 11 | **Submodule (PWA repo) SQL** | **NOT FOUND** | n/a | the submodule migration chain has no `bonus_rules_v2` DDL |

### C.1 Practical status of the feature today

| Capability | Status |
|---|---|
| Creating a bonus rule from the director panel | **Broken** (every attempt fails at the DB validator) |
| Editing / toggling a rule | **Broken** (same trigger path) |
| Marking any order `delivered` while at least one active rule exists | **Broken** (the status flip rolls back) |
| Marking an order `delivered` when **no** active rule exists | Succeeds — the evaluator's rule loop body never executes, and the validator is only called inside the loop (`0019:305`) |
| The `max_earn` cap itself | **Never functional** — the value is stored but read by nothing |

---

## D. Migration History

### D.1 Chronology of the two names

| Order | Artifact | What it says | Consequence |
|---|---|---|---|
| 1 | `docs/opencode/audit/LIVE-VERIFICATION-REPORT.md:495,648` (pre-implementation design) | `bonus_rules_v2` includes **`max_earn`** | the contract was fixed as `max_earn` **before** any migration was written |
| 2 | `0018_bonus_financial_system.sql:133` | creates `max_earn numeric(12,2)` | the contract was implemented |
| 3 | `0019_bonus_earn_engine.sql:171,172,377,378` | references **`max_bonus`** | **the deviation is introduced here** — a field name that no artifact ever declares |
| 4 | `0020 / 0021 / 0022` | never mention either name (0 occurrences) | the deviation was never corrected |
| 5 | PWA `bonusFinancialApi.ts` / `BonusRulesV2Page.tsx` | read/write `max_earn` | the client side stayed faithful to the contract |
| 6 | Submodule `Medlik-Waap/supabase/migrations/0001…0016` | contain no `bonus_rules_v2` DDL at all | **the submodule did not create the divergence and must not receive a duplicate fix** |

### D.2 Why it survived every gate

| Gate | What it verified | Why the defect passed |
|---|---|---|
| `PHASE-4.3-FINAL-0019-REVIEW.md` §L | "Rule Validation Review — PASS … covering basis/type/xor/GENERAL/product_values-deep/dates/**sanity**/customer_type-gap" | The check was summarised as "sanity" with line references (`:167-173`) and never compared the literal field name against the `0018` column list. |
| `PHASE-15-RULES-V2-REVIEW.md:7` | "Table `bonus_rules_v2` columns match UI fields **1:1** (… value/percent/**max**/…)" | The 1:1 claim was asserted using the abbreviation "max" — precisely the assertion that is false for this one field. |
| `PHASE-5-0019-LIVE-PRECHECK.md` §I/§K | object/name collisions, referenced tables "verified present" | Table presence was verified; **composite field resolution inside function bodies was not**. |
| `PHASE-6-0019-LIVE-VERIFICATION.md` §F/§T/§U | live object presence using `position()` markers, and "Unexpected differences: None" | Markers searched for security-critical signals (`BONUS_CONFIG_ERROR`, replay paths, sentinels) — **not field names**; §T explicitly states full byte-diff was not performed. |
| `PHASE-7-EARN-ENGINE-TEST-DESIGN.md` §R | behavioural test design including "TEST 9 max cap" | **BLOCKED — TEST ENVIRONMENT REQUIRED**; no test was ever executed, so the error was never observed. |
| `PHASE-46` §E.4 | static live inspection | **this is where it was found** |

**Root-cause classification:** an authoring defect in `0019` combined with a verification blind spot — every gate checked *presence* of objects, never *resolution* of composite fields, and no gate ever executed the code.

---

## E. Minimal Fix Design

### E.1 Options considered, and why only one survives the evidence

| Option | Change | Verdict | Justification from evidence |
|---|---|---|---|
| **A — align the two SQL functions with the existing column** | `max_bonus` → `max_earn` in 6 identifier occurrences (2 in the validator, incl. its message; 4 in the evaluator) | **SELECTED** | `max_earn` is the declared column (live-verified), the PWA's read/write field, and the name in the pre-implementation design contract (`LIVE-VERIFICATION-REPORT` T3). Preserves the cap semantics exactly (`0019:377-378` intent). Nothing else must change. |
| B — rename the column `max_earn` → `max_bonus` | `ALTER TABLE … RENAME COLUMN` + rewrite the PWA | REJECTED | Breaks `bonusFinancialApi.ts`/`BonusRulesV2Page.tsx` (7 usages) and contradicts the recorded design contract; requires an application change, which this phase forbids; larger blast radius for zero gain. |
| C — add a second column `max_bonus` and keep both | `ADD COLUMN max_bonus` + copy values | REJECTED — **dangerous** | The PWA would keep writing `max_earn` while the engine reads `max_bonus`, so the cap would silently become `NULL` = **unlimited**. That converts a loud failure into a silent financial mis-statement. Also creates two competing sources of truth. |
| D — expose the value through a view / alias | create a view or a renamed composite | REJECTED | The field is accessed on a **function parameter of composite type**; a view cannot supply an attribute to `public.bonus_rules_v2`'s row type. It would also require changing the functions anyway. |
| E — change the composite type | recreate the table type with a `max_bonus` attribute | REJECTED | Table rewrite, dependency cascade, and the same PWA breakage as option B. |

### E.2 The exact change (design only — not created in this phase)

Two functions, six identifier occurrences, nothing else:

**Function 1 — `public.bonus_check_rule_v2(p_rule public.bonus_rules_v2)`, defined at `0019:88-180`**

| Location | Current text | Change to |
|---|---|---|
| `0019:171` | `if p_rule.max_bonus is not null and p_rule.max_bonus <= 0 then` | `if p_rule.max_earn is not null and p_rule.max_earn <= 0 then` |
| `0019:172` | `return format('Rule %s: max_bonus must be positive', p_rule.id);` | `return format('Rule %s: max_earn must be positive', p_rule.id);` (message text only — cosmetic, no behavioural effect; recommended so the error names the real field) |
| all other lines (89-170, 174-180) | unchanged | byte-identical |

**Function 2 — `public.bonus_evaluate_order_earn(p_order_id uuid)`, defined at `0019:220-455`**

| Location | Current text | Change to |
|---|---|---|
| `0019:377` | `if v_rule.max_bonus is not null and v_earned > v_rule.max_bonus then` | `if v_rule.max_earn is not null and v_earned > v_rule.max_earn then` |
| `0019:378` | `v_earned := v_rule.max_bonus;` | `v_earned := v_rule.max_earn;` |
| all other lines (220-376, 379-455) | unchanged | byte-identical |

**Semantics preserved exactly** — the cap continues to mean: *if the rule specifies a cap and the computed earn exceeds it, the earned amount equals the cap; otherwise the computed amount stands*. No change to stacking, priority ordering, usage limits, eligibility, minimums, value basis, `v_stop`, snapshots, idempotency keys, error classification, or account-mode handling.

**Deliberately NOT part of the fix:**

- no `ALTER TABLE` (the schema is already correct);
- no change to `0020`, `0021`, `0022`;
- no edit of `0019` itself (it is already applied live — editing it would desynchronise file and database);
- no duplicate migration in the `Medlik-Waap` submodule chain (it contains no `bonus_rules_v2` DDL, so a copy would create a **new** divergence, which the task forbids);
- no PWA or Flutter change;
- no change to grants/revokes/RLS.

### E.3 ACL handling (verified live, affects the migration text)

Live `pg_proc.proacl` for the two target functions:

```
bonus_check_rule_v2        = {postgres=X/postgres, anon=X/postgres, authenticated=X/postgres, service_role=X/postgres}
bonus_evaluate_order_earn  = {postgres=X/postgres, anon=X/postgres, authenticated=X/postgres, service_role=X/postgres}
```

Two consequences:

1. **`CREATE OR REPLACE FUNCTION` preserves the existing ACL** for an unchanged signature, so applying the fix introduces **no** privilege change. This is desirable and must be stated as an acceptance criterion.
2. **Secondary finding (recorded, not fixed):** `0019`'s `revoke all on function … from public` removed only the `PUBLIC` grant; Supabase's default privileges still grant `EXECUTE` to `anon`/`authenticated`/`service_role`. The claim in `PHASE-4.3` §M and `PHASE-6` §I that the internals are "revoked" is therefore only partially true — they are no longer public, but they remain callable by any authenticated client. This is a **security-posture observation outside the scope of Phase 47**; changing it would alter behaviour beyond the contract mismatch.

---

## F. Compatibility Analysis

| Layer | Touched by the fix? | Impact | Evidence / reasoning |
|---|---|---|---|
| **Flutter (`medlink_app`)** | No | **None** | Zero references to `bonus_rules_v2`, `max_earn`, or `max_bonus` in `medlink_app/lib` (grep = 0). Flutter has no v2 rule management UI. |
| **PWA (`Medlik-Waap/artifacts/pharma-pwa`)** | No | **None — becomes functional** | The PWA already sends `max_earn` (`bonusFinancialApi.ts:177`) and reads it (`:56,:86`). After the fix its rule form and status toggles succeed. No field-name change on this side. |
| **PWA client-side validation** | No | Consistent | `BonusRulesV2Page.tsx:159` rejects `<= 0` when present — identical rule to `0019:171`. No divergence introduced. |
| **Database schema** | No DDL | **Unchanged** | The fix is two `CREATE OR REPLACE FUNCTION` statements. No table, column, constraint, index, trigger, policy, or grant is added, removed, or renamed. |
| **DB function signatures** | Unchanged | **Binary-compatible** | `bonus_check_rule_v2(public.bonus_rules_v2)` and `bonus_evaluate_order_earn(uuid)` keep identical parameter types and return types; `CREATE OR REPLACE` replaces bodies only. |
| **Dependent objects** | None | **Unaffected** | The validator is reached through `trg_bonus_rules_v2_validate` (unchanged, references the function by name); the evaluator is reached through `bonus_on_order_delivered` (unchanged). No view or materialized view depends on `bonus_rules_v2` (live `pg_depend`/`pg_rewrite` probe returned only the table and the trigger). |
| **Grants / ACLs** | Preserved | **No privilege change** | `CREATE OR REPLACE` keeps the existing ACL (live ACL recorded in §E.3). Must be asserted after application (§I AC9). |
| **RLS policies** | Unchanged | **None** | 23 policies untouched; the fix adds no policy and no write path. |
| **Existing Bonus rules** | n/a | **No retroactive effect** | `bonus_rules_v2` = **0 rows** (live-verified). No stored cap value exists to reinterpret. |
| **Historical ledger / entitlements** | n/a | **No recomputation** | `bonus_ledger` = 0, `bonus_pending_entitlements` = 0, `bonus_earn_allocations` = 0, `bonus_audit_trail` = 0 (live-verified). |
| **Pending replay path** | None | **Unaffected by design** | `bonus_process_pending` replays `computed_value`; it never re-reads rule fields (live body contains neither name). Rule snapshots are built with `to_jsonb(v_rule)` (`0019:438`), i.e. dynamic — the stored key follows whatever the table actually has (`max_earn`), so existing snapshots (none today) would remain consistent. |
| **Earn calculation semantics** | Intended activation only | The cap starts applying for the first time | Before the fix the cap code is unreachable; after the fix a rule with `max_earn` set caps the earned amount — exactly what `PHASE-7` TEST 9 and the UI label ("الحد الأقصى للكسب") specify. This is the **intended** behaviour, not a policy change. With 0 rules there is no immediate observable change. |
| **Earning policy / limits** | Unchanged | None | No change to `allow_*`, minimums, `usage_limit`, `priority`, `is_stackable`, `value_basis`, `bonus_value`, `bonus_percent`, `eligibility`, or dates. |
| **Legacy Buy-X-Free-Y** | Untouched | None | `bonus_rules` (0003) has no `max_*` column (live probe = `NONE`); `create_order_with_items` (0017) contains neither name (live count = 0). The two models remain disjoint. |
| **Main vs submodule migration chains** | Main only | **No new divergence** | The submodule chain contains no `bonus_rules_v2` DDL (`grep -rln bonus_rules_v2 Medlik-Waap/supabase/migrations/` = empty). Adding the fix **only** to the main chain keeps the split exactly as it is today (the pre-existing `0016` divergence documented in PHASE-46 §C.3 is neither widened nor narrowed). |
| **Other apps / consumers** | None | **None** | No other consumer of `bonus_rules_v2` exists in either repository (grep across all file types). |

---

## G. Test Plan (isolated environment only)

**Mandatory constraint:** every test below must run against a **scratch/isolated Supabase project**, never `lmkomzqioneuyvatzsov`. No test in this plan was executed in Phase 47.

### G.1 Preconditions

- an isolated project with the main-repo chain applied through `0022`, then the fix migration;
- one throwaway director identity (the validator is not identity-gated, but the RLS write policy on `bonus_rules_v2` is director-only);
- one throwaway active product (needed by `PER_PRODUCT` validation and by earn evaluation);
- one throwaway client with a bonus account, one address, and one base branch;
- a **cleanup protocol**: because the ledger is append-only, financial fixtures must live in a dedicated scratch project (the same conclusion reached in `PHASE-7` §M).

### G.2 Test matrix

| # | Test | Setup | Action | Expected | Rule source (extracted, not assumed) |
|---|---|---|---|---|---|
| T1 | Validator accepts a rule with a cap | none | `insert into bonus_rules_v2 (name, rule_type, value_basis, bonus_value, max_earn) values (…, 500, 100)` | insert succeeds | `0019:171` — `<= 0` is the only forbidden case; `> 0` is valid. The PWA mirrors this at `BonusRulesV2Page.tsx:159` |
| T2 | Validator rejects a non-positive cap | none | same insert with `max_earn = 0` and again with `-1` | both rejected; message names `max_earn` | `0019:171-172` |
| T3 | Validator accepts a NULL cap | none | insert with `max_earn` omitted/null | insert succeeds | `is not null` guard at `0019:171`; column is nullable (live-verified, no default) |
| T4 | Full PWA payload shape is accepted | none | insert using the key set produced by `toDbPayload` (`bonusFinancialApi.ts:165-204`) | insert succeeds | proves the API contract matches the table |
| T5 | Update path | a rule from T1 | `update bonus_rules_v2 set name = … where id = …` | update succeeds → BEFORE UPDATE trigger passes | live trigger def: `BEFORE INSERT OR UPDATE` |
| T6 | Status toggle alone | a rule from T1 | `update … set status = 'suspended'` then `'active'` | both succeed | `setBonusRuleV2Status` (`bonusFinancialApi.ts:225`) is an UPDATE → same trigger |
| T7 | Cap applied | active rule: `value_basis='PER_ORDER'`, `bonus_value=500`, `max_earn=200`; order whose eligible slice >= 1 | deliver the order | exactly one `EARN` of **200** on `bonus_ledger`, key `SALES_EARN:{order}:{rule}` | `0019:353-379` (cap branch) |
| T8 | No cap | rule with `max_earn = NULL`, `bonus_value = 500` | deliver | `EARN` = 500 | `is not null` guard |
| T9 | Exactly at the cap | `bonus_value = 200`, `max_earn = 200` | deliver | `EARN` = 200 (strict `>` comparison — equality is not capped) | `0019:377` uses `v_earned > v_rule.max_earn` |
| T10 | Zero/negative computed earn | rule that computes 0 (e.g. excluded product slice) | deliver | **no** ledger row; no cap interaction; stacking stop semantics preserved | `0019:380-383` (`if v_earned <= 0`) |
| T11 | Cap combined with `PER_UNIT` / `PER_PRODUCT` | `PER_UNIT` qty 5 × 100 with `max_earn = 250`; `PER_PRODUCT` map values with a cap | deliver | capped value honoured in both bases | cap is applied after the basis switch (`0019:377`) |
| T12 | Idempotency unaffected | T7 scenario | re-fire the delivery (re-delivery attempt / processor retry / concurrent) | a single `EARN` row; key unique | `0019:386,402` + live unique index `bonus_ledger_idempotency_key_key` |
| T13 | Delivery no longer rolls back | active matching rule present | `update orders set status='delivered'` | status persists; earn created | the defect's primary symptom |
| T14 | Suspended-account hold path | account `status='suspended'` | deliver | hold row in `bonus_pending_entitlements`, status persists, **no** evaluator error | `0019:481-495` |
| T15 | Non-matching order | rule with `min_order_value` above the order | deliver | no earn, no error | validator still executes per candidate rule but now resolves correctly |
| T16 | Regression — Flutter suite | unchanged app | `flutter test` | 39/39 pass, `flutter analyze` = 4 pre-existing infos | baseline from PHASE-46 §K.1 |
| T17 | No accidental DDL | after applying the fix | compare `pg_attribute` snapshot of `bonus_rules_v2` and `information_schema.columns` before/after | identical column set | see §I AC1 |
| T18 | ACL preserved | after applying the fix | compare `pg_proc.proacl` before/after for the two functions | identical | §E.3 / §I AC9 |

### G.3 Documented ambiguities (recorded, not resolved by assumption)

| Ambiguity | What the code actually says |
|---|---|
| Is `max_earn = 0` allowed? | No when explicitly provided — the validator rejects `<= 0`. Only `NULL` means "no cap". |
| Negative cap? | Impossible via the app paths (validator + PWA validation reject it). **However** the table has **no SQL CHECK** on `max_earn` (live-verified), so a service-role direct write could bypass the validator... except that the validator is a BEFORE INSERT/UPDATE **trigger**, so it cannot be bypassed by any write path — including service-role. A `CHECK` constraint is therefore optional hardening, not a gap in enforcement. |
| Cap on the order total or on the earned amount? | On the **earned amount** (`v_earned`), applied after the basis computation. Confirmed by the UI label and by `0019:377`. |
| Interaction with `is_stackable` | None — the cap is applied per rule inside the loop; a capped non-stackable rule still stops later rules (`0019:451`). |

### G.4 What cannot be tested today

No isolated project exists (repository-wide search for a staging reference = 0 hits; only `lmkomzqioneuyvatzsov` is linked — see §H.3), so T1–T18 remain **designed, not executed**. Financial-fixture cleanup is still an open decision (`PHASE-7` §M).

---

## H. Migration Plan

### H.1 Is a new migration required?

**Yes — one migration, main repository only.** Rationale:

- `0019` is already applied to the live database and must not be edited (editing an applied migration desynchronises the file from the database, and the task forbids modifying existing migrations);
- the two functions are live objects; the only sanctioned way to align them with the schema is an idempotent `CREATE OR REPLACE` migration;
- the submodule chain has no `bonus_rules_v2` DDL, so a copy there would **create** a divergence (explicitly forbidden by the task).

### H.2 Proposed migration (described only — NOT created in this phase)

| Property | Value |
|---|---|
| Proposed file | `supabase/migrations/0023_bonus_rule_max_earn_contract_fix.sql` |
| Repository | main repo `/home/adman/stitch_medlink_yemen` |
| Type | Idempotent body replacement — `CREATE OR REPLACE FUNCTION` ×2, no DDL |
| Header comment must state | scope (only the `max_bonus`→`max_earn` alignment), the evidence reference (PHASE-46 §E.4 / PHASE-47 §A), the note that `0019` is intentionally untouched, and the instruction that this file is **not** auto-applied |
| Statement 1 | `create or replace function public.bonus_check_rule_v2(p_rule public.bonus_rules_v2) returns text …` — body copied verbatim from `0019:88-180` except `0019:171-172` (`max_bonus` → `max_earn`, message text likewise) |
| Statement 2 | `create or replace function public.bonus_evaluate_order_earn(p_order_id uuid) returns int …` — body copied verbatim from `0019:220-455` except `0019:377-378` (`max_bonus` → `max_earn`) |
| Statement 3 | `revoke all on function public.bonus_check_rule_v2(public.bonus_rules_v2) from public;` and `revoke all on function public.bonus_evaluate_order_earn(uuid) from public;` — restated verbatim from `0019:619-623` purely so a **fresh** database replaying `0001→0023` reproduces the same ACL state (no-op on the current live DB, where they are already revoked) |
| Statement 4 | `grant execute on function public.bonus_process_pending(uuid) to authenticated;` — restated verbatim from `0019:624` |
| Must NOT contain | any `ALTER TABLE`, `ADD/DROP COLUMN`, `CREATE INDEX`, trigger change, policy change, data statement, or any edit to `0020`/`0021`/`0022` semantics |
| Re-runnability | Fully re-runnable: `CREATE OR REPLACE` is idempotent; the revoke/grant statements are idempotent |
| Property/role requirement | Must be applied by a role that owns (or may replace) the two functions — the live owner is `postgres` (live-verified), i.e. the SQL-Editor/manual path |
| Authored line budget | ~475 lines, of which only 6 lines differ from the `0019` originals |

### H.3 Application rules for the future phase (documented, not executed)

| Rule | Reason |
|---|---|
| Apply **manually** (SQL Editor), following the project's established convention | `PHASE-5` §B established that the CLI migration-history table is absent — this is a manual-apply project |
| **Never** run `supabase db push` in this repository | `supabase/.temp/linked-project.json` shows the CLI is linked to the **production** project `lmkomzqioneuyvatzsov`; a push would target live |
| Apply first to an isolated project, then to production | §G requires behavioural proof before live application |
| Capture a before/after catalog snapshot (`pg_attribute`, `pg_proc.prosrc`, `pg_proc.proacl`, `pg_trigger`) | §I acceptance criteria are snapshot-based |
| Verify the pre-existing backup/restore point before touching live | `PHASE-5` §M recorded that no backup was ever verified |

---

## I. Acceptance Criteria

| # | Criterion | How to verify (read-only) | Expected |
|---|---|---|---|
| **AC1** | No schema change | compare `select attname, format_type(atttypid,atttypmod) from pg_attribute where attrelid='public.bonus_rules_v2'::regclass and attnum>0 and not attisdropped` before/after | byte-identical, still 32 columns including `max_earn`, still **no** `max_bonus` |
| **AC2** | Validator body aligned | `select (length(prosrc)-length(replace(prosrc,'max_bonus','')))/10 …` for `bonus_check_rule_v2` | `max_bonus` = **0**; `max_earn` = **3** |
| **AC3** | Evaluator body aligned | same computation for `bonus_evaluate_order_earn` | `max_bonus` = **0**; `max_earn` = **3** |
| **AC4** | No collateral function change | scan all `pg_proc.prosrc` in `public` for both names | only the two functions contain `max_earn` (3 each); **no** function contains `max_bonus`; `create_order_with_items` still contains neither |
| **AC5** | Rule creation works | staging: insert a valid rule through the PWA payload shape | succeeds (no `42703`) |
| **AC6** | Rule update + status toggle work | staging: `update … set name`, then `set status='suspended'` | both succeed |
| **AC7** | Non-positive cap rejected | staging: `max_earn = 0` and `= -1` | both rejected, message references `max_earn` |
| **AC8** | NULL cap = unlimited | staging: `max_earn` null, `bonus_value=500` → deliver | `EARN` = 500 |
| **AC9** | Cap enforced | staging: `bonus_value=500`, `max_earn=200` → deliver | `EARN` = 200 exactly |
| **AC10** | Equality is not capped | staging: `bonus_value=200`, `max_earn=200` → deliver | `EARN` = 200 |
| **AC11** | Delivery status persists | staging: `update orders set status='delivered'` with an active matching rule | status remains `delivered`; earn row created |
| **AC12** | ACLs unchanged | compare `pg_proc.proacl` for both functions before/after | identical to §E.3 values |
| **AC13** | Triggers unchanged | compare `pg_trigger` for `bonus_rules_v2`, `orders`, `order_items` before/after | identical definitions |
| **AC14** | No data touched | `count(*)` on `bonus_rules_v2`, `bonus_ledger`, `bonus_pending_entitlements`, `bonus_earn_allocations`, `bonus_audit_trail`, `order_cancellations` | production values unchanged by the migration itself (0 today) |
| **AC15** | Single source of truth for the name | repository grep for `max_bonus` in `supabase/migrations/` after the fix | only historical files (`0019` and the new migration's comment, if it mentions the old name for traceability) — no new definition |
| **AC16** | App regression clean | `flutter test` + `flutter analyze` (no app change expected) | 39/39 pass; 4 pre-existing infos |
| **AC17** | Legacy model intact | `create_order_with_items` and `bonus_rules` behaviour unchanged | no diff in `prosrc`; column probe still `NONE` |

---

## J. Remaining Risks

| # | Risk / open item | Severity | Why it remains open |
|---|---|---|---|
| J1 | The runtime failure (`42703`) is a **static inference** from two independently verified live facts (missing attribute; bodies referencing it). It was **not executed**, because calling the functions could be construed as operational use. | Low (inference is standard PostgreSQL semantics) | Confirmation belongs to §G T1–T3 in an isolated project. |
| J2 | **Secondary ACL finding:** live `bonus_check_rule_v2`, `bonus_evaluate_order_earn`, `bonus_validate_rule_v2`, `bonus_on_order_delivered`, `bonus_rules_v2_validate_trigger` retain `EXECUTE` for `anon` / `authenticated` / `service_role` despite `0019`'s revoke, which only removed the `PUBLIC` grant. `bonus_process_pending` also carries an explicit `PUBLIC` entry. | Medium | Out of scope for Phase 47 (a privilege change is a behaviour change). It also means an authenticated client could call the internal validator/evaluator directly — a hardening item for a later, decision-gated phase. |
| J3 | `0019` remains **unfixed in the repository** after the proposed migration | By design | Editing an applied migration is forbidden. Consequence: a fresh `0001→0022` replay still produces the defect until `0023` is applied. This must be understood by anyone replaying the chain. |
| J4 | `max_earn` has **no SQL CHECK** constraint (live-verified) | Low | Enforcement exists via the BEFORE trigger, which no write path can bypass. A CHECK would be redundant hardening; adding it would be a schema change outside this scope. |
| J5 | No isolated test environment exists | High (blocks behavioural proof) | Repository-wide search for staging = 0 hits; only `lmkomzqioneuyvatzsov` is linked. Financial-fixture cleanup is still undecided (`PHASE-7` §M). |
| J6 | CLI linked to **production** (`supabase/.temp/linked-project.json` → `lmkomzqioneuyvatzsov`) | Medium (operational) | Any `db push` would hit live. Must be neutralised procedurally (relink or never push) in the migration phase. |
| J7 | The fix **activates the cap for the first time** | Low today | With 0 rules there is no immediate effect; the first rule created afterwards will be capped. This is the documented contract, not a policy change, but it should be noted in the release notes of that phase. |
| J8 | Pre-existing, unrelated items carried from PHASE-46 | n/a | Two divergent `0016` copies; 3 live `financial_*` tables with no repo DDL; `PHASE-15`'s MEDIUM finding (edit wipes `eligible_customers`). None is touched or worsened here. |
| J9 | `bonus_rules_v2` rows are 0 **today**, so "no retroactive impact" is a snapshot statement | Low | If rules are created between now and the fix's application, they would have been impossible to create (the write fails), so the statement holds regardless of timing. |

---

## K. Next Phase Readiness

### K.1 Is the fix specified well enough to author a local migration?

# **YES**

The defect is a single, fully-identified identifier mismatch with:

- a fully verified correct name (`max_earn`) — live column, PWA field, documented contract;
- a fully enumerated change set — exactly 3 occurrences in each of exactly 2 functions, with line numbers;
- a preserved-semantics design — the cap logic and validation rule stay exactly as intended by `0019`;
- a zero-data-risk profile — 0 rules, 0 ledger rows, 0 pending rows, 0 allocations (all live-verified);
- a complete compatibility analysis — no app change, no schema change, no ACL change, no trigger change, no chain duplication (§F).

No business decision is required to author it: the fix restores the already-locked contract and changes no policy, limit, basis, eligibility rule, or accounting treatment.

### K.2 Exact scope of the next phase (description only — nothing created here)

**Create one file:** `supabase/migrations/0023_bonus_rule_max_earn_contract_fix.sql` in the **main repository** (`/home/adman/stitch_medlink_yemen/supabase/migrations/`).

**Containing exactly:**

1. `create or replace function public.bonus_check_rule_v2(p_rule public.bonus_rules_v2)` — source: `supabase/migrations/0019_bonus_earn_engine.sql:88-180`, with the single logical edit at lines 171-172 (`p_rule.max_bonus` → `p_rule.max_earn`, and the message string).
2. `create or replace function public.bonus_evaluate_order_earn(p_order_id uuid)` — source: `supabase/migrations/0019_bonus_earn_engine.sql:220-455`, with the single logical edit at lines 377-378 (`v_rule.max_bonus` → `v_rule.max_earn`).
3. The three restated privilege statements from `0019:619-624` (`revoke` ×2, `grant` ×1) so a fresh replay reproduces the ACL state.
4. A header comment recording: scope, the PHASE-46 §E.4 evidence, the fact that `0019` stays untouched, and that the file is applied manually.

**Authoring constraints for that phase:**

- every line outside the six edited identifiers must be byte-identical to the `0019` originals (verify with a diff after authoring);
- no `ALTER TABLE`, no data statement, no trigger/policy/index change;
- no change to `0019`, `0020`, `0021`, `0022`, or to any file in the `Medlik-Waap` submodule;
- the file must not be applied — application is a separate, explicitly requested step preceded by an isolated-environment test run (§G) and a before/after catalog snapshot (§I).

### K.3 Evidence the next phase must cite

| Claim in the migration header | Evidence reference |
|---|---|
| the column is `max_earn` | `0018_bonus_financial_system.sql:133` + live `pg_attribute` |
| the functions reference an absent field | `0019:171,172,377,378` + live `pg_proc.prosrc` occurrence counts (3 and 3) |
| no other object is affected | live scan: only those 2 functions contain `max_bonus`; `max_earn` has 0 SQL readers today |
| no data at risk | live counts: `bonus_rules_v2` = 0, `bonus_ledger` = 0, `bonus_pending_entitlements` = 0, `bonus_earn_allocations` = 0 |
| the contract is `max_earn` | `docs/opencode/audit/LIVE-VERIFICATION-REPORT.md:495,648`; `bonusFinancialApi.ts:177`; `BonusRulesV2Page.tsx:616` |

### K.4 Missing evidence required before *application* (not before authoring)

Authoring can proceed now. **Application** still requires, in order:

1. an isolated project to execute §G T1–T18 (currently absent — J5);
2. a verified restore point on production (`PHASE-5` §M recorded none);
3. an explicit decision to activate the cap for future rules (J7) — the activation is the intended contract, but it is the first time it becomes effective and should be acknowledged by the owner;
4. a procedural guard against `supabase db push` hitting production (J6).

No further investigation is needed to write the file. This phase stops here.

---

*Report produced under Phase 47 read-only rules. No file was modified except this report; no migration was created; no SQL write was executed; the two investigated functions were never called.*

**PHASE 47 — BONUS RULE CONTRACT INVESTIGATION COMPLETE**
