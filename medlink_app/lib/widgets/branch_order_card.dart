import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../utils/theme.dart';
import 'order_status_chip.dart';

/// Order card shown in the branch manager's orders tab. Exposes quick
/// actions (assign driver / transfer / reject) alongside a tap-through to
/// the full detail screen.
class BranchOrderCard extends StatelessWidget {
  const BranchOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onAssignDriver,
    required this.onTransfer,
    required this.onReject,
  });

  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback onAssignDriver;
  final VoidCallback onTransfer;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canAct = order.status == 'pending' || order.status == 'assigned';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.client?.name?.isNotEmpty == true
                          ? order.client!.name!
                          : '${l10n.orderNumber} ${order.id.substring(0, 8)}',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 2),
              if (order.deliveryAddress != null)
                Text(
                  order.deliveryAddress!.addressText,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} ﷼',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (order.assignedDriver?.name?.isNotEmpty == true)
                    Text(
                      '${l10n.branchDriversLabel}: ${order.assignedDriver!.name}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              if (canAct) ...[
                const Divider(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    if (order.status == 'pending')
                      OutlinedButton.icon(
                        onPressed: onAssignDriver,
                        icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                        label: Text(l10n.branchAssignDriver),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: onTransfer,
                      icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                      label: Text(l10n.branchTransferOrder),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    if (order.status == 'pending')
                      OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                        label: Text(
                          l10n.branchRejectOrder,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
