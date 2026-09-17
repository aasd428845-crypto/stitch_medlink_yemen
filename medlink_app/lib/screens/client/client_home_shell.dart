import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/cart_controller.dart';
import '../../services/notification_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/app_logo.dart';
import 'account_tab.dart';
import 'catalog_tab.dart';
import 'client_design.dart';
import 'home_tab.dart';
import 'orders_tab.dart';

class ClientHomeShell extends StatefulWidget {
  const ClientHomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<ClientHomeShell> createState() => _ClientHomeShellState();
}

class _ClientHomeShellState extends State<ClientHomeShell> {
  late int _index = widget.initialIndex.clamp(0, 3).toInt();

  static const _tabs = [HomeTab(), CatalogTab(), OrdersTab(), AccountTab()];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final cart = context.watch<CartController>();
    final unreadNotifications =
      context.watch<NotificationController>().unreadCount;

    final tabDefs = [
      (l10n.clientHomeLabel, LucideIcons.home),
      (l10n.clientCatalogLabel, LucideIcons.grid3x3),
      (l10n.clientOrdersLabel, LucideIcons.clipboardList),
      (l10n.notificationsTitle, LucideIcons.bell),
      (l10n.clientProfileLabel, LucideIcons.user),
    ];

    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: ClientColors.background,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: ClientColors.surface,
          foregroundColor: ClientColors.text,
          scrolledUnderElevation: 0,
          elevation: 0,
          toolbarHeight: 76,
          titleSpacing: 16,
          title: _ClientBrandHeader(
            name: auth.profile?.name,
            branchName: auth.profile?.branchName,
          ),
          actions: [
            IconButton(
              tooltip: l10n.clientProfileLabel,
              onPressed: () => setState(() => _index = 4),
              icon: CircleAvatar(
                radius: 17,
                backgroundColor: ClientColors.primarySoft,
                foregroundColor: ClientColors.primaryDark,
                child: Text(
                  _initialOf(auth.profile?.name),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(bottom: 96),
          child: IndexedStack(index: _index, children: _tabs),
        ),
        bottomNavigationBar: ClientFloatingBottomBar(
          items: [
            for (var i = 0; i < tabDefs.length; i++)
              ClientBottomBarItem(
                icon: tabDefs[i].$2,
                label: tabDefs[i].$1,
                badgeCount: i == 3 ? unreadNotifications : 0,
              ),
          ],
          selectedIndex: _index == 3 ? 4 : _index,
          onSelect: (i) {
            if (i == 3) {
              context.push('/notifications');
            } else {
              setState(() => _index = i == 4 ? 3 : i);
            }
          },
          fabIcon: LucideIcons.shoppingCart,
          fabBadgeCount: cart.totalItemCount,
          onFabPressed: () => context.push('/client/cart'),
        ),
      ),
    );
  }

  String _initialOf(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'م' : trimmed.substring(0, 1);
  }
}

class _ClientBrandHeader extends StatelessWidget {
  const _ClientBrandHeader({this.name, this.branchName});

  final String? name;
  final String? branchName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final contextLabel = branchName?.trim().isNotEmpty == true
        ? branchName!
        : (name?.trim().isNotEmpty == true ? name! : l10n.clientAccountContext);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(
          size: 38,
          backgroundColor: ClientColors.primary,
          foregroundColor: Colors.white,
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MedLink Yemen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ClientColors.navy,
                fontWeight: FontWeight.w900,
                letterSpacing: -.2,
              ),
            ),
            Text(
              contextLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ClientColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
