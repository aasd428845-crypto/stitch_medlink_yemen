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
  String get loginSubtitle => 'Enter your credentials to access your account';

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
  String get createAccountLink => 'Create Account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle =>
      'Register your details — your account will be reviewed by management';

  @override
  String get nameLabel => 'Full Name';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get registerButton => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginLink => 'Sign In';

  @override
  String get acceptTermsPrefix => 'I agree to the';

  @override
  String get termsAndConditions => 'Terms & Privacy Policy';

  @override
  String get pendingApprovalTitle => 'Awaiting Review';

  @override
  String get pendingApprovalMessage =>
      'Your registration has been received. Your account is currently under review by management. You will be notified once approved.';

  @override
  String get pendingApprovalRefresh => 'Refresh Status';

  @override
  String get logoutButton => 'Sign Out';

  @override
  String get rejectedTitle => 'Account Rejected';

  @override
  String get rejectedMessage =>
      'Sorry, your account registration has been rejected by management. Please contact support for more information.';

  @override
  String get suspendedTitle => 'Account Suspended';

  @override
  String get suspendedMessage =>
      'This account has been temporarily suspended by management. Please contact support for more details.';

  @override
  String get directorNotSupportedTitle => 'Access Unavailable';

  @override
  String get directorNotSupportedMessage =>
      'Company director accounts are managed exclusively through the dedicated web platform and cannot sign in from the mobile app.';

  @override
  String get backToLogin => 'Back to Sign In';

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
      'You must agree to the Terms & Privacy Policy to continue';

  @override
  String get genericErrorTitle => 'An Error Occurred';

  @override
  String get networkError =>
      'Could not connect to the server. Check your internet connection and try again.';

  @override
  String get invalidCredentials => 'Incorrect email or password';

  @override
  String get emailAlreadyRegistered => 'This email is already registered';

  @override
  String get unknownError => 'An unexpected error occurred, please try again';

  @override
  String get dbDuplicateError =>
      'This item already exists and cannot be duplicated';

  @override
  String get dbColumnNotFoundError =>
      'A data structure error occurred, please try again later';

  @override
  String get dbPermissionDeniedError =>
      'You don\'t have permission to perform this action';

  @override
  String get dbForeignKeyError =>
      'This action can\'t be completed because this item is linked to other data';

  @override
  String get dbUnknownError => 'A server error occurred, please try again';

  @override
  String get homeTitle => 'Home';

  @override
  String get comingSoon => 'This section is coming soon';

  @override
  String get clientHomeLabel => 'Home';

  @override
  String get clientCatalogLabel => 'Catalog';

  @override
  String get clientOrdersLabel => 'My Orders';

  @override
  String get clientProfileLabel => 'Account';

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
  String get branchDashboardInProgress => 'In Transit';

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
  String get branchDriverActiveOrders => 'active order';

  @override
  String get branchOrderFilterAll => 'All';

  @override
  String get branchOrderFilterPending => 'Pending';

  @override
  String get branchOrderFilterAssigned => 'Assigned';

  @override
  String get branchOrderFilterInProgress => 'In Transit';

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
  String get branchNoOrders => 'No incoming orders';

  @override
  String get branchOrderDetailTitle => 'Order Details';

  @override
  String get branchChangeStatus => 'Change Status';

  @override
  String get branchStatusUpdateConfirm => 'Confirm Status Change';

  @override
  String get branchNoDrivers => 'No drivers in this branch yet';

  @override
  String get homeGreeting => 'Hello';

  @override
  String get homeSubtitle => 'What do you need today?';

  @override
  String get offersSection => 'Promotional Offers';

  @override
  String get noOffersFound => 'No offers available at the moment';

  @override
  String get viewOffer => 'View Details';

  @override
  String get categoriesSection => 'Browse by Category';

  @override
  String get featuredProducts => 'Featured Products';

  @override
  String get catalogTitle => 'Catalog';

  @override
  String get searchHint => 'Search for a medicine or product...';

  @override
  String get filterByCategory => 'Filter by Category';

  @override
  String get allCategories => 'All';

  @override
  String get noProductsFound => 'No matching products found';

  @override
  String get productDetailTitle => 'Product Details';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get addedToCart => 'Added to cart';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get inStock => 'In Stock';

  @override
  String get stockQuantity => 'Available Quantity';

  @override
  String get bonusTag => 'Gift';

  @override
  String get productCategory => 'Category';

  @override
  String get productManufacturer => 'Manufacturer';

  @override
  String get productDosageForm => 'Dosage Form';

  @override
  String get productUnitPrice => 'Unit Price';

  @override
  String get cartTitle => 'Shopping Cart';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartItemCount => 'Items';

  @override
  String get proceedToCheckout => 'Proceed to Order';

  @override
  String get removeFromCart => 'Remove';

  @override
  String get clearCart => 'Clear Cart';

  @override
  String get checkoutTitle => 'Confirm Direct Order';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get addNewAddress => 'Add New Address';

  @override
  String get addressLabel => 'Address Name (e.g. Pharmacy)';

  @override
  String get addressText => 'Detailed Address';

  @override
  String get saveAddress => 'Save Address';

  @override
  String get orderNotes => 'Order Notes (optional)';

  @override
  String get confirmOrder => 'Confirm & Send Order';

  @override
  String get orderSuccessTitle => 'Order Sent Successfully!';

  @override
  String get orderSuccessSubtitle =>
      'Your order will be directed to the nearest branch for preparation and delivery.';

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
  String get orderStatusAssigned => 'Driver Assigned';

  @override
  String get orderStatusInProgress => 'In Transit';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderItemsCount => 'Items';

  @override
  String get deliveredTo => 'Directed to';

  @override
  String get driverNoOrders => 'No assigned orders at the moment';

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
  String get driverScheduledDelivery => 'Expected Delivery Time';

  @override
  String get driverFilterAll => 'All';

  @override
  String get driverFilterAssigned => 'Assigned';

  @override
  String get driverFilterInProgress => 'In Transit';

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

  @override
  String get driverRoleLabel => 'MedLink Driver';

  @override
  String get driverHeroSubtitle =>
      'Track delivery tasks and order status from one screen.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get offerDetailTitle => 'Offer Details';

  @override
  String get offerValidFrom => 'Valid from';

  @override
  String get offerValidUntil => 'Valid until';

  @override
  String get offerGovernorate => 'Target Governorate';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get changePasswordSubtitle =>
      'You must change your temporary password before continuing';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get changePasswordButton => 'Change Password';

  @override
  String get changePasswordSuccess => 'Password changed successfully';

  @override
  String get retry => 'Retry';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get freeDelivery => 'Free Delivery';

  @override
  String get emptyCart => 'Cart is empty';

  @override
  String get exploreCategories => 'Browse by Category';

  @override
  String get reorderSuggestions => 'You may need to reorder soon';

  @override
  String get availableQuantity => 'Available';

  @override
  String get reorderAddedToCart =>
      'Items were added to the cart at current prices';

  @override
  String get autoBonusBadge => 'Auto Bonus 🎁';

  @override
  String get category => 'Category';

  @override
  String get dosageForm => 'Dosage Form';

  @override
  String get manufacturer => 'Manufacturer';

  @override
  String get productDetails => 'Product Details';

  @override
  String get unit => 'unit';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get driverOrdersLabel => 'My Orders';

  @override
  String get driverEarningsLabel => 'Earnings';

  @override
  String get driverChatLabel => 'Chat';

  @override
  String get driverCreateTitle => 'Add New Driver';

  @override
  String get driverTempPasswordLabel => 'Temporary Password';

  @override
  String get driverCreateButton => 'Create Account';

  @override
  String get driverCreatedSuccess => 'Success';

  @override
  String get driverCreatedMessage =>
      'Driver account created successfully. They can now sign in with the temporary password.';

  @override
  String get driverActionSuccess => 'Operation completed successfully';

  @override
  String get driverSuspend => 'Suspend';

  @override
  String get driverActivate => 'Activate';

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
  String get driverStatusPending => 'Pending Review';

  @override
  String get rateDriverTitle => 'Rate Driver';

  @override
  String get rateDriverPrompt => 'How was your experience with the driver?';

  @override
  String get rateDriverCommentHint => 'Write your comment (optional)';

  @override
  String get rateDriverSubmit => 'Submit Rating';

  @override
  String get rateDriverSuccess => 'Thank you for your rating';

  @override
  String get rateDriverAlreadyRated => 'This order has already been rated';

  @override
  String get ratingAverageLabel => 'Average Rating';

  @override
  String get ratingCountLabel => 'Total Ratings';

  @override
  String get noRatingsYet => 'No ratings yet';

  @override
  String get yourRatingLabel => 'Your Rating';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatNoConversations => 'No active conversations';

  @override
  String get chatMessageHint => 'Write a message...';

  @override
  String get chatSendButton => 'Send';

  @override
  String get chatEmptyRoom => 'No messages yet — start the conversation';

  @override
  String get chatWithDriver => 'Chat with driver';

  @override
  String get chatWithBranch => 'Chat with branch';

  @override
  String get driverLocationTitle => 'Driver location';

  @override
  String get driverLocationUpdate => 'Update my location';

  @override
  String get driverLocationUpdated => 'Your location has been updated';

  @override
  String get driverLocationPermissionDenied =>
      'Please allow location access to enable live delivery';

  @override
  String get driverLocationUnavailable => 'Location is currently unavailable';

  @override
  String get helpSupportTitle => 'Help & Support';

  @override
  String get helpFaqSection => 'Frequently Asked Questions';

  @override
  String get helpContactSection => 'Contact Us';

  @override
  String get helpCallUs => 'Call Us';

  @override
  String get helpWhatsapp => 'Message us on WhatsApp';

  @override
  String get helpEmailUs => 'Email Us';

  @override
  String get branchNotAssignedTitle => 'No branch assigned to your account';

  @override
  String get branchNotAssignedMessage =>
      'This section couldn\'t load because your account isn\'t linked to a branch yet. Please contact company management to assign your branch.';
}
