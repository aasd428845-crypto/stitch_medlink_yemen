# MedLink Yemen — First Run Audit

DO NOT MODIFY APPLICATION FILES.

You are performing the first repository audit for a large multi-application product.

Read the repository structure and existing documentation before making assumptions. Pay special attention to:
- `.agents/memory`
- `.zcode/plans`
- `docs`
- `lib`
- `medlink_app`
- `Medlik-Waap`
- `supabase`
- `scripts`
- `artifacts`
- `attached_assets`
- `screenshots`
- workspace files

Determine actual roles from file contents, not folder names alone.

Map:
1. every application/package;
2. Flutter mobile/desktop/web targets;
3. existing Web/Admin dashboard;
4. future Windows requirements;
5. Supabase schema, migrations, functions, policies and auth;
6. data flows and shared models;
7. API/service boundaries;
8. roles and permissions;
9. design system and visual references;
10. tests and current verification state;
11. build/deployment configuration;
12. dependencies and external services;
13. implemented/partial/planned/missing work;
14. duplicated or conflicting implementations;
15. security and architectural risks.

Create the following documents in `docs/opencode/audit/`:
- PROJECT_ARCHITECTURE.md
- PROJECT_APPLICATION_MAP.md
- PROJECT_DATABASE_MAP.md
- PROJECT_API_MAP.md
- PROJECT_AUTHORIZATION_MAP.md
- PROJECT_DESIGN_SYSTEM.md
- PROJECT_IMPLEMENTATION_STATUS.md
- PROJECT_RISKS.md
- PROJECT_WINDOWS_PLAN.md

Every important conclusion must cite the repository file/path that supports it.

Do not implement features. Do not delete or rewrite existing documentation.
