import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/bonus_wallet_controller.dart';
import '../../services/catalog_controller.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

/// Product redemption flow: pick a product → quantity → review → confirm.
/// The server computes the real bonus value and enforces funds; the value
/// shown here is an estimate only and is labeled as such.
class BonusRedeemScreen extends StatefulWidget {
  const BonusRedeemScreen({super.key});

  @override
  State<BonusRedeemScreen> createState() => _BonusRedeemScreenState();
}

class _BonusRedeemScreenState extends State<BonusRedeemScreen> {
  final _searchCtrl = TextEditingController();
  Product? _selected;
  int _quantity = 1;
  String? _formError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogController>().loadProducts();
      context.read<BonusWalletController>().loadWallet();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  double get _estimate =>
      _selected == null ? 0 : _selected!.unitPrice * _quantity;

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context)!;
    final product = _selected;
    if (product == null) {
      setState(() => _formError = l10n.bonusRedeemPickProduct);
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
              _ReviewRow(label: l10n.bonusProductLabel, value: product.name),
              _ReviewRow(label: l10n.bonusQuantityLabel, value: '$_quantity'),
              _ReviewRow(
                label: l10n.bonusEstimatedValue,
                value: _formatAmount(_estimate),
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
      await wallet.submitRedemption(productId: product.id, quantity: _quantity);
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
    final catalog = context.watch<CatalogController>();
    final wallet = context.watch<BonusWalletController>();

    final q = _searchCtrl.text.trim().toLowerCase();
    final products = catalog.products.where((p) {
      if (!p.isActive) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q);
    }).toList();

    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: ClientColors.background,
        appBar: AppBar(
          title: Text(l10n.bonusRedeemTitle),
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
                    _formatAmount(wallet.funds?.available ?? 0),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ClientSearchField(
              controller: _searchCtrl,
              hintText: l10n.bonusSearchProducts,
              onSubmitted: (_) {},
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (catalog.products.isEmpty && !catalog.isLoading)
              ClientCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text(l10n.bonusNoProducts)),
                ),
              )
            else
              for (final p in products.take(30))
                _ProductPickTile(
                  product: p,
                  selected: _selected?.id == p.id,
                  onTap: () => setState(() {
                    _selected = p;
                    _formError = null;
                  }),
                ),
            const SizedBox(height: 16),
            if (_selected != null)
              ClientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selected!.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.bonusQuantityLabel,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                              ),
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
                            Text(
                              '$_quantity',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              onPressed: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.bonusEstimatedValue,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          _formatAmount(_estimate),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(
                _formError!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: ClientColors.danger),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: wallet.isSubmitting || _selected == null
                  ? null
                  : _confirm,
              icon: wallet.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(l10n.bonusSubmitRedemption),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatAmount(double value) {
  final abs = value.abs();
  final text = abs == abs.truncateToDouble()
      ? abs.toInt().toString()
      : abs.toStringAsFixed(2);
  return '${value < 0 ? '-' : '+'}$text';
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPickTile extends StatelessWidget {
  const _ProductPickTile({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final Product product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              icon: Icons.medication_rounded,
              color: selected ? ClientColors.primary : ClientColors.textMuted,
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
                    product.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.unit} • ${product.unitPrice}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: ClientColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
