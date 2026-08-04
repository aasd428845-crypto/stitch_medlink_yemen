import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';

/// Branch drivers roster with a live available/busy indicator derived from
/// currently assigned (non-final) orders.
class BranchDriversTab extends StatelessWidget {
  const BranchDriversTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branch = context.watch<BranchController>();

    return RefreshIndicator(
      onRefresh: () async {
        await branch.loadDrivers();
        await branch.loadOrders();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (branch.driversError != null) ...[
            ErrorBanner(message: branch.driversError!),
            const SizedBox(height: AppSpacing.md),
          ],
          if (branch.isLoadingDrivers && branch.drivers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (branch.drivers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  l10n.branchNoDrivers,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          else
            for (final driver in branch.drivers)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: branch.isDriverBusy(driver.id)
                        ? AppColors.warningContainer
                        : AppColors.successContainer,
                    child: Icon(
                      Icons.local_shipping_rounded,
                      color: branch.isDriverBusy(driver.id)
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ),
                  title: Text(driver.name?.isNotEmpty == true ? driver.name! : driver.email),
                  subtitle: Text(driver.phone ?? ''),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        branch.isDriverBusy(driver.id)
                            ? l10n.branchDriverBusy
                            : l10n.branchDriverAvailable,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: branch.isDriverBusy(driver.id)
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
                      Text(
                        '${branch.activeOrderCountFor(driver.id)} ${l10n.branchDriverActiveOrders}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
