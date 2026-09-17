import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/promotional_offer.dart';
import '../../utils/theme.dart';
import '../screens/client/client_design.dart';

/// Reusable product card used in CatalogTab and HomeTab.
/// Tapping navigates to ProductDetailScreen; [onAdd] triggers cart addition.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
    this.offer,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final PromotionalOffer? offer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final specialPrice = offer?.specialPrice;
    final discountPercent = offer?.discountPercent;
    final hasOffer = specialPrice != null || discountPercent != null;
    final offerPrice = specialPrice ??
      (discountPercent == null
        ? null
        : product.unitPrice * (1 - discountPercent / 100));

    return ClientCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              AspectRatio(
                aspectRatio: 1.18,
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
                  12,
                  AppSpacing.sm,
                  4,
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
                        color: ClientColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        product.category,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: ClientColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // Product name
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: ClientColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (product.manufacturer != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.manufacturer!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ClientColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (product.dosageForm?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${product.dosageForm} · ${product.unit}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ClientColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Price row + Add button
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  4,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasOffer) ...[
                            Text(
                              '${product.unitPrice.toStringAsFixed(0)} ر.ي',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: ClientColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              '${offerPrice!.toStringAsFixed(0)} ر.ي',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: ClientColors.success,
                              ),
                            ),
                          ] else
                            Text(
                              '${product.unitPrice.toStringAsFixed(0)} ر.ي',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: ClientColors.primary,
                              ),
                            ),
                          if (discountPercent != null)
                            Text(
                              'خصم ${discountPercent.toStringAsFixed(0)}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: ClientColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ClientColors.primarySoft, ClientColors.surfaceMuted],
        ),
      ),
      child: Center(
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .65),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.medication_liquid_rounded,
            size: 30,
            color: ClientColors.primary,
          ),
        ),
      ),
    );
  }
}
