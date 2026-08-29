import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/branch_controller.dart';
import '../../utils/theme.dart';
import '../shared/coming_soon_scaffold.dart';
import 'branch_chat_tab.dart';
import 'branch_dashboard_tab.dart';
import 'branch_drivers_tab.dart';
import 'branch_floating_bottom_bar.dart';
import 'branch_inventory_tab.dart';
import 'branch_invoices_tab.dart';
import 'branch_manager_design.dart';
import 'branch_orders_tab.dart';
import 'branch_settings_sheet.dart';

/// Bottom-nav shell for the `branch_manager` role: soft pastel gradient
/// background, transparent app bar and a floating glass bottom bar with a
/// central quick-order FAB â€” all wrapped in [AppTheme.branchManagerLight].
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

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tabDefs = [
      (l10n.branchDashboardLabel, LucideIcons.layoutDashboard),
      (l10n.branchOrdersLabel, LucideIcons.clipboardList),
      (l10n.branchInventoryLabel, LucideIcons.boxes),
      (l10n.branchInvoicesLabel, LucideIcons.receipt),
      (l10n.branchDriversLabel, LucideIcons.truck),
      (l10n.chatTitle, LucideIcons.messageCircle),
    ];

    final branchId = context.watch<AuthController>().profile?.branchId;
    final tabs = [
      BranchDashboardTab(onNavigate: _select),
      const BranchOrdersTab(),
      const BranchInventoryTab(),
      const BranchInvoicesTab(),
      const BranchDriversTab(),
      const BranchChatTab(),
    ];

    return Theme(
      data: AppTheme.branchManagerLight,
      child: BranchGlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            toolbarHeight: 76,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tabDefs[_index].$1,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: BranchColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                ),
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
                icon: const Icon(LucideIcons.settings),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const BranchSettingsSheet(),
                ),
              ),
              const RoleAppBarActions(),
              const SizedBox(width: 4),
            ],
          ),
          body: branchId == null
              ? MissingAccountDataBody(
                  title: l10n.branchNotAssignedTitle,
                  message: l10n.branchNotAssignedMessage,
                )
              : tabs[_index],
          bottomNavigationBar: BranchFloatingBottomBar(
            items: [
              for (final tab in tabDefs)
                BranchBottomBarItem(icon: tab.$2, label: tab.$1),
            ],
            selectedIndex: _index,
            onSelect: _select,
            onFabPressed: () => _select(1),
          ),
        ),
      ),
    );
  }
}
