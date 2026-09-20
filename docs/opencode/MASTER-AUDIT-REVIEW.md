# MedLink Yemen — التقرير الموحد للتدقيق الأول (MASTER AUDIT REVIEW)
> تاريخ الإنشاء: 2026-09-18. تدقيق قراءة فقط: لا تعديل كود، لا migrations، لا قاعدة بيانات، لا push.
> المصادر: `docs/opencode/audit/PROJECT_ARCHITECTURE.md`، `PROJECT_APPLICATION_MAP.md`، `PROJECT_DATABASE_MAP.md`، `PROJECT_WEB_DIRECTOR_REVIEW.md` — وهذا التقرير تجميع لها لا بديل عنها.
> قاعدة التصنيف: Implemented = موجود ومقروء في الكود/SQL. Partial = موجود لكن ناقص أو مكسور جزئيًا. Planned = خطة مكتوبة فقط. Missing = لا أثر له. Unknown = لا دليل في المستودع (يحتاج تحققًا حيًا). الخطط السابقة ليست دليل تنفيذ.

## 1. ملخص الحالة الحالية
نظام B2B لتوزيع الأدوية في اليمن فوق مشروع Supabase واحد (`lmkomzqioneuyvatzsov`)، بمكوّنين منتجين حقيقيين: تطبيق Flutter (عميل/مدير فرع/سائق — مكتمل وظيفيًا على مستوى الكود) ولوحة ويب PWA (مدير عام — سليمة البنية لكن فيها 3 عيوب حرجة تكسر وظائف ظاهرة). حولهما قوالب Replit وعقود API هيكلية غير مفعّلة ونسخة توثيقية متداخلة. **لم يُتحقق من أي سلوك حي**: حالة الـmigrations على القاعدة الحية ونشر الـEdge Functions والبناءات — كلها Unknown.

## 2. التطبيقات والمشاريع الموجودة فعليًا
| # | الكيان | النوع | الدليل |
|---|---|---|---|
| 1 | `medlink_app/` | تطبيق Flutter (التطبيق الأساسي) | `medlink_app/pubspec.yaml:1-63`، `medlink_app/lib/main.dart:27-31` |
| 2 | `Medlik-Waap/` | مشروع ويب مستقل (gitlink، مستودع منفصل) | gitlink `35ede5e`، `Medlik-Waap/artifacts/pharma-pwa/src/App.tsx:1-34` |
| 3 | `artifacts/api-server/` | قالب Express (health فقط) — ليس جزءًا من المنتج | `artifacts/api-server/src/routes/health.ts` |
| 4 | `artifacts/mockup-sandbox/` | قالب معاينة مكونات — بلا محتوى | `artifacts/mockup-sandbox/src/App.tsx` (يقرأ `components/mockups/*` غير الموجودة) |
| 5 | `lib/api-spec|api-zod|api-client-react|db/` | عقود بداية غير مفعّلة | `lib/db/src/schema/index.ts` = `export {}`، `openapi.yaml` فيه `/healthz` فقط |
| 6 | `scripts/` | سكربت `hello.ts` فقط | `scripts/src/hello.ts` |
| 7 | `stitch_medlink_yemen/` | نسخة توثيقية متداخلة (لا كود تطبيقي) | `PROJECT_APPLICATION_MAP.md §6` |

## 3. حالة كل جزء من النظام
| الجزء | الحالة | الدليل |
|---|---|---|
| Flutter عميل (كتالوج/سلة/بونص/طلبات/عناوين/عروض) | Implemented | `lib/screens/client/*` (17 شاشة)، `lib/services/order_service.dart:141-206` |
| Flutter مدير فرع (طلبات/مخزون/فواتير/سائقون/إعدادات) | Implemented | `lib/screens/branch_manager/*` (15)، `branch_service.dart` + RPCs §6 |
| Flutter سائق (طلبات/أرباح/تقييم/محادثة/موقع) | Implemented (الخريطة المضمنة Partial — مؤجلة لمفتاح Maps) | `lib/screens/driver/*` (7)، `driver_location_map.dart:1-95`، `المرحلة_السادسة.md` |
| Flutter إشعارات/دعم/تقييم سائق | Implemented | `screens/shared/notifications_screen.dart`، `widgets/rate_driver_sheet.dart` |
| Flutter مصادقة + بوابة موافقة + رفض المدير | Implemented | `app_router.dart:216-277`، `auth_service.dart:39-60` |
| ويب: دخول/حارس دور/تخطيط/تنقل | Implemented | `AuthContext.tsx:39-71`، `App.tsx:31-32`، `DirectorLayout.tsx:1-257` |
| ويب: مدراء فروع/انضمام/كتالوج/مخزون/عروض/بونص/ذمم/مندوبون/تحليلات/إشعارات/مالية | Implemented بنيويًا (باستثناء §10) | `PROJECT_WEB_DIRECTOR_REVIEW.md §2` |
| ويب: لوحة القيادة التشغيلية/المالية | Partial (مكسورة البيانات — §10) | `dashboardApi.ts:71,107,112,288` |
| ويب: مراقبة الطلبات (تنبيه فرع/توجيه/بنود) | Partial (ميزات ميتة — §10) | `OrdersMonitoringPage.tsx:102,228,211` |
| عقود `lib/*` + `api-server` + `mockup-sandbox` | Partial (هياكل بلا تكامل) | `PROJECT_APPLICATION_MAP.md §4` |
| Windows/macOS/Linux | Partial (قالب Flutter فقط، بلا كود خاص) — حالة البناء Unknown | `medlink_app/windows/`، `generated_plugins.cmake` (3 إضافات فقط) |
| المحادثة الحية + الموقع المباشر (مرحلة 9) | Planned (Flutter: بنية chat/location موجودة؛ الويب: لا شيء) | `خطة_المرحلة_التاسعة.md`، `supabase/migrations/0007` |
| المحاسب (`accountant` في RLS المالية) | Missing (لا دور في Flutter، والويب يرفض غير المدير) | `0007_financial_setup_rls.sql:68` مقابل `AuthContext.tsx:8` |

