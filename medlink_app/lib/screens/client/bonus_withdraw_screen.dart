import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/bonus_wallet_controller.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

/// Cash withdrawal flow: amount → method/notes → review → confirm.
/// Limits, eligibility and approval are enforced server-side; the UI
/// collects input and surfaces backend results only.
class BonusWithdrawScreen extends StatefulWidget {
  const BonusWithdrawScreen({super.key});

  @override
  State<BonusWithdrawScreen> createState() => _BonusWithdrawScreenState();
}

class _BonusWithdrawScreenState extends State<BonusWithdrawScreen> {
  final _amountCtrl = TextEditingController();
  final _methodCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _formError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<BonusWalletController>().loadWallet(),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _methodCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _formError = l10n.bonusInvalidAmount);
      return;
    }
    final wallet = context.read<BonusWalletController>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: ClientColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
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
              Text(
                l10n.bonusConfirmTitle,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _ReviewRow(label: l10n.bonusAmountLabel, value: '$amount'),
              if (_methodCtrl.text.trim().isNotEmpty)
                _ReviewRow(
                  label: l10n.bonusMethodLabel,
                  value: _methodCtrl.text.trim(),
                ),
              const SizedBox(height: 8),
              Text(
                l10n.bonusServerConfirms,
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      child: Text(l10n.bonusCancelAction),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      child: Text(l10n.bonusConfirmAction),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await wallet.submitWithdrawal(
        amount: amount,
        method: _methodCtrl.text.trim().isEmpty
            ? null
            : _methodCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      context.pushReplacement('/client/bonus-requests');
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = wallet.error ?? l10n.bonusSubmitError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wallet = context.watch<BonusWalletController>();

    return Scaffold(
      backgroundColor: ClientColors.background,
      appBar: AppBar(
        title: Text(l10n.bonusWithdrawTitle),
        backgroundColor: ClientColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          ClientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClientSectionTitle(
                  title: l10n.bonusAvailable,
                  icon: Icons.account_balance_wallet_rounded,
                ),
                const SizedBox(height: 4),
                Text(
                  '${wallet.funds?.available ?? 0}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ClientCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.bonusAmountLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.bonusMethodLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _methodCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.bonusMethodHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.bonusNotesLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 8),
            Text(
              _formError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ClientColors.danger,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: wallet.isSubmitting ? null : _confirm,
            icon: wallet.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.payments_outlined),
            label: Text(l10n.bonusSubmitWithdrawal),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
