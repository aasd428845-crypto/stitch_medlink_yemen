import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/bonus_wallet_controller.dart';
import '../../services/bonus_wallet_service.dart';
import '../../utils/error_mapper.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

/// Server-driven Bonus discount section for a single order.
///
/// Display only: available funds come from `BonusWalletService.fetchMyFunds`
/// and every figure after submit comes from RPC results or ledger rows.
/// Nothing financial is computed here as a source of truth; the database
/// (0020 `apply_order_discount` / `cancel_order_discount`) decides.
/// Shown only while the order is `pending` (server re-validates anyway).
class OrderDiscountSection extends StatefulWidget {
  const OrderDiscountSection({
    super.key,
    required this.orderId,
    required this.status,
    required this.totalAmount,
    required this.onChanged,
  });

  final String orderId;
  final String status;
  final double totalAmount;
  final VoidCallback onChanged;

  @override
  State<OrderDiscountSection> createState() => _OrderDiscountSectionState();
}

class _OrderDiscountSectionState extends State<OrderDiscountSection> {
  final TextEditingController _amountCtrl = TextEditingController();
  double? _lastRequested;

  @override
  void initState() {
    super.initState();
    // Post-frame: loadWallet notifies listeners, which is illegal
    // synchronously inside initState's first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final wallet = context.read<BonusWalletController>();
      if (wallet.funds == null && !wallet.isLoading) {
        wallet.loadWallet();
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  BonusLedgerEntry? _appliedEntry(List<BonusLedgerEntry> entries) {
    for (final e in entries) {
      if (e.txnType == 'ORDER_DISCOUNT' &&
          e.status == 'POSTED' &&
          e.orderId == widget.orderId) {
        return e;
      }
    }
    return null;
  }

  Future<void> _apply() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;
    final wallet = context.read<BonusWalletController>();
    _lastRequested = amount;
    try {
      final id = await wallet.submitOrderDiscount(
        orderId: widget.orderId,
        amount: amount,
      );
      if (!mounted || id == null) return;
      _amountCtrl.clear();
      widget.onChanged();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(mapAuthErrorToMessage(l10n, wallet.error ?? '')),
        ),
      );
    }
  }

  Future<void> _retry() async {
    final amount = _lastRequested;
    if (amount == null) return;
    _amountCtrl.text = amount.toStringAsFixed(0);
    await _apply();
  }

  Future<void> _remove() async {
    final wallet = context.read<BonusWalletController>();
    try {
      final id = await wallet.removeOrderDiscount(orderId: widget.orderId);
      if (!mounted || id == null) return;
      widget.onChanged();
    } catch (_) {
      // Error is exposed via wallet.error below; nothing else to do here.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status != 'pending') return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final wallet = context.watch<BonusWalletController>();
    final applied = _appliedEntry(wallet.entries);
    final available = wallet.funds?.available ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClientSectionTitle(
          title: l10n.orderDiscountTitle,
          icon: Icons.discount_outlined,
          iconColor: ClientColors.primary,
        ),
        const SizedBox(height: 10),
        ClientCard(
          borderRadius: 22,
          child: wallet.isLoading && wallet.funds == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.orderDiscountSubtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.orderDiscountAvailable,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          '${available.toStringAsFixed(0)} ﷼',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (applied != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.orderDiscountApplied,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${(-applied.amount).toStringAsFixed(0)} ﷼',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ClientColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.orderDiscountPayable,
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '${(widget.totalAmount + applied.amount).toStringAsFixed(0)} ﷼',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: wallet.isSubmitting ? null : _remove,
                          icon: wallet.isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.remove_circle_outline_rounded),
                          label: Text(l10n.orderDiscountRemove),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.orderDiscountAmountHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: wallet.isSubmitting ? null : _apply,
                          icon: wallet.isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.discount_rounded),
                          label: Text(l10n.orderDiscountApply),
                        ),
                      ),
                    ],
                    if (wallet.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        wallet.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ClientColors.danger,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: wallet.isSubmitting ? null : _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.bonusRetry),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