## 4. قاعدة البيانات والجداول والعلاقات والسياسات
- قاعدة واحدة مشتركة؛ ثلاثة مسارات migrations (الجذر 0001→0017 authoritative، الويب 0001→0015 + ملف 0016 غير متتبع، نسخة Flutter المحلية 0012 متعارضة الرقم) — التفاصيل في `PROJECT_DATABASE_MAP.md §1-3`.
- النواة: `branches/users/products/inventory/promotional_offers/client_addresses/orders/order_items/bonus_rules/driver_commissions/ratings/notifications/chat/driver_locations/special_requests` مع triggers (`handle_new_user`، `trg_orders_set_delivered_at`، رصيد الفواتير) وRPCs ذرية (`branch_allocate_order`، `create_order_with_items`، `driver_advance_order_status`...).
- الطبقة المالية (ويب): 26 جدول `financial_*` + 3 views + ترحيل تلقائي + عدم قابلية تعديل المرحّل — `PROJECT_DATABASE_MAP.md §3`.
- RLS: محكمة التصميم (تقييد تحديث المستخدم `0005`، خصوصية الموقع `0008`) لكن فيها تضاربان: نطاق `invoices` بين المستودعين، و3 ملفات تتنافس على سياسة `notifications_select_relevant` — `PROJECT_DATABASE_MAP.md §5`.

## 5. Authentication وAuthorization
- Supabase Auth (بريد/كلمة + Google). صف `public.users` يُنشأ حصرًا عبر trigger `handle_new_user` (`supabase/migrations/0001:26-50`)؛ التسجيل الذاتي يفرض `role='client'` (`auth_service.dart:39-60`)؛ `company_director` يُرفض ويُسجَّل خروجه في Flutter (`app_router.dart:234-237`) ويُقبل وحده في الويب مع اشتراط `active` (`AuthContext.tsx:54-64`).
- الحالات: `pending_approval/active/rejected/suspended` + `requires_password_change` للسائقين/المدراء المنشئين عبر Edge Functions.
- ثغرتان مُغلقتان موثقتين: ترويج الدور الذاتي (`0005`) وتسريب موقع السائقين (`0008` — تحقق ساكن 6/6، والسلوك الحي Unknown).
- فجوة: لا سياسة UPDATE للمدير على `invoices` (الدالة الميتة `setInvoicePaid` ستُرفض لو استُعملت)؛ ودور `accountant` بلا مسار دخول.

## 6. APIs وEdge Functions
- Flutter ← Supabase مباشرة (PostgREST/RLS) + دالة واحدة `manage-driver-account` (إنشاء/إيقاف/تصفير سائقين بتحقق مدير نشط لفرعه — `supabase/functions/manage-driver-account/index.ts:51-62`).
- ويب ← Supabase مباشرة للقراءة + 3 دوال كتابة: `manage-branch-manager-account`، `manage-client-account` (موافقات)، `fetch-exchange-rates` (تحتاج `EXCHANGE_RATE_API_KEY` — التكوين الحي Unknown).
- RPCs الخادمية مطابقة للمستهلكين سطرًا بسطر (جدول المطابقة في `PROJECT_DATABASE_MAP.md §4`)؛ التطبيقان لا يتشاركان RPCs.
- حالة النشر (CLI/Dashboard) Unknown — لا دليل في المستودع؛ خطة `.zcode` كانت تطلب نشرًا يدويًا.

