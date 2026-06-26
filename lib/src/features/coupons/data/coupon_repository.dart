import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// A coupon the customer has successfully applied to their current cart. The
/// discount is what the server computed for that cart's subtotal.
class AppliedCoupon {
  const AppliedCoupon({
    required this.code,
    required this.discountPaise,
    required this.subtotalPaise,
    this.description,
  });

  final String code;
  final int discountPaise;
  final int subtotalPaise;
  final String? description;
}

class CouponRepository {
  CouponRepository(this._dio);

  final Dio _dio;

  /// Validates a code against the customer's live cart and returns the
  /// discount it would grant. Throws [ApiException] with a friendly message
  /// when the coupon is invalid / ineligible.
  Future<AppliedCoupon> validate(String code) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/coupons/validate',
        data: {'code': code.trim().toUpperCase()},
      );
      final d = response.data!['data'] as Map<String, dynamic>;
      return AppliedCoupon(
        code: (d['code'] ?? code).toString(),
        discountPaise: _toInt(d['discountPaise']),
        subtotalPaise: _toInt(d['subtotalPaise']),
        description: d['description'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  return CouponRepository(ref.watch(dioProvider));
});

/// The coupon currently applied to the cart (null = none). Cleared whenever
/// the cart changes or an order is placed, so the shown discount is never stale.
final appliedCouponProvider = StateProvider<AppliedCoupon?>((ref) => null);
