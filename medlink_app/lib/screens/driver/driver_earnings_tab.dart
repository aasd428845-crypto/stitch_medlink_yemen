import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/driver_commission.dart';
import '../../services/driver_orders_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';

class DriverEarningsTab extends StatefulWidget {
  const DriverEarningsTab({super.key});

  @override
  State<DriverEarningsTab> createState() => _DriverEarningsTabState();
}

class _DriverEarningsTabState extends State<DriverEarningsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DriverOrdersController>().loadEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = context.watch<DriverOrdersController>();

    final now = DateTime.now();
    final thisMonth = now.month;
    final thisYear = now.year;
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;

    final isThisMonth =
        ctrl.selectedMonth == thisMonth && ctrl.selectedYear == thisYear;

    return RefreshIndicator(
      onRefresh: ctrl.loadEarnings,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Period selector ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _PeriodChip(
                  label: l10n.driverThisMonth,
                  selected: isThisMonth,
                  onTap: () => ctrl.setEarningsPeriod(thisMonth, thisYear),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PeriodChip(
                  label: l10n.driverLastMonth,
                  selected: !isThisMonth,
                  onTap: () =>
                      ctrl.setEarningsPeriod(lastMonth, lastMonthYear),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Error ────────────────────────────────────────────────────────
          if (ctrl.earningsError != null) ...[
            ErrorBanner(message: ctrl.earningsError!),
            const SizedBox(height: AppSpacing.md),
          ],

          // ── Loading ──────────────────────────────────────────────────────
          if (ctrl.isLoadingEarnings) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            // ── Summary cards ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.payments_rounded,
                    label: l10n.driverTotalEarningsLabel,
                    value: '${ctrl.totalEarnings.toStringAsFixed(0)} ر.ي',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.local_shipping_rounded,
                    label: l10n.driverTotalDeliveries,
                    value: '${ctrl.deliveredCount}',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Empty state ───────────────────────────────────────────────
            if (ctrl.earnings.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 48,
                        color: AppColors.outline,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.driverNoEarnings,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // ── Commission list ───────────────────────────────────────
              Text(
                l10n.driverOrderEarning,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final commission in ctrl.earnings) ...[
                _CommissionCard(commission: commission),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

// ── Period chip ────────────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: selected
              ? null
              : Border.all(color: AppColors.outlineVariant),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

// ── Summary card ───────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Commission card ────────────────────────────────────────────────────────────

class _CommissionCard extends StatelessWidget {
  const _CommissionCard({required this.commission});

  final DriverCommission commission;

  @override
  Widget build(BuildContext context) {
    final shortId = '#${commission.orderId.substring(0, 8).toUpperCase()}';
    final date = commission.createdAt;
    final dateStr =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

    final isPaid = commission.status == 'paid';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: AppSpacing.sm),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPaid ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shortId,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${commission.amount.toStringAsFixed(0)} ر.ي',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'من ${commission.orderTotalAmount.toStringAsFixed(0)} ر.ي',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
