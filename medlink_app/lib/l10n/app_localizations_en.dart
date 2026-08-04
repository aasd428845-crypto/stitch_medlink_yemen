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
  String get branchInventoryLabel => 'Inventory';

  @override
  String get branchInvoicesLabel => 'Invoices';

  @override
  String get branchDriversLabel => 'Drivers';

  @override
  String get driverOrdersLabel => 'Orders';

  @override
  String get driverEarningsLabel => 'Earnings';

  @override
  String get driverChatLabel => 'Chat';
}
