import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/branch_order_card.dart';
import '../../widgets/error_banner.dart';
import 'branch_manager_design.dart';
import 'branch_order_actions.dart';

/// Premium branch-manager dashboard: animated hero, glassmorphism metric tiles,
/// gradient quick-actions, stats bento, and recent-orders list.
class BranchDashboardTab extends StatelessWidget {
  const BranchDashboardTab({super.key, this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branch = context.watch<BranchController>();

    return RefreshIndicator(
      color: BranchColors.glassHeroGradient.first,
      backgroundColor: Colors.white,
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
          // 76 → clears transparent AppBar; 120 → clears floating bottom bar
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 120),
          children: [
            // ── Hero ───────────────────────────────────────────────────────
            const BranchManagerHero(
              title: 'لوحة الفرع',
              subtitle:
                  'مركز التحكم اليومي بالطلبات والمخزون والسائقين والفواتير.',
            ),
            const SizedBox(height: 10),

            // ── Error ──────────────────────────────────────────────────────
            if (branch.ordersError != null) ...[
              ErrorBanner(message: branch.ordersError!),
              const SizedBox(height: 10),
            ],

            // ── Metrics ────────────────────────────────────────────────────
            BranchSectionTitle(
              title: 'ملخص اليوم',
              icon: LucideIcons.barChart2,
              iconColor: BranchColors.glassHeroGradient.first,
            ),
            const SizedBox(height: 10),
            _MetricGrid(
              newOrders: branch.newOrdersCount,
              inProgress: branch.inProgressOrdersCount,
              completedToday: branch.completedTodayCount,
              l10n: l10n,
            ),
            const SizedBox(height: 20),

            // ── Quick Actions ──────────────────────────────────────────────
            BranchSectionTitle(
              title: 'الوصول السريع',
              icon: LucideIcons.zap,
              iconColor: BranchColors.metricOrangeGradient.first,
            ),
            const SizedBox(height: 10),
            _QuickActionsRow(onNavigate: onNavigate),
            const SizedBox(height: 20),

            // ── Stats Bento ────────────────────────────────────────────────
            BranchSectionTitle(
              title: 'الإحصائيات والتقارير',
              icon: LucideIcons.pieChart,
              iconColor: BranchColors.metricBlueGradient.first,
            ),
            const SizedBox(height: 10),
            _StatsBento(onNavigate: onNavigate),
            const SizedBox(height: 20),

            // ── Recent Orders ──────────────────────────────────────────────
            BranchSectionTitle(
              title: l10n.branchDashboardRecentOrders,
              action: 'كل الطلبات',
              onAction: () => onNavigate?.call(1),
              icon: LucideIcons.clipboardList,
              iconColor: BranchColors.metricGreenGradient.first,
            ),
            const SizedBox(height: 10),
            if (branch.isLoadingOrders && branch.orders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (branch.recentOrders.isEmpty)
              _EmptyOrders()
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

// ─── Metric Grid ──────────────────────────────────────────────────────────────

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.newOrders,
    required this.inProgress,
    required this.completedToday,
    required this.l10n,
  });

  final int newOrders;
  final int inProgress;
  final int completedToday;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // 2-column grid, uses fixed aspect ratio — titles are short Arabic labels
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        BranchMetricTile(
          label: l10n.branchDashboardNewOrders,
          value: '$newOrders',
          icon: LucideIcons.bell,
          color: BranchColors.warning,
        ),
        BranchMetricTile(
          label: l10n.branchDashboardInProgress,
          value: '$inProgress',
          icon: LucideIcons.truck,
          color: BranchColors.primary,
        ),
        BranchMetricTile(
          label: l10n.branchDashboardCompletedToday,
          value: '$completedToday',
          icon: LucideIcons.checkCircle,
          color: BranchColors.success,
        ),
        const BranchMetricTile(
          label: 'مراقبة الفرع',
          value: 'مباشر',
          icon: LucideIcons.activity,
          color: BranchColors.primaryContainer,
        ),
      ],
    );
  }
}

