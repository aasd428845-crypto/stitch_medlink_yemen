import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/bonus_wallet_controller.dart';
import '../../services/bonus_wallet_service.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

/// Human labels for ledger transaction types. Unknown future types fall
/// back to the raw stored value (never hidden, never guessed).
String bonusTxnLabel(String txnType) {
  return switch (txnType) {
    'EARN' => 'مكافأة مكتسبة',
    'REDEEM_PRODUCT' => 'استبدال بمنتج',
    'ORDER_DISCOUNT' => 'خصم على طلب',
    'CASH_WITHDRAWAL' => 'سحب نقدي',
    'REFUND' => 'استرداد مبلغ',
    'REVERSAL' => 'عكس قيد',
    'ADJUSTMENT' => 'تسوية',
    'EXPIRATION' => 'انتهاء صلاحية',
    'OPENING_BALANCE' => 'رصيد افتتاحي',
    'LEGACY_MIGRATION' => 'رصيد مرحّل',
    _ => txnType,
  };
}

String _formatAmount(double value) {
  final abs = value.abs();
  final text = abs == abs.truncateToDouble()
      ? abs.toInt().toString()
      : abs.toStringAsFixed(2);
  return '${value < 0 ? '-' : '+'}$text';
}

/// Bonus wallet screen: balance hero (server-computed), recent activity,
/// and a link to the full history. Read-only; no redemption/withdrawal
/// flows in this batch.
class BonusWalletScreen extends StatefulWidget {
  const BonusWalletScreen({super.key});

  @override
  State<BonusWalletScreen> createState() => _BonusWalletScreenState();
}

class _BonusWalletScreenState extends State<BonusWalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<BonusWalletController>().loadWallet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wallet = context.watch<BonusWalletController>();

    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: ClientColors.background,
        appBar: AppBar(
          title: Text(l10n.bonusWalletTitle),
          backgroundColor: ClientColors.background,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.bonusRefresh,
              onPressed: wallet.isLoading ? null : wallet.loadWallet,
            ),
          ],
        ),
        body: Builder(
          builder: (context) {
            if (wallet.isLoading && wallet.funds == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (wallet.error != null && wallet.funds == null) {
              return _WalletError(
                message: wallet.error!,
                onRetry: wallet.loadWallet,
              );
            }

            final funds = wallet.funds;
            final recent = wallet.entries.take(5).toList();

            return RefreshIndicator(
              onRefresh: wallet.loadWallet,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _BalanceHero(
                    available: funds?.available ?? 0,
                    reserved: funds?.reserved ?? 0,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.push('/client/bonus-redeem'),
                          icon: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 20,
                          ),
                          label: Text(l10n.bonusRedeemTitle),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/client/bonus-withdraw'),
                          icon: const Icon(Icons.payments_outlined, size: 20),
                          label: Text(l10n.bonusWithdrawTitle),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => context.push('/client/bonus-requests'),
                      icon: const Icon(Icons.receipt_long_rounded, size: 20),
                      label: Text(l10n.bonusRequestsTitle),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ClientSectionTitle(
                    title: l10n.bonusRecentActivity,
                    icon: Icons.history_rounded,
                    action: l10n.bonusViewAll,
                    onAction: () => context.push('/client/bonus-history'),
                  ),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    ClientCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            l10n.bonusEmptyHistory,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    ...recent.map(
                      (e) => _LedgerTile(
                        entry: e,
                        onTap: () => context.push('/client/bonus-history'),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.available, required this.reserved});

  final double available;
  final double reserved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ClientCard(
      borderRadius: 28,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [ClientColors.primary, ClientColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.bonusAvailable,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white.withValues(alpha: .85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _formatAmount(available),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push('/client/bonus-history'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${l10n.bonusReserved}: ${_formatAmount(reserved)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry, this.onTap});

  final BonusLedgerEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final positive = entry.amount >= 0;
    return ClientCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderRadius: 22,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Row(
          children: [
            ClientIconBadge(
              icon: positive
                  ? Icons.add_circle_outline_rounded
                  : Icons.remove_circle_outline_rounded,
              color: positive ? ClientColors.success : ClientColors.danger,
              size: 44,
              iconSize: 20,
              borderRadius: 14,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bonusTxnLabel(entry.txnType),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.createdAt.length >= 10
                        ? entry.createdAt.substring(0, 10)
                        : entry.createdAt,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              _formatAmount(entry.amount),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: positive ? ClientColors.success : ClientColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletError extends StatelessWidget {
  const _WalletError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            const SizedBox(height: 4),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.bonusRetry),
            ),
          ],
        ),
      ),
    );
  }
}
