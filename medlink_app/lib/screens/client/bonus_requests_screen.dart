import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/bonus_wallet_controller.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

/// The client's own redemption and withdrawal requests with live statuses.
/// Cancellation is offered only where the backend permits it
/// (redemptions: PENDING; withdrawals: PENDING/UNDER_REVIEW) —
/// the RPC remains the final authority.
class BonusRequestsScreen extends StatefulWidget {
  const BonusRequestsScreen({super.key});

  @override
  State<BonusRequestsScreen> createState() => _BonusRequestsScreenState();
}

class _BonusRequestsScreenState extends State<BonusRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<BonusWalletController>().loadMyRequests(),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wallet = context.watch<BonusWalletController>();

    return Scaffold(
      backgroundColor: ClientColors.background,
      appBar: AppBar(
        title: Text(l10n.bonusRequestsTitle),
        backgroundColor: ClientColors.background,
        bottom: TabBar(
          controller: _tabs,
          labelColor: ClientColors.primary,
          tabs: [
            Tab(text: l10n.bonusRedemptionsTab),
            Tab(text: l10n.bonusWithdrawalsTab),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.bonusRefresh,
            onPressed: wallet.isLoading ? null : wallet.loadMyRequests,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (wallet.isLoading &&
              wallet.redemptions.isEmpty &&
              wallet.withdrawals.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (wallet.error != null &&
              wallet.redemptions.isEmpty &&
              wallet.withdrawals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: ClientColors.danger,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.bonusLoadError,
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: wallet.loadMyRequests,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.bonusRetry),
                    ),
                  ],
                ),
              ),
            );
          }
          return TabBarView(
            controller: _tabs,
            children: [
              _RequestList(
                emptyText: l10n.bonusEmptyRedemptions,
                children: [
                  for (final r in wallet.redemptions)
                    _RequestTile(
                      title:
                          '${l10n.bonusRedemptionItem} × ${r.quantity}',
                      subtitle:
                          '${l10n.bonusValueLabel}: ${r.bonusValue}',
                      status: r.status,
                      cancellable: r.status == 'PENDING',
                      onCancel: () => _confirmCancel(
                        context,
                        () => wallet.cancelRedemption(r.id),
                      ),
                    ),
                ],
              ),
              _RequestList(
                emptyText: l10n.bonusEmptyWithdrawals,
                children: [
                  for (final w in wallet.withdrawals)
                    _RequestTile(
                      title: '${l10n.bonusAmountLabel}: ${w.amount}',
                      subtitle: w.rejectionReason?.isNotEmpty == true
                          ? w.rejectionReason!
                          : (w.paymentMethod?.isNotEmpty == true
                                ? w.paymentMethod!
                                : ''),
                      status: w.status,
                      cancellable:
                          w.status == 'PENDING' ||
                          w.status == 'UNDER_REVIEW',
                      onCancel: () => _confirmCancel(
                        context,
                        () => wallet.cancelWithdrawal(w.id),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.bonusCancelTitle),
        content: Text(l10n.bonusCancelMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.bonusCancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.bonusConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await action();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<BonusWalletController>().error ??
                l10n.bonusSubmitError,
          ),
        ),
      );
    }
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({required this.emptyText, required this.children});

  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Center(
        child: ClientCard(
          padding: const EdgeInsets.all(32),
          borderRadius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClientIconBadge(
                icon: Icons.inbox_outlined,
                color: ClientColors.primary,
                size: 56,
                iconSize: 26,
                borderRadius: 18,
              ),
              const SizedBox(height: 12),
              Text(
                emptyText,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          context.read<BonusWalletController>().loadMyRequests(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: children,
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.cancellable,
    required this.onCancel,
  });

  final String title;
  final String subtitle;
  final String status;
  final bool cancellable;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClientCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderRadius: 22,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ClientColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (cancellable)
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text(l10n.bonusCancelRequest),
            ),
        ],
      ),
    );
  }
}
