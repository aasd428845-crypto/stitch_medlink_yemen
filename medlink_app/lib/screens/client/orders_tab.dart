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
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderController>().loadClientOrders());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orderCtrl = context.watch<OrderController>();

    if (orderCtrl.isLoading && orderCtrl.orders.isEmpty) return const Center(child: CircularProgressIndicator());

    if (orderCtrl.error != null && orderCtrl.orders.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
        const SizedBox(height: AppSpacing.sm),
        Text(orderCtrl.error!, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(onPressed: orderCtrl.loadClientOrders, icon: const Icon(Icons.refresh_rounded), label: Text(l10n.retry)),
      ]));
    }

    if (orderCtrl.orders.isEmpty) {
      return Center(child: ClientDesignSurface(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.receipt_long_outlined, size: 54, color: Color(0xFF63D9FF)),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.noOrdersFound, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      ])));
    }

    return RefreshIndicator(
      onRefresh: orderCtrl.loadClientOrders,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: orderCtrl.orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          final order = orderCtrl.orders[i];
          final dateStr = order.createdAt != null ? order.createdAt!.substring(0, 10) : '';
          return ClientDesignSurface(
            padding: EdgeInsets.zero,
            child: InkWell(
              onTap: () => context.push('/client/order/${order.id}'),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0x2263D9FF), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF63D9FF))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${l10n.orderNumber} ${order.id.substring(0, 8)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      if (dateStr.isNotEmpty) Text(dateStr, style: const TextStyle(color: Color(0xFF8FA5B5), fontSize: 12)),
                    ])),
                    OrderStatusChip(status: order.status),
                  ]),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0x223C5A70)),
                  const SizedBox(height: 8),
                  Row(children: [
                    if (order.deliveryAddress != null) Expanded(child: Text('${l10n.deliveredTo}: ${order.deliveryAddress!.label}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFA7BAC8)))),
                    const SizedBox(width: 10),
                    Text('${order.totalAmount.toStringAsFixed(0)} ﷼', style: const TextStyle(color: Color(0xFF63D9FF), fontWeight: FontWeight.w900)),
                  ]),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
