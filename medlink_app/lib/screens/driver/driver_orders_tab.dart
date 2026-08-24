import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/order.dart';
import '../../services/driver_orders_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';

class DriverOrdersTab extends StatefulWidget {
  const DriverOrdersTab({super.key});

  @override
  State<DriverOrdersTab> createState() => _DriverOrdersTabState();
}

class _DriverOrdersTabState extends State<DriverOrdersTab> {
  int _segment = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DriverOrdersController>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = context.watch<DriverOrdersController>();

    final filtered = ctrl.orders.where((order) {
      return _segment == 0
          ? order.status == 'assigned'
          : order.status == 'in_progress';
    }).toList();

    return Column(
      children: [
        // ── Two delivery stages from the real orders.status values ────────
        Material(
          color: AppColors.surfaceContainerLowest,
          child: Row(
            children: [
              _SegmentButton(
                label: l10n.driverFilterAssigned,
                selected: _segment == 0,
                onTap: () => setState(() => _segment = 0),
              ),
              _SegmentButton(
                label: l10n.driverFilterInProgress,
                selected: _segment == 1,
                onTap: () => setState(() => _segment = 1),
              ),
            ],
          ),
        ),

        // ── Order list ─────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: ctrl.loadOrders,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (ctrl.ordersError != null) ...[
                  ErrorBanner(message: ctrl.ordersError!),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (ctrl.isLoadingOrders && ctrl.orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            size: 48,
                            color: AppColors.outline,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.driverNoOrders,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final order in filtered) ...[
                    _DriverOrderCard(
                      order: order,
                      onTap: () => context.push('/driver/order/${order.id}'),
                      onAdvance: () => _advanceOrder(context, order),
                      onCall: () => _callClient(order),
                      onMap: () => _openMap(order),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _advanceOrder(BuildContext context, OrderModel order) async {
    final next = order.status == 'assigned' ? 'in_progress' : 'delivered';
    await context.read<DriverOrdersController>().advanceOrderStatus(order.id, next);
  }

  Future<void> _callClient(OrderModel order) async {
    final phone = order.client?.phone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMap(OrderModel order) async {
    final address = order.deliveryAddress;
    if (address?.latitude == null || address?.longitude == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${address!.latitude},${address.longitude}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? AppColors.primary : Colors.transparent, width: 3)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        )),
      ),
    ),
  );
}

// ── Order card ─────────────────────────────────────────────────────────────────

class _DriverOrderCard extends StatelessWidget {
  const _DriverOrderCard({required this.order, required this.onTap, required this.onAdvance, required this.onCall, required this.onMap});

  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback onAdvance;
  final VoidCallback onCall;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final shortId = '#${order.id.substring(0, 8).toUpperCase()}';
    final clientName = order.client?.name ?? '—';
    final address = order.deliveryAddress?.addressText ?? '—';
    final itemCount = order.items?.length ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: ID + status chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    shortId,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Row 2: client name
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    clientName,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Row 3: delivery address
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (order.scheduledDeliveryAt != null &&
                  order.scheduledDeliveryAt!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.schedule_outlined,
                        size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      order.scheduledDeliveryAt!
                          .replaceFirst('T', ' ')
                          .substring(0, 16),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

               // Actions are available directly on the card.
               Row(
                 children: [
                   Expanded(
                     child: FilledButton.icon(
                       onPressed: onAdvance,
                       icon: Icon(order.status == 'assigned' ? Icons.local_shipping_rounded : Icons.check_circle_rounded),
                       label: Text(order.status == 'assigned' ? l10n.driverStartDelivery : l10n.driverConfirmDelivery),
                     ),
                   ),
                   const SizedBox(width: AppSpacing.sm),
                   IconButton.filledTonal(onPressed: onCall, icon: const Icon(Icons.call_outlined), tooltip: l10n.driverClientPhone),
                   IconButton.filledTonal(onPressed: onMap, icon: const Icon(Icons.directions_outlined), tooltip: l10n.driverDeliveryAddress),
                 ],
               ),
               const SizedBox(height: AppSpacing.sm),
               // Row 4: item count + total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$itemCount ${l10n.driverOrderItems}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} ر.ي',
                    style: theme.textTheme.titleSmall?.copyWith(
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
    );
  }
}

// ── Status chip ────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (label, color, background) = switch (status) {
      'assigned' => (
          l10n.driverFilterAssigned,
          AppColors.primary,
          AppColors.secondaryContainer,
        ),
      'in_progress' => (
          l10n.driverFilterInProgress,
          AppColors.warning,
          AppColors.warningContainer,
        ),
      'delivered' => (
          l10n.driverFilterDelivered,
          AppColors.success,
          AppColors.successContainer,
        ),
      _ => (status, AppColors.outline, AppColors.surfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
