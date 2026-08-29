import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/client_address.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/special_request.dart';
import 'order_service.dart';

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
  }) async {
    _setLoading(true);
    try {
      final newAddr = await _service.saveClientAddress(
        label: label,
        addressText: addressText,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
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
