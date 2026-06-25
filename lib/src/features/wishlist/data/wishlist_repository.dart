import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../products/domain/product.dart';

/// Talks to the customer wishlist API. The list endpoint returns the same
/// store-scoped product shape the rest of the catalog uses, so it parses
/// straight into [Product].
class WishlistRepository {
  WishlistRepository(this._dio);

  final Dio _dio;

  /// Full product cards for the wishlist screen.
  Future<List<Product>> list() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/wishlist');
      final items = response.data?['items'] as List<dynamic>? ?? const [];
      return items.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// The set of wishlisted product ids — powers the heart toggle everywhere.
  Future<Set<String>> ids() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/wishlist/ids');
      final ids = response.data?['data'] as List<dynamic>? ?? const [];
      return ids.map((e) => e.toString()).toSet();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> add(String productId) async {
    try {
      await _dio.post<Map<String, dynamic>>('/wishlist/$productId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> remove(String productId) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/wishlist/$productId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(ref.watch(dioProvider));
});
