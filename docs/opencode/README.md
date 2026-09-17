# MedLink Yemen OpenCode V2

This directory documents the workflow used by the V2 environment.

## Phase 0 — Repository Audit
Run the audit agent first. The expected deliverables are:
- `PROJECT_ARCHITECTURE.md`
- `PROJECT_APPLICATION_MAP.md`
- `PROJECT_DATABASE_MAP.md`
- `PROJECT_API_MAP.md`
- `PROJECT_AUTHORIZATION_MAP.md`
- `PROJECT_DESIGN_SYSTEM.md`
- `PROJECT_IMPLEMENTATION_STATUS.md`
- `PROJECT_RISKS.md`
- `PROJECT_WINDOWS_PLAN.md`

Do not generate these from guesses. They must be derived from repository evidence.

## Phase 1 — Baseline
Run formatting, static analysis and tests for each discovered application independently. Record current failures before making new changes.

## Phase 2 — Architecture
Resolve contradictions and define shared contracts before large implementation.

## Phase 3 — Implementation
Implement one bounded feature at a time, with tests and cross-client verification.

## Phase 4 — Windows
Use the audit outputs as the source of truth for the future Windows client.

## Phase 5 — Release
Only after verification, prepare target-specific builds and deployment steps.
