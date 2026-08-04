import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../shared/coming_soon_scaffold.dart';

class BranchManagerHomeShell extends StatefulWidget {
  const BranchManagerHomeShell({super.key});

  @override
  State<BranchManagerHomeShell> createState() => _BranchManagerHomeShellState();
}

class _BranchManagerHomeShellState extends State<BranchManagerHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      (l10n.branchDashboardLabel, Icons.dashboard_outlined, Icons.dashboard_rounded),
      (l10n.branchInventoryLabel, Icons.inventory_2_outlined, Icons.inventory_2_rounded),
      (l10n.branchInvoicesLabel, Icons.receipt_outlined, Icons.receipt_rounded),
      (l10n.branchDriversLabel, Icons.local_shipping_outlined, Icons.local_shipping_rounded),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_index].$1),
        actions: const [RoleAppBarActions()],
      ),
      body: ComingSoonBody(label: tabs[_index].$1),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(icon: Icon(tab.$2), selectedIcon: Icon(tab.$3), label: tab.$1),
        ],
      ),
    );
  }
}
