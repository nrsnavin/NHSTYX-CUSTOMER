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
        },
      );
      final items = response.data!['items'] as List<dynamic>;
      return items.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
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
