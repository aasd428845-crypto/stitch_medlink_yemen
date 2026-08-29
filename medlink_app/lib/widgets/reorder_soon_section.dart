import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/theme.dart';
import 'medlink_design.dart';

/// Horizontal list of the products the client most recently ordered, letting
/// them quickly re-add a previously purchased item to the cart.
class ReorderSoonSection extends StatelessWidget {
  const ReorderSoonSection({
    super.key,
    required this.title,
    required this.products,
    required this.onAdd,
  });

  final String title;
  final List<Product> products;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(title: title),
        SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              final product = products[i];
              return _MiniProductCard(
                product: product,
                onAdd: () => onAdd(product),
                priceStyle: theme.textTheme.bodyLarge,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniProductCard extends StatelessWidget {
  const _MiniProductCard({
    required this.product,
    required this.onAdd,
    required this.priceStyle,
  });

  final Product product;
  final VoidCallback onAdd;
  final TextStyle? priceStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 140,
      child: GlassPanel(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product image / placeholder
            SizedBox(
              height: 88,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.unitPrice.toStringAsFixed(0)} ﷼',
                        style: (priceStyle ?? theme.textTheme.bodyMedium)?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: FilledButton(
                          onPressed: onAdd,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: AppColors.primaryContainer,
                            shape: const CircleBorder(),
                          ),
                          child: const Icon(Icons.add_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceContainerLow,
      child: const Center(
        child: Icon(
          Icons.medication_outlined,
          size: 32,
          color: AppColors.outlineVariant,
        ),
      ),
    );
  }
}
