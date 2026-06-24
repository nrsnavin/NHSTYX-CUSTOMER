import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../categories/presentation/category_controller.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../home/presentation/home_screen.dart';
import '../../search/presentation/ai_search_screen.dart';
import '../domain/product.dart';
import 'product_card.dart';
import 'product_detail_screen.dart';
import 'products_controller.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final store = ref.watch(authControllerProvider).valueOrNull?.store;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: _LocationHeader(
          city: store?.city,
          storeName: store?.name,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            color: Theme.of(context).colorScheme.primary,
            tooltip: 'AI search',
            onPressed: () => _openSearch(context),
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
          Expanded(
            child: AsyncValueView<List<Product>>(
              value: productsAsync,
              onRetry: () => ref.invalidate(productsProvider),
              loading: () => const ProductGridSkeleton(),
              data: (products) {
                if (products.isEmpty) {
                  return _EmptyCatalog(hasStore: store != null);
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(productsProvider),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, i) {
                      final p = products[i];
                      return ProductCard(
                        product: p,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiSearchScreen()));
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
            onTap: () => ref.read(homeTabProvider.notifier).state = 1,
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

class _CategoryRail extends ConsumerWidget {
  const _CategoryRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selected = ref.watch(selectedCategoryProvider);

    return categoriesAsync.maybeWhen(
      orElse: () => const SizedBox(height: 44),
      data: (categories) {
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _Chip(
                label: 'All',
                selected: selected == null,
                onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
              ),
              for (final c in categories)
                _Chip(
                  label: c.name,
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? scheme.primary : scheme.outline),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.onPrimary : scheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
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
