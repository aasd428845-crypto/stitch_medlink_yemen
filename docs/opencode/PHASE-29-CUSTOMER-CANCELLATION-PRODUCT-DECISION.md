# PHASE 29 — CUSTOMER CANCELLATION PRODUCT DECISION ANALYSIS (analysis only)

## 1. Executive Summary
Four open decisions (BD-1 storage, BD-2 format, BD-3 authorizer set, BD-4 requiredness) analyzed against verified code: roles are client/branch_manager/driver/company_director (`constants.dart:24-28`); RLS order-updates admit branch_manager/director/assigned-driver but NOT client (0002:156-161); 0021 admits client/branch_manager/director with differentiated gates and zero client UI wired. Locked constraints bounding all options: H1 pending-only client cancel, H3 fail-closed, compensating-only reversal, cancel+recreate (no patching), no `parentOrderId` migration, no payment track. No selection made anywhere below.

## 2. Locked Decisions (carried, not reopened)
H1 pending-only customer cancellation; H3 fail-closed; discount reversal compensating-only with POSTED immutability; edit = cancel + reorder; no migration for `parentOrderId` existence; payment out of scope. All verified consistent with 0021 text and current code; no conflict found.

## 3. BD-1 Cancellation Reason Storage
OPTION A column (`orders.cancellation_reason` nullable text, possibly + `cancelled_at`/`cancelled_by` — note: no `updated_at` exists today): queryable via existing order reads; inherits orders RLS (client-own/director/branch per existing policies); audit unchanged (reason already logged on success); model +1 field; API transparent; one additive migration; repeated cancels overwrite single value (history only in audit); reporting via simple GROUP BY; company-specific = future column or companion table; 0021-compatible (no signature change — reason already a param).
OPTION B dedicated table (`order_cancellations`: order FK unique, reason, cancelled_by, cancelled_at, previous_status): full history, multi-attempt records, appeal-ready; needs table + RLS + model + reads + migration; best reporting; same 0021 compatibility.
OPTION C other: no metadata mechanism exists (verified absent) — no candidate; excluded on evidence, not preference.
Effects stated without ranking; costs differ in schema weight vs history depth.

## 4. BD-2 Reason Format
A fixed codes (conceptual examples only, nothing added): UX = tappable list, reporting = aggregatable, l10n = new keys per code, analytics = clean, abuse = constrained input, DB = text/code column, multi-company = divergences need per-company sets (FUTURE ARCHITECTURAL DEPENDENCY — no tenant store exists). B free text: UX = flexible, reporting = weak, l10n = none, analytics = noisy, abuse = open input (length-capped), DB = text, multi-company = uniform. C code + optional note: superset properties of both; needs two fields. D company-configurable: impossible today — FUTURE ARCHITECTURAL DEPENDENCY (no tenant/company configuration); recorded, not built.

## 5. BD-3 Cancellation Authorization
Current truth: client cancels NOTHING today (no UI, no RLS update right); branch cancels via direct writes (UI exists); director may via RLS but has no UI; assigned driver may via RLS but has no UI and is excluded from 0021. Options: A customer-only (narrowest new surface; branch keeps direct-write path → two-track cancel mechanics persist); B customer + branch manager (matches the only existing cancel UI; both routed via 0021 if branch action is swapped); C customer + director/admin (covers escalation path for H3 aborts); D all system-supported roles per 0021 gates (client pending-only, branch own-branch, director all, driver excluded — exactly what the file enforces). Each option's enforcement lives server-side in 0021; RLS needs no change for B/C/D as long as the RPC (not direct writes) becomes the path. No permission invented beyond what code+RLS+0021 already describe; no change made.

## 6. BD-4 Reason Requiredness
0021 REQUIRES non-empty `p_reason` (line 61) — any UI must supply something. Options: A required (collect explicit reason every time; matches RPC contract directly); B optional (UI sends fixed default string when skipped — default text itself becomes the policy content); C conditional (e.g., required when discount present, default otherwise — provable states only: discount-present vs absent are detectable client-side from own ledger; all other conditions would be new business rules and are NOT introduced here). Effects: A maximizes report quality, adds friction; B minimizes friction, dilutes analytics; C balances on verifiable state only.

## 7. Multi-Company Product Analysis
Per BD, each option marked as GLOBAL PRODUCT DEFAULT (ships uniformly today), FUTURE COMPANY CONFIGURATION (needs tenant store — absent, recorded as dependency), or GLOBAL NOW + CONFIGURABLE LATER: BD-1 storage shape → GLOBAL NOW (one shape for all) + history depth per company FUTURE; BD-2 taxonomy → GLOBAL NOW (fixed-or-free per decision) + per-company sets FUTURE; BD-3 authorizer set → GLOBAL NOW (mirrors existing roles) + per-company matrices FUTURE; BD-4 requiredness → GLOBAL NOW + CONFIGURABLE LATER. No tenant architecture invented or assumed.

## 8. Lifecycle Analysis
Pending → request + reason → server validation (auth/role/ownership/state) → atomic cancel (+conditional reversal) → dual audit → cancelled response → UI reloads. Timeout → same-key retry converges (no duplicate money). Duplicate → existing result. Already-cancelled → converge (reversal-only if stranded, else silent). Non-pending (client) → reject + reload. Reversal failure → full rollback, status unchanged, error surfaced. Screen-change mid-flight → response arrives to dead context; idempotent retry from refreshed state is safe (no double-submit: controller busy guard + retained key pattern already built for discount, reusable shape for cancel).

