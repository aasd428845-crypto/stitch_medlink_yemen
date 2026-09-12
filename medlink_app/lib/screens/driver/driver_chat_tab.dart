import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../services/chat_controller.dart';
import '../../services/driver_orders_controller.dart';
import '../../utils/theme.dart';
import '../branch_manager/branch_manager_design.dart';
import 'driver_design.dart';

class DriverChatTab extends StatefulWidget {
  const DriverChatTab({super.key});
  @override
  State<DriverChatTab> createState() => _DriverChatTabState();
}

class _DriverChatTabState extends State<DriverChatTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ChatController>().loadDriverRooms(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chat = context.watch<ChatController>();
    final orders = context
        .watch<DriverOrdersController>()
        .orders
        .where(
          (order) =>
              order.status == 'assigned' || order.status == 'in_progress',
        )
        .toList();

    // Error state — show Arabic error with retry button instead of spinner
    if (chat.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                chat.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    context.read<ChatController>().loadDriverRooms(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    // Loading state — only show spinner during initial load
    if (chat.isLoading && chat.rooms.isEmpty) {
      return const GlassLoadingState(message: 'جارٍ تحميل المحادثات');
    }

    return Column(
      children: [
        DriverHero(
          title: l10n.driverChatLabel,
          subtitle: l10n.driverHeroSubtitle,
        ),
        Expanded(
          child: orders.isEmpty
              ? Center(
                  child: DriverSurface(
                    margin: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 44,
                          color: BranchColors.primary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.chatNoConversations,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, index) {
                    final order = orders[index];
                    final matchingRooms = chat.rooms.where(
                      (r) => r.orderId == order.id,
                    );
                    final room = matchingRooms.isEmpty
                        ? null
                        : matchingRooms.first;
                    return DriverSurface(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const PastelIconBadge(
                          icon: Icons.chat_bubble_outline_rounded,
                          color: BranchColors.primary,
                          size: 44,
                          iconSize: 20,
                          shape: BoxShape.circle,
                        ),
                        title: Text(
                          '#${order.id.substring(0, 8).toUpperCase()}',
                        ),
                        subtitle: Text(
                          room?.lastMessage ?? l10n.chatWithBranch,
                        ),
                        trailing: const Icon(Icons.chevron_left_rounded),
                        onTap: () async {
                          try {
                            final myId =
                                Supabase.instance.client.auth.currentUser?.id;
                            if (myId == null) return;
                            final created =
                                room ??
                                await context
                                    .read<ChatController>()
                                    .getOrCreateRoom(
                                      orderId: order.id,
                                      driverId: myId,
                                      branchId: order.branchId!,
                                    );
                            if (context.mounted) {
                              context.push(
                                '/chat/${created.id}',
                                extra: {
                                  'orderNumber':
                                      '#${order.id.substring(0, 8).toUpperCase()}',
                                  'otherPartyName': l10n.chatWithBranch,
                                },
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تعذر فتح المحادثة: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
