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

class BranchOrdersTab extends StatelessWidget {
  const BranchOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branch = context.watch<BranchController>();

    final filters = <String?, _FilterDef>{
      null: _FilterDef(label: l10n.branchOrderFilterAll, icon: LucideIcons.layoutGrid, gradient: BranchColors.glassHeroGradient),
      'pending': _FilterDef(label: l10n.branchOrderFilterPending, icon: LucideIcons.clock, gradient: BranchColors.metricOrangeGradient),
      'assigned': _FilterDef(label: l10n.branchOrderFilterAssigned, icon: LucideIcons.userCheck, gradient: BranchColors.metricBlueGradient),
      'in_progress': _FilterDef(label: l10n.branchOrderFilterInProgress, icon: LucideIcons.truck, gradient: BranchColors.metricPurpleGradient),
      'delivered': _FilterDef(label: l10n.branchOrderFilterDelivered, icon: LucideIcons.checkCircle, gradient: BranchColors.metricGreenGradient),
      'cancelled': _FilterDef(label: l10n.branchOrderFilterCancelled, icon: LucideIcons.xCircle, gradient: [BranchColors.error, BranchColors.danger]),
    };

    return Column(
      children: [
        // ── Page header ────────────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 68, 16, 0),
          child: BranchManagerHero(
            title: 'الطلبات',
            subtitle: 'استعرض وأدر جميع طلبات الفرع بسهولة.',
          ),
        ),

        // ── Modern Filter Chips ────────────────────────────────────────────
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final entry = filters.entries.elementAt(index);
              final selected = branch.orderFilter == entry.key;
              final def = entry.value;
              return _GlassFilterChip(
                label: def.label,
                icon: def.icon,
                gradient: def.gradient,
                selected: selected,
                onTap: () => branch.setOrderFilter(entry.key),
              );
            },
          ),
        ),

        // ── Count badge ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: BranchColors.glassHeroGradient),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: BranchColors.glassHeroGradient.first
                          .withValues(alpha: .25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Text(
                  '${branch.filteredOrders.length} طلب',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Orders List ────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: BranchColors.glassHeroGradient.first,
            backgroundColor: Colors.white,
            onRefresh: branch.loadOrders,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              children: [
                if (branch.ordersError != null) ...[
                  ErrorBanner(message: branch.ordersError!),
                  const SizedBox(height: 12),
                ],
                if (branch.isLoadingOrders && branch.orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (branch.filteredOrders.isEmpty)
                  _EmptyOrders()
                else
                  for (final order in branch.filteredOrders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BranchOrderCard(
                        order: order,
                        onTap: () => context.push('/branch/order/${order.id}'),
                        onAllocate: () => showAllocateSheet(context, order),
                        onAssignDriver: () =>
                            showAssignDriverDialog(context, order),
                        onTransfer: () =>
                            showTransferOrderDialog(context, order),
                        onReject: () => showRejectOrderConfirm(context, order),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Filter Definition ────────────────────────────────────────────────────────

class _FilterDef {
  const _FilterDef({
    required this.label,
    required this.icon,
    required this.gradient,
  });
  final String label;
  final IconData icon;
  final List<Color> gradient;
}

// ─── Glass Filter Chip ────────────────────────────────────────────────────────

class _GlassFilterChip extends StatelessWidget {
  const _GlassFilterChip({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: .78),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: .6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? gradient.first.withValues(alpha: .30)
                  : Colors.black.withValues(alpha: .04),
              blurRadius: selected ? 14 : 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : BranchColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : BranchColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: Colors.white.withValues(alpha: .5), width: 1.2),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: BranchColors.metricBlueGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    boxShadow: [
                      BoxShadow(
                        color: BranchColors.metricBlueGradient.first
                            .withValues(alpha: .3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child:
                      const Icon(LucideIcons.inbox, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد طلبات في هذه الحالة',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'جرّب تغيير الفلتر أو اسحب للأسفل للتحديث.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}