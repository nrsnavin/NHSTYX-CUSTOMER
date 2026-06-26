import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../products/domain/product.dart';
import '../../products/presentation/product_card.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../../products/presentation/products_controller.dart';
import '../domain/category.dart';

/// A dedicated page listing the products of one category. If the category has
/// sub-categories, a chip rail lets the shopper narrow to one of them.
class CategoryProductsScreen extends ConsumerStatefulWidget {
  const CategoryProductsScreen({super.key, required this.category});

  final Category category;

  @override
  ConsumerState<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends ConsumerState<CategoryProductsScreen> {
  // null = the whole category (parent, which includes all children on the
  // backend); otherwise a specific sub-category id.
  String? _subId;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final children = category.children;
    final effectiveId = _subId ?? category.id;
    final productsAsync = ref.watch(categoryProductsProvider(effectiveId));

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: Column(
        children: [
          if (children.isNotEmpty)
            _SubCategoryRail(
              parent: category,
              selectedId: _subId,
              onSelect: (id) => setState(() => _subId = id),
            ),
          Expanded(
            child: AsyncValueView<List<Product>>(
              value: productsAsync,
              onRetry: () => ref.invalidate(categoryProductsProvider(effectiveId)),
              loading: () => const ProductGridSkeleton(),
              data: (products) {
                if (products.isEmpty) return const _EmptyCategory();
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(categoryProductsProvider(effectiveId)),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
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
}

/// Horizontal "All · sub-category" selector for a parent category.
class _SubCategoryRail extends StatelessWidget {
  const _SubCategoryRail({required this.parent, required this.selectedId, required this.onSelect});

  final Category parent;
  final String? selectedId;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _Chip(label: 'All', selected: selectedId == null, onTap: () => onSelect(null)),
          for (final c in parent.children)
            _Chip(label: c.name, selected: selectedId == c.id, onTap: () => onSelect(c.id)),
        ],
      ),
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
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        labelStyle: TextStyle(
          color: selected ? scheme.onPrimary : scheme.onSurface,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        selectedColor: scheme.primary,
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text('No products in this category yet', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
