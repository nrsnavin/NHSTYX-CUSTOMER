import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/product.dart';
import '../domain/review.dart';

class ProductRepository {
  ProductRepository(this._dio);

  final Dio _dio;

  Future<List<Product>> fetchProducts({
    String? search,
    String? categoryId,
    String? sort,
    String? brand,
    int? minPricePaise,
    int? maxPricePaise,
    bool inStock = false,
    int page = 1,
    int limit = 40,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/products',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null) 'categoryId': categoryId,
          if (sort != null) 'sort': sort,
          if (brand != null && brand.isNotEmpty) 'brand': brand,
          if (minPricePaise != null) 'minPricePaise': minPricePaise,
          if (maxPricePaise != null) 'maxPricePaise': maxPricePaise,
          if (inStock) 'inStock': 'true',
        },
      );
      final items = response.data!['items'] as List<dynamic>;
      return items.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Distinct brands the customer's store stocks (for the catalog filter).
  Future<List<String>> fetchBrands() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/products/brands');
      final items = response.data?['items'] as List<dynamic>? ?? const [];
      return items.map((e) => e as String).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// A single product with full detail (incl. its store variants).
  Future<Product> fetchProduct(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/products/$id');
      return Product.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Best-selling products in the customer's city/store.
  Future<List<Product>> fetchBestSelling() => _fetchList('/products/best-selling');

  /// Products the customer has ordered before (most recent first).
  Future<List<Product>> fetchRecentlyOrdered() => _fetchList('/products/recently-ordered');

  /// A product's rating summary + recent reviews.
  Future<ReviewSummary> fetchReviews(String productId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/products/$productId/reviews');
      return ReviewSummary.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// The shop's own review for a product (to prefill the form), or null.
  Future<({int rating, String? comment})?> fetchMyReview(String productId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/products/$productId/reviews/mine');
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return (rating: (data['rating'] as num).toInt(), comment: data['comment'] as String?);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Create or update the shop's review for a product.
  Future<void> submitReview(String productId, {required int rating, String? comment}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/products/$productId/reviews',
        data: {'rating': rating, if (comment != null && comment.isNotEmpty) 'comment': comment},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Product>> _fetchList(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      final items = response.data?['items'] as List<dynamic>? ?? const [];
      return items.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(dioProvider));
});
