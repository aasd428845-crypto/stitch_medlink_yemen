import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';
import '../branch_manager/branch_floating_bottom_bar.dart';
import '../branch_manager/branch_manager_design.dart';
import '../shared/coming_soon_scaffold.dart';
import 'driver_chat_tab.dart';
import 'driver_earnings_tab.dart';
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
      (l10n.driverOrdersLabel, LucideIcons.clipboardList),
      (l10n.driverEarningsLabel, LucideIcons.banknote),
      (l10n.driverChatLabel, LucideIcons.messageCircle),
    ];

    return Theme(
      data: AppTheme.branchManagerLight,
      child: BranchGlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: BranchColors.onSurface,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            title: Text(tabs[_index].$1),
            actions: [RoleAppBarActions()],
          ),
          body: IndexedStack(
            index: _index,
            children: const [
              DriverOrdersV2(),
              DriverEarningsTab(),
              DriverChatTab(),
            ],
          ),
          bottomNavigationBar: BranchFloatingBottomBar(
            items: [
              for (final tab in tabs)
                BranchBottomBarItem(icon: tab.$2, label: tab.$1),
            ],
            selectedIndex: _index,
            onSelect: (i) => setState(() => _index = i),
            // FAB toggles quick order accept / navigate back to orders
            fabIcon: LucideIcons.navigation,
            onFabPressed: () => setState(() => _index = 0),
          ),
        ),
      ),
    );
  }
}
