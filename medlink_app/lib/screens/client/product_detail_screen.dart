import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../services/auth_controller.dart';
import '../../services/cart_controller.dart';
import '../../services/catalog_service.dart';
import '../../utils/theme.dart';

/// Full-screen product detail view.
/// Navigated to via /client/product/:id (pushed on top of ClientHomeShell).
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productDetails),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load, l10n: l10n)
              : _product == null
                  ? Center(child: Text(l10n.noProductsFound))
                  : _ProductBody(
                      product: _product!,
                      availableQuantity: _availableQuantity,
                      l10n: l10n,
                    ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero image ───────────────────────────────────────
                Hero(
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

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          product.category,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.onSecondaryContainer,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Product name
                      Text(
                        product.name,
                        style: theme.textTheme.headlineMedium,
                      ),

                      if (product.nameEn != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          product.nameEn!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.md),

                      // Price
                      Row(
                        children: [
                          Text(
                            l10n.unitPrice,
                            style: theme.textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            '${product.unitPrice.toStringAsFixed(0)} ﷼',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: AppSpacing.xl),

                      // Details table
                      _DetailTable(product: product, l10n: l10n),

                      // Description
                      if (product.description != null &&
                          product.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          product.description!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Add to cart button ────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: ElevatedButton.icon(
              onPressed: availableQuantity == 0
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
                availableQuantity == 0
                    ? l10n.outOfStock
                    : availableQuantity == null
                        ? l10n.addToCart
                        : '${l10n.addToCart} · ${l10n.availableQuantity}: $availableQuantity',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceContainerLow,
      child: const Center(
        child: Icon(
          Icons.medication_outlined,
          size: 64,
          color: AppColors.outlineVariant,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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

    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: rows.map((row) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                row.$1,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xs,
                horizontal: AppSpacing.sm,
              ),
              child: Text(
                row.$2,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.onRetry,
    required this.l10n,
  });

  final String error;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.sm),
            Text(error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
