import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/cart.dart';

class CartRepository {
  CartRepository(this._dio);

  final Dio _dio;

  Cart _parse(Response<Map<String, dynamic>> response) =>
      Cart.fromJson(response.data!['data'] as Map<String, dynamic>);

  Future<Cart> getCart() async {
    try {
      return _parse(await _dio.get<Map<String, dynamic>>('/cart'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Cart> addItem(String productId, int quantity, {String? variantId}) async {
    try {
      return _parse(await _dio.post<Map<String, dynamic>>(
        '/cart/items',
        data: {
          'productId': productId,
          'quantity': quantity,
          if (variantId != null) 'variantId': variantId,
        },
      ));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Cart> setQuantity(String productId, int quantity, {String? variantId}) async {
    try {
      return _parse(await _dio.patch<Map<String, dynamic>>(
        '/cart/items/$productId',
        data: {'quantity': quantity, if (variantId != null) 'variantId': variantId},
      ));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Cart> removeItem(String productId, {String? variantId}) async {
    try {
      return _parse(await _dio.delete<Map<String, dynamic>>(
        '/cart/items/$productId',
        queryParameters: {if (variantId != null) 'variantId': variantId},
      ));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Cart> clear() async {
    try {
      return _parse(await _dio.delete<Map<String, dynamic>>('/cart'));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(dioProvider));
});
