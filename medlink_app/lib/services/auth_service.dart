import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../utils/constants.dart';

/// Single source of truth for every authentication operation. Every screen
/// that needs to sign up, sign in, sign out, or read the current profile
/// must call through this service — never re-implement this logic locally.
///
/// Architecture rules honored here (see project context doc):
/// - Real Supabase auth only, no fake/demo accounts, no shared passwords.
/// - Never manually insert/upsert into public.users — the `handle_new_user`
///   trigger owns that row exclusively.
/// - Every Supabase call is wrapped so failures are logged under the
///   SUPABASE_DEBUG tag with the function name and full error text.
/// - Success is only ever reported after a real, verified response.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  void _logError(String fn, Object error, [StackTrace? st]) {
    debugPrint(
      '[${AppConstants.supabaseDebugTag}] $fn failed: $error'
      '${st != null ? '\n$st' : ''}',
    );
  }

  /// Registers a new `client` account. Role is always forced to 'client'
  /// here — self-registration for other roles is not permitted anywhere in
  /// this app (branch_manager/driver accounts are created by staff, and
  /// company_director is entirely out of this app's scope).
  Future<AuthResponse> signUpClient({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'role': 'client',
        },
      );
      return response;
    } catch (e, st) {
      _logError('signUpClient', e, st);
      rethrow;
    }
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e, st) {
      _logError('signInWithPassword', e, st);
      rethrow;
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: AppConstants.googleOAuthClientId,
        scopes: ['email', 'profile'],
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('تم إلغاء تسجيل الدخول عبر جوجل');
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null) {
        throw const AuthException('تعذّر الحصول على بيانات جوجل، حاول مجدداً');
      }
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return response;
    } catch (e, st) {
      _logError('signInWithGoogle', e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e, st) {
      _logError('signOut', e, st);
      rethrow;
    }
  }

  /// Reads the row `handle_new_user` created for the signed-in user.
  /// Never writes to `public.users` from client code.
  Future<UserProfile?> fetchCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return null;
      return UserProfile.fromJson(row);
    } catch (e, st) {
      _logError('fetchCurrentProfile', e, st);
      rethrow;
    }
  }

  Future<void> acceptTerms() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from('users')
          .update({'terms_accepted_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (e, st) {
      _logError('acceptTerms', e, st);
      rethrow;
    }
  }
}
