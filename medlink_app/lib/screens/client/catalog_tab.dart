import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/cart_controller.dart';
import '../../services/catalog_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/product_card.dart';

/// The "Catalog" tab inside ClientHomeShell.
/// Provides full-text search (debounced) + category filter chips + product grid.
class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogController>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value, CatalogController catalog) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      catalog.updateSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = context.watch<CatalogController>();

    return Column(
      children: [
        // ── Search bar ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => _onSearchChanged(v, catalog),
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        catalog.updateSearch('');
                      },
                    )
                  : null,
            ),
          ),
        ),

        // ── Category filter chips ─────────────────────────────────────
        if (catalog.categories.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: catalog.categories.length + 1, // +1 for "All"
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, i) {
                if (i == 0) {
                  // "All" chip
                  final selected = catalog.selectedCategory == null;
                  return FilterChip(
                    label: Text(l10n.allCategories),
                    selected: selected,
                    onSelected: (_) => catalog.selectCategory(null),
                  );
                }
                final cat = catalog.categories[i - 1];
                final selected = catalog.selectedCategory == cat;
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) =>
                      catalog.selectCategory(selected ? null : cat),
                );
              },
            ),
          ),

        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1),

        // ── Product grid ──────────────────────────────────────────────
        Expanded(
          child: _buildGrid(context, l10n, catalog),
        ),
      ],
    );
  }

  Widget _buildGrid(
    BuildContext context,
    AppLocalizations l10n,
    CatalogController catalog,
  ) {
    if (catalog.isLoading && catalog.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (catalog.error != null && catalog.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.sm),
            Text(
              catalog.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: catalog.loadProducts,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (catalog.products.isEmpty) {
      return Center(
        child: Text(
          l10n.noProductsFound,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: catalog.loadProducts,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.72,
        ),
        itemCount: catalog.products.length,
        itemBuilder: (context, i) {
          final product = catalog.products[i];
          return ProductCard(
            product: product,
            onTap: () => context.push('/client/product/${product.id}'),
            onAdd: () {
              context.read<CartController>().addItem(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.addedToCart),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
