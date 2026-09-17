import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/auth_controller.dart';
import '../../services/cart_controller.dart';
import '../../services/catalog_service.dart';
import '../../utils/theme.dart';
import 'client_design.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  int? _availableQuantity;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = context.read<CatalogService>();
      final branchId = context.read<AuthController>().profile?.branchId;
      _product = await service.fetchProductById(widget.productId);
      if (_product != null && branchId != null) {
        _availableQuantity = await service.fetchProductQuantity(
          productId: widget.productId,
          branchId: branchId,
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: AppTheme.clientLight,
      child: Scaffold(
        backgroundColor: ClientColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ClientColors.text,
          title: Text(l10n.productDetails),
        ),
        body: ClientGlassBackground(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
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
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : _product == null
              ? Center(child: Text(l10n.noProductsFound))
              : _ProductBody(
                  product: _product!,
                  availableQuantity: _availableQuantity,
                  l10n: l10n,
                ),
        ),
      ),
    );
  }
}

class _ProductBody extends StatelessWidget {
  const _ProductBody({
    required this.product,
    required this.availableQuantity,
    required this.l10n,
  });
  final Product product;
  final int? availableQuantity;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOutOfStock = availableQuantity == 0;
    final stockLabel = isOutOfStock
        ? l10n.outOfStock
        : availableQuantity == null
        ? l10n.inStock
        : '${l10n.availableQuantity}: $availableQuantity';
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 116),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClientCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 28,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Hero(
                      tag: 'product_${product.id}',
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: product.imageUrl != null
                            ? Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(),
                              )
                            : _imagePlaceholder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Pill(label: product.category, color: ClientColors.primary),
                    const SizedBox(width: 8),
                    _Pill(
                      label: stockLabel,
                      color: isOutOfStock
                          ? ClientColors.danger
                          : ClientColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  product.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: ClientColors.navy,
                  ),
                ),
                if (product.nameEn?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.nameEn!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ClientColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ClientCard(
                  borderRadius: 22,
                  child: Row(
                    children: [
                      const ClientIconBadge(
                        icon: Icons.payments_outlined,
                        color: ClientColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.unitPrice,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ClientColors.textMuted,
                          ),
                        ),
                      ),
                      Text(
                        '${product.unitPrice.toStringAsFixed(0)} ر.ي',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: ClientColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ClientSectionTitle(
                  title: l10n.productDetails,
                  icon: Icons.info_outline_rounded,
                ),
                const SizedBox(height: 10),
                ClientCard(
                  borderRadius: 22,
                  child: _DetailTable(product: product, l10n: l10n),
                ),
                if (product.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  ClientSectionTitle(
                    title: product.name,
                    icon: Icons.description_outlined,
                  ),
                  const SizedBox(height: 10),
                  ClientCard(
                    borderRadius: 22,
                    child: Text(
                      product.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: FilledButton.icon(
              onPressed: isOutOfStock
                  ? null
                  : () {
                      context.read<CartController>().addItem(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.addedToCart),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: Text(
                isOutOfStock
                    ? l10n.outOfStock
                    : availableQuantity == null
                    ? l10n.addToCart
                    : '${l10n.addToCart} · ${l10n.availableQuantity}: $availableQuantity',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: ClientColors.surfaceMuted,
      child: const Center(
        child: Icon(
          Icons.medication_outlined,
          size: 64,
          color: ClientColors.outline,
        ),
      ),
    );
  }
}

class _DetailTable extends StatelessWidget {
  const _DetailTable({required this.product, required this.l10n});
  final Product product;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (product.manufacturer != null)
        (l10n.manufacturer, product.manufacturer!),
      if (product.dosageForm != null) (l10n.dosageForm, product.dosageForm!),
      (l10n.unit, product.unit),
      (l10n.category, product.category),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  rows[i].$1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ClientColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  rows[i].$2,
                  textAlign: TextAlign.end,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (i != rows.length - 1)
            Divider(
              height: 20,
              color: ClientColors.outline.withValues(alpha: .7),
            ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
