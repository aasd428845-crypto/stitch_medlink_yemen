import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import 'auth_service.dart';

enum AuthStatus { loading, signedOut, signedIn }

/// App-wide auth/session state. GoRouter listens to this via
/// [ChangeNotifier] to decide redirects; screens read it via Provider to
/// know the current role/account_status without re-fetching.
class AuthController extends ChangeNotifier {
  AuthController(this._authService) {
    _sub = _authService.authStateChanges.listen((_) => _refresh());
    _refresh();
  }

  final AuthService _authService;
  StreamSubscription<AuthState>? _sub;

  AuthStatus status = AuthStatus.loading;
  UserProfile? profile;
  Object? lastError;

  bool get isSignedIn => _authService.currentSession != null;

  Future<void> _refresh() async {
    if (_authService.currentSession == null) {
      status = AuthStatus.signedOut;
      profile = null;
      notifyListeners();
      return;
    }
    try {
      final fetched = await _authService.fetchCurrentProfile();
      profile = fetched;
      status = AuthStatus.signedIn;
      lastError = null;
    } catch (e) {
      lastError = e;
      status = AuthStatus.signedIn;
    }
    notifyListeners();
  }

  Future<void> refreshProfile() => _refresh();

  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
