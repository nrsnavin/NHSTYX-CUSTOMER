import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/category_repository.dart';
import '../domain/category.dart';

/// Top-level categories (each with its sub-categories).
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).fetchCategories();
});

/// Currently selected category filter on the Shop tab (null = All).
final selectedCategoryProvider = StateProvider<Category?>((ref) => null);
