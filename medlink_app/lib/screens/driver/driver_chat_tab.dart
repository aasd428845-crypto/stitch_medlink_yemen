import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/chat_controller.dart';
import '../../services/driver_orders_controller.dart';
import '../../utils/theme.dart';

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
    if (chat.isLoading) return const Center(child: CircularProgressIndicator());
    if (orders.isEmpty) return Center(child: Text(l10n.chatNoConversations));
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) {
        final order = orders[index];
        final matchingRooms = chat.rooms.where((r) => r.orderId == order.id);
        final room = matchingRooms.isEmpty ? null : matchingRooms.first;
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.chat_bubble_outline_rounded),
            ),
            title: Text('#${order.id.substring(0, 8).toUpperCase()}'),
            subtitle: Text(room?.lastMessage ?? l10n.chatWithBranch),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () async {
              try {
                final created =
                    room ??
                    await context.read<ChatController>().getOrCreateRoom(
                      orderId: order.id,
                      driverId: order.assignedDriverId!,
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
              } catch (_) {}
            },
          ),
        );
      },
    );
  }
}
