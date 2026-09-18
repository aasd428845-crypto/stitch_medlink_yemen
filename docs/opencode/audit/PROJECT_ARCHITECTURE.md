# MedLink Yemen — مخطط المعمارية (First Run Audit)
> أُنشئ في 2026-09-17 بواسطة تدقيق OpenCode V2 الأول (تعليمات: `docs/opencode/FIRST-AUDIT-PROMPT.md`).
> قراءة فقط: لم يُعدَّل أي كود تطبيقي، ولا migrations، ولا قاعدة البيانات.

## 1. الصورة الكبرى

MedLink Yemen هو نظام توزيع صيدلاني B2B متعدد التطبيقات فوق **مشروع Supabase واحد** (`lmkomzqioneuyvatzsov`):

| التطبيق | التقنية | الجمهور | الأدلة |
|---|---|---|---|
| تطبيق Flutter (Android/iOS/ويب/سطح مكتب) | Flutter 3.8+ / Dart SDK ^3.8 | العميل، مدير الفرع، السائق | `medlink_app/pubspec.yaml`, `replit.md` |
| لوحة ويب/PWA للمدير العام | React 19 + Vite + Tailwind | `company_director` فقط | `Medlik-Waap/artifacts/pharma-pwa/`, `Medlik-Waap/replit.md` |
| قوالب عناصر Replit + sandbox للنماذج الأولية | Express/pino + Vite | غير مرتبط بالمنتج | `artifacts/api-server/`, `artifacts/mockup-sandbox/` |
| عقود API مشتركة (هيكل بداية، غير مستخدم) | OpenAPI + Orval + Drizzle | — | `lib/api-spec/openapi.yaml`, `lib/db/src/schema/index.ts` |

- "مشروع الويب" هنا هو **Medlik-Waap** (مستودع gitlink مستقل): `git ls-files -s | grep 160000` → `Medlik-Waap` عند `6192dd8`، عنده `.git` خاصه و`pnpm-workspace.yaml` خاص به.
- دليل العميل الأصلي: `attached_assets/CLAUDE_1785847218095.md` (B2B مغلق، موافقة إلزامية، توصيل مجاني دائماً، 4 أدوار صارمة).

## 2. القواعد المعمارية المُعلنة (المصادر)
- `AGENTS.md` — المصدر هو المستودع، عقود Supabase بنية تحتية مشتركة، Windows يعيد استخدام العقود نفسها.
- `attached_assets/CLAUDE_1785847218095.md` §3 — 10 قواعد صارمة (لا صفوف يدوية في users، تسلسل snake_case حرفي، لا توليد IDs يدوي، منطق واحد لكل عملية، لا نجاح وهمي، تسجيل SUPABASE_DEBUG، تقسيم الخدمات، i18n من أول شاشة).
- `replit.md` (الجذر) §Architecture Rules — نفس القواعد + رفض فوري لدور `company_director` في تطبيق Flutter.
- `.agents/memory/MEMORY.md` — ذاكرة متكررة: Flutter ليس artifact، مفاخر pubspec، أخطاء Edge Functions، ترقيم migrations المشترك.

## 3. التدفق الوظيفي الأساسي
1. العميل يسجّل → صف users عبر trigger `handle_new_user` (`supabase/migrations/0001_initial_schema.sql:26-50`) → `account_status='pending_approval'` افتراضياً (`0003:1-3`).
2. الموافقة من لوحة الويب عبر Edge Function `manage-client-account` (`Medlik-Waap/supabase/functions/manage-client-account/index.ts`، استدعاء: `Medlik-Waap/artifacts/pharma-pwa/src/lib/clientApprovalApi.ts`).
3. العميل يتصفح الكتالوج ويطلب: `medlink_app/lib/services/order_service.dart` (`createOrder`) — يستدعي RPC `create_order_with_items` (0017)، الذي يتحقق خادمياً من القاعدة الفائزة والسعر والإجمالي، ثم يحفظ paid/bonus و`bonus_rule_id`.
4. مدير الفرع يخصّص الطلب ذرياً: RPC `branch_allocate_order` (0016) — يجمع paid + bonus لكل منتج، يخصم الكمية الفيزيائية مرة واحدة، ويفوتر الجزء المدفوع فقط.
5. السائق يتقدم بحالة الطلب: RPC `driver_advance_order_status` (`supabase/migrations/0006`) من `medlink_app/lib/services/driver_orders_service.dart`.
6. عند `delivered` يُملأ `delivered_at` تلقائياً: trigger `trg_orders_set_delivered_at` (`0009:55-58`).
7. المدير العام يراقب كل شيء من `Medlik-Waap/artifacts/pharma-pwa/src/pages/director/*` (KPIs، كتالوج، مخزون، عروض، بونص، ذمم، نظام مالي كامل).

### Bonus rules — contract
- `product_id IS NULL` قاعدة عامة للمنتج، بينما القاعدة ذات المنتج المحدد لها أولوية.
- عند وجود أكثر من قاعدة مطابقة: أعلى bonus مكتسب، ثم أقل buy threshold، ثم أقدم `created_at`، ثم أصغر `id`.
- `is_stackable=false` يمنح bonus مرة واحدة عند بلوغ الشرط؛ `true` يحسب مضاعفات الشرط.
- الصلاحية تشمل `is_active` والتاريخ الشامل والمحافظة المستهدفة. سطور bonus مجانية للمحاسبة لكنها وحدات فيزيائية للمخزون.

## 4. حدود الخدمات
- **Flutter → Supabase مباشرة** (PostgREST/RLS + 1 Edge Function). لا يمر عبر أي خادم Node. (`medlink_app/lib/services/*.dart`)
- **Web → Supabase مباشرة** (قراءة RLS) + 3 Edge Functions للكتابة الحساسة. (`Medlik-Waap/artifacts/pharma-pwa/src/lib/*.ts`, `Medlik-Waap/supabase/functions/`)
- **Express `api-server`** في `artifacts/` يخدم `/api/healthz` فقط (`artifacts/api-server/src/routes/health.ts`) — عناصر قالب Replit وليست جزءاً من نشر MedLink.
- عقود `lib/` (OpenAPI/Orval/Drizzle/Zod) فارغة من نماذج فعلية (`lib/db/src/schema/index.ts` فيه `export {}` فقط) — بنية بداية غير مفعّلة.

## 5. الحالة الإجمالية
- تطبيق Flutter: مكتمل الوظائف للأدوار الثلاثة (مراحل 1–8 منجزة، مرحلة 9 مخططة) — راجع `replit.md:39-49` وتقارير `المرحلة_*.md`.
- لوحة الويب: مكتملة بنيوياً بما فيها النظام المالي، لكن `Medlik-Waap/docs/المرحلة-المالية-حالة-التسليم.md:38-44` يقرر أنها **ليست جاهزة للإنتاج** قبل اختبارات SQL/CI.
