import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App name shown on splash and login
  ///
  /// In ar, this message translates to:
  /// **'ميدلينك اليمن'**
  String get appName;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بياناتك للوصول إلى حسابك'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginButton;

  /// No description provided for @orDivider.
  ///
  /// In ar, this message translates to:
  /// **'أو'**
  String get orDivider;

  /// No description provided for @continueWithGoogle.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة عبر جوجل'**
  String get continueWithGoogle;

  /// No description provided for @noAccountYet.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get noAccountYet;

  /// No description provided for @createAccountLink.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get createAccountLink;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// No description provided for @registerTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل بياناتك، وسيتم مراجعة حسابك من قبل الإدارة'**
  String get registerSubtitle;

  /// No description provided for @nameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get nameLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPasswordLabel;

  /// No description provided for @registerButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get registerButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get alreadyHaveAccount;

  /// No description provided for @loginLink.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginLink;

  /// No description provided for @acceptTermsPrefix.
  ///
  /// In ar, this message translates to:
  /// **'أوافق على'**
  String get acceptTermsPrefix;

  /// No description provided for @termsAndConditions.
  ///
  /// In ar, this message translates to:
  /// **'الشروط وسياسة الخصوصية'**
  String get termsAndConditions;

  /// No description provided for @pendingApprovalTitle.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار المراجعة'**
  String get pendingApprovalTitle;

  /// No description provided for @pendingApprovalMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم استلام طلب تسجيلك بنجاح. حسابك الآن قيد المراجعة من قبل الإدارة، وسيتم إشعارك فور الموافقة عليه.'**
  String get pendingApprovalMessage;

  /// No description provided for @pendingApprovalRefresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الحالة'**
  String get pendingApprovalRefresh;

  /// No description provided for @logoutButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logoutButton;

  /// No description provided for @rejectedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض الحساب'**
  String get rejectedTitle;

  /// No description provided for @rejectedMessage.
  ///
  /// In ar, this message translates to:
  /// **'نعتذر، تم رفض طلب تسجيل حسابك من قبل الإدارة. للاستفسار، يرجى التواصل مع الدعم.'**
  String get rejectedMessage;

  /// No description provided for @suspendedTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحساب موقوف'**
  String get suspendedTitle;

  /// No description provided for @suspendedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف هذا الحساب مؤقتاً من قبل الإدارة. يرجى التواصل مع الدعم لمزيد من التفاصيل.'**
  String get suspendedMessage;

  /// No description provided for @directorNotSupportedTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدخول غير متاح'**
  String get directorNotSupportedTitle;

  /// No description provided for @directorNotSupportedMessage.
  ///
  /// In ar, this message translates to:
  /// **'حسابات مدير الشركة العام تُدار حصراً عبر منصة الويب المخصصة، ولا يمكن الدخول بهذا الدور من تطبيق الجوال.'**
  String get directorNotSupportedMessage;

  /// No description provided for @backToLogin.
  ///
  /// In ar, this message translates to:
  /// **'العودة لتسجيل الدخول'**
  String get backToLogin;

  /// No description provided for @validationRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get validationRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In ar, this message translates to:
  /// **'صيغة البريد الإلكتروني غير صحيحة'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب أن تكون 6 أحرف على الأقل'**
  String get validationPasswordShort;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get validationPasswordMismatch;

  /// No description provided for @validationTermsRequired.
  ///
  /// In ar, this message translates to:
  /// **'يجب الموافقة على الشروط وسياسة الخصوصية للمتابعة'**
  String get validationTermsRequired;

  /// No description provided for @genericErrorTitle.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get genericErrorTitle;

  /// No description provided for @networkError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بالخادم. تحقق من اتصالك بالإنترنت وحاول مجدداً'**
  String get networkError;

  /// No description provided for @invalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو كلمة المرور غير صحيحة'**
  String get invalidCredentials;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد الإلكتروني مسجّل بالفعل'**
  String get emailAlreadyRegistered;

  /// No description provided for @unknownError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع، حاول مرة أخرى'**
  String get unknownError;

  /// No description provided for @homeTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get homeTitle;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'هذا القسم قيد الإنشاء'**
  String get comingSoon;

  /// No description provided for @clientHomeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get clientHomeLabel;

  /// No description provided for @clientCatalogLabel.
  ///
  /// In ar, this message translates to:
  /// **'الكتالوج'**
  String get clientCatalogLabel;

  /// No description provided for @clientOrdersLabel.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get clientOrdersLabel;

  /// No description provided for @clientProfileLabel.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get clientProfileLabel;

  /// No description provided for @branchDashboardLabel.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get branchDashboardLabel;

  /// No description provided for @branchOrdersLabel.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get branchOrdersLabel;

  /// No description provided for @branchInventoryLabel.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get branchInventoryLabel;

  /// No description provided for @branchInvoicesLabel.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير'**
  String get branchInvoicesLabel;

  /// No description provided for @branchDriversLabel.
  ///
  /// In ar, this message translates to:
  /// **'السائقون'**
  String get branchDriversLabel;

  /// No description provided for @branchDashboardNewOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلبات جديدة'**
  String get branchDashboardNewOrders;

  /// No description provided for @branchDashboardInProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التوصيل'**
  String get branchDashboardInProgress;

  /// No description provided for @branchDashboardCompletedToday.
  ///
  /// In ar, this message translates to:
  /// **'مكتملة اليوم'**
  String get branchDashboardCompletedToday;

  /// No description provided for @branchDashboardRecentOrders.
  ///
  /// In ar, this message translates to:
  /// **'أحدث الطلبات'**
  String get branchDashboardRecentOrders;

  /// No description provided for @branchAssignDriver.
  ///
  /// In ar, this message translates to:
  /// **'إسناد سائق'**
  String get branchAssignDriver;

  /// No description provided for @branchTransferOrder.
  ///
  /// In ar, this message translates to:
  /// **'تحويل الطلب'**
  String get branchTransferOrder;

  /// No description provided for @branchRejectOrder.
  ///
  /// In ar, this message translates to:
  /// **'رفض الطلب'**
  String get branchRejectOrder;

  /// No description provided for @branchSelectDriver.
  ///
  /// In ar, this message translates to:
  /// **'اختر السائق'**
  String get branchSelectDriver;

  /// No description provided for @branchSelectBranch.
  ///
  /// In ar, this message translates to:
  /// **'اختر الفرع'**
  String get branchSelectBranch;

  /// No description provided for @branchConfirmTransfer.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد التحويل'**
  String get branchConfirmTransfer;

  /// No description provided for @branchNoDriversAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد سائق مسند'**
  String get branchNoDriversAvailable;

  /// No description provided for @branchNoOtherBranches.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فروع أخرى متاحة'**
  String get branchNoOtherBranches;

  /// No description provided for @branchDriverBusy.
  ///
  /// In ar, this message translates to:
  /// **'مشغول'**
  String get branchDriverBusy;

  /// No description provided for @branchDriverAvailable.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get branchDriverAvailable;

  /// No description provided for @branchDriverActiveOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلب نشط'**
  String get branchDriverActiveOrders;

  /// No description provided for @branchOrderFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get branchOrderFilterAll;

  /// No description provided for @branchOrderFilterPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get branchOrderFilterPending;

  /// No description provided for @branchOrderFilterAssigned.
  ///
  /// In ar, this message translates to:
  /// **'مُسند'**
  String get branchOrderFilterAssigned;

  /// No description provided for @branchOrderFilterInProgress.
  ///
  /// In ar, this message translates to:
  /// **'جاري التوصيل'**
  String get branchOrderFilterInProgress;

  /// No description provided for @branchOrderFilterDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التسليم'**
  String get branchOrderFilterDelivered;

  /// No description provided for @branchOrderFilterCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get branchOrderFilterCancelled;

  /// No description provided for @branchInventoryEditQuantity.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الكمية'**
  String get branchInventoryEditQuantity;

  /// No description provided for @branchInventoryCurrentQuantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية الحالية'**
  String get branchInventoryCurrentQuantity;

  /// No description provided for @branchInventoryUpdate.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get branchInventoryUpdate;

  /// No description provided for @branchNoInventory.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أصناف في المخزون بعد'**
  String get branchNoInventory;

  /// No description provided for @branchNoInvoices.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فواتير مكتملة بعد'**
  String get branchNoInvoices;

  /// No description provided for @branchNoOrders.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات واردة'**
  String get branchNoOrders;

  /// No description provided for @branchOrderDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get branchOrderDetailTitle;

  /// No description provided for @branchChangeStatus.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الحالة'**
  String get branchChangeStatus;

  /// No description provided for @branchStatusUpdateConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد تغيير الحالة'**
  String get branchStatusUpdateConfirm;

  /// No description provided for @branchNoDrivers.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد سائقون في هذا الفرع بعد'**
  String get branchNoDrivers;

  /// No description provided for @homeGreeting.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ما الذي تحتاجه اليوم؟'**
  String get homeSubtitle;

  /// No description provided for @offersSection.
  ///
  /// In ar, this message translates to:
  /// **'العروض الترويجية'**
  String get offersSection;

  /// No description provided for @noOffersFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عروض متاحة حالياً'**
  String get noOffersFound;

  /// No description provided for @viewOffer.
  ///
  /// In ar, this message translates to:
  /// **'عرض التفاصيل'**
  String get viewOffer;

  /// No description provided for @categoriesSection.
  ///
  /// In ar, this message translates to:
  /// **'التصفح حسب الفئة'**
  String get categoriesSection;

  /// No description provided for @featuredProducts.
  ///
  /// In ar, this message translates to:
  /// **'منتجات مميزة'**
  String get featuredProducts;

  /// No description provided for @catalogTitle.
  ///
  /// In ar, this message translates to:
  /// **'الكتالوج'**
  String get catalogTitle;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن دواء أو منتج...'**
  String get searchHint;

  /// No description provided for @filterByCategory.
  ///
  /// In ar, this message translates to:
  /// **'تصفية حسب الفئة'**
  String get filterByCategory;

  /// No description provided for @allCategories.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allCategories;

  /// No description provided for @noProductsFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات مطابقة'**
  String get noProductsFound;

  /// No description provided for @productDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المنتج'**
  String get productDetailTitle;

  /// No description provided for @addToCart.
  ///
  /// In ar, this message translates to:
  /// **'أضف إلى السلة'**
  String get addToCart;

  /// No description provided for @addedToCart.
  ///
  /// In ar, this message translates to:
  /// **'تم إضافته إلى السلة'**
  String get addedToCart;

  /// No description provided for @outOfStock.
  ///
  /// In ar, this message translates to:
  /// **'غير متوفر'**
  String get outOfStock;

  /// No description provided for @inStock.
  ///
  /// In ar, this message translates to:
  /// **'متوفر'**
  String get inStock;

  /// No description provided for @stockQuantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية المتوفرة'**
  String get stockQuantity;

  /// No description provided for @bonusTag.
  ///
  /// In ar, this message translates to:
  /// **'هدية'**
  String get bonusTag;

  /// No description provided for @productCategory.
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get productCategory;

  /// No description provided for @productManufacturer.
  ///
  /// In ar, this message translates to:
  /// **'الشركة المصنعة'**
  String get productManufacturer;

  /// No description provided for @productDosageForm.
  ///
  /// In ar, this message translates to:
  /// **'الشكل الدوائي'**
  String get productDosageForm;

  /// No description provided for @productUnitPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الوحدة'**
  String get productUnitPrice;

  /// No description provided for @cartTitle.
  ///
  /// In ar, this message translates to:
  /// **'سلة المشتريات'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In ar, this message translates to:
  /// **'السلة فارغة'**
  String get cartEmpty;

  /// No description provided for @cartTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get cartTotal;

  /// No description provided for @cartItemCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأصناف'**
  String get cartItemCount;

  /// No description provided for @proceedToCheckout.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة للطلب'**
  String get proceedToCheckout;

  /// No description provided for @removeFromCart.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get removeFromCart;

  /// No description provided for @clearCart.
  ///
  /// In ar, this message translates to:
  /// **'تفريغ السلة'**
  String get clearCart;

  /// No description provided for @checkoutTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الطلب المباشر'**
  String get checkoutTitle;

  /// No description provided for @deliveryAddress.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التسليم'**
  String get deliveryAddress;

  /// No description provided for @addNewAddress.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان جديد'**
  String get addNewAddress;

  /// No description provided for @addressLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم العنوان (مثال: الصيدلية)'**
  String get addressLabel;

  /// No description provided for @addressText.
  ///
  /// In ar, this message translates to:
  /// **'العنوان بالتفصيل'**
  String get addressText;

  /// No description provided for @saveAddress.
  ///
  /// In ar, this message translates to:
  /// **'حفظ العنوان'**
  String get saveAddress;

  /// No description provided for @orderNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الطلب (اختياري)'**
  String get orderNotes;

  /// No description provided for @confirmOrder.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد وإرسال الطلب'**
  String get confirmOrder;

  /// No description provided for @orderSuccessTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلبك بنجاح!'**
  String get orderSuccessTitle;

  /// No description provided for @orderSuccessSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سيتم توجيه الطلب لأقرب فرع للبدء بالتجهيز والتوصيل.'**
  String get orderSuccessSubtitle;

  /// No description provided for @viewOrderDetails.
  ///
  /// In ar, this message translates to:
  /// **'متابعة تفاصيل الطلب'**
  String get viewOrderDetails;

  /// No description provided for @ordersTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get ordersTitle;

  /// No description provided for @noOrdersFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات حتى الآن'**
  String get noOrdersFound;

  /// No description provided for @orderNumber.
  ///
  /// In ar, this message translates to:
  /// **'طلب رقم'**
  String get orderNumber;

  /// No description provided for @orderStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get orderStatusPending;

  /// No description provided for @orderStatusAssigned.
  ///
  /// In ar, this message translates to:
  /// **'مُسند لسائق'**
  String get orderStatusAssigned;

  /// No description provided for @orderStatusInProgress.
  ///
  /// In ar, this message translates to:
  /// **'جاري التوصيل'**
  String get orderStatusInProgress;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التسليم'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get orderStatusCancelled;

  /// No description provided for @orderItemsCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد البنود'**
  String get orderItemsCount;

  /// No description provided for @deliveredTo.
  ///
  /// In ar, this message translates to:
  /// **'موجه إلى'**
  String get deliveredTo;

  /// No description provided for @driverNoOrders.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات مُسندة حالياً'**
  String get driverNoOrders;

  /// No description provided for @driverStartDelivery.
  ///
  /// In ar, this message translates to:
  /// **'بدء التوصيل'**
  String get driverStartDelivery;

  /// No description provided for @driverConfirmDelivery.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد التسليم'**
  String get driverConfirmDelivery;

  /// No description provided for @driverDeliveryStarted.
  ///
  /// In ar, this message translates to:
  /// **'بدأت رحلة التوصيل'**
  String get driverDeliveryStarted;

  /// No description provided for @driverDeliveryConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'تم تسليم الطلب بنجاح'**
  String get driverDeliveryConfirmed;

  /// No description provided for @driverOrderDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get driverOrderDetailTitle;

  /// No description provided for @driverClientPhone.
  ///
  /// In ar, this message translates to:
  /// **'هاتف العميل'**
  String get driverClientPhone;

  /// No description provided for @driverDeliveryAddress.
  ///
  /// In ar, this message translates to:
  /// **'عنوان التسليم'**
  String get driverDeliveryAddress;

  /// No description provided for @driverScheduledDelivery.
  ///
  /// In ar, this message translates to:
  /// **'وقت التسليم المتوقع'**
  String get driverScheduledDelivery;

  /// No description provided for @driverFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get driverFilterAll;

  /// No description provided for @driverFilterAssigned.
  ///
  /// In ar, this message translates to:
  /// **'مُسند'**
  String get driverFilterAssigned;

  /// No description provided for @driverFilterInProgress.
  ///
  /// In ar, this message translates to:
  /// **'جاري التوصيل'**
  String get driverFilterInProgress;

  /// No description provided for @driverFilterDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تم التسليم'**
  String get driverFilterDelivered;

  /// No description provided for @driverEarningsThisMonth.
  ///
  /// In ar, this message translates to:
  /// **'أرباح هذا الشهر'**
  String get driverEarningsThisMonth;

  /// No description provided for @driverTotalDeliveries.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي التوصيلات'**
  String get driverTotalDeliveries;

  /// No description provided for @driverNoEarnings.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أرباح مسجّلة بعد'**
  String get driverNoEarnings;

  /// No description provided for @driverOrderEarning.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل العمولات'**
  String get driverOrderEarning;

  /// No description provided for @driverChatComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'الدردشة المباشرة ستكون متاحة في مرحلة قادمة'**
  String get driverChatComingSoon;

  /// No description provided for @driverThisMonth.
  ///
  /// In ar, this message translates to:
  /// **'هذا الشهر'**
  String get driverThisMonth;

  /// No description provided for @driverLastMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر الماضي'**
  String get driverLastMonth;

  /// No description provided for @driverTotalEarningsLabel.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الأرباح'**
  String get driverTotalEarningsLabel;

  /// No description provided for @driverOrderItems.
  ///
  /// In ar, this message translates to:
  /// **'بنود'**
  String get driverOrderItems;

  /// No description provided for @driverUpdateError.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحديث الحالة، حاول مجدداً'**
  String get driverUpdateError;

  /// No description provided for @notificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل مقروءاً'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تنبيهات حتى الآن'**
  String get notificationsEmpty;

  /// No description provided for @offerDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل العرض'**
  String get offerDetailTitle;

  /// No description provided for @offerValidFrom.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ من'**
  String get offerValidFrom;

  /// No description provided for @offerValidUntil.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي في'**
  String get offerValidUntil;

  /// No description provided for @offerGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة المستهدفة'**
  String get offerGovernorate;

  /// No description provided for @changePasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يجب عليك تغيير كلمة المرور المؤقتة قبل الاستمرار'**
  String get changePasswordSubtitle;

  /// No description provided for @newPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور الجديدة'**
  String get confirmNewPasswordLabel;

  /// No description provided for @changePasswordButton.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get changePasswordButton;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير كلمة المرور بنجاح'**
  String get changePasswordSuccess;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In ar, this message translates to:
  /// **'المجموع الجزئي'**
  String get subtotal;

  /// No description provided for @freeDelivery.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل مجاني'**
  String get freeDelivery;

  /// No description provided for @emptyCart.
  ///
  /// In ar, this message translates to:
  /// **'السلة فارغة'**
  String get emptyCart;

  /// No description provided for @exploreCategories.
  ///
  /// In ar, this message translates to:
  /// **'تصفح حسب الفئة'**
  String get exploreCategories;

  /// No description provided for @autoBonusBadge.
  ///
  /// In ar, this message translates to:
  /// **'هدية تلقائية 🎁'**
  String get autoBonusBadge;

  /// No description provided for @category.
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get category;

  /// No description provided for @dosageForm.
  ///
  /// In ar, this message translates to:
  /// **'الشكل الدوائي'**
  String get dosageForm;

  /// No description provided for @manufacturer.
  ///
  /// In ar, this message translates to:
  /// **'الشركة المصنعة'**
  String get manufacturer;

  /// No description provided for @productDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المنتج'**
  String get productDetails;

  /// No description provided for @unit.
  ///
  /// In ar, this message translates to:
  /// **'وحدة'**
  String get unit;

  /// No description provided for @unitPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الوحدة'**
  String get unitPrice;

  /// No description provided for @driverOrdersLabel.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get driverOrdersLabel;

  /// No description provided for @driverEarningsLabel.
  ///
  /// In ar, this message translates to:
  /// **'أرباحي'**
  String get driverEarningsLabel;

  /// No description provided for @driverChatLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدردشة'**
  String get driverChatLabel;

  /// No description provided for @driverCreateTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة سائق جديد'**
  String get driverCreateTitle;

  /// No description provided for @driverTempPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور المؤقتة'**
  String get driverTempPasswordLabel;

  /// No description provided for @driverCreateButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get driverCreateButton;

  /// No description provided for @driverCreatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم بنجاح'**
  String get driverCreatedSuccess;

  /// No description provided for @driverCreatedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء حساب السائق بنجاح، يمكنه الآن تسجيل الدخول بكلمة المرور المؤقتة.'**
  String get driverCreatedMessage;

  /// No description provided for @driverActionSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت العملية بنجاح'**
  String get driverActionSuccess;

  /// No description provided for @driverSuspend.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get driverSuspend;

  /// No description provided for @driverActivate.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get driverActivate;

  /// No description provided for @driverResetPassword.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين كلمة المرور'**
  String get driverResetPassword;

  /// No description provided for @driverResetPasswordNew.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get driverResetPasswordNew;

  /// No description provided for @driverResetPasswordConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور الجديدة'**
  String get driverResetPasswordConfirm;

  /// No description provided for @driverStatusActive.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get driverStatusActive;

  /// No description provided for @driverStatusSuspended.
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get driverStatusSuspended;

  /// No description provided for @driverStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار المراجعة'**
  String get driverStatusPending;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
