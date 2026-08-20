import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/branch.dart';
import '../models/order.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';

/// Single source of truth for branch-manager operations: incoming orders,
/// driver assignment/transfer, and the branch's driver roster.
///
/// Architecture rules (CLAUDE.md §3):
/// - Every Supabase call logs through SUPABASE_DEBUG.
/// - Success is only reported after a verified real response.
/// - No logic is duplicated — inventory reads reuse CatalogService via the
///   controller; this service only owns what's unique to the branch role.
class BranchService {
  BranchService(this._client);

  final SupabaseClient _client;

  void _logError(String fn, Object error, [StackTrace? st]) {
    debugPrint(
      '[${AppConstants.supabaseDebugTag}] BranchService.$fn failed: $error'
      '${st != null ? '\n$st' : ''}',
    );
  }

  void _logSuccess(String fn) {
    debugPrint('[${AppConstants.supabaseDebugTag}] BranchService.$fn OK');
  }

  static const _orderSelect = '*, '
      'delivery_address:client_addresses(*), '
      'client:users!orders_client_id_fkey(*), '
      'assigned_driver:users!orders_assigned_driver_id_fkey(*)';

  /// Orders currently routed to [branchId]. Optionally filtered by [status].
  Future<List<OrderModel>> fetchBranchOrders(
    String branchId, {
    String? status,
  }) async {
    try {
      var query =
          _client.from('orders').select(_orderSelect).eq('branch_id', branchId);
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }
      final rows = await query.order('created_at', ascending: false);
      _logSuccess('fetchBranchOrders');
      return (rows as List)
          .map((r) => OrderModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logError('fetchBranchOrders', e, st);
      rethrow;
    }
  }

  /// Full order detail (with items + client + driver) for the branch manager
  /// order-detail screen.
  Future<OrderModel?> fetchOrderDetailForBranch(String orderId) async {
    try {
      final row = await _client
          .from('orders')
          .select('$_orderSelect, items:order_items(*, product:products(*))')
          .eq('id', orderId)
          .maybeSingle();
      _logSuccess('fetchOrderDetailForBranch');
      if (row == null) return null;
      return OrderModel.fromJson(row);
    } catch (e, st) {
      _logError('fetchOrderDetailForBranch', e, st);
      rethrow;
    }
  }

  // ── Driver Ratings ─────────────────────────────────────────────────────────

  /// Returns average rating and total count for [driverId].
  /// Returns `{average: null, count: 0}` when no ratings exist yet.
  Future<({double? average, int count})> fetchDriverRatingSummary(
      String driverId) async {
    try {
      final rows = await _client
          .from('driver_ratings')
          .select('rating')
          .eq('driver_id', driverId);
      _logSuccess('fetchDriverRatingSummary');
      final list = rows as List;
      if (list.isEmpty) return (average: null, count: 0);
      final sum =
          list.fold<int>(0, (s, r) => s + (r['rating'] as int));
      final avg = sum / list.length;
      return (average: avg, count: list.length);
    } catch (e, st) {
      _logError('fetchDriverRatingSummary', e, st);
      rethrow;
    }
  }

  /// Assigns [driverId] to [orderId] and advances its status to `assigned`.
  Future<void> assignDriverToOrder(String orderId, String driverId) async {
    try {
      await _client.from('orders').update({
        'assigned_driver_id': driverId,
        'status': 'assigned',
      }).eq('id', orderId);
      _logSuccess('assignDriverToOrder');
    } catch (e, st) {
      _logError('assignDriverToOrder', e, st);
      rethrow;
    }
  }

