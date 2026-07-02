import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/presentation/category_controller.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';
import '../domain/review.dart';

/// Free-text filter typed on the Shop tab's inline search field.
final productSearchProvider = StateProvider<String>((ref) => '');

/// Accumulated catalog feed for the Shop tab: the products loaded so far plus
/// whether more pages remain and whether a "load more" fetch is in flight.
class ProductFeedState {
  const ProductFeedState({
    required this.products,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<Product> products;
  final bool hasMore;
  final bool loadingMore;

  ProductFeedState copyWith({List<Product>? products, bool? hasMore, bool? loadingMore}) {
    return ProductFeedState(
      products: products ?? this.products,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// Paginating product catalog, reactive to the selected category and search
/// text. The first page loads on build; [loadMore] appends the next page as
/// the shopper scrolls, giving the wholesale catalog true infinite scroll.
class ProductFeedNotifier extends AutoDisposeAsyncNotifier<ProductFeedState> {
  static const _pageSize = 24;
  int _page = 1;

  @override
  Future<ProductFeedState> build() async {
    final search = ref.watch(productSearchProvider);
    final category = ref.watch(selectedCategoryProvider);
    _page = 1;
    final result = await ref.watch(productRepositoryProvider).fetchProductPage(
          search: search.isEmpty ? null : search,
          categoryId: category?.id,
          page: 1,
          limit: _pageSize,
        );
    return ProductFeedState(products: result.items, hasMore: result.hasMore);
  }

  /// Fetch and append the next page. No-ops while a load is already running,
  /// or once the catalog is exhausted.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    final search = ref.read(productSearchProvider);
    final category = ref.read(selectedCategoryProvider);
    try {
      final result = await ref.read(productRepositoryProvider).fetchProductPage(
            search: search.isEmpty ? null : search,
            categoryId: category?.id,
            page: _page + 1,
            limit: _pageSize,
          );
      _page += 1;
      state = AsyncData(ProductFeedState(
        products: [...current.products, ...result.items],
        hasMore: result.hasMore,
      ));
    } catch (_) {
      // Keep what we have and drop the spinner; the shopper can scroll to retry.
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}

final productsProvider =
    AsyncNotifierProvider.autoDispose<ProductFeedNotifier, ProductFeedState>(
        ProductFeedNotifier.new);

/// Full detail for a single product (incl. its store variants) — backs the
/// product-detail page's variant selector.
final productDetailProvider =
    FutureProvider.autoDispose.family<Product, String>((ref, id) {
  return ref.watch(productRepositoryProvider).fetchProduct(id);
});

/// Products for a single category id — backs the dedicated category page.
/// Tree-aware on the backend (a parent includes its children).
final categoryProductsProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((ref, categoryId) {
  return ref.watch(productRepositoryProvider).fetchProducts(categoryId: categoryId, limit: 100);
});

/// A filter + sort query for the category page. A record gives value equality,
/// so the provider caches one result per distinct selection.
typedef ProductQuery = ({
  String categoryId,
  String sort,
  String? brand,
  int? minPaise,
  int? maxPaise,
  bool inStock,
});

/// Category products under an active filter + sort selection.
final filteredCategoryProductsProvider =
    FutureProvider.autoDispose.family<List<Product>, ProductQuery>((ref, q) {
  return ref.watch(productRepositoryProvider).fetchProducts(
        categoryId: q.categoryId,
        sort: q.sort,
        brand: q.brand,
        minPricePaise: q.minPaise,
        maxPricePaise: q.maxPaise,
        inStock: q.inStock,
        limit: 100,
      );
});

/// Distinct brands the customer's store stocks (powers the brand filter).
final storeBrandsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(productRepositoryProvider).fetchBrands();
});

/// A product's rating summary + recent reviews.
final productReviewsProvider =
    FutureProvider.autoDispose.family<ReviewSummary, String>((ref, productId) {
  return ref.watch(productRepositoryProvider).fetchReviews(productId);
});

/// The shop's own review for a product (null if not yet reviewed).
final myReviewProvider =
    FutureProvider.autoDispose.family<({int rating, String? comment})?, String>((ref, productId) {
  return ref.watch(productRepositoryProvider).fetchMyReview(productId);
});

/// Best sellers in the customer's city/store (home rail).
final bestSellingProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).fetchBestSelling();
});

/// Products the customer ordered before (home rail). Empty for new customers.
final recentlyOrderedProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).fetchRecentlyOrdered();
});
