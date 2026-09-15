import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../models/promotional_offer.dart';
import 'catalog_service.dart';

class ReorderRecommendation {
  const ReorderRecommendation({
    required this.product,
    required this.averageCycleDays,
    required this.daysSinceLastOrder,
  });

  final Product product;
  final int averageCycleDays;
  final int daysSinceLastOrder;
}

/// State holder for the catalog feature.
/// Consumed by HomeTab, CatalogTab, and ProductDetailScreen.
class CatalogController extends ChangeNotifier {
  CatalogController(this._service);

  final CatalogService _service;

  // ── State ─────────────────────────────────────────────────────────────────
  List<Product> _products = [];
  List<Product> get products => _products;

  List<Product> _newProducts = [];
  List<Product> get newProducts => _newProducts;
  bool _newProductsLoading = false;
  bool get newProductsLoading => _newProductsLoading;
  String? _newProductsError;
  String? get newProductsError => _newProductsError;

  List<PromotionalOffer> _offers = [];
  List<PromotionalOffer> get offers => _offers;
  bool _offersLoading = false;
  bool get offersLoading => _offersLoading;
  String? _offersError;
  String? get offersError => _offersError;

  List<String> _categories = [];
  List<String> get categories => _categories;
  bool _categoriesLoading = false;
  bool get categoriesLoading => _categoriesLoading;
  String? _categoriesError;
  String? get categoriesError => _categoriesError;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<ReorderRecommendation> _reorderRecommendations = [];
  List<ReorderRecommendation> get reorderRecommendations =>
      _reorderRecommendations;
  bool _reorderLoading = false;
  bool get reorderLoading => _reorderLoading;
  String? _reorderError;
  String? get reorderError => _reorderError;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Call once on first entering the client home area.
  Future<void> initialize() async {
    if (_initialized) return;
    await Future.wait([
      loadProducts(),
      loadOffers(),
      loadCategories(),
      loadNewProducts(),
    ]);
    await loadReorderRecommendations();
    _initialized = true;
    notifyListeners();
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
    _offersLoading = true;
    _offersError = null;
    notifyListeners();
    try {
      _offers = await _service.fetchActiveOffers();
    } catch (e) {
      _offers = [];
      _offersError = e.toString();
    } finally {
      _offersLoading = false;
    }
    notifyListeners();
  }

  Future<void> loadNewProducts() async {
    _newProductsLoading = true;
    _newProductsError = null;
    notifyListeners();
    try {
      _newProducts = await _service.fetchLatestProducts();
    } catch (e) {
      _newProducts = [];
      _newProductsError = e.toString();
    } finally {
      _newProductsLoading = false;
    }
    notifyListeners();
  }

  /// Calculates a recommendation from the client's real delivered orders.
  /// A product is shown only after two or more purchase dates establish a
  /// cycle, and only once the current interval is close to that cycle.
  Future<void> loadReorderRecommendations() async {
    _reorderLoading = true;
    _reorderError = null;
    notifyListeners();
    try {
      final history = await _service.fetchPurchaseHistory();
      final now = DateTime.now();
      final recommendations = <ReorderRecommendation>[];

      for (final product in _products) {
        final dates = [...?history[product.id]]..sort();
        if (dates.length < 2) continue;

        final intervals = <int>[];
        for (var i = 1; i < dates.length; i++) {
          final days = dates[i].difference(dates[i - 1]).inDays;
          if (days > 0) intervals.add(days);
        }
        if (intervals.isEmpty) continue;

        final average = (intervals.reduce((a, b) => a + b) / intervals.length)
            .round();
        final elapsed = now.difference(dates.last).inDays;
        if (average > 0 && elapsed >= (average * 0.8).round()) {
          recommendations.add(
            ReorderRecommendation(
              product: product,
              averageCycleDays: average,
              daysSinceLastOrder: elapsed,
            ),
          );
        }
      }

      _reorderRecommendations = recommendations;
    } catch (e) {
      _reorderRecommendations = [];
      _reorderError = e.toString();
    } finally {
      _reorderLoading = false;
    }
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categoriesLoading = true;
    _categoriesError = null;
    notifyListeners();
    try {
      _categories = await _service.fetchCategories();
    } catch (e) {
      _categories = [];
      _categoriesError = e.toString();
    } finally {
      _categoriesLoading = false;
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
