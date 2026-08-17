import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/medlink_design.dart';
import 'driver_earnings_tab.dart';
import 'driver_chat_tab.dart';
import 'driver_orders_v2.dart';

class DriverHomeShell extends StatefulWidget {
  const DriverHomeShell({super.key});
  @override
  State<DriverHomeShell> createState() => _DriverHomeShellState();
}

class _DriverHomeShellState extends State<DriverHomeShell> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      (l10n.driverOrdersLabel, Icons.assignment_outlined, Icons.assignment_rounded),
      (l10n.driverEarningsLabel, Icons.payments_outlined, Icons.payments_rounded),
      (l10n.driverChatLabel, Icons.chat_bubble_outline, Icons.chat_bubble_rounded),
    ];
    return MedLinkScaffold(
      appBar: MedLinkTopBar(title: tabs[_index].$1, actions: const [RoleAppBarActions()]),
      body: IndexedStack(index: _index, children: const [DriverOrdersV2(), DriverEarningsTab(), DriverChatTab()]),
      bottomNavigationBar: MedLinkBottomNav(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [for (final tab in tabs) NavigationDestination(icon: Icon(tab.$2), selectedIcon: Icon(tab.$3), label: tab.$1)],
      ),
    );
  }
}
