/// Central app-wide constants.
///
/// Supabase URL and anon key are the *publishable* keys for this project.
/// Per project instructions, the anon key is safe to embed directly in
/// Flutter client code — it relies entirely on Postgres Row Level Security
/// policies for authorization, never on secrecy of this value.
class AppConstants {
  AppConstants._();

  static const String supabaseUrl = 'https://lmkomzqioneuyvatzsov.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_yxm5GTZm87Y3wQwi019lXQ_IMLplZQc';

  static const String googleOAuthClientId =
      '448796262930-j1k8aordm2dp3h11khrdpaiqgn4hso9t.apps.googleusercontent.com';

  /// Debug log tag mandated by the project's architecture rules — every
  /// Supabase call must log through this tag so failures are traceable.
  static const String supabaseDebugTag = 'SUPABASE_DEBUG';
}

/// Strict user roles. `companyDirector` exists only to be recognized and
/// rejected — this app never renders any UI for that role.
enum UserRole {
  client,
  branchManager,
  driver,
  companyDirector;

  static UserRole fromString(String value) {
    switch (value) {
      case 'client':
        return UserRole.client;
      case 'branch_manager':
        return UserRole.branchManager;
      case 'driver':
        return UserRole.driver;
      case 'company_director':
        return UserRole.companyDirector;
      default:
        throw ArgumentError('Unknown role from database: $value');
    }
  }

  String get wireValue {
    switch (this) {
      case UserRole.client:
        return 'client';
      case UserRole.branchManager:
        return 'branch_manager';
      case UserRole.driver:
        return 'driver';
      case UserRole.companyDirector:
        return 'company_director';
    }
  }
}

enum AccountStatus {
  pendingApproval,
  active,
  rejected,
  suspended;

  static AccountStatus fromString(String value) {
    switch (value) {
      case 'pending_approval':
        return AccountStatus.pendingApproval;
      case 'active':
        return AccountStatus.active;
      case 'rejected':
        return AccountStatus.rejected;
      case 'suspended':
        return AccountStatus.suspended;
      default:
        throw ArgumentError('Unknown account_status from database: $value');
    }
  }
}
