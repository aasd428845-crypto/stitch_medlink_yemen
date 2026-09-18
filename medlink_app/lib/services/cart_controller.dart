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
  String? _bonusGovernorate;

  void updateBonusRules(List<BonusRule> rules) {
    _activeRules = rules;
    _evaluateBonuses();
  }

  /// Sets the delivery governorate used for location-limited bonus rules.
  void setBonusGovernorate(String? governorate) {
    final normalized = _normalizeGovernorate(governorate);
    if (_bonusGovernorate == normalized) return;
    _bonusGovernorate = normalized;
    _evaluateBonuses();
    notifyListeners();
  }

  String? _normalizeGovernorate(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty ? null : normalized;

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

  /// Evaluates bonus rules against paid cart lines.
  ///
  /// Product-specific rules take precedence over general (`product_id IS NULL`)
  /// rules. Within the winning scope, the choice is deterministic: highest
  /// earned bonus, lowest buy threshold, earliest creation time, then ID.
  /// `isStackable` applies threshold multiples only to the selected rule.
  void _evaluateBonuses() {
    _bonusItems.clear();
    if (_userItems.isEmpty || _activeRules.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool isWithinDateWindow(BonusRule rule) {
      final startRaw = rule.startDate;
      final endRaw = rule.endDate;
      final startParsed = startRaw == null ? null : DateTime.tryParse(startRaw);
      final endParsed = endRaw == null ? null : DateTime.tryParse(endRaw);
      if (startRaw != null && startParsed == null) return false;
      if (endRaw != null && endParsed == null) return false;
      final start = startParsed == null
          ? null
          : DateTime(startParsed.year, startParsed.month, startParsed.day);
      final end = endParsed == null
          ? null
          : DateTime(endParsed.year, endParsed.month, endParsed.day);
      return (start == null || !today.isBefore(start)) &&
          (end == null || !today.isAfter(end));
    }

    for (final userItem in _userItems) {
      final candidates = _activeRules.where((rule) {
        final targetGovernorate = _normalizeGovernorate(rule.targetGovernorate);
        return rule.isActive &&
            rule.buyQuantity > 0 &&
            rule.freeQuantity > 0 &&
            userItem.quantity >= rule.buyQuantity &&
            isWithinDateWindow(rule) &&
            (targetGovernorate == null || targetGovernorate == _bonusGovernorate) &&
            (rule.productId == userItem.product.id || rule.productId == null);
      }).toList();
      if (candidates.isEmpty) continue;

      final specific = candidates
          .where((rule) => rule.productId == userItem.product.id)
          .toList();
      final scoped = specific.isNotEmpty
          ? specific
          : candidates.where((rule) => rule.productId == null).toList();
      scoped.sort((a, b) {
        final aBonus =
            (a.isStackable ? userItem.quantity ~/ a.buyQuantity : 1) *
            a.freeQuantity;
        final bBonus =
            (b.isStackable ? userItem.quantity ~/ b.buyQuantity : 1) *
            b.freeQuantity;
        final bonusCompare = bBonus.compareTo(aBonus);
        if (bonusCompare != 0) return bonusCompare;
        final thresholdCompare = a.buyQuantity.compareTo(b.buyQuantity);
        if (thresholdCompare != 0) return thresholdCompare;
        final createdCompare =
            (a.createdAt ?? '').compareTo(b.createdAt ?? '');
        if (createdCompare != 0) return createdCompare;
        return a.id.compareTo(b.id);
      });

      final rule = scoped.first;
      final multiplier = rule.isStackable
          ? userItem.quantity ~/ rule.buyQuantity
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
