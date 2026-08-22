import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/cart_controller.dart';
import '../../widgets/medlink_design.dart';
import 'account_tab.dart';
import 'catalog_tab.dart';
import 'home_tab.dart';
import 'orders_tab.dart';

/// Bottom-nav shell for the `client` role.
/// Tab 0 → HomeTab (offers + categories + products)
/// Tab 1 → CatalogTab (full catalog + search + filter)
/// Tab 2 → OrdersTab (active & previous orders)
/// Tab 3 → Account hub
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
      (l10n.clientHomeLabel, Icons.home_outlined, Icons.home_rounded),
      (
        l10n.clientCatalogLabel,
        Icons.grid_view_outlined,
        Icons.grid_view_rounded,
      ),
      (
        l10n.clientOrdersLabel,
        Icons.receipt_long_outlined,
        Icons.receipt_long_rounded,
      ),
      (l10n.clientProfileLabel, Icons.person_outline, Icons.person_rounded),
    ];

    final body = _tabs[_index];

    return MedLinkScaffold(
      appBar: MedLinkTopBar(
        title: tabDefs[_index].$1,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: cart.totalItemCount > 0,
              label: Text('${cart.totalItemCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => context.push('/client/cart'),
          ),
          const RoleAppBarActions(),
        ],
      ),
      body: body,
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
