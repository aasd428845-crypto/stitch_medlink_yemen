import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

    final filters = <String?, String>{
      null: l10n.driverFilterAll,
      'assigned': l10n.driverFilterAssigned,
      'in_progress': l10n.driverFilterInProgress,
      'delivered': l10n.driverFilterDelivered,
    };

    return Column(
      children: [
        // ── Filter chips ───────────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            children: [
              for (final entry in filters.entries)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: ctrl.orderFilter == entry.key,
                    onSelected: (_) => ctrl.setOrderFilter(entry.key),
                  ),
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
                else if (ctrl.filteredOrders.isEmpty)
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
                  for (final order in ctrl.filteredOrders) ...[
                    _DriverOrderCard(
                      order: order,
                      onTap: () => context.push('/driver/order/${order.id}'),
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
}

// ── Order card ─────────────────────────────────────────────────────────────────

class _DriverOrderCard extends StatelessWidget {
  const _DriverOrderCard({required this.order, required this.onTap});

  final OrderModel order;
  final VoidCallback onTap;

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
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
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
