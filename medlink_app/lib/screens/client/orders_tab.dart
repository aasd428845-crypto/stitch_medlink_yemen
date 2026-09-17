import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/order_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/order_status_chip.dart';
import 'client_design.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<OrderController>().loadClientOrders(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orderCtrl = context.watch<OrderController>();

    if (orderCtrl.isLoading && orderCtrl.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orderCtrl.error != null && orderCtrl.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: ClientColors.danger,
            ),
            const SizedBox(height: 10),
            Text(
              orderCtrl.error!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: orderCtrl.loadClientOrders,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (orderCtrl.orders.isEmpty) {
      return Center(
        child: ClientCard(
          padding: const EdgeInsets.all(32),
          borderRadius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClientIconBadge(
                icon: Icons.receipt_long_outlined,
                color: ClientColors.primary,
                size: 56,
                iconSize: 28,
                shape: BoxShape.circle,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noOrdersFound,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: orderCtrl.loadClientOrders,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: orderCtrl.orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final order = orderCtrl.orders[i];
          final dateStr = order.createdAt != null
              ? order.createdAt!.substring(0, 10)
              : '';
          return ClientCard(
            padding: EdgeInsets.zero,
            borderRadius: 24,
            child: InkWell(
              onTap: () => context.push('/client/order/${order.id}'),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClientIconBadge(
                          icon: Icons.receipt_long_rounded,
                          color: ClientColors.primary,
                          size: 44,
                          iconSize: 20,
                          borderRadius: 14,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${l10n.orderNumber} ${order.id.substring(0, 8)}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              if (dateStr.isNotEmpty)
                                Text(
                                  dateStr,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        OrderStatusChip(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(color: ClientColors.outline.withValues(alpha: .5)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (order.deliveryAddress != null)
                          Expanded(
                            child: Text(
                              '${l10n.deliveredTo}: ${order.deliveryAddress!.label}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(width: 10),
                        Text(
                          '${order.totalAmount.toStringAsFixed(0)} ﷼',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: ClientColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
