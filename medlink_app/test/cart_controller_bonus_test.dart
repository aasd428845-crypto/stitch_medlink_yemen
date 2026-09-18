import 'package:flutter_test/flutter_test.dart';

import 'package:medlink_app/models/bonus_rule.dart';
import 'package:medlink_app/models/product.dart';
import 'package:medlink_app/services/cart_controller.dart';

void main() {
  final product = Product(
    id: 'product-1',
    name: 'Test medicine',
    category: 'medicine',
    unitPrice: 100,
  );

  BonusRule rule({
    String id = 'rule-1',
    int buy = 10,
    int free = 1,
    bool stackable = true,
    String? start,
    String? end,
    String? governorate,
    bool active = true,
    String? createdAt = '2026-01-01T00:00:00Z',
    String? productId = 'product-1',
  }) {
    return BonusRule(
      id: id,
      productId: productId,
      buyQuantity: buy,
      freeQuantity: free,
      isStackable: stackable,
      startDate: start,
      endDate: end,
      targetGovernorate: governorate,
      isActive: active,
      createdAt: createdAt,
    );
  }

  test('buy 10 gives one free unit and keeps the line free', () {
    final cart = CartController()..updateBonusRules([rule()]);

    cart.addItem(product, 10);

    expect(cart.items, hasLength(2));
    final bonus = cart.items.singleWhere((item) => item.isBonus);
    expect(bonus.quantity, 1);
    expect(bonus.unitPrice, 0);
    expect(bonus.bonusRuleId, 'rule-1');
    expect(cart.subtotalAmount, 1000);
  });

  test('stackable rule gives two free units for quantity 20', () {
    final cart = CartController()..updateBonusRules([rule()]);

    cart.addItem(product, 20);

    expect(cart.items.singleWhere((item) => item.isBonus).quantity, 2);
  });

  test('non-stackable rule gives one free unit for quantity 20', () {
    final cart = CartController()..updateBonusRules([rule(stackable: false)]);

    cart.addItem(product, 20);

    expect(cart.items.singleWhere((item) => item.isBonus).quantity, 1);
  });

  test('future, expired, and inactive rules do not apply', () {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    String date(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';

    final cart = CartController()
      ..updateBonusRules([
        rule(
          id: 'future',
          start: date(tomorrow),
          end: date(tomorrow.add(const Duration(days: 2))),
        ),
        rule(
          id: 'expired',
          start: date(yesterday.subtract(const Duration(days: 3))),
          end: date(yesterday),
        ),
        rule(id: 'inactive', active: false),
      ]);

    cart.addItem(product, 10);

    expect(cart.items.where((item) => item.isBonus), isEmpty);
  });

  test(
    'target governorate is enforced and recalculated when address changes',
    () {
      final cart = CartController()
        ..updateBonusRules([rule(governorate: 'أمانة العاصمة')]);

      cart.addItem(product, 10);
      expect(cart.items.where((item) => item.isBonus), isEmpty);

      cart.setBonusGovernorate('أمانة العاصمة');
      expect(cart.items.singleWhere((item) => item.isBonus).quantity, 1);

      cart.setBonusGovernorate('عدن');
      expect(cart.items.where((item) => item.isBonus), isEmpty);
    },
  );

  test('specific rules win over general rules deterministically', () {
    final cart = CartController()
      ..updateBonusRules([
        rule(
          id: 'general',
          productId: null,
          buy: 10,
          free: 1,
          createdAt: '2026-01-01T00:00:00Z',
        ),
        rule(
          id: 'specific',
          buy: 10,
          free: 2,
          createdAt: '2026-01-02T00:00:00Z',
        ),
      ]);

    cart.addItem(product, 10);

    final bonus = cart.items.singleWhere((item) => item.isBonus);
    expect(bonus.quantity, 2);
    expect(bonus.bonusRuleId, 'specific');
  });

  test(
    'quantity changes and removing the qualifying product remove bonus lines',
    () {
      final cart = CartController()..updateBonusRules([rule()]);

      cart.addItem(product, 10);
      cart.updateQuantity(product.id, 9);
      expect(cart.items.where((item) => item.isBonus), isEmpty);

      cart.updateQuantity(product.id, 10);
      expect(cart.items.singleWhere((item) => item.isBonus).quantity, 1);

      cart.removeItem(product.id);
      expect(cart.isEmpty, isTrue);
      expect(cart.items, isEmpty);
    },
  );
}
