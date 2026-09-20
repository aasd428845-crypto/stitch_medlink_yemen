# مراجعة واجهة المدير العام (ويب) — Medlik-Waap / pharma-pwa
> تدقيق قراءة فقط — 2026-09-18. لم يُعدَّل أي ملف تطبيقي، لا migrations، لا اتصال بقاعدة البيانات، لا push.
> المنهج: قراءة سطرية كاملة للملفات الحرجة + مسح آلي لبقية الصفحات (الجداول/RPCs/الحالات النصية/حالات التحميل والخطأ).

## 1. النطاق
- الدخول: `Medlik-Waap/artifacts/pharma-pwa/src/App.tsx:1-34` — كل مسارات `/director/*` تحت `ProtectedRoute allowedRoles=['company_director']` (`App.tsx:31`)، والجذر يوجّه المدير للوحة (`App.tsx:32`).
- المصادقة: `src/contexts/AuthContext.tsx:1-143` — رفض فوري + تسجيل خروج لأي دور غير `company_director` (`:54-57`) ولأي حالة غير `active` (`:61-64`). سليم.
- التخطيط: `src/layouts/DirectorLayout.tsx:1-257` — sidebar + تنقل سفلي للجوال + تبديل ليلي/نهاري + خروج. 18 عنصر تنقل (`:38-57`).
- النماذج: `src/types/models.ts:1-114` — أنواع قديمة من حقبة Firestore (انظر §3).

## 2. مطابقة العقود (جدول × كود)

| المنطقة | الملف | الحكم |
|---|---|---|
| حسابات مدراء الفروع (قراءة/إنشاء/تفعيل/تعديل/تصفير) | `lib/branchManagerApi.ts:1-120` + `pages/director/BranchManagersPage.tsx:1-616` | سليم — كل الكتابة عبر Edge Function `manage-branch-manager-account` (`branchManagerApi.ts:47-56`) |
| طلبات الانضمام (قبول/رفض) | `lib/clientApprovalApi.ts:1-72` + `PendingClientsPage.tsx:1-189` | سليم — عبر `manage-client-account` (`:40-56`) |
| العروض الترويجية + إشعار تلقائي | `lib/promotionalOffersApi.ts:1-209` + `OffersPanel.tsx` + `OfferForm.tsx` | سليم — أعمدة notifications المستعملة (`title,body,target_role,target_branch_id,related_offer_id,created_by`) موجودة في `supabase/migrations/0003`؛ الكتابة مشمولة بسياسة `offers_director_manage` (`0002:89-90`) |
| قواعد البونص + إشعار تلقائي | `lib/bonusRulesApi.ts:1-172` + `BonusRulesPanel.tsx` | سليم — مشمولة بـ`bonus_rules_director_manage` (`0003:21-22`) |
| الكتالوج + استيراد Excel + رفع صور | `CatalogPage.tsx:1-586` + `lib/catalogImport.ts:1-185` | سليم بشروط — أعمدة `sku/commercial_name/...` أضافتها `Medlik-Waap/.../0014_product_catalog_sync.sql:11-19`؛ الرفع يستعمل bucket `product-images` (مطابق `supabase/migrations/0015:10-12`) |
| المندوبون + إحصاء التسليم | `lib/driverStatsApi.ts:1-124` + `DriversPage.tsx:1-168` | سليم — يستعمل `status='delivered'` الصحيح (`driverStatsApi.ts:42-46`) |
| تحليلات الأصناف | `lib/itemAnalyticsApi.ts:1-165` + `ItemAnalyticsPage.tsx` | سليم — يوثّق الحالات الصحيحة في ترويسته (`:3-8`) |
| المخزون (جدول محوري + صلاحيات) | `InventoryOverviewPage.tsx:111-159` + `lib/expiryInventoryApi.ts:42-48` | سليم — `quantity/expiry_date/unit_price` مطابقة للمهاجرات |
| المالية (مصروفات/سندات/قيود/رواتب أطباء) | `ExpensesPage` + `ReceiptsPage` + `JournalPage` + `FinancialPage` عبر `supabase.rpc` | سليم — أسماء الوسائط مطابقة للتوقيعات (مثال `create_financial_expense` في `0010_financial_simple_entries.sql:35-41`) |
| إرسال إشعار (دور/مجموعة/فرد + سجل) | `lib/sendNotificationApi.ts:1-73` + `SendNotificationPage.tsx:1-200+` | سليم — يطابق عمود `target_user_ids` من `Medlik-Waap/.../0005:16-18` |
| الذمم + سجل الفواتير (قراءة) | `lib/receivablesApi.ts:1-114` + `ReceivablesPage.tsx:1-281` | سليم قراءةً — `credit_limit/current_balance` من `0004_phase4:56-60` |