## 9. Reporting Analysis
Future reporting needs (counts, reasons, per-client/branch/period, discount-linked, reorder-linked): OPTION A answers all single-value questions via GROUP BY; multi-attempt/appeal questions need OPTION B; free-text (BD-2/B) weakens aggregation under either storage; audit alone cannot serve per-order readback (append-only, no order-level query path). No analytics built here.

## 10. Decision Matrix
| Decision | Option | Product Impact | Technical Impact | Reporting | Multi-Company | Requires New Schema | Status |
|---|---|---|---|---|---|---|---|
| BD-1 | A column | minimal surface | 1 column + model | single-value GROUP BY | global now | Yes (additive) | BUSINESS DECISION |
| BD-1 | B table | history-ready | table + RLS + reads | full history | global now | Yes (additive) | BUSINESS DECISION |
| BD-1 | C other | none available | — | — | — | — | TECHNICAL GAP (no mechanism) |
| BD-2 | A codes | tappable UX | text/code + l10n | aggregatable | global now, sets FUTURE | No (uses BD-1 store) | BUSINESS DECISION |
| BD-2 | B free text | flexible UX | text + length cap | weak | global now | No | BUSINESS DECISION |
| BD-2 | C code+note | superset | two fields | best | global now | No | BUSINESS DECISION |
| BD-2 | D configurable | deferred | needs tenancy | per-company | FUTURE | FUTURE ARCHITECTURAL DEPENDENCY | FUTURE |
| BD-3 | A customer-only | narrowest surface | 0021 as-is | actor=client | global now | No | BUSINESS DECISION |
| BD-3 | B +branch | matches existing UI | branch swap to RPC | mixed actors | global now | No | BUSINESS DECISION |
| BD-3 | C +director | escalation covered | no UI needed now | mixed actors | global now | No | BUSINESS DECISION |
| BD-3 | D all per 0021 | uniform path | 0021 as-is | full | global now | No | BUSINESS DECISION |
| BD-4 | A required | max report quality | reason sheet | complete | global now | No | BUSINESS DECISION |
| BD-4 | B optional+default | min friction | default string | diluted | global now | No | BUSINESS DECISION |
| BD-4 | C conditional | balanced on provable state | discount check | partial | global now | No | BUSINESS DECISION |

## 11. Owner Decision Sheet
BD-1 — Question: where is the cancel reason stored? Options: A nullable column on orders / B dedicated cancellations table / C none viable. Current Evidence: zero reason storage repo-wide; audit carries reason on success only. Affected Files: order model/service/controller/detail UI (future). Affected Backend: additive migration (A or B). Affected UI: reason control + display. Affected Migration: new file required (either option). Decision: OWNER INPUT REQUIRED.
BD-2 — Question: what shape is the reason? Options: A fixed codes / B free text / C code+note / D company-configurable (FUTURE dependency). Current Evidence: no taxonomy anywhere; l10n system ready for codes. Affected Files: l10n + detail sheet. Affected Backend: none beyond BD-1 store. Affected UI: reason control shape. Affected Migration: none beyond BD-1. Decision: OWNER INPUT REQUIRED.
BD-3 — Question: who may cancel? Options: A customer-only / B +branch / C +director / D all per 0021 gates. Current Evidence: branch-only UI today; RLS admits branch/director/driver; 0021 gates client/branch/director. Affected Files: branch actions + future detail entry. Affected Backend: 0021 as specified (no change). Affected UI: entry points per role. Affected Migration: none. Decision: OWNER INPUT REQUIRED.
BD-4 — Question: is reason required? Options: A always / B optional+default / C conditional on provable state. Current Evidence: RPC rejects empty (0021:61). Affected Files: detail sheet validation. Affected Backend: none. Affected UI: form behavior. Affected Migration: none. Decision: OWNER INPUT REQUIRED.

## 12. Implementation Gate
BD-1: IMPLEMENTATION BLOCKED (store must exist before final cancel UI). BD-2: IMPLEMENTATION CAN PROCEED in UI-skeleton form (control shape swappable; l10n keys additive) but final UX needs the decision. BD-3: IMPLEMENTATION CAN PROCEED per-role incrementally (branch swap needs no decision if D chosen as-is; client entry needs H1 approval carried from 22.2). BD-4: IMPLEMENTATION CAN PROCEED (validation branch covers all options; default string is one line when decided). No implementation started.

## 13. Evidence / File References
Roles `constants.dart:24-28`; RLS 0002:156-161 (no client update); 0021:61 reason requirement, :64-97 auth gates, :114-148 reversal, :152-167 status+audit; zero reason/metadata matches repo-wide; zero client cancel matches; `parentOrderId` model-only (+schema, zero I/O); audit `reason` 0018:322; notification precedent `related_offer_id` (no order equivalent).

## 14. Final Status
Transport note: one ECONNRESET on an empty call; content delivered in smaller chunks, none lost. No other timeouts/failures/corrections; no report-vs-code discrepancies found.

PHASE 29 COMPLETE — CUSTOMER CANCELLATION PRODUCT DECISION ANALYSIS
NO CODE MODIFIED
NO DATABASE CHANGES
NO SQL EXECUTED
NO MIGRATION CREATED
NO COMMIT
NO PUSH
