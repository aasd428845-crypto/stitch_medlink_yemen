import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/chat_controller.dart';
import '../../utils/theme.dart';

class BranchChatTab extends StatefulWidget {
  const BranchChatTab({super.key});
  @override
  State<BranchChatTab> createState() => _BranchChatTabState();
}

class _BranchChatTabState extends State<BranchChatTab> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final branchId = context.read<AuthController>().profile?.branchId;
    if (branchId != null) {
      context.read<ChatController>().loadBranchRooms(branchId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chat = context.watch<ChatController>();
    if (chat.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (chat.rooms.isEmpty) {
      return Center(child: Text(l10n.chatNoConversations));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: chat.rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) {
        final room = chat.rooms[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.local_shipping_outlined),
            ),
            title: Text('#${room.orderId.substring(0, 8).toUpperCase()}'),
            subtitle: Text(room.driverName ?? l10n.chatWithDriver),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () => context.push(
              '/chat/${room.id}',
              extra: {
                'orderNumber': '#${room.orderId.substring(0, 8).toUpperCase()}',
                'otherPartyName': room.driverName ?? l10n.chatWithDriver,
              },
            ),
          ),
        );
      },
    );
  }
}
