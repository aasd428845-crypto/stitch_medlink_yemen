import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/notification_model.dart';
import '../../services/notification_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/error_banner.dart';

/// Notification centre — shared across all roles.
/// Accessible via the bell icon in the AppBar from any home shell.
/// Uses a soft pastel gradient background to match the branch manager theme.
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

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BranchColors.glassBackgroundStart,
            Color(0xFFEFF0FF),
            BranchColors.glassBackgroundEnd,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: BranchColors.glassHeroGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: BranchColors.glassHeroGradient.first
                          .withValues(alpha: .28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child:
                    const Icon(LucideIcons.bell, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.notificationsTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: BranchColors.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          actions: [
            if (ctrl.unreadCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: ctrl.markAllAsRead,
                  icon: const Icon(LucideIcons.checkCheck,
                      size: 16, color: BranchColors.primary),
                  label: Text(
                    l10n.notificationsMarkAllRead,
                    style: const TextStyle(
                        color: BranchColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        body: Builder(
          builder: (context) {
            if (ctrl.isLoading && ctrl.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (ctrl.error != null && ctrl.notifications.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ErrorBanner(message: ctrl.error!),
                    const SizedBox(height: 16),
                    _GradientButton(
                      label: l10n.retry,
                      onPressed: ctrl.loadNotifications,
                    ),
                  ],
                ),
              );
            }

            if (ctrl.notifications.isEmpty) {
              return _EmptyNotifications(message: l10n.notificationsEmpty);
            }

            return RefreshIndicator(
              color: BranchColors.glassHeroGradient.first,
              backgroundColor: Colors.white,
              onRefresh: ctrl.loadNotifications,
              child: ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: ctrl.notifications.length,
                itemBuilder: (context, i) {
                  final notif = ctrl.notifications[i];
                  return _NotifCard(
                    notification: notif,
                    onTap: () => ctrl.markAsRead(notif.id),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.notification, required this.onTap});

  final NotificationModel notification;
  final VoidCallback onTap;

  IconData get _icon {
    return switch (notification.targetRole) {
      'client' => LucideIcons.user,
      'branch_manager' => LucideIcons.store,
      'driver' => LucideIcons.truck,
      _ => LucideIcons.bell,
    };
  }

  List<Color> get _gradient {
    return switch (notification.targetRole) {
      'client' => BranchColors.metricBlueGradient,
      'branch_manager' => BranchColors.metricPurpleGradient,
      'driver' => BranchColors.metricGreenGradient,
      _ => BranchColors.glassHeroGradient,
    };
  }

  String _formatDate(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} د';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isUnread
              ? BranchColors.glassHeroGradient.first.withValues(alpha: .04)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnread
                ? BranchColors.glassHeroGradient.first.withValues(alpha: .20)
                : Colors.grey.shade100,
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─ Icon ─
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _gradient.first.withValues(alpha: .28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(_icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),

              // ─ Content ─
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: BranchColors.onSurface,
                                  fontWeight: isUnread
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                  colors: BranchColors.glassWarmGradient),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BranchColors.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(LucideIcons.clock,
                            size: 11,
                            color: BranchColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(notification.createdAt),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: BranchColors.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 48, horizontal: 28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .80),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: Colors.white.withValues(alpha: .55), width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: BranchColors.glassHeroGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: BranchColors.glassHeroGradient.first
                              .withValues(alpha: .30),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Icon(LucideIcons.bellOff,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: BranchColors.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ستظهر تنبيهاتك هنا فور وصولها.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: BranchColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Gradient Button ──────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: BranchColors.glassHeroGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: BranchColors.glassHeroGradient.first
                  .withValues(alpha: .30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