## 3. عيوب حرجة (تكسر وظائف ظاهرة)

### 3.1 لوحة القيادة تستعلم حالات طلبات غير موجودة
- `lib/dashboardApi.ts:71` — `ACTIVE_ORDER_STATUSES = ['Submitted','Allocated','PartiallyShipped','OutForDelivery']`.
- `dashboardApi.ts:107,112` — الإيرادات تُحسب بـ`.in('status',['Invoiced','Delivered'])`.
- القيد الفعلي (`supabase/migrations/0002:132-133`) يسمح فقط `pending/assigned/in_progress/delivered/cancelled` — وحسّاس لحالة الأحرف (`Delivered ≠ delivered`).
- الأثر: عدّاد الطلبات النشطة والإيرادات (30/60 يوم و12 شهر) يقرأ صفرًا دائمًا، و`ORDER_STATUS_LABEL` في `DashboardPage.tsx:46-53` لا يطابق أي حالة حقيقية.
- ملاحظة إنصاف: `itemAnalyticsApi.ts:3-8` و`driverStatsApi.ts:40-46` يوثّقان ويستعملان الحالات الصحيحة — الكسر محصور في `dashboardApi` + `DashboardPage`.

### 3.2 عدّاد المخزون الحرج يستعلم عمودًا غير موجود
- `dashboardApi.ts:288` — `.select('available_quantity, branch_id')` على `warehouse_inventory`، والعمود الفعلي `quantity` (`0004_phase4:22-31`).
- الأثر: PostgREST يرجع خطأً يُتجاهل (`{ data: criticalData }` بلا فحص خطأ) فيُحسب `criticalItems = 0` بصمت (`dashboardApi.ts:319`) — بطاقة "المخزون مستقر" مضللة.

### 3.3 صفحة مراقبة الطلبات مبنية على أعمدة وجدول غير موجودة
- `OrdersMonitoringPage.tsx:102-108` — إدخال في جدول `director_notifications`، ولا أثر له في أي migration (بحث شامل فارغ) — زر "تنبيه الفرع" يفشل دائمًا برسالة "تعذر إرسال التنبيه".
- `OrdersMonitoringPage.tsx:9-36` — يقرأ `order_lines/client_name/client_type/client_governorate/scheduled_delivery_date` من صف الطلب، وهي غير موجودة (البنود في `order_items`، ولا اسم عميل مخزّن) — جدول "محتوى الطلب" فارغ دائمًا واسم العميل فارغ.
- `OrdersMonitoringPage.tsx:228` — صندوق إعادة التوجيه مشروط بحالات قديمة (`Submitted/Draft/Allocated`) فلا يظهر للطلبات الحقيقية.
- `OrdersMonitoringPage.tsx:211` — زر "اتصال بالعميل" بـ`href="tel:0000000"` يعرض تنبيهًا وهميًا بدل الاتصال.