## 7. Design System والواجهات
- Flutter: ثلاثة أنظمة متوازية — داكن كحلي (`utils/theme.dart:AppColors`)، زجاجي فاتح للمدير/السائق (`BranchColors` + `branch_manager_design.dart` بلا `Color(0x…)` خام)، سريري فاتح للعميل (`client_design.dart`)؛ عربي RTL افتراضي + إنجليزي، خط Google Fonts.
- ويب: Teal/Cairo، RTL، داكن/فاتح، shadcn/ui + Tailwind v4 — متسق داخليًا لكنه هوية رابعة لا تشترك رموزها مع Flutter (لا حزمة رموز مشتركة — Missing).
- مراجع بصرية: `screenshots/` (3 لقطات) + `attached_assets/` (نماذج HTML ولقطات أندرويد/واتساب).

## 8. ما تم تنفيذه فعليًا (خلاصة الإثباتات)
Flutter: المراحل 1–8 بشاشاتها وخدماتها ونماذجها (يثبتها الكود لا تقارير `المرحلة_*.md` وحدها)؛ الويب: 24 صفحة مدير + تخطيط + 12 وحدة lib + 3 دوال + طبقة مالية كاملة SQL وواجهاتها؛ RLS والدوال الذرية وال triggers. التحقق المنفذ هنا: `flutter analyze` نظيف، `flutter test` ناجح (placeholder)، فحص ساكن لسياسة الموقع 6/6.

## 9. ما هو ناقص (Missing/Planned)
- Missing: أيقونات PWA؛ مسار دخول `accountant`؛ سياسة تحديث فواتير للمدير؛ تنفيذ `director_notifications` أو حذفه؛ توحيد رموز التصميم؛ تكامل `lib/*`؛ محتوى `mockup-sandbox`؛ اختبارات حقيقية (Flutter placeholder، الويب صفر).
- Planned: المرحلة 9 (دردشة حية + موقع مباشر)؛ دمج الفرع المالي للإنتاج (ممنوع قبل قائمة `حالة-التسليم.md:27-35`).

## 10. الأخطاء والتعارضات المكتشفة
| # | الخطورة | الوصف | المواقع |
|---|---|---|---|
| 1 | حرجة | لوحة القيادة تستعلم حالات طلبات مستحيلة (`Submitted/Invoiced/Delivered` بكبيتل) فتقرأ صفرًا | `dashboardApi.ts:71,107,112` مقابل `0002:132-133` |
| 2 | حرجة | عمود `available_quantity` غير موجود (الصحيح `quantity`) فيُعرض "المخزون مستقر" بصمت | `dashboardApi.ts:288,319` |
| 3 | حرجة | `director_notifications` غير موجود + أعمدة طلبات وهمية + بوابة توجيه بحالات قديمة + زر اتصال وهمي | `OrdersMonitoringPage.tsx:102,9-36,228,211` |
| 4 | متوسطة | أرقام عرض ثابتة (`12.5`، `ORD-000i`، `530.5`...) تُعرض كبيانات حية | `dashboardApi.ts:145,257-264,325-327,338` |
| 5 | متوسطة | `setInvoicePaid` ميتة وبلا غطاء RLS | `receivablesApi.ts:108-114` |
| 6 | متوسطة | تضارب سياسة `notifications_select_relevant` بين 3 ملفات + تضارب نطاق `invoices` بين المستودعين + تكرار رقم migration 0012 | `PROJECT_DATABASE_MAP.md §1,5` |
| 7 | متوسطة | جدول مراحل `replit.md:39-49` (6–9 "التالية") يكذّبه الكود وتقارير المراحل 6–8 (منجزة) — وثيقة متقادمة | `replit.md` مقابل `lib/screens/driver/*` |
| 8 | صغيرة | `$` بدل `﷼`؛ بحث/جرس زخرفيان؛ كلمات مرور ظاهرة؛ أنواع Firestore ميتة مصدر الحالات القديمة؛ `replit.md` الويب يذكر Firestore و`/branch` | `PROJECT_WEB_DIRECTOR_REVIEW.md §4` |

## 11. المخاطر التقنية والأمنية
- **حرجة**: قرارات تشغيلية على لوحة قيادة صفرية (خطر مالي/تشغيلي مباشر).
- **عالية**: `scripts/post-merge.sh:4` ينفذ `pnpm --filter db push` تلقائيًا بعد الدمج — دفع مخطط Drizzle فارغ/متخلف قد يصطدم بقاعدة Supabase المشتركة.
- **عالية**: gitlink الويب يتحرك بين commits (`6192dd8`→`35ede5e`) مع حالات dirty وملف migration غير متتبع (`0016_bonus_inventory_allocation_safety.sql`) — خطر انقسام القاعدة الحية عن المراجَع.
- **متوسطة**: مفاتيح publishable مضمنة (مقصود، معتمد على RLS — أي ثغرة RLS تصبح حرجة)؛ `accountant` بلا مسار يوحي بسياسات ميتة أو توسع قادم غير مخطط.
- **متوسطة**: نموذجا مخزون متوازيان (`inventory` + `warehouse_inventory`) يتزامنان عبر RPC واحد — أي كتابة خارج `branch_add_stock_batch` تكسر الاتساق.

