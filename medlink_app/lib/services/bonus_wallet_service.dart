import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';

/// Available/reserved bonus funds for the current client, as computed by
/// the `bonus_account_funds` RPC. Never calculated in UI code.
@immutable
class BonusFunds {
  const BonusFunds({required this.available, required this.reserved});

  factory BonusFunds.fromJson(Map<String, dynamic> json) {
    return BonusFunds(
      available: (json['available'] as num?)?.toDouble() ?? 0,
      reserved: (json['reserved'] as num?)?.toDouble() ?? 0,
    );
  }

  final double available;
  final double reserved;
}

/// One row of `public.bonus_ledger` visible to the client.
/// Display only: amounts and labels are shown verbatim, never recomputed.
@immutable
class BonusLedgerEntry {
  const BonusLedgerEntry({
    required this.id,
    required this.txnType,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.orderId,
    this.ruleId,
    this.reference,
    this.notes,
  });

  factory BonusLedgerEntry.fromJson(Map<String, dynamic> json) {
    return BonusLedgerEntry(
      id: json['id'] as String,
      txnType: json['txn_type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      orderId: json['order_id'] as String?,
      ruleId: json['rule_id'] as String?,
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final String txnType;
  final double amount;
  final String status;
  final String createdAt;
  final String? orderId;
  final String? ruleId;
  final String? reference;
  final String? notes;
}

/// One row of `public.bonus_redemptions` visible to the client.
@immutable
class BonusRedemption {
  const BonusRedemption({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.bonusValue,
    required this.status,
    required this.createdAt,
  });

  factory BonusRedemption.fromJson(Map<String, dynamic> json) {
    return BonusRedemption(
      id: json['id'] as String,
      productId: json['product_id'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      bonusValue: (json['bonus_value'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final String id;
  final String productId;
  final int quantity;
  final double bonusValue;
  final String status;
  final String createdAt;
}

/// One row of `public.bonus_withdrawals` visible to the client.
@immutable
class BonusWithdrawal {
  const BonusWithdrawal({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paymentMethod,
    this.rejectionReason,
  });

  factory BonusWithdrawal.fromJson(Map<String, dynamic> json) {
    return BonusWithdrawal(
      id: json['id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      paymentMethod: json['payment_method'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  final String id;
  final double amount;
  final String status;
  final String createdAt;
  final String? paymentMethod;
  final String? rejectionReason;
}

/// Single source of truth for client Bonus wallet reads.
/// Architecture rule (CLAUDE.md §3):
/// - Every Supabase call logs through SUPABASE_DEBUG.
/// - Success is only reported after a real verified response.
/// - Balance is NEVER computed here: `bonus_account_funds` is authoritative.
/// - Only the signed-in user's own id is ever used (RLS owns the rest).
class BonusWalletService {
  BonusWalletService(this._client);

  final SupabaseClient _client;

  void _logError(String fn, Object error, [StackTrace? st]) {
    debugPrint(
      '[${AppConstants.supabaseDebugTag}] BonusWalletService.$fn failed: $error'
      '${st != null ? '\n$st' : ''}',
    );
  }

  void _logSuccess(String fn) {
    debugPrint('[${AppConstants.supabaseDebugTag}] BonusWalletService.$fn OK');
  }

  /// Funds for the current user. Throws when signed out.
  Future<BonusFunds> fetchMyFunds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('المستخدم غير مسجل الدخول');
    }
    try {
      final data = await _client.rpc(
        'bonus_account_funds',
        params: {'p_user_id': userId},
      );
      final row = data is List && data.isNotEmpty
          ? data.first as Map<String, dynamic>
          : data as Map<String, dynamic>;
      _logSuccess('fetchMyFunds');
      return BonusFunds.fromJson(row);
    } catch (e, st) {
      _logError('fetchMyFunds', e, st);
      rethrow;
    }
  }

  /// Ledger history for the current user (RLS limits rows to the caller).
  Future<List<BonusLedgerEntry>> fetchMyLedger({int limit = 100}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('المستخدم غير مسجل الدخول');
    }
    try {
      final rows = await _client
          .from('bonus_ledger')
          .select(
            'id, txn_type, amount, status, created_at, order_id, rule_id, reference, notes',
          )
          .eq('account_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      _logSuccess('fetchMyLedger');
      return (rows as List)
          .map((r) => BonusLedgerEntry.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logError('fetchMyLedger', e, st);
      rethrow;
    }
  }

  /// Submits a product redemption for the current user.
  /// Returns the new redemption id. Server validates funds/product.
  Future<String> requestRedemption({
    required String productId,
    required int quantity,
    String? idempotencyKey,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const AuthException('المستخدم غير مسجل الدخول');
    }
    try {
      final data = await _client.rpc(
        'request_redemption',
        params: {
          'p_product_id': productId,
          'p_quantity': quantity,
          if (idempotencyKey != null) 'p_idempotency_key': idempotencyKey,
        },
      );
      _logSuccess('requestRedemption');
      return data as String;
    } catch (e, st) {
      _logError('requestRedemption', e, st);
      rethrow;
    }
  }

  /// Submits a cash withdrawal for the current user.
  /// Returns the new withdrawal id. Limits/policies enforced server-side.
  Future<String> requestWithdrawal({
    required double amount,
    String? method,
    String? notes,
    String? idempotencyKey,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const AuthException('المستخدم غير مسجل الدخول');
    }
    try {
      final data = await _client.rpc(
        'request_withdrawal',
        params: {
          'p_amount': amount,
          if (method != null && method.isNotEmpty) 'p_method': method,
          if (notes != null && notes.isNotEmpty) 'p_notes': notes,
          if (idempotencyKey != null) 'p_idempotency_key': idempotencyKey,
        },
      );
      _logSuccess('requestWithdrawal');
      return data as String;
    } catch (e, st) {
      _logError('requestWithdrawal', e, st);
      rethrow;
    }
  }

  /// Cancels the caller's own pending redemption (server enforces status).
  Future<void> cancelRedemption(String redemptionId) async {
    if (_client.auth.currentUser == null) {
      throw const AuthException('المستخدم غير مسجل الدخول');
    }
    try {
      await _client.rpc(
        'cancel_redemption',
        params: {'p_redemption_id': redemptionId},
      );
      _logSuccess('cancelRedemption');
    } catch (e, st) {
      _logError('cancelRedemption', e, st);
      rethrow;
    }
  }

  /// Cancels the caller's own pending withdrawal (server enforces status).
  Future<void> cancelWithdrawal(String withdrawalId) async {
    if (_client.auth.currentUser == null) {
      throw const AuthException('المستخدم غير مسجل الدخول');
    }
    try {
      await _client.rpc(
        'cancel_withdrawal',
        params: {'p_withdrawal_id': withdrawalId},
      );
      _logSuccess('cancelWithdrawal');
    } catch (e, st) {
      _logError('cancelWithdrawal', e, st);
      rethrow;
    }
  }

  /// Applies bonus as a discount on the caller's own pending order.
  /// Returns the new ORDER_DISCOUNT ledger id. All policy (caps, funding
  /// scope, zero-order, idempotency) is enforced server-side by
  /// `apply_order_discount`; the amount here is a request, never a decision.
  Future<String> requestOrderDiscount({
    required String orderId,
    required double amount,
    String? idempotencyKey,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const AuthException('المستخدم غير مسجل الدخول');
    }
    try {
      final data = await _client.rpc(
        'apply_order_discount',
        params: {
          'p_order_id': orderId,
          'p_amount': amount,
          if (idempotencyKey != null) 'p_idempotency_key': idempotencyKey,
        },
      );
      _logSuccess('requestOrderDiscount');
      return data as String;
    } catch (e, st) {
      _logError('requestOrderDiscount', e, st);
      rethrow;
    }
  }

  /// Removes the caller's applied order discount (compensating reversal).
  /// Server decides from the discount-time policy snapshot; no-op unless a
  /// POSTED discount exists for the order.
  Future<String> cancelOrderDiscount({
    required String orderId,
    String? reason,
    String? idempotencyKey,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const AuthException('المستخدم غير مسجل الدخول');
    }
    try {
      final data = await _client.rpc(
        'cancel_order_discount',
        params: {
          'p_order_id': orderId,
          if (reason != null && reason.isNotEmpty) 'p_reason': reason,
          if (idempotencyKey != null) 'p_idempotency_key': idempotencyKey,
        },
      );
      _logSuccess('cancelOrderDiscount');
      return data as String;
    } catch (e, st) {
      _logError('cancelOrderDiscount', e, st);
      rethrow;
    }
  }

  /// The caller's own redemptions (RLS limits rows to the caller).
  Future<List<BonusRedemption>> fetchMyRedemptions({int limit = 50}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('المستخدم غير مسجل الدخول');
    }
    try {
      final rows = await _client
          .from('bonus_redemptions')
          .select('id, product_id, quantity, bonus_value, status, created_at')
          .eq('account_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      _logSuccess('fetchMyRedemptions');
      return (rows as List)
          .map((r) => BonusRedemption.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logError('fetchMyRedemptions', e, st);
      rethrow;
    }
  }

  /// The caller's own withdrawals (RLS limits rows to the caller).
  Future<List<BonusWithdrawal>> fetchMyWithdrawals({int limit = 50}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('المستخدم غير مسجل الدخول');
    }
    try {
      final rows = await _client
          .from('bonus_withdrawals')
          .select(
            'id, amount, status, created_at, payment_method, rejection_reason',
          )
          .eq('account_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      _logSuccess('fetchMyWithdrawals');
      return (rows as List)
          .map((r) => BonusWithdrawal.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logError('fetchMyWithdrawals', e, st);
      rethrow;
    }
  }
}
