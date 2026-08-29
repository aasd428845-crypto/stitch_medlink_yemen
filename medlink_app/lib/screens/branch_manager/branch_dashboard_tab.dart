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

/// Premium branch-manager dashboard: live summary, quick access, the real
/// statistics bento and the recent-orders list. Glassmorphism, safe-area
/// aware, overflow-proof.
class BranchDashboardTab extends StatelessWidget {
  const BranchDashboardTab({super.key, this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branch = context.watch<BranchController>();

    // 1) SafeArea keeps the pink hero clear of the system status bar; the extra
    // 76px top padding clears the transparent floating AppBar (settings /
    // notifications / sign-out) so nothing overlaps.
    return RefreshIndicator(
      color: BranchColors.primary,
      backgroundColor: BranchColors.background,
      onRefresh: () async {
        await branch.loadOrders();
        await branch.loadStats();
      },
      child: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          clipBehavior: Clip.none,
          physics: const AlwaysScrollableScrollPhysics(),
          // bottom padding (120) clears the floating bottom nav bar.
          padding: const EdgeInsets.fromLTRB(16, 76, 16, 120),
          children: [
            const BranchManagerHero(
              title: 'لوحة الفرع',
              subtitle: 'مركز التحكم اليومي بالطلبات والمخزون والسائقين والفواتير.',
            ),
            const SizedBox(height: 12),
            if (branch.ordersError != null) ...[
              ErrorBanner(message: branch.ordersError!),
              const SizedBox(height: 12),
            ],
            const BranchSectionTitle(title: 'ملخص اليوم'),
            const SizedBox(height: 8),
            // 2) No fixed height: a 2-column grid sized by childAspectRatio. The
            // card text is wrapped in FittedBox so it scales down instead of
            // overflowing its cell.
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                BranchMetricTile(
                    label: l10n.branchDashboardNewOrders,
                    value: '${branch.newOrdersCount}',
                    icon: Icons.notifications_active_rounded,
                    color: BranchColors.warning),
                BranchMetricTile(
                    label: l10n.branchDashboardInProgress,
                    value: '${branch.inProgressOrdersCount}',
                    icon: Icons.local_shipping_rounded,
                    color: BranchColors.primary),
                BranchMetricTile(
                    label: l10n.branchDashboardCompletedToday,
                    value: '${branch.completedTodayCount}',
                    icon: Icons.check_circle_rounded,
                    color: BranchColors.success),
                const BranchMetricTile(
                    label: 'مراقبة الفرع',
                    value: 'مباشر',
                    icon: Icons.monitor_heart_rounded,
                    color: BranchColors.primaryContainer),
              ],
            ),
            const SizedBox(height: 16),
            const BranchSectionTitle(title: 'الوصول السريع'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: BranchQuickAction(
                        icon: Icons.receipt_long_rounded,
                        label: 'الفواتير',
                        color: BranchColors.primary,
                        onTap: () => onNavigate?.call(3))),
                const SizedBox(width: 9),
                Expanded(
                    child: BranchQuickAction(
                        icon: Icons.inventory_2_rounded,
                        label: 'المخزون',
                        color: BranchColors.success,
                        onTap: () => onNavigate?.call(2))),
                const SizedBox(width: 9),
                Expanded(
                    child: BranchQuickAction(
                        icon: Icons.groups_rounded,
                        label: 'السائقون',
                        color: BranchColors.warning,
                        onTap: () => onNavigate?.call(4))),
                const SizedBox(width: 9),
                Expanded(
                    child: BranchQuickAction(
                        icon: Icons.chat_bubble_rounded,
                        label: 'المحادثات',
                        color: BranchColors.primaryContainer,
                        onTap: () => onNavigate?.call(5))),
              ],
            ),
            const SizedBox(height: 16),
            const BranchSectionTitle(title: 'الإحصائيات والتقارير'),
            const SizedBox(height: 8),
            _StatsBento(onNavigate: onNavigate),
            const SizedBox(height: 16),
            BranchSectionTitle(
                title: l10n.branchDashboardRecentOrders,
                action: 'كل الطلبات',
                onAction: () => onNavigate?.call(1)),
            const SizedBox(height: 8),
            if (branch.isLoadingOrders && branch.orders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (branch.recentOrders.isEmpty)
              const BranchManagerSurface(
                padding: EdgeInsets.symmetric(vertical: 28, horizontal: 18),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded,
                        color: BranchColors.onSurfaceVariant, size: 32),
                    SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('لا توجد طلبات حديثة',
                          style: TextStyle(
                              color: BranchColors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ),
                    SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('ستظهر الطلبات الجديدة هنا فور وصولها.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: BranchColors.onSurfaceVariant,
                              fontSize: 12)),
                    ),
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
                    onAllocate: () => showAllocateSheet(context, order),
                    onAssignDriver: () =>
                        showAssignDriverDialog(context, order),
                    onTransfer: () => showTransferOrderDialog(context, order),
                    onReject: () => showRejectOrderConfirm(context, order),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// The statistics bento: sales, completed orders, accuracy, the 7-day delivery
/// chart, top drivers, inventory alerts and the financial progress circle —
/// every number derived from real orders/invoices/catalog data.
class _StatsBento extends StatelessWidget {
  const _StatsBento({this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final branch = context.watch<BranchController>();
    final growth = branch.salesGrowthPercent;

    return Column(
      children: [
        // Sales
        BranchManagerSurface(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              PastelIconBadge(
                icon: Icons.trending_up_rounded,
                color: BranchColors.primary,
                shape: BoxShape.circle,
                size: 48,
                iconSize: 22,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text('مبيعات هذا الشهر',
                          style: TextStyle(
                              color: BranchColors.onSurfaceVariant,
                              fontSize: 12)),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${branch.salesThisMonth.toStringAsFixed(0)} ﷼',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: (growth >= 0 ? BranchColors.success : BranchColors.error)
                      .withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${growth >= 0 ? '▲' : '▼'} ${growth.abs()}%',
                  maxLines: 1,
                  style: TextStyle(
                    color: growth >= 0
                        ? BranchColors.success
                        : BranchColors.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                icon: Icons.task_alt_rounded,
                label: 'طلبات مكتملة هذا الشهر',
                value: '${branch.completedThisMonth}',
                color: BranchColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                icon: Icons.verified_user_rounded,
                label: 'دقة التخصيص',
                value: '${branch.allocationAccuracyPercent}%',
                color: BranchColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Weekly delivery chart
        BranchManagerSurface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text('سرعة التسليم (آخر ٧ أيام)',
                    style: TextStyle(
                        color: BranchColors.onSurface,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),
              _WeeklyChart(days: branch.weeklyDeliveries),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BranchManagerSurface(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text('أفضل السائقين',
                          style: TextStyle(
                              color: BranchColors.onSurface,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 10),
                    if (branch.topDrivers.isEmpty)
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text('لا توجد توصيلات بعد',
                            style: TextStyle(
                                color: BranchColors.onSurfaceVariant,
                                fontSize: 11)),
                      )
                    else
                      for (final (i, d) in branch.topDrivers.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: BranchColors.warning
                                      .withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Center(
                                  child: Text('${i + 1}',
                                      style: const TextStyle(
                                          color: BranchColors.warning,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(d.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12)),
                              ),
                              Text('${d.count}',
                                  style: const TextStyle(
                                      color: BranchColors.primary,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BranchManagerSurface(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text('تنبيهات المخزون',
                          style: TextStyle(
                              color: BranchColors.onSurface,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 10),
                    _AlertRow(
                      icon: Icons.warning_amber_rounded,
                      label: 'مخزون منخفض/نفد',
                      count: branch.lowStockCount,
                      color: BranchColors.warning,
                    ),
                    const SizedBox(height: 8),
                    _AlertRow(
                      icon: Icons.hourglass_bottom_rounded,
                      label: 'تنتهي قريباً',
                      count: branch.expiringSoonCount,
                      color: BranchColors.primary,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(34),
                          side: const BorderSide(
                              color: BranchColors.outlineVariant),
                        ),
                        onPressed: () => onNavigate?.call(2),
                        child: const Text('فتح المخزون',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Financial insights
        BranchManagerSurface(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 74,
                      height: 74,
                      child: CircularProgressIndicator(
                        value: branch.paidRatioPercent / 100,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: BranchColors.surfaceContainerHigh,
                        color: BranchColors.primary,
                      ),
                    ),
                    Text('${branch.paidRatioPercent}%',
                        style: const TextStyle(
                            color: BranchColors.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text('رؤى مالية',
                          style: TextStyle(
                              color: BranchColors.onSurface,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${branch.invoicesPaid.toStringAsFixed(0)} ﷼ مدفوعة من أصل ${branch.invoicesTotal.toStringAsFixed(0)} ﷼ — ${branch.pendingCount + branch.overdueCount} فاتورة قيد الانتظار.',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: BranchColors.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.5),
                    ),
                    if (branch.overdueCount > 0) ...[
                      const SizedBox(height: 5),
                      Text('${branch.overdueCount} متأخرة — تحتاج متابعة.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: BranchColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BranchManagerSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          PastelIconBadge(
              icon: icon,
              color: color,
              shape: BoxShape.circle,
              size: 38,
              iconSize: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(value,
                      style: const TextStyle(
                          color: BranchColors.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(label,
                      style: const TextStyle(
                          color: BranchColors.onSurfaceVariant,
                          fontSize: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PastelIconBadge(
            icon: icon,
            color: color,
            shape: BoxShape.circle,
            size: 26,
            iconSize: 13),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: BranchColors.onSurfaceVariant, fontSize: 11)),
        ),
        Text('$count',
            maxLines: 1,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12)),
      ],
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.days});

  final List<({DateTime day, int count})> days;

  @override
  Widget build(BuildContext context) {
    final maxCount =
        days.fold<int>(0, (m, d) => d.count > m ? d.count : m);
    const weekdays = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final d in days)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (d.count > 0)
                  Text('${d.count}',
                      maxLines: 1,
                      style: const TextStyle(
                          color: BranchColors.onSurfaceVariant,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Container(
                  height: 70,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 16,
                    height: maxCount == 0
                        ? 4
                        : (d.count / maxCount * 60).clamp(4.0, 60.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: BranchColors.tabActiveGradient,
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(weekdays[d.day.weekday - 1],
                    maxLines: 1,
                    style: const TextStyle(
                        color: BranchColors.onSurfaceVariant, fontSize: 9)),
              ],
            ),
          ),
      ],
    );
  }
}
