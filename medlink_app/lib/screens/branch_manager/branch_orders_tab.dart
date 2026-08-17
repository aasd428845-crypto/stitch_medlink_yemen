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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('الطلبات', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(99), border: Border.all(color: AppColors.primary.withValues(alpha: .22))),
                child: Text('${branch.filteredOrders.length} طلب', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final entry = filters.entries.elementAt(index);
              final selected = branch.orderFilter == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) => branch.setOrderFilter(entry.key),
                backgroundColor: const Color(0xFF0E1B2B),
                selectedColor: AppColors.primary.withValues(alpha: .16),
                side: BorderSide(color: selected ? AppColors.primary.withValues(alpha: .35) : const Color(0xFF29445A)),
                labelStyle: TextStyle(color: selected ? AppColors.primary : const Color(0xFF9FB1BD), fontWeight: FontWeight.w700, fontSize: 12),
                showCheckmark: false,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              );
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: const Color(0xFF102238),
            onRefresh: branch.loadOrders,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                if (branch.ordersError != null) ...[
                  ErrorBanner(message: branch.ordersError!),
                  const SizedBox(height: 12),
                ],
                if (branch.isLoadingOrders && branch.orders.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 55), child: Center(child: CircularProgressIndicator()))
                else if (branch.filteredOrders.isEmpty)
                  const BranchManagerSurface(
                    margin: EdgeInsets.only(top: 20),
                    child: Column(children: [
                      Icon(Icons.inbox_rounded, size: 38, color: Color(0xFF6E8798)),
                      SizedBox(height: 10),
                      Text('لا توجد طلبات في هذه الحالة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('جرّب تغيير الفلتر أو اسحب للأسفل للتحديث.', style: TextStyle(color: Color(0xFF8EA3B1), fontSize: 12)),
                    ]),
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
