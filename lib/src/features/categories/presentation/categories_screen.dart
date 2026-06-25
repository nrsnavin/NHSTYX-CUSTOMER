import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/product_thumb.dart';
import '../../products/presentation/products_controller.dart';
import '../domain/category.dart';
import 'category_controller.dart';

/// Full-page browse of all categories. Picking one filters the Shop tab by
/// that category (tree-aware on the backend, so a parent includes its children).
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: AsyncValueView<List<Category>>(
        value: categoriesAsync,
        onRetry: () => ref.invalidate(categoriesProvider),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories yet'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.82,
            ),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final c = categories[i];
              return _CategoryTile(category: c, onTap: () => _select(context, ref, c));
            },
          );
        },
      ),
    );
  }

  void _select(BuildContext context, WidgetRef ref, Category c) {
    // Clear any text filter so the category selection is what shows on Shop.
    ref.read(productSearchProvider.notifier).state = '';
    ref.read(selectedCategoryProvider.notifier).state = c;
    Navigator.of(context).pop();
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
