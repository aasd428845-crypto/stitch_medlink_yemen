import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/client_address.dart';
import '../models/order.dart';
import '../models/order_cancellation.dart';
import '../models/product.dart';
import '../models/special_request.dart';
import 'bonus_wallet_controller.dart' show newIdempotencyKey;
import 'order_service.dart';

class MissingDeliveryAddressException implements Exception {
  const MissingDeliveryAddressException();
}

/// State holder for addresses, order submission, and client order history.
class OrderController extends ChangeNotifier {
  OrderController(this._service);

  final OrderService _service;

  List<ClientAddress> _addresses = [];
  List<ClientAddress> get addresses => _addresses;

  ClientAddress? _selectedAddress;
  ClientAddress? get selectedAddress => _selectedAddress;

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  List<Product> _reorderProducts = [];
  List<Product> get reorderProducts => _reorderProducts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadAddresses() async {
    _setLoading(true);
    try {
      _addresses = await _service.fetchClientAddresses();
      if (_addresses.isNotEmpty && _selectedAddress == null) {
        _selectedAddress = _addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => _addresses.first,
        );
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAddress(String addressId) async {
    await _service.deleteClientAddress(addressId);
    await loadAddresses();
  }

  void selectAddress(ClientAddress address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<ClientAddress> saveAddress({
    required String label,
    required String addressText,
    double? latitude,
    double? longitude,
    bool isDefault = false,
    // Extended fields
    String? ownerName,
    String? phone,
    String? altPhone,
    String? landmark,
    String? governorate,
    String? city,
    String? district,
  }) async {
    _setLoading(true);
    try {
      final newAddr = await _service.saveClientAddress(
        label: label,
        addressText: addressText,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
        ownerName: ownerName,
        phone: phone,
        altPhone: altPhone,
        landmark: landmark,
        governorate: governorate,
        city: city,
        district: district,
      );
      await loadAddresses();
      _selectedAddress = newAddr;
      notifyListeners();
      return newAddr;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadClientOrders() async {
    _setLoading(true);
    try {
      _orders = await _service.fetchClientOrders();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Loads the products the client most recently ordered, for the
  /// "quick reorder" section. Failures are non-critical and keep the list empty.
  Future<void> loadReorderProducts() async {
    try {
      final products = await _service.fetchRecentReorderProducts();
      if (_reorderProducts.length == products.length &&
          _reorderProducts.map((p) => p.id).toSet().length ==
              products.map((p) => p.id).toSet().length) {
        return;
      }
      _reorderProducts = products;
      notifyListeners();
    } catch (_) {
      // Non-critical — leave the reorder list empty.
    }
  }

  Future<OrderModel> submitOrder({
    required List<CartItem> cartItems,
    String? notes,
  }) async {
    if (_selectedAddress == null) {
      throw const MissingDeliveryAddressException();
    }
    _setLoading(true);
    try {
      final created = await _service.createOrder(
        deliveryAddressId: _selectedAddress?.id,
        items: cartItems,
        notes: notes,
      );
      await loadClientOrders();
      _error = null;
      return created;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  bool _isCancelling = false;
  bool get isCancelling => _isCancelling;

  String? _cancelError;
  String? get cancelError => _cancelError;

  // Logical-operation idempotency, mirroring BonusWalletController: one key
  // per (order, reason), retained across retries of the same operation so a
  // timeout retry can never post a second financial effect server-side.
  // Keys clear only on success (or explicit discard).
  String? _cancelKey;
  String _cancelSig = '';

  List<OrderCancellation> _cancellationHistory = [];
  List<OrderCancellation> get cancellationHistory => _cancellationHistory;

  /// Cancels the caller's own order through the financial cancellation RPC.
  /// Returns the reversal ledger id (null when no discount existed). Guards
  /// double-submit; the server enforces ownership, pending state (H1),
  /// policy snapshot, and idempotency.
  Future<String?> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    if (_isCancelling) return null;
    _isCancelling = true;
    _cancelError = null;
    notifyListeners();
    try {
      final sig = '$orderId|$reason';
      if (_cancelKey == null || _cancelSig != sig) {
        _cancelKey = newIdempotencyKey();
        _cancelSig = sig;
      }
      final id = await _service.cancelOrder(
        orderId: orderId,
        reason: reason,
        idempotencyKey: _cancelKey,
      );
      _cancelKey = null;
      _cancelSig = '';
      await loadClientOrders();
      await loadCancellationHistory(orderId);
      return id;
    } catch (e) {
      // Key retained: retry reuses it, so the server dedupes.
      _cancelError = e.toString();
      rethrow;
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }

  /// Discards the pending cancellation attempt. Next submit mints fresh.
  void discardPendingCancellation() {
    _cancelKey = null;
    _cancelSig = '';
    _cancelError = null;
  }

  /// Loads the cancellation history for one order (read-only; RLS-scoped).
  Future<void> loadCancellationHistory(String orderId) async {
    try {
      _cancellationHistory = await _service.fetchOrderCancellationHistory(
        orderId,
      );
      notifyListeners();
    } catch (e) {
      _cancelError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  /// Submits a special request for a product not in the catalog.
  Future<SpecialRequest> createSpecialRequest({
    required String productName,
    required int quantity,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      final created = await _service.createSpecialRequest(
        productName: productName,
        quantity: quantity,
        notes: notes,
      );
      _error = null;
      return created;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}
