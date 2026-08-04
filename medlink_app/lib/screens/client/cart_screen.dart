import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/cart_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/cart_item_tile.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cart = context.watch<CartController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cartTitle),
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: l10n.clearCart,
              onPressed: () => cart.clearCart(),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: AppColors.outlineVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.emptyCart,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: cart.items.length,
                    itemBuilder: (context, i) {
                      final item = cart.items[i];
                      return CartItemTile(
                        item: item,
                        onQuantityChanged: (qty) {
                          cart.updateQuantity(item.product.id, qty);
                        },
                        onRemove: () {
                          cart.removeItem(item.product.id);
                        },
                      );
                    },
                  ),
                ),

                // Footer checkout summary
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border(
                      top: BorderSide(color: AppColors.outlineVariant),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.subtotal,
                                style: Theme.of(context).textTheme.bodyMedium),
                            Text(
                              '${cart.subtotalAmount.toStringAsFixed(0)} ﷼',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        // Free delivery badge
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined,
                                size: 18, color: AppColors.success),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              l10n.freeDelivery,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.md),

                        ElevatedButton(
                          onPressed: () => context.push('/client/checkout'),
                          child: Text(l10n.proceedToCheckout),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
