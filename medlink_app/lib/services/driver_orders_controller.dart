import 'package:flutter/foundation.dart';

import '../models/driver_commission.dart';
import '../models/order.dart';
import 'driver_orders_service.dart';

/// ChangeNotifier managing all state for the driver home screens:
/// - Tab 1: order list + status transitions
/// - Tab 2: earnings summary by month
class DriverOrdersController extends ChangeNotifier {
  DriverOrdersController(this._service);

  final DriverOrdersService _service;

  // ── Orders state ────────────────────────────────────────────────────────────

  List<OrderModel> _orders = [];
  bool _isLoadingOrders = false;
  String? _ordersError;

  /// null = show all; otherwise filters to the given status string.
  String? _orderFilter;

  List<OrderModel> get orders => _orders;
  bool get isLoadingOrders => _isLoadingOrders;
  String? get ordersError => _ordersError;
  String? get orderFilter => _orderFilter;

  List<OrderModel> get filteredOrders {
    if (_orderFilter == null) return _orders;
    return _orders.where((o) => o.status == _orderFilter).toList();
  }

  // ── Earnings state ───────────────────────────────────────────────────────────

  List<DriverCommission> _earnings = [];
  bool _isLoadingEarnings = false;
  String? _earningsError;

  final _now = DateTime.now();
  late int _selectedMonth = _now.month;
  late int _selectedYear = _now.year;

  List<DriverCommission> get earnings => _earnings;
  bool get isLoadingEarnings => _isLoadingEarnings;
  String? get earningsError => _earningsError;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  double get totalEarnings =>
      _earnings.fold(0.0, (sum, e) => sum + e.amount);

  int get deliveredCount => _earnings.length;

  // ── Orders actions ──────────────────────────────────────────────────────────

  Future<void> loadOrders() async {
    _isLoadingOrders = true;
    _ordersError = null;
    notifyListeners();

    try {
      _orders = await _service.fetchMyOrders();
    } catch (e) {
      _ordersError = e.toString();
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  void setOrderFilter(String? filter) {
    _orderFilter = filter;
    notifyListeners();
  }

  /// Advances the order status via the RPC. Returns true on success.
  /// On success: updates the order in the local list (optimistic sync).
  /// On failure: sets [ordersError].
  Future<bool> advanceOrderStatus(String orderId, String newStatus) async {
    _ordersError = null;
    notifyListeners();

    try {
      await _service.advanceOrderStatus(orderId, newStatus);
      // Sync the local list
      _orders = [
        for (final o in _orders)
          if (o.id == orderId) o.copyWith(status: newStatus) else o,
      ];
      notifyListeners();
      return true;
    } catch (e) {
      _ordersError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Earnings actions ─────────────────────────────────────────────────────────

  Future<void> loadEarnings() async {
    _isLoadingEarnings = true;
    _earningsError = null;
    notifyListeners();

    try {
      _earnings = await _service.fetchMyEarnings(
        month: _selectedMonth,
        year: _selectedYear,
      );
    } catch (e) {
      _earningsError = e.toString();
    } finally {
      _isLoadingEarnings = false;
      notifyListeners();
    }
  }

  /// Switches to a different month/year and reloads earnings.
  Future<void> setEarningsPeriod(int month, int year) async {
    _selectedMonth = month;
    _selectedYear = year;
    await loadEarnings();
  }
}
