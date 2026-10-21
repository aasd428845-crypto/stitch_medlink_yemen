# خطة مرجعية: إعادة تصميم واجهة مدير الفرع بنفس تصميم واجهة العميل

> الحالة: **خطة فقط — لم يتم تنفيذ أي تغيير بعد.**
> النطاق: تطبيق Flutter (`medlink_app/`) فقط.
> الهدف: ضمان عدم نسيان أي صفحة أو تبويب أو بطاقة أو نافذة في واجهة مدير الفرع (`role = branch_manager`) تحتاج إلى الانتقال إلى نظام التصميم الموجود في واجهة العميل.

---

## 1. المرجع: ما الذي يُعد "التصميم الجديد" (واجهة العميل)

### 1.1 الملفات المرجعية

| المكون | الملف | الدور |
|---|---|---|
| الألوان والثيم | `lib/utils/theme.dart` (`ClientColors`, `AppTheme.clientLight`) | مصدر الألوان؛ `clientLight` مشتق من `branchManagerLight` مع تجاوز primary/surface/background |
| مكونات التصميم | `lib/screens/client/client_design.dart` | `ClientCard`, `ClientHero`, `ClientSectionTitle`, `ClientIconBadge`, `ClientSearchField`, `ClientGlassBackground`, `ClientDesignSurface`, `ClientFloatingBottomBar`, `ClientBottomBarItem` |
| الغلاف والتنقل | `lib/screens/client/client_home_shell.dart` | 4 تبويبات بـ `IndexedStack` + شريط سفلي عائم مع زر سلة في المنتصف + `_ClientBrandHeader` في الأعلى |

### 1.2 مواصفات مكونات العميل (المرجع الذي يجب مطابقته)

- **`ClientCard`**: نصف قطر 24، خلفية فاتحة، ظل خفيف بلون primary.
- **`ClientHero`**: تدرج، نصف قطر 30، للعناوين الرئيسية في الصفحة.
- **`ClientFloatingBottomBar`**: شريط عائم، تسميات تظهر فقط عند عرض ≥ 840، مؤشر متحرك للتبويب النشط، `_CountBadge` بحد أقصى "9+".
- **`ClientGlassBackground`**: خلفية موحدة للشاشات.
- **الحالات**: كل تبويب عميل يطبّق حالات التحميل والخطأ والفراغ (مثال: `orders_tab.dart` يعرض `CircularProgressIndicator`، ورسالة خطأ مع زر إعادة المحاولة، ثم حالة فراغ).

### 1.3 نقاط مراجعة قبل البدء (تم التحقق منها)

- جميع شاشات العميل (`screens/client/*.dart`) تستخدم `ClientColors` ولا تستخدم `AppColors` (الداكن القديم) مباشرة.
- شاشات العميل تستخدم `ClientCard` في معظم الأقسام (مثلاً `order_detail_screen.dart` 7 مرات، `addresses_screen.dart` 4 مرات، `product_detail_screen.dart` 4 مرات).
- الشاشات الفرعية للعميل (`bonus_*`, `addresses_screen`, `legal_screen`, `digital_card_screen`, `special_request_screen`, `offer_detail_screen`, `business_profile_screen`) تستخدم نفس النظام.
- **يجب التأكد عملياً** (بتشغيل التطبيق أو لقطات الشاشة) من أن كل شاشة عميل تعرض حالات التحميل/الخطأ/الفراغ/المعطّل بالشكل المتسق قبل اعتمادها مرجعاً نهائياً.

---

## 2. الوضع الحالي لواجهة مدير الفرع

### 2.1 الغلاف والتبويبات

ملف الغلاف: `lib/screens/branch_manager/branch_manager_home_shell.dart` (158 سطر)

