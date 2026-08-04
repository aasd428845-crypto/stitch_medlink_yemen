import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';

/// Translates raw Supabase/Postgrest errors into a localized message key.
/// Never swallow the original error — callers must still log the raw
/// exception under the SUPABASE_DEBUG tag; this only controls what the user
/// sees on screen.
String mapAuthErrorToMessage(AppLocalizations l10n, Object error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return l10n.invalidCredentials;
    }
    if (msg.contains('already registered') || msg.contains('user already exists')) {
      return l10n.emailAlreadyRegistered;
    }
    return error.message;
  }
  if (error is PostgrestException) {
    return error.message;
  }
  return l10n.unknownError;
}
