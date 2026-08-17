import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';
import 'branch_manager_design.dart';

class BranchInvoicesTab extends StatefulWidget {
  const BranchInvoicesTab({super.key});
  @override
  State<BranchInvoicesTab> createState() => _BranchInvoicesTabState();
}

class _BranchInvoicesTabState extends State<BranchInvoicesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<BranchController>().loadInvoices());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branch = context.watch<BranchController>();
    final total = branch.invoices.fold<double>(0, (sum, item) => sum + item.totalAmount);

    return RefreshIndicator(
      onRefresh: branch.loadInvoices,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          BranchManagerHero(title: l10n.branchInvoicesLabel, subtitle: 'الفواتير المكتملة وسجل المبيعات الخاص بالفرع في مكان واحد.'),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: BranchMetricTile(label: 'عدد الفواتير', value: '${branch.invoices.length}', icon: Icons.receipt_long_rounded, color: const Color(0xFF63D9FF))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: BranchMetricTile(label: 'إجمالي المبيعات', value: '${total.toStringAsFixed(0)} ﷼', icon: Icons.payments_rounded, color: const Color(0xFF6DE7C8))),
          ]),
          const SizedBox(height: AppSpacing.lg),
          if (branch.invoicesError != null) ...[ErrorBanner(message: branch.invoicesError!), const SizedBox(height: AppSpacing.md)],
          const BranchSectionTitle(title: 'آخر الفواتير'),
          const SizedBox(height: AppSpacing.sm),
          if (branch.isLoadingInvoices && branch.invoices.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.xl), child: Center(child: CircularProgressIndicator()))
          else if (branch.invoices.isEmpty)
            BranchManagerSurface(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text(l10n.branchNoInvoices, style: const TextStyle(color: Color(0xFFA7BAC8))))) )
          else
            for (final invoice in branch.invoices)
              BranchManagerSurface(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(14),
                child: InkWell(
                  onTap: () => context.push('/branch/order/${invoice.id}'),
                  borderRadius: BorderRadius.circular(18),
                  child: Row(children: [
                    Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFF6DE7C8).withValues(alpha: .12), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF6DE7C8))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(invoice.client?.name?.isNotEmpty == true ? invoice.client!.name! : '${l10n.orderNumber} ${invoice.id.substring(0, 8)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(invoice.createdAt?.substring(0, 10) ?? '', style: const TextStyle(color: Color(0xFF8FA5B5), fontSize: 12)),
                    ])),
                    Text('${invoice.totalAmount.toStringAsFixed(0)} ﷼', style: const TextStyle(color: Color(0xFF63D9FF), fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_left_rounded, color: Color(0xFF688093)),
                  ]),
                ),
              ),
        ],
      ),
    );
  }
}