| # | التبويب | الملف | الشريط السفلي |
|---|---|---|---|
| 0 | لوحة الفرع | `branch_dashboard_tab.dart` | `BranchBottomBarItem` |
| 1 | الطلبات | `branch_orders_tab.dart` | `BranchBottomBarItem` (زر FAB المركزي يفتح هذا التبويب: `_select(1)`) |
| 2 | المخزون | `branch_inventory_tab.dart` | `BranchBottomBarItem` |
| 3 | الفواتير | `branch_invoices_tab.dart` | `BranchBottomBarItem` |
| 4 | السائقون | `branch_drivers_tab.dart` | `BranchBottomBarItem` |
| 5 | المحادثات | `branch_chat_tab.dart` | `BranchBottomBarItem` |

- الشريط السفلي: `branch_floating_bottom_bar.dart` (`BranchFloatingBottomBar`, `_CentralFab`, `_BarItem`, `BranchBottomBarItem`).
- الشريط العلوي: شعار + زر إشعارات (بشارة بتدرج `glassWarmGradient`) + زر الإعدادات (`BranchSettingsSheet`).
- الخلفية: `BranchGlassBackground` مع `BackdropFilter` (زجاجي).
- عند غياب `branchId` يعرض `MissingAccountDataBody`.

### 2.2 نظام التصميم الحالي للفرع

- الألوان: `BranchColors` (لوحة Material 3 فاتحة: primary `004AC6`، خلفية `FAF8FF`، تدرجات).
- المكونات: `branch_manager_design.dart` (881 سطر): `GlassCard`, `BranchGlassBackground`, `BranchGlass`, ومقاييس بتدرجات ملونة.
- الفرق الجوهري عن العميل: زجاجي (`BackdropFilter`) مقابل بطاقات بيضاء بظل خفيف؛ وتدرجات متعددة الألوان للمقاييس مقابل `ClientHero` واحد.

### 2.3 جدول الملفات المطلوب تغييرها (تفصيل كامل)

الأعمدة: عدد الأسطر، عدد استخدامات `BranchColors` / `GlassCard` / `BranchGlass` / `ClientCard` / `ClientColors` / `AppColors` / `Card(` كما تم قياسها.

#### أ) الغلاف والتنقل والمكونات الأساسية

| الملف | أسطر | BranchColors | GlassCard | BranchGlass | ClientCard | ClientColors | مطلوب؟ |
|---|---|---|---|---|---|---|---|
| `branch_manager_home_shell.dart` | 158 | 1 | 0 | 1 | 0 | 0 | **نعم**: الخلفية، الشريط العلوي، الشارة |
| `branch_floating_bottom_bar.dart` | 273 | 9 | 0 | 0 | 0 | 0 | **نعم**: استبدال بـ `ClientFloatingBottomBar` أو نسخة مكافئة |
| `branch_manager_design.dart` | 881 | 26 | 2 | 2 | 0 | 0 | **نعم**: يُستبدل تدريجياً بمكونات العميل |

#### ب) التبويبات (الصفحات الرئيسية الستة)

