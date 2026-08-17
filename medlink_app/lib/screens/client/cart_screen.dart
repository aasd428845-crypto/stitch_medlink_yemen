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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cartTitle), actions: [
        if (!cart.isEmpty) IconButton(icon: const Icon(Icons.delete_outline_rounded), tooltip: l10n.clearCart, onPressed: cart.clearCart),
      ]),
      body: cart.isEmpty
          ? Center(child: ClientDesignSurface(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.shopping_cart_outlined, size: 58, color: Color(0xFF63D9FF)),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.emptyCart, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ])))
          : Column(children: [
              Expanded(child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                itemCount: cart.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = cart.items[i];
                  return ClientDesignSurface(padding: const EdgeInsets.all(8), child: CartItemTile(
                    item: item,
                    onQuantityChanged: (qty) => cart.updateQuantity(item.product.id, qty),
                    onRemove: () => cart.removeItem(item.product.id),
                  ));
                },
              )),
              ClientDesignSurface(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(l10n.subtotal, style: const TextStyle(color: Color(0xFFA7BAC8))),
                    Text('${cart.subtotalAmount.toStringAsFixed(0)} ﷼', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF6DE7C8)),
                    const SizedBox(width: 7),
                    Text(l10n.freeDelivery, style: const TextStyle(color: Color(0xFF6DE7C8), fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(width: double.infinity, child: FilledButton.icon(icon: const Icon(Icons.arrow_back_rounded), label: Text(l10n.proceedToCheckout), onPressed: () => context.push('/client/checkout'))),
                ])),
              ),
            ]),
    );
  }
}
