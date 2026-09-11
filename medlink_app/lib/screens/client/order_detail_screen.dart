import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../services/cart_controller.dart';
import '../../services/order_service.dart';
import '../../utils/theme.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/rate_driver_sheet.dart';
import '../../widgets/driver_location_map.dart';
import '../branch_manager/branch_manager_design.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _existingRating;
  bool _ratingLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = context.read<OrderService>();
      _order = await service.fetchOrderDetails(widget.orderId);
      if (_order?.status == 'delivered') await _loadRating();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRating() async {
    try {
      final service = context.read<OrderService>();
      final rating = await service.fetchRatingForOrder(widget.orderId);
      if (mounted) setState(() { _existingRating = rating ?? {}; _ratingLoaded = true; });
    } catch (_) {
      if (mounted) setState(() => _ratingLoaded = true);
    }
  }

  Future<void> _reorder() async {
    final order = _order;
    if (order == null || order.items == null) return;
    final l10n = AppLocalizations.of(context)!;
    final payableItems = order.items!.where((item) => !item.isBonus).toList();
    if (payableItems.isEmpty) return;
    final service = context.read<OrderService>();
    final cart = context.read<CartController>();
    final products = await service.fetchCurrentProducts(payableItems.map((item) => item.productId).toSet().toList());
    if (!mounted) return;
    final byId = {for (final product in products) product.id: product};
    for (final item in payableItems) {
      final product = byId[item.productId];
      if (product != null) cart.addItem(product, item.quantity);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reorderAddedToCart)));
  }

  void _openRatingSheet() {
    final order = _order;
    if (order == null) return;
    final driverId = order.assignedDriverId;
    if (driverId == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Provider.value(
        value: context.read<OrderService>(),
        child: RateDriverSheet(orderId: order.id, driverId: driverId, onRated: (rating, comment) { setState(() { _existingRating = {'rating': rating, 'comment': comment}; }); }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: AppTheme.branchManagerLight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: BranchColors.onSurface,
          title: Text(_order != null ? '${l10n.orderNumber} ${_order!.id.substring(0, 8)}' : l10n.ordersTitle),
        ),
        body: BranchGlassBackground(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline_rounded, size: 48, color: BranchColors.error), const SizedBox(height: 10), Text(_error!, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 16), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: Text(l10n.retry))]))
                  : _order == null
                      ? Center(child: Text(l10n.noOrdersFound))
                      : _OrderContent(order: _order!, l10n: l10n, existingRating: _existingRating, ratingLoaded: _ratingLoaded, onRatePressed: _openRatingSheet, onReorderPressed: _reorder),
        ),
      ),
    );
  }
}

