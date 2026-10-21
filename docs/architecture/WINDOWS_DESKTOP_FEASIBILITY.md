# Windows Desktop Feasibility — MedLink Flutter Application

- **Status:** Feasibility & architecture assessment only. No implementation performed.
- **Date:** 2026-10-16
- **Subject:** Can `medlink_app/` (canonical Flutter application of MedLink Yemen) be built and delivered as a native Windows desktop application by reusing the existing implementation?
- **Canonical source:** repository root `medlink_app/` (git remote `aasd428845-crypto/stitch_medlink_yemen`, branch `main`, HEAD `3e0acc0`).
- **Pre-existing project intent (aligned with):** `docs/opencode/PROJECT-COMPLETION-STATUS.md` ("Desktop/Windows app — Future, links to existing `medlink_app` contracts"; "Windows: only after contracts stabilize — reuse the same layers via `supabase_flutter` with narrow platform isolation, no isolated system — per `AGENTS.md:4`") and `docs/opencode/MASTER-AUDIT-REVIEW.md` ("Windows/macOS/Linux — Partial (Flutter template only, no specific code) — build status Unknown — `medlink_app/windows/`, `generated_plugins.cmake` (3 plugins only)").
- **Important:** No Windows build has ever been produced or tested. Everything build/runtime related below is marked **confirmed-by-repository-evidence** vs **NEEDS-BUILD-VERIFICATION**.

---

## 1. Executive Summary

**Verdict: Feasible without a rewrite — proceed to a bounded proof-of-feasibility build task on a Windows machine.**

The existing Flutter application is already fully multi-platform-scaffolded. `medlink_app/windows/` exists, is complete (18 git-tracked files: CMake project, Win32 runner, resources), and uses the standard Flutter runner with a default 1280×720 window. The resolved plugin set already includes Windows implementations for everything the app actually uses at platform level.

**Reusable as-is (no changes expected):**
- All business logic: 20 service classes, 42 models, controllers (Provider), `go_router` routing with role-based redirects.
- Supabase integration: auth (email/password), database, realtime (chat, driver location, in-app notifications), session persistence.
- Roles & permissions: client / branch_manager / driver / company_director handling is pure Dart + RLS — platform-independent.
- Design system, Arabic RTL localization, theme (`google_fonts`).
- The customer and branch-manager screens themselves: 58 screen files + 19 widgets, all plain Flutter/Material — no orientation locks, no platform channels, no `Platform.is*` branches anywhere in the code.

**The only functional gaps (2 plugins used by the app have no Windows implementation):**
1. `google_maps_flutter` — used in 2 surfaces: address picker (`addresses_screen.dart`) and driver-location map (`driver_location_map.dart`, rendered inside client order details).
2. `google_sign_in` — used for the "Sign in with Google" button (`auth_service.dart`); email/password auth is unaffected.

Both can be **feature-gated on desktop for the first build** (hide Google button; replace map with coordinates + "open in map" browser link) without touching business rules — full replacements are follow-up decisions.

**Everything else resolves on Windows** (verified against pub.dev platform metadata for all 169 resolved packages, plus `.flutter-plugins-dependencies` and the checked-in Windows plugin registrant): `supabase_flutter`, `go_router`, `provider`, `file_picker`, `url_launcher`, `shared_preferences`, `path_provider`, `app_links`, `geolocator_windows`, `qr_flutter`, `cached_network_image` (with a documented JSON fallback for cache metadata instead of sqflite), `flutter_svg`, `csv`, `intl`.

**No peripheral work needed for parity:** the app has no printing/PDF, no barcode/camera scanning, no file uploads beyond a CSV import (already desktop-safe), no OS-level notifications (in-app only), and no offline queue today.

**Key caveat:** the Windows runner has never been compiled with the current Flutter version. The first real proof is `flutter run -d windows` on a Windows machine (Stage B of Section 9). Until then, "builds on Windows" must not be claimed.

---

## 2. Current Flutter Project Structure Relevant to Windows

### 2.1 Application
- `medlink_app/` — 146 Dart files under `lib/`; 58 screen files; 19 widgets; 42 models; 20 services; single router file.
- Entry: `lib/main.dart` (pure Dart bootstrap: `initSupabase()` → `MedLinkApp` with Provider DI + `MaterialApp.router`, Arabic-first locale, RTL `Directionality` wrapper).
- Platform folders present: `android/`, `ios/`, `linux/`, `macos/`, `web/`, **`windows/`** — all listed in `medlink_app/.metadata` (7 platform migration entries). The revision string is a Nix-packaged Flutter placeholder (`nixpkgs0000...`), i.e. the scaffold was generated in the Replit/Nix environment — no FVM pin exists (`.fvmrc` absent), no CI workflows exist.
- `pubspec.yaml`: `environment: sdk: ^3.8.0`; version `1.0.0+1`; direct dependencies include `supabase_flutter ^2.8.0`, `go_router ^14.6.2`, `google_maps_flutter ^2.10.0`, `google_sign_in ^6.2.2`, `geolocator ^13.0.0`, `file_picker ^8.0.0+1`, `url_launcher ^6.3.1`, `shared_preferences ^2.3.4`, `google_fonts ^6.2.1`, `cached_network_image ^3.4.1`, `flutter_svg`, `qr_flutter`, `provider`, `intl`, `csv`, `lucide_icons_flutter`.
- Local toolchain (host, for reference only): Flutter **3.47.4 stable** (Dart 3.13.3) via snap on Linux — a Linux host **cannot** build for Windows (no MSVC toolchain; Flutter has no cross-compilation). `flutter config --list` shows `enable-windows-desktop: (Not set)` locally; on stable Flutter desktop is enabled by default (verify on the Windows machine).

