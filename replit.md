# MedLink Yemen — Flutter App

## Project Overview

MedLink Yemen is a Flutter mobile application (running as Flutter Web on Replit) for B2B pharmaceutical and medical supply distribution in Yemen.

### User Roles

| Role | Description |
|------|-------------|
| `client` | Pharmacist / buyer — browse catalog, place orders, track deliveries |
| `branch_manager` | Branch manager — manage orders, inventory, invoices, and drivers |
| `driver` | Delivery driver — view assigned orders, earnings, chat |
| `company_director` | Blocked in this app — web platform only |

### Backend

**Supabase** (PostgreSQL + Auth + Edge Functions):
- URL and anon key are embedded in `lib/utils/constants.dart` (safe — RLS enforces auth).
- Authentication: email/password and Google Sign-In.
- New user rows are created by the `handle_new_user` database trigger — never insert into `public.users` from client code.
- Migrations are in `supabase/migrations/` at the repo root (applied via Supabase CLI or dashboard).
- Edge Functions are in `supabase/functions/` at the repo root (deployed via Supabase CLI).

### Running the App

**Workflow**: `Flutter MedLink App`

```
cd medlink_app && flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0
```

The app is not a standard artifact — it shows in the Workflows panel, not the Preview dropdown.

---

## Development Phases

| # | Phase | Status |
|---|-------|--------|
| 1 | Foundation + Auth + Approval gateway | ✅ Done |
| 2 | Product catalog + inventory | ✅ Done |
| 3 | Cart + bonus logic + order placement | ✅ Done |
| 4 | Branch manager panel (orders, inventory, invoices, drivers) | ✅ Done |
| 5 | Driver account management via Edge Function | ✅ Done |
| 6 | Driver interface (orders, maps, earnings) | ⏳ Next |
| 7 | Notifications center + promotional offers | ⏳ |
| 8 | Driver rating + help & support | ⏳ |
| 9 | Live chat + live location | ⏳ |

---

## Phase 5 — Driver Account Management (Supabase Edge Function)

### Edge Function: `manage-driver-account`

Located at `supabase/functions/manage-driver-account/index.ts` (repo root — same level as `supabase/migrations/`).

**Deploy with (run from repo root):**
```bash
supabase link --project-ref lmkomzqioneuyvatzsov
supabase functions deploy manage-driver-account
```

**Actions:**
- `create` — creates a new driver auth account with temp password, sets `account_status=active`, `requires_password_change=true`, `branch_id=manager's branch`
- `update_status` — activates or suspends a driver (`active` | `suspended`)
- `reset_password` — resets the driver's password and flags `requires_password_change=true`

### First-Login Password Change

Drivers created by a branch manager have `requires_password_change = true` in `public.users`. The router redirects them to `/change-password` before they can access any other screen.

### Testing Phase 5

1. Log in as a branch manager.
2. Go to the **Drivers** tab → tap the **+** FAB to create a driver.
3. Share the email + temp password with the driver.
4. Log in as the driver — you will be forced to `/change-password`.
5. After changing the password, you land on the driver home.
6. As the branch manager: tap a driver card to activate/suspend or reset their password.

---

## Architecture Rules (from CLAUDE.md)

- Every Supabase call must log through the `SUPABASE_DEBUG` tag (see `AppConstants.supabaseDebugTag`).
- Success is only reported after a verified real response.
- No fake/demo accounts or hardcoded test data in production code.
- Never insert manually into `public.users` — the `handle_new_user` trigger owns that row.
- `company_director` role is always immediately rejected and signed out.
- Branch manager never needs to sign out to manage driver accounts — Edge Function handles it.

---

## Key Files

```
supabase/                                 ← Supabase project root (repo root)
├── migrations/                           ← SQL schema migrations (0001–0005)
└── functions/
    └── manage-driver-account/            ← Phase 5 Edge Function (index.ts)

medlink_app/                              ← Flutter app
└── lib/
    ├── main.dart                         ← App entry, provider setup
    ├── routing/app_router.dart           ← GoRouter + role-based redirects
    ├── utils/constants.dart              ← Supabase URL, anon key, roles, statuses
    ├── utils/theme.dart                  ← Colors, typography, spacing
    ├── l10n/app_ar.arb                   ← Arabic strings (default)
    ├── l10n/app_en.arb                   ← English strings
    ├── models/                           ← Freezed models (user, order, product, …)
    ├── services/
    │   ├── auth_service.dart             ← Supabase auth wrapper
    │   ├── auth_controller.dart          ← Auth state (ChangeNotifier)
    │   ├── driver_service.dart           ← Edge Function calls + password change
    │   ├── branch_service.dart           ← Branch manager DB operations
    │   └── branch_controller.dart        ← Branch state (ChangeNotifier)
    └── screens/
        ├── auth/                         ← Login, register, pending, change_password
        ├── client/                       ← Home, catalog, cart, checkout, orders
        ├── branch_manager/               ← Dashboard, orders, inventory, invoices, drivers
        └── driver/                       ← Driver shell (Phase 6)
```

---

## User Preferences

- App language: Arabic RTL by default (`const Locale('ar')`).
- All Supabase calls must use the `SUPABASE_DEBUG` log tag.
- No mock data or fake accounts in code — always use real Supabase auth.
- Driver accounts are created by branch managers, not through self-registration.
- The edge function deploy step must be done from the Supabase CLI (not from Replit).
