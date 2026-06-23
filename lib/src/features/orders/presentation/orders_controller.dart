import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../cart/presentation/cart_controller.dart';
import '../data/order_repository.dart';
import '../data/razorpay_service.dart';
import '../domain/order.dart';

/// The signed-in customer's order history.
final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).fetchOrders();
});

/// Handles checkout: posts the order, then refreshes cart + order history.
class CheckoutController extends AutoDisposeAsyncNotifier<Order?> {
  @override
  Future<Order?> build() async => null;

  Future<Order?> placeOrder({
    required String addressId,
    required String paymentMethod,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard<Order?>(() async {
      final checkout = await ref.read(orderRepositoryProvider).placeOrder(
        addressId: addressId,
        paymentMethod: paymentMethod,
      );
      ref.invalidate(cartControllerProvider);
      ref.invalidate(ordersProvider);

      if (paymentMethod != 'RAZORPAY') {
        return checkout.order;
      }

      final razorpay = checkout.razorpay;
      if (razorpay == null) {
        throw ApiException('Razorpay checkout details were not returned.');
      }

      final payment = await ref.read(razorpayServiceProvider).pay(razorpay);
      final paidOrder = await ref.read(orderRepositoryProvider).verifyRazorpayPayment(
        orderId: checkout.order.id,
        razorpayOrderId: payment.orderId,
        razorpayPaymentId: payment.paymentId,
        razorpaySignature: payment.signature,
      );
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
