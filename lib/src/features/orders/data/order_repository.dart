import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/order.dart';

class RazorpayCheckout {
  const RazorpayCheckout({
    required this.enabled,
    required this.keyId,
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.name,
    required this.description,
    required this.prefill,
    required this.notes,
  });

  final bool enabled;
  final String? keyId;
  final String orderId;
  final int amountPaise;
  final String currency;
  final String name;
  final String description;
  final Map<String, dynamic> prefill;
  final Map<String, dynamic> notes;

  factory RazorpayCheckout.fromJson(Map<String, dynamic> json) {
    return RazorpayCheckout(
      enabled: json['enabled'] == true,
      keyId: json['keyId'] as String?,
      orderId: json['orderId'] as String,
      amountPaise: _toInt(json['amountPaise']),
      currency: (json['currency'] ?? 'INR') as String,
      name: (json['name'] ?? 'NH Styx') as String,
      description: (json['description'] ?? 'Order payment') as String,
      prefill: Map<String, dynamic>.from(json['prefill'] as Map? ?? const {}),
      notes: Map<String, dynamic>.from(json['notes'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toOptions() {
    final key = keyId;
    if (!enabled || key == null || key.isEmpty) {
      throw ApiException('Razorpay is not configured yet. Please choose another payment method.');
    }
    return {
      'key': key,
      'amount': amountPaise,
      'currency': currency,
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': prefill,
      'notes': notes,
      'theme': {'color': '#111111'},
    };
  }
}

class CheckoutResult {
  const CheckoutResult({required this.order, this.razorpay});

  final Order order;
  final RazorpayCheckout? razorpay;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    final orderJson = json['order'] is Map<String, dynamic>
        ? json['order'] as Map<String, dynamic>
        : json;
    return CheckoutResult(
      order: Order.fromJson(orderJson),
      razorpay: json['razorpay'] is Map<String, dynamic>
          ? RazorpayCheckout.fromJson(json['razorpay'] as Map<String, dynamic>)
          : null,
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class OrderRepository {
  OrderRepository(this._dio);

  final Dio _dio;

  Future<CheckoutResult> placeOrder({
    required String addressId,
    required String paymentMethod,
    String? notes,
    String? bankReference,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders',
        data: {
          'addressId': addressId,
          'paymentMethod': paymentMethod,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (bankReference != null && bankReference.isNotEmpty) 'bankReference': bankReference,
        },
      );
      return CheckoutResult.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Order> verifyRazorpayPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders/$orderId/pay/razorpay/verify',
        data: {
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
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

  /// (Re)issues a Razorpay checkout for an existing unpaid online order, so the
  /// customer can pay it from the Orders screen (e.g. an agent-placed order).
  Future<RazorpayCheckout> payRazorpay(String orderId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/orders/$orderId/pay/razorpay');
      return RazorpayCheckout.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Downloads the GST invoice PDF bytes for an order (paid orders only).
  Future<Uint8List> fetchInvoice(String orderId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/orders/$orderId/invoice',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(dioProvider));
});
