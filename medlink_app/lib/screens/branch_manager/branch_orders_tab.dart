import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/branch_order_card.dart';
import '../../widgets/error_banner.dart';
import 'branch_order_actions.dart';

/// Full incoming-orders list with status filter chips.
class BranchOrdersTab extends StatelessWidget {
  const BranchOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branch = context.watch<BranchController>();

    final filters = <String?, String>{
      null: l10n.branchOrderFilterAll,
      'pending': l10n.branchOrderFilterPending,
      'assigned': l10n.branchOrderFilterAssigned,
      'in_progress': l10n.branchOrderFilterInProgress,
      'delivered': l10n.branchOrderFilterDelivered,
      'cancelled': l10n.branchOrderFilterCancelled,
    };

    return Column(
      children: [
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
                    selected: branch.orderFilter == entry.key,
                    onSelected: (_) => branch.setOrderFilter(entry.key),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: branch.loadOrders,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (branch.ordersError != null) ...[
                  ErrorBanner(message: branch.ordersError!),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (branch.isLoadingOrders && branch.orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (branch.filteredOrders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: Text(
                        l10n.noOrdersFound,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  for (final order in branch.filteredOrders)
                    BranchOrderCard(
                      order: order,
                      onTap: () => context.push('/branch/order/${order.id}'),
                      onAssignDriver: () => showAssignDriverDialog(context, order),
                      onTransfer: () => showTransferOrderDialog(context, order),
                      onReject: () => showRejectOrderConfirm(context, order),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
