import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../utils/theme.dart';
import '../../widgets/order_status_chip.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = context.read<OrderService>();
      _order = await service.fetchOrderDetails(widget.orderId);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _order != null
              ? '${l10n.orderNumber} ${_order!.id.substring(0, 8)}'
              : l10n.ordersTitle,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: AppSpacing.sm),
                      Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _order == null
                  ? Center(child: Text(l10n.noOrdersFound))
                  : _OrderContent(order: _order!, l10n: l10n),
    );
  }
}

class _OrderContent extends StatelessWidget {
  const _OrderContent({required this.order, required this.l10n});

  final OrderModel order;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.orderNumber} ${order.id.substring(0, 8)}',
                        style: theme.textTheme.headlineSmall,
                      ),
                      if (order.createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          order.createdAt!.substring(0, 10),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  OrderStatusChip(status: order.status),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Address Card
          if (order.deliveryAddress != null) ...[
            Text(l10n.deliveryAddress, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined,
                    color: AppColors.primary),
                title: Text(order.deliveryAddress!.label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(order.deliveryAddress!.addressText),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Order Items List
          if (order.items != null && order.items!.isNotEmpty) ...[
            Text('بنود الطلب', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items!.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final item = order.items![i];
                  return ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.product?.name ?? 'منتج',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (item.isBonus)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successContainer,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              l10n.autoBonusBadge,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text('الكمية: ${item.quantity}'),
                    trailing: Text(
                      item.isBonus
                          ? '0 ﷼'
                          : '${(item.quantity * item.unitPrice).toStringAsFixed(0)} ﷼',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.isBonus
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Notes
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            Text(l10n.orderNotes, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(order.notes!, style: theme.textTheme.bodyMedium),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Payment Summary Card
          Card(
            color: AppColors.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.subtotal, style: theme.textTheme.bodyMedium),
                      Text(
                        '${order.totalAmount.toStringAsFixed(0)} ﷼',
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
                      Text(l10n.total, style: theme.textTheme.headlineSmall),
                      Text(
                        '${order.totalAmount.toStringAsFixed(0)} ﷼',
                        style: theme.textTheme.headlineSmall?.copyWith(
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
        ],
      ),
    );
  }
}
