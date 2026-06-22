import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/product_repository.dart';
import '../domain/product.dart';

/// Current catalog search query.
final productSearchProvider = StateProvider<String>((ref) => '');

/// Product catalog, reactive to [productSearchProvider].
final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final search = ref.watch(productSearchProvider);
  return ref.watch(productRepositoryProvider).fetchProducts(search: search);
});
