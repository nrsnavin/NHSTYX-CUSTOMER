import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../cart/domain/cart_item.dart';
import '../domain/order.dart';

class OrderRepository {
  OrderRepository(this._dio);

  final Dio _dio;

  Future<Order> placeOrder(List<CartItem> items, {String? notes}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders',
        data: {
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'items': items
              .map((item) => {'variantId': item.variant.id, 'quantity': item.quantity})
              .toList(),
        },
      );
      return Order.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Order>> fetchOrders({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/orders',
        queryParameters: {'page': page, 'limit': limit},
      );
      final items = response.data!['items'] as List<dynamic>;
      return items.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(dioProvider));
});
