import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/cart_controller.dart';
import '../../services/notification_controller.dart';
import '../../utils/theme.dart';
import '../branch_manager/branch_floating_bottom_bar.dart';
import '../branch_manager/branch_manager_design.dart';
import 'account_tab.dart';
import 'catalog_tab.dart';
import 'home_tab.dart';
import 'orders_tab.dart';

class ClientHomeShell extends StatefulWidget {
  const ClientHomeShell({super.key});

  @override
  State<ClientHomeShell> createState() => _ClientHomeShellState();
}

class _ClientHomeShellState extends State<ClientHomeShell> {
  int _index = 0;

  static const _tabs = [HomeTab(), CatalogTab(), OrdersTab(), AccountTab()];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cart = context.watch<CartController>();

    final tabDefs = [
      (l10n.clientHomeLabel, LucideIcons.home),
      (l10n.clientCatalogLabel, LucideIcons.grid3x3),
      (l10n.clientOrdersLabel, LucideIcons.clipboardList),
      (l10n.clientProfileLabel, LucideIcons.user),
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
            title: Text(tabDefs[_index].$1),
            actions: [
              Builder(
                builder: (context) {
                  final unread =
                      context.watch<NotificationController>().unreadCount;
                  return IconButton(
                    tooltip: l10n.notificationsTitle,
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      backgroundColor: BranchColors.danger,
                      label: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(color: BranchColors.onPrimary),
                      ),
                      child: const Icon(LucideIcons.bell),
                    ),
                    onPressed: () => context.push('/notifications'),
                  );
                },
              ),
              IconButton(
                icon: Badge(
                  isLabelVisible: cart.totalItemCount > 0,
                  backgroundColor: BranchColors.danger,
                  label: Text(
                    '${cart.totalItemCount}',
                    style: const TextStyle(color: BranchColors.onPrimary),
                  ),
                  child: const Icon(LucideIcons.shoppingCart),
                ),
                onPressed: () => context.push('/client/cart'),
              ),
            ],
          ),
           body: Padding(
             padding: const EdgeInsets.only(bottom: 96),
             child: IndexedStack(
               index: _index,
               children: _tabs,
             ),
           ),
          bottomNavigationBar: BranchFloatingBottomBar(
            items: [
              for (final tab in tabDefs)
                BranchBottomBarItem(icon: tab.$2, label: tab.$1),
            ],
            selectedIndex: _index,
            onSelect: (i) => setState(() => _index = i),
            // FAB يفتح سلة التسوق
            fabIcon: LucideIcons.shoppingCart,
            onFabPressed: () => context.push('/client/cart'),
          ),
        ),
      ),
    );
  }
}
