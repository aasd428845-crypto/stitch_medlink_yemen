import 'package:flutter/foundation.dart';

import '../models/branch.dart';
import '../models/inventory_item.dart';
import '../models/order.dart';
import '../models/user_profile.dart';
import 'branch_service.dart';
import 'catalog_service.dart';

/// State holder for every branch-manager screen: dashboard, orders,
/// inventory, invoices, and drivers. One controller, one branchId, shared
/// across all tabs so data fetched for one section (e.g. orders) can also
/// power the dashboard stat cards without a duplicate query.
class BranchController extends ChangeNotifier {
  BranchController(this._branchService, this._catalogService);

  final BranchService _branchService;
  final CatalogService _catalogService;

  String? _branchId;

  // ── Orders ───────────────────────────────────────────────────────────────
  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  String? _orderFilter; // null = all
  String? get orderFilter => _orderFilter;

  bool _isLoadingOrders = false;
  bool get isLoadingOrders => _isLoadingOrders;

  String? _ordersError;
  String? get ordersError => _ordersError;

  List<OrderModel> get filteredOrders => _orderFilter == null
      ? _orders
      : _orders.where((o) => o.status == _orderFilter).toList();

  int get newOrdersCount => _orders.where((o) => o.status == 'pending').length;
  int get inProgressOrdersCount =>
      _orders.where((o) => o.status == 'assigned' || o.status == 'in_progress').length;
  int get completedTodayCount {
    final today = DateTime.now();
    return _orders.where((o) {
      if (o.status != 'delivered' || o.createdAt == null) return false;
      final d = DateTime.tryParse(o.createdAt!);
      return d != null &&
          d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).length;
  }

  List<OrderModel> get recentOrders => _orders.take(5).toList();

  // ── Inventory ────────────────────────────────────────────────────────────
  List<InventoryItem> _inventory = [];
  List<InventoryItem> get inventory => _inventory;

  bool _isLoadingInventory = false;
  bool get isLoadingInventory => _isLoadingInventory;

  String? _inventoryError;
  String? get inventoryError => _inventoryError;

  // ── Invoices (delivered orders) ─────────────────────────────────────────
  List<OrderModel> _invoices = [];
  List<OrderModel> get invoices => _invoices;

  bool _isLoadingInvoices = false;
  bool get isLoadingInvoices => _isLoadingInvoices;

  String? _invoicesError;
  String? get invoicesError => _invoicesError;

  // ── Drivers ──────────────────────────────────────────────────────────────
  List<UserProfile> _drivers = [];
  List<UserProfile> get drivers => _drivers;

  bool _isLoadingDrivers = false;
  bool get isLoadingDrivers => _isLoadingDrivers;

  String? _driversError;
  String? get driversError => _driversError;

  /// Active (not delivered/cancelled) order count per driver id, derived
  /// from the already-fetched [_orders] list.
  int activeOrderCountFor(String driverId) => _orders
      .where((o) =>
          o.assignedDriverId == driverId &&
          o.status != 'delivered' &&
          o.status != 'cancelled')
      .length;

  bool isDriverBusy(String driverId) => activeOrderCountFor(driverId) > 0;

  // ── Transfer target branches ─────────────────────────────────────────────
  List<Branch> _otherBranches = [];
  List<Branch> get otherBranches => _otherBranches;

  bool _initialized = false;

  /// Call once when entering the branch manager shell.
  Future<void> initialize(String branchId) async {
    _branchId = branchId;
    if (_initialized) return;
    _initialized = true;
    await Future.wait([
      loadOrders(),
      loadInventory(),
      loadDrivers(),
      loadOtherBranches(),
    ]);
  }

  Future<void> loadOrders() async {
    if (_branchId == null) return;
    _isLoadingOrders = true;
    notifyListeners();
    try {
      _orders = await _branchService.fetchBranchOrders(_branchId!);
      _ordersError = null;
    } catch (e) {
      _ordersError = e.toString();
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  void setOrderFilter(String? status) {
    _orderFilter = status;
    notifyListeners();
  }

  Future<void> loadInventory() async {
    if (_branchId == null) return;
    _isLoadingInventory = true;
    notifyListeners();
    try {
      _inventory = await _catalogService.fetchInventoryForBranch(_branchId!);
      _inventoryError = null;
    } catch (e) {
      _inventoryError = e.toString();
    } finally {
      _isLoadingInventory = false;
      notifyListeners();
    }
  }

  Future<void> loadInvoices() async {
    if (_branchId == null) return;
    _isLoadingInvoices = true;
    notifyListeners();
    try {
      _invoices =
          await _branchService.fetchBranchOrders(_branchId!, status: 'delivered');
      _invoicesError = null;
    } catch (e) {
      _invoicesError = e.toString();
    } finally {
      _isLoadingInvoices = false;
      notifyListeners();
    }
  }

  Future<void> loadDrivers() async {
    if (_branchId == null) return;
    _isLoadingDrivers = true;
    notifyListeners();
    try {
      _drivers = await _branchService.fetchBranchDrivers(_branchId!);
      _driversError = null;
    } catch (e) {
      _driversError = e.toString();
    } finally {
      _isLoadingDrivers = false;
      notifyListeners();
    }
  }

  Future<void> loadOtherBranches() async {
    if (_branchId == null) return;
    try {
      _otherBranches = await _branchService.fetchOtherBranches(_branchId!);
      notifyListeners();
    } catch (_) {
      // Non-critical for the main flows — leave empty, transfer dialog will
      // show an empty state.
    }
  }

  Future<void> assignDriver(String orderId, String driverId) async {
    await _branchService.assignDriverToOrder(orderId, driverId);
    await loadOrders();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _branchService.updateOrderStatus(orderId, status);
    await loadOrders();
  }

  Future<void> transferOrder(String orderId, String targetBranchId) async {
    await _branchService.transferOrder(orderId, targetBranchId);
    await loadOrders();
  }

  Future<void> updateInventoryQuantity(String inventoryId, int quantity) async {
    await _branchService.updateInventoryQuantity(inventoryId, quantity);
    await loadInventory();
  }
}
