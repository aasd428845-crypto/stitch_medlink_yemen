import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/chat_controller.dart';
import '../../utils/theme.dart';
import 'branch_manager_design.dart';

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
    if (branchId != null) context.read<ChatController>().loadBranchRooms(branchId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chat = context.watch<ChatController>();
    if (chat.isLoading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        BranchManagerHero(title: l10n.chatTitle, subtitle: 'تواصل سريع مع السائقين لمتابعة الطلبات والتوصيلات.'),
        const SizedBox(height: AppSpacing.lg),
        if (chat.rooms.isEmpty)
          BranchManagerSurface(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [const Icon(Icons.forum_outlined, color: Color(0xFF63D9FF), size: 42), const SizedBox(height: 12), Text(l10n.chatNoConversations, style: const TextStyle(color: Color(0xFFA7BAC8)))])))
        else
          for (final room in chat.rooms)
            BranchManagerSurface(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.push('/chat/${room.id}', extra: {'orderNumber': '#${room.orderId.substring(0, 8).toUpperCase()}', 'otherPartyName': room.driverName ?? l10n.chatWithDriver}),
                child: Row(children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF63D9FF).withValues(alpha: .12), shape: BoxShape.circle), child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF63D9FF))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('#${room.orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(room.driverName ?? l10n.chatWithDriver, style: const TextStyle(color: Color(0xFF9DB0BE)))])),
                  const Icon(Icons.chevron_left_rounded, color: Color(0xFF688093)),
                ]),
              ),
            ),
      ],
    );
  }
}
