// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MedLink Yemen';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginSubtitle => 'Enter your details to access your account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get orDivider => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get noAccountYet => 'Don\'t have an account?';

  @override
  String get createAccountLink => 'Create a new account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle =>
      'Register your details; your account will be reviewed by management';

  @override
  String get nameLabel => 'Full name';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get registerButton => 'Create account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginLink => 'Sign in';

  @override
  String get acceptTermsPrefix => 'I agree to the';

  @override
  String get termsAndConditions => 'Terms & Privacy Policy';

  @override
  String get pendingApprovalTitle => 'Pending Review';

  @override
  String get pendingApprovalMessage =>
      'Your registration request has been received. Your account is now under review by management, and you will be notified once it is approved.';

  @override
  String get pendingApprovalRefresh => 'Refresh status';

  @override
  String get logoutButton => 'Sign out';

  @override
  String get rejectedTitle => 'Account Rejected';

  @override
  String get rejectedMessage =>
      'We\'re sorry, your registration request was rejected by management. Please contact support for details.';

  @override
  String get suspendedTitle => 'Account Suspended';

  @override
  String get suspendedMessage =>
      'This account has been temporarily suspended by management. Please contact support for details.';

  @override
  String get directorNotSupportedTitle => 'Sign-in unavailable';

  @override
  String get directorNotSupportedMessage =>
      'Company director accounts are managed exclusively through the dedicated web platform and cannot sign in from the mobile app.';

  @override
  String get backToLogin => 'Back to sign in';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationEmailInvalid => 'Invalid email format';

  @override
  String get validationPasswordShort =>
      'Password must be at least 6 characters';

  @override
  String get validationPasswordMismatch => 'Passwords do not match';

  @override
  String get validationTermsRequired =>
      'You must accept the Terms & Privacy Policy to continue';

  @override
  String get genericErrorTitle => 'Something went wrong';

  @override
  String get networkError =>
      'Could not connect to the server. Check your connection and try again';

  @override
  String get invalidCredentials => 'Incorrect email or password';

  @override
  String get emailAlreadyRegistered => 'This email is already registered';

  @override
  String get unknownError => 'An unexpected error occurred, please try again';

  @override
  String get homeTitle => 'Home';

  @override
  String get comingSoon => 'This section is under construction';

  @override
  String get clientHomeLabel => 'Home';

  @override
  String get clientCatalogLabel => 'Catalog';

  @override
  String get clientOrdersLabel => 'Orders';

  @override
  String get clientProfileLabel => 'Profile';

  @override
  String get branchDashboardLabel => 'Dashboard';

  @override
  String get branchOrdersLabel => 'Orders';

  @override
  String get branchInventoryLabel => 'Inventory';

  @override
  String get branchInvoicesLabel => 'Invoices';

  @override
  String get branchDriversLabel => 'Drivers';

  @override
  String get branchDashboardNewOrders => 'New Orders';

  @override
  String get branchDashboardInProgress => 'In Progress';

  @override
  String get branchDashboardCompletedToday => 'Completed Today';

  @override
  String get branchDashboardRecentOrders => 'Recent Orders';

  @override
  String get branchAssignDriver => 'Assign Driver';

  @override
  String get branchTransferOrder => 'Transfer Order';

  @override
  String get branchRejectOrder => 'Reject Order';

  @override
  String get branchSelectDriver => 'Select Driver';

  @override
  String get branchSelectBranch => 'Select Branch';

  @override
  String get branchConfirmTransfer => 'Confirm Transfer';

  @override
  String get branchNoDriversAvailable => 'No driver assigned';

  @override
  String get branchNoOtherBranches => 'No other branches available';

  @override
  String get branchDriverBusy => 'Busy';

  @override
  String get branchDriverAvailable => 'Available';

  @override
  String get branchDriverActiveOrders => 'active orders';

  @override
  String get branchOrderFilterAll => 'All';

  @override
  String get branchOrderFilterPending => 'Pending';

  @override
  String get branchOrderFilterAssigned => 'Assigned';

  @override
  String get branchOrderFilterInProgress => 'In Progress';

  @override
  String get branchOrderFilterDelivered => 'Delivered';

  @override
  String get branchOrderFilterCancelled => 'Cancelled';

  @override
  String get branchInventoryEditQuantity => 'Edit Quantity';

  @override
  String get branchInventoryCurrentQuantity => 'Current Quantity';

  @override
  String get branchInventoryUpdate => 'Update';

  @override
  String get branchNoInventory => 'No inventory items yet';

  @override
  String get branchNoInvoices => 'No completed invoices yet';

  @override
  String get branchNoDrivers => 'No drivers at this branch yet';

  @override
  String get branchOrderDetailTitle => 'Order Details';

  @override
  String get branchChangeStatus => 'Update Status';

  @override
  String get branchStatusUpdateConfirm =>
      'Are you sure you want to perform this action?';

  @override
  String get driverOrdersLabel => 'Orders';

  @override
  String get driverEarningsLabel => 'Earnings';

  @override
  String get driverChatLabel => 'Chat';

  @override
  String get driverCreateTitle => 'Add New Driver';

  @override
  String get driverCreateButton => 'Create Driver Account';

  @override
  String get driverTempPasswordLabel => 'Temporary Password';

  @override
  String get driverTempPasswordHint => 'You will share this with the driver';

  @override
  String get driverCreatedSuccess => 'Driver account created successfully';

  @override
  String get driverCreatedMessage => 'Share these credentials with the driver:';

  @override
  String get driverManageTitle => 'Manage Driver';

  @override
  String get driverActivate => 'Activate Account';

  @override
  String get driverSuspend => 'Suspend Account';

  @override
  String get driverResetPassword => 'Reset Password';

  @override
  String get driverResetPasswordNew => 'New Password';

  @override
  String get driverResetPasswordConfirm => 'Confirm New Password';

  @override
  String get driverStatusActive => 'Active';

  @override
  String get driverStatusSuspended => 'Suspended';

  @override
  String get driverStatusPending => 'Pending';

  @override
  String get driverActionSuccess => 'Action completed successfully';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get changePasswordSubtitle =>
      'You must set a new password before continuing';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get changePasswordButton => 'Change Password';

  @override
  String get catalogTitle => 'Product Catalog';

  @override
  String get searchHint => 'Search for a product...';

  @override
  String get allCategories => 'All';

  @override
  String get noProductsFound => 'No products match your search';

  @override
  String get noOffersFound => 'No offers available at this time';

  @override
  String get productDetails => 'Product Details';

  @override
  String get unitPrice => 'Price per unit';

  @override
  String get manufacturer => 'Manufacturer';

  @override
  String get dosageForm => 'Dosage form';

  @override
  String get unit => 'Unit';

  @override
  String get category => 'Category';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get addedToCart => 'Added to cart';

  @override
  String get offersSection => 'Promotional Offers';

  @override
  String get viewOffer => 'View details';

  @override
  String get homeGreeting => 'Welcome,';

  @override
  String get homeSubtitle => 'Explore our products and offers';

  @override
  String get quickOrderSection => 'Quick Order';

  @override
  String get exploreCategories => 'Browse categories';

  @override
  String get retry => 'Try again';

  @override
  String get cartTitle => 'Shopping Cart';

  @override
  String get emptyCart => 'Your cart is currently empty';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get total => 'Total';

  @override
  String get freeDelivery => '100% Free Delivery';

  @override
  String get proceedToCheckout => 'Proceed to Checkout';

  @override
  String get autoBonusBadge => '🎁 Free Bonus';

  @override
  String get clearCart => 'Clear Cart';

  @override
  String get checkoutTitle => 'Order Confirmation';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get addNewAddress => 'Add New Address';

  @override
  String get addressLabel => 'Label (e.g. Pharmacy)';

  @override
  String get addressText => 'Detailed Address';

  @override
  String get saveAddress => 'Save Address';

  @override
  String get orderNotes => 'Order Notes (Optional)';

  @override
  String get confirmOrder => 'Confirm & Send Order';

  @override
  String get orderSuccessTitle => 'Order Sent Successfully!';

  @override
  String get orderSuccessSubtitle =>
      'Your order will be routed to the nearest branch for preparation and delivery.';

  @override
  String get viewOrderDetails => 'Track Order Details';

  @override
  String get ordersTitle => 'My Orders';

  @override
  String get noOrdersFound => 'No orders yet';

  @override
  String get orderNumber => 'Order #';

  @override
  String get orderStatusPending => 'Pending Review';

  @override
  String get orderStatusAssigned => 'Assigned to Driver';

  @override
  String get orderStatusInProgress => 'Out for Delivery';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderItemsCount => 'Items';

  @override
  String get deliveredTo => 'Delivered to';

  @override
  String get driverNoOrders => 'No orders assigned at the moment';

  @override
  String get driverStartDelivery => 'Start Delivery';

  @override
  String get driverConfirmDelivery => 'Confirm Delivery';

  @override
  String get driverDeliveryStarted => 'Delivery started';

  @override
  String get driverDeliveryConfirmed => 'Order delivered successfully';

  @override
  String get driverOrderDetailTitle => 'Order Details';

  @override
  String get driverClientPhone => 'Client Phone';

  @override
  String get driverDeliveryAddress => 'Delivery Address';

  @override
  String get driverFilterAll => 'All';

  @override
  String get driverFilterAssigned => 'Assigned';

  @override
  String get driverFilterInProgress => 'In Progress';

  @override
  String get driverFilterDelivered => 'Delivered';

  @override
  String get driverEarningsThisMonth => 'Earnings this month';

  @override
  String get driverTotalDeliveries => 'Total Deliveries';

  @override
  String get driverNoEarnings => 'No earnings recorded yet';

  @override
  String get driverOrderEarning => 'Commission Details';

  @override
  String get driverChatComingSoon =>
      'Live chat will be available in an upcoming phase';

  @override
  String get driverThisMonth => 'This Month';

  @override
  String get driverLastMonth => 'Last Month';

  @override
  String get driverTotalEarningsLabel => 'Total Earnings';

  @override
  String get driverOrderItems => 'items';

  @override
  String get driverUpdateError => 'Failed to update status, please try again';
}
