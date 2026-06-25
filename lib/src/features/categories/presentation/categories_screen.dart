import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/product_thumb.dart';
import '../../home/presentation/home_screen.dart';
import '../../products/presentation/products_controller.dart';
import '../../search/presentation/ai_search_screen.dart';
import '../domain/category.dart';
import 'category_controller.dart';

/// Browse all categories, grouped by parent with their sub-categories as cards
/// (Instamart-style). Picking a (sub-)category filters the Home tab by it —
/// tree-aware on the backend, so a parent includes its children.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  void _select(WidgetRef ref, Category c) {
    ref.read(productSearchProvider.notifier).state = '';
    ref.read(selectedCategoryProvider.notifier).state = c;
    ref.read(homeTabProvider.notifier).state = 0; // back to Home, now filtered
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiSearchScreen()),
            ),
          ),
        ],
      ),
      body: AsyncValueView<List<Category>>(
        value: categoriesAsync,
        onRetry: () => ref.invalidate(categoriesProvider),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories yet'));
          }
          final withChildren = categories.where((c) => c.children.isNotEmpty).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text('Shop by category',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _CategoryGrid(items: categories, onTap: (c) => _select(ref, c)),
              for (final parent in withChildren) ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(parent.name,
                          style:
                              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    TextButton(
                      onPressed: () => _select(ref, parent),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _CategoryGrid(items: parent.children, onTap: (c) => _select(ref, c)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.items, required this.onTap});

  final List<Category> items;
  final void Function(Category) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _CategoryTile(category: items[i], onTap: () => onTap(items[i])),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = category.imageUrl != null && category.imageUrl!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? ProductThumb(imageUrl: category.imageUrl)
                  : Icon(Icons.category_outlined, color: theme.colorScheme.primary, size: 30),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
