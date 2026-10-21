import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../utils/theme.dart';
import 'order_status_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BranchOrderCard extends StatelessWidget {
  const BranchOrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onAllocate,
    required this.onAssignDriver,
    required this.onTransfer,
    required this.onReject,
  });

  final OrderModel order;
  final VoidCallback onTap;
  final VoidCallback onAllocate;
  final VoidCallback onAssignDriver;
  final VoidCallback onTransfer;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final canAct = order.status == 'pending' || order.status == 'assigned';
    final clientName = order.client?.name?.isNotEmpty == true
        ? order.client!.name!
        : '${l10n.orderNumber} ${order.id.substring(0, 8)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: ClientColors.surface.withValues(alpha: .74),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: .7),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: ClientColors.primary.withValues(alpha: .06),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ClientColors.primary.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      LucideIcons.receipt,
                      color: ClientColors.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: ClientColors.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${l10n.orderNumber} ${order.id.substring(0, 8)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: ClientColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OrderStatusChip(status: order.status),
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.chevronLeft,
                    color: ClientColors.textMuted,
                  ),
                ],
              ),
              if (order.deliveryAddress != null) ...[
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      size: 16,
                      color: ClientColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.deliveryAddress!.addressText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ClientColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: ClientColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.banknote,
                      size: 17,
                      color: ClientColors.primary,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${order.totalAmount.toStringAsFixed(0)} ﷼',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: ClientColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    if (order.assignedDriver?.name?.isNotEmpty == true) ...[
                      const Icon(
                        LucideIcons.truck,
                        size: 16,
                        color: ClientColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          order.assignedDriver!.name!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: ClientColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canAct) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    if (order.status == 'pending')
                      _ActionButton(
                        icon: LucideIcons.sparkles,
                        label: 'تخصيص',
                        onTap: onAllocate,
                      ),
                    if (order.status == 'pending')
                      _ActionButton(
                        icon: LucideIcons.userPlus,
                        label: l10n.branchAssignDriver,
                        onTap: onAssignDriver,
                      ),
                    _ActionButton(
                      icon: LucideIcons.arrowLeftRight,
                      label: l10n.branchTransferOrder,
                      onTap: onTransfer,
                    ),
                    if (order.status == 'pending')
                      _ActionButton(
                        icon: LucideIcons.x,
                        label: l10n.branchRejectOrder,
                        onTap: onReject,
                        danger: true,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? ClientColors.danger : ClientColors.primary;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        side: BorderSide(color: color.withValues(alpha: .28)),
        backgroundColor: color.withValues(alpha: .06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }
}