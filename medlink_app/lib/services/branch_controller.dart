import 'package:flutter/foundation.dart';

import '../models/branch.dart';
import '../models/inventory_item.dart';
import '../models/invoice.dart';
import '../models/order.dart';
import '../models/user_profile.dart';
import 'branch_service.dart';
import 'catalog_service.dart';
import 'driver_service.dart';

/// State holder for every branch-manager screen: dashboard, orders,
/// inventory, invoices, and drivers. One controller, one branchId, shared
/// across all tabs so data fetched for one section (e.g. orders) can also
/// power the dashboard stat cards without a duplicate query.
class BranchController extends ChangeNotifier {
  BranchController(
    this._branchService,
    this._catalogService,
    this._driverService,
  );

  final BranchService _branchService;
  final CatalogService _catalogService;
  final DriverService _driverService;

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

  // ── Invoices (real `invoices` table) ────────────────────────────────────
  List<Invoice> _invoices = [];
  List<Invoice> get invoices => _invoices;

  bool _isLoadingInvoices = false;
  bool get isLoadingInvoices => _isLoadingInvoices;

  String? _invoicesError;
  String? get invoicesError => _invoicesError;

  List<Invoice> get activeInvoices =>
      _invoices.where((i) => i.status != 'cancelled').toList();

  double get invoicesTotal =>
      activeInvoices.fold<double>(0, (sum, i) => sum + i.amount);

  double get invoicesPaid => _invoices
      .where((i) => i.status == 'paid')
      .fold<double>(0, (sum, i) => sum + i.amount);

  int get overdueCount => _invoices.where((i) => i.isOverdue).length;

  int get pendingCount =>
      _invoices.where((i) => i.status == 'pending' && !i.isOverdue).length;

  // ── Clients (for standalone invoice creation) ────────────────────────────
  List<UserProfile> _clients = [];
  List<UserProfile> get clients => _clients;

  bool _isLoadingClients = false;
  bool get isLoadingClients => _isLoadingClients;

