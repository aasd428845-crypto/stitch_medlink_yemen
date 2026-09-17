# OpenCode — MedLink Yemen V2

A project-specific OpenCode environment for the MedLink Yemen repository.

## What is different from V1?
V2 is designed around the actual repository structure and a non-destructive architecture-audit-first workflow. It includes:
- MedLink-specific Skills
- MedLink specialist subagents
- Current OpenCode V2 MCP configuration
- Audit prompts and output templates
- Rules for Supabase/RLS/database/API safety
- A Windows plan workflow for the not-yet-built client
- Web/Admin dashboard rules
- Shared design-system rules

## First use
1. Extract this kit into the repository root.
2. Review `opencode.json` and `AGENTS.md`.
3. Run OpenCode from the repository root.
4. Perform the first audit using `docs/opencode/FIRST-AUDIT-PROMPT.md`.
5. Do not implement features until the audit documents exist.

## Important
The kit does not pretend to know every detail of the repository. The audit is intentionally evidence-driven.
