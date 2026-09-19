# MedLink Yemen — خريطة قاعدة البيانات (First Run Audit)
> تدقيق قراءة فقط — 2026-09-18. لم تُنفَّذ أي migration ولم يُجرَ أي اتصال بقاعدة البيانات؛ كل ما هنا مستخرج من ملفات SQL في المستودع.

## 1. قاعدة واحدة مشتركة + ثلاثة مسارات migrations
مشروع Supabase واحد `lmkomzqioneuyvatzsov` (الدليل: `medlink_app/lib/utils/constants.dart:10`، `Medlik-Waap/supabase/config.toml:1`، `Medlik-Waap/artifacts/pharma-pwa/src/lib/supabaseClient.ts:6-8`).

ثلاثة مجلدات migrations في المستودع:
| المجلد | الملفات | الدور |
|---|---|---|
| `supabase/migrations/` (الجذر) | 0001 → 0017 | **السجل الرئيسي المشترك** (`.agents/memory/shared-migration-numbering.md` يقرّ بأن الجذر authoritative) |
| `Medlik-Waap/supabase/migrations/` | 0001 → 0017 | سجل مكمل للمدير العام/المالي — نفس القاعدة الفعلية، مع مزامنة Bonus 0016/0017 |
| `medlink_app/supabase/migrations/` | 0012 فقط | ملف محلي بتكرار رقم 0012 — محذَّر من التطبيق كما هو |

## 2. الجداول — النواة التشغيلية (الجذر)
- `0001`: `branches`، `users` (role IN client/branch_manager/company_director/driver، requires_password_change) + trigger `handle_new_user` + دوال `current_user_role()`/`current_user_branch_id()`.
- `0002`: `products`, `inventory`, `promotional_offers`, `client_addresses`, `orders` (status check يحوي pending/assigned/in_progress/delivered/cancelled)، `order_items`.
- `0003`: `bonus_rules`, `driver_commission_rules`, `driver_commissions`, `driver_ratings`, `notifications`, `notification_reads` + `users.account_status`/`terms_accepted_at`.
- `0007`: `chat_rooms`, `chat_messages`, `driver_locations`.
- `0009`: أعمدة `orders.priority`, `orders.delivered_at`, `warehouse_inventory.reorder_level`, `invoices.branch_id` + RPC `branch_allocate_order`.
- `0010`: `notification_preferences`, `branch_bank_accounts` + RPCs إعدادات/تحويل مخزون.
- `0012`: `special_requests`. `0014`: حقول عنوان موسعة. `0015`: bucket `product-images` + سياسات مدير عام.
- `0016`: إصلاح `branch_allocate_order` ليشترط تخصيص paid + bonus كاملاً، ويخصم الكمية الفيزيائية مرة واحدة، مع إصدار فاتورة للجزء المدفوع فقط. النسخة نفسها موجودة في مشروع Web/Admin.
- `0017`: `order_items.bonus_rule_id`، حماية سعر سطر bonus، RPC `create_order_with_items` للتحقق الخادمي من القاعدة/السعر/الإجمالي، وRPC `get_order_product_distribution` للتحليل. النسخة نفسها موجودة في مشروع Web/Admin.

## 3. جداول طبقة الويب (Medlik-Waap على نفس القاعدة)
- `0004_phase4`: `warehouse_inventory` (بنسخته الخاصة قبل 0009 الذي أضاف reorder_level)، `invoices`، `payments` + أعمدة `users.credit_limit/current_balance` + triggerا رصيد (`trg_invoice_increase_balance`, `trg_payment_decrease_balance`).
- `0006_financial_core`: 26 جدولاً مالياً (`financial_*` من companies إلى audit_logs) + 3 views (`financial_general_ledger`, `financial_trial_balance`, `financial_branch_profitability`).
- `0011`: `payout_documents`, `payout_line_items` + دوال رواتب الأطباء.
- `0014_product_catalog_sync`: trigger `sync_new_product_to_branches`.

