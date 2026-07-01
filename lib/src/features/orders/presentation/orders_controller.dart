import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../coupons/data/coupon_repository.dart';
import '../data/order_repository.dart';
import '../data/razorpay_service.dart';
import '../domain/order.dart';
import '../domain/order_tracking.dart';

/// The signed-in customer's order history.
final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).fetchOrders();
});

/// Shipment tracking timeline for a single order (backs the detail screen).
final orderTrackingProvider =
    FutureProvider.autoDispose.family<OrderTracking, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).fetchTracking(orderId);
});

/// Handles checkout: posts the order, then refreshes cart + order history.
class CheckoutController extends AutoDisposeAsyncNotifier<Order?> {
  @override
  Future<Order?> build() async => null;

  Future<Order?> placeOrder({
    required String addressId,
    required String paymentMethod,
    String? bankReference,
    String? couponCode,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard<Order?>(() async {
      final checkout = await ref.read(orderRepositoryProvider).placeOrder(
        addressId: addressId,
        paymentMethod: paymentMethod,
        bankReference: bankReference,
        couponCode: couponCode,
      );

      if (paymentMethod != 'RAZORPAY') {
        // Order is final the moment it's placed — the server already emptied
        // the cart, so refresh it (now empty) and the order history.
        ref.read(appliedCouponProvider.notifier).state = null;
        ref.invalidate(cartControllerProvider);
        ref.invalidate(ordersProvider);
        return checkout.order;
      }

      final razorpay = checkout.razorpay;
      if (razorpay == null) {
        throw ApiException('Razorpay checkout details were not returned.');
      }

      // Payment can fail or be cancelled here. If so, pay() throws BEFORE we
      // touch the cart — the server also keeps it intact until verification —
      // so the customer keeps their items and can retry.
      final payment = await ref.read(razorpayServiceProvider).pay(razorpay);
      final paidOrder = await ref.read(orderRepositoryProvider).verifyRazorpayPayment(
        orderId: checkout.order.id,
        razorpayOrderId: payment.orderId,
        razorpayPaymentId: payment.paymentId,
        razorpaySignature: payment.signature,
      );

      // Paid + verified — the server has now emptied the cart; refresh both.
      ref.read(appliedCouponProvider.notifier).state = null;
      ref.invalidate(cartControllerProvider);
      ref.invalidate(ordersProvider);
      return paidOrder;
    });
    state = result;
    return result.valueOrNull;
  }
}

final checkoutControllerProvider =
AutoDisposeAsyncNotifierProvider<CheckoutController, Order?>(CheckoutController.new);
