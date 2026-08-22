import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/inventory_item.dart';
import '../models/product.dart';
import '../models/promotional_offer.dart';
import '../utils/constants.dart';

/// Single source of truth for all catalog, inventory, and offers reads.
///
/// Architecture rules (CLAUDE.md §3):
/// - Every Supabase call logs through SUPABASE_DEBUG.
/// - Success is only reported after a verified real response.
/// - No logic is duplicated — every screen calls this service.
class CatalogService {
  CatalogService(this._client);

  final SupabaseClient _client;

  void _logError(String fn, Object error, [StackTrace? st]) {
    debugPrint(
      '[${AppConstants.supabaseDebugTag}] CatalogService.$fn failed: $error'
      '${st != null ? '\n$st' : ''}',
    );
  }

  void _logSuccess(String fn) {
    debugPrint('[${AppConstants.supabaseDebugTag}] CatalogService.$fn OK');
  }

  // ── Products ──────────────────────────────────────────────────────────────

  /// Fetches active products. Optionally filter by [category] or [searchQuery].
  Future<List<Product>> fetchProducts({
    String? category,
    String? searchQuery,
  }) async {
    try {
      var query = _client.from('products').select().eq('is_active', true);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Case-insensitive Arabic/English search on name
        query = query.ilike('name', '%$searchQuery%');
      }

      final rows = await query.order('name');
      _logSuccess('fetchProducts');
      return (rows as List)
          .map((r) => Product.fromJson(r))
          .toList();
    } catch (e, st) {
      _logError('fetchProducts', e, st);
      rethrow;
    }
  }

  /// Fetches a single product by [id].
  Future<Product?> fetchProductById(String id) async {
    try {
      final row = await _client
          .from('products')
          .select()
          .eq('id', id)
          .maybeSingle();
      _logSuccess('fetchProductById');
      if (row == null) return null;
      return Product.fromJson(row);
    } catch (e, st) {
      _logError('fetchProductById', e, st);
      rethrow;
    }
  }

  /// Returns all distinct category values present in active products.
  Future<List<String>> fetchCategories() async {
    try {
      final rows = await _client
          .from('products')
          .select('category')
          .eq('is_active', true)
          .order('category');
      _logSuccess('fetchCategories');
      final seen = <String>{};
      final result = <String>[];
      for (final r in rows as List) {
        final cat = r['category'] as String?;
        if (cat != null && seen.add(cat)) result.add(cat);
      }
      return result;
    } catch (e, st) {
      _logError('fetchCategories', e, st);
      rethrow;
    }
  }

  // ── Offers ────────────────────────────────────────────────────────────────

  /// Fetches currently active promotional offers.
  /// Optionally filters by [governorate] (null = show global offers too).
  Future<List<PromotionalOffer>> fetchActiveOffers({
    String? governorate,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      var query = _client
          .from('promotional_offers')
          .select()
          .eq('is_active', true)
          .or('start_date.is.null,start_date.lte.$today')
          .or('end_date.is.null,end_date.gte.$today');

      if (governorate != null && governorate.isNotEmpty) {
        query = query.or(
          'target_governorate.is.null,target_governorate.eq.$governorate',
        );
      }

      final rows = await query.order('created_at', ascending: false);
      _logSuccess('fetchActiveOffers');
      return (rows as List)
          .map((r) => PromotionalOffer.fromJson(r))
          .where((offer) => offer.isCurrentlyActive)
          .toList();
    } catch (e, st) {
      _logError('fetchActiveOffers', e, st);
      rethrow;
    }
  }

  /// Returns delivered-order dates grouped by product for the current client.
  ///
  /// The query uses the existing `orders` and `order_items` columns and is
  /// intentionally limited to delivered, non-bonus lines.  No purchase cycle
  /// is inferred until there are at least two delivered orders for a product.
  Future<Map<String, List<DateTime>>> fetchPurchaseHistory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    try {
      final rows = await _client
          .from('orders')
          .select('created_at, items:order_items(product_id, is_bonus)')
          .eq('client_id', userId)
          .eq('status', 'delivered')
          .order('created_at');

      final history = <String, List<DateTime>>{};
      for (final row in rows as List) {
        final date = DateTime.tryParse(row['created_at'] as String? ?? '');
        if (date == null) continue;
        final items = row['items'] as List? ?? const [];
        for (final item in items) {
          if (item['is_bonus'] == true) continue;
          final productId = item['product_id'] as String?;
          if (productId == null) continue;
          history.putIfAbsent(productId, () => []).add(date);
        }
      }
      _logSuccess('fetchPurchaseHistory');
      return history;
    } catch (e, st) {
      _logError('fetchPurchaseHistory', e, st);
      rethrow;
    }
  }

  // ── Inventory ─────────────────────────────────────────────────────────────

  /// Fetches inventory for a specific [branchId], joined with product details.
  Future<List<InventoryItem>> fetchInventoryForBranch(String branchId) async {
    try {
      final rows = await _client
          .from('inventory')
          .select('*, product:products(*)')
          .eq('branch_id', branchId)
          .order('updated_at', ascending: false);
      _logSuccess('fetchInventoryForBranch');
      return (rows as List)
          .map((r) => InventoryItem.fromJson(r))
          .toList();
    } catch (e, st) {
      _logError('fetchInventoryForBranch', e, st);
      rethrow;
    }
  }

  /// Returns the actual quantity for a product in the client's assigned
  /// branch. The Flutter project uses the existing `inventory` table; no
  /// fallback to another branch is allowed.
  Future<int> fetchProductQuantity({
    required String productId,
    required String branchId,
  }) async {
    try {
      final rows = await _client
          .from('inventory')
          .select('quantity')
          .eq('branch_id', branchId)
          .eq('product_id', productId);
      _logSuccess('fetchProductQuantity');
      return (rows as List).fold<int>(
        0,
        (sum, row) => sum + ((row['quantity'] as num?)?.toInt() ?? 0),
      );
    } catch (e, st) {
      _logError('fetchProductQuantity', e, st);
      rethrow;
    }
  }
}
