import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/cart_controller.dart';
import '../../services/catalog_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/product_card.dart';
import '../branch_manager/branch_manager_design.dart';

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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => _onSearchChanged(v, catalog),
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              color: ClientColors.text,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              hintStyle: const TextStyle(color: ClientColors.textMuted),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: ClientColors.primary,
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('', catalog);
                      },
                    ),
              filled: true,
              fillColor: ClientColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: ClientColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: BranchColors.primary,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
        if (catalog.categories.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: catalog.categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, i) {
                if (i == 0) {
                  final selected = catalog.selectedCategory == null;
                  return FilterChip(
                    label: Text(l10n.allCategories),
                    selected: selected,
                    onSelected: (_) => catalog.selectCategory(null),
                    showCheckmark: false,
                    backgroundColor: ClientColors.surfaceMuted,
                    selectedColor: ClientColors.primarySoft,
                    side: BorderSide(
                      color: selected
                          ? ClientColors.primary
                          : ClientColors.outline,
                    ),
                    labelStyle: TextStyle(
                      color: selected
                          ? ClientColors.primary
                          : ClientColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                }
                final cat = catalog.categories[i - 1];
                final selected = catalog.selectedCategory == cat;
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) =>
                      catalog.selectCategory(selected ? null : cat),
                  showCheckmark: false,
                  backgroundColor: ClientColors.surfaceMuted,
                  selectedColor: ClientColors.primarySoft,
                  side: BorderSide(
                    color: selected
                        ? ClientColors.primary
                        : ClientColors.outline,
                  ),
                  labelStyle: TextStyle(
                    color: selected
                        ? ClientColors.primary
                        : ClientColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 10),
        Expanded(child: _buildGrid(context, l10n, catalog)),
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
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: BranchColors.error,
            ),
            const SizedBox(height: 10),
            Text(
              catalog.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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
        child: SoftCard(
          padding: const EdgeInsets.all(32),
          borderRadius: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PastelIconBadge(
                icon: Icons.search_off_rounded,
                color: BranchColors.onSurfaceVariant,
                size: 56,
                iconSize: 28,
                shape: BoxShape.circle,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noProductsFound,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: catalog.loadProducts,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 148),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.66,
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