  String? _clientsError;
  String? get clientsError => _clientsError;

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
      loadInvoices(),
      loadCatalog(),
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
      final rows = await _branchService.fetchBranchInvoices(_branchId!);
      _invoices =
          rows.map((r) => Invoice.fromJson(r)).toList();
      _invoicesError = null;
    } catch (e) {
      _invoicesError = e.toString();
    } finally {
      _isLoadingInvoices = false;
      notifyListeners();
    }
  }

  Future<void> loadClients() async {
    _isLoadingClients = true;
    notifyListeners();
    try {
      _clients = await _branchService.fetchBranchClients();
      _clientsError = null;
    } catch (e) {
      _clientsError = e.toString();
    } finally {
      _isLoadingClients = false;
      notifyListeners();
    }
  }

  Future<void> createInvoice({
    required String clientId,
    required double amount,
    DateTime? dueDate,
  }) async {
    if (_branchId == null) return;
    await _branchService.createInvoice(
      branchId: _branchId!,
      clientId: clientId,
      amount: amount,
      dueDate: dueDate,
    );
    await loadInvoices();
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

  // ── Driver management (Phase 5 — via Edge Function) ───────────────────────

  /// Creates a new driver account under this branch. Refreshes the driver
  /// roster on success.
  Future<void> createDriver({
    required String name,
    required String email,
    required String phone,
    required String tempPassword,
  }) async {
    await _driverService.createDriver(
      name: name,
      email: email,
      phone: phone,
      tempPassword: tempPassword,
    );
    await loadDrivers();
  }

  /// Activates or suspends a driver. [status] = `'active'` or `'suspended'`.
  Future<void> updateDriverStatus(String driverId, String status) async {
    await _driverService.updateDriverStatus(driverId, status);
    await loadDrivers();
  }

  /// Resets a driver's password and sets requires_password_change = true.
  Future<void> resetDriverPassword(String driverId, String newPassword) async {
    await _driverService.resetDriverPassword(driverId, newPassword);
    await loadDrivers();
  }

  // ── Settings (Section 1 — settings modal) ─────────────────────────────────

  Branch? _branchInfo;
  Branch? get branchInfo => _branchInfo;

  Future<void> loadBranchInfo() async {
    if (_branchId == null) return;
    try {
      _branchInfo = await _branchService.fetchBranch(_branchId!);
      notifyListeners();
    } catch (_) {
      // Non-critical — the modal falls back to the profile's branch name.
    }
  }

  /// Saves editable branch info (name / governorate / address).
  Future<void> saveBranchInfo({
    required String name,
    String? governorate,
    String? addressText,
  }) async {
    if (_branchId == null) return;
    await _branchService.updateBranchInfo(
      _branchId!,
      name: name,
      governorate: governorate,
      addressText: addressText,
    );
    await loadBranchInfo();
  }

  // ── Notification preferences ──────────────────────────────────────────────
  bool _prefsNewOrders = true;
  bool _prefsLowStock = true;
  bool _prefsExpiryAlerts = true;
  bool _prefsDriverMessages = false;
  bool get prefsNewOrders => _prefsNewOrders;
  bool get prefsLowStock => _prefsLowStock;
  bool get prefsExpiryAlerts => _prefsExpiryAlerts;
  bool get prefsDriverMessages => _prefsDriverMessages;

  Future<void> loadNotificationPreferences(String userId) async {
    try {
      final row =
          await _branchService.fetchNotificationPreferences(userId);
      if (row == null) {
        _prefsNewOrders = true;
        _prefsLowStock = true;
        _prefsExpiryAlerts = true;
        _prefsDriverMessages = false;
      } else {
        _prefsNewOrders = row['new_orders'] as bool? ?? true;
        _prefsLowStock = row['low_stock'] as bool? ?? true;
        _prefsExpiryAlerts = row['expiry_alerts'] as bool? ?? true;
        _prefsDriverMessages = row['driver_messages'] as bool? ?? false;
      }
      notifyListeners();
    } catch (_) {
      // Defaults stay in place.
    }
  }

  Future<void> saveNotificationPreferences(String userId) async {
    await _branchService.updateNotificationPreferences(
      userId,
      newOrders: _prefsNewOrders,
      lowStock: _prefsLowStock,
      expiryAlerts: _prefsExpiryAlerts,
      driverMessages: _prefsDriverMessages,
    );
  }

  void setPrefNewOrders(bool v) {
    _prefsNewOrders = v;
    notifyListeners();
  }

  void setPrefLowStock(bool v) {
    _prefsLowStock = v;
    notifyListeners();
  }

  void setPrefExpiryAlerts(bool v) {
    _prefsExpiryAlerts = v;
    notifyListeners();
  }

  void setPrefDriverMessages(bool v) {
    _prefsDriverMessages = v;
    notifyListeners();
  }

  // ── Branch bank accounts ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _bankAccounts = [];
  List<Map<String, dynamic>> get bankAccounts => _bankAccounts;

  Future<void> loadBankAccounts() async {
    if (_branchId == null) return;
    try {
      _bankAccounts = await _branchService.fetchBranchBankAccounts(_branchId!);
      notifyListeners();
    } catch (_) {
      // Leave the previous list; the modal shows an empty state if needed.
    }
  }

  Future<void> addBankAccount({
    required String bankName,
    required String accountName,
    required String accountNumber,
  }) async {
    if (_branchId == null) return;
    await _branchService.addBranchBankAccount(
      _branchId!,
      bankName: bankName,
      accountName: accountName,
      accountNumber: accountNumber,
    );
    await loadBankAccounts();
  }

  Future<void> updateBankAccount(
    String accountId, {
    String? bankName,
    String? accountName,
    String? accountNumber,
  }) async {
    await _branchService.updateBranchBankAccount(
      accountId,
      bankName: bankName,
      accountName: accountName,
      accountNumber: accountNumber,
    );
    await loadBankAccounts();
  }

  Future<void> deleteBankAccount(String accountId) async {
    await _branchService.deleteBranchBankAccount(accountId);
    await loadBankAccounts();
  }

  Future<void> setDefaultBankAccount(String accountId) async {
    if (_branchId == null) return;
    await _branchService.setDefaultBranchBankAccount(_branchId!, accountId);
    await loadBankAccounts();
  }

  // ── Stock transfer between branches ───────────────────────────────────────
  Future<void> transferStock({
    required String productId,
    required String toBranchId,
    required int quantity,
  }) async {
    await _branchService.transferStockBetweenBranches(
      productId: productId,
      toBranchId: toBranchId,
      quantity: quantity,
    );
    await loadInventory();
  }

  // ── Order allocation (Section 2) ──────────────────────────────────────────

  /// Runs the atomic allocation RPC (migration 0009) and refreshes the order
  /// list + invoices afterwards.
  Future<String?> allocateOrder({
    required String orderId,
    required bool issueInvoice,
    DateTime? expectedDeliveryDate,
    required List<Map<String, dynamic>> allocations,
  }) async {
    final invoiceId = await _branchService.allocateOrder(
      orderId: orderId,
      issueInvoice: issueInvoice,
      expectedDeliveryDate: expectedDeliveryDate,
      allocations: allocations,
    );
    await loadOrders();
    await loadInvoices();
    return invoiceId;
  }

  /// Inventory rows for the given products at all other branches — the smart
  /// allocation engine uses this to locate a supplier for missing stock.
  Future<List<Map<String, dynamic>>> stockAcrossBranches(
      List<String> productIds) async {
    if (_branchId == null) return [];
    return _branchService.fetchStockAcrossBranches(
      productIds,
      excludeBranchId: _branchId!,
    );
  }

  // ── Full catalog inventory (Section 4) ────────────────────────────────────
  List<CatalogRow> _catalog = [];
  List<CatalogRow> get catalog => _catalog;

  bool _isLoadingCatalog = false;
  bool get isLoadingCatalog => _isLoadingCatalog;

  String? _catalogError;
  String? get catalogError => _catalogError;

  /// Merges the full active product catalog with the branch's aggregate
  /// quantity (`inventory`) and the nearest expiry / reorder level
  /// (`warehouse_inventory`) into a single table for the inventory screen.
  Future<void> loadCatalog() async {
    if (_branchId == null) return;
    _isLoadingCatalog = true;
    notifyListeners();
    try {
      final products = await _branchService.fetchAllProducts();
      final warehouse = await _branchService.fetchBranchWarehouse(_branchId!);

      final invByProduct = {
        for (final i in _inventory) i.productId: i.quantity,
      };
      final nearestExpiry = <String, String>{};
      final reorderLevel = <String, int>{};
      for (final w in warehouse) {
        final pid = w['product_id'] as String;
        final exp = w['expiry_date'] as String?;
        if (exp != null) {
          final cur = nearestExpiry[pid];
          if (cur == null || exp.compareTo(cur) < 0) nearestExpiry[pid] = exp;
        }
        reorderLevel[pid] = w['reorder_level'] as int? ?? 5;
      }

      _catalog = [
        for (final p in products)
          CatalogRow(
            productId: p['id'] as String,
            name: p['name'] as String? ?? '—',
            unit: p['unit'] as String? ?? '',
            quantity: invByProduct[p['id']] ?? 0,
            nearestExpiry: nearestExpiry[p['id']],
            reorderLevel: reorderLevel[p['id']] ?? 5,
            unitPrice: ((p['unit_price'] as num?) ?? 0).toDouble(),
          ),
      ]..sort((a, b) => a.name.compareTo(b.name));
      _catalogError = null;
    } catch (e) {
      _catalogError = e.toString();
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  /// Adds a new stock batch for [productId] and reloads the catalog.
  Future<void> addStockBatch({
    required String productId,
    required int quantity,
    DateTime? expiryDate,
  }) async {
    if (_branchId == null) return;
    await _branchService.addStockBatch(
      branchId: _branchId!,
      productId: productId,
      quantity: quantity,
      expiryDate: expiryDate,
    );
    await loadCatalog();
  }

  /// Sets the aggregate quantity for [productId] (creating the `inventory`
  /// row first when the branch has no row for this product yet).
  Future<void> setProductQuantity(String productId, int quantity) async {
    final row =
        _inventory.where((i) => i.productId == productId).firstOrNull;
    if (row == null) {
      if (_branchId == null) return;
      await _branchService.createInventoryRow(_branchId!, productId);
      await loadInventory();
      final created =
          _inventory.where((i) => i.productId == productId).firstOrNull;
      if (created != null) {
        await _branchService.updateInventoryQuantity(created.id, quantity);
      }
    } else {
      await _branchService.updateInventoryQuantity(row.id, quantity);
    }
    await loadCatalog();
  }

  // ── Statistics (Section 6 — dashboard bento, all real data) ───────────────

  static DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);
  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Sum of non-cancelled invoices created in the current month.
  double get salesThisMonth {
    final start = _monthStart(DateTime.now());
    return activeInvoices
        .where((i) {
          final d = DateTime.tryParse(i.createdAt ?? '');
          return d != null && !d.isBefore(start);
        })
        .fold<double>(0, (sum, i) => sum + i.amount);
  }

  /// Same sum for the previous month — basis of the growth percentage.
  double get salesLastMonth {
    final now = DateTime.now();
    final thisStart = _monthStart(now);
    final lastStart = _monthStart(DateTime(now.year, now.month - 1, 1));
    return activeInvoices
        .where((i) {
          final d = DateTime.tryParse(i.createdAt ?? '');
          return d != null && !d.isBefore(lastStart) && d.isBefore(thisStart);
        })
        .fold<double>(0, (sum, i) => sum + i.amount);
  }

  /// +N% vs previous month (0 when no baseline).
  int get salesGrowthPercent {
    if (salesLastMonth <= 0) return 0;
    return ((salesThisMonth - salesLastMonth) / salesLastMonth * 100).round();
  }

  /// Delivered orders in the current month.
  int get completedThisMonth {
    final start = _monthStart(DateTime.now());
    return _orders
        .where((o) => o.status == 'delivered' &&
            (DateTime.tryParse(o.deliveredAt ?? o.createdAt ?? '') ?? DateTime.now())
                .isAfter(start))
        .length;
  }

  /// Allocation accuracy = share of delivered orders that arrived on or
  /// before their scheduled date (or had no deadline at all).
  int get allocationAccuracyPercent {
    final delivered =
        _orders.where((o) => o.status == 'delivered' && o.deliveredAt != null).toList();
    if (delivered.isEmpty) return 100;
    var onTime = 0;
    for (final o in delivered) {
      final deliveredDay = DateTime.tryParse(o.deliveredAt!);
      final scheduled = DateTime.tryParse(o.scheduledDeliveryAt ?? '');
      if (scheduled == null || (deliveredDay != null && !deliveredDay.isAfter(scheduled))) {
        onTime++;
      }
    }
    return (onTime / delivered.length * 100).round();
  }

  /// Deliveries per day for the last 7 days (from `delivered_at`).
  List<({DateTime day, int count})> get weeklyDeliveries {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      final count = _orders.where((o) {
        final d = DateTime.tryParse(o.deliveredAt ?? '');
        return d != null && _dayOnly(d) == day;
      }).length;
      return (day: day, count: count);
    });
    return days;
  }

  /// Top drivers by completed deliveries (name + count).
  List<({String name, int count})> get topDrivers {
    final counts = <String, int>{};
    for (final o in _orders) {
      if (o.status == 'delivered' && o.assignedDriver?.name?.isNotEmpty == true) {
        counts.update(o.assignedDriver!.name!, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in sorted.take(3))
        (name: e.key, count: e.value),
    ];
  }

  /// Share of invoice value actually paid — the financial progress circle.
  int get paidRatioPercent {
    final total = activeInvoices.fold<double>(0, (s, i) => s + i.amount);
    if (total <= 0) return 0;
    return (invoicesPaid / total * 100).round();
  }

  /// Inventory alerts from the full catalog: low stock + expiring soon.
  int get lowStockCount =>
      _catalog.where((r) => r.isLowStock || r.isOutOfStock).length;

  int get expiringSoonCount => _catalog.where((r) => r.isExpiringSoon).length;

  /// Loads the data behind the dashboard statistics (invoices + catalog).
  Future<void> loadStats() => Future.wait([loadInvoices(), loadCatalog()]);
}

/// One row in the full-catalog inventory table (Section 4).
class CatalogRow {
  const CatalogRow({
    required this.productId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.nearestExpiry,
    required this.reorderLevel,
    required this.unitPrice,
  });

  final String productId;
  final String name;
  final String unit;
  final int quantity;
  final String? nearestExpiry;
  final int reorderLevel;
  final double unitPrice;

  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => !isOutOfStock && quantity <= reorderLevel;

  /// True when the nearest expiry is within 30 days (or already past).
  bool get isExpiringSoon {
    final exp = nearestExpiry;
    if (exp == null) return false;
    final d = DateTime.tryParse(exp);
    if (d == null) return false;
    return d.difference(DateTime.now()).inDays <= 30;
  }
}
