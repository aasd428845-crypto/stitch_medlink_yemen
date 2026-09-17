# MedLink Yemen — OpenCode V2 Project Instructions

## Mission
MedLink Yemen is a large multi-application system. The repository is the source of truth. Never invent architecture when the repository or its documentation can answer the question.

The public repository currently contains areas including:
- `.agents/memory`
- `.zcode/plans`
- `Medlik-Waap`
- `artifacts`
- `attached_assets`
- `docs`
- `lib`
- `medlink_app`
- `screenshots`
- `scripts`
- `supabase`
- workspace/configuration files

These names are repository observations, not assumptions about their final roles. Audit them before implementation.

## Critical rules
1. Before a major change, inspect the relevant code AND documentation.
2. Treat Supabase/database/API contracts as shared infrastructure.
3. Trace consumers before changing schema, auth, roles, models or API behavior.
4. Do not create the Windows application as an isolated system. It must reuse the same business/domain contracts and design language unless the architecture audit proves otherwise.
5. Do not delete or rewrite existing plans, memories, screenshots or documentation unless explicitly requested.
6. Do not expose secrets. Never commit service-role keys, passwords, tokens or private credentials.
7. Do not run destructive database commands against production.
8. Prefer additive, backward-compatible changes.
9. Avoid large unrelated refactors.
10. When uncertain, inspect and report rather than guessing.

## Change protocol
For non-trivial work:
- Analyze
- Map dependencies
- Plan
- Implement in small steps
- Format/lint/analyze
- Test
- Review the diff
- Report exactly what changed and what was verified

## UI protocol
Use existing screenshots/design docs/Figma when available. Maintain a shared design system across Flutter, Web/Admin and future Windows. Include loading, empty, error, disabled and permission states.

## Completion gate
A task is not complete until relevant verification is run or the exact reason it could not be run is reported.
