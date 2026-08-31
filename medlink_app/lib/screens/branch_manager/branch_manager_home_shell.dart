import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/branch_controller.dart';
import '../../services/notification_controller.dart';
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
    final unreadCount =
        context.watch<NotificationController>().unreadCount;

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
            toolbarHeight: 60,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            title: null,
            actions: [
              // ── Notification bell with unread badge ──
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: l10n.notificationsTitle,
                    icon: const Icon(LucideIcons.bell),
                    onPressed: () => context.push('/notifications'),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IgnorePointer(
                        child: Container(
                          width: 16,
                          height: 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: BranchColors.glassWarmGradient,
                            ),
                            border:
                                Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // ── Settings ──
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
