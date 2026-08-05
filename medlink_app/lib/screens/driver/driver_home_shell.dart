import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import '../shared/coming_soon_scaffold.dart';
import 'driver_earnings_tab.dart';
import 'driver_orders_tab.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_index].$1),
        actions: const [RoleAppBarActions()],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          const DriverOrdersTab(),
          const DriverEarningsTab(),
          // Chat tab — Phase 9 placeholder
          _DriverChatPlaceholder(label: l10n.driverChatLabel),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final tab in tabs)
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

class _DriverChatPlaceholder extends StatelessWidget {
  const _DriverChatPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 56,
            color: AppColors.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.driverChatComingSoon,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