| الملف | أسطر | BranchColors | GlassCard | BranchGlass | Card( | مطلوب؟ |
|---|---|---|---|---|---|---|
| `branch_dashboard_tab.dart` | 962 | 56 | 0 | 0 | 8 | **نعم** (الأكبر أثراً: الهيرو، المقاييس، الوصول السريع، البنتو، الإحصائيات، آخر الطلبات) |
| `branch_orders_tab.dart` | 295 | 13 | 0 | 0 | 1 | **نعم** |
| `branch_inventory_tab.dart` | 925 | 36 | 0 | 0 | 8 | **نعم** |
| `branch_invoices_tab.dart` | 238 | 14 | 0 | 0 | 2 | **نعم** |
| `branch_drivers_tab.dart` | 290 | 13 | 0 | 0 | 2 | **نعم** |
| `branch_chat_tab.dart` | 373 | 12 | 0 | 0 | 3 | **نعم** |

#### ج) الشاشات الفرعية والصفحات (تُفتح بالتنقل)

| الملف | أسطر | BranchColors | Card( | مطلوب؟ |
|---|---|---|---|---|
| `branch_order_detail_screen.dart` | 512 | 6 | 6 | **نعم** — ⚠️ **يحتوي تعديلات غير مُلتزَمة (uncommitted) — انظر القسم 5** |

#### د) النوافذ السفلية (Bottom Sheets)

| الملف | أسطر | BranchColors | مطلوب؟ |
|---|---|---|---|
| `branch_allocate_sheet.dart` | 652 | 34 | **نعم** (نافذة تخصيص الطلب، حالات تحميل/خطأ/فراغ) |
| `branch_invoice_create_sheet.dart` | 338 | 8 | **نعم** |
| `branch_settings_sheet.dart` | 854 | 38 | **نعم** (يحتوي حوار تأكيد) |
| `create_driver_sheet.dart` | 238 | 1 | **نعم** (يستخدم `showDialog`) |
| `manage_driver_sheet.dart` | 274 | 11 | **نعم** |

#### هـ) الحوارات (Dialogs) وأدوات الإجراءات

| الملف | الحوار | مطلوب؟ |
|---|---|---|
| `branch_order_actions.dart` (252 سطر، BranchColors 2) | `showAllocateSheet`، `showAssignDriverDialog`، `showTransferOrderDialog`، `showRejectOrderConfirm`، `_RejectOrderDialog` (AlertDialog) | **نعم**: توحيد شكل `AlertDialog` مع نمط العميل |
| `branch_order_detail_screen.dart` | تأكيد تغيير الحالة (`branchChangeStatus`)، تأكيد آخر (سطر ~491) | **نعم** |
| `branch_inventory_tab.dart` | حوارات متعددة + `showModalBottomSheet` | **نعم** |
| `branch_drivers_tab.dart` | `_create` و`_manage` عبر `showModalBottomSheet` | **نعم** |
| `branch_invoices_tab.dart` | `showInvoiceDetail` / `InvoiceStatusChip` | **نعم** |

#### و) المكونات المشتركة داخل الفرع (widgets)

| الملف | أسطر | BranchColors | Card( | مطلوب؟ |
|---|---|---|---|---|
| `lib/widgets/branch_order_card.dart` | 246 | 16 | 1 | **نعم** (بطاقة الطلب الرئيسية، `BranchOrderCard`) |
| `lib/widgets/inventory_quantity_tile.dart` | 74 | 3 | 1 | **نعم** |

#### ز) الشاشات المشتركة التي تستخدم ألوان الفرع

| الملف | الاستخدام | ملاحظة |
|---|---|---|
| `lib/screens/shared/notifications_screen.dart` | يستخدم `BranchColors` | **يُراجَع**: مشتركة بين الأدوار، لا تُغيَّر إلا بقرار (انظر القسم 4) |
| `lib/screens/shared/help_support_screen.dart` | يستخدم `BranchColors` | **يُراجَع** كما أعلاه |
| `lib/screens/shared/splash_screen.dart` | يستخدم `BranchColors` | **يُراجَع** كما أعلاه |

#### ح) المكونات المشتركة بالنظام الداكن القديم (`AppColors`)

هذه الملفات تُستخدم من شاشات الفرع والعميل معاً. لا يُعدَّل أي منها إلا بعد قرار صريح:

- `widgets/error_banner.dart`، `order_status_chip.dart`، `stat_card.dart` (يُستخدم في `branch_dashboard_tab`, `branch_orders_tab`, `branch_inventory_tab`, `branch_invoice_create_sheet`, `branch_order_detail_screen`, `branch_settings_sheet`, `create_driver_sheet`, `manage_driver_sheet`, `branch_drivers_tab`, `branch_invoices_tab`).
- `notification_tile.dart`، `offer_banner_card.dart`، `app_primary_button.dart`، `medlink_design.dart`، `cart_item_tile.dart`، `chat_message_bubble.dart`، `driver_rating_badge.dart`، `faq_tile.dart`، `rate_driver_sheet.dart`، `reorder_soon_section.dart`، `app_logo.dart`.

**خطر مُحدَّد**: هذه المكونات مصممة للخلفية الداكنة. إذا ظهرت على الخلفية الفاتحة لـ `BranchColors`/`ClientColors` فقد يصبح النص غير مقروء. يجب التحقق من ذلك بلقطة شاشة لكل استخدام في الفرع قبل أي تغيير.

---

## 3. خريطة التحويل (من مكوّن الفرع إلى مكوّن العميل)

| عنصر الفرع الحالي | المكوّن المكافئ في العميل | ملاحظة |
|---|---|---|
| `BranchGlassBackground` | `ClientGlassBackground` | استبدال الخلفية |
| `GlassCard` | `ClientCard` | استبدال البطاقة؛ الحفاظ على الحدود والظل |
| `BranchFloatingBottomBar` + `_CentralFab` | `ClientFloatingBottomBar` + `_ClientFab` | **قرار مطلوب**: الفرع لديه 6 تبويبات والعميل لديه 4 — انظر القسم 4 |
| `BranchBottomBarItem` | `ClientBottomBarItem` | |
| عنوان الصفحة/الهيرو "لوحة الفرع" | `ClientHero` | |
| عناوين الأقسام | `ClientSectionTitle` | |
| أيقونات الحالات الملونة | `ClientIconBadge` | |
| حقل البحث (في المخزون/الطلبات) | `ClientSearchField` | |
| `BranchOrderCard` | بطاقة طلب مطابقة لـ `ClientCard` (العميل يعرض الطلبات في `orders_tab.dart`) | |
| `InvoiceStatusChip`, `OrderStatusChip` | الشكل الموحد المستخدم في شاشات العميل | يحتاج تحقق من الألوان |
| شارة الإشعارات بتدرج `glassWarmGradient` | شارة العميل `_CountBadge` (حد 9+) | |
| `MissingAccountDataBody` | حالة "بيانات الحساب مفقودة" المتبعة في العميل | تحقق |
| `AppTheme.branchManagerLight` | `AppTheme.clientLight` | الثيم نفسه يُعاد استخدامه؛ لا تُكسر الألوان المشتركة |

---

## 4. قرارات تحتاج موافقتك قبل التنفيذ

1. **عدد التبويبات**: هل تبقى 6 تبويبات للفرع (لوحة، طلبات، مخزون، فواتير، سائقون، محادثات) مع شريط عائم بنمط العميل، أم تُدمج بعضها؟ (العميل لديه 4 تبويبات).
2. **زر الـ FAB المركزي**: حالياً يفتح تبويب الطلبات. هل يبقى كذلك، أم يتحول إلى "إنشاء فاتورة" أو إجراء آخر؟
3. **الشاشات المشتركة** (`notifications_screen`, `help_support_screen`, `splash_screen`): هل تُوحَّد الآن للعميل والفرع معاً، أم تبقى مؤجلة؟
4. **المكونات المشتركة بالنظام الداكن القديم**: هل تُحوَّل إلى الألوان الفاتحة الجديدة؟ هذا يؤثر على شاشات العميل أيضاً.
5. **حدود الثيم**: هل تُحدَّث `AppTheme.branchManagerLight` نفسه (الذي يرث منه `clientLight`) أم يُنشأ ثيم مستقل للفرع؟ الأول يؤثر على العميل.

---

## 5. تعديلات غير مُلتزَمة يجب الحفاظ عليها

- `medlink_app/lib/screens/branch_manager/branch_order_detail_screen.dart`: **+273 سطر** غير مُلتزَم.
- `medlink_app/lib/screens/client/order_detail_screen.dart`: **+259 سطر** غير مُلتزَم.

**القاعدة**: لا يُكتب فوق هذين الملفين من جديد. أي تغيير تصميمي عليهما يُطبَّق كتعديل فوق النسخة الحالية، ويُراجَع `git diff` قبل وبعد.

---

## 6. التنفيذ المقترح (بالمراحل)

| المرحلة | المحتوى | معيار الإنهاء |
|---|---|---|
| 0 | تأكيد القرارات في القسم 4 + جرد الشاشات بلقطات | موافقة مكتوبة |
| 1 | تحديث الثيم والخلفية والشريط السفلي والشريط العلوي للغلاف | `flutter analyze` بلا أخطاء؛ التبويبات تعمل |
| 2 | لوحة الفرع (`branch_dashboard_tab`) | كل الأقسام الستة تعرض بالتصميم الجديد |
| 3 | الطلبات + `branch_order_card` + `branch_order_detail_screen` (مع الحفاظ على التعديلات غير المُلتزَمة) | الطلب يعرض، الإجراءات تعمل، التعديلات محفوظة |
| 4 | المخزون + `inventory_quantity_tile` + الحوارات المرتبطة | الإضافة/التعديل/الحذف تعمل |
| 5 | الفواتير + `branch_invoice_create_sheet` | الإنشاء والعرض يعملان |
| 6 | السائقون (`create_driver_sheet`, `manage_driver_sheet`) | الإنشاء والإدارة تعمل |
| 7 | المحادثات | الإرسال والاستقبال يعملان |
| 8 | حوارات الإجراءات (`branch_order_actions`) + `branch_allocate_sheet` + `branch_settings_sheet` | كل الحوارات تعرض بالشكل الموحد |
| 9 | الشاشات المشتركة (إن تقرر ذلك) | الإشعارات والمساعدة والسبلاش بالشكل الموحد |

---

## 7. الحالات الواجب الحفاظ عليها في كل شاشة (وفق AGENTS.md)

لكل تبويب ونافذة وحوار:

- **التحميل** (loading)
- **الخطأ** (error) مع زر إعادة المحاولة
- **الفراغ** (empty)
- **المعطّل** (disabled) — مثل أزرار الإجراءات عند عدم توفر الصلاحية أو الحالة
- **الصلاحية** (permission) — حالة المستخدم غير المخوّل

---

## 8. التحقق

قبل اعتبار أي مرحلة مكتملة:

1. `flutter analyze` بلا أخطاء جديدة (لم يُشغَّل بعد لهذه المهمة).
2. `flutter test` — الاختبارات الموجودة: `branch_cancellation_test.dart`, `order_cancellation_test.dart`, `order_discount_test.dart`, `cart_controller_bonus_test.dart`, `bonus_idempotency_key_test.dart`, `widget_test.dart`. (لم تُشغَّل بعد.)
3. مقارنة بصرية: لقطة لكل شاشة فرع بعد التغيير مقابل شاشة العميل المرجعية، مع فحص النص على الخلفية الفاتحة.
4. `git diff` للمراجعة: التأكد أن التغييرات مقتصرة على `medlink_app/lib/screens/branch_manager/`, `medlink_app/lib/widgets/`، و`utils/theme.dart` إن تقرر ذلك — وليس على ملفات الخادم أو قاعدة البيانات.
5. لا تغيير على `supabase/`, `api-server/`, أو `lib/api-spec` ضمن هذه الخطة (واجهة فقط).

---

## 9. ما لم يُتحقق منه بعد

- لم يُشغَّل `flutter analyze` ولا `flutter test`.
- لم تُلتقط لقطات للواجهة الحالية؛ مقارنة الشكل النهائي تعتمد على التقاط لقطات.
- شاشات العميل المتبقية (`catalog_tab`, `cart_screen`, `checkout_screen`, `product_detail_screen`, `order_success_screen`, `account_tab` بالكامل، `bonus_*`) تحتاج قراءة أعمق لتأكيد أن كل مكوّن فيها يستخدم `ClientCard`/`ClientColors` دون استثناءات.
- تمت قراءة ملفات الفرع بالقياس (عدد الأسطر والاستخدامات) وقراءة جزئية للتبويبات؛ قراءة كاملة لكل حوار وكل حالة ستكون في المرحلة 0.
