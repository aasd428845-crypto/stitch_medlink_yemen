// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'ميدلينك اليمن';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'أدخل بياناتك للوصول إلى حسابك';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get orDivider => 'أو';

  @override
  String get continueWithGoogle => 'المتابعة عبر جوجل';

  @override
  String get noAccountYet => 'ليس لديك حساب؟';

  @override
  String get createAccountLink => 'إنشاء حساب جديد';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get registerTitle => 'إنشاء حساب جديد';

  @override
  String get registerSubtitle =>
      'سجّل بياناتك، وسيتم مراجعة حسابك من قبل الإدارة';

  @override
  String get nameLabel => 'الاسم الكامل';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get registerButton => 'إنشاء الحساب';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get loginLink => 'تسجيل الدخول';

  @override
  String get acceptTermsPrefix => 'أوافق على';

  @override
  String get termsAndConditions => 'الشروط وسياسة الخصوصية';

  @override
  String get pendingApprovalTitle => 'بانتظار المراجعة';

  @override
  String get pendingApprovalMessage =>
      'تم استلام طلب تسجيلك بنجاح. حسابك الآن قيد المراجعة من قبل الإدارة، وسيتم إشعارك فور الموافقة عليه.';

  @override
  String get pendingApprovalRefresh => 'تحديث الحالة';

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String get rejectedTitle => 'تم رفض الحساب';

  @override
  String get rejectedMessage =>
      'نعتذر، تم رفض طلب تسجيل حسابك من قبل الإدارة. للاستفسار، يرجى التواصل مع الدعم.';

  @override
  String get suspendedTitle => 'الحساب موقوف';

  @override
  String get suspendedMessage =>
      'تم إيقاف هذا الحساب مؤقتاً من قبل الإدارة. يرجى التواصل مع الدعم لمزيد من التفاصيل.';

  @override
  String get directorNotSupportedTitle => 'الدخول غير متاح';

  @override
  String get directorNotSupportedMessage =>
      'حسابات مدير الشركة العام تُدار حصراً عبر منصة الويب المخصصة، ولا يمكن الدخول بهذا الدور من تطبيق الجوال.';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get validationRequired => 'هذا الحقل مطلوب';

  @override
  String get validationEmailInvalid => 'صيغة البريد الإلكتروني غير صحيحة';

  @override
  String get validationPasswordShort =>
      'كلمة المرور يجب أن تكون 6 أحرف على الأقل';

  @override
  String get validationPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get validationTermsRequired =>
      'يجب الموافقة على الشروط وسياسة الخصوصية للمتابعة';

  @override
  String get genericErrorTitle => 'حدث خطأ';

  @override
  String get networkError =>
      'تعذّر الاتصال بالخادم. تحقق من اتصالك بالإنترنت وحاول مجدداً';

  @override
  String get invalidCredentials => 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get emailAlreadyRegistered => 'هذا البريد الإلكتروني مسجّل بالفعل';

  @override
  String get unknownError => 'حدث خطأ غير متوقع، حاول مرة أخرى';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get comingSoon => 'هذا القسم قيد الإنشاء';

  @override
  String get clientHomeLabel => 'الرئيسية';

  @override
  String get clientCatalogLabel => 'الكتالوج';

  @override
  String get clientOrdersLabel => 'طلباتي';

  @override
  String get clientProfileLabel => 'حسابي';

  @override
  String get branchDashboardLabel => 'لوحة التحكم';

  @override
  String get branchOrdersLabel => 'الطلبات';

  @override
  String get branchInventoryLabel => 'المخزون';

  @override
  String get branchInvoicesLabel => 'الفواتير';

  @override
  String get branchDriversLabel => 'السائقون';

  @override
  String get branchDashboardNewOrders => 'طلبات جديدة';

  @override
  String get branchDashboardInProgress => 'قيد التوصيل';

  @override
  String get branchDashboardCompletedToday => 'مكتملة اليوم';

  @override
  String get branchDashboardRecentOrders => 'أحدث الطلبات';

  @override
  String get branchAssignDriver => 'إسناد سائق';

  @override
  String get branchTransferOrder => 'تحويل الطلب';

  @override
  String get branchRejectOrder => 'رفض الطلب';

  @override
  String get branchSelectDriver => 'اختر السائق';

  @override
  String get branchSelectBranch => 'اختر الفرع';

  @override
  String get branchConfirmTransfer => 'تأكيد التحويل';

  @override
  String get branchNoDriversAvailable => 'لا يوجد سائق مسند';

  @override
  String get branchNoOtherBranches => 'لا توجد فروع أخرى متاحة';

  @override
  String get branchDriverBusy => 'مشغول';

  @override
  String get branchDriverAvailable => 'متاح';

  @override
  String get branchDriverActiveOrders => 'طلب نشط';

  @override
  String get branchOrderFilterAll => 'الكل';

  @override
  String get branchOrderFilterPending => 'قيد المراجعة';

  @override
  String get branchOrderFilterAssigned => 'مُسند';

  @override
  String get branchOrderFilterInProgress => 'جاري التوصيل';

  @override
  String get branchOrderFilterDelivered => 'تم التسليم';

  @override
  String get branchOrderFilterCancelled => 'ملغي';

  @override
  String get branchInventoryEditQuantity => 'تعديل الكمية';

  @override
  String get branchInventoryCurrentQuantity => 'الكمية الحالية';

  @override
  String get branchInventoryUpdate => 'تحديث';

  @override
  String get branchNoInventory => 'لا توجد أصناف في المخزون بعد';

  @override
  String get branchNoInvoices => 'لا توجد فواتير مكتملة بعد';

  @override
  String get branchNoDrivers => 'لا يوجد سائقون في هذا الفرع بعد';

  @override
  String get branchOrderDetailTitle => 'تفاصيل الطلب';

  @override
  String get branchChangeStatus => 'تحديث الحالة';

  @override
  String get branchStatusUpdateConfirm => 'هل أنت متأكد من تنفيذ هذا الإجراء؟';

  @override
  String get driverOrdersLabel => 'طلباتي';

  @override
  String get driverEarningsLabel => 'أرباحي';

  @override
  String get driverChatLabel => 'الدردشة';

  @override
  String get driverCreateTitle => 'إضافة سائق جديد';

  @override
  String get driverCreateButton => 'إنشاء حساب السائق';

  @override
  String get driverTempPasswordLabel => 'كلمة المرور المؤقتة';

  @override
  String get driverTempPasswordHint => 'ستشاركها مع السائق';

  @override
  String get driverCreatedSuccess => 'تم إنشاء حساب السائق بنجاح';

  @override
  String get driverCreatedMessage => 'شارك بيانات الدخول التالية مع السائق:';

  @override
  String get driverManageTitle => 'إدارة السائق';

  @override
  String get driverActivate => 'تفعيل الحساب';

  @override
  String get driverSuspend => 'إيقاف الحساب';

  @override
  String get driverResetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get driverResetPasswordNew => 'كلمة المرور الجديدة';

  @override
  String get driverResetPasswordConfirm => 'تأكيد كلمة المرور الجديدة';

  @override
  String get driverStatusActive => 'نشط';

  @override
  String get driverStatusSuspended => 'موقوف';

  @override
  String get driverStatusPending => 'قيد المراجعة';

  @override
  String get driverActionSuccess => 'تم تنفيذ الإجراء بنجاح';

  @override
  String get changePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get changePasswordSubtitle =>
      'يجب عليك تعيين كلمة مرور جديدة قبل المتابعة';

  @override
  String get newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPasswordLabel => 'تأكيد كلمة المرور الجديدة';

  @override
  String get changePasswordButton => 'تغيير كلمة المرور';

  @override
  String get catalogTitle => 'كتالوج المنتجات';

  @override
  String get searchHint => 'ابحث عن منتج...';

  @override
  String get allCategories => 'الكل';

  @override
  String get noProductsFound => 'لا توجد منتجات مطابقة للبحث';

  @override
  String get noOffersFound => 'لا توجد عروض متاحة حالياً';

  @override
  String get productDetails => 'تفاصيل المنتج';

  @override
  String get unitPrice => 'السعر للوحدة';

  @override
  String get manufacturer => 'الشركة المصنّعة';

  @override
  String get dosageForm => 'الشكل الدوائي';

  @override
  String get unit => 'الوحدة';

  @override
  String get category => 'الفئة';

  @override
  String get addToCart => 'أضف إلى السلة';

  @override
  String get addedToCart => 'تمت الإضافة إلى السلة';

  @override
  String get offersSection => 'العروض الترويجية';

  @override
  String get viewOffer => 'عرض التفاصيل';

  @override
  String get homeGreeting => 'أهلاً،';

  @override
  String get homeSubtitle => 'اكتشف منتجاتنا وعروضنا';

  @override
  String get quickOrderSection => 'طلب سريع';

  @override
  String get exploreCategories => 'تصفّح الفئات';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cartTitle => 'سلة الشراء';

  @override
  String get emptyCart => 'السلة فارغة حالياً';

  @override
  String get subtotal => 'الإجمالي الفرعي';

  @override
  String get total => 'المجموع الكلي';

  @override
  String get freeDelivery => 'التوصيل مجاني 100%';

  @override
  String get proceedToCheckout => 'متابعة الطلب';

  @override
  String get autoBonusBadge => '🎁 بونص تلقائي';

  @override
  String get clearCart => 'تفريغ السلة';

  @override
  String get checkoutTitle => 'تأكيد الطلب المباشر';

  @override
  String get deliveryAddress => 'عنوان التسليم';

  @override
  String get addNewAddress => 'إضافة عنوان جديد';

  @override
  String get addressLabel => 'اسم العنوان (مثال: الصيدلية)';

  @override
  String get addressText => 'العنوان بالتفصيل';

  @override
  String get saveAddress => 'حفظ العنوان';

  @override
  String get orderNotes => 'ملاحظات الطلب (اختياري)';

  @override
  String get confirmOrder => 'تأكيد وإرسال الطلب';

  @override
  String get orderSuccessTitle => 'تم إرسال طلبك بنجاح!';

  @override
  String get orderSuccessSubtitle =>
      'سيتم توجيه الطلب لأقرب فرع للبدء بالتجهيز والتوصيل.';

  @override
  String get viewOrderDetails => 'متابعة تفاصيل الطلب';

  @override
  String get ordersTitle => 'طلباتي';

  @override
  String get noOrdersFound => 'لا توجد طلبات حتى الآن';

  @override
  String get orderNumber => 'طلب رقم';

  @override
  String get orderStatusPending => 'قيد المراجعة';

  @override
  String get orderStatusAssigned => 'مُسند لسائق';

  @override
  String get orderStatusInProgress => 'جاري التوصيل';

  @override
  String get orderStatusDelivered => 'تم التسليم';

  @override
  String get orderStatusCancelled => 'ملغي';

  @override
  String get orderItemsCount => 'عدد البنود';

  @override
  String get deliveredTo => 'موجه إلى';

  @override
  String get driverNoOrders => 'لا توجد طلبات مُسندة حالياً';

  @override
  String get driverStartDelivery => 'بدء التوصيل';

  @override
  String get driverConfirmDelivery => 'تأكيد التسليم';

  @override
  String get driverDeliveryStarted => 'بدأت رحلة التوصيل';

  @override
  String get driverDeliveryConfirmed => 'تم تسليم الطلب بنجاح';

  @override
  String get driverOrderDetailTitle => 'تفاصيل الطلب';

  @override
  String get driverClientPhone => 'هاتف العميل';

  @override
  String get driverDeliveryAddress => 'عنوان التسليم';

  @override
  String get driverFilterAll => 'الكل';

  @override
  String get driverFilterAssigned => 'مُسند';

  @override
  String get driverFilterInProgress => 'جاري التوصيل';

  @override
  String get driverFilterDelivered => 'تم التسليم';

  @override
  String get driverEarningsThisMonth => 'أرباح هذا الشهر';

  @override
  String get driverTotalDeliveries => 'إجمالي التوصيلات';

  @override
  String get driverNoEarnings => 'لا توجد أرباح مسجّلة بعد';

  @override
  String get driverOrderEarning => 'تفاصيل العمولات';

  @override
  String get driverChatComingSoon =>
      'الدردشة المباشرة ستكون متاحة في مرحلة قادمة';

  @override
  String get driverThisMonth => 'هذا الشهر';

  @override
  String get driverLastMonth => 'الشهر الماضي';

  @override
  String get driverTotalEarningsLabel => 'إجمالي الأرباح';

  @override
  String get driverOrderItems => 'بنود';

  @override
  String get driverUpdateError => 'فشل تحديث الحالة، حاول مجدداً';
}
