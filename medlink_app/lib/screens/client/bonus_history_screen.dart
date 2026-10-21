import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/bonus_wallet_controller.dart';
import '../../services/bonus_wallet_service.dart';
import '../../utils/theme.dart';
import 'bonus_wallet_screen.dart' show bonusTxnLabel;
import 'client_design.dart';

/// Full Bonus ledger history for the client. Read-only.
/// Filters apply to already-loaded rows; the service fetches the latest
/// 100 entries, which is documented in the empty state when relevant.
class BonusHistoryScreen extends StatefulWidget {
  const BonusHistoryScreen({super.key});

  @override
  State<BonusHistoryScreen> createState() => _BonusHistoryScreenState();
}

class _BonusHistoryScreenState extends State<BonusHistoryScreen> {
  String _typeFilter = '';
  String _statusFilter = '';

  static const _knownTypes = <String>[
    'EARN',
    'REDEEM_PRODUCT',
    'ORDER_DISCOUNT',
    'CASH_WITHDRAWAL',
    'REFUND',
    'REVERSAL',
    'ADJUSTMENT',
    'EXPIRATION',
    'OPENING_BALANCE',
    'LEGACY_MIGRATION',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<BonusWalletController>().loadHistory(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wallet = context.watch<BonusWalletController>();

    final entries = wallet.entries.where((e) {
      if (_typeFilter.isNotEmpty && e.txnType != _typeFilter) return false;
      if (_statusFilter.isNotEmpty && e.status != _statusFilter) return false;
      return true;
    }).toList();

    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: ClientColors.background,
        appBar: AppBar(
          title: Text(l10n.bonusHistoryTitle),
          backgroundColor: ClientColors.background,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.bonusRefresh,
              onPressed: wallet.isLoading ? null : wallet.loadHistory,
            ),
          ],
        ),
        body: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                children: [
                  _FilterChip(
                    label: l10n.bonusFilterAll,
                    selected: _typeFilter.isEmpty && _statusFilter.isEmpty,
                    onTap: () => setState(() {
                      _typeFilter = '';
                      _statusFilter = '';
                    }),
                  ),
                  _FilterChip(
                    label: l10n.bonusStatusPosted,
                    selected: _statusFilter == 'POSTED',
                    onTap: () => setState(() {
                      _statusFilter = _statusFilter == 'POSTED' ? '' : 'POSTED';
                    }),
                  ),
                  _FilterChip(
                    label: l10n.bonusStatusPending,
                    selected: _statusFilter == 'PENDING',
                    onTap: () => setState(() {
                      _statusFilter = _statusFilter == 'PENDING'
                          ? ''
                          : 'PENDING';
                    }),
                  ),
                  for (final t in _knownTypes)
                    _FilterChip(
                      label: bonusTxnLabel(t),
                      selected: _typeFilter == t,
                      onTap: () => setState(() {
                        _typeFilter = _typeFilter == t ? '' : t;
                      }),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (wallet.isLoading && wallet.entries.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (wallet.error != null && wallet.entries.isEmpty) {
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
                              onPressed: wallet.loadHistory,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(l10n.bonusRetry),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (entries.isEmpty) {
                    return Center(
                      child: ClientCard(
                        padding: const EdgeInsets.all(32),
                        borderRadius: 28,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClientIconBadge(
                              icon: Icons.receipt_long_rounded,
                              color: ClientColors.primary,
                              size: 56,
                              iconSize: 26,
                              borderRadius: 18,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.bonusEmptyHistory,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: wallet.loadHistory,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      itemCount: entries.length,
                      itemBuilder: (context, i) =>
                          _HistoryTile(entry: entries[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: ClientColors.primarySoft,
        backgroundColor: ClientColors.surface,
        side: BorderSide(
          color: selected ? ClientColors.primary : ClientColors.outline,
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final BonusLedgerEntry entry;

  void _showDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ClientColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final rows = <MapEntry<String, String>>[
          MapEntry(l10n.bonusDetailsTitle, bonusTxnLabel(entry.txnType)),
          MapEntry(
            l10n.bonusStatusPosted,
            entry.status == 'POSTED'
                ? l10n.bonusStatusPosted
                : l10n.bonusStatusPending,
          ),
          if (entry.reference != null && entry.reference!.isNotEmpty)
            MapEntry(l10n.bonusReferenceLabel, entry.reference!),
          if (entry.orderId != null)
            MapEntry(l10n.bonusOrderLabel, entry.orderId!),
          if (entry.ruleId != null)
            MapEntry(l10n.bonusRuleLabel, entry.ruleId!),
          if (entry.notes != null && entry.notes!.isNotEmpty)
            MapEntry(l10n.bonusNotesLabel, entry.notes!),
          MapEntry(l10n.bonusAccountLabel, l10n.bonusWalletTitle),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ClientColors.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bonusTxnLabel(entry.txnType),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _formatSheetAmount(entry.amount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: entry.amount >= 0
                            ? ClientColors.success
                            : ClientColors.danger,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.createdAt.length >= 16
                      ? entry.createdAt.substring(0, 16).replaceAll('T', ' ')
                      : entry.createdAt,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final r in rows)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.key,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    r.value,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final positive = entry.amount >= 0;
    return ClientCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderRadius: 22,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _showDetails(context),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatSheetAmount(entry.amount),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: positive
                        ? ClientColors.success
                        : ClientColors.danger,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.status,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatSheetAmount(double value) {
  final abs = value.abs();
  final text = abs == abs.truncateToDouble()
      ? abs.toInt().toString()
      : abs.toStringAsFixed(2);
  return '${value < 0 ? '-' : '+'}$text';
}
