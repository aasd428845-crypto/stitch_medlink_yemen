import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    if (branchId != null) {
      context.read<ChatController>().loadBranchRooms(branchId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chat = context.watch<ChatController>();
    final branchId = context.watch<AuthController>().profile?.branchId;

    // No branch ID — show message instead of infinite spinner
    if (branchId == null) {
      return const Center(
        child: Text('لم يتم تعيين فرع لهذا الحساب.'),
      );
    }

    // Loading only when truly waiting for first data
    if (chat.isLoading && chat.rooms.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        // ── Hero header ──────────────────────────────────────────────────
        const BranchManagerHero(
          title: 'المحادثات',
          subtitle: 'تواصل سريع مع السائقين لمتابعة الطلبات.',
        ),
        const SizedBox(height: 20),

        // ── Empty state ──────────────────────────────────────────────────
        if (chat.rooms.isEmpty)
          _ChatEmptyState(message: l10n.chatNoConversations)
        else ...[
          // Count badge
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: BranchColors.metricBlueGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: BranchColors.metricBlueGradient.first
                      .withValues(alpha: .28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Text(
              '${chat.rooms.length} محادثة',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12),
            ),
          ),

          // Room cards
          for (final room in chat.rooms) _ChatRoomCard(room: room, l10n: l10n),
        ],
      ],
    );
  }
}

// ─── Chat Room Card ───────────────────────────────────────────────────────────

class _ChatRoomCard extends StatefulWidget {
  const _ChatRoomCard({required this.room, required this.l10n});

  final dynamic room;
  final dynamic l10n;

  @override
  State<_ChatRoomCard> createState() => _ChatRoomCardState();
}

class _ChatRoomCardState extends State<_ChatRoomCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final orderId = '#${(room.orderId as String).substring(0, 8).toUpperCase()}';
    final driverName =
        (room.driverName as String?) ?? widget.l10n.chatWithDriver as String;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.push(
          '/chat/${room.id}',
          extra: {
            'orderNumber': orderId,
            'otherPartyName': driverName,
          },
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: BranchColors.metricBlueGradient.first
                    .withValues(alpha: .08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
                color: Colors.grey.shade100, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: BranchColors.metricBlueGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: BranchColors.metricBlueGradient.first
                            .withValues(alpha: .30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(LucideIcons.truck,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: BranchColors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: BranchColors.glassHeroGradient.first
                                  .withValues(alpha: .10),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              orderId,
                              style: TextStyle(
                                color:
                                    BranchColors.glassHeroGradient.first,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Icon(LucideIcons.chevronLeft,
                      size: 16,
                      color: BranchColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .78),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: .55), width: 1.2),
          ),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: BranchColors.metricBlueGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BranchColors.metricBlueGradient.first
                          .withValues(alpha: .30),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: const Icon(LucideIcons.messageCircle,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'ستظهر محادثاتك مع السائقين هنا فور بدء أي توصيل.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}