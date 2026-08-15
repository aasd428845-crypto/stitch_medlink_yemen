import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../utils/theme.dart';
import 'medlink_design.dart';

/// Reusable product card used in CatalogTab and HomeTab.
/// Tapping navigates to ProductDetailScreen; [onAdd] triggers cart addition.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        product.category,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.onSecondaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // Product name
                    Text(
                      product.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (product.manufacturer != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.manufacturer!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Price row + Add button
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${product.unitPrice.toStringAsFixed(0)} ﷼',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      width: 36,
                      child: FilledButton(
                        onPressed: onAdd,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        child: const Icon(Icons.add_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          size: 40,
          color: AppColors.outlineVariant,
        ),
      ),
    );
  }
}
