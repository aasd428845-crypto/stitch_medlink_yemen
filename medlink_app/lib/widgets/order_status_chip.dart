import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/theme.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (label, bg, fg) = switch (status) {
      'pending' => (
        l10n.orderStatusPending,
        ClientColors.navy.withValues(alpha: .12),
        ClientColors.navy,
      ),
      'assigned' => (
        l10n.orderStatusAssigned,
        ClientColors.primarySoft,
        ClientColors.primary,
      ),
      'in_progress' => (
        l10n.orderStatusInProgress,
        ClientColors.warning.withValues(alpha: .14),
        ClientColors.warning,
      ),
      'delivered' => (
        l10n.orderStatusDelivered,
        ClientColors.success.withValues(alpha: .14),
        ClientColors.success,
      ),
      'cancelled' => (
        l10n.orderStatusCancelled,
        ClientColors.danger.withValues(alpha: .14),
        ClientColors.danger,
      ),
      _ => (status, ClientColors.surfaceMuted, ClientColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
