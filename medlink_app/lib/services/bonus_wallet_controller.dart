import 'package:flutter/foundation.dart';
import 'dart:math' show Random;

import 'bonus_wallet_service.dart';

/// Generates idempotency keys for financial submits. Combines wall-clock
/// microseconds with 64 cryptographic random bits: retries of the same
/// logical operation reuse the stored key, while distinct operations
/// always mint a fresh one. No user input, no amounts, no timestamps alone.
String newIdempotencyKey() {
  final random = Random.secure();
  final hi = random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
  final lo = random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
  return 'client-${DateTime.now().microsecondsSinceEpoch}-$hi$lo';
}

/// Builds the logical-operation signature for an order-discount submit so
/// retries of the same (order, amount) reuse one idempotency key while any
/// parameter change starts a fresh logical operation.
String discountOperationSig(String orderId, double amount) =>
    '$orderId|$amount';

/// State holder for the client Bonus wallet and history.
/// All money figures come from `BonusWalletService` (RPC + RLS);
/// this controller only tracks loading/error state.
class BonusWalletController extends ChangeNotifier {
  BonusWalletController(this._service);

  final BonusWalletService _service;

  BonusFunds? _funds;
  BonusFunds? get funds => _funds;

  List<BonusLedgerEntry> _entries = [];
  List<BonusLedgerEntry> get entries => _entries;

  List<BonusRedemption> _redemptions = [];
  List<BonusRedemption> get redemptions => _redemptions;

  List<BonusWithdrawal> _withdrawals = [];
  List<BonusWithdrawal> get withdrawals => _withdrawals;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  // Logical-operation idempotency: a key is minted once per distinct submit
  // and retained across retries of the SAME operation, so a timeout retry
  // can never mint a second financial row server-side. Any change to the
  // operation parameters starts a new logical operation with a fresh key.
  // Keys are cleared only on success (or explicit discard).
  String? _redemptionKey;
  String _redemptionSig = '';
  String? _withdrawalKey;
  String _withdrawalSig = '';
  String? _discountKey;
  String _discountSig = '';
  String? _discountRemovalKey;
  String _discountRemovalSig = '';

  String? _error;
  String? get error => _error;

  Future<void> loadWallet() async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _service.fetchMyFunds(),
        _service.fetchMyLedger(limit: 20),
      ]);
      _funds = results[0] as BonusFunds;
      _entries = results[1] as List<BonusLedgerEntry>;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadHistory({int limit = 100}) async {
    _setLoading(true);
    try {
      _entries = await _service.fetchMyLedger(limit: limit);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMyRequests() async {
    _setLoading(true);
    try {
      final results = await Future.wait([
        _service.fetchMyRedemptions(),
        _service.fetchMyWithdrawals(),
      ]);
      _redemptions = results[0] as List<BonusRedemption>;
      _withdrawals = results[1] as List<BonusWithdrawal>;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Submits a redemption; returns the new id. Guards double-submit via
  /// [_isSubmitting]; server enforces funds/product/idempotency.
  Future<String?> submitRedemption({
    required String productId,
    required int quantity,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    notifyListeners();
    try {
      final sig = '$productId|$quantity';
      if (_redemptionKey == null || _redemptionSig != sig) {
        _redemptionKey = newIdempotencyKey();
        _redemptionSig = sig;
      }
      final id = await _service.requestRedemption(
        productId: productId,
        quantity: quantity,
        idempotencyKey: _redemptionKey,
      );
      _redemptionKey = null;
      _redemptionSig = '';
      _error = null;
      await loadWallet();
      await loadMyRequests();
      return id;
    } catch (e) {
      // Key retained: UI retry reuses it, so the server dedupes.
      _error = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Discards the pending redemption attempt (e.g. user starts over with
  /// different parameters outside the submit flow). Next submit mints fresh.
  void discardPendingRedemption() {
    _redemptionKey = null;
    _redemptionSig = '';
  }

  /// Submits a withdrawal; returns the new id. Limits enforced server-side.
  Future<String?> submitWithdrawal({
    required double amount,
    String? method,
    String? notes,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    notifyListeners();
    try {
      final sig = '$amount|${method ?? ''}|${notes ?? ''}';
      if (_withdrawalKey == null || _withdrawalSig != sig) {
        _withdrawalKey = newIdempotencyKey();
        _withdrawalSig = sig;
      }
      final id = await _service.requestWithdrawal(
        amount: amount,
        method: method,
        notes: notes,
        idempotencyKey: _withdrawalKey,
      );
      _withdrawalKey = null;
      _withdrawalSig = '';
      _error = null;
      await loadWallet();
      await loadMyRequests();
      return id;
    } catch (e) {
      // Key retained: UI retry reuses it, so the server dedupes.
      _error = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Discards the pending withdrawal attempt. Next submit mints fresh.
  void discardPendingWithdrawal() {
    _withdrawalKey = null;
    _withdrawalSig = '';
  }

  Future<void> cancelRedemption(String id) async {
    try {
      await _service.cancelRedemption(id);
      _error = null;
      await loadMyRequests();
      await loadWallet();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> cancelWithdrawal(String id) async {
    try {
      await _service.cancelWithdrawal(id);
      _error = null;
      await loadMyRequests();
      await loadWallet();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  /// Applies bonus as a discount on a pending order; returns the new
  /// ORDER_DISCOUNT ledger id. Guards double-submit via [_isSubmitting];
  /// server enforces eligibility, caps, funding scope and idempotency.
  /// Retries reuse [_discountKey] so a timeout retry can never post twice.
  Future<String?> submitOrderDiscount({
    required String orderId,
    required double amount,
  }) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    notifyListeners();
    try {
      final sig = discountOperationSig(orderId, amount);
      if (_discountKey == null || _discountSig != sig) {
        _discountKey = newIdempotencyKey();
        _discountSig = sig;
      }
      final id = await _service.requestOrderDiscount(
        orderId: orderId,
        amount: amount,
        idempotencyKey: _discountKey,
      );
      _discountKey = null;
      _discountSig = '';
      _error = null;
      await loadWallet();
      await loadHistory();
      return id;
    } catch (e) {
      // Key retained: UI retry reuses it, so the server dedupes.
      _error = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Discards the pending discount attempt (e.g. user edits the amount
  /// outside the submit flow). Next submit mints a fresh key.
  void discardPendingDiscount() {
    _discountKey = null;
    _discountSig = '';
  }

  /// Removes the caller's applied order discount (compensating reversal
  /// decided server-side from the discount-time snapshot).
  Future<String?> removeOrderDiscount({required String orderId}) async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    notifyListeners();
    try {
      const op = 'remove';
      final sig = '$orderId|$op';
      if (_discountRemovalKey == null || _discountRemovalSig != sig) {
        _discountRemovalKey = newIdempotencyKey();
        _discountRemovalSig = sig;
      }
      final id = await _service.cancelOrderDiscount(
        orderId: orderId,
        idempotencyKey: _discountRemovalKey,
      );
      _discountRemovalKey = null;
      _discountRemovalSig = '';
      _error = null;
      await loadWallet();
      await loadHistory();
      return id;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