### 2.2 Windows platform folder (exists, complete, tracked)
`medlink_app/windows/` — 18 files, all git-tracked, none modified in the working tree:

| Item | Content (confirmed) |
|---|---|
| `CMakeLists.txt` | `project(medlink_app LANGUAGES CXX)`, `BINARY_NAME "medlink_app"` |
| `runner/main.cpp` | Win32 entry; default window `Size(1280, 720)`; window title `medlink_app` |
| `runner/*` | `flutter_window`, `win32_window`, `utils`, `resource.h`, `Runner.rc`, `runner.exe.manifest`, `resources/app_icon.ico` (default Flutter icon) |
| `flutter/generated_plugins.cmake` | Native Windows plugins at last generation: **`app_links`, `geolocator_windows`, `url_launcher_windows`** |
| `flutter/generated_plugin_registrant.cc` | Registers exactly those three (`AppLinksPluginCApi`, `GeolocatorWindows`, `UrlLauncherWindows`) |

Additional resolved Windows plugin entries in `medlink_app/.flutter-plugins-dependencies` (includes Dart-implemented desktop plugins that need no C++ registration): **`app_links`, `file_picker`, `geolocator_windows`, `path_provider_windows`, `shared_preferences_windows`, `url_launcher_windows`**.

### 2.3 Build state
- No `build/windows/` directory exists; `medlink_app/build/` currently contains Android-era artifacts only. **No Windows binary has ever been produced** (consistent with the audit doc's "build status Unknown").
- The `windows/` scaffold predates the current Flutter version (generated under the Nix environment); a regeneration pass with a pinned Flutter version on the build machine is expected (see Section 7/9).

### 2.4 Repository hygiene observation (recorded, not acted upon)
A nested duplicate checkout exists at `stitch_medlink_yemen/stitch_medlink_yemen/` — a **separate git repository** (own `.git`, HEAD `da10d81`, 2026-09-17) containing an older snapshot of the same project (including its own `medlink_app/` with an identical `pubspec.yaml` and a `windows/` folder). The canonical app for any Windows work is the **repository-root `medlink_app/`**. The nested copy must not be built from or edited.

### 2.5 Existing behavioral baselines (for parity testing)
`medlink_app/docs/مراجعة-شاملة-مدير-الفرع.md` and `medlink_app/docs/مراجعة-شاملة-واجهة-العميل.md` — detailed review documents of the branch-manager and client UIs. Use these as the behavior checklist so desktop adaptation does not alter flows.

---

## 3. Reusability Assessment — Customer & Branch Manager Experiences

### 3.1 Route inventory (from `lib/routing/app_router.dart`, 302 lines)

| Route | Screen file(s) | Portable? |
|---|---|---|
| `/splash`, `/login`, `/register`, `/terms`, `/pending-approval`, `/rejected`, `/suspended`, `/change-password`, `/director-blocked` | `screens/auth/*` (6 files) | Yes (Google button is the only platform-specific element — see 4/5) |
| `/client` (+ home/catalog/orders/account tabs) | `client_home_shell.dart` + `home_tab`, `catalog_tab`, `orders_tab`, `account_tab` | Yes |
| `/client/product/:id`, `cart`, `checkout`, `order-success/:id`, `order/:id`, `offer/:id`, `digital-card`, `addresses`, `business-profile`, `legal`, `special-request`, `bonus-wallet/-history/-redeem/-withdraw/-requests` | 18 further client files (24 files total) | Mostly yes — **`addresses_screen.dart` uses GoogleMap**; **`order_detail_screen.dart` embeds `DriverLocationMap`** (line 334) |
| `/branch` (+ dashboard/orders/inventory/invoices/drivers/chat tabs) + `order/:id` | `branch_manager_home_shell.dart` + 15 further files (16 total) | Yes |
| `/driver`, `/driver/order/:id` | `screens/driver/*` (7 files) | Mostly yes — geolocator + `tel:` call buttons are the platform-sensitive parts |
| `/notifications`, `/help`, `/chat/:roomId` | `screens/shared/*` | Yes — `help_support_screen` launches `tel:` / `wa.me` / `mailto:` URIs |

Role-based redirect logic (`app_router.dart` lines 241–300): loading → splash; signed-out → login; company_director → blocked screen (sign-out); account status pending/rejected/suspended gates; forced password change; role home routing (`/client`, `/branch`, `/driver`). All pure Dart — identical behavior on Windows.

### 3.2 Shell behaviors (evidence)
- Client shell (163 lines): AppBar with brand header + `IndexedStack` of 4 tabs + custom floating bottom bar with cart FAB and notification badge (line 84). All custom widgets in `client_design.dart` — plain Flutter.
- Branch shell (158 lines): 6 tabs (dashboard, orders, inventory, invoices, drivers, chat) behind `BranchFloatingBottomBar` (line 145), custom glass background, settings via `showModalBottomSheet` (line 129). All plain Flutter.

### 3.3 What actually needs desktop attention (and what must not change)
1. **Maps (2 surfaces)** — plugin unsupported; desktop fallback required (Section 6.5).
2. **Google Sign-In button** — plugin unsupported; gate or replace (Section 5.3).
3. **`tel:` links** (driver call buttons, help screen) — unsupported URI scheme on Windows; degrade gracefully.
4. **Layout polish for wide windows** — content currently mobile-first: `RefreshIndicator` in 15 files, `showModalBottomSheet` in 12 files, no `LayoutBuilder`/`NavigationRail` anywhere (0 files), `MediaQuery` used in 10 files (mostly design helpers). Suggested minimal adaptation: constrain max content width / center panels on wide windows; keep bottom sheets (they work with mouse) — **not a redesign**.
5. **Pull-to-refresh** is touch-centric; keep as-is for parity and optionally add explicit refresh affordances later.
6. **Explicitly out of scope:** no changes to business rules, roles, permissions, Supabase schema/RLS/RPCs, and no screen rewrites. Desktop-specific code, when needed, must be narrowly isolated (per the Windows skill guidance).

### 3.4 Reuse classification table

Legend: **AS_IS** = reusable as-is · **ADAPT** = reusable with desktop adaptation · **WORK** = requires Windows compatibility work · **BLOCKED** = blocked by external dependency (mitigation required) · **VERIFY** = needs build/runtime verification.

| Module / file(s) | Classification | Evidence |
|---|---|---|
| `lib/main.dart` | AS_IS | Pure Dart bootstrap; no platform APIs |
| `lib/routing/app_router.dart` | AS_IS | go_router only; pure redirect logic |
| `lib/services/*.dart` (20 files) | AS_IS | Supabase SDK only; all packages Windows-supported |
| `lib/models/*` (42) | AS_IS | Pure Dart + generated code |
| `lib/utils/theme.dart` | AS_IS (note) | `google_fonts` fetches Be Vietnam Pro at runtime (needs internet on first run; cacheable) |
| `lib/utils/error_mapper.dart`, `constants.dart` | AS_IS | Pure Dart; only publishable keys embedded |
| `lib/l10n/*` (ar/en) | AS_IS | gen-l10n; Arabic-first RTL |
| `screens/auth/login_screen.dart` (254 lines) | ADAPT (Google button) | `_submitGoogle` lines 59–74, button 208–211 → `auth_service.signInWithGoogle` |
| `lib/services/auth_service.dart` → `signInWithGoogle()` | BLOCKED (plugin) · AS_IS otherwise | `google_sign_in` 6.3.0 platforms: android/ios/macos/web only; email/password & profile logic pure Supabase |
| `screens/auth/register|terms|change_password|account_status|pending_approval` | AS_IS | No platform APIs |
| `screens/client/*` (24 files) except maps | ADAPT | Standard Material; wide-window polish only |
| `screens/client/addresses_screen.dart` | WORK | `GoogleMap` widget + `LatLng` picker (lines 193, 416, 712–730) |
| `widgets/driver_location_map.dart` (+ usage in `client/order_detail_screen.dart:334`) | WORK | `google_maps_flutter` + Supabase Realtime feed |
| `screens/client/digital_card_screen.dart` | AS_IS | `qr_flutter` renders QR locally (no scanner) |
| `screens/branch_manager/*` (16 files incl. 5 bottom sheets) | ADAPT | Plain Material; wide-layout polish; sheets work with mouse |
| `screens/branch_manager/branch_inventory_tab.dart` (947 lines) | ADAPT (low risk) | CSV import via `file_picker` + `dart:io` `File(file.path!)` — desktop-safe (handles both `bytes` and `path`) |
| `screens/driver/*` | ADAPT + notes | `geolocator` (check/requestPermission, getCurrentPosition), `tel:`/maps URLs |
| `screens/shared/*` | ADAPT (help screen URIs) | `tel:` won't resolve on Windows; `wa.me`/`mailto:` open via browser/mail client |
| `widgets/*` (19) | AS_IS/ADAPT | Plain Flutter widgets |
| `windows/` runner (18 files) | VERIFY | Exists & tracked; never compiled since generation; regenerate with pinned Flutter |
| `android/`, `ios/`, `web/`, `linux/`, `macos/` | Out of scope | Untouched |
| No offline/printing/barcode/notification code | n/a | Confirmed absent (see Section 6) |

---

## 4. Dependency & Plugin Compatibility Findings

**Method:** platform metadata from the public pub.dev score API for **all 169 hosted packages** resolved in `.dart_tool/package_config.json` (dump saved to `/tmp/opencode/win-feasibility/pub-platforms.json`), cross-checked with `pubspec.lock`-resolved versions in `~/.pub-cache` (package pubspecs read), `.flutter-plugins-dependencies`, and the checked-in Windows plugin registrant. *(Additional sources beyond the original inspection plan were necessary because platform support cannot be established from the lockfile alone.)*

**Result: every resolved package is Windows-compatible except the platform-restricted subsets of the two plugins used by the app (`google_maps_flutter`, `google_sign_in`) and `sqflite` (mobile-only, transitively present via `flutter_cache_manager` but not used on the Windows code path — see below).**

| Package (resolved) | Used for in app | Windows verdict (evidence) |
|---|---|---|
| `supabase_flutter` 2.15.4 (+ `supabase`, `gotrue`, `postgrest`, `realtime_client`, `storage_client`) | Auth, DB, Realtime, all services | **YES** — platform tags all platforms |
| `go_router` 14.x, `provider`, `intl`, `csv`, `lucide_icons_flutter`, `cupertino_icons` | Routing, DI, i18n, CSV parsing, icons | **YES** — pure Dart/fonts |
| `google_fonts` 6.x | Theme typography | **YES** — runtime font fetch (first-run internet); optional later: bundle fonts |
| `flutter_svg` | SVG rendering | **YES** |
| `cached_network_image` 3.4.1 → `flutter_cache_manager` 3.4.2 | Product/avatar images, disk cache | **YES** — `_config_io.dart` selects `JsonCacheInfoRepository` on non-(Android/iOS/macOS) platforms (no sqflite on Windows); runtime confirm at PoF |
| `sqflite` (transitive, via `flutter_cache_manager` only) | — (not invoked on Windows path) | **Mobile-only** (android/ios/macos) — **not a blocker**; confirmed sole dependent: `flutter_cache_manager` |
| `google_maps_flutter` 2.14.2 | Address picker; driver location map | **NO** — android/ios/web only (impls: `_android`, `_ios`, `_web`) |
| `google_sign_in` 6.3.0 | "Sign in with Google" | **NO** — android/ios/macos/web only |
| `geolocator` 13.0.4 → `geolocator_windows` 0.2.5 | Driver position (checks permission, `getCurrentPosition`) | **YES** — plugin registers `GeolocatorWindows`; permission-API nuances = PoF verification item |
| `file_picker` 8.3.7 | Branch inventory CSV import | **YES** — desktop via Dart FFI (`win32 ^5.9`); no C++ registration needed (consistent with registrant) |
| `url_launcher` 6.3.2 → `url_launcher_windows` 3.1.x | Open support/photos/map links | **YES** — http/https/mailto; **`tel:` scheme unsupported on Windows** (adapt call buttons) |
| `shared_preferences` 2.5.3 → `_windows` 2.4.x | Session persistence (via supabase_flutter) | **YES** |
| `path_provider` 2.1.5 → `_windows` 2.2.x | Cache/temp paths (transitive) | **YES** |
| `app_links` 6.4.1 | Deep links (supabase_flutter dependency; **not referenced anywhere in `lib/`**) | **YES** — README: "desktop included linux, macOS, Windows"; windows `pluginClass: AppLinksPluginCApi`; registered in runner |
| `passkeys_platform_interface` (supabase_flutter dep) | Passkeys (not used by app code) | Interface only; no runtime impact |
| Dev deps (`build_runner`, `freezed`, `json_serializable`, `flutter_lints`) | Codegen/analysis | **YES** — host-side only |

**Confirmed vs unverified:**
- Confirmed by repository/manifest evidence: the Windows plugin set, registrant entries, absence of unsupported native registrations, package platform tags.
- NEEDS-BUILD-VERIFICATION (cannot be established without a Windows build): runner regeneration under current Flutter, MSVC/CMake version acceptance, `geolocator_windows` permission behavior, file dialog behavior, font fetch with/without internet, image cache metadata writes in practice.

---

## 5. Supabase / Authentication / Permissions Assessment

### 5.1 Initialization & configuration (no changes needed for Windows)
- `lib/services/supabase_bootstrap.dart`: `Supabase.initialize(url: AppConstants.supabaseUrl, anonKey: AppConstants.supabaseAnonKey)` — called once from `main()`.
- `lib/utils/constants.dart`: values are **compile-time constants** — the Supabase project URL and a **publishable ("sb_publishable_…") anon key**, plus the Google OAuth client ID. The file documents that these are publishable by design (authorization is enforced by Postgres RLS, never by key secrecy).
- **Secret hygiene check performed:** repository-wide search in `lib/` found **zero** JWT-style literals (`eyJ…`), **zero** `service_role` references, and no passwords/private keys. Only publishable identifiers are embedded. This report deliberately does not reproduce any key values.
- Desktop build implication: same publishable configuration ships with the Windows binary; **no environment secrets are required** for the current feature set. Optional later hardening: `--dart-define` injection for multi-environment builds (not required now).

### 5.2 Auth flows (reusable except Google)
- `AuthService` (single source of truth): `signUpClient` (role forced to `client`), `signInWithPassword`, `signInWithGoogle`, `signOut`, `fetchCurrentProfile` (reads `public.users`; never writes it — the `handle_new_user` trigger owns the row), `acceptTerms` (updates `terms_accepted_at`). All except Google are pure `supabase_flutter` calls → **work identically on Windows**.
- Session persistence: handled by supabase_flutter via `shared_preferences` (Windows implementation present ✔).
- Realtime: `ChatService.subscribeToDriverLocation`, chat, in-app notifications over `realtime_client` websockets → platform-independent ✔.

### 5.3 Google Sign-In on Windows (the one auth gap)
- `signInWithGoogle()` depends on `google_sign_in` — no Windows implementation exists (verified). Without action, pressing the Google button on Windows would fail at runtime.
- Options (for the future implementation task, in order of preference):
  1. **Feature-gate for the first Windows build:** hide/disable the Google button on desktop (small, reversible, keeps email/password fully functional). Recommended for PoF.
  2. **Replace with a browser OAuth flow** via `supabase.auth.signInWithOAuth()` + `app_links` callback. `app_links` supports Windows (custom URL scheme), but this requires: code changes in `auth_service`/`login_screen`, a registered custom scheme in the Windows app, and a **Supabase redirect-URL allowlist update** (dashboard configuration — requires owner approval, out of scope of this investigation).
- No other auth method (email/password, password change, approval states) is affected.

### 5.4 Roles & permissions
- Role resolution is data-driven: `users.role` → `UserRole` enum (`client`, `branch_manager`, `driver`, `company_director` [recognized and rejected by design]) + `account_status` gating + `requiresPasswordChange` flow — all in pure Dart (`constants.dart`, `app_router.dart`).
- RLS and server-side authorization are untouched and unaffected by the client platform. **No Supabase schema, RLS, RPC, trigger, or migration changes are required or proposed.** Migrations in `supabase/migrations/` (including pending 0024–0027) are out of scope and must not be touched.

### 5.5 Configuration changes required for Windows
- **None** for the core (email/password auth, data, realtime). 
- **One optional decision** if Google login must work on desktop: implement Option 2 (Section 5.3), which includes a Supabase-dashboard redirect configuration step requiring explicit owner approval.

---

## 6. Desktop UI and Peripheral Considerations

### 6.1 UI & interaction inventory (repository evidence)
| Pattern | Count | Desktop implication |
|---|---|---|
| `RefreshIndicator` (pull-to-refresh) | 15 files | Works with mouse-drag on desktop, but keep explicit refresh affordances where UX-critical |
| `showModalBottomSheet` | 12 files | Functional with mouse; optional (not required) dialog treatment on wide screens |
| `MediaQuery` | 10 files (mostly design helpers) | Layouts will stretch; recommend max-width constraints on wide windows |
| `LayoutBuilder` / `NavigationRail` / `NavigationDrawer` | 0 files | No adaptive breakpoints exist yet — desktop adaptation is additive |
| Orientation locks / `SystemChrome` / haptics | 0 occurrences | **No phone-only lock exists** — a major portability win |
| `Platform.is*` / `defaultTargetPlatform` / `kIsWeb` | 0 occurrences | No platform branching in business code; any desktop conditionals will be new, isolated additions |
| Custom `MethodChannel`s | 0 | No native bridges to port |
| `dart:io` | 1 file (`branch_inventory_tab.dart`) | File read for CSV import — works on Windows |
| `dart:html` / `package:js` / `package:web` | 0 | No web-only imports |

### 6.2 Window & forms
- Default window 1280×720 (runner `main.cpp`), resizable, standard Win32 chrome; title "medlink_app" and default Flutter icon are template defaults (update during packaging).
- Text fields, dropdowns, date pickers, dialogs: standard Material — fine on Windows; Arabic RTL is first-class (default locale `ar`, `Directionality` forced RTL in `main.dart`).
- No minimum-window-size enforcement exists (optional later: `window_manager` package or runner edit — a polish item, not a blocker).
- Error handling: `utils/error_mapper.dart` maps failures to Arabic messages — platform-independent.

### 6.3 Printing & PDF — not applicable (evidence-based)
No `printing`/`pdf` packages exist in the dependency graph and no print code was found. Branch invoices are in-app UI flows. **There is nothing to port today.** (If printable invoices become a future requirement, the `printing` package supports Windows — future scope.)

### 6.4 Barcode/scanner & camera — not applicable (evidence-based)
No scanner or camera packages exist; `qr_flutter` only *renders* a QR code on the client digital card (`digital_card_screen.dart`). There is no scanning/camera feature to port. (USB HID keyboard-wedge scanners would later work through ordinary text input — a future feature, not a porting concern.)

### 6.5 Maps (the desktop gap) — recommended fallback
Two surfaces: address picker (`addresses_screen.dart`) and driver-location map (`driver_location_map.dart`; shown in client order details when a driver is assigned).
- Recommended PoF behavior: on Windows, replace the `GoogleMap` widget with a text/coordinates panel + "open in external map" button via `url_launcher` (http URL — supported). The Supabase Realtime feed and data layer stay unchanged.
- Alternative (later decision): a Windows-compatible map library (e.g., `flutter_map`/OSM) — a product decision, not required for feasibility.

### 6.6 Files, storage, caching
- **File selection/import:** branch inventory CSV import through `file_picker` (desktop-safe; code reads `file.path`). No image/document uploads exist in the app today.
- **Local storage:** session via `shared_preferences` (Windows impl ✔); image cache via `flutter_cache_manager` with JSON-based metadata repository on Windows (no sqflite dependency at runtime); temp/cache dirs via `path_provider` (Windows impl ✔).

### 6.7 Notifications
- In-app notifications only (`NotificationService` reading Supabase; badge in shells). **No** `flutter_local_notifications`/push plugin exists — nothing to port; parity is preserved with in-app notifications. (OS toasts would be a future enhancement, not a requirement.)

### 6.8 Offline usage, synchronization, retry behavior (current reality)
- **There is no offline queue, local database, or connectivity listener today** (no `connectivity_plus`, no `sqflite`/`hive` usage in app code). 
- Network failures surface through error mapping + manual refresh (`RefreshIndicator`); Supabase SDK handles websocket reconnection for Realtime. On Windows the same behavior applies unchanged (same Dart code path).
- Anything beyond that (true offline mode/sync) is a **product-level enhancement**, unrelated to platform — explicitly out of scope for the Windows port.

---

## 7. Build Environment and Packaging Requirements

### 7.1 Required Windows build environment (confirmed requirements — to be validated by an actual build)
- Windows 10 (1809+) or Windows 11, x64.
- Flutter SDK — **pin one version** for the build (recommend the 3.47.x stable line for parity with the current dev snapshot; project constraint `sdk: ^3.8.0` satisfied by Dart 3.13.3).
- **Visual Studio 2022** with the **"Desktop development with C++"** workload (includes MSVC v143 C++ toolset, Windows 10/11 SDK, CMake, Ninja). (`Visual Studio Build Tools` variant also works if driven via flutter's `--no-pub`/msbuild discovery — standard Flutter requirement.)
- Git (to clone/pull the repo).
- **No cross-compilation:** the Linux host used for this assessment cannot produce a Windows build; the build must run on Windows.

### 7.2 Build steps (for the future build task)
1. `flutter doctor` → confirm "Windows toolchain" ✔ (also confirms Visual Studio and Windows SDK detection).
2. `flutter config --enable-windows-desktop` (usually already default on stable).
3. In `medlink_app/`: `flutter pub get`.
4. Regeneration pass (expected, because the scaffold predates the current Flutter): `flutter create --platforms=windows .` → review the diff on `windows/**` (keep `BINARY_NAME`/icon/title customizations if any) — **do not** regenerate other platforms.
5. Debug proof: `flutter run -d windows`.
6. Release artifact: `flutter build windows --release` → output `build\windows\x64\runner\Release\` (containing `medlink_app.exe`, `flutter_windows.dll`, plugin DLLs, and the `data\` folder).
- The Windows runner regenerates the plugin registrant during build; the checked-in registrant will be updated automatically to whatever the current dependency set resolves (expected: the same three native plugins).

### 7.3 Runtime dependencies
- The release bundle is self-contained (Flutter engine + Dart AOT snapshot + plugin DLLs). Flutter ships the needed MSVC runtime DLLs inside the bundle; MSVC redistributable may still be prudent to verify on a clean machine (PoF item).
- **WebView2 runtime is NOT required** — the app has no webview dependency.

### 7.4 Installer / distribution options (decision, not a blocker)
| Option | Notes |
|---|---|
| Portable ZIP of `Release\` folder | Simplest; no signing; manual updates |
| MSIX (`msix` pub package) | Proper install/uninstall; **requires a signing certificate** (publisher identity) |
| Inno Setup / NSIS installer | Familiar wizard installers; code-signing recommended |
| Enterprise internal distribution (winget/manual) | Later option |

- **Code signing** is recommended for SmartScreen trust; obtaining a certificate is an owner/ops decision.
- **Updates & versioning:** app version currently `1.0.0+1`; Windows executable/product version derives from it. Update channel strategy (MSIX App Installer, winget, or custom) is a later decision.
- **Configuration/environments:** the current single-environment publishable config is embedded; no secrets needed. For future multi-environment builds, `--dart-define` injection is the recommended hardening.
- **CI:** none exists today; manual builds first; GitHub Actions `windows-latest` is a viable future automation.

### 7.5 Confirmed vs needs real build test
- *Confirmed:* platform scaffold exists; dependency set resolves for Windows; no incompatible native registration; toolchain requirements are standard Flutter ones.
- *Needs real Windows test (do not assume until done):* first successful compile, runner regeneration output, geolocator permission behavior, file dialogs, image cache writes, font loading, DPI/scaling behavior, installer packaging, clean-VM execution.

---

## 8. Main Risks and Blockers

| # | Risk / Blocker | Severity | Likelihood | Mitigation / Status |
|---|---|---|---|---|
| 1 | `google_maps_flutter` has no Windows implementation (2 surfaces) | Medium (limited to those screens) | Certain | Desktop fallback (coords + external map link) for PoF; optional replacement later |
| 2 | `google_sign_in` has no Windows implementation (1 auth method) | Medium | Certain | Feature-gate the button on desktop for PoF; browser-OAuth alternative later (needs config approval) |
| 3 | Windows runner never compiled with current Flutter → unknown build-time issues | Medium | Medium | Staged PoF build (Section 9); regenerate runner with pinned Flutter |
| 4 | `tel:` URIs unsupported on Windows (call buttons) | Low | Certain | Hide/disable call buttons on desktop; keep other link types |
| 5 | `geolocator_windows` permission-API behavior unverified | Low/Medium (driver screens only) | Medium | Verify at PoF; driver role is secondary to this task's scope |
| 6 | Wide-window layout roughness (mobile-first paddings, floating bars) | Low (cosmetic) | High | Max-width constraints + iterative polish; no redesign |
| 7 | Packaging/signing decisions (certificate, installer, SmartScreen) | Medium (distribution) | Certain | Owner/ops decision before external distribution; PoF unaffected |
| 8 | No Windows CI/farm; builds depend on a Windows machine being available | Low/Medium | Medium | Manual first; optional GitHub Actions later |
| 9 | Flutter version drift (Nix-created project, no FVM pin) | Low | Medium | Pin a Flutter version for the Windows build task |

**No blockers found that require rewriting the app, forking business logic, or changing Supabase.**

---

## 9. Minimal Proof-of-Feasibility Plan (smallest safe sequence)

> **Separation of concerns:** Stage 0 was **analysis — completed as part of this document**. Stages A–F are **build tasks** and must be separately approved; they were NOT started, and no `flutter build/run` for Windows was attempted.

| Stage | Steps | Type |
|---|---|---|
| **0. Analysis (this document)** | Repository inspection; dependency/platform audit (169 packages); auth/roles review; reuse classification; risk assessment | **Analysis — DONE** |
| **A. Environment bring-up** | On a Windows machine: install pinned Flutter + VS 2022 C++ workload; `flutter doctor`; clone canonical repo; `flutter pub get` in `medlink_app` | BUILD TASK |
| **B. First smoke run** | `flutter run -d windows` (debug): splash → login renders; email/password login with a real test account; role routing works (`/client`, `/branch`); Arabic RTL renders | BUILD TASK |
| **C. Customer checklist** | Catalog → product → cart → checkout → order success → order details (with map fallback) → notifications → bonus screens; window resize sanity | BUILD TASK |
| **D. Branch-manager checklist** | Dashboard → orders (actions/detail) → inventory (incl. CSV import) → invoices → drivers → chat → settings sheet | BUILD TASK |
| **E. Platform verification** | Image loading/caching; session persistence across restarts; `url_launcher` (https/wa.me/mailto; tel: degradation); file picker paths; Google button gated; geolocator behavior (driver) | BUILD TASK |
| **F. Release & packaging trial** | `flutter build windows --release`; run on a clean Windows VM; ZIP (and optionally MSIX with a test cert); record size, startup, known issues | BUILD TASK (separately approved) |

Minimum viable proof = A + B (+ C for customer confidence). Success criteria = no code changes required in `lib/` beyond the two gated features + documented results.

---

## 10. Estimated Complexity by Work Area (qualitative — no fabricated timelines)

Assumptions: one experienced Flutter developer; canonical repo; pinned Flutter version; desktop adaptations remain additive (no redesign), per scope rules.

| Work area | Complexity | Notes / assumptions |
|---|---|---|
| Windows scaffold enablement + regeneration | **Low** | Folder exists; regeneration is mechanical; review diff |
| Core reuse (services, models, routing, theme) | **None–Low** | Expected to compile/run unchanged |
| Email/password auth, roles, approvals | **None** | Pure Supabase + Dart logic |
| Google Sign-In adaptation | **Medium** | Gate = Low; full browser-OAuth flow = Medium–High incl. config approval |
| Maps adaptation (2 surfaces) | **Medium** | Fallback = Low–Medium; replacement library = Medium–High (decision-dependent) |
| Desktop layout polish — customer | **Medium** | Max-width constraints, spacing, optional hover states |
| Desktop layout polish — branch manager | **Medium** | Data-dense tabs benefit most from width work |
| CSV import / file dialogs verification | **Low** | Already desktop-capable code path |
| Image caching runtime verification | **Low** | JSON fallback built into dependency |
| `tel:` degradation + link handling | **Low** | Small conditional UI changes |
| Packaging / signing / distribution | **Medium** | Depends on owner decisions (certificate, installer type) |
| QA matrix (Win 10/11, DPI scaling, RTL, resize) | **Medium** | New testing surface |
| CI automation (optional) | **Low–Medium** | Only if/when desired |

---

## 11. Recommendation

**Proceed to a separately approved, bounded proof-of-feasibility build task (Section 9, Stages A–C minimum) on a Windows machine, using the canonical `medlink_app` at the repository root — without forking the codebase and without touching Supabase.**

Rationale (evidence-backed):
1. The platform scaffold and plugin resolution for Windows already exist in the repository — the project was never mobile-only.
2. The entire business/domain layer, auth (except Google), roles, routing, design system, and both target experiences are plain Flutter/Dart and portable.
3. The only functional gaps are two well-understood, containable plugin gaps (maps, Google sign-in) with simple gating fallbacks that preserve behavior.
4. No peripherals (printing, scanning, notifications, offline sync) exist in the current product, so parity does not require new platform capabilities.
5. All remaining uncertainty is build/runtime-level — which is exactly what the staged PoF resolves.

**Explicit non-goals** (unchanged from project rules): no redesign of customer/branch-manager flows, no business-rule or permission changes, no Supabase schema/RLS/migration changes, no isolated second app, no rewrite in another framework.

---

## 12. Acceptance Criteria Checklist (for the future Windows implementation task)

- [ ] A Windows machine builds the **canonical** `medlink_app` with a pinned Flutter version; `flutter doctor` shows the Windows toolchain OK.
- [ ] `flutter run -d windows` launches the app (debug) on Windows 10/11 x64 with no crash.
- [ ] Email/password login works with a real account; signed-out gating and `/splash` redirect work.
- [ ] Role routing verified: `client → /client`, `branch_manager → /branch`; approval-status gates (pending/rejected/suspended) verified.
- [ ] Google sign-in: hidden or disabled on desktop (gated) — OR a working browser-OAuth flow with owner-approved Supabase redirect configuration (state which was implemented).
- [ ] Customer checklist passes: home, catalog, product, cart, checkout, order success, order detail, notifications, bonus wallet/history/redeem, addresses, digital card (QR renders), legal, RTL intact.
- [ ] Branch-manager checklist passes: dashboard, orders (+actions/detail), inventory incl. CSV import, invoices, drivers, chat, settings.
- [ ] Maps surfaces on desktop: no crash; coordinates/fallback + external-link behavior per decision.
- [ ] `tel:` buttons degrade gracefully on Windows (hidden/disabled, no errors).
- [ ] Session persists across app restarts (shared_preferences).
- [ ] Images load and cache; cache metadata works (JSON repository path).
- [ ] Window behavior: resizable; min-size decision recorded; title/icon updated to MedLink branding.
- [ ] `flutter analyze` is clean for the changes made.
- [ ] Release build produced (`flutter build windows --release`); artifact runs on a clean Windows VM; bundle size recorded.
- [ ] No secrets embedded beyond the existing publishable keys (verify); no service-role keys anywhere.
- [ ] No Supabase schema/RLS/migration/RPC changes were made or required.
- [ ] Known-issues list + build instructions documented for the team.
- [ ] Single codebase preserved: no duplicated business logic, no forked screens, desktop conditionals isolated and minimal.

---

## Appendix A — Evidence Inventory

**Repository files inspected** (read or targeted-grepped; no modifications):
- Root: git metadata (`main`, `3e0acc0`, remote `aasd428845-crypto/stitch_medlink_yemen`), `worktree list`, directory listings.
- `medlink_app/`: `.metadata`, `pubspec.yaml` (full), `pubspec.lock` (mtime + resolution context), `.flutter-plugins-dependencies` (parsed), `README.md`, `l10n.yaml`, `docs/مراجعة-شاملة-مدير-الفرع.md` + `docs/مراجعة-شاملة-واجهة-العميل.md` (heads).
- `medlink_app/windows/` (all 18 files listed; read: `CMakeLists.txt` head, `runner/main.cpp` head, `runner/Runner.rc` head, `flutter/generated_plugins.cmake`, `flutter/generated_plugin_registrant.cc`).
- `medlink_app/lib/`: `main.dart`, `routing/app_router.dart`, `services/auth_service.dart`, `services/supabase_bootstrap.dart`, `utils/constants.dart` (structure only, literals redacted), `utils/theme.dart` (grep), `screens/client/client_home_shell.dart`, `screens/branch_manager/branch_manager_home_shell.dart`, `widgets/driver_location_map.dart` (head); targeted greps across all 146 Dart files for: plugin usage sites, `SystemChrome`/orientation/haptics, `Platform.is`/`defaultTargetPlatform`/`kIsWeb`, `dart:io`, `dart:html`/`js`/`web`, `MethodChannel`, `MediaQuery`, `showModalBottomSheet`, `RefreshIndicator`, `LayoutBuilder`, `NavigationRail/Drawer`, `app_links`, CSV/file-picker/url_launcher/geolocator call sites; screen/widget inventories + line counts of key screens.
- Docs: `docs/opencode/PROJECT-COMPLETION-STATUS.md` (Windows lines), `docs/opencode/MASTER-AUDIT-REVIEW.md` (Windows lines).

**External evidence sources** (clearly non-repository; needed because platform support cannot be derived from the lockfile):
- pub.dev score API — platform tags for all **169** resolved hosted packages → `/tmp/opencode/win-feasibility/pub-platforms.json`.
- `~/.pub-cache` resolved package manifests: `supabase_flutter`, `supabase`, `cached_network_image`, `flutter_cache_manager` (+ source: `_config_io.dart`, `config.dart`, `cache_store.dart`), `app_links` (+ README), `geolocator`/`geolocator_windows`, `file_picker`, `google_sign_in`, `google_maps_flutter`, `shared_preferences`, `url_launcher`, `path_provider`.
- Local environment: `flutter --version` (3.47.4 stable / Dart 3.13.3 via snap, Linux host), `flutter config --list`.

**Files created by this task:**
- `docs/architecture/WINDOWS_DESKTOP_FEASIBILITY.md` (this document — the only repository addition).
- Working files (outside repo): `/tmp/opencode/win-feasibility/pubcheck.mjs`, `/tmp/opencode/win-feasibility/pub-platforms.json`.

## Appendix B — Safety & Explicit Non-Actions

- No application code was edited; no files under `medlink_app/lib/`, `windows/`, `android/`, `ios/`, or any platform folder were modified.
- No `pubspec.yaml`/`pubspec.lock` changes; no `flutter pub get`/`flutter build`/`flutter run` was executed against the project (only read-only `flutter --version`/`flutter config --list`).
- No Supabase changes of any kind (no schema/RLS/migrations/RPC/dashboard); production untouched.
- No commits, pushes, or deployments.
- The nested duplicate repository (`stitch_medlink_yemen/stitch_medlink_yemen/`) was observed but not modified or used.
- Only publishable keys exist in `lib/utils/constants.dart`; no secrets were found, and no key values are reproduced in this report.
- Nothing in this document should be read as a claim that a Windows build currently works — that remains to be proven by Stage B of the plan on real Windows hardware.
