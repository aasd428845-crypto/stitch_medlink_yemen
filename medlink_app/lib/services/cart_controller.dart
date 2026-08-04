import 'package:flutter/foundation.dart';

import '../models/bonus_rule.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// State holder for the shopping cart.
/// Implements automatic bonus evaluation whenever user item quantities change.
class CartController extends ChangeNotifier {
  // User added items (non-bonus)
  final List<CartItem> _userItems = [];
  // Computed bonus items (auto-generated)
  final List<CartItem> _bonusItems = [];

  List<BonusRule> _activeRules = [];

  void updateBonusRules(List<BonusRule> rules) {
    _activeRules = rules;
    _evaluateBonuses();
  }

  /// All cart lines: user items + auto-computed bonus lines
  List<CartItem> get items => [..._userItems, ..._bonusItems];

  int get totalItemCount {
    return items.fold(0, (sum, i) => sum + i.quantity);
  }

  double get subtotalAmount {
    return _userItems.fold(0.0, (sum, i) => sum + i.lineTotal);
  }

  bool get isEmpty => _userItems.isEmpty;

  void addItem(Product product, [int quantity = 1]) {
    final idx = _userItems.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      final current = _userItems[idx];
      _userItems[idx] = current.copyWith(quantity: current.quantity + quantity);
    } else {
      _userItems.add(
        CartItem(
          product: product,
          quantity: quantity,
          isBonus: false,
          unitPrice: product.unitPrice,
        ),
      );
    }
    _evaluateBonuses();
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }
    final idx = _userItems.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      _userItems[idx] = _userItems[idx].copyWith(quantity: newQuantity);
      _evaluateBonuses();
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _userItems.removeWhere((i) => i.product.id == productId);
    _evaluateBonuses();
    notifyListeners();
  }

  void clearCart() {
    _userItems.clear();
    _bonusItems.clear();
    notifyListeners();
  }

  /// Evaluates bonus rules against non-bonus items in the cart
  void _evaluateBonuses() {
    _bonusItems.clear();
    if (_userItems.isEmpty || _activeRules.isEmpty) return;

    for (final userItem in _userItems) {
      final rule = _activeRules.firstWhere(
        (r) => r.productId == userItem.product.id && r.isActive,
        orElse: () => const BonusRule(
          id: '',
          productId: '',
          buyQuantity: 0,
          freeQuantity: 0,
        ),
      );

      if (rule.id.isNotEmpty && rule.buyQuantity > 0) {
        if (userItem.quantity >= rule.buyQuantity) {
          final multiplier = rule.isStackable
              ? (userItem.quantity ~/ rule.buyQuantity)
              : 1;
          final bonusQty = multiplier * rule.freeQuantity;

          if (bonusQty > 0) {
            _bonusItems.add(
              CartItem(
                product: userItem.product,
                quantity: bonusQty,
                isBonus: true,
                unitPrice: 0.0,
              ),
            );
          }
        }
      }
    }
  }
}
