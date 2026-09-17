import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/product.dart';
import '../../models/promotional_offer.dart';
import '../../services/auth_controller.dart';
import '../../services/cart_controller.dart';
import '../../services/catalog_controller.dart';
import '../../utils/theme.dart';
import '../../widgets/product_card.dart';
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
        await Future.wait([
          catalog.loadProducts(),
          catalog.loadOffers(),
          catalog.loadCategories(),
          catalog.loadNewProducts(),
        ]);
        await catalog.loadReorderRecommendations();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ClientHero(
              name: userName,
              subtitle: l10n.homeSubtitle,
              greeting: l10n.homeGreeting,
            ),
          ),
          SliverToBoxAdapter(
            child: ClientSearchField(
              controller: _searchController,
              hintText: l10n.searchHint,
              onSubmitted: catalog.updateSearch,
              onChanged: catalog.updateSearch,
            ),
          ),
          SliverToBoxAdapter(
            child: ClientSectionTitle(
              title: l10n.offersSection,
              icon: Icons.local_offer_outlined,
              iconColor: ClientColors.primary,
            ),
          ),
          SliverToBoxAdapter(
            child: _OfferCarousel(
              offers: catalog.offers,
              isLoading: catalog.offersLoading,
              error: catalog.offersError,
              onRetry: catalog.loadOffers,
            ),
          ),
          SliverToBoxAdapter(
            child: _LatestUpdatesTicker(
              offers: catalog.offers,
              newProducts: catalog.newProducts,
              reorderRecommendations: catalog.reorderRecommendations,
            ),
          ),
          if (catalog.categoriesLoading ||
              catalog.categoriesError != null ||
              catalog.categories.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: ClientSectionTitle(
                title: l10n.categoriesSection,
                icon: Icons.category_outlined,
                iconColor: ClientColors.primary,
                action: l10n.viewAll,
                onAction: () => _openCatalog(context),
              ),
            ),
            SliverToBoxAdapter(
              child: _CategoriesSection(
                categories: catalog.categories,
                isLoading: catalog.categoriesLoading,
                error: catalog.categoriesError,
                selectedCategory: catalog.selectedCategory,
                onRetry: catalog.loadCategories,
                onSelect: (category) {
                  final selected = catalog.selectedCategory == category;
                  catalog.selectCategory(selected ? null : category);
                  _openCatalog(context, clearFilters: false);
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
          if (catalog.newProductsLoading ||
              catalog.newProductsError != null ||
              catalog.newProducts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: ClientSectionTitle(
                title: l10n.newProductsSection,
                icon: Icons.new_releases_outlined,
                iconColor: ClientColors.primary,
                action: l10n.viewAll,
                onAction: () => _openCatalog(context),
              ),
            ),
            SliverToBoxAdapter(
              child: _NewProductsSection(
                products: catalog.newProducts,
                isLoading: catalog.newProductsLoading,
                error: catalog.newProductsError,
                onRetry: catalog.loadNewProducts,
                onAdd: (product) => _addToCart(context, product),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
          SliverToBoxAdapter(
            child: ClientSectionTitle(
              title: l10n.featuredProducts,
              icon: Icons.medication_outlined,
              iconColor: ClientColors.primary,
              action: l10n.viewAll,
              onAction: () => _openCatalog(context),
            ),
          ),
          if (catalog.isLoading && catalog.products.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (catalog.error != null && catalog.products.isEmpty)
            SliverFillRemaining(
              child: Center(
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
              ),
            )
          else if (catalog.products.isEmpty)
            SliverToBoxAdapter(
              child: ClientCard(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                borderRadius: 24,
                child: Center(
                  child: Text(
                    l10n.noProductsFound,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 148),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.52,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final product = catalog.products[i];
                    return ProductCard(
                      product: product,
                      onTap: () =>
                          context.push('/client/product/${product.id}'),
                      onAdd: () => _addToCart(context, product),
                    );
                  },
                  childCount: catalog.products.length > 4
                      ? 4
                      : catalog.products.length,
                ),
              ),
            ),
          if (catalog.reorderLoading ||
              catalog.reorderError != null ||
              catalog.reorderRecommendations.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: ClientSectionTitle(
                title: l10n.reorderSuggestions,
                icon: Icons.repeat_rounded,
                iconColor: ClientColors.primary,
              ),
            ),
            SliverToBoxAdapter(
              child: _ReorderSection(
                recommendations: catalog.reorderRecommendations,
                isLoading: catalog.reorderLoading,
                error: catalog.reorderError,
                onRetry: catalog.loadReorderRecommendations,
                onAdd: (product) => _addToCart(context, product),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
          if (catalog.isInitialized ||
              catalog.offersLoading ||
              catalog.offersError != null) ...[
            SliverToBoxAdapter(
              child: ClientSectionTitle(
                title: l10n.currentOffersSection,
                icon: Icons.local_offer_rounded,
                iconColor: ClientColors.primary,
              ),
            ),
            SliverToBoxAdapter(
              child: _CurrentOffersSection(
                offers: catalog.offers,
                isLoading: catalog.offersLoading,
                error: catalog.offersError,
                onRetry: catalog.loadOffers,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ],
      ),
    );
  }

  void _openCatalog(BuildContext context, {bool clearFilters = true}) {
    if (clearFilters) {
      context.read<CatalogController>().clearFilters();
    }
    context.go('/client?tab=1');
  }

  void _addToCart(BuildContext context, Product product) {
    final l10n = AppLocalizations.of(context)!;
    context.read<CartController>().addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.addedToCart),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

const _categoryIcons = [
  Icons.medication_outlined,
  Icons.vaccines_outlined,
  Icons.healing_outlined,
  Icons.child_care_outlined,
  Icons.sanitizer_outlined,
];

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ClientColors.primary : ClientColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? ClientColors.primary : ClientColors.outline,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? Colors.white : ClientColors.primary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? Colors.white : ClientColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({
    required this.categories,
    required this.isLoading,
    required this.error,
    required this.selectedCategory,
    required this.onRetry,
    required this.onSelect,
  });

  final List<String> categories;
  final bool isLoading;
  final String? error;
  final String? selectedCategory;
  final Future<void> Function() onRetry;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isLoading && categories.isEmpty) {
      return SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, __) => const _CategorySkeleton(),
        ),
      );
    }
    if (error != null && categories.isEmpty) {
      return _HomeErrorState(message: error!, onRetry: onRetry);
    }
    if (categories.isEmpty) {
      return _HomeEmptyState(
        icon: Icons.category_outlined,
        message: l10n.noCategoriesFound,
      );
    }

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final category = categories[i];
          return _CategoryCard(
            label: category,
            icon: _categoryIcons[i % _categoryIcons.length],
            selected: selectedCategory == category,
            onTap: () => onSelect(category),
          );
        },
      ),
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: ClientColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.outline),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ClientColors.primary,
          ),
        ),
      ),
    );
  }
}

