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
}
