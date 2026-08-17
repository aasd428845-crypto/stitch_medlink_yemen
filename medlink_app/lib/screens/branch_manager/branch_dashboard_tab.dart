import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/branch_order_card.dart';
import '../../widgets/error_banner.dart';
import 'branch_manager_design.dart';
import 'branch_order_actions.dart';

/// Premium branch-manager dashboard. Business logic and controller contracts
/// are intentionally preserved; this file changes presentation only.
class BranchDashboardTab extends StatelessWidget {
  const BranchDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branch = context.watch<BranchController>();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: const Color(0xFF102238),
      onRefresh: branch.loadOrders,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
        children: [
          const BranchManagerHero(
            title: 'لوحة الفرع',
            subtitle: 'مركز التحكم اليومي بالطلبات والمخزون والسائقين والفواتير.',
          ),
          const SizedBox(height: 18),
          if (branch.ordersError != null) ...[
            ErrorBanner(message: branch.ordersError!),
            const SizedBox(height: 14),
          ],
          BranchSectionTitle(title: 'ملخص اليوم'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              BranchMetricTile(label: l10n.branchDashboardNewOrders, value: branch.newOrdersCount, icon: Icons.notifications_active_rounded, color: AppColors.warning),
              BranchMetricTile(label: l10n.branchDashboardInProgress, value: branch.inProgressOrdersCount, icon: Icons.local_shipping_rounded, color: AppColors.primary),
              BranchMetricTile(label: l10n.branchDashboardCompletedToday, value: branch.completedTodayCount, icon: Icons.task_alt_rounded, color: AppColors.success),
              const BranchMetricTile(label: 'مراقبة الفرع', value: 'مباشر', icon: Icons.monitor_heart_rounded, color: Color(0xFF9B8CFF)),
            ],
          ),
          const SizedBox(height: 22),
          BranchSectionTitle(title: 'الوصول السريع'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: BranchQuickAction(icon: Icons.receipt_long_rounded, label: 'الفواتير', color: const Color(0xFF8C9EFF), onTap: () => _openTab(context, 3))),
              const SizedBox(width: 9),
              Expanded(child: BranchQuickAction(icon: Icons.inventory_2_rounded, label: 'المخزون', color: const Color(0xFF5AD9B6), onTap: () => _openTab(context, 2))),
              const SizedBox(width: 9),
              Expanded(child: BranchQuickAction(icon: Icons.groups_rounded, label: 'السائقون', color: const Color(0xFFFFB86B), onTap: () => _openTab(context, 4))),
              const SizedBox(width: 9),
              Expanded(child: BranchQuickAction(icon: Icons.chat_bubble_rounded, label: 'المحادثات', color: const Color(0xFF66E4E0), onTap: () => _openTab(context, 5))),
            ],
          ),
          const SizedBox(height: 24),
          BranchSectionTitle(title: l10n.branchDashboardRecentOrders, action: 'كل الطلبات', onAction: () => _openTab(context, 1)),
          const SizedBox(height: 10),
          if (branch.isLoadingOrders && branch.orders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (branch.recentOrders.isEmpty)
            const BranchManagerSurface(
              padding: EdgeInsets.symmetric(vertical: 32, horizontal: 18),
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, color: Color(0xFF6E8798), size: 36),
                  SizedBox(height: 10),
                  Text('لا توجد طلبات حديثة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('ستظهر الطلبات الجديدة هنا فور وصولها.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8EA3B1), fontSize: 12)),
                ],
              ),
            )
          else
            for (final order in branch.recentOrders)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BranchOrderCard(
                  order: order,
                  onTap: () => context.push('/branch/order/${order.id}'),
                  onAssignDriver: () => showAssignDriverDialog(context, order),
                  onTransfer: () => showTransferOrderDialog(context, order),
                  onReject: () => showRejectOrderConfirm(context, order),
                ),
              ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  static void _openTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_BranchManagerHomeShellStateProxy>();
    state?.select(index);
  }
}

/// Interface used by the shell without coupling the dashboard to its private
/// State implementation.
abstract class _BranchManagerHomeShellStateProxy extends State<StatefulWidget> {
  void select(int index);
}
