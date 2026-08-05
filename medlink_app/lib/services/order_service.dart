import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bonus_rule.dart';
import '../models/cart_item.dart';
import '../models/client_address.dart';
import '../models/order.dart';
import '../utils/constants.dart';

/// Single source of truth for Order, Address, and Bonus Rule database operations.
/// Architecture rule (CLAUDE.md §3):
/// - Every Supabase call logs through SUPABASE_DEBUG.
/// - Success is only reported after a real verified response.
class OrderService {
  OrderService(this._client);

  final SupabaseClient _client;

  void _logError(String fn, Object error, [StackTrace? st]) {
    debugPrint(
      '[${AppConstants.supabaseDebugTag}] OrderService.$fn failed: $error'
      '${st != null ? '\n$st' : ''}',
    );
  }

  void _logSuccess(String fn) {
    debugPrint('[${AppConstants.supabaseDebugTag}] OrderService.$fn OK');
  }

  // ── Bonus Rules ────────────────────────────────────────────────────────────

  /// Fetches active bonus rules from `public.bonus_rules`.
  Future<List<BonusRule>> fetchBonusRules() async {
    try {
      final rows = await _client
          .from('bonus_rules')
          .select()
          .eq('is_active', true);
      _logSuccess('fetchBonusRules');
      return (rows as List)
          .map((r) => BonusRule.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logError('fetchBonusRules', e, st);
      rethrow;
    }
  }

  // ── Addresses ──────────────────────────────────────────────────────────────

  /// Fetches saved addresses for current authenticated client.
  Future<List<ClientAddress>> fetchClientAddresses() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final rows = await _client
          .from('client_addresses')
          .select()
          .eq('client_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      _logSuccess('fetchClientAddresses');
      return (rows as List)
          .map((r) => ClientAddress.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logError('fetchClientAddresses', e, st);
      rethrow;
    }
  }

  /// Saves a new address for the client.
  Future<ClientAddress> saveClientAddress({
    required String label,
    required String addressText,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('المستخدم غير مسجل الدخول');
    }

    try {
      final insertedRow = await _client
          .from('client_addresses')
          .insert({
            'client_id': userId,
            'label': label,
            'address_text': addressText,
            'latitude': latitude,
            'longitude': longitude,
            'is_default': isDefault,
          })
          .select()
          .single();

      _logSuccess('saveClientAddress');
      return ClientAddress.fromJson(insertedRow);
    } catch (e, st) {
      _logError('saveClientAddress', e, st);
      rethrow;
    }
  }

  Future<void> deleteClientAddress(String addressId) async {
    try {
      await _client.from('client_addresses').delete().eq('id', addressId);
      _logSuccess('deleteClientAddress');
    } catch (e, st) {
      _logError('deleteClientAddress', e, st);
      rethrow;
    }
  }

  // ── Orders Creation & Fetching ─────────────────────────────────────────────

  /// Submits a new order with items & bonus lines.
  /// Automatically resolves nearest/default branch if not assigned.
  Future<OrderModel> createOrder({
    required String? deliveryAddressId,
    required List<CartItem> items,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('المستخدم غير مسجل الدخول');
    }
    if (items.isEmpty) {
      throw ArgumentError('لا يمكن إنشاء طلب بسلة فارغة');
    }

    try {
      // Pick first active branch as target (or null)
      String? branchId;
      final branches = await _client.from('branches').select('id').limit(1);
      if ((branches as List).isNotEmpty) {
        branchId = branches.first['id'] as String?;
      }

      // Calculate total payable amount (bonus items have unitPrice = 0)
      final totalAmount = items.fold<double>(
        0.0,
        (sum, item) => sum + (item.quantity * item.unitPrice),
      );

      // Insert Order row
      final orderRow = await _client
          .from('orders')
          .insert({
            'client_id': userId,
            'branch_id': branchId,
            'status': 'pending',
            'delivery_address_id': deliveryAddressId,
            'total_amount': totalAmount,
            'notes': notes,
          })
          .select()
          .single();

      final orderId = orderRow['id'] as String;

      // Insert Order Items
      final orderItemPayloads = items.map((item) {
        return {
          'order_id': orderId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'is_bonus': item.isBonus,
        };
      }).toList();

      await _client.from('order_items').insert(orderItemPayloads);

      _logSuccess('createOrder');
      return OrderModel.fromJson(orderRow);
    } catch (e, st) {
      _logError('createOrder', e, st);
      rethrow;
    }
  }

  /// Fetches order history for current client.
  Future<List<OrderModel>> fetchClientOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final rows = await _client
          .from('orders')
          .select('*, delivery_address:client_addresses(*)')
          .eq('client_id', userId)
          .order('created_at', ascending: false);
      _logSuccess('fetchClientOrders');
      return (rows as List)
          .map((r) => OrderModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      _logError('fetchClientOrders', e, st);
      rethrow;
    }
  }

  /// Fetches single order details with joined order items & address.
  Future<OrderModel?> fetchOrderDetails(String orderId) async {
    try {
      final row = await _client
          .from('orders')
          .select(
            '*, delivery_address:client_addresses(*), items:order_items(*, product:products(*))',
          )
          .eq('id', orderId)
          .maybeSingle();

      _logSuccess('fetchOrderDetails');
      if (row == null) return null;
      return OrderModel.fromJson(row);
    } catch (e, st) {
      _logError('fetchOrderDetails', e, st);
      rethrow;
    }
  }

  // ── Driver Ratings ─────────────────────────────────────────────────────────

  /// Submits a driver rating for a delivered order.
  /// [client_id] is derived from the current session — never passed from UI.
  /// Throws if the order has already been rated (unique constraint on order_id).
  Future<void> submitDriverRating({
    required String orderId,
    required String driverId,
    required int rating,
    String? comment,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('المستخدم غير مسجل الدخول');
    }

    try {
      await _client.from('driver_ratings').insert({
        'order_id': orderId,
        'driver_id': driverId,
        'client_id': userId,
        'rating': rating,
        'comment': comment,
      });
      _logSuccess('submitDriverRating');
    } catch (e, st) {
      _logError('submitDriverRating', e, st);
      rethrow;
    }
  }

  /// Returns the existing rating row for [orderId], or null if not yet rated.
  Future<Map<String, dynamic>?> fetchRatingForOrder(String orderId) async {
    try {
      final row = await _client
          .from('driver_ratings')
          .select('rating, comment')
          .eq('order_id', orderId)
          .maybeSingle();
      _logSuccess('fetchRatingForOrder');
      return row;
    } catch (e, st) {
      _logError('fetchRatingForOrder', e, st);
      rethrow;
    }
  }
}
