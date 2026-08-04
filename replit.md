# MedLink Yemen — Flutter App

A B2B medical supply ordering platform for Yemen, built in Flutter (web-served on Replit). Supports three user roles: **client (pharmacist/buyer)**, **branch manager**, and **driver/delivery**.

---

## How to run

The app runs via the **"Flutter MedLink App"** workflow:

```
cd medlink_app && flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0
```

It launches at **port 3000** as Flutter Web. It is not a standard Replit artifact (Flutter Web is not a supported artifact type), so it does not appear in the Preview dropdown — it runs as a plain workflow. View it from the Workflows panel.

---

## Stack

| Layer | Technology |
|---|---|
| UI framework | Flutter (Dart) |
| State management | Provider + ChangeNotifier |
| Navigation | GoRouter (role-guarded routes) |
| Backend | Supabase (Postgres + Auth + RLS) |
| Localisation | flutter_localizations + ARB (Arabic default, RTL) |
| Code gen | freezed + json_serializable |

---

## Architecture rules (from CLAUDE.md / project spec)

- Every Supabase call logs via `AppConstants.supabaseDebugTag` (`'SUPABASE_DEBUG'`).
- **Never** `INSERT`/`UPSERT` into `public.users` manually — the DB trigger handles profile creation on auth sign-up.
- All business logic lives in `*Service` classes; `*Controller` classes are `ChangeNotifier` wrappers for UI state only.
- `flutter analyze` must exit with **`No issues found!`** before closing any phase.
- Role `company_director` is recognised and immediately rejected (auto sign-out) — no UI is ever rendered for it.

---

## Project structure

```
medlink_app/lib/
├── l10n/              # ARB translation files (app_ar.arb, app_en.arb)
├── models/            # freezed data models (product, order, branch, user_profile, …)
├── routing/           # app_router.dart — GoRouter + role/status guards
├── screens/
│   ├── auth/          # login, register, terms, pending_approval, account_status
│   ├── client/        # home_tab, catalog_tab, product_detail, cart, checkout, orders, order_detail
│   ├── branch_manager/# branch_manager_home_shell (Phase 4: dashboard, orders, inventory, invoices, drivers)
│   ├── driver/        # driver_home_shell (Phase 6: assigned orders, map, rating)
│   └── shared/        # splash_screen, coming_soon_scaffold
├── services/          # auth_service/controller, catalog_service/controller,
│                      # order_service/controller, cart_controller
├── utils/             # constants.dart, theme.dart, error_mapper.dart
└── widgets/           # shared UI components
```

---

## Supabase configuration

Credentials live in `medlink_app/lib/utils/constants.dart`. The anon key is safe to embed in Flutter client code — security is enforced entirely via Postgres RLS policies, not key secrecy.

- **URL**: `https://lmkomzqioneuyvatzsov.supabase.co`
- Migrations: `0001_initial_schema.sql` and `0003_bonus_commission_approval_notifications.sql` are already applied to the live database.
- `0002_catalog_inventory_orders.sql` (products, inventory, promotional_offers, client_addresses, orders, order_items) was also applied as part of Phase 2.

---

## Development phases

| Phase | Status | Description |
|---|---|---|
| 1 | ✅ Done | Foundation: Supabase auth, GoRouter, i18n, role guards, pending-approval gate |
| 2 | ✅ Done | Catalog, product detail, cart, bonus rules, checkout, order success (client) |
| 3 | 🔜 Next | Branch manager dashboard: orders, inventory, invoices, drivers |
| 4 | — | Driver account management (via Edge Function) |
| 5 | — | Driver interface: assigned orders, maps, earnings |
| 6 | — | Notifications + promotional offers |
| 7 | — | Driver ratings + help/support |
| 8 | — | Live chat + live driver location |

---

## Testing accounts

Register accounts directly in the app, then set `role` and `account_status = 'active'` manually in the Supabase Table Editor for `public.users`. No hardcoded test credentials exist in the app.

---

## User preferences

- Arabic is the default and only active locale; RTL layout is enforced globally.
- Keep the existing folder structure (`screens/auth`, `screens/client`, etc.) — do not restructure.
- Do not add mock/fake data or bypass auth for development; use real Supabase test accounts.