class _OrderContent extends StatelessWidget {
  const _OrderContent({required this.order, required this.l10n, required this.existingRating, required this.ratingLoaded, required this.onRatePressed, required this.onReorderPressed});
  final OrderModel order;
  final AppLocalizations l10n;
  final Map<String, dynamic>? existingRating;
  final bool ratingLoaded;
  final VoidCallback onRatePressed;
  final VoidCallback onReorderPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelivered = order.status == 'delivered';
    final hasRating = existingRating != null && existingRating!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(borderRadius: 24, tint: 0.82, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${l10n.orderNumber} ${order.id.substring(0, 8)}', style: theme.textTheme.headlineSmall), if (order.createdAt != null) ...[const SizedBox(height: 2), Text(order.createdAt!.substring(0, 10), style: theme.textTheme.bodySmall)]]), OrderStatusChip(status: order.status)])),
          const SizedBox(height: 16),
          if (isDelivered && ratingLoaded) ...[
            if (hasRating)
              _RatingDisplay(rating: existingRating!['rating'] as int, comment: existingRating!['comment'] as String?, l10n: l10n)
            else
              SizedBox(width: double.infinity, child: OutlinedButton.icon(icon: const Icon(Icons.star_outline_rounded), label: Text(l10n.rateDriverTitle), onPressed: onRatePressed)),
            const SizedBox(height: 16),
          ],
          if (order.deliveryAddress != null) ...[
            BranchSectionTitle(title: l10n.deliveryAddress, icon: Icons.location_on_outlined, iconColor: BranchColors.primary),
            const SizedBox(height: 10),
            SoftCard(borderRadius: 22, child: Row(children: [PastelIconBadge(icon: Icons.location_on_outlined, color: BranchColors.primary, size: 44, iconSize: 20, borderRadius: 14), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(order.deliveryAddress!.label, style: theme.textTheme.titleSmall), const SizedBox(height: 2), Text(order.deliveryAddress!.addressText, style: theme.textTheme.bodySmall)]))])),
            const SizedBox(height: 16),
          ],
          if (order.scheduledDeliveryAt != null) ...[
            SoftCard(borderRadius: 22, margin: const EdgeInsets.only(bottom: 16), child: Row(children: [PastelIconBadge(icon: Icons.schedule_rounded, color: BranchColors.warning, size: 44, iconSize: 20, borderRadius: 14), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l10n.driverScheduledDelivery, style: theme.textTheme.titleSmall), const SizedBox(height: 2), Text(order.scheduledDeliveryAt!, style: theme.textTheme.bodySmall)]))])),
          ],
          if (order.status == 'in_progress' && order.assignedDriverId != null) ...[DriverLocationMap(driverId: order.assignedDriverId!), const SizedBox(height: 16)],
          if (order.items != null && order.items!.isNotEmpty) ...[
            BranchSectionTitle(title: 'بنود الطلب', icon: Icons.inventory_2_outlined, iconColor: BranchColors.primaryContainer),
            const SizedBox(height: 10),
            GlassCard(borderRadius: 24, tint: 0.78, child: ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: order.items!.length, separatorBuilder: (_, __) => Divider(height: 1, color: BranchColors.outlineVariant.withValues(alpha: .5)), itemBuilder: (context, i) { final item = order.items![i]; return ListTile(contentPadding: EdgeInsets.zero, title: Row(children: [Expanded(child: Text(item.product?.name ?? 'منتج', style: const TextStyle(fontWeight: FontWeight.bold))), if (item.isBonus) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: BranchColors.successContainer, borderRadius: BorderRadius.circular(99)), child: Text(l10n.autoBonusBadge, style: theme.textTheme.labelMedium?.copyWith(color: BranchColors.success, fontWeight: FontWeight.bold)))]), subtitle: Text('الكمية: ${item.quantity}'), trailing: Text(item.isBonus ? '0 ﷼' : '${(item.quantity * item.unitPrice).toStringAsFixed(0)} ﷼', style: TextStyle(fontWeight: FontWeight.bold, color: item.isBonus ? BranchColors.success : BranchColors.primary))); })),
            const SizedBox(height: 16),
          ],
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            BranchSectionTitle(title: l10n.orderNotes, icon: Icons.notes_rounded, iconColor: BranchColors.warning),
            const SizedBox(height: 10),
            SoftCard(borderRadius: 22, child: Text(order.notes!, style: theme.textTheme.bodyMedium)),
            const SizedBox(height: 16),
          ],
          GlassCard(borderRadius: 24, tint: 0.82, child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.subtotal, style: theme.textTheme.bodyMedium), Text('${order.totalAmount.toStringAsFixed(0)} ﷼', style: const TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [const Icon(Icons.local_shipping_outlined, size: 18, color: BranchColors.success), const SizedBox(width: 4), Text(l10n.freeDelivery, style: const TextStyle(color: BranchColors.success, fontWeight: FontWeight.bold))]), const Text('0 ﷼', style: TextStyle(color: BranchColors.success, fontWeight: FontWeight.bold))]), Divider(height: 20, color: BranchColors.outlineVariant.withValues(alpha: .5)), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l10n.total, style: theme.textTheme.headlineSmall), Text('${order.totalAmount.toStringAsFixed(0)} ﷼', style: theme.textTheme.headlineSmall?.copyWith(color: BranchColors.primary, fontWeight: FontWeight.w700))])])),
          if (isDelivered) ...[const SizedBox(height: 16), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onReorderPressed, icon: const Icon(Icons.replay_rounded), label: Text(l10n.reorderAddedToCart)))],
        ],
      ),
    );
  }
}

class _RatingDisplay extends StatelessWidget {
  const _RatingDisplay({required this.rating, required this.comment, required this.l10n});
  final int rating;
  final String? comment;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SoftCard(borderRadius: 22, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.star_rounded, color: BranchColors.warning, size: 20), const SizedBox(width: 4), Text(l10n.yourRatingLabel, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))]), const SizedBox(height: 8), Row(children: List.generate(5, (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 22, color: BranchColors.warning))), if (comment != null && comment!.isNotEmpty) ...[const SizedBox(height: 8), Text(comment!, style: theme.textTheme.bodySmall)]]));
  }
}