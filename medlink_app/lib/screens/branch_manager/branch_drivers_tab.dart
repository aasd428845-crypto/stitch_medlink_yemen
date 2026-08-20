import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../services/branch_controller.dart';
import '../../services/branch_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/driver_rating_badge.dart';
import '../../widgets/error_banner.dart';
import 'branch_manager_design.dart';
import 'create_driver_sheet.dart';
import 'manage_driver_sheet.dart';

class BranchDriversTab extends StatelessWidget {
  const BranchDriversTab({super.key});

  void _create(BuildContext c) => showModalBottomSheet<void>(
        context: c,
        isScrollControlled: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: c.read<BranchController>(),
          child: const CreateDriverSheet(),
        ),
      );

  void _manage(BuildContext c, UserProfile d) => showModalBottomSheet<void>(
        context: c,
        isScrollControlled: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: c.read<BranchController>(),
          child: ManageDriverSheet(driver: d),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = context.watch<BranchController>();
    final busy = b.drivers.where((d) => b.isDriverBusy(d.id)).length;
    final available = b.drivers.length - busy;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await b.loadDrivers();
              await b.loadOrders();
            },
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    const BranchManagerHero(
                      title: 'إدارة المندوبين',
                      subtitle:
                          'راقب توفر السائقين وأداء التوصيل وإسناد الطلبات من شاشة واحدة.',
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: BranchMetricTile(
                          label: 'إجمالي السائقين',
                          value: '${b.drivers.length}',
                          icon: Icons.groups_rounded,
                          color: BranchColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BranchMetricTile(
                          label: 'متاحون الآن',
                          value: '$available',
                          icon: Icons.person_rounded,
                          color: BranchColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BranchMetricTile(
                          label: 'في مهام نشطة',
                          value: '$busy',
                          icon: Icons.route_rounded,
                          color: BranchColors.warning,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    if (b.driversError != null) ...[
                      ErrorBanner(message: b.driversError!),
                      const SizedBox(height: 12),
                    ],
                    BranchSectionTitle(title: 'السائقون'),
                    const SizedBox(height: 10),
                    if (b.isLoadingDrivers && b.drivers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (b.drivers.isEmpty)
                      BranchManagerSurface(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              size: 42,
                              color: BranchColors.primary,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.branchNoDrivers,
                              style: const TextStyle(
                                  color: BranchColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              icon: const Icon(Icons.add),
                              label: Text(l10n.driverCreateTitle),
                              onPressed: () => _create(context),
                            ),
                          ]),
                        ),
                      )
                    else
                      for (final d in b.drivers)
                        _DriverCard(
                          driver: d,
                          isBusy: b.isDriverBusy(d.id),
                          activeCount: b.activeOrderCountFor(d.id),
                          service: context.read<BranchService>(),
                          onTap: () => _manage(context, d),
                        ),
                  ],
                ),
                Positioned(
                  left: 16,
                  bottom: 110,
                  child: FloatingActionButton.extended(
                    onPressed: () => _create(context),
                    backgroundColor: BranchColors.primary,
                    foregroundColor: BranchColors.onPrimary,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('إضافة سائق',
                        style: TextStyle(fontWeight: FontWeight.w800)),
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

class _DriverCard extends StatefulWidget {
  const _DriverCard({
    required this.driver,
    required this.isBusy,
    required this.activeCount,
    required this.service,
    required this.onTap,
  });

  final UserProfile driver;
  final bool isBusy;
  final int activeCount;
  final BranchService service;
  final VoidCallback onTap;

  @override
  State<_DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<_DriverCard> {
  ({double? average, int count})? rating;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await widget.service.fetchDriverRatingSummary(widget.driver.id);
      if (mounted) setState(() => rating = r);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext c) {
    final l = AppLocalizations.of(c)!;
    final active = widget.driver.accountStatus == AccountStatus.active;
    final color = widget.isBusy ? BranchColors.warning : BranchColors.success;

    return BranchManagerSurface(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.onTap,
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_shipping_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.driver.name?.isNotEmpty == true
                      ? widget.driver.name!
                      : widget.driver.email,
                  style: const TextStyle(
                    color: BranchColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.driver.phone?.isNotEmpty == true)
                  Text(
                    widget.driver.phone!,
                    style: const TextStyle(
                      color: BranchColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 5),
                DriverRatingBadge(
                  average: rating?.average,
                  count: rating?.count ?? 0,
                  noRatingsLabel: l.noRatingsYet,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  widget.isBusy ? l.branchDriverBusy : l.branchDriverAvailable,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              if (!active)
                Text(
                  l.driverStatusSuspended,
                  style: const TextStyle(
                    color: BranchColors.warning,
                    fontSize: 10,
                  ),
                ),
              Text(
                '${widget.activeCount} ${l.branchDriverActiveOrders}',
                style: const TextStyle(
                  color: BranchColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.chevron_left_rounded,
            color: BranchColors.onSurfaceVariant,
          ),
        ]),
      ),
    );
  }
}