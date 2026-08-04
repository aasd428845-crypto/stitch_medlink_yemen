import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';

/// Completed (delivered) orders shown as invoices for the branch.
class BranchInvoicesTab extends StatefulWidget {
  const BranchInvoicesTab({super.key});

  @override
  State<BranchInvoicesTab> createState() => _BranchInvoicesTabState();
}

class _BranchInvoicesTabState extends State<BranchInvoicesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchController>().loadInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branch = context.watch<BranchController>();

    return RefreshIndicator(
      onRefresh: branch.loadInvoices,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (branch.invoicesError != null) ...[
            ErrorBanner(message: branch.invoicesError!),
            const SizedBox(height: AppSpacing.md),
          ],
          if (branch.isLoadingInvoices && branch.invoices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (branch.invoices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  l10n.branchNoInvoices,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            for (final invoice in branch.invoices)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: ListTile(
                  onTap: () => context.push('/branch/order/${invoice.id}'),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.successContainer,
                    child: Icon(Icons.receipt_long_rounded, color: AppColors.success),
                  ),
                  title: Text(
                    invoice.client?.name?.isNotEmpty == true
                        ? invoice.client!.name!
                        : '${l10n.orderNumber} ${invoice.id.substring(0, 8)}',
                  ),
                  subtitle: Text(invoice.createdAt?.substring(0, 10) ?? ''),
                  trailing: Text(
                    '${invoice.totalAmount.toStringAsFixed(0)} ﷼',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
