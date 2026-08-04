import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../models/promotional_offer.dart';
import 'catalog_service.dart';

/// State holder for the catalog feature.
/// Consumed by HomeTab, CatalogTab, and ProductDetailScreen.
class CatalogController extends ChangeNotifier {
  CatalogController(this._service);

  final CatalogService _service;

  // ── State ─────────────────────────────────────────────────────────────────
  List<Product> _products = [];
  List<Product> get products => _products;

  List<PromotionalOffer> _offers = [];
  List<PromotionalOffer> get offers => _offers;

  List<String> _categories = [];
  List<String> get categories => _categories;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _initialized = false;

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Call once on first entering the client home area.
  Future<void> initialize() async {
    if (_initialized) return;
    await Future.wait([loadProducts(), loadOffers(), loadCategories()]);
    _initialized = true;
  }

  Future<void> loadProducts() async {
    _setLoading(true);
    try {
      _products = await _service.fetchProducts(
        category: _selectedCategory,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadOffers() async {
    try {
      _offers = await _service.fetchActiveOffers();
    } catch (_) {
      // Offers failure is non-critical — silently ignore, keep list empty.
    }
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _service.fetchCategories();
    } catch (_) {
      _categories = [];
    }
    notifyListeners();
  }

  void selectCategory(String? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
    loadProducts();
  }

  void updateSearch(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
    loadProducts();
  }

  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    notifyListeners();
    loadProducts();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
