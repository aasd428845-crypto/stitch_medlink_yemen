import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';

/// Wraps the `manage-driver-account` Edge Function and the driver's own
/// password-change flow. Branch managers call the Edge Function methods;
/// drivers call [changeMyPassword] after first login.
class DriverService {
  DriverService(this._client);

  final SupabaseClient _client;

  void _logError(String fn, Object error, [StackTrace? st]) {
    debugPrint(
      '[${AppConstants.supabaseDebugTag}] DriverService.$fn failed: $error'
      '${st != null ? '\n$st' : ''}',
    );
  }

  void _logSuccess(String fn) {
    debugPrint('[${AppConstants.supabaseDebugTag}] DriverService.$fn OK');
  }

  /// Invokes the edge function and throws a human-readable message on error.
  Future<void> _invoke(Map<String, dynamic> body) async {
    final response = await _client.functions.invoke(
      'manage-driver-account',
      body: body,
    );
    if (response.status != 200) {
      final msg = (response.data as Map<String, dynamic>?)?['error']
          as String? ??
          'حدث خطأ غير متوقع (${response.status})';
      throw Exception(msg);
    }
  }

  /// Creates a new driver account under the calling manager's branch.
  /// The new account is immediately active and flagged for password change.
  Future<void> createDriver({
    required String name,
    required String email,
    required String phone,
    required String tempPassword,
  }) async {
    try {
      await _invoke({
        'action': 'create',
        'name': name,
        'email': email,
        'phone': phone,
        'password': tempPassword,
      });
      _logSuccess('createDriver');
    } catch (e, st) {
      _logError('createDriver', e, st);
      rethrow;
    }
  }

  /// Activates or suspends a driver account in the manager's branch.
  /// [status] must be `'active'` or `'suspended'`.
  Future<void> updateDriverStatus(String driverId, String status) async {
    try {
      await _invoke({
        'action': 'update_status',
        'driverId': driverId,
        'status': status,
      });
      _logSuccess('updateDriverStatus');
    } catch (e, st) {
      _logError('updateDriverStatus', e, st);
      rethrow;
    }
  }

  /// Resets a driver's password and flags the account for password change.
  Future<void> resetDriverPassword(
      String driverId, String newPassword) async {
    try {
      await _invoke({
        'action': 'reset_password',
        'driverId': driverId,
        'newPassword': newPassword,
      });
      _logSuccess('resetDriverPassword');
    } catch (e, st) {
      _logError('resetDriverPassword', e, st);
      rethrow;
    }
  }

  /// Driver-side: updates the auth password then clears the
  /// `requires_password_change` flag via a security-definer RPC.
  ///
  /// Writing the flag through the RPC (not directly to `public.users`) ensures
  /// the client can never set arbitrary columns — the RPC only clears
  /// `requires_password_change` for the authenticated caller.
  Future<void> changeMyPassword(String newPassword) async {
    try {
      final response =
          await _client.auth.updateUser(UserAttributes(password: newPassword));
      if (response.user == null) {
        throw Exception('تعذّر تغيير كلمة المرور، حاول مجدداً');
      }
      // Atomically clear the flag through the backend-controlled RPC.
      // Migration 0005 defines clear_requires_password_change() as
      // security definer so it bypasses RLS without leaking privileges.
      await _client.rpc('clear_requires_password_change');
      _logSuccess('changeMyPassword');
    } catch (e, st) {
      _logError('changeMyPassword', e, st);
      rethrow;
    }
  }
}
