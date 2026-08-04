import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../shared/coming_soon_scaffold.dart';

/// Bottom-nav shell for the `client` role. Tabs are wired now; each body is
/// a real screen once its own batch lands (catalog, orders, profile).
class ClientHomeShell extends StatefulWidget {
  const ClientHomeShell({super.key});

  @override
  State<ClientHomeShell> createState() => _ClientHomeShellState();
}

class _ClientHomeShellState extends State<ClientHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      (l10n.clientHomeLabel, Icons.home_outlined, Icons.home_rounded),
      (l10n.clientCatalogLabel, Icons.grid_view_outlined, Icons.grid_view_rounded),
      (l10n.clientOrdersLabel, Icons.receipt_long_outlined, Icons.receipt_long_rounded),
      (l10n.clientProfileLabel, Icons.person_outline, Icons.person_rounded),
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
