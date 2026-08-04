import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/cart_controller.dart';
import '../../services/order_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderController>().loadAddresses();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = context.read<CartController>();
    final orderCtrl = context.read<OrderController>();

    if (cart.isEmpty) return;

    try {
      final order = await orderCtrl.submitOrder(
        cartItems: cart.items,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      cart.clearCart();
      if (mounted) {
        context.go('/client/order-success/${order.id}');
      }
    } catch (_) {
      // Error is set on orderCtrl.error
    }
  }

  void _showAddAddressDialog(BuildContext context) {
    final labelCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.addNewAddress),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(labelText: l10n.addressLabel),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: textCtrl,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.addressText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              if (labelCtrl.text.trim().isEmpty || textCtrl.text.trim().isEmpty) {
                return;
              }
              await context.read<OrderController>().saveAddress(
                    label: labelCtrl.text.trim(),
                    addressText: textCtrl.text.trim(),
                  );
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: Text(l10n.saveAddress),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cart = context.watch<CartController>();
    final orderCtrl = context.watch<OrderController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checkoutTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (orderCtrl.error != null) ...[
              ErrorBanner(message: orderCtrl.error!),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Delivery address section ──────────────────────────────
            Text(l10n.deliveryAddress,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),

            if (orderCtrl.isLoading && orderCtrl.addresses.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (orderCtrl.addresses.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off_outlined,
                          color: AppColors.outlineVariant),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'لا يوجد عنوان محفوظ بعد',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddAddressDialog(context),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.addNewAddress),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              for (final addr in orderCtrl.addresses)
                Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: InkWell(
                    onTap: () => orderCtrl.selectAddress(addr),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(
                            orderCtrl.selectedAddress?.id == addr.id
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: orderCtrl.selectedAddress?.id == addr.id
                                ? AppColors.primary
                                : AppColors.outlineVariant,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(addr.label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(addr.addressText,
                                    style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _showAddAddressDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.addNewAddress),
                ),
              ),
            ],

            const Divider(height: AppSpacing.xl),

            // ── Order notes ───────────────────────────────────────────
            Text(l10n.orderNotes, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'أدخل أي تعليمات خاصة بالتسليم...',
              ),
            ),

            const Divider(height: AppSpacing.xl),

            // ── Summary breakdown ────────────────────────────────────
            Text('ملخص الطلب', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('عدد البنود:',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text('${cart.items.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.subtotal,
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                          '${cart.subtotalAmount.toStringAsFixed(0)} ﷼',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined,
                                size: 18, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(l10n.freeDelivery,
                                style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Text('0 ﷼',
                            style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.total,
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text(
                          '${cart.subtotalAmount.toStringAsFixed(0)} ﷼',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Submit button
            ElevatedButton(
              onPressed: orderCtrl.isLoading ? null : _submit,
              child: orderCtrl.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Text(l10n.confirmOrder),
            ),
          ],
        ),
      ),
    );
  }
}
