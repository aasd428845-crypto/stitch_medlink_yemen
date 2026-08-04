import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/branch_order_card.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/stat_card.dart';
import 'branch_order_actions.dart';

/// Branch manager landing tab: quick stat cards + the 5 most recent orders.
class BranchDashboardTab extends StatelessWidget {
  const BranchDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branch = context.watch<BranchController>();

    return RefreshIndicator(
      onRefresh: branch.loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (branch.ordersError != null) ...[
            ErrorBanner(message: branch.ordersError!),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: l10n.branchDashboardNewOrders,
                  value: branch.newOrdersCount,
                  icon: Icons.fiber_new_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  label: l10n.branchDashboardInProgress,
                  value: branch.inProgressOrdersCount,
                  icon: Icons.local_shipping_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatCard(
                  label: l10n.branchDashboardCompletedToday,
                  value: branch.completedTodayCount,
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.branchDashboardRecentOrders,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (branch.isLoadingOrders && branch.orders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (branch.recentOrders.isEmpty)
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
            for (final order in branch.recentOrders)
              BranchOrderCard(
                order: order,
                onTap: () => context.push('/branch/order/${order.id}'),
                onAssignDriver: () => showAssignDriverDialog(context, order),
                onTransfer: () => showTransferOrderDialog(context, order),
                onReject: () => showRejectOrderConfirm(context, order),
              ),
        ],
      ),
    );
  }
}
