import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/product.dart';

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