## 4. الدوال (RPC) المستهلكة من الكود — مصفوفة المطابقة
| RPC | معرّف في SQL | مستهلك Flutter | مستهلك ويب |
|---|---|---|---|
| `branch_allocate_order` | 0009 | branch_service.dart | — |
| `create_order_with_items` | 0017 | order_service.dart | — |
| `get_order_product_distribution` | 0017 | order_service.dart | — |
| `branch_add_stock_batch` | 0011 | branch_service.dart | — |
| `branch_set_default_bank_account` | 0010 | branch_service.dart | — |
| `branch_transfer_stock_between_branches` | 0010 | branch_service.dart | — |
| `driver_advance_order_status` | 0006 | driver_orders_service.dart | — |
| `clear_requires_password_change` | 0005 | driver_service.dart | — |
| `create_financial_expense` / `create_financial_receipt` / `create_financial_disbursement` / `create_financial_journal_entry` / `post_financial_journal_entry` | 0010 (تعدّلها 0012) | — | ExpensesPage/JournalPage/ReceiptsPage |
| `get_doctors_payables` / `create_doctors_payouts_entries` | 0011W | — | FinancialPage |
**ملاحظة**: الرمز W = ملف Medlik-Waap. التطبيقان لا يستدعيان RPCs بعضهما.

## 5. سياسات RLS (الخلاصة)
- users: select ذاتي/مدير عام (`0001:69-70`)؛ update ذاتي مقيّد بعد `0005` (منع ترويج الدور/الحالة) — إغلاق ثغرة موثقة في ترويسة 0005.
- orders/order_items: العميل يقرأ طلباته، لكن الإنشاء أصبح عبر `create_order_with_items` فقط (0017)؛ المدير يحدّث طلبات فرعه (0002)؛ السائق select عبر `0006`.
- inventory: قراءة مصادَقة، تحديث مدير فرع، إدراج/حذف مدير عام (0002+0004).
- invoices: إدراج/تحديث مدير فرع لفرعه (0009)، select مدير فرع (0013)، بينما نسخة الويب 0004W أعطت select لأي مصادَق — انظر PROJECT_RISKS (تضارب نطاق invoices بين المستودعين).
- driver_locations: 0008 يقصّر الرؤية (مدير الفرع لسائقيه فقط، العميل أثناء `in_progress` فقط) — إصلاح موثق لثغرة 0007.
- الطبقة المالية 0007W: director+accountant؛ budgets/audit للمدير فقط.
- notifications: نسخة الجذر 0003 تُبقي `notifications_director_manage` و `notifications_select_relevant`؛ النسخة المحلية (medlink_app 0012) ونسخة الويب 0005W تضيف `target_user_ids` — **3 ملفات تتنافس على نفس السياسة**.

## 6. Auth
- Supabase Auth (email/password + Google)؛ الصفوف في public.users تُنشأ حصراً بـ trigger `handle_new_user` (`0001:26-50`)؛ الميتاداتا role/phone/branch تحمل عند التسجيل (`medlink_app/lib/services/auth_service.dart:39-60`).
- كلمات مرور السائقين المؤقتة وإجبار التغيير عبر Edge Function + `requires_password_change` (`supabase/functions/manage-driver-account/index.ts:83-104`).

## 7. ما لم يُتحقق منه (حدود التدقيق)
- لا يوجد ملف `supabase/migrations/_journal` أو جدول history في المستودع يثبت أن 0001–0014 طبّقت فعلاً على البيئة الحية؛ `replit.md:22` يذكر التطبيق عبر CLI/Dashboard. حالة 0015 المدمجة حديثاً على القاعدة الحية مجهولة. الالتزام بقاعدة «نفّذ من Dashboard → SQL Editor» موثق في ترويسات الملفات نفسها (0005:3، 0009:4).
