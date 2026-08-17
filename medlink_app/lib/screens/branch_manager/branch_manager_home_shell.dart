import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/branch_controller.dart';
import '../shared/coming_soon_scaffold.dart';
import 'branch_dashboard_tab.dart';
import 'branch_drivers_tab.dart';
import 'branch_inventory_tab.dart';
import 'branch_invoices_tab.dart';
import 'branch_orders_tab.dart';
import 'branch_chat_tab.dart';
import '../../widgets/medlink_design.dart';

/// Bottom-nav shell for the `branch_manager` role.
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

    return MedLinkScaffold(
      appBar: MedLinkTopBar(
        title: tabDefs[_index].$1,
        subtitle: 'MedLink · إدارة الفرع',
        actions: const [RoleAppBarActions()],
      ),
      body: branchId == null
          ? MissingAccountDataBody(
              title: l10n.branchNotAssignedTitle,
              message: l10n.branchNotAssignedMessage,
            )
          : tabs[_index],
      bottomNavigationBar: MedLinkBottomNav(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final tab in tabDefs)
            NavigationDestination(
              icon: Icon(tab.$2),
              selectedIcon: Icon(tab.$3),
              label: tab.$1,
            ),
        ],
      ),
    );
  }
}