## 4. عيوب متوسطة/صغيرة
4.1 أرقام عرض مُختلقة في لوحة القيادة: `deltaPct` ثابتة (`12.5`, `5.0`, `-15.0` في `dashboardApi.ts:325-327`؛ `4.2`, `8.5`, `-2.1` في `:257-260`)، و`orderNumber: ORD-000i` مولّد من الفهرس (`:338`)، واحتياطيات أسعار الصرف (`530.5/528.0/140.2/139.5` في `:263-264`) وهوامش (`28.5` في `:145`) — تُعرض كأنها بيانات حية، مخالف لروح قاعدة "لا نجاح/بيانات وهمية" في `replit.md`.
4.2 `setInvoicePaid` في `lib/receivablesApi.ts:108-114` دالة ميتة (لا يستوردها أي ملف — بحث شامل أكّد) وفوق ذلك لا توجد سياسة UPDATE للمدير على `invoices` (الموجود: إدراج مدير `0004_phase4:84-86` + إدراج/تحديث مدير فرع `0009:78-96`) — لو رُبطت بزر لاحقًا ستُرفض من RLS.
4.3 `deletePromotionalOffer` في `promotionalOffersApi.ts:194-198` يتجاهل خطأ حذف الإشعارات المرتبطة (`:195` بلا فحص) — فشل صامت محتمل قبل حذف العرض.
4.4 كلمات المرور المؤقتة تُكتب كنص ظاهر (`type` افتراضي) في `BranchManagersPage.tsx:422-431` و`:580-589` — مقبول للمشاركة لكنه قرار أمني يستحق التوثيق.
4.5 السعر يُعرض ببادئة `$` في `CatalogPage.tsx:388` و`OrdersMonitoringPage.tsx:166` رغم أن التسمية "العملة المحلية" — يوحّد على `formatYer` المستعمل في `DashboardPage.tsx:329`.
4.6 بحث `⌘ K` في `DirectorLayout.tsx:210-214` وجرس الإشعارات (`:227-230` بنقطة ثابتة) عنصران زخرفيان بلا وظيفة.
4.7 `types/models.ts` يحمل أنواعًا ميتة من حقبة Firestore (`OrderStatus` القديم `:34`، `BranchOffer`، `DirectorNotification`، `Address`) — تُستعمل جزئيًا كعارضات محلية في 3 صفحات فقط؛ خطرها أنها مصدر الحالات القديمة في `OrdersMonitoringPage` و`StatusBadge.tsx:10-19`.
4.8 أصول PWA ناقصة: الـmanifest في `vite.config.ts:27-40` يطلب `/icon-192.png` و`/icon-512.png` و`includeAssets: favicon.ico`، ومجلد `public/` يحوي فقط `favicon.svg` + `robots.txt` — التثبيت كتطبيق سيظهر بلا أيقونة.
4.9 وثيقة `Medlik-Waap/replit.md:49-70` متقادمة: تذكر مجموعات Firestore ومسارات `/branch/*` و`BranchManagerLayout.tsx` غير الموجودة، وتحذّر من `@workspace/api-client-react` غير المستعمل أصلًا — تضلّل أي مطور جديد.

## 5. ما هو سليم ويُحسب للمشروع
- حارس الدور على مستويين (سياق + مسار) مع تسجيل خروج فوري للمخالف — `AuthContext.tsx:39-71` + `App.tsx:31`.
- كل كتابة على `users` (مدراء/عملاء) تمر عبر Edge Functions بتحقق `company_director` نشط — `branchManagerApi.ts:47-56`، `clientApprovalApi.ts:40-48`.
- ترجمة أخطاء عربية وحوارات تأكيد قبل (إنشاء/إيقاف/حذف) — `BranchManagersPage.tsx:351-613`، `PendingClientsPage.tsx:173-186`.
- حالات تحميل/خطأ/فراغ في كل صفحة مرئية (skeleton في `DashboardPage.tsx:98-111`، ورسائل فراغ عربية في كل الجداول).
- الكتالوج: تحقق مزدوج (عميل + ترجمة أخطاء القاعدة للحقل العربي) — `CatalogPage.tsx:55-98,225-261`.
- الاستيراد من Excel: تحقق صارم (أعمدة مطلوبة، SKU مكرر، أرقام عربية) — `catalogImport.ts:56-159`.

## 6. حدود هذه المراجعة (لم يُتحقق حيًا)
- لم يُشغَّل `vite dev` ولا `typecheck` (Node النظام v10 لا يشغّل TypeScript المثبت — عائق بيئي موثق سابقًا).
- لم يُختبر أي استعلام ضد القاعدة الحية؛ أحكام "سليم/مكسور" مبنية على مطابقة النصوص بين الكود وملفات SQL فقط.
- الملفات `main.tsx` و`not-found.tsx` والمكوّنات (`ConfirmDialog/ErrorMessage/LoadingSpinner`) رُوجعت سطحيًا؛ وأجسام صفحات المالية رُوجعت عبر RPCs لا سطرًا بسطر.

## 7. التوصية (مرتبة، دون تنفيذ)
1. توحيد حالات الطلبات في `dashboardApi.ts` + `DashboardPage.tsx` + `OrdersMonitoringPage.tsx` + `StatusBadge.tsx` على قيم القيد الفعلي — حرج.
2. إصلاح عمود المخزون الحرج إلى `quantity` مع فحص الخطأ — حرج.
3. حسم `director_notifications`: إما migration تُنشئه أو حذف زر التنبيه وربط أزرار الطلب بـ`order_items`/بيانات العميل الحقيقية — حرج.
4. إزالة الأرقام الثابتة أو وسمها "تقديري" — متوسط.
5. إضافة أيقونات PWA أو إسقاط المراجع — صغير.
6. تحديث `Medlik-Waap/replit.md` (إسقاط Firestore ومسارات `/branch`) — صغير.
