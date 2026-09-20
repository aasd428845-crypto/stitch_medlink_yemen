# MedLink Yemen — تقرير التحقق (LIVE VERIFICATION REPORT)
> الجولة الأولى: 2026-09-18. الجولة الثانية (تحديث): 2026-09-18. الجولة الثالثة: بيئة Node 22.23.2 + pnpm 9.15.9 (مسار المستخدم) — Web typecheck/build أصبحا LIVE VERIFIED. مرحلة VERIFY ONLY: لا تعديل كود، لا migrations، لا RLS، لا deploy، لا push، لا أسرار.
> القواعد: STATIC VERIFIED = الدليل من النصوص فقط. LIVE VERIFIED = سلوك فعلي مُختبر. UNKNOWN = تعذّر الوصول (بالسبب). NOT VERIFIED = لم يُختبر لعائق بيئي. لا شيء مصنف LIVE VERIFIED لمجرد أن الكود "يبدو صحيحًا".

## Executive Summary
- STATIC VERIFIED: العيوب الحرجة الثلاثة ما زالت قائمة حرفيًا (تحقق ثانٍ بنفس الأسطر)؛ تصميم RLS/الدوال/المهاجرات مطابق للموثق سابقًا.
- LIVE VERIFIED: `flutter analyze` (4 infos، صفر errors) و`flutter test` (8/8) — أُعيد تشغيلهما بنفس النتائج.
- LIVE VERIFIED (جديد): ويب `pharma-pwa` — `pnpm run typecheck` exit 0 (صفر أخطاء) و`pnpm run build` exit 0 (2453 وحدة → `dist/public/` مع `sw.js` و`manifest.webmanifest`) على Node 22.23.2 + pnpm 9.15.9. تحذيران غير قاتلين (ليسا أخطاء): sourcemap في `sheet.tsx:2`، وحجم chunk (~1.5MB JS يقترح code-splitting لاحقًا).
- UNKNOWN: المطبق حيًا من migrations، نشر الدوال الأربع، سلوك RLS بالأدوار — لا `supabase`/`psql`/credentials في البيئة (تحقق ثانٍ: ما زالت غائبة).
- NOT VERIFIED سابقًا ثم LIVE VERIFIED: `typecheck`/`build` الويب كانا متعذرين على Node v10؛ نُفذا بنجاح على بيئة Node 22.23.2 + pnpm 9.15.9 (مسار المستخدم، بلا مساس بالنظام) — انظر جدول §Build Verification.

## Supabase Migrations
`supabase migration list` لم تُنفذ (الأداة غائبة، لا credentials). الجرد المستودعي للمقارنة: الجذر 0001→0017، الويب 0001→0016، المحلي ملف 0012 وحيد.

| Migration | Repo | Live | Match | Evidence | Notes |
|---|---|---|---|---|---|
| 0015 صور المنتجات (جذر+ويب) | نعم | UNKNOWN | UNKNOWN | ملف `0015_product_images_storage.sql` في المسارين | يعتمد عليه رفع صور الكتالوج |
| 0016 جذر (سلامة التخصيص) | نعم | UNKNOWN | UNKNOWN | `supabase/migrations/0016_bonus_inventory_allocation_safety.sql` | ظهر خارجيًا أثناء التدقيق |
| 0017 جذر (سلامة طلبات البونص) | نعم | UNKNOWN | UNKNOWN | `supabase/migrations/0017_bonus_order_integrity_and_analytics.sql` | يُضيف `create_order_with_items` الذي يستدعيه Flutter |
| 0016 ويب (untracked سابقًا) | نعم | UNKNOWN | UNKNOWN | `Medlik-Waap/supabase/migrations/0016_bonus_inventory_allocation_safety.sql` | وُجد `??` في حالة سابقة — يُحسم قبل التطبيق |
| المالية 0006W→0013W | نعم | UNKNOWN | UNKNOWN | 8 ملفات مالية في `Medlik-Waap/supabase/migrations/` | الإنتاج ممنوع قبل قائمتها |
| تعارض 0012 | نعم (ملفان) | UNKNOWN | UNKNOWN | الجذر `0012_special_requests.sql` ≠ المحلي `medlink_app/.../0012_client_account_notifications.sql` | المحلي لا يُطبق كما هو |

## Edge Functions
`supabase functions list --project-ref lmkomzqioneuyvatzsov` لم تُنفذ (لا CLI). `verify_jwt = true` مؤكد نصًا (`Medlik-Waap/supabase/config.toml:4,7`).

| Function | Exists in Repo | Deployed | Status/Version | Evidence |
|---|---|---|---|---|
| manage-driver-account | نعم (`supabase/functions/`) | UNKNOWN | UNKNOWN | كود فقط، بلا دليل نشر |
| manage-branch-manager-account | نعم (ويب) | UNKNOWN | UNKNOWN | كود فقط، بلا دليل نشر |
| manage-client-account | نعم (ويب) | UNKNOWN | UNKNOWN | كود فقط، بلا دليل نشر |
| fetch-exchange-rates | نعم (ويب) | UNKNOWN | UNKNOWN | `EXCHANGE_RATE_API_KEY` يُقرأ من البيئة (`index.ts:5`) — الوجود غير مؤكد والقيمة لا تُطبع |

## RLS
اختبار حي غير ممكن (لا حسابات أدوار ولا اتصال). الجدول أدناه: المتوقع من النصوص، والفعلي UNKNOWN.

| Role | Table | Operation | Expected | Actual | Status |
|---|---|---|---|---|---|
| director | invoices | UPDATE | Denied (لا سياسة) | UNKNOWN | STATIC VERIFIED نصًا / LIVE UNKNOWN |
| branch_manager | invoices (فرعه) | INSERT/UPDATE | Allowed | UNKNOWN | STATIC VERIFIED نصًا / LIVE UNKNOWN |
| client | driver_locations (طلب `in_progress` فقط) | SELECT | Allowed | UNKNOWN | STATIC VERIFIED (6/6 ساكن على `0008`) / LIVE UNKNOWN |
| branch_manager | driver_locations (سائقو فرعه) | SELECT | Allowed | UNKNOWN | STATIC VERIFIED نصًا / LIVE UNKNOWN |
| client | orders (طلباته) | SELECT/INSERT | Allowed | UNKNOWN | STATIC VERIFIED نصًا / LIVE UNKNOWN |
| driver | orders (المسندة) | SELECT | Allowed | UNKNOWN | STATIC VERIFIED نصًا / LIVE UNKNOWN |
| director | notifications | ALL | Allowed | UNKNOWN | STATIC VERIFIED نصًا / LIVE UNKNOWN |
| أدوار غير المدير | notifications المستهدفة | SELECT | مشروط | UNKNOWN | 3 تعريفات متنافسة — السارية UNKNOWN |
| director/accountant | financial_* | ALL/SELECT | حسب `0007W` | UNKNOWN | STATIC VERIFIED نصًا / LIVE UNKNOWN |
| accountant | أي واجهة | LOGIN | لا مسار (مرفوض في الويب، بلا دور في Flutter) | UNKNOWN | STATIC VERIFIED كفجوة / LIVE UNKNOWN |

## Build Verification
| Component | Command | Result | Environment | Evidence |
|---|---|---|---|---|
| Flutter analyze | `flutter analyze --no-pub` (من `medlink_app/`) | 4 infos (`deprecated_member_use`)، صفر errors/warnings — مكرر بنفس النتيجة | Flutter SDK عبر snap | `branch_invoice_create_sheet.dart:127`، `branch_order_actions.dart:46,104`، `addresses_screen.dart:498` |
| Flutter test | `flutter test` | 8/8 (7 بونص + placeholder) — مكرر بنفس النتيجة | نفس البيئة | `test/cart_controller_bonus_test.dart` + `test/widget_test.dart` |
| Web typecheck | `tsc -p tsconfig.json --noEmit` (عبر `pnpm run typecheck`) | PASS — exit 0، صفر أخطاء | Node 22.23.2 + pnpm 9.15.9 (مسار المستخدم) | ناتج الأمر المباشر، الجولة الثالثة |
| Web build | `vite build --config vite.config.ts` (عبر `pnpm run build`) | PASS — exit 0 في ~18s، 2453 وحدة → `dist/public/` (`sw.js` + `manifest.webmanifest`)؛ تحذيران غير قاتلين: sourcemap `sheet.tsx:2` وchunk ‏~1.5MB | نفس البيئة | ناتج الأمر المباشر، الجولة الثالثة |

## Critical Web Bugs (أُعيد التحقق — ما زالت قائمة)
- **Critical #1 — STATIC VERIFIED (عالية)**: `dashboardApi.ts:71` (`ACTIVE_ORDER_STATUSES` القديمة)، `:107-108`،`:112` (`.in('status',['Invoiced','Delivered'])`)،`:341` — مقابل القيد `0002:133` (`pending/assigned/in_progress/delivered/cancelled`). ما زال قائمًا: نعم.
- **Critical #2 — STATIC VERIFIED (عالية)**: `dashboardApi.ts:288` (`available_quantity`) — ولا وجود للعمود في أي migration (`grep` شامل صفر) مقابل `quantity` في `0004_phase4:26`. ما زال قائمًا: نعم.
- **Critical #3 — STATIC VERIFIED (عالية)**: `OrdersMonitoringPage.tsx:102` (`director_notifications` غير موجود)،`:10`,`:25` (`order_lines/client_name/client_governorate` غير موجودة)،`:228` (بوابة `Submitted/Draft/Allocated`)،`:211` (`tel:0000000`). ما زال قائمًا: نعم، بلا أي فرق عن التقرير السابق.

## Remaining Unknowns
1. المطبق حيًا من migrations (0015/0016/0017/المالية/0012) — لا CLI/credentials. 2. نشر/إصدار/تكوين الدوال الأربع. 3. سلوك RLS بالأدوار الخمسة — لا حسابات/اتصال. 4. أي بناء Release. 5. CI خارجي. 6. بيانات الإنتاج. 7. مفتاحا Maps وExchange. 8. typecheck/build الويب — عائق بيئي محلي (ممكن على Node ≥20).

## Recommended Next Actions
1. من جهاز مخوّل: `supabase migration list` + `functions list --project-ref lmkomzqioneuyvatzsov` واملأ جدولي §Migrations/§Functions.
2. مصفوفة RLS (جدول §RLS) على بيئة اختبار بحسابات الأدوار الخمسة.
3. على Node ≥20: `pnpm install --frozen-lockfile` (دون مساس بالمصدر) ثم `typecheck` ثم `build` وسجّل النتيجتين.
4. بعد اكتمال التحقق فقط: معالجة Criticals §6 ثم §10-4 من الموحد.

## Area / Status / Evidence / Action Required
| Area | Status | Evidence | Action Required |
|---|---|---|---|
| Flutter analyze | LIVE VERIFIED | 4 infos مكررة، صفر errors | لا شيء |
| Flutter tests | LIVE VERIFIED | 8/8 مكررة | توسيع التغطية لاحقًا |
| Web typecheck/build | LIVE VERIFIED | typecheck exit 0 + build exit 0 (2453 وحدة) على Node 22.23.2 + pnpm 9.15.9 | لا شيء (تحذيرا sourcemap/chunk للعلم فقط) |
| Migrations حيًا | PARTIAL (جرد حي جزئي) | 53 جدولًا حيًا؛ غياب special_requests/director_notifications؛ Remote فارغ في migration list (لا يثبت الغياب) | حسم الأعمدة/الدوال تم؛ السجل الكامل Unknown |
| Edge Functions | LIVE VERIFIED (منشور+مطابق) | 3/4 ACTIVE؛ الكود المنشور مطابق للمستودع (branch-mgr بفرق CRLF فقط)؛ `fetch-exchange-rates` غائبة (§V5.1 §V6.1) | توثيق مصدر صفّي الصرف |
| RLS سلوكًا | UNKNOWN (تعريفات+تفعيل LIVE VERIFIED) | تعريفات §R4.7-R4.8 حية + تفعيل 6/6 (§V5.4)؛ السلوك يحتاج حسابات لم تُنشأ | مصفوفة اختبار |
| Criticals #1-3 | LIVE VERIFIED (القيد/الأعمدة/الغياب) | §R4.4-R4.5 + غياب director_notifications حيًا | إصلاح لاحق |

