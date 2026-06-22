import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/formatters.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../cart/presentation/cart_controller.dart';
import '../domain/product.dart';
import 'products_controller.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SearchBar(
            hintText: 'Search products…',
            leading: const Icon(Icons.search),
            onSubmitted: (value) =>
                ref.read(productSearchProvider.notifier).state = value.trim(),
          ),
        ),
        Expanded(
          child: AsyncValueView<List<Product>>(
            value: productsAsync,
            onRetry: () => ref.invalidate(productsProvider),
            data: (products) {
              if (products.isEmpty) {
                return const Center(child: Text('No products found.'));
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(productsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _ProductCard(product: products[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = product.defaultVariant;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.checkroom_outlined, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.categoryName != null)
                    Text(product.categoryName!, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    'From ${formatCurrency(product.fromPrice)}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  if (variant != null)
                    Text(
                      'MOQ ${variant.minOrderQty} · ${variant.inStock ? '${variant.stockQuantity} in stock' : 'Out of stock'}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: (variant == null || !variant.inStock)
                  ? null
                  : () {
                      ref.read(cartControllerProvider.notifier).add(product, variant);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text('Added ${product.name} to cart'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                    },
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