// ─── Quick Actions Row ────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BranchQuickAction(
            icon: LucideIcons.receipt,
            label: 'الفواتير',
            color: BranchColors.primary,
            gradient: BranchColors.pastelBluGradient,
            onTap: () => onNavigate?.call(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BranchQuickAction(
            icon: LucideIcons.boxes,
            label: 'المخزون',
            color: BranchColors.success,
            gradient: BranchColors.pastelGreenGradient,
            onTap: () => onNavigate?.call(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BranchQuickAction(
            icon: LucideIcons.users,
            label: 'السائقون',
            color: BranchColors.warning,
            gradient: BranchColors.pastelAmberGradient,
            onTap: () => onNavigate?.call(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BranchQuickAction(
            icon: LucideIcons.messageCircle,
            label: 'المحادثات',
            color: BranchColors.primaryContainer,
            gradient: BranchColors.pastelVioletGradient,
            onTap: () => onNavigate?.call(5),
          ),
        ),
      ],
    );
  }
}

// ─── Stats Bento ─────────────────────────────────────────────────────────────

/// Statistics bento: sales, completed orders, accuracy, 7-day chart,
/// top drivers, inventory alerts, and financial progress — all from live data.
class _StatsBento extends StatelessWidget {
  const _StatsBento({this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final branch = context.watch<BranchController>();
    final growth = branch.salesGrowthPercent;
    final isUp = growth >= 0;

    return Column(
      children: [
        // ── Sales card ──────────────────────────────────────────────────
        _GlassBentoCard(
          child: Row(
            children: [
              PastelIconBadge(
                icon: LucideIcons.trendingUp,
                color: BranchColors.primary,
                gradient: BranchColors.metricBlueGradient,
                shape: BoxShape.circle,
                size: 52,
                iconSize: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مبيعات هذا الشهر',
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${branch.salesThisMonth.toStringAsFixed(0)} ﷼',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: BranchColors.onSurface,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Growth badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUp
                        ? BranchColors.metricGreenGradient
                        : [BranchColors.error, BranchColors.danger],
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${isUp ? '▲' : '▼'} ${growth.abs()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Two mini stats ──────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                icon: LucideIcons.checkCircle,
                label: 'طلبات مكتملة هذا الشهر',
                value: '${branch.completedThisMonth}',
                gradient: BranchColors.metricGreenGradient,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                icon: LucideIcons.shieldCheck,
                label: 'دقة التخصيص',
                value: '${branch.allocationAccuracyPercent}%',
                gradient: BranchColors.metricBlueGradient,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Weekly delivery chart ───────────────────────────────────────
        _GlassBentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PastelIconBadge(
                    icon: LucideIcons.barChart2,
                    color: BranchColors.primary,
                    gradient: BranchColors.glassPrimaryGradient,
                    shape: BoxShape.circle,
                    size: 36,
                    iconSize: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'سرعة التسليم (آخر ٧ أيام)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _WeeklyChart(days: branch.weeklyDeliveries),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Top drivers + Inventory alerts ──────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _GlassBentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PastelIconBadge(
                          icon: LucideIcons.award,
                          color: BranchColors.warning,
                          gradient: BranchColors.metricOrangeGradient,
                          shape: BoxShape.circle,
                          size: 32,
                          iconSize: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('أفضل السائقين',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (branch.topDrivers.isEmpty)
                      Text('لا توجد توصيلات بعد',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: BranchColors.onSurfaceVariant))
                    else
                      for (final (i, d) in branch.topDrivers.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: BranchColors.metricOrangeGradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text('${i + 1}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(d.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: BranchColors.primary
                                      .withValues(alpha: .10),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text('${d.count}',
                                    style: TextStyle(
                                        color: BranchColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlassBentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PastelIconBadge(
                          icon: LucideIcons.alertTriangle,
                          color: BranchColors.warning,
                          gradient: BranchColors.metricOrangeGradient,
                          shape: BoxShape.circle,
                          size: 32,
                          iconSize: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('تنبيهات المخزون',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _AlertRow(
                      icon: LucideIcons.alertCircle,
                      label: 'منخفض / نفد',
                      count: branch.lowStockCount,
                      gradient: BranchColors.metricOrangeGradient,
                    ),
                    const SizedBox(height: 8),
                    _AlertRow(
                      icon: LucideIcons.clock,
                      label: 'تنتهي قريباً',
                      count: branch.expiringSoonCount,
                      gradient: BranchColors.metricBlueGradient,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _GradientButton(
                        label: 'فتح المخزون',
                        onPressed: () => onNavigate?.call(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Financial insights ──────────────────────────────────────────
        _GlassBentoCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular progress
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: branch.paidRatioPercent / 100,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor:
                            BranchColors.metricBlueGradient.first
                                .withValues(alpha: .12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          BranchColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      '${branch.paidRatioPercent}%',
                      style: const TextStyle(
                        color: BranchColors.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PastelIconBadge(
                          icon: LucideIcons.dollarSign,
                          color: BranchColors.success,
                          gradient: BranchColors.metricGreenGradient,
                          shape: BoxShape.circle,
                          size: 30,
                          iconSize: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'رؤى مالية',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${branch.invoicesPaid.toStringAsFixed(0)} ﷼ مدفوعة من أصل '
                      '${branch.invoicesTotal.toStringAsFixed(0)} ﷼ — '
                      '${branch.pendingCount + branch.overdueCount} فاتورة قيد الانتظار.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.6,
                          ),
                    ),
                    if (branch.overdueCount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(LucideIcons.alertCircle,
                              color: BranchColors.error, size: 13),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '${branch.overdueCount} فاتورة متأخرة',
                              maxLines: 1,
                              style: const TextStyle(
                                color: BranchColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
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

// ─── Bento Card Wrapper ───────────────────────────────────────────────────────

class _GlassBentoCard extends StatelessWidget {
  const _GlassBentoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: .5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Mini Stat ────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return _GlassBentoCard(
      child: Row(
        children: [
          PastelIconBadge(
            icon: icon,
            color: gradient.first,
            gradient: gradient,
            shape: BoxShape.circle,
            size: 40,
            iconSize: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: BranchColors.onSurface,
                        ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: BranchColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Alert Row ────────────────────────────────────────────────────────────────

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final int count;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PastelIconBadge(
          icon: icon,
          color: gradient.first,
          gradient: gradient,
          shape: BoxShape.circle,
          size: 28,
          iconSize: 13,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: BranchColors.onSurfaceVariant)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Gradient Button ──────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: BranchColors.glassPrimaryGradient,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:
                  BranchColors.glassPrimaryGradient.first.withValues(alpha: .35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Weekly Chart ─────────────────────────────────────────────────────────────

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.days});

  final List<({DateTime day, int count})> days;

  @override
  Widget build(BuildContext context) {
    final maxCount = days.fold<int>(0, (m, d) => d.count > m ? d.count : m);
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
                  Text(
                    '${d.count}',
                    maxLines: 1,
                    style: TextStyle(
                      color: BranchColors.metricBlueGradient.first,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  height: 72,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 18,
                    height: maxCount == 0
                        ? 4
                        : (d.count / maxCount * 64).clamp(4.0, 64.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: d.count > 0
                            ? BranchColors.glassPrimaryGradient
                            : [
                                BranchColors.outlineVariant,
                                BranchColors.outlineVariant
                              ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: d.count > 0
                          ? [
                              BoxShadow(
                                color: BranchColors.glassPrimaryGradient.first
                                    .withValues(alpha: .3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  weekdays[d.day.weekday - 1],
                  maxLines: 1,
                  style: const TextStyle(
                    color: BranchColors.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: .45), width: 1.2),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BranchColors.outlineVariant.withValues(alpha: .4),
                ),
                child: const Icon(LucideIcons.inbox,
                    color: BranchColors.onSurfaceVariant, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                'لا توجد طلبات حديثة',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'ستظهر الطلبات الجديدة هنا فور وصولها.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