## الجولة الرابعة — أدلة حية من القاعدة المنشورة (2026-09-18)
> الأدوات: Supabase CLI 2.117.0 (مسار المستخدم)، وصول مصادق مؤكد، المشروع `lmkomzqioneuyvatzsov`. كل الاستعلامات SELECT على كتالوج النظام فقط (metadata) — صفر بيانات تشغيلية، صفر كتابة.

### R4.1 Web — LIVE VERIFIED (مؤكد من الجولة الثالثة)
- `pnpm run typecheck` → exit 0 (Node 22.23.2 + pnpm 9.15.9). `pnpm run build` → exit 0 (2453 وحدة → `dist/public/` مع `sw.js` و`manifest.webmanifest`)؛ تحذيران غير قاتلين فقط (sourcemap `sheet.tsx:2`، chunk ~1.5MB).

### R4.2 Supabase CLI والوصول — LIVE VERIFIED
- `supabase --version` → `2.117.0`. `supabase projects list` نجح ويعرض `lmkomzqioneuyvatzsov` («موريد الادويه»). لا tokens معروضة.

### R4.3 الجداول الحية — LIVE VERIFIED (53 جدولًا في `public`)
- `director_notifications` **غائب** (Critical #3 مؤكد حيًا). `special_requests` **غائب** (دليل قوي أن `0012` الجذر غير مطبق — دون ادعاء حسم كامل السجل).
- الطبقة المالية كاملة موجودة (26 جدول `financial_*` + `payout_*`) مع بصمات seeding (`companies=1`, `fiscal_years=1`, `periods=12`, `currencies=3`, `accounts=15`).
- بيانات حية: users=8، branches=22، products=1، orders=2، order_items=2، inventory=22، warehouse_inventory=25، notifications=6، exchange_rates=2.
- `public.projects` (0 صفوف) موجود **ومصدره Unknown** — لا تخمين.

### R4.4 الأعمدة الحية — LIVE VERIFIED
- orders: `id, client_id, branch_id, parent_order_id, target_branches, status, delivery_address_id, assigned_driver_id, total_amount, scheduled_delivery_at, notes, created_at, priority, delivered_at` — **لا** `client_name/client_type/client_governorate/order_lines` (Critical #3 حيًا)؛ وجود `priority/delivered_at` = بصمة `0009`.
- order_items: بلا `bonus_rule_id` → `0017` غير مطبق. inventory: `quantity` فقط (Critical #2 حيًا). warehouse_inventory: `quantity + reorder_level + expiry_date + unit_price` (مطابق). products: كاملة بأعمدة `0014W`. notifications: مع `target_user_ids`. users/invoices: كاملة مع `account_status/credit_limit/current_balance` و`branch_id`.

### R4.5 قيد `orders.status` الحي — LIVE VERIFIED
- `CHECK ((status = ANY (ARRAY['pending','assigned','in_progress','delivered','cancelled'])))` — Critical #1 مؤكد حيًا (قيم الـdashboard مستحيلة التخزين).

### R4.6 الدوال — LIVE VERIFIED
- `branch_allocate_order(uuid,boolean,date,jsonb)` الحية = **نسخة إصلاح 0016** (علامات: `v_required_qty/v_paid_qty/v_paid_unit_price`، أقفال `FOR UPDATE`، تجميع `group by product_id`، فوترة الجزء المدفوع `least(...)`) — ليست 0009 الأصلية.
- `create_order_with_items` و`get_order_product_distribution`: **0 صفوف** (غائبتان) — لا يُدَّعى أكثر من ذلك.
- 16 دالة أخرى موجودة (التخصيص/المخزون/السائق/المالية/الأطباء/`handle_new_user`/`sync_new_product_to_branches`).

### R4.7 السياسات الحية — LIVE VERIFIED (تعريفات)
- driver_locations: طقم `0008` بالضبط (الواسعة القديمة غائبة).
- orders/inventory/warehouse_inventory: مطابقة المستودع.
- invoices: 5 سياسات مطابقة المستودع — **لا UPDATE/DELETE للمدير** (الفجوة مؤكدة على مستوى التعريف).
- notifications: 6 سياسات (انظر R4.8). صيغة `select_relevant` الحية (`target_user_ids IS NULL OR...`) تطابق نسخة الملف المحلي لا `0005W` — دليل على أي الملفين طُبق، دون حسم تاريخ/مصدر الإنشاء.

### R4.8 اكتشاف حرج جديد — سياسات `Allow all` على notifications — LIVE VERIFIED
| policy | cmd | roles | USING / WITH CHECK |
|---|---|---|---|
| Allow all delete notifications | DELETE | {public} | `true` |
| Allow all insert notifications | INSERT | {public} | `true` (WITH CHECK) |
| Allow all read notifications | SELECT | {public} | `true` |
| Allow all update notifications | UPDATE | {public} | `true` |
- الأثر: مسار RLS غير مقيد (حتى للمجهول) يتعارض مع سياسات الدور المقصودة. المصدر/التاريخ Unknown — لا يُخترع (بصمة اسمية توحي بإنشاء Dashboard يدوي، وتُسجل كملاحظة لا كحقيقة).

### R4.9 حدود صريحة (لا ادعاء زائد)
- وجود كائنات حية لا يثبت تطبيق migration بعينها ولا تاريخه — السجل الكامل Unknown.
- `migration list` أظهر Remote فارغًا لـ0001→0017: هذا **لا يثبت غياب الكائنات** (الأداة تتعقب CLI فقط؛ التطبيق اليدوي لا يظهر) — وهو متسق مع ما وجدناه حيًا.
- سلوك RLS الفعلي بالأدوار ما زال UNKNOWN (التعريفات مؤكدة، السلوك يحتاج حسابات اختبار).

## سجل التحقق الحي — الجولة الخامسة (2026-09-18 ~19:38–19:46 UTC)
> كل الأوامر READ-ONLY على المشروع `lmkomzqioneuyvatzsov` عبر Supabase CLI 2.117.0. لا كتابة، لا أسرار معروضة.

### V5.1 قائمة الدوال المنشورة — LIVE VERIFIED
- الأمر: `supabase functions list --project-ref lmkomzqioneuyvatzsov` (قراءة فقط).
- النتيجة: 3 دوال ACTIVE — `manage-branch-manager-account` (v2، حدُّثت 2026-08-12)، `manage-client-account` (v1، 2026-08-12)، `manage-driver-account` (v1، 2026-09-03).
- المثبت: الدوال الثلاث التي يستدعيها الكود منشورة ونشطة. **غير المثبت**: تطابق الكود المنشور مع المستودع (الإصدار لا يكشف المحتوى).
- اكتشاف: `fetch-exchange-rates` **غير منشورة** (غائبة من القائمة) — LIVE VERIFIED بالغياب؛ أسعار الصرف الحية (صفّان) مصدر إدخالهما Unknown. `EXCHANGE_RATE_API_KEY` ما زال UNKNOWN.
- أخطاء/توقف: لا.

### V5.2 محفزات public الحية — LIVE VERIFIED
- الأمر: SELECT على `pg_trigger` (قراءة فقط).
- النتيجة: 11 محفزًا — `trg_orders_set_delivered_at`، `trg_invoice_increase_balance`، `trg_payment_decrease_balance`، `trg_sync_new_product_to_branches`، `trg_financial_{invoice,commission×2,bonus}_auto_journal`، `trg_financial_journal_{,line}_immutable`، و`update_projects_updated_at` على جدول `projects`.
- المثبت: بصمات `0009` و`0004W` و`0014W` و`0008W/0009W` مطبقة. `update_projects_updated_at` يؤكد أن جدول `projects` مجهول المصدر مُدار فعليًا — مصدره Unknown (لا تخمين).
- ملاحظة منهجية: استعلام أول بصيغة `LIKE` أعاد صفرًا خطأً؛ أُعيد بصيغة join صريحة ونجح — سُجل الخطأ هنا بدل إخفائه.

### V5.3 حاويات التخزين — LIVE VERIFIED (غياب حرج)
- الأمر: `SELECT id, name, public FROM storage.buckets` (metadata فقط).
- النتيجة: حاوية واحدة فقط — `videos` (public). **لا توجد `product-images`**.
- المثبت: migration `0015` (الجذر والويب) غير مطبقة حيًا أو حُذفت حاويتها — والنتيجة المباشرة أن رفع صور الكتالوج من `CatalogPage.tsx:206-208` سيفشل حيًا (تحليل مبني على الدليل، موسوم كذلك).
- أخطاء: المحاولة الأولى انتهت مهلتها (transient)؛ نجحت الإعادة.

### V5.4 تفعيل RLS على الجداول الستة — LIVE VERIFIED
- الأمر: SELECT على `pg_class.relrowsecurity` (قراءة فقط).
- النتيجة: `relrowsecurity = true` على `orders, driver_locations, invoices, notifications, inventory, warehouse_inventory` (6/6).
- المثبت: RLS مفعّل. غير المثبت: السلوك الفعلي بالأدوار (يحتاج حسابات اختبار — لم تُنشأ التزامًا بالقواعد) → يبقى UNKNOWN.

### V5.5 سلوك RLS بالأدوار — UNKNOWN (مسجل بالسبب)
- لم يُنفذ أي اختبار صلاحيات: لا توجد حسابات اختبار، ويُمنع إنشاء حسابات أو استعمال الإنتاج. مصفوفة Role×Table×Operation تبقى UNKNOWN بالكامل.

### تعارضات مسجلة بلا تسوية
- C1: `migration list` أظهر Remote فارغًا لـ0001→0017 بينما الكائنات الحية تثبت تطبيقًا جزئيًا واسعًا (بما فيه إصلاح 0016) — التفسير الموثق: التطبيق اليدوي لا يظهر في سجل CLI. لا يُدَّعى أي اتجاه.
- C2: سياسات `Allow all` على notifications تتعارض مع سياسة الدور على نفس الجدول — مسجلة كما هي.
- C3: `select_relevant` الحية بصيغة الملف المحلي لا `0005W` — مسجلة كدليل على الملف المطبق دون تاريخ.

## سجل التحقق الحي — الجولة السادسة (2026-09-18 ~20:03–20:10 UTC)
> READ-ONLY. الدوال حُملت إلى `/tmp` خارج المستودع؛ لا أسرار (الكود يقرأ credentials من `Deno.env` فقط).

### V6.1 مطابقة الكود المنشور للدوال — LIVE VERIFIED
- الأمر: `supabase functions download <name> --project-ref lmkomzqioneuyvatzsov --use-api` للثلاث (قراءة فقط).
- `manage-driver-account`: **مطابق بايتًا لبايت** لملف المستودع (`supabase/functions/.../index.ts`).
- `manage-client-account`: **مطابق بايتًا لبايت** لملف المستودع (`Medlik-Waap/.../index.ts`).
- `manage-branch-manager-account`: مطابق المحتوى مع فرق نهايات الأسطر فقط (المنشور CRLF — بصمة رفع من Windows؛ المستودع LF). سُجل الفرق كما هو دون تسوية.
- `fetch-exchange-rates`: غائبة من `functions list` (مؤكد من V5.1) — غير منشورة.
- `verify_jwt` حيًا: لا عمود لها في `functions list` ولا طريقة قراءة متاحة → تبقى STATIC من `Medlik-Waap/supabase/config.toml:4,7`، وحيًّا UNKNOWN.

### V6.2 سجل `supabase_migrations` — LIVE VERIFIED (بالغياب)
- الأمر: `SELECT count(*) FROM supabase_migrations.schema_migrations` → خطأ `42P01: relation does not exist`.
- المثبت: **لا migration طُبق عبر CLI إطلاقًا** — كل الكائنات الحية أُدخلت يدويًا (Dashboard/SQL). هذا يفسر Remote الفارغ في `migration list` نهائيًا (C1 مغلق كتفسير موثق، لا كتخمين).

### V6.3 جدول `projects` — unrelated مؤكد بالبنية، المصدر Unknown
- الأمر: أعمدة `public.projects` → `id, video_url, user_command, status, output_url, created_at, updated_at, user_email, transcript, template_id, content_type, duration_seconds, error`.
- المثبت: بنية أداة توليد فيديو (تتكامل مع bucket `videos`) — **لا علاقة له بـMedLink ولا بأي migration في المستودعين**. المصدر/المالك: `Source/creation time: UNKNOWN` (لا تخمين).
- حاوية `videos` أُنشئت `2026-08-08` (من `storage.buckets.created_at`) — التاريخ الوحيد المؤكد بأداة؛ غيره Unknown.

### V6.4 ما تعذر إثباته (يبقى UNKNOWN)
- تطابق محتوى الدوال الثلاث لحظة نشرها الأولى مقابل تحديثاتها (الإصدارات v1/v1/v2 توثق التحديث لا المحتوى السابق).
- تواريخ/مصادر: سياسات `Allow all`، جدول `projects`/حاوية `videos` (عدا تاريخ الحاوية)، كل migration فردية.
- سلوك RLS بالأدوار (لا حسابات اختبار — محظور إنشاؤها).

## ROUND 7 — FINAL UNKNOWN CLOSURE (2026-09-18 ~20:29–20:32 UTC)
> READ-ONLY فقط. لا حسابات اختبار، لا كتابة، لا أسرار.

### R7.1 Migration provenance
- Status: UNKNOWN (نهائي بهذه الأدوات).
- Evidence: بحث `information_schema.tables WHERE table_name ILIKE '%migration%'` أعاد فقط جداول Supabase الداخلية (`auth.schema_migrations`، `realtime.schema_migrations`، `storage.migrations`) — لا سجل مستخدم. `supabase_migrations.schema_migrations` غير موجود (V6.2).
- What is proven: لا يوجد أي مسار metadata يكشف تاريخ/مصدر/ترتيب التطبيق اليدوي (كتالوجات PG لا تخزن طوابع DDL؛ CLI لم يُستخدم إطلاقًا).
- What is not proven: أي شيء عن متى/بأي ترتيب طُبق كل ملف.
- Limitation: الإثبات الوحيد الممكن هو سجلات Dashboard audit (غير متاحة عبر CLI).

### R7.2 Allow-all policies (مصدر/تاريخ)
- Status: UNKNOWN (نهائي).
- Evidence: `pg_policy` لا يحمل أي طابع زمني أو مالك إنشاء قابل للاستعلام؛ لا جدول سجل متاح.
- What is proven: التعريفات والسلوك الضمني (`public` + `true`) فقط.
- What is not proven: المصدر والتاريخ — أي تخمين (Dashboard/شخص/أداة) مرفوض.
- Limitation: تتطلب سجلات المنصة أو إفادة المشغّل البشري.

### R7.3 RLS behavior
- Status: UNKNOWN (نهائي بهذه القيود).
- Evidence: لم يُختبر — لا test identities مصرح بها، ويُحظر إنشاؤها أو مساس الإنتاج.
- What is proven: التعريفات (R4.7) + التفعيل 6/6 (V5.4) فقط.
- Limitation: الطريقة الآمنة الوحيدة الموثقة (دون تنفيذ): مشروع اختبار منفصل + حسابات أدوار مُعدّة بموافقة المالك + مصفوفة Role×Table×Operation — تُذكر هنا كخطة لا كتنفيذ.

### R7.4 Edge Functions (استكمال)
- Status: LIVE VERIFIED للمنشور/الحالة/الإصدار/التواريخ/المطابقة (V5.1+V6.1)؛ UNKNOWN لتطابق لحظة النشر الأولى ولمحتوى `verify_jwt` الحي.
- Evidence: `functions list` (3 ACTIVE + تواريخ) + `download` ومقارنة بايتية (فرق CRLF وحيد مسجل).
- Limitation: `list` لا يعرض `verify_jwt` ولا محتوى الإصدارات السابقة.

### R7.5 Exchange rates (مصدر الصفّين)
- Status: UNKNOWN للمصدر (بتضييق جديد).
- Evidence: `SELECT currency_code, fetched_at` → صفّان (USD/SAR) بنفس الطابع `2026-08-16 20:15:25` — متسق مع إدخال دفعة واحدة (سلوك دالة الجلب يُدخل الاثنين معًا) **ومتسق أيضًا** مع إدخال يدوي مزدوج.
- What is proven: التوقيت فقط. What is not proven: الدالة مقابل اليدوي (الدالة نفسها غير منشورة اليوم، لكن ربما نُشرت ثم حُذفت — لا دليل).
- Limitation: لا سجل تنفيذ دوال متاح قرائيًا عبر CLI. (استعلام أول انتهت مهلته transient؛ أُعيد بصيغة أضيق ونجح — مسجل.)

### R7.6 Storage (تثبيت)
- Status: LIVE VERIFIED (بلا تغيير): حاوية `videos` فقط؛ `product-images` غائبة (مؤكد ثانيةً بتاريخ 20:29 UTC).
- Limitation: لا شيء معلق هنا — البند مغلق.

## SKILLS & MCP INVENTORY (2026-09-18 — READ-ONLY، بلا تثبيت/حذف/تعديل)
> الأوامر: فحص مجلدات (`ls`) + `opencode mcp list` (v2.0.6) + قراءة `opencode.json`. لم يُغيَّر أي ملف إعدادات.

### الموجود حاليًا — Skills (11، كلها project في `.opencode/skills/`)
| Skill | يغطي من احتياجات المشروع |
|---|---|
| flutter-medlink | Flutter/Mobile |
| web-admin-dashboard | Web/Admin |
| supabase-database | Supabase/PostgreSQL/RLS/Functions |
| api-contracts | عقود API المشتركة |
| medlink-architecture | Architecture |
| medlink-design-system | Design System + Modern UI/UX |
| medlink-repository-audit | تدقيق المستودع |
| security-privacy | Security |
| testing-verification | Testing/QA |
| release-deployment | Builds/Releases |
| windows-medlink | Windows/Desktop (لاحقًا) |
- المصادر الأخرى: global (`~/.config/opencode/skills`) غائب، `.agents/skills` غائب، `.claude/skills` غائب — لا Skills خارج المشروع.
- صلاحيات Skills في `opencode.json:43-54`: `skill:* allow` + `skill:medlink-* allow` — مفعّلة.

### الموجود حاليًا — MCP servers
| MCP | الحالة | ملاحظة |
|---|---|---|
| context7 | disabled (مدرج لكن معطل) | موثق/مكتبات — مفيد لـFlutter/Web/Supabase |
| figma | disabled | مفيد لـDesign System إن وُجد ملف Figma (لا دليل عليه في المستودع) |
| github | disabled | يحتاج `GITHUB_PERSONAL_ACCESS_TOKEN`؛ مفيد لـCI/PR لاحقًا |
| playwright | مهيأ في `opencode.json:17-24` لكن **غائب من `mcp list`** | على الأرجح فشل الإقلاع (npx + Node النظام v10) — يحتاج Node حديث في PATH الـMCP |
| supabase | **غير مهيأ إطلاقًا** | لا سيرفر في الإعدادات ولا في القائمة |

### المطلوب للمشروع مقابل الموجود
- مغطى بالSkills: كل المجالات العشرة (بما فيها Windows لاحقًا) — لا حاجة Skills جديدة الآن.
- MCP ناقص حرج: **Supabase MCP** (قراءة schema/سياسات/سجلات دون CLI يدوي) — مفقود.
- MCP موجود لكن غير متصل: context7 (تفعيله يفيد Flutter/Supabase)، playwright (إصلاح إقلاعه يفيد اختبار الويب E2E)، github/figma (يؤجلان حتى CI/Figma فعلي).
- ما يؤجل لـWindows phase: تفعيل `windows-medlink` عمليًا + أي MCP خاص بسطح المكتب (لا شيء مطلوب الآن).
- تعارض/ملاحظة: `playwright` المهيأ يعتمد Node النظام (v10) فيشتغل؛ الحل البيئي (Node 22 في مسار المستخدم) لا يراه افتراضيًا — توثيق فقط، بلا تغيير.

## SUPABASE MCP — إضافة وتهيئة (2026-09-18، إعدادات OpenCode فقط)
- اسم MCP: `supabase` — أُضيف إلى `opencode.json → mcp.servers` (14 سطرًا، JSON valid مؤكد).
- طريقة التهيئة (بلا أسرار): سيرفر local عبر `npx -y @supabase/mcp-server-supabase@latest --read-only --project-ref=lmkomzqioneuyvatzsov` مع تمرير `SUPABASE_ACCESS_TOKEN` من متغير البيئة فقط (`{env:...}` على نمط مدخل github) — لم تُكتب أي قيمة في أي ملف.
- حالة الاتصال: **غير متصل** — `opencode mcp list` لا يظهره (نفس عرض `playwright` المهيأ: context7/figma/github disabled فقط).
- project ref: `lmkomzqioneuyvatzsov` (المشروع الآخر لم يُذكر إطلاقًا).
- اختبار READ-ONLY: **لم يُنفذ** — يتطلب (1) `SUPABASE_ACCESS_TOKEN` مهيأ محليًا من المالك دون إرساله هنا، و(2) غالبًا Node حديث لمشغّل npx (النظام v10) — كلاهما خارج صلاحية هذه الخطوة.
- المثبت: الإدخال موجود وصالح بنيويًا. غير المثبت: أي اتصال أو قراءة عبر MCP.
- ملاحظة: `opencode.json` أصبح tracked-modified (+14) — تغيير إعدادات مقصود ومصرّح به منك، لا تغيير تطبيقي.

## MCP RUNTIME — تشخيص تشغيل Supabase MCP (2026-09-18)
- ثبت: Node 22.23.2 + npm/npx 10.9.8 تعمل من مسار fnm (`~/.local/share/fnm/.../bin`)؛ لا sudo ولا مساس بالنظام.
- ثبت: `opencode mcp list` (v2.0.6) يعرض المهيأ فقط عند نجاح الإقلاع؛ أوامر فرعية متاحة: `list/add/auth/logout` (لا فحص تشخيصي أعمق).
- تغيير إعدادات موثق (ضروري لتحديد executable): أمر سيرفر `supabase` في `opencode.json` أصبح مسار npx المطلق لـNode 22 بدل `npx` العام (الذي كان يحل إلى Node v10). JSON valid مؤكد بعد التعديل.
- النتيجة: `supabase` **ما زال غائبًا من القائمة** بعد الإصلاح — أي أن runtime لم يكن العائق الوحيد؛ المرجح (غير مثبت) غياب `SUPABASE_ACCESS_TOKEN` في بيئة التشغيل فيُنهي السيرفر بدءه.
- المطلوب من المالك محليًا (دون إرسال شيء هنا): تهيئة `SUPABASE_ACCESS_TOKEN` في بيئة تشغيل OpenCode ثم إعادة `opencode mcp list`.

## SUPABASE MCP — حالة الاتصال والاختبار (2026-09-19)
- التوكن: مهيأ محليًا من المالك (مؤكد الوجود دون طباعة أي قيمة) — `TOKEN_PRESENT_IN_SHELL`.
- `opencode mcp list`: لا يظهر `supabase` (ولا `playwright`) — context7/figma/github disabled فقط.
- اختبار عبر `opencode run` (خلفية): الوكيل أفاد `search({query:"supabase"})` → 0 أدوات — لا MCP متاح.
- اختبار عبر `opencode run --standalone` (سيرفر خاص يقرأ الإعدادات الحالية): نفس النتيجة — الكتالوج يحوي `browser.*` و`opencode.*` فقط؛ الوكيل قرأ `opencode.json:25-38` وأكد الإعداد موجودًا لكنه غير محمّل. رفض التخمين وامتنع عن إرجاع جداول.
- تشخيص الحزمة نفسها: تشغيل `npx @supabase/mcp-server-supabase@latest --read-only --project-ref=...` يدويًا تحت Node 22 ينطلق وينتهي نظيفًا (exit 0) — الحزمة سليمة؛ الخلل في تحميل OpenCode للسيرفر لا في الحزمة أو التوكن (استنتاج تشخيصي مسجل كذلك).
- النتيجة: **MCP غير وظيفي في هذه البيئة رغم صحة الإعداد والتوكن** — الاختبار القرائي عبر MCP **لم يُنفذ** (تعذر الأداة نفسها). التحقق الحي مستمر عبر Supabase CLI (يعمل ومصادق).
- لا كتابة ولا أسرار في أي مخرج.

## CONTEXT7 MCP — تفعيل واختبار (2026-09-19)
- الإعداد السابق: remote `https://mcp.context7.com/mcp` مع `disabled:true` — يعمل دون secret رسميًا (حدود معدل مجهول).
- التغيير (إعدادات فقط): حذف سطر `disabled` من مدخل `context7` في `opencode.json` — لا secret أُضيف، ولا شيء آخر مُس.
- `opencode mcp list` → `✓ context7 connected` (figma/github بقيتا disabled؛ supabase/playwright غائبان كما قبل).
- الاختبار عبر `opencode run --standalone`: الأدوات حاضرة في الكتالوج (`resolve-library-id` / `query-docs`). المحاولة الأولى لـ`resolve-library-id` فشلت بخطأ نقل عابر (`socket closed`)؛ الإعادة نجحت وأعادت IDs حقيقية (`/supabase/supabase`، `/supabase/cli`...).
- النتيجة: **LIVE VERIFIED** — Context7 متصل ووظيفي. Supabase MCP لم يُمس (كما أمرت).

## PLAYWRIGHT MCP — تشخيص وإصلاح جزئي (2026-09-19)
- السبب الأول: أمر `npx` العام يحل إلى Node v10 (shebang `env node`) فيقتل سيرفرات MCP المحلية عند الإقلاع — مثبت بالفحص.
- الإصلاح (إعدادات فقط): أمر `playwright` أصبح `[node-22-absolute, ~/.local/lib/node_modules/@playwright/mcp/cli.js]` بعد تثبيت `@playwright/mcp@0.0.81` user-global عبر npm المستخدم (خارج المستودع تمامًا، بلا sudo). JSON valid مؤكد.
- تشغيل السيرفر يدويًا: ينطلق وينتهي نظيفًا (exit 0) — الثنائية سليمة. لم تُثبت متصفحات (`~/.cache/ms-playwright` غائب) لأنها غير لازمة للتسجيل — سُجل السبب بدل التثبيت العشوائي.
- النتيجة: `mcp list` ما زال لا يعرضه، وجلسة `--standalone` أفادت `tools-present: no` — أي أن OpenCode 2.0.6 هنا لا يحمّل سيرفرات MCP المحلية إطلاقًا (supabase/playwright)، بينما البعيدة (context7) تعمل. السبب الجذري داخل OpenCode نفسه: UNKNOWN (مسجل كذلك، بلا تخمين).
- Supabase MCP لم يُمس في هذه الجولة.

## GITHUB & FIGMA MCP — فحص وتفعيل (2026-09-19)
### Figma (remote)
- الإعداد السابق: remote + disabled. التغيير: حذف `disabled` فقط (بلا secrets). JSON valid.
- `mcp list` → `⚠ figma needs authentication` (ظاهر، غير متصل).
- المصادقة الرسمية: `opencode mcp auth figma` → فشل: `Dynamic Client Registration rejected (HTTP 403): Forbidden` — سيرفر Figma يرفض تسجيل هذا العميل؛ لا مسار OAuth ذاتيًا ولا توكن يدويًا مسموحًا هنا.
- النتيجة: **BLOCKED (auth)** — لم يُختبر أي أداة. لا أسرار طُلبت أو وُضعت.

### GitHub (local عبر docker)
- النوع: local — `docker run ... ghcr.io/github/github-mcp-server` + توكن env.
- الفحص: `docker` **غائب** من الجهاز (`command -v docker` فارغ) + لا توكن مهيأ.
- القرار: تُرك disabled — التفعيل لن يغير شيئًا (عائقان: runtime مفقود + مصادقة مفقودة)، وتثبيت docker خارج النطاق.
- النتيجة: **BLOCKED (runtime + auth)** — معها يتأكد نمط أوسع: المحلية (supabase/playwright/github) لا تعمل هنا؛ البعيدة بلا مصادقة (context7) تعمل.

## BONUS SYSTEM CLOSURE REPORT (2026-09-19 — VERIFY/CLOSE، بلا تعديل تطبيقي)
> المواصفة: `attached_assets/...Bonus-Syste_1789739862650.txt` (§1–§13). القاعدة: PASS/LIVE تحتاج دليلًا منفذًا؛ لا PASS على وجود كود يحتاج تحققًا حيًا.

### A. Requirements
| § | المتطلب | الحالة | الدليل | ملاحظة |
|---|---|---|---|---|
| §1 | صلاحية القاعدة (نشطة/تاريخ/محافظة) | PASS | `cart_controller.dart:108-139` + نفس المنطق خادميًا `0017:145-190` + اختبارات D-G | العميل والخادم متطابقان |
| §2 | قواعد متعددة حتمية | PASS | `cart_controller.dart:95-100,143-163` + `0017:101-104,182-190` + اختبار الأولوية | موثق في الكود |
| §3 | القاعدة العامة (null) | DECISION REQUIRED | `cart_controller.dart:139,146-148` + `0017:169-170` يعاملانها "عامة"؛ لا قرار مكتوب | السلوك موجود، القرار التجاري غائب |
| §4 | مخزون البونص (11 وحدة، بلا خصم مضاعف) | PARTIAL | `0016` حيًا فعال (تعريف حي مؤكد)؛ مسار الإنشاء ينتظر `0017` | الكود/SQL جاهز، الحي معلق |
| §5 | عرض العميل (شارة/0/الإجمالي/التفاصيل) | PASS | `cart_item_tile.dart:53-97`، `order_detail_screen.dart:358-385` | — |
| §6 | مدير الفرع (فصل مدفوع/بونص، بلا حذف) | PASS | `branch_allocate_sheet.dart:61,515`، `branch_order_detail_screen.dart:210-221` | — |
| §7 | السائق (عرض فقط) | PASS | `driver_order_detail_screen.dart:211-249` | — |
| §8 | المالية (حركة مخزون متسقة، بلا ازدواج) | PASS | `trg_financial_bonus_inventory` حيًا (قائمة المحفزات) + تصميم `0016` | السلوك التنفيذي ينتظر `0017` |
| §9 | التحليلات (مدفوع/بونص/إجمالي) | PARTIAL | RPC `get_order_product_distribution` (`0017:247-281`) + موديل `OrderDistribution`؛ لا مستهلك UI | RPC غير مطبق حيًا ولا واجهة تستهلكه |
| §10 | إشعارات الإدارة | DECISION REQUIRED | الإنشاء يُشعِر (`bonusRulesApi`)؛ التعديل/التفعيل صامت (بلا سبام) — المواصفة تركتها مفتوحة | لا تغيير سلوك |
| §11 | Web/Admin كما هي + التوافق | PASS | panels/form intact + نفس الحقول؛ `tsc` exit 0 و`build` exit 0 (أُعيدا) | — |
| §12 | قاعدة البيانات (ترقيم، بلا ازدواج، RLS) | PASS | `0016`(156 سطر)→`0017`(283 سطر) تسلسل صحيح؛ لا جداول/أعمدة مكررة؛ grants لـauthenticated | التنفيذ الحي يدوي لاحقًا |
| §13 | اختبار التدفق A-O | PARTIAL | A-I آليًا (8/8)؛ J-O وسكربت الانحدار محظور التنفيذ (بلا DB اختبار) | السكربت جاهز |

### B. Implementation
- Flutter: Cart/Order/Branch/Driver bonus كامل + badge/split/display. Branch: allocate sheet بالفصل. Driver: عرض. Web/Admin: CRUD + إشعار إنشاء + panels سليمة. Database/Migrations: `0016` (حي) + `0017` (مستودع فقط). Tests: 7 بونص + placeholder (8/8).

### C. Live Database
- `0016`: فعالة حيًا (تعريف `branch_allocate_order` = نسخة الإصلاح). `0017`: غائبة كليًا (الدالتان 0 صفوف، ولا `bonus_rule_id`). RPCs الأخرى حاضرة. الأعمدة: كل المطلوب موجود عدا `bonus_rule_id`. Trigger البونص المالي حاضر. Discrepancy: سياسات `Allow all` على notifications + جدول `projects` المجهول (خارج نطاق هذه المهمة — مسجلان سابقًا).

### D. Regression (I1/I2/I3)
- السكربت `scripts/sql/bonus-invariants-regression.sql`: أسماء الأعمدة/RPC مطابقة حرفيًا لـ`0017`؛ `ROLLBACK` دائم؛ ملف جديد خارج `supabase/migrations/` (لا يُطبق تلقائيًا).
- الحالة: **BLOCKED — no safe test database available** (لم يُنفذ؛ الإنتاج محظور، ولا scratch/local).

### E. Decisions Required
1. هل `product_id=NULL` = قاعدة عامة رسميًا؟ 2. هل تعديل/تفعيل/تعطيل القاعدة يُشعِر العملاء أم الإنشاء فقط؟ (لا إجابة في المصدر — لا تغيير سلوك.)

### F. Blockers
1. تطبيق `0017` حيًا (يدوي، بقرار المالك). 2. قاعدة اختبار لتنفيذ سكربت الانحدار + سيناريوهات J-O.

### G. Manual Action Required
1. راجع `0017` ثم نفذها يدويًا (Dashboard/SQL) — **0017 READY FOR MANUAL EXECUTION**: تنشئ `bonus_rule_id` + قيد `order_items_bonus_price_check` + RPC التحقق `create_order_with_items` + RPC التحليلات؛ تسقط سياستي الإدخال المباشر (لا مُدخل مباشر آخر في الكود — فحص `grep` صفر)؛ prerequisite: `0016` مطبقة فعلًا حيًا؛ المخاطر: بعد التطبيق يصبح الإنشاء حصرًا عبر RPC (مقصود ومصمم له).
2. وفّر scratch DB لتشغيل سكربت الانحدار. 3. احسم القرارين التجاريين.

### H. Final Status
**PARTIALLY COMPLETE — ACTION REQUIRED** (ليست READY FOR FINAL LIVE VERIFICATION: سلوك §4/§8/§13 الحي معلق على `0017`؛ ولا COMPLETED: §9 جزئي وقراران مفتوحان).

## BONUS SYSTEM — 0017 vs FULL SPEC GAP ANALYSIS (2026-09-19 — ANALYZE ONLY، صفر تغيير)
> المواصفة الجديدة: نظام Bonus مالي (Balance/Ledger/EARN/REDEEM_PRODUCT/ORDER_DISCOUNT/CASH_WITHDRAWAL/REFUND/REVERSAL/ADJUSTMENT/EXPIRATION + سحب نقدي بدورة PENDING→…→COMPLETED + Available/Reserved/Used + dashboards). المصدر: `supabase/migrations/0017_bonus_order_integrity_and_analytics.sql` (283 سطرًا، قُرئ كاملًا) + `0016` + جدول `bonus_rules` (`0003`).

### 1. Scope
مراجعة ما تفعله `0017` فعلًا مقابل المواصفة المالية الجديدة — تحليل فقط، بلا تنفيذ/تعديل/إنشاء.

### 2. Evidence (ما تفعله 0017 حرفيًا)
- `order_items.bonus_rule_id` (FK → bonus_rules) + قيد `order_items_bonus_price_check (not is_bonus or unit_price=0) NOT VALID`.
- إسقاط سياستي `orders_client_insert` و`order_items_insert` (الإنشاء حصرًا عبر RPC).
- `create_order_with_items(uuid,jsonb,text)`: تحقق خادمي (عنوان العميل، منتجات نشطة، سعر مطابق ±0.005، كمية بونص مطابقة لقاعدة منتقاة حتميًا، rule_id مطابق)، إجمالي مدفوع محسوب خادميًا، أول فرع كفرع افتراضي.
- `get_order_product_distribution`: paid/bonus/total لكل (order,product) مع فلتر رؤية حسب الدور.
- `GRANT EXECUTE ... TO authenticated` للدالتين.

### 3. Current 0017 capabilities (تغطي نموذج Buy X → Free Y فقط)
تحقق سعري/كمي خادمي، منع تلاعب البونص، اختيار rule حتمي (خاص→عام/أعلى بونص/أدنى عتبة/أقدم/ID)، `bonus_rule_id` للتدقيق، فصل paid/bonus/total للتحليل، إغلاق الإدخال المباشر.

### 4-5. Gap Analysis (مختصر — التفصيل في §6)
| المتطلب الجديد | 0017 | السبب |
|---|---|---|
| Bonus Balance (Available/Reserved/Used) | Not Supported | لا جدول رصيد؛ لا أعمدة حجز/استخدام |
| Ledger + EARN/REDEEM/REFUND/REVERSAL/ADJUSTMENT/EXPIRATION | Not Supported | لا ledger؛ الأحداث الوحيدة سطور طلبات |
| ORDER_DISCOUNT (خصم على طلب) | Not Supported | البونص وحدات مجانية فقط، لا خصم قيمي |
| CASH_WITHDRAWAL + دورة PENDING→…→COMPLETED/REJECTED + حدود/موافقات/إيصالات | Not Supported | لا كيانات سحب إطلاقًا |
| Double-spend protection مالي | Partial | محمي telescopically داخل الطلب الواحد (كمية مطابقة + سعر)؛ لا رصيد مركزي يُستنزف |
| Audit غير قابل للحذف | Partial | `bonus_rule_id` + سطور دائمة؛ بلا ledger/compensating مخصص |
| قواعد مرنة (حد أدنى طلب/نوع عميل/نوع بونص/نسبة/حدود/انتهاء...) | Not Supported | `bonus_rules` = (product,buy,free,stackable,dates,governorate,active) فقط |
| Dashboards (عميل/مدير/سحب/تحليلات) | Not Supported | لا RPCs/واجهات لها (التوزيع RPC موجود بلا مستهلك UI) |

### 6. فصل أنواع البونص + سلامة 0017 المحفوظة + علاقتها بـ0016
- التمييز الصريح: **غائب**. `NULL product_id` يُعامل "عامًا" في الكود (`cart_controller:146-148`) و`0017:169-170` لكن بلا حقل نوع — لا تمييز Product-based / Monetary / General → **GAP / DECISION REQUIRED** (تأكيد ما سُجل في الإغلاق).
- `bonus_rules` مصمم حصريًا لـBuy X → Free Y (الأعمدة العشرة أعلاه؛ لا نوع/قيمة/نسبة/حدود/استخدامات) → **غير قادر على المواصفة الجديدة نصًا**.
- ما يُحفَظ من 0017 مهما تغير التصميم: التحقق الخادمي للسعر/الكمية، إلزام `unit_price=0` للبونص، `bonus_rule_id`، الاختيار الحتمي، إغلاق الإدخال المباشر، RPC التوزيع — كلها صالحة تحت أي ledger لاحق.
- 0016 مقابل 0017: لا تداخل — 0016 = خصم فيزيائي عند التخصيص + فاتورة المدفوع (حي)؛ 0017 = تحقق الإنشاء + عمود التتبع + تحليلات. منطق 0016 يبقى. الحاجة لاحقًا: migration جديدة (0018+‎) للـledger والسحب — **لا تُنشأ الآن**.

### 7. خطة Schema مقترحة (بلا SQL، بدائل عند الحاجة)
- `bonus_ledger` (id/user_id/type EARN|REDEEM_PRODUCT|ORDER_DISCOUNT|CASH_WITHDRAWAL|REFUND|REVERSAL|ADJUSTMENT|EXPIRATION/amount/balance_after/ref/order_id/rule_id/created_by/created_at + فهرس user/time + RLS ذاتي/مدير + RPC `earn_bonus`/`redeem_*` security-definer + منع Double-spend بقيد رصيد غير سالب ومعاملة ذرية).
- `bonus_withdrawal_requests` (الحالات PENDING→UNDER_REVIEW→APPROVED→PAID→COMPLETED / REJECTED + الحدود min/max/monthly + payment_method/reference/notes + audit).
- توسيع `bonus_rules` (نوع/قيمة/نسبة/حدود/استخدامات) أو جدول قواعد v2 — **DECISION REQUIRED**: توسيع مقابل v2 نظيفة.
- ربط ledger بسطور الطلبات الحالية عبر `bonus_rule_id` (الجسر المحفوظ من 0017).

### 8. القرار التحليلي: **C**
**0017 تعالج جزءًا محددًا (سلامة طلب Buy X → Free Y) ويجب الاحتفاظ بمنطقها، بينما نظام Bonus المالي يحتاج migration لاحقة** — لأن كل ما تفعله صحيح وضروري تحت أي تصميم، ولا شيء فيها يعيق الـledger (لا أعمدة متعارضة، لا سياسات مهدومة بلا بديل).

### 9. إجابات المطلوب (بلا طلب تنفيذ)
- 0017 سليمة لما صُممت له؛ تغطي §4-جزئيًا/§8/§9-آليًا ولا تغطي المالية الجديدة إطلاقًا.
- يُحفَظ: التحقق الخادمي + قيد السعر + التتبع + الحتمية + إغلاق الإدخال + التوزيع.
- ينقص: ledger/أرصدة/سحب/خصومات/قواعد مرنة/dashboards.
- قراراتك قبل Migration التالية: (1) معنى `NULL` رسميًا، (2) إشعارات دورة القاعدة، (3) توسيع القواعد أم v2، (4) حدود/موافقات السحب النقدي، (5) هل البونص الحالي يُرحَّل كأرصدة افتتاحية أم يبقى تاريخ طلبات فقط.
- **تصريح صريح: صفر تغيير نُفذ على قاعدة البيانات أو الملفات في هذه المهمة (تحليل فقط).**

## BONUS SYSTEM — CONFIGURABLE ARCHITECTURE v2 (2026-09-19 — تحليل/تصميم فقط)
> مبدأ حاكم جديد: Business Policy = بيانات/إعدادات يديرها المدير العام من Web/Admin — لا قيم مدفونة في الكود. ما سُجل سابقًا DECISION REQUIRED للسياسات التشغيلية أُعيد تصنيفه CONFIGURABLE. لا حذف للأدلة السابقة أعلاه. صفر تغيير منفذ.

### v2.1 إعادة تصنيف الفجوات (بدل DECISION REQUIRED للسياسات)
| المتطلب | 0017 | التصميم المستهدف | التصنيف |
|---|---|---|---|
| معنى البونص/NULL | ضمني (عام) | حقل `rule_type` صريح (PRODUCT/MONETARY/GENERAL) + `redemption_methods[]` | CONFIGURABLE (الأنواع) + ARCHITECTURE REQUIRED (الحقل) |
| طرق الاستخدام (منتج/خصم/نقدي) | غير موجودة | `bonus_settings` مفاتيح إيقاف + قواعد لكل طريقة | CONFIGURABLE |
| حدود/موافقات/صلاحية السحب | غير موجودة | `withdrawal_policy` (min/max/monthly/%/methods/receipt/notes/approval) قابلة للتحرير | CONFIGURABLE |
| الإشعارات (10 أحداث) | الإنشاء فقط | `notification_preferences` لكل حدث on/off | CONFIGURABLE |
| الأهلية (عميل/نوع/محافظة) | محافظة فقط | حقول أهلية موسعة + `eligible_*` | CONFIGURABLE |
| منع تعديل الرصيد/الصرف المزدوج/سعر البونص/سلامة المعاملات/RLS/عدم حذف الـledger | جزئي (سعر/كمية داخل الطلب) | قيود DB + RPCs ذرية + RLS — لا يملك المدير تجاوزها | SECURITY INVARIANT |
| ترحيل الأرصدة القائمة مقابل رصيد افتتاحي | — | تصميم يدعم الخيارين مع توثيق/تدقيق | BUSINESS INPUT REQUIRED (الاختيار نفسه) + ARCHITECTURE REQUIRED (الآلية) |

### v2.2 النتائج A–L (مختصرة)
- **A (يُحفَظ من 0017)**: التحقق الخادمي + قيد السعر + `bonus_rule_id` + الحتمية + إغلاق الإدخال + التوزيع — طبقة سلامة دائمة.
- **B (يحتاجه المالي)**: ledger بأنواعه الثمانية + أرصدة (Available/Reserved/Used) + سحب بدورة حياة + خصومات + قواعد مرنة + إشعارات قابلة للضبط + audit.
- **C (جداول)**: `bonus_ledger` (user/type/amount/balance_after/status/source/order/rule/actor/reference/created_at)؛ `bonus_withdrawal_requests` (الحالات الست + حدود/دفع/إيصال/ملاحظات/actor/reason)؛ `bonus_redemptions` (منتج/خصم)؛ `bonus_settings` (مفاتيح key/value + updated_by/at)؛ `bonus_rules` موسعة أو `bonus_rules_v2`؛ `bonus_audit_trail` (actor/time/old/new/reason/reference).
- **D (RPCs)**: `earn_bonus` / `redeem_product` / `apply_order_discount` / `request_withdrawal` / `review_withdrawal` / `record_withdrawal_payment` / `reverse_bonus_txn` / `expire_bonus` — كلها security-definer ذرية مع فحص الأهلية والحدود من الإعدادات الحية.
- **E (إعدادات المدير)**: تفعيل الطرق الثلاث + حدود السحب + الموافقات + الصلاحية + 10 أحداث إشعارات + الأهلية — كلها key/value أو صفوف سياسة قابلة للتحرير من Web/Admin.
- **F (Configurable)**: الحدود/النسب/الطرق/الموافقات/الإشعارات/الأهلية/الصلاحية/قيم القواعد.
- **G (Security Invariant)**: لا تعديل رصيد مباشر؛ لا صرف مزدوج؛ سعر بونص صفري؛ ذرية مالية؛ RLS؛ لا حذف تاريخ — محمية DB/RPC بلا تجاوز إداري.
- **H (Web/Admin)**: Dashboard (9 مؤشرات) + Rules CRUD/archive + Withdrawal Management + Settings — كما في المواصفة.
- **I (Customer)**: رصيد/تاريخ/استرداد/سحب مشروط/خصم مشروط — قراءة وطلبات فقط.
- **J (لا Double-spending)**: ledger مصدر الحقيقة + حجز Reserved ذري عند الطلب + قيد رصيد غير سالب + فحص حد الصرف داخل المعاملة.
- **K (Audit)**: ledger إلحاقي + compensating entries + `bonus_audit_trail` (old/new/actor/reason) — لا حذف.
- **L (التوسع)**: حقول اختيارية + `rule_type` + مصفوفات طرق/منتجات + settings مفتوحة المفاتيح — سياسة الغد تُفعَّل من اللوحة بلا إعادة بناء.

### v2.3 استراتيجية الترحيل (بلا SQL الآن)
- تُبقى `0017` كما هي (طبقة سلامة). لاحقًا: migration واحدة أو مجزأة للـledger/السحب/الإعدادات/القواعد/audit + RPCs + RLS + فهارس — تُكتب بعد مراجعتك لهذا التصميم.
- **تصريح: تحليل فقط — لا SQL نُفذ، لا ملفات تطبيق/ترحيل أُنشئت أو عُدلت، لا قاعدة بيانات مُست.**

## BONUS TRANSITION — تثبيت متطلب الانتقال (2026-09-20 — VERIFY/ANALYSIS ONLY)
> المعتمد: LEGACY_MIGRATION + OPENING_BALANCE معًا على مستوى العميل (لا قرار شامل)؛ الجديد يبدأ 0؛ لا تحويل تلقائي لوحدات Free Y دون قاعدة صريحة؛ كل رصيد ابتدائي عبر ledger لا تعديل مباشر. ZERO تغيير منفذ.

### أدلة حية جديدة (counts فقط، بلا محتوى)
- `bonus_rules`: 0 صفوف حيًا (LIVE VERIFIED عبر table-stats؛ العد المباشر انتهت مهلته transient مرتين — مسجل).
- `order_items`: سطران، 0 بونص؛ `bonus_rule_id` غائب (خطأ 42703 مؤكد) → لا ربط تاريخي ممكن.
- `notifications`: 6 صفوف، 0 إشارة بونص. `invoices`: 0. `users`: بلا أي عمود رصيد بونص (المخطط مؤكد سابقًا).
- سياسات حية إضافية: `director_manage_bonus_rules` (ALL) على bonus_rules — **غير موجودة في أي migration** (يدوية كـAllow-all)؛ `order_items_insert` ما زالت حية (0017 غير مطبقة — متسق).

### A) موجود فعليًا الآن
جدول قواعد فارغ + علم `is_bonus` + تدفق طلبات + تخصيص 0016 حي + بنية إشعارات + أعمدة ذمم (`credit_limit/current_balance` — ذمم لا بونص). لا أرصدة، لا ledger، لا سحب.

### B) ما يمكن ترحيله بأمان
**لا شيء محسوب**: صفر قواعد وصفر سطور بونص تاريخية → لا أساس بياناتي لأي ترحيل آلي. فقط مبالغ يدوية معتمدة لكل عميل.

### C) ما يحتاج اعتمادًا يدويًا
أي مبلغ legacy (لا مصدر)، وأي تحويل لوحدات مجانية (مستحيل حسابيًا: سعرها 0 مخزن، وممنوع صراحة دون قاعدة).

### D) فجوات التصميم المالي
ledger/الأرصدة/السحب/القواعد المرنة/الإشعارات القابلة للضبط/audit/dashboards + RLS/RPCs الخاصة بها.

### E) تصميم الانتقال (per-account)
- `bonus_accounts(user_id PK, mode: NONE|LEGACY_MIGRATION|OPENING_BALANCE, opened_at, opened_by, note)` — الجديد بلا صف أو NONE=0.
- كل رصيد ابتدائي = صف ledger (`LEGACY_MIGRATION` بمرجع الاعتماد، أو `OPENING_BALANCE` بمرجع السياسة) — لا تعديل مباشر أبدًا.
- الإعدادات العامة (`bonus_settings`) للافتراضيات فقط، لا تفرض وضعًا شاملًا.

### F) التعايش الثلاثي
نعم — الوضع حقل لكل حساب + أنواع ledger مميزة + إعدادات افتراضية عامة؛ لا مفتاح شامل يمنع الاختلاط.

### G) محتوى Migration القادمة (قائمة بلا SQL)
ledger (+الأنواع الثمانية الموسعة بنوعي الافتتاح) + قيود (رصيد غير سالب ضمني عبر RPC) + فهارس (user/time) + RLS (ذاتي/مدير) + RPCs افتتاح مقيدة للمدير + `bonus_accounts` + `bonus_settings` الأساسية + audit. دورة السحب الكاملة قد تكون نفس الـmigration أو لاحقة — تُحسم عند كتابتها.

### H) مخاطر/تعارض مع 0016/0017
لا تعارض بنيوي (طبقات متوازية). نقطة تماس مستقبلية واحدة مسجلة: خصم الطلبات (ORDER_DISCOUNT) سيحتاج توسيع `create_order_with_items` لاحقًا — لا يمنع شيئًا اليوم.

## BONUS FINANCIAL SYSTEM — MIGRATION 0018 DESIGN (2026-09-20 — DESIGN ONLY، بلا SQL/تنفيذ)
> ترتيب الترقيم مؤكد: الجذر ينتهي `0017`، الويب `0016`، المحلي `0012` — لا `0018` في أي مسار. الأدلة الحية المعتمدة أعلاه (أرصدة صفرية، لا ledger، لا سحب، `0017` غائبة) لا يُفترض عكسها.

### A. Executive Summary
طبقة مالية موازية (لا تمس Buy X → Free Y): حساب لكل عميل بثلاثة أوضاع (ZERO/OPENING_BALANCE/LEGACY_MIGRATION) + ledger إلحاقي (10 أنواع) + سحب بدورة حياة + قواعد v2 صريحة النوع + كل السياسات CONFIGURABLE من اللوحة + ثوابت أمنية DB-level.

### B. Current Live Evidence (مثبت أعلاه)
أرصدة صفرية، لا ledger/سحب، `0017` غائبة، سياسة يدوية إضافية محفوظة (لا حذف)، `0016` فعالة.

### C. Target Architecture
`bonus_accounts` ← `bonus_ledger` (مصدر الحقيقة) ← طلبات (redemption/discount/withdrawal) ← `bonus_settings` + `bonus_rules_v2` (سياسات) ← `bonus_audit_trail` (كل حساس). `0016/0017` تبقيان طبقة سلامة الطلبات الفيزيائية.

### D. bonus_accounts
`user_id PK→users`، `mode (NONE|OPENING_BALANCE|LEGACY_MIGRATION)`، `status (active|suspended)`، `currency (default YER)`، `opened_at/opened_by/note`، `created_at/updated_at`. **لا أعمدة رصيد mutable** — الرصيد = `SUM(ledger.amount)` دائمًا عبر view (`available/reserved/used/earned/expired`). مصدر الحقيقة: الـledger.

### E. bonus_ledger
`(id, account→bonus_accounts, type[10 + OPENING_BALANCE + LEGACY_MIGRATION], signed amount, status[POSTED|PENDING|REVERSED], order_id?, withdrawal_id?, redemption_id?, rule_id?, actor, reference, notes, created_at)` + فهرس (account,time). منع الحذف: REVOKE DELETE + trigger يمنع UPDATE بعد POSTED (نمط `0008W` المالي) + التصحيح عبر REVERSAL/ADJUSTMENT فقط. الرصيد يُشتق: Available = مجموع POSTED − المحجوز؛ Reserved = مجموع PENDING المرتبطة بطلبات مفتوحة؛ Used = مستهلك/مسحوب/منتهي.

### F. bonus_rules v2
`bonus_rules` الحالية تبقى لـBuy X → Free Y (لا كسر). الجديد `bonus_rules_v2`: (name/description/type[PRODUCT|MONETARY|GENERAL]/status/dates/min_order/min_qty/value/percent/max_earn/eligible_customers/customer_type/governorate/products_include+exclude/stackable/usage_limits/expiry/allow_product/allow_discount/allow_cash/cash_min/max/monthly/approval/priority) — تُستخدم تدريجيًا، والقديمة تعمل بالتوازي.

### G. Redemption
`bonus_redemptions(id, account, product_id, qty, bonus_value, status[PENDING|APPROVED|REJECTED|FULFILLED|CANCELLED], ledger_link, actor, times, reason)` — الإنشاء يحجز Reserved ذريًا (فحص Available داخل المعاملة + قفل صف الحساب)؛ الرفض/الإلغاء يحرر الحجز (compensating)؛ التنفيذ يستهلك (Used)؛ السعر يُؤخذ من الكتالوج خادميًا لا من العميل.

### H. Withdrawal
`bonus_withdrawals(id, account, amount, status[PENDING|UNDER_REVIEW|APPROVED|REJECTED|PAID|COMPLETED], requested/reviewed/approved/paid actors+times, method/reference/receipt/notes/reject_reason, ledger_link)` — الحجز عند الطلب؛ الدفع يسجل reference؛ الرفض يحرر؛ PAID→COMPLETED بعد المطابقة. السياسة من `withdrawal_policy` (enabled/min/max/monthly/%/methods/approval/notes) — كلها CONFIGURABLE بلا أرقام ثابتة هنا.

### I. Order Discount
لا تعديل `create_order_with_items` في 0018 (تبقى كما هي — مبدأ عدم الكسر + `0017` غير مطبقة حيًا أصلًا). التصميم: العميل يرسل `bonus_discount` المطلوب؛ RPC لاحقة (0019+‎) تتحقق (Available − المحجوز، الخصم ≤ الإجمالي، الإجمالي لا يسالب)، تحجز، تربط ledger، وعند الإلغاء/الrefund تحرر/تعكس. يُفصل تمامًا عن سطور Free Y الفيزيائية.

### J. Settings
`bonus_settings(key PK, value jsonb, updated_by/at)`: طرق الاستخدام الثلاث on/off، السحب، الخصم، الصلاحية، الإشعارات لكل حدث، الموافقات، الحدود، الأهلية، العملة. Global هنا؛ وper-rule في `bonus_rules_v2` تتجاوزها عند التعارض (الأضيق يفوز — قاعدة موثقة).

### K. Audit
`bonus_audit_trail(id, entity, entity_id, action, actor, at, old_value, new_value, reason, reference)` يغطي: قواعد (إنشاء/تعديل/تفعيل/أرشفة)، إعدادات، افتتاحي/مرحّل، تسويات، موافقات/رفض، مدفوعات، استردادات، عكسيات — إلحاقي فقط.

### L. RPCs (تصميم بلا SQL)
`open_bonus_account` / `post_opening_balance` / `post_legacy_migration` (مدير فقط، بمرجع وسبب) / `earn_bonus` / `redeem_product_{request,approve,fulfill,cancel}` / `apply_order_discount` (لاحقة مع توسيع create_order) / `request/review/approve/reject/mark_paid/complete_withdrawal` / `reverse_bonus_txn` / `expire_bonus` — كلها: دخل مُدقق، خرج id، صلاحية دور، حدود معاملة واحدة، قفل `FOR UPDATE` على الحساب، فحص RLS، فشل = exception بلا أثر جزئي، أثر ledger ذري.

### M. RLS
العميل: قراءة حسابه/ledger/طلباته فقط + إنشاء طلباته فقط (لا INSERT مباشر في ledger، لا اعتماد ذاتي). المدير: إدارة القواعد/الإعدادات/المراجعات/الافتتاحي حسب الدور. السياسة اليدوية `director_manage_bonus_rules` تُحفَظ كما هي (لا حذف بلا سبب موثق). الأدوار الموجودة فقط (client/branch_manager/driver/company_director) — لا أدوار مخترعة؛ accountant بلا مسار (مسجل سابقًا).

### N. Notifications
الأحداث العشرة + إعداد `per-event on/off` (global، وper-rule عند الحاجة) — لا إرسال إلا للمفعّل.

### O. Analytics
Views مشتقة (لا جداول): أرصدة العملاء، إجماليات الإصدار/الاسترداد/الخصومات/السحب، المعلقة/المرفوضة، المنتهية، أداء القواعد، حسب المحافظة/المنتج حيث تسمح البيانات. UI لاحقًا — هذه المرحلة DB/backend.

### P. Security Invariants (11 + 1)
الـ11 المطلوبة كما هي (سالب/صرف مزدوج/حذف/إنشاء مباشر/اعتماد ذاتي/حدود/تعديل بعد اعتماد/محجوز/سعر صفري/ذرية/سباقات) + (12) لا افتتاح/ترحيل بلا مرجع وسبب ومعتمد.

### Q. التوافق 0016/0017
يبقى كلاهما بلا مساس؛ المالي طبقة موازية؛ التماس الوحيد توسيع create_order للخصم (0019+‎)؛ لا كسر لإنشاء الطلب الحالي؛ لا افتراض تطبيق 0017 حيًا.

### R. نطاق 0018 (يدخل)
ledger + accounts + rules_v2 + redemptions + withdrawals + settings + audit + RLS + RPCs الافتتاح/الكسب/السحب + فهارس + قيود. **يؤجل**: توسيع create_order (لاحقة)، dashboards UI، ترحيل بيانات (لا شيء)، ربط Free Y بقيم مالية.

### S-U. مخاطر/أسئلة
المخاطر: سياسات يدوية حية خارج الملفات (Allow-all + director_manage_bonus_rules) قد تتعارض مع RLS الجديدة — تُراجع قبل التطبيق لا الآن. لا BUSINESS INPUT REQUIRED جديد: كل السياسات CONFIGURABLE؛ الوحيد البشري المؤجل: اختيار الترحيل مقابل الافتتاحي لكل عميل (بيد المدير وقت التنفيذ).

### إجابات 1-6
1. التصميم مكتمل (A–U) بلا SQL. 2. الجداول: accounts/ledger/rules_v2/redemptions/withdrawals/settings/audit. 3. الـRPCs: §L (14 عملية). 4. لـ0019+: توسيع الخصم + dashboards + أي ترحيل معتمد. 5. صفر خطر على الحالي (لا كسر، لا افتراضات حية، سياسات يدوية محفوظة). ### إجابات 1-6
1. التصميم مكتمل (A–U) بلا SQL. 2. الجداول: accounts/ledger/rules_v2/redemptions/withdrawals/settings/audit. 3. الـRPCs: §L (14 عملية). 4. لـ0019+: توسيع الخصم + dashboards + أي ترحيل معتمد. 5. صفر خطر على الحالي (لا كسر، لا افتراضات حية، سياسات يدوية محفوظة). ### إجابات 1-6
1. التصميم مكتمل (A–U) بلا SQL. 2. الجداول: accounts/ledger/rules_v2/redemptions/withdrawals/settings/audit. 3. الـRPCs: §L (14 عملية). 4. لـ0019+: توسيع الخصم + dashboards + أي ترحيل معتمد. 5. صفر خطر على الحالي (لا كسر، لا افتراضات حية، سياسات يدوية محفوظة). 6. مراجعتك المطلوبة: الجداول/RPCs/الحدود القابلة للضبط + تأكيد عدم كتابة SQL بعد.

## Migration 0018 — Final Integrity Fix (2026-09-20 — STATIC فقط)
> الملف 1304 أسطر بعد الإصلاح. **LIVE DB CHANGED: NO. SQL EXECUTED ON SUPABASE: NO.**

### T1 (FK مقابل حذف PENDING): PASS بلا تعديل
الاتجاه المفترض معكوس: FKs على `ledger.withdrawal_id/redemption_id` (التابع) — حذف صف ledger لا يمس الأب أبدًا. الإلغاء/الرفض يحذفان PENDING فقط (الـtrigger يسمح) وصف الطلب يبقى. RESTRICT محفوظ عمدًا: الآباء لا تُحذف أصلًا بأي RPC، وSET NULL كان سيُيتم التاريخ، وCASCADE مرفوض. الاتجاه العكسي (`request.ledger_id` → SET NULL) صحيح ويسمح بالتحرير.

### T2 (الانتهاء): FIXED واحد + DOCUMENTED
- التعارض المؤكد: سقف `least(amount, available)` على مستوى الحساب قد يُنسب لقديم أكثر من بقاياه الفعلية (لا traceability لكل EARN في النظام — مثبت من غياب أي رابط توزيع).
- الإصلاح: إبقاء السقف (يمنع السالب دائمًا) + ربط reverses_id + حارس NOT EXISTS + `ON CONFLICT DO NOTHING` بمطابق الفهرس + عدّ فعلي عبر row_count (أُزيل العد المزدوج). التزامن: تخطٍ رشيق بدل إجهاض.
- Limitation موثقة: النسبة لكل EARN بلا تتبع دقيق — لم يُخترع FIFO (ممنوع)؛ الإجمالي آمن دائمًا.

### T3 (عكس العكسي/التفاعلات): DOCUMENTED بلا تعديل
- A/B/C مغلقة (حراس + فهرس). D (عكس EXPIRATION): **مسموح تقنيًا** — يعيد التوازن بعكس محدود السلسلة (REVERSAL لا يُعكس، والانتهاء لا يتكرر) — تصحيح مشروع لخطأ انتهاء، بلا chain. الفهرس غير موسع (يطابق الحالات غير المقصودة فقط).

### Cross-check (A–O تحليليًا)
A/B/C الإلغاء-الرفض يحرران PENDING والطلب يبقى CANCELLED/REJECTED. D كامل. E/F مرفوض الدفع (حراس). G/H idempotency تُرجع الموجود. I/J/K مرفوض/متخطى بأمان. L/M ممنوع/مسموح مضبوط. N السقف يمنع السالب. O الإجمالي محدود بالمتاح (النسبة التفصيلية limitation أعلاه).

### Objects النهائية
جداول 7، RPCs 16، سياسات 14، trigger تجميد 1، فهارس 6 (منها unique جزئي)، FKs (rule/withdrawal/redemption/links). 0016/0017/Tطبيق untouched. الخصم مؤجل.

## Migration 0018 — Targeted Financial Integrity Review (2026-09-20 — STATIC فقط)
> الملف: `supabase/migrations/0018_bonus_financial_system.sql` (1298 سطرًا بعد المراجعة). قُرئ كاملًا + Skills ذات الصلة. 0016/0017 للتوافق فقط. **NO LIVE DATABASE CHANGES WERE EXECUTED.**

### Findings (1–8)
- Review 1 (expire مزدوج + تجاوز المتاح): **FIXED** — ربط EXPIRATION بالأصل (`reverses_id`) + حارس NOT EXISTS + سقف بالمتاح الجاري + فهرس unique جزئي كحد خلفي. السبب: الإصدار السابق كان يعيد إنقاص نفس EARN ويتجاوز المتاح.
- Review 2 (عكس مزدوج/عكس العكسي): **FIXED** — حارس رفض REVERSAL-الأصل + حارس وجود عكس فعال + نفس الفهرس + معامل idempotency اختياري (تغيير توقيع مبرر ماليًا). السبب: تكرار −100 ممكن سابقًا.
- Review 3 (mode التاريخي): **FIXED** — حراس رفض إعادة التصنيف الصامتة في open/post_* (NONE→أول وضع فقط). السبب: upsert كان يبتلع OPENING→LEGACY مع إضافة رصيد جديد. مسار إعادة صريح لاحقًا (موثق).
- Review 4 (FKs): **FIXED** — FKs متأخرة لـwithdrawal_id/redemption_id (RESTRICT، بعد §5 — نُقلت من موضع كان سيفشل) + الفهرس الجزئي. علاقة ledger_id الثنائية عبر RPCs (موثقة).
- Review 5 (snapshot السعر): **FIXED جزئيًا تقنيًا** — قفل `FOR UPDATE` على صف المنتج + القيمة مخزنة لا تُعاد حسابها أبدًا. PASS للثبات، والسباق مغلق.
- Review 6 (earn posting): **PASS + DOCUMENTED** — posting يدوي مقيد (حساب نشط + FK rule تلقائي)؛ ليست engine؛ max_earn/percent/usage DEFERRED/CONFIGURABLE.
- Review 7 (settings/expiry): **PASS** — الافتراضات معطلة آمنة؛ الغياب = توقف صريح؛ لا قيم تجارية ثابتة.
- Review 8 (دورة السحب): **FIXED** — أُضيفت `cancel_withdrawal` (CANCELLED بلا مسار سابقًا) → **16 RPC + helper = 17 دالة** (انحراف موثق). كل الحراس الطرفية سليمة (لا دفع لمرفوض/غير معتمد، لا إكمال لغير مدفوع، لا إعادة).

### Cross-check (14 بندًا)
definer+search_path شامل (عدا trigger التجميد بلا مراجع — آمن)؛ auth/roles/ownership داخل كل RPC؛ أقفال صفوف؛ idempotency على المنشئات الست + العكس؛ RLS بلا كتابة مباشرة؛ ledger إلحاقي؛ audit شامل؛ A–F: القفل الذري يغلقها جميعًا (موثق تحليليًا).

### Final objects
جداول 7، RPCs 16، سياسات 14، trigger تجميد 1، فهارس 5 (منها unique جزئي)، قيود CHECK/UNIQUE/FK كاملة. 0016/0017 untouched. الخصم مؤجل.

### Static verification performed
توازن `$$`/BEGIN-END؛ grants تحل نوعيًا 17/17؛ بلا إدخالات محظورة؛ بلا مراجع معلقة؛ ترتيب FKs صحيح بعد النقل. Parser حقيقي (pg_query) غير متاح محليًا — مسجل كحد.

## BONUS FINANCIAL SYSTEM — MIGRATION 0018 WRITTEN (2026-09-20 — كتابة فقط، بلا تنفيذ)
> الملف: `supabase/migrations/0018_bonus_financial_system.sql` (1154 سطرًا). كُتب بموافقتك الصريحة؛ **لم يُنفذ على أي قاعدة** (لا push/up/dashboard/CLI).

1. اسم الملف النهائي: `supabase/migrations/0018_bonus_financial_system.sql` (الترقيم مؤكد: لا 0018 سابقًا؛ تعارض أسماء صفر في المستودع).
2. عدد الأسطر: 1154. 3. الجداول (7): accounts/ledger/rules_v2/redemptions/withdrawals/settings/audit_trail. 4. Enums: نصوص + CHECK (لا enum types — تجنب قفل ALTER مستقبلي). 5. Constraints: أوضاع/حالات/مبالغ موجبة/نسب 0-100/ quantities>0 / UNIQUE(idempotency) / FKs (rule عبر ALTER لاحق لترتيب الملف). 6. Indexes: (account,time) + (account,status) + audit(entity). 7. Triggers: تجميد POSTED فقط (PENDING تديره RPCs). 8. RLS/policies: 14 (2/جدول: قراءة ذاتية + إدارة)؛ صفر كتابة مباشرة لأحد. 9. RPCs (15: الـ14 + start_withdrawal_review الضرورية لدورة UNDER_REVIEW — انحراف موثق). 10. Invariants: الـ12+1 كلها DB-level. 11. Idempotency: مفتاح UNIQUE + إرجاع الموجود في 6 RPCs إنشائية. 12. Concurrency: قفل صف الحساب + حراس الحالات + فحص ذري. 13. Dependencies: users/products/orders/branches/addresses فقط (موجودة حيًا)؛ لا اعتماد على 0017 بتاتًا. 14. Deferred: توسيع الخصم/سطور الاسترداد/UI/الترحيل الفعلي. 15. Static verification: أزواج $$ سليمة؛ BEGIN/END 17/17؛ grants تنفيذية فقط (16/16)؛ بلا إدخالات محظورة؛ بلا مراجع معلقة؛ كل الدوال definer+search_path (عدا trigger التجميد الذي لا يلزم). أُصلح أثناء المراجعة: خصوصية funds + ترتيب FK + قابلية UNDER_REVIEW + سقوف شهرية/نسبية + استعادة idempotency السحب. 16. **تصريح: SQL لم يُنفذ Live — القاعدة الحية لم تتغير (يُتحقق بـtable-stats لاحقًا عند التنفيذ اليدوي).**

### تحذيرات
- W1: `open_*`/`post_*`/`earn` تمنح المدير قوة إصدار — مقصودة ومقيدة بالدور + audit + مرجع إلزامي.
- W2: `expire_bonus` يتطلب `expiry_policy` مهيأة وإلا رفض صريح — لا انتهاء صامت.
- W3: seed الإعدادات محافظ (الكل معطل) — التفعيل قرار مدير لاحق.
- W4: `director_manage_bonus_rules` اليدوية محفوظة ولم تُستنسخ — أي توحيد لاحق يحتاج توثيق سبب.

## BONUS FINANCIAL SYSTEM — FINAL DESIGN REVIEW (2026-09-20 — REVIEW ONLY، بلا SQL/تنفيذ)
> يراجع تصميم v2 أعلاه سطرًا سطرًا. القاعدة: PASS/GAP/CONFLICT/NEEDS REVISION/DEFERRED. لا SQL كُتب أو نُفذ.

### A. Seven Tables Review
**T1 bonus_accounts** — حساب واحد لكل عميل. PK user_id→users(id) ON DELETE RESTRICT (منع يتيم مالي؛ التعطيل عبر status لا الحذف). الأعمدة: mode(text: NONE|OPENING_BALANCE|LEGACY_MIGRATION, NOT NULL, default NONE)؛ status(active|suspended, default active)؛ currency(text default YER)؛ opened_at/at: opened_by→users nullable, note text nullable؛ created_at/updated_at default now(). UNIQUE(user_id) ضمني من PK → يستحيل حسابان لنفس العميل (سؤال 2 مجاب). لا أعمدة رصيد إطلاقًا (لا divergence ممكنًا؛ لا cached — الأداء عبر view + فهرس ledger، فإن لزم cache لاحقًا يُعاد حسابه من الـledger بمهمة تحقق دورية — موثق كخطة لا كحقل). RLS: العميل SELECT لصفه؛ الإدخال/التعديل مدير فقط عبر RPC (لا INSERT مباشر للعميل). DELETE ممنوع للجميع (REVOKE + سياسات بلا DELETE). append-only فعليًا (تعديل status/mode بإجراء مدقق فقط). concurrency: قفل `FOR UPDATE` على صف الحساب في كل RPC مالي. تعارض مع الحالي: لا شيء (جدول جديد كليًا).

**T2 bonus_ledger** — السجل المالي. PK id uuid؛ account→accounts ON DELETE RESTRICT؛ type (10 أنواع + OPENING_BALANCE + LEGACY_MIGRATION) CHECK؛ amount signed numeric (موجب دائن/سالب مدين — direction ضمن الإشارة، موثق)؛ status(POSTED|PENDING|REVERSED, default POSTED)؛ order_id?/withdrawal_id?/redemption_id?/rule_id? (FKs nullable)؛ actor→users NOT NULL؛ reference text nullable؛ notes nullable؛ created_at default now(). UNIQUE لمنع التكرار: (reference) حيث non-null؟ — الأفضل idempotency_key text UNIQUE nullable لكل RPC (يعالج Scenario D على مستوى DB). RLS: العميل SELECT لصفوفه؛ لا INSERT/UPDATE/DELETE لأي عميل (الكتابة RPC security-definer فقط)؛ المدير SELECT الكل + لا كتابة مباشرة (عبر RPC). DELETE ممنوع (REVOKE) + trigger يمنع UPDATE بعد POSTED (نمط 0008W) → append-only مثبت. مالي حساس: نعم. تلاعب: مستحيل عبر RLS+trigger+الإشارة الموقعة. concurrency: كل إدخال داخل معاملة RPC مع قفل الحساب. triggers: واحد لمنع التعديل (+ ربما updated؟ لا updated أصلًا — جيد). تعارض: لا شيء.

**T3 bonus_rules_v2** — بجانب القديم (لا كسر — القديم يبقى لـBuy X→Free Y). الأعمدة: name/description، rule_type(PRODUCT|MONETARY|GENERAL) NOT NULL صريح (لا NULL ضمني)، status، dates، min_order/min_qty/value/percent/max_earn، eligible_customers(jsonb)/customer_type/governorate، products_include/exclude (uuid[])، stackable/priority/usage_limits/expiry، allow_product/allow_discount/allow_cash + cash_min/max/monthly/approval. RLS: قراءة النشطة للعميل + إدارة مدير (مطابق نمط القديم). سياسة `director_manage_bonus_rules` اليدوية تخص الجدول القديم — تُحفَظ ولا تُستنسخ إلا بتوثيق (القرار: v2 بسياسات جديدة مسماة صراحة، والقديمة تُترك).

**T4 bonus_redemptions** — طلب واحد = منتج واحد (product_id NOT NULL, qty>0 CHECK) — قرار تصميم صريح: multi-product عبر طلبات متعددة؛ جدول سطور منفصل **مؤجل** (DEFERRED) لعدم الحاجة الآن. الحالات: PENDING|APPROVED|REJECTED|FULFILLED|CANCELLED + reservation (PENDING link) + consumption عند FULFILLED + actor/times/reason + ledger_link. يمنع: تجاوز الرصيد (فحص ذري)، التنفيذ المزدوج (انتقالات حالة محروسة بشرط WHERE status)، تغيير القيمة بعد الاعتماد (trigger تجميد)، التلاعب بالسعر (السعر من الكتالوج خادميًا).

**T5 bonus_withdrawals** — الحالات الست + CANCELLED إضافية (سحب الطلب قبل المراجعة — ضرورية، موثقة كإضافة). الأعمدة: account/amount>0/requested_at/reviewed_by/at/approved_by/at/paid_by/at/method/reference/receipt/notes/reject_reason/ledger_link. الحجز عند الإنشاء؛ التحرير عند REJECTED/CANCELLED؛ الاستهلاك عند PAID؛ COMPLETED بعد المطابقة. العميل لا يعتمد/يدفع/يعدل بعد PENDING (RLS + فحص RPC).

**T6 bonus_settings** — (key PK, value jsonb, updated_by/at). مفاتيح: methods(product/discount/cash) on/off؛ حدود السحب؛ الموافقات؛ الصلاحية؛ إشعارات per-event؛ الأهلية؛ العملة. GLOBAL هنا؛ per-rule في v2 تتجاوز (الأضيق يفوز). لا تكرار بلا سبب: كل سياسة في مكان واحد (per-customer تُشتق من rules/settings لا جدول ثالث).

**T7 bonus_audit_trail** — (id, entity, entity_id, action, actor, at default now(), old/new jsonb, reason, reference). إلحاقي (لا UPDATE/DELETE لأحد). يغطي الأحداث الـ11 المطلوبة.

### B. Fourteen RPC Review (مضغوطة — النمط الموحد ثم الفروق)
النمط الموحد لكل RPC مالية: SECURITY DEFINER + `auth.uid()` أولًا + فحص الدور/الملكية + قفل `FOR UPDATE` على صف الحساب + معاملة واحدة + فشل=exception بلا أثر + حدث audit + GRANT لـauthenticated فقط + لا privilege escalation (المدير لا يتجاوز invariants؛ العميل لا يكتب ledger).
1. `open_bonus_account(p_user)` مدير: إنشاء/تفعيل حساب (idempotent على user_id). 2. `post_opening_balance(p_user,amount,ref,reason)` مدير: OPENING_BALANCE + فتح الحساب إن لزم. 3. `post_legacy_migration(...)` مدير: LEGACY_MIGRATION بمرجع الاعتماد. 4. `earn_bonus` مدير/نظام: EARN مرتبط بقاعدة. 5-7. `request/approve/fulfill_redemption` (+cancel): حجز→تنفيذ/تحرير مع سعر كتالوج خادمي. 8-11. `request/review/approve|reject/mark_paid/complete_withdrawal`: الحجز عند الطلب، الدفع بمرجع، الرفض يحرر، idempotency_key يمنع التكرار (Scenario D). 12. `reverse_bonus_txn` مدير: REVERSAL مرتبط بالأصل (لا حذف). 13. `expire_bonus` نظام: EXPIRATION للمنتهي. 14. `apply_order_discount` — **DEFERRED إلى 0019+** (تحتاج توسيع create_order؛ تُصمم الآن وتُنفذ لاحقًا). العميل يستدعي مباشرة: طلبات الإنشاء/الاسترداد/السحب فقط؛ الباقي مدير/نظام. ما تمنعه DB نفسها: CHECKs + UNIQUE(idempotency) + RLS + REVOKE + trigger التجميد.

### C. Ledger Integrity — PASS
لا حذف (REVOKE) + لا تعديل بعد POSTED (trigger) + تصحيح compensating + كل حركة بسبب/فاعل/مرجع + ربط order/withdrawal/redemption/rule + idempotency. GAP وحيد: لا شيء — التصميم مغلق.

### D. Balance Model — PASS
Earned=Σموجب؛ Used=Σمستهلك/مسحوب/منتهي؛ Reserved=ΣPENDING المرتبطة بمفتوحة؛ Available=Earned−Used−Reserved (دائمًا view، لا تخزين). المعادلات لا double-count (الحجز يُستبعد من Available ويُحسم عند الاستهلاك لا قبله).

### E. Concurrency Review
- A (رصيد 100k وطلبان 80k): قفل الحساب `FOR UPDATE` يُسلسل المعاملتين؛ الثانية ترى Available=20k فتفشل — **واحدة فقط تنجح**.
- B (استرداد 60k + سحب 60k من 60k): نفس القفل + فحص ذري — **لا تنجحان معًا**.
- C (تسوية مدير أثناء سحب جارٍ): التسوية ADJUSTMENT تُسجل كحركة مستقلة ولا تعبث بالمحجوز؛ السحب يستمر على المبلغ المحجوز أصلًا — **السلوك: السماح مع العزل** (المحجوز مملوك للطلب).
- D (إعادة إرسال بعد timeout): `idempotency_key` UNIQUE → الثانية تُرجع الأصلية/تُرفض — **لا تكرار**.

### F. RLS Matrix
| Table | Customer | Director/Admin | Others |
|---|---|---|---|
| accounts/ledger/redemptions/withdrawals | SELECT own؛ INSERT طلباته فقط (redemptions/withdrawals)؛ لا UPDATE/DELETE؛ لا كتابة ledger | SELECT الكل؛ الكتابة عبر RPC فقط (لا مباشرة) | driver/branch_manager: لا شيء (يُرفض) |
| rules_v2/settings | SELECT النشط/العامة | ALL (إدارة) | — |
| audit | SELECT ما يخصه | SELECT الكل؛ لا كتابة مباشرة | — |
- لا تسريب بين العملاء (كل سياسة مقيدة `user_id=auth.uid()`)؛ المدير لا يتجاوز invariants (المحمية قيودًا لا سياسات).

### G. Security Invariants (12+1 — موضع الفرض)
1 سالب: CHECK + فحص RPC ذري. 2 صرف مزدوج: قفل + idempotency. 3 حذف: REVOKE. 4 إنشاء مباشر: RLS بلا INSERT. 5 اعتماد ذاتي: فحص `approver≠requester`. 6 حدود: CHECK + فحص سياسة حية. 7 تعديل بعد اعتماد: trigger تجميد. 8 محجوز مزدوج: Reserved مستبعد. 9 سعر صفري: CHECK (موروث من 0017 للفيزيائي). 10 ذرية: معاملة واحدة. 11 سباقات: FOR UPDATE. 12 افتتاح بلا مرجع: NOT NULL + RPC. كلها DB-level (لا GAP تطبيقي).

### H. 0016/0017 Compatibility — PASS
يبقى كلاهما؛ المالي موازٍ؛ لا تعديل create_order الآن؛ لا افتراض تطبيق 0017 (التصميم يعمل قبلها وبعدها).

### I. Migration Boundaries
في 0018: الجداول 7 + RLS + RPCs (عدا الخصم) + فهارس + قيود + triggers تجميد. لـ0019+: توسيع الخصم + UI + تحليلات عرض + أي ترحيل معتمد.

### J. Scenario Verification (18)
التصميم يدعمها جميعًا نظريًا (1-3 أوضاع الحساب، 4-12 دورات الحجز/الدفع/العكس، 13-14 القفل/idempotency، 15 RLS، 16 RPC مدير، 17-18 audit/settings) — تحقق نظري مسجل، لا تنفيذي.

### K-L. Gaps & Verdict
- GAP وحيد جوهري سابق أُغلق تصميميًا (الحجز الذري + idempotency). لا GAP أمني/مالي متبقٍ على الورق.
- DEFERRED: جدول سطور الاسترداد، توسيع الخصم، UI، الترحيل الفعلي.
- **FINAL DESIGN VERDICT: 1. READY FOR SQL** (مشروط بمراجعتك — لا SQL كُتب).
- **تصريح: DESIGN ONLY — لا SQL كُتب أو نُفذ، لا ملفات/قاعدة عُدلت.**