  /// Updates the order status directly (accept/reject/mark in-progress/
  /// delivered/cancelled).
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _client.from('orders').update({'status': status}).eq('id', orderId);
      _logSuccess('updateOrderStatus');
    } catch (e, st) {
      _logError('updateOrderStatus', e, st);
      rethrow;
    }
  }

  /// Moves an order to another branch. The receiving branch starts fresh:
  /// driver unassigned and status reset to `pending`.
  Future<void> transferOrder(String orderId, String targetBranchId) async {
    try {
      await _client.from('orders').update({
        'branch_id': targetBranchId,
        'assigned_driver_id': null,
        'status': 'pending',
      }).eq('id', orderId);
      _logSuccess('transferOrder');
    } catch (e, st) {
      _logError('transferOrder', e, st);
      rethrow;
    }
  }

  /// Sets the quantity for an existing `inventory` row.
  Future<void> updateInventoryQuantity(
    String inventoryId,
    int quantity,
  ) async {
    try {
      await _client.from('inventory').update({
        'quantity': quantity,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', inventoryId);
      _logSuccess('updateInventoryQuantity');
    } catch (e, st) {
      _logError('updateInventoryQuantity', e, st);
      rethrow;
    }
  }

  /// Creates a new `inventory` row for a product with no stock entry yet at
  /// this branch (initial quantity 0, then editable like any other row).
  Future<void> createInventoryRow(String branchId, String productId) async {
    try {
      await _client.from('inventory').insert({
        'branch_id': branchId,
        'product_id': productId,
        'quantity': 0,
      });
      _logSuccess('createInventoryRow');
    } catch (e, st) {
      _logError('createInventoryRow', e, st);
      rethrow;
    }
  }

  /// Drivers who belong to [branchId].
  Future<List<UserProfile>> fetchBranchDrivers(String branchId) async {
    try {
      final rows = await _client
          .from('users')
          .select()
          .eq('role', 'driver')
          .eq('branch_id', branchId)
          .order('name');
      _logSuccess('fetchBranchDrivers');
      return (rows as List)
          .map((r) => UserProfile.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logError('fetchBranchDrivers', e, st);
      rethrow;
    }
  }

  /// All branches except [excludeBranchId] — used to populate the "transfer
  /// order" destination picker.
  Future<List<Branch>> fetchOtherBranches(String excludeBranchId) async {
    try {
      final rows = await _client
          .from('branches')
          .select()
          .neq('id', excludeBranchId)
          .order('name');
      _logSuccess('fetchOtherBranches');
      return (rows as List)
          .map((r) => Branch.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logError('fetchOtherBranches', e, st);
      rethrow;
    }
  }

  // ── Branch settings (Section 1 — settings modal) ──────────────────────────

  /// Full row of the manager's own branch.
  Future<Branch?> fetchBranch(String branchId) async {
    try {
      final row = await _client
          .from('branches')
          .select()
          .eq('id', branchId)
          .maybeSingle();
      _logSuccess('fetchBranch');
      if (row == null) return null;
      return Branch.fromJson(row);
    } catch (e, st) {
      _logError('fetchBranch', e, st);
      rethrow;
    }
  }

  /// Updates editable branch info (name / governorate / address). The
  /// `branches_manager_update_own` policy (migration 0010) allows a manager
  /// to edit only their own branch row.
  Future<void> updateBranchInfo(
    String branchId, {
    required String name,
    String? governorate,
    String? addressText,
  }) async {
    try {
      await _client.from('branches').update({
        'name': name,
        if (governorate != null) 'governorate': governorate,
        if (addressText != null) 'address_text': addressText,
      }).eq('id', branchId);
      _logSuccess('updateBranchInfo');
    } catch (e, st) {
      _logError('updateBranchInfo', e, st);
      rethrow;
    }
  }

  /// Notification toggles for [userId]; returns the DB row or `null` when the
  /// user never saved preferences (the caller then uses the defaults).
  Future<Map<String, dynamic>?> fetchNotificationPreferences(
      String userId) async {
    try {
      final row = await _client
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      _logSuccess('fetchNotificationPreferences');
      return row;
    } catch (e, st) {
      _logError('fetchNotificationPreferences', e, st);
      rethrow;
    }
  }

  /// Upserts the four notification toggles for [userId].
  Future<void> updateNotificationPreferences(
    String userId, {
    required bool newOrders,
    required bool lowStock,
    required bool expiryAlerts,
    required bool driverMessages,
  }) async {
    try {
      await _client.from('notification_preferences').upsert({
        'user_id': userId,
        'new_orders': newOrders,
        'low_stock': lowStock,
        'expiry_alerts': expiryAlerts,
        'driver_messages': driverMessages,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _logSuccess('updateNotificationPreferences');
    } catch (e, st) {
      _logError('updateNotificationPreferences', e, st);
      rethrow;
    }
  }

  // ── Branch bank accounts (Section 1 — settings modal) ─────────────────────

  /// All payment accounts registered for [branchId].
  Future<List<Map<String, dynamic>>> fetchBranchBankAccounts(
      String branchId) async {
    try {
      final rows = await _client
          .from('branch_bank_accounts')
          .select()
          .eq('branch_id', branchId)
          .order('is_default', ascending: false)
          .order('created_at');
      _logSuccess('fetchBranchBankAccounts');
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      _logError('fetchBranchBankAccounts', e, st);
      rethrow;
    }
  }

  Future<void> addBranchBankAccount(
    String branchId, {
    required String bankName,
    required String accountName,
    required String accountNumber,
  }) async {
    try {
      await _client.from('branch_bank_accounts').insert({
        'branch_id': branchId,
        'bank_name': bankName,
        'account_name': accountName,
        'account_number': accountNumber,
      });
      _logSuccess('addBranchBankAccount');
    } catch (e, st) {
      _logError('addBranchBankAccount', e, st);
      rethrow;
    }
  }

  Future<void> updateBranchBankAccount(
    String accountId, {
    String? bankName,
    String? accountName,
    String? accountNumber,
  }) async {
    try {
      await _client.from('branch_bank_accounts').update({
        if (bankName != null) 'bank_name': bankName,
        if (accountName != null) 'account_name': accountName,
        if (accountNumber != null) 'account_number': accountNumber,
      }).eq('id', accountId);
      _logSuccess('updateBranchBankAccount');
    } catch (e, st) {
      _logError('updateBranchBankAccount', e, st);
      rethrow;
    }
  }

  Future<void> deleteBranchBankAccount(String accountId) async {
    try {
      await _client
          .from('branch_bank_accounts')
          .delete()
          .eq('id', accountId);
      _logSuccess('deleteBranchBankAccount');
    } catch (e, st) {
      _logError('deleteBranchBankAccount', e, st);
      rethrow;
    }
  }

  /// Marks [accountId] as the default account for its branch (the partial
  /// unique index in migration 0010 guarantees a single default per branch).
  Future<void> setDefaultBranchBankAccount(
      String branchId, String accountId) async {
    try {
      await _client.rpc('branch_set_default_bank_account', params: {
        'p_account_id': accountId,
        'p_branch_id': branchId,
      });
      _logSuccess('setDefaultBranchBankAccount');
    } catch (e, st) {
      _logError('setDefaultBranchBankAccount', e, st);
      rethrow;
    }
  }

  // ── Stock transfer between branches (Section 1 — RPC) ─────────────────────

  /// Atomically moves [quantity] units of [productId] from the current
  /// manager's branch to [toBranchId] (migration 0010 RPC). Throws with a
  /// readable message when stock is insufficient.
  Future<void> transferStockBetweenBranches({
    required String productId,
    required String toBranchId,
    required int quantity,
  }) async {
    try {
      await _client.rpc('branch_transfer_stock_between_branches', params: {
        'p_product_id': productId,
        'p_to_branch_id': toBranchId,
        'p_quantity': quantity,
      });
      _logSuccess('transferStockBetweenBranches');
    } catch (e, st) {
      _logError('transferStockBetweenBranches', e, st);
      rethrow;
    }
  }

  // ── Order allocation (Section 2 — smart allocation modal) ─────────────────

  /// Inventory rows for [productIds] at every branch except
  /// [excludeBranchId] — the smart engine uses this to find a source branch
  /// that can supply a missing quantity (RLS: inventory is readable by any
  /// authenticated user, quantities included for managers).
  Future<List<Map<String, dynamic>>> fetchStockAcrossBranches(
    List<String> productIds, {
    required String excludeBranchId,
  }) async {
    try {
      if (productIds.isEmpty) return [];
      final rows = await _client
          .from('inventory')
          .select('product_id, branch_id, quantity')
          .inFilter('product_id', productIds)
          .neq('branch_id', excludeBranchId)
          .gt('quantity', 0);
      _logSuccess('fetchStockAcrossBranches');
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      _logError('fetchStockAcrossBranches', e, st);
      rethrow;
    }
  }

  /// Runs the atomic allocation RPC `branch_allocate_order` (migration 0009):
  /// validates stock, deducts quantities, marks the order assigned, sets the
  /// expected delivery date and issues an invoice. Returns the invoice id
  /// (or null when [issueInvoice] is false).
  Future<String?> allocateOrder({
    required String orderId,
    required bool issueInvoice,
    DateTime? expectedDeliveryDate,
    required List<Map<String, dynamic>> allocations,
  }) async {
    try {
      final result = await _client.rpc('branch_allocate_order', params: {
        'p_order_id': orderId,
        'p_issue_invoice': issueInvoice,
        'p_expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
        'p_allocations': allocations,
      });
      _logSuccess('allocateOrder');
      return result as String?;
    } catch (e, st) {
      _logError('allocateOrder', e, st);
      rethrow;
    }
  }

  // ── Real invoices (Section 3 — invoices ledger) ───────────────────────────

  static const _invoiceSelect = '*, client:users!invoices_client_id_fkey(*)';

  /// The branch's invoices from the real `invoices` table (migration 0004 +
  /// 0009), newest first, with the client's name joined.
  Future<List<Map<String, dynamic>>> fetchBranchInvoices(String branchId) async {
    try {
      final rows = await _client
          .from('invoices')
          .select(_invoiceSelect)
          .eq('branch_id', branchId)
          .order('created_at', ascending: false);
      _logSuccess('fetchBranchInvoices');
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      _logError('fetchBranchInvoices', e, st);
      rethrow;
    }
  }

  /// Creates a standalone invoice for the branch (policy
  /// `invoices_branch_manager_insert`, migration 0009).
  Future<void> createInvoice({
    required String branchId,
    required String clientId,
    required double amount,
    DateTime? dueDate,
  }) async {
    try {
      await _client.from('invoices').insert({
        'branch_id': branchId,
        'client_id': clientId,
        'amount': amount,
        'status': 'pending',
        if (dueDate != null) 'due_date': dueDate.toIso8601String(),
      });
      _logSuccess('createInvoice');
    } catch (e, st) {
      _logError('createInvoice', e, st);
      rethrow;
    }
  }

  /// Clients the branch manager may bill (RLS policy 0004 lets branch
  /// managers read all clients).
  Future<List<UserProfile>> fetchBranchClients() async {
    try {
      final rows = await _client
          .from('users')
          .select()
          .eq('role', 'client')
          .order('name');
      _logSuccess('fetchBranchClients');
      return (rows as List)
          .map((r) => UserProfile.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logError('fetchBranchClients', e, st);
      rethrow;
    }
  }

  // ── Full catalog inventory (Section 4 — inventory screen) ─────────────────

  /// Every active product in the catalog (the full-table view of Section 4).
  Future<List<Map<String, dynamic>>> fetchAllProducts() async {
    try {
      final rows = await _client
          .from('products')
          .select()
          .eq('is_active', true)
          .order('name');
      _logSuccess('fetchAllProducts');
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      _logError('fetchAllProducts', e, st);
      rethrow;
    }
  }

  /// The branch's `warehouse_inventory` rows — each row is a stock batch with
  /// its own expiry date and reorder level.
  Future<List<Map<String, dynamic>>> fetchBranchWarehouse(String branchId) async {
    try {
      final rows = await _client
          .from('warehouse_inventory')
          .select()
          .eq('branch_id', branchId);
      _logSuccess('fetchBranchWarehouse');
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e, st) {
      _logError('fetchBranchWarehouse', e, st);
      rethrow;
    }
  }

  /// Adds a new stock batch for a product at the manager's branch: records the
  /// batch (with expiry date + unit price) in `warehouse_inventory` and
  /// increases the aggregate quantity in `inventory` atomically (migration
  /// 0011 RPC).
  Future<void> addStockBatch({
    required String branchId,
    required String productId,
    required int quantity,
    DateTime? expiryDate,
    double? unitPrice,
  }) async {
    try {
      await _client.rpc('branch_add_stock_batch', params: {
        'p_branch_id': branchId,
        'p_product_id': productId,
        'p_quantity': quantity,
        'p_expiry_date': expiryDate?.toIso8601String(),
        'p_unit_price': unitPrice ?? 0,
      });
      _logSuccess('addStockBatch');
    } catch (e, st) {
      _logError('addStockBatch', e, st);
      rethrow;
    }
  }
}
