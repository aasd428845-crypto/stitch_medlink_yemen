# MedLink Yemen — خريطة التطبيقات والحزم (First Run Audit)
> تدقيق قراءة فقط — 2026-09-17.

## 1. مساحة العمل الجذر (`/`)
- `package.json` + `pnpm-workspace.yaml` + `tsconfig.base.json` — مساحة pnpm، حزمها: `artifacts/*`, `lib/*`, `scripts` (`pnpm-workspace.yaml:37-41`).
- `.replit:14-33` — workflow `Flutter MedLink App` يشغّل `flutter run -d web-server --web-port=3000` من `medlink_app`.
- `replit.md` — دليل المشروع الرسمي (أدوار، مراحل، قواعد CLAUDE.md، ملفات مفتاحية).
- `opencode.json` — إعداد OpenCode (MCP: playwright مفعّل؛ context7/figma/github معطلة).
- `.agents/memory/*.md` — 4 مذكرات تقنية ذهبية (انظر PROJECT_RISKS §استنساخ).
- `.zcode/plans/plan-sess_1ce08931-…md` — خطة جلسة سابقة لتشغيل دخول المدير العام على الويب.

## 2. `medlink_app/` — تطبيق Flutter (التطبيق الأساسي)
- `pubspec.yaml:19-63` — اسم medlink_app، إصدار 1.0.0+1، SDK ^3.8.0؛ تبعيات: supabase_flutter، go_router، google_fonts، google_sign_in، google_maps_flutter، qr_flutter، geolocator، freezed، provider، lucide_icons_flutter، file_picker، csv.
- `lib/main.dart:27-31` — تهيئة Supabase ثم MultiProvider بـ16 خدمة/متصل تغيير.
- `lib/routing/app_router.dart:36-277` — GoRouter مع redirects حسب role/account_status/requires_password_change.
- الشاشات: `lib/screens/auth/*` (6)، `lib/screens/client/*` (17)، `lib/screens/branch_manager/*` (15)، `lib/screens/driver/*` (7)، `lib/screens/shared/*` (6).
- `lib/models/*` — 13 نموذج freezed/json_serializable مطابقة لأعمدة snake_case.
- `lib/services/*` — 12 خدمة + متصلاتها (انظر PROJECT_API_MAP).
- `lib/l10n/` — عربي افتراضي + إنجليزي (`app_ar.arb`, `app_en.arb`, `untranslated.txt`).
- منصات: `android/` (build.gradle.kts، minSdk افتراضي)، `ios/` (Info.plist)، `web/` (index.html/manifest)، `windows/` (CMake runner كامل)، `linux/`, `macos/`.
- اختبارات: `test/widget_test.dart` — placeholder فقط (10 أسطر).

## 3. `Medlik-Waap/` — مشروع الويب (مستودع gitlink مستقل)
- gitlink عند `6192dd8`؛ عنده `.git` يتبع `https://github.com/aasd428845-crypto/Medlik-Waap.git`، وفرع `main...origin/main`.
- `artifacts/pharma-pwa/` — PWA React 19 (vite-plugin-pwa، RTL، Cairo، react-router-dom v7):
  - `src/contexts/AuthContext.tsx:6-8` — مخصص حصراً لدور `company_director`؛ أي دور آخر يُسجَّل خروجه فوراً.
  - `src/App.tsx` — مسارات `/director/*` (24 صفحة داخل `src/pages/director/`) محمية بـProtectedRoute.
  - `src/lib/*.ts` — 12 وحدة API تقرأ جداول Supabase مباشرة وتستدعي 3 Edge Functions.
- `supabase/` — 15 migration مالية/تشغيلية + 3 Edge Functions + `config.toml` (نفس project_id `lmkomzqioneuyvatzsov`).
- `docs/` — 9 وثائق مراحل عربية (الانضمام، السائقون، العروض، الذمم، النظام المالي…).
- `artifacts/api-server` + `artifacts/mockup-sandbox` + `lib/*` — نسخ قوالب Replit داخل المشروع الفرعي.

## 4. قوالب Replit في الجذر (`artifacts/`, `lib/`, `scripts/`)
- `artifacts/api-server` — Express + pino + drizzle (`@workspace/db`)، مسار `/api/healthz` فقط (`src/routes/health.ts`).
- `artifacts/mockup-sandbox` — Vite React لمعاينة مكونات (`src/App.tsx` Gallery + `/preview/:name`)، يقرأ `src/components/mockups/*` غير الموجودة.
- `lib/api-spec` — OpenAPI 3.1 فيه `/healthz` فقط (`openapi.yaml`)؛ Orval يولّد `lib/api-zod` و `lib/api-client-react` (مولّد حالياً من العقد الفارغ).
- `lib/db` — Drizzle مع schema فارغ (`src/schema/index.ts` = `export {}`).
- `scripts` — `hello.ts` فقط + `post-merge.sh` (يشغّل `pnpm --filter db push` — انظر PROJECT_RISKS).

## 5. أصول وتوثيق
- `attached_assets/` — 30+ ملف: سياق CLAUDE الأصلي، نماذج HTML لفواتير/شاشات، لقطات أندرويد/واتساب، ملف zip للمشروع.
- `screenshots/` — 3 لقطات تصميم: `medlink-client-redesign.jpg`, `medlink-branch-redesign.jpg`, `medlink-driver-redesign.jpg`.
- الجذر: 12 وثيقة مراحل عربية (تقارير إنجاز + خطط) + `docs/` (5 وثائق تصميم v2 + مراجعة مندوب) + `docs/opencode/*`.

## 6. النسخة المتداخلة `stitch_medlink_yemen/`
- مجلد كامل (له `.git`، وbranch عند `da10d81` — نفس HEAD الخارجي، untracked في الأب) — **نسخة مستندية فقط**: كل ملفاته توثيق/تكوين، لا `lib/` أو `screens/` تطبيقية؛ حجمه صغير (لا `medlink_app/` تطبيقية داخله). هذا **ازدواج توثيقي** يجب حسمه لاحقاً (انظر PROJECT_RISKS).
