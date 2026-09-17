import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/theme.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = AppTheme.clientLight;

    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: ClientColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: ClientColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 72,
                    color: ClientColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  l10n.orderSuccessTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),

                Text(
                  l10n.orderSuccessSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ClientColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Order ID badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: ClientColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: ClientColors.outline),
                  ),
                  child: Text(
                    '${l10n.orderNumber} ${orderId.substring(0, 8)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                ElevatedButton.icon(
                  onPressed: () => context.go('/client/order/$orderId'),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: Text(l10n.viewOrderDetails),
                ),
                const SizedBox(height: AppSpacing.sm),

                TextButton(
                  onPressed: () => context.go('/client'),
                  child: Text(l10n.clientHomeLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
