import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_controller.dart';
import '../../services/cart_controller.dart';
import '../../services/catalog_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/offer_banner_card.dart';
import '../../widgets/product_card.dart';
import '../../widgets/medlink_design.dart';
import 'client_design.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogController>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final catalog = context.watch<CatalogController>();
    final userName = auth.profile?.name ?? l10n.homeGreeting;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([catalog.loadProducts(), catalog.loadOffers(), catalog.loadCategories()]);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: ClientHero(name: userName, subtitle: l10n.homeSubtitle)),
          SliverToBoxAdapter(child: ClientSearchField(controller: _searchController, onSubmitted: catalog.updateSearch)),
          if (catalog.offers.isNotEmpty || catalog.isLoading) ...[
            SliverToBoxAdapter(child: SectionHeading(title: l10n.offersSection)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: catalog.isLoading && catalog.offers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: catalog.offers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, i) {
                          final offer = catalog.offers[i];
                          return GestureDetector(
                            onTap: () => context.push('/client/offer/${offer.id}', extra: offer),
                            child: OfferBannerCard(offer: offer),
                          );
                        },
                      ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          ],
          if (catalog.categories.isNotEmpty) ...[
            SliverToBoxAdapter(child: SectionHeading(title: l10n.exploreCategories)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: catalog.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, i) {
                    final cat = catalog.categories[i];
                    final selected = catalog.selectedCategory == cat;
                    return FilterChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (_) => catalog.selectCategory(selected ? null : cat),
                      showCheckmark: false,
                      backgroundColor: const Color(0xFF0D1B2A),
                      selectedColor: const Color(0x2263D9FF),
                      side: BorderSide(color: selected ? const Color(0xFF63D9FF) : const Color(0xFF29445A)),
                      labelStyle: TextStyle(color: selected ? const Color(0xFF63D9FF) : const Color(0xFF9FB2BF), fontWeight: FontWeight.w700, fontSize: 12),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          ],
          SliverToBoxAdapter(child: SectionHeading(title: l10n.catalogTitle)),
          if (catalog.isLoading && catalog.products.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (catalog.error != null && catalog.products.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.sm),
                  Text(catalog.error!, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(onPressed: catalog.loadProducts, icon: const Icon(Icons.refresh_rounded), label: Text(l10n.retry)),
                ]),
              ),
            )
          else if (catalog.products.isEmpty)
            SliverToBoxAdapter(
              child: ClientDesignSurface(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Center(child: Text(l10n.noProductsFound, style: const TextStyle(color: Color(0xFFA7BAC8))),),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm, childAspectRatio: 0.72),
                delegate: SliverChildBuilderDelegate((context, i) {
                  final product = catalog.products[i];
                  return ProductCard(
                    product: product,
                    onTap: () => context.push('/client/product/${product.id}'),
                    onAdd: () {
                      context.read<CartController>().addItem(product);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addedToCart), duration: const Duration(seconds: 1)));
                    },
                  );
                }, childCount: catalog.products.length),
              ),
            ),
        ],
      ),
    );
  }
}
