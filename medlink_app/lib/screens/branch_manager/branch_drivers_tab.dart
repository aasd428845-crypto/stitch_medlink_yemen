import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../services/branch_controller.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';
import 'create_driver_sheet.dart';
import 'manage_driver_sheet.dart';

/// Branch drivers roster.
///
/// • FAB → [CreateDriverSheet] (create a new driver account via Edge Function)
/// • Tap a driver card → [ManageDriverSheet] (activate/suspend/reset password)
class BranchDriversTab extends StatelessWidget {
  const BranchDriversTab({super.key});

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BranchController>(),
        child: const CreateDriverSheet(),
      ),
    );
  }

  void _openManageSheet(BuildContext context, UserProfile driver) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BranchController>(),
        child: ManageDriverSheet(driver: driver),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final branch = context.watch<BranchController>();

    return Scaffold(
      body: RefreshIndicator(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 48, color: AppColors.outline),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.branchNoDrivers,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(l10n.driverCreateTitle),
                        onPressed: () => _openCreateSheet(context),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final driver in branch.drivers)
                _DriverCard(
                  driver: driver,
                  isBusy: branch.isDriverBusy(driver.id),
                  activeCount: branch.activeOrderCountFor(driver.id),
                  onTap: () => _openManageSheet(context, driver),
                ),
          ],
        ),
      ),
      floatingActionButton: branch.drivers.isEmpty
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.person_add_rounded),
              label: Text(l10n.driverCreateTitle),
              onPressed: () => _openCreateSheet(context),
            ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({
    required this.driver,
    required this.isBusy,
    required this.activeCount,
    required this.onTap,
  });

  final UserProfile driver;
  final bool isBusy;
  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = driver.accountStatus == AccountStatus.active;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isBusy
                    ? AppColors.warningContainer
                    : AppColors.successContainer,
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: isBusy ? AppColors.warning : AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name?.isNotEmpty == true
                          ? driver.name!
                          : driver.email,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (driver.phone?.isNotEmpty == true)
                      Text(
                        driver.phone!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Busy / available badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: isBusy
                          ? AppColors.warningContainer
                          : AppColors.successContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      isBusy ? l10n.branchDriverBusy : l10n.branchDriverAvailable,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: isBusy ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Account status badge (only show if not active)
                  if (!isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warningContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        l10n.driverStatusSuspended,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '$activeCount ${l10n.branchDriverActiveOrders}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}
