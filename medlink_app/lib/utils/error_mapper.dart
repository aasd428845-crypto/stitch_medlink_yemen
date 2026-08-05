import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import 'constants.dart';

/// Postgres SQLSTATE codes we translate into a friendly Arabic message.
/// See https://www.postgresql.org/docs/current/errcodes-appendix.html
class _PgErrorCodes {
  _PgErrorCodes._();
  static const uniqueViolation = '23505';
  static const foreignKeyViolation = '23503';
  static const undefinedColumn = '42703';
  static const insufficientPrivilege = '42501';
}

void _logRawError(Object error) {
  // The original exception is always logged in full for diagnosis —
  // only the on-screen message is ever simplified/localized.
  debugPrint('[${AppConstants.supabaseDebugTag}] mapAuthErrorToMessage: $error');
}

/// Translates raw Supabase/Postgrest errors into a localized message.
/// Never swallow the original error — the raw exception is always logged
/// under the SUPABASE_DEBUG tag; this only controls what the user sees on
/// screen. An unexpected/unrecognized error ALWAYS falls back to a generic
/// Arabic message — the raw English exception text is never shown to users.
String mapAuthErrorToMessage(AppLocalizations l10n, Object error) {
  _logRawError(error);

  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return l10n.invalidCredentials;
    }
    if (msg.contains('already registered') || msg.contains('user already exists')) {
      return l10n.emailAlreadyRegistered;
    }
    // Unrecognized auth error — never surface raw provider text.
    return l10n.unknownError;
  }

  if (error is PostgrestException) {
    final code = error.code;
    final msg = error.message.toLowerCase();

    if (code == _PgErrorCodes.uniqueViolation || msg.contains('duplicate key')) {
      return l10n.dbDuplicateError;
    }
    if (code == _PgErrorCodes.undefinedColumn || msg.contains('column') && msg.contains('does not exist')) {
      return l10n.dbColumnNotFoundError;
    }
    if (code == _PgErrorCodes.insufficientPrivilege ||
        msg.contains('permission denied') ||
        msg.contains('row-level security') ||
        msg.contains('rls')) {
      return l10n.dbPermissionDeniedError;
    }
    if (code == _PgErrorCodes.foreignKeyViolation || msg.contains('foreign key constraint')) {
      return l10n.dbForeignKeyError;
    }
    // Any other Postgrest error — generic Arabic message, never raw SQL text.
    return l10n.dbUnknownError;
  }

  return l10n.unknownError;
}