class _NewProductsSection extends StatelessWidget {
  const _NewProductsSection({
    required this.products,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onAdd,
  });

  final List<Product> products;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRetry;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isLoading && products.isEmpty) {
      return const SizedBox(
        height: 302,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null && products.isEmpty) {
      return _HomeErrorState(message: error!, onRetry: onRetry);
    }
    if (products.isEmpty) {
      return _HomeEmptyState(
        icon: Icons.new_releases_outlined,
        message: l10n.noNewProducts,
      );
    }

    return SizedBox(
      height: 302,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final product = products[i];
          return SizedBox(
            width: 190,
            child: ProductCard(
              product: product,
              onTap: () => context.push('/client/product/${product.id}'),
              onAdd: () => onAdd(product),
            ),
          );
        },
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: ClientColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ClientColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: ClientColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: ClientColors.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: l10n.retry,
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            color: ClientColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ReorderSection extends StatelessWidget {
  const _ReorderSection({
    required this.recommendations,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onAdd,
  });

  final List<ReorderRecommendation> recommendations;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRetry;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isLoading && recommendations.isEmpty) {
      return const SizedBox(
        height: 302,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null && recommendations.isEmpty) {
      return _HomeErrorState(message: error!, onRetry: onRetry);
    }
    if (recommendations.isEmpty) {
      return _HomeEmptyState(
        icon: Icons.repeat_rounded,
        message: l10n.noReorderRecommendations,
      );
    }

    return SizedBox(
      height: 302,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recommendations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final recommendation = recommendations[i];
          return SizedBox(
            width: 190,
            child: ProductCard(
              product: recommendation.product,
              onTap: () =>
                  context.push('/client/product/${recommendation.product.id}'),
              onAdd: () => onAdd(recommendation.product),
            ),
          );
        },
      ),
    );
  }
}

class _CurrentOffersSection extends StatelessWidget {
  const _CurrentOffersSection({
    required this.offers,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final List<PromotionalOffer> offers;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isLoading && offers.isEmpty) {
      return const SizedBox(
        height: 184,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null && offers.isEmpty) {
      return _HomeErrorState(message: error!, onRetry: onRetry);
    }
    if (offers.isEmpty) {
      return _HomeEmptyState(
        icon: Icons.local_offer_outlined,
        message: l10n.noOffersFound,
      );
    }

    return SizedBox(
      height: 184,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final offer = offers[i];
          return _CompactOfferCard(
            offer: offer,
            onTap: () =>
                context.push('/client/offer/${offer.id}', extra: offer),
          );
        },
      ),
    );
  }
}

class _CompactOfferCard extends StatelessWidget {
  const _CompactOfferCard({required this.offer, required this.onTap});

  final PromotionalOffer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Material(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ClientColors.outline),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  height: double.infinity,
                  child: offer.imageUrl == null
                      ? const ColoredBox(
                          color: ClientColors.primarySoft,
                          child: Icon(
                            Icons.local_offer_outlined,
                            color: ClientColors.primary,
                            size: 28,
                          ),
                        )
                      : Image.network(
                          offer.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: ClientColors.primarySoft,
                            child: Icon(
                              Icons.local_offer_outlined,
                              color: ClientColors.primary,
                            ),
                          ),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (offer.discountText?.trim().isNotEmpty == true)
                          Text(
                            offer.discountText!,
                            style: const TextStyle(
                              color: ClientColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 5),
                        Text(
                          offer.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: ClientColors.text,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (offer.description?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            offer.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: ClientColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferCarousel extends StatefulWidget {
  const _OfferCarousel({
    required this.offers,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final List<PromotionalOffer> offers;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRetry;

  @override
  State<_OfferCarousel> createState() => _OfferCarouselState();
}

class _OfferCarouselState extends State<_OfferCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _configureTimer();
  }

  @override
  void didUpdateWidget(covariant _OfferCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offers.length != widget.offers.length) {
      _configureTimer();
      if (_currentPage >= widget.offers.length && widget.offers.isNotEmpty) {
        _currentPage = 0;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _pageController.jumpToPage(0),
        );
      }
    }
  }

  void _configureTimer() {
    _timer?.cancel();
    if (widget.offers.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % widget.offers.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.isLoading && widget.offers.isEmpty) {
      return const SizedBox(
        height: 218,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.error != null && widget.offers.isEmpty) {
      return _HomeErrorState(message: widget.error!, onRetry: widget.onRetry);
    }
    if (widget.offers.isEmpty) {
      return Container(
        height: 112,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ClientColors.surfaceMuted,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ClientColors.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer_outlined, color: ClientColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.noOffersFound,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ClientColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 218,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.offers.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final offer = widget.offers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _OfferSlide(
                  offer: offer,
                  onTap: () =>
                      context.push('/client/offer/${offer.id}', extra: offer),
                ),
              );
            },
          ),
        ),
        if (widget.offers.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.offers.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: i == _currentPage ? 22 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? ClientColors.primary
                          : ClientColors.outline,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _OfferSlide extends StatelessWidget {
  const _OfferSlide({required this.offer, required this.onTap});

  final PromotionalOffer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClientColors.navy,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (offer.imageUrl != null)
              Image.network(
                offer.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC102A43)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (offer.discountText?.trim().isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: ClientColors.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        offer.discountText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    offer.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (offer.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      offer.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.viewOffer,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 17,
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
}

class _LatestUpdatesTicker extends StatefulWidget {
  const _LatestUpdatesTicker({
    required this.offers,
    required this.newProducts,
    required this.reorderRecommendations,
  });

  final List<PromotionalOffer> offers;
  final List<Product> newProducts;
  final List<ReorderRecommendation> reorderRecommendations;

  @override
  State<_LatestUpdatesTicker> createState() => _LatestUpdatesTickerState();
}

class _LatestUpdatesTickerState extends State<_LatestUpdatesTicker> {
  final _scrollController = ScrollController();
  Timer? _timer;

  List<String> _contentFor(_LatestUpdatesTicker value) => [
    ...value.offers
        .take(3)
        .map(
          (offer) => [
            offer.title,
            if (offer.discountText?.trim().isNotEmpty == true)
              offer.discountText!,
          ].join(' — '),
        ),
    ...value.newProducts.take(3).map((product) => product.name),
    ...value.reorderRecommendations
        .take(2)
        .map((recommendation) => recommendation.product.name),
  ];

  List<String> get _content => _contentFor(widget);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void didUpdateWidget(covariant _LatestUpdatesTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_contentFor(oldWidget).join('|') != _content.join('|')) {
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
    }
  }

  void _startScrolling() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent <= 0) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final target = _scrollController.offset >= max - 2 ? 0.0 : max;
      await _scrollController.animateTo(
        target,
        duration: const Duration(seconds: 3),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = _content.isEmpty ? l10n.noUpdates : _content.join('   •   ');
    return Container(
      height: 42,
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ClientColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClientColors.outline),
      ),
      child: Row(
        children: [
          Container(
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            color: ClientColors.primarySoft,
            child: Text(
              l10n.latestUpdates,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: ClientColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              reverse: Directionality.of(context) == TextDirection.rtl,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                text,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ClientColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
