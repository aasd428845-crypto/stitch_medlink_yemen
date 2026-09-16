import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/cart_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/cart_item_tile.dart';
import 'client_design.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cart = context.watch<CartController>();

    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: ClientColors.background,
        appBar: AppBar(
          backgroundColor: ClientColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: ClientColors.text,
          title: Text(l10n.cartTitle),
          actions: [
            if (!cart.isEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: l10n.clearCart,
                onPressed: cart.clearCart,
              ),
          ],
        ),
        body: ClientGlassBackground(
          child: cart.isEmpty
              ? Center(
                  child: ClientCard(
                    padding: const EdgeInsets.all(32),
                    borderRadius: 28,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClientIconBadge(
                          icon: Icons.shopping_cart_outlined,
                          color: ClientColors.primary,
                          size: 56,
                          iconSize: 28,
                          shape: BoxShape.circle,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.emptyCart,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final item = cart.items[i];
                          return ClientCard(
                            padding: const EdgeInsets.all(8),
                            borderRadius: 22,
                            child: CartItemTile(
                              item: item,
                              onQuantityChanged: (qty) =>
                                  cart.updateQuantity(item.product.id, qty),
                              onRemove: () => cart.removeItem(item.product.id),
                            ),
                          );
                        },
                      ),
                    ),
                    ClientCard(
                      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      borderRadius: 24,
                      tint: 0.82,
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.subtotal,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: ClientColors.textMuted),
                                ),
                                Text(
                                  '${cart.subtotalAmount.toStringAsFixed(0)} ﷼',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_shipping_outlined,
                                  size: 18,
                                  color: ClientColors.success,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  l10n.freeDelivery,
                                  style: const TextStyle(
                                    color: ClientColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.arrow_back_rounded),
                                label: Text(l10n.proceedToCheckout),
                                onPressed: () =>
                                    context.push('/client/checkout'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
