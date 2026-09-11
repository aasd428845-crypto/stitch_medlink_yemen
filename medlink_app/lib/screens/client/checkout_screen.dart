import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/cart_controller.dart';
import '../../services/order_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';
import '../branch_manager/branch_manager_design.dart';
import 'addresses_screen.dart';

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
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      cart.clearCart();
      if (mounted) context.go('/client/order-success/${order.id}');
    } catch (_) {}
  }

  void _showAddAddressDialog(BuildContext context) {
    // Navigate to the full rich addresses screen for adding a new address
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddressesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cart = context.watch<CartController>();
    final orderCtrl = context.watch<OrderController>();

    return Theme(
      data: AppTheme.branchManagerLight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: BranchColors.onSurface, title: Text(l10n.checkoutTitle)),
        body: BranchGlassBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (orderCtrl.error != null) ...[ErrorBanner(message: orderCtrl.error!), const SizedBox(height: 16)],
                BranchSectionTitle(title: l10n.deliveryAddress, icon: Icons.location_on_outlined, iconColor: BranchColors.primary),
                const SizedBox(height: 12),
                if (orderCtrl.isLoading && orderCtrl.addresses.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (orderCtrl.addresses.isEmpty)
                  SoftCard(
                    borderRadius: 22,
                    child: Row(
                      children: [
                        PastelIconBadge(icon: Icons.location_off_outlined, color: BranchColors.onSurfaceVariant, size: 44, iconSize: 20, borderRadius: 14),
                        const SizedBox(width: 14),
                        Expanded(child: Text('لا يوجد عنوان محفوظ بعد', style: Theme.of(context).textTheme.bodyMedium)),
                        TextButton.icon(onPressed: () => _showAddAddressDialog(context), icon: const Icon(Icons.add_rounded), label: Text(l10n.addNewAddress)),
                      ],
                    ),
                  )
                else ...[
                  for (final addr in orderCtrl.addresses)
                    SoftCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      borderRadius: 22,
                      padding: const EdgeInsets.all(14),
                      child: InkWell(
                        onTap: () => orderCtrl.selectAddress(addr),
                        borderRadius: BorderRadius.circular(22),
                        child: Row(
                          children: [
                            Icon(
                              orderCtrl.selectedAddress?.id == addr.id ? Icons.check_circle_rounded : Icons.circle_outlined,
                              color: orderCtrl.selectedAddress?.id == addr.id ? BranchColors.primary : BranchColors.outlineVariant,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(addr.label, style: Theme.of(context).textTheme.titleSmall),
                                  const SizedBox(height: 2),
                                  Text(addr.addressText, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(onPressed: () => _showAddAddressDialog(context), icon: const Icon(Icons.add_rounded), label: Text(l10n.addNewAddress)),
                  ),
                ],
                const SizedBox(height: 20),
                BranchSectionTitle(title: l10n.orderNotes, icon: Icons.notes_rounded, iconColor: BranchColors.warning),
                const SizedBox(height: 12),
                TextField(controller: _notesController, maxLines: 3, decoration: const InputDecoration(hintText: 'أدخل أي تعليمات خاصة بالتسليم...')),
                const SizedBox(height: 20),
                BranchSectionTitle(title: 'ملخص الطلب', icon: Icons.receipt_long_outlined, iconColor: BranchColors.primaryContainer),
                const SizedBox(height: 12),
                GlassCard(
                  borderRadius: 24,
                  tint: 0.82,
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('عدد البنود:', style: Theme.of(context).textTheme.bodyMedium),
                        Text('${cart.items.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(l10n.subtotal, style: Theme.of(context).textTheme.bodyMedium),
                        Text('${cart.subtotalAmount.toStringAsFixed(0)} ﷼', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Row(children: [const Icon(Icons.local_shipping_outlined, size: 18, color: BranchColors.success), const SizedBox(width: 4), Text(l10n.freeDelivery, style: const TextStyle(color: BranchColors.success, fontWeight: FontWeight.bold))]),
                        const Text('0 ﷼', style: TextStyle(color: BranchColors.success, fontWeight: FontWeight.bold)),
                      ]),
                      Divider(height: 20, color: BranchColors.outlineVariant.withValues(alpha: .5)),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(l10n.total, style: Theme.of(context).textTheme.headlineSmall),
                        Text('${cart.subtotalAmount.toStringAsFixed(0)} ﷼', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: BranchColors.primary, fontWeight: FontWeight.w700)),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: orderCtrl.isLoading ? null : _submit,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: orderCtrl.isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                      : Text(l10n.confirmOrder),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}