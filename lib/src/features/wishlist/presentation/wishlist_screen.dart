import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/product_grid.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/product_card.dart';
import '../../products/presentation/product_detail_screen.dart';
import 'wishlist_controller.dart';

/// The shop's saved products. Cards carry the same quick-add stepper as the
/// storefront; the heart on each card (filled here) removes it from the list.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);
    // The live id set lets a removed card disappear instantly, before the
    // background re-fetch of the full list completes.
    final ids = ref.watch(wishlistIdsProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: AsyncValueView<List<Product>>(
        value: wishlistAsync,
        onRetry: () => ref.invalidate(wishlistProvider),
        loading: () => const ProductGridSkeleton(),
        data: (products) {
          final visible = ids == null
              ? products
              : products.where((p) => ids.contains(p.id)).toList();
          if (visible.isEmpty) return const _EmptyWishlist();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(wishlistProvider);
              ref.invalidate(wishlistIdsProvider);
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: productGridDelegate,
              itemCount: visible.length,
              itemBuilder: (context, i) {
                final p = visible[i];
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
    );
  }
}

class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('Your wishlist is empty', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Tap the heart on any product to save it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
