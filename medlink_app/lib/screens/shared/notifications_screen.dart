import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/notification_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/notification_tile.dart';

/// Notification centre — shared across all roles.
/// Accessible via the bell icon in the AppBar from any home shell.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = context.watch<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if (ctrl.unreadCount > 0)
            TextButton.icon(
              onPressed: ctrl.markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(l10n.notificationsMarkAllRead),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (ctrl.isLoading && ctrl.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ctrl.error != null && ctrl.notifications.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ErrorBanner(message: ctrl.error!),
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  onPressed: ctrl.loadNotifications,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            );
          }
          if (ctrl.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 56,
                    color: AppColors.outline,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.notificationsEmpty,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: ctrl.loadNotifications,
            child: ListView.separated(
              itemCount: ctrl.notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final notif = ctrl.notifications[i];
                return NotificationTile(
                  notification: notif,
                  onTap: () => ctrl.markAsRead(notif.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
