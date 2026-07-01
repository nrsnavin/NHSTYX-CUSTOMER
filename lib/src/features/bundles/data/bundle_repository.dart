import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/bundle.dart';

/// Talks to the bundles API. The list endpoint returns bundles already priced
/// for the shopper's store (per-item price, totals, availability).
class BundleRepository {
  BundleRepository(this._dio);

  final Dio _dio;

  Future<List<Bundle>> list() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/bundles');
      final items = response.data?['items'] as List<dynamic>? ?? const [];
      return items.map((e) => Bundle.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Expands the whole bundle into the shopper's server-side cart.
  Future<void> addToCart(String bundleId) async {
    try {
      await _dio.post<Map<String, dynamic>>('/bundles/$bundleId/add-to-cart');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final bundleRepositoryProvider = Provider<BundleRepository>((ref) {
  return BundleRepository(ref.watch(dioProvider));
});
