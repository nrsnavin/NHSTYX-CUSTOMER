import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/presentation/category_controller.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';

/// Free-text filter typed on the Shop tab's inline search field.
final productSearchProvider = StateProvider<String>((ref) => '');

/// Product catalog, reactive to the selected category and search text.
final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final search = ref.watch(productSearchProvider);
  final category = ref.watch(selectedCategoryProvider);
  return ref.watch(productRepositoryProvider).fetchProducts(
        search: search.isEmpty ? null : search,
        categoryId: category?.id,
      );
});

/// Best sellers in the customer's city/store (home rail).
final bestSellingProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).fetchBestSelling();
});

/// Products the customer ordered before (home rail). Empty for new customers.
final recentlyOrderedProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).fetchRecentlyOrdered();
});
