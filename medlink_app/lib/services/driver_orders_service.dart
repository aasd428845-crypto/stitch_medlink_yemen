import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/driver_commission.dart';
import '../models/order.dart';
import '../utils/constants.dart';

/// Supabase data layer for the driver role.
///
/// Architecture rules (CLAUDE.md §3):
/// - Every Supabase call logs through SUPABASE_DEBUG.
/// - Status transitions go through the driver_advance_order_status RPC;
///   direct UPDATE on orders is intentionally blocked for drivers.
class DriverOrdersService {
  DriverOrdersService(this._client);

  final SupabaseClient _client;

  /// Joined fields for driver order lists and detail views.
  static const _driverOrderSelect = '*, '
      'delivery_address:client_addresses(*), '
      'client:users!orders_client_id_fkey(*), '
      'items:order_items(*, product:products(*))';

  void _logError(String fn, Object error, [StackTrace? st]) {
    debugPrint(
      '[${AppConstants.supabaseDebugTag}] DriverOrdersService.$fn failed: $error'
      '${st != null ? '\n$st' : ''}',
    );
  }

  void _logSuccess(String fn) {
    debugPrint('[${AppConstants.supabaseDebugTag}] DriverOrdersService.$fn OK');
  }

  // ── Orders ──────────────────────────────────────────────────────────────────

  /// Fetches all orders assigned to the current driver, sorted by
  /// urgency (assigned first, then in_progress, then delivered).
  Future<List<OrderModel>> fetchMyOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final rows = await _client
          .from('orders')
          .select(_driverOrderSelect)
          .eq('assigned_driver_id', userId)
          .inFilter('status', ['assigned', 'in_progress', 'delivered'])
          .order('created_at', ascending: false);

      _logSuccess('fetchMyOrders');

      final orders = (rows as List)
          .map((r) => OrderModel.fromJson(r as Map<String, dynamic>))
          .toList();

      // Sort: assigned → in_progress → delivered
      const priority = {'assigned': 0, 'in_progress': 1, 'delivered': 2};
      orders.sort(
        (a, b) =>
            (priority[a.status] ?? 3).compareTo(priority[b.status] ?? 3),
      );
      return orders;
    } catch (e, st) {
      _logError('fetchMyOrders', e, st);
      rethrow;
    }
  }

  /// Advances an order's status via the security-definer RPC.
  /// Allowed: assigned → in_progress, in_progress → delivered.
  Future<void> advanceOrderStatus(String orderId, String newStatus) async {
    try {
      await _client.rpc('driver_advance_order_status', params: {
        'p_order_id': orderId,
        'p_new_status': newStatus,
      });
      _logSuccess('advanceOrderStatus($orderId → $newStatus)');
    } catch (e, st) {
      _logError('advanceOrderStatus', e, st);
      rethrow;
    }
  }

  // ── Ratings ─────────────────────────────────────────────────────────────────

  /// Returns the current driver's average rating and total review count.
  Future<({double? average, int count})> fetchMyRatingSummary() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return (average: null, count: 0);

    try {
      final rows = await _client
          .from('driver_ratings')
          .select('rating')
          .eq('driver_id', userId);
      _logSuccess('fetchMyRatingSummary');
      final list = rows as List;
      if (list.isEmpty) return (average: null, count: 0);
      final sum =
          list.fold<int>(0, (s, r) => s + (r['rating'] as int));
      final avg = sum / list.length;
      return (average: avg, count: list.length);
    } catch (e, st) {
      _logError('fetchMyRatingSummary', e, st);
      rethrow;
    }
  }

  // ── Earnings ────────────────────────────────────────────────────────────────

  /// Fetches driver commissions for a given calendar month.
  Future<List<DriverCommission>> fetchMyEarnings({
    required int month,
    required int year,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Build month boundary dates
    final startDate = DateTime(year, month);
    final endDate = DateTime(year, month + 1);

    try {
      final rows = await _client
          .from('driver_commissions')
          .select('*, order:orders(id, total_amount)')
          .eq('driver_id', userId)
          .gte('created_at', startDate.toIso8601String())
          .lt('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      _logSuccess('fetchMyEarnings($month/$year)');
      return (rows as List)
          .map((r) => DriverCommission.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logError('fetchMyEarnings', e, st);
      rethrow;
    }
  }
}
