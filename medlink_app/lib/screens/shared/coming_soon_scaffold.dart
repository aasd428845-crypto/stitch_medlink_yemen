import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/notification_controller.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

/// Placeholder body used by role home screens for sections not yet built in
/// this batch. Each role screen still owns its real bottom navigation so the
/// shell and routing are final — only the tab content is a stub for now.
class ComingSoonBody extends StatelessWidget {
  const ComingSoonBody({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_rounded, size: 48, color: AppColors.outline),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.comingSoon,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Body shown instead of a role tab when the signed-in account is missing
/// data required to load that tab (e.g. a branch_manager whose `branch_id`
/// is null). This is deliberately distinct from [ComingSoonBody]: the
/// feature IS built, the account is just missing required setup — showing
/// the "under construction" wording here would be misleading.
class MissingAccountDataBody extends StatelessWidget {
  const MissingAccountDataBody({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AppBar actions shared across all role home shells:
/// - Help icon → /help
/// - Bell icon with unread badge → /notifications
/// - Logout
class RoleAppBarActions extends StatelessWidget {
  const RoleAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationController>().unreadCount;
    final l10n = AppLocalizations.of(context)!;
    final authCtrl = context.read<AuthController>();
    final role = authCtrl.profile?.role ?? UserRole.client;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.helpSupportTitle,
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: () => context.push('/help', extra: role),
        ),
        IconButton(
          tooltip: l10n.notificationsTitle,
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(
              unread > 9 ? '9+' : '$unread',
              style: const TextStyle(fontSize: 10),
            ),
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () => context.push('/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => authCtrl.signOut(),
        ),
      ],
    );
  }
}
