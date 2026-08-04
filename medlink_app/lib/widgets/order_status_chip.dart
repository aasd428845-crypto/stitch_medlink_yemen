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
          AppColors.warningContainer,
          AppColors.warning
        ),
      'assigned' => (
          l10n.orderStatusAssigned,
          AppColors.secondaryContainer,
          AppColors.onSecondaryContainer
        ),
      'in_progress' => (
          l10n.orderStatusInProgress,
          AppColors.primaryContainer,
          AppColors.onPrimaryContainer
        ),
      'delivered' => (
          l10n.orderStatusDelivered,
          AppColors.successContainer,
          AppColors.success
        ),
      'cancelled' => (
          l10n.orderStatusCancelled,
          AppColors.errorContainer,
          AppColors.error
        ),
      _ => (status, AppColors.surfaceContainer, AppColors.onSurfaceVariant),
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