## 12. الديون التقنية
1. ازدواج المستودعات المتداخلة (`stitch_medlink_yemen/` توثيقي، وقوالب Replit مكررة داخل `Medlik-Waap/`) — حسم بالحذف أو الأرشفة.
2. `lib/*` و`api-server` و`mockup-sandbox`: إما تفعيل أو حذف (كود ميت يضلل الفحص).
3. أنواع `models.ts` القديمة و`StatusBadge` القديم — توحيد على قيم القيد الفعلي.
4. الأرقام الثابتة في `dashboardApi` — حساب حقيقي أو وسم "تقديري".
5. `untranslated.txt` و`Medlik-Waap/replit.md` و`replit.md` (جدول المراحل) — مزامنة وثائقية.
6. اختبارات: placeholder واحد فقط في Flutter وصفر في الويب.

## 13. الاعتماديات والمكونات القديمة/غير المتوافقة
- Flutter: `supabase_flutter ^2.8.0`، `go_router ^14.6.2`، `google_maps_flutter ^2.10.0` (بلا مفتاح مُعد — Partial)، `freezed ^2.5.7`/`json_serializable` (مولّدات ملتزمة — سليم).
- ويب: React 19 + `react-router-dom v7` + Tailwind v4 (حديث ومتسق)؛ `xlsx ^0.18.5` قديمة (تدقيق أمني مستحسن)؛ تعليق catalog "expo requires react 19.1.0" بلا expo في المساحة (متقادم).
- بيئة هذا الفحص: Node v10 (لا يشغّل TypeScript المثبت — `typecheck` الويب لم يُنفذ هنا)؛ `pnpm` و`supabase` CLI غير متوفرين في PATH.

## 14. الأجزاء غير المؤكدة (Unknown — تحتاج تحققًا حيًا)
1. أي migrations طُبقت على القاعدة الحية (خصوصًا `0015`/`0016`/`0017` وملفات الويب المالية).
2. نشر وتكوين Edge Functions الأربع ومفاتيحها (`EXCHANGE_RATE_API_KEY`).
3. سلوك RLS الفعلي بحسابات الأدوار الأربعة (الفحص الساكن لا يغني).
4. أي بناء Release (Android/iOS/Web/Windows) ونتائجه.
5. وجود CI runs أو اختبارات تكامل خارج المستودع.
6. بيانات الإنتاج (فروع/مستخدمون/طلبات) — لم يُنظر إليها إطلاقًا.
7. مفتاح Google Maps وتفعيل الخريطة المضمنة للسائق.

## 15. خطة مقترحة لترتيب العمل مستقبلًا (دون تنفيذ)
1. **تثبيت الحقيقة الحية**: جرد `supabase migration list` + `functions list` من CLI مخوّل، وتوثيق الفجوة عن المستودع — قبل أي إصلاح.
2. **إصلاحات الويب الحرجة** (بعد التثبيت): حالات الطلبات (§10-1)، عمود المخزون (§10-2)، حسم `director_notifications` (§10-3) — كل إصلاح يُطابَق مع قيد القاعدة الحية.
3. **إزالة التضليل العددي**: الأرقام الثابتة في `dashboardApi` (§10-4).
4. **توحيد الهجرات**: ترقيم واحد authoritative، وحسم ملف 0012 المحلي و0016 الويب غير المتتبع، وتجميد قاعدة "Dashboard SQL Editor" بإجراء مراجعة.
5. **الأمان**: مراجعة RLS بحسابات أدوار حقيقية في بيئة اختبار؛ حسم `accountant`؛ إيقاف `post-merge push` التلقائي أو تقييده.
6. **الديون**: حذف/أرشفة المكرر (النسخة المتداخلة، `lib/*` أو تفعيلها، أنواع Firestore) وتحديث الوثائق المتقادمة.
7. **التحقق**: اختبارات حقيقية (وحدات للمنطق المالي/البونص + تكامل RLS) وCI قبل أي إعلان إنتاج — والتزام قرار `حالة-التسليم.md` بعدم دمج المالي كجاهز.
8. **Windows**: فقط بعد استقرار العقود — إعادة استخدام نفس الطبقات عبر `supabase_flutter` مع عزل平台ي ضيق، ولا نظام منعزل (حسب `AGENTS.md:4`).
