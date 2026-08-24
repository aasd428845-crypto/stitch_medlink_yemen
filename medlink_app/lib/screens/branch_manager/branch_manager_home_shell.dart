import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../shared/coming_soon_scaffold.dart';
import 'branch_chat_tab.dart';
import 'branch_dashboard_tab.dart';
import 'branch_drivers_tab.dart';
import 'branch_inventory_tab.dart';
import 'branch_invoices_tab.dart';
import 'branch_orders_tab.dart';
import 'branch_settings_sheet.dart';

/// Bottom-nav shell for the `branch_manager` role, wrapped in the light
/// design theme ([AppTheme.branchManagerLight]).
class BranchManagerHomeShell extends StatefulWidget {
  const BranchManagerHomeShell({super.key});

  @override
  State<BranchManagerHomeShell> createState() => _BranchManagerHomeShellState();
}

class _BranchManagerHomeShellState extends State<BranchManagerHomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final branchId = context.read<AuthController>().profile?.branchId;
      if (branchId != null) {
        context.read<BranchController>().initialize(branchId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabDefs = [
      (l10n.branchDashboardLabel, Icons.dashboard_outlined, Icons.dashboard_rounded),
      (l10n.branchOrdersLabel, Icons.list_alt_outlined, Icons.list_alt_rounded),
      (l10n.branchInventoryLabel, Icons.inventory_2_outlined, Icons.inventory_2_rounded),
      (l10n.branchInvoicesLabel, Icons.receipt_outlined, Icons.receipt_rounded),
      (l10n.branchDriversLabel, Icons.local_shipping_outlined, Icons.local_shipping_rounded),
      (l10n.chatTitle, Icons.chat_bubble_outline, Icons.chat_bubble_rounded),
    ];

    final branchId = context.watch<AuthController>().profile?.branchId;
    final tabs = [
      BranchDashboardTab(onNavigate: (i) => setState(() => _index = i)),
      const BranchOrdersTab(),
      const BranchInventoryTab(),
      const BranchInvoicesTab(),
      const BranchDriversTab(),
      const BranchChatTab(),
    ];

    return Theme(
      data: AppTheme.branchManagerLight,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tabDefs[_index].$1),
              Text(
                'MedLink · إدارة الفرع',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: BranchColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'الإعدادات',
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const BranchSettingsSheet(),
              ),
            ),
            const RoleAppBarActions(),
          ],
        ),
        body: Stack(
          children: [
            const _BranchPastelBackdrop(),
            Positioned.fill(
              child: branchId == null
                  ? MissingAccountDataBody(
                      title: l10n.branchNotAssignedTitle,
                      message: l10n.branchNotAssignedMessage,
                    )
                  : tabs[_index],
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Container(
            decoration: BoxDecoration(
              color: BranchColors.surfaceContainerLowest.withValues(alpha: .84),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: BranchColors.onPrimary.withValues(alpha: .8),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: BranchColors.primary.withValues(alpha: .13),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: NavigationBar(
              height: 72,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final tab in tabDefs)
                  NavigationDestination(
                    icon: Icon(tab.$2),
                    selectedIcon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: BranchColors.tabActiveGradient,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: BranchColors.primary.withValues(alpha: .24),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(tab.$3, color: BranchColors.onPrimary, size: 20),
                    ),
                    label: tab.$1,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchPastelBackdrop extends StatelessWidget {
  const _BranchPastelBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFF7F3FF),
            Color(0xFFF2F8FF),
            Color(0xFFFFF8F1),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -60,
            child: _PastelOrb(
              size: 250,
              color: BranchColors.primary.withValues(alpha: .08),
            ),
          ),
          Positioned(
            top: 260,
            left: -110,
            child: _PastelOrb(
              size: 220,
              color: const Color(0xFFB9EDE3).withValues(alpha: .16),
            ),
          ),
          Positioned(
            bottom: -120,
            right: 40,
            child: _PastelOrb(
              size: 280,
              color: const Color(0xFFFFDCCB).withValues(alpha: .16),
            ),
          ),
        ],
      ),
    );
  }
}

class _PastelOrb extends StatelessWidget {
  const _PastelOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}