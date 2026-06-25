import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/presentation/category_controller.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../home/presentation/home_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../search/presentation/ai_search_screen.dart';
import '../domain/product.dart';
import 'product_card.dart';
import 'product_detail_screen.dart';
import 'products_controller.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(authControllerProvider).valueOrNull?.store;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: _LocationHeader(
          city: store?.city,
          storeName: store?.name,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.person, color: scheme.onPrimaryContainer, size: 22),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _ViewCartBar(),
      body: Column(
        children: [
          // Tappable AI search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _SearchField(onTap: () => _openSearch(context)),
          ),
          const _CategoryRail(),
          const SizedBox(height: 4),
          const Expanded(child: _ShopFeed()),
        ],
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiSearchScreen()));
  }
}

/// The shop's scrolling feed. On the unfiltered home it leads with the
/// best-selling and recently-ordered rails; once a category or search is
/// active it shows just the matching grid.
class _ShopFeed extends ConsumerWidget {
  const _ShopFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final store = ref.watch(authControllerProvider).valueOrNull?.store;
    final filtering = ref.watch(selectedCategoryProvider) != null ||
        ref.watch(productSearchProvider).isNotEmpty;
    final city = store?.city;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productsProvider);
        ref.invalidate(bestSellingProvider);
        ref.invalidate(recentlyOrderedProvider);
      },
      child: CustomScrollView(
        slivers: [
          if (!filtering) ...[
            _ProductRailSliver(
              title: (city == null || city.isEmpty) ? 'Best selling' : 'Best selling in $city',
              icon: Icons.local_fire_department_outlined,
              provider: bestSellingProvider,
            ),
            _ProductRailSliver(
              title: 'Recently ordered',
              icon: Icons.history,
              provider: recentlyOrderedProvider,
            ),
            const _SectionHeaderSliver(title: 'All products'),
          ],
          ...productsAsync.when(
            loading: () => const [SliverFillRemaining(child: ProductGridSkeleton())],
            error: (e, _) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(e.toString())),
                ),
              ),
            ],
            data: (products) {
              if (products.isEmpty) {
                return [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyCatalog(hasStore: store != null),
                  ),
                ];
              }
              return [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.62,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final p = products[i];
                        return ProductCard(
                          product: p,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                          ),
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

/// A horizontal product rail backed by an async provider; renders nothing
/// until it has at least one product (so empty rails — e.g. a new customer's
/// "Recently ordered" — simply disappear).
class _ProductRailSliver extends ConsumerWidget {
  const _ProductRailSliver({required this.title, required this.icon, required this.provider});

  final String title;
  final IconData icon;
  final ProviderListenable<AsyncValue<List<Product>>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(provider).valueOrNull ?? const <Product>[];
    if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverToBoxAdapter(child: _ProductRail(title: title, icon: icon, products: products));
  }
}

class _ProductRail extends StatelessWidget {
  const _ProductRail({required this.title, required this.icon, required this.products});

  final String title;
  final IconData icon;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = products[i];
              return SizedBox(
                width: 152,
                child: ProductCard(
                  product: p,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderSliver extends StatelessWidget {
  const _SectionHeaderSliver({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Persistent "View cart" bar that slides in when the basket has items —
/// taps jump straight to the Cart tab.
class _ViewCartBar extends ConsumerWidget {
  const _ViewCartBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    if (cart == null || cart.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Material(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => ref.read(homeTabProvider.notifier).state = 3,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag, color: scheme.onPrimary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${cart.totalQuantity} item${cart.totalQuantity == 1 ? '' : 's'} · ${formatPaise(cart.subtotalPaise)}',
                      style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text('View cart',
                      style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700)),
                  Icon(Icons.chevron_right, color: scheme.onPrimary, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Blinkit-style location header: city up front, fulfilling store beneath.
class _LocationHeader extends StatelessWidget {
  const _LocationHeader({this.city, this.storeName});
  final String? city;
  final String? storeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasStore = city != null && city!.isNotEmpty;
    return Row(
      children: [
        Icon(Icons.location_on, color: scheme.primary, size: 26),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      hasStore ? city! : 'NH Styx',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (hasStore) Icon(Icons.keyboard_arrow_down, size: 20, color: scheme.onSurface),
                ],
              ),
              Text(
                hasStore ? 'Shipped from ${storeName ?? ''}' : 'Everything your store needs',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Search anything for your store…',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Instamart-style main category tabs: a horizontal row of icon + label
/// tiles, the selected one highlighted.
class _CategoryRail extends ConsumerWidget {
  const _CategoryRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selected = ref.watch(selectedCategoryProvider);

    return categoriesAsync.maybeWhen(
      orElse: () => const SizedBox(height: 88),
      data: (categories) {
        return SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _CategoryTab(
                label: 'All',
                icon: Icons.apps,
                imageUrl: null,
                selected: selected == null,
                onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
              ),
              for (final c in categories)
                _CategoryTab(
                  label: c.name,
                  icon: Icons.category_outlined,
                  imageUrl: c.imageUrl,
                  selected: selected?.id == c.id,
                  onTap: () => ref.read(selectedCategoryProvider.notifier).state = c,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: selected ? scheme.primary : scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: hasImage
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      width: 54,
                      height: 54,
                      errorBuilder: (_, __, ___) =>
                          Icon(icon, color: selected ? scheme.onPrimary : scheme.primary, size: 26),
                    )
                  : Icon(icon, color: selected ? scheme.onPrimary : scheme.primary, size: 26),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.hasStore});
  final bool hasStore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(
          hasStore ? Icons.inventory_2_outlined : Icons.location_off_outlined,
          size: 48,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            hasStore ? 'No products here yet' : "We don't serve your city yet",
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (!hasStore) ...[
          const SizedBox(height: 6),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Contact support to get your store connected.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
