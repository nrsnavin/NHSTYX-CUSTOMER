import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/domain/cart_item.dart';
import '../../cart/presentation/cart_controller.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';

/// The signed-in customer's order history.
final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  return ref.watch(orderRepositoryProvider).fetchOrders();
});

/// Handles checkout: posts the cart, clears it, and refreshes order history.
class CheckoutController extends AutoDisposeAsyncNotifier<Order?> {
  @override
  Future<Order?> build() async => null;

  Future<Order?> placeOrder({String? notes}) async {
    final cart = ref.read(cartControllerProvider);
    if (cart.isEmpty) return null;

    state = const AsyncLoading();
    final result = await AsyncValue.guard<Order?>(() async {
      final List<CartItem> items = List.of(cart);
      final order = await ref.read(orderRepositoryProvider).placeOrder(items, notes: notes);
      ref.read(cartControllerProvider.notifier).clear();
      ref.invalidate(ordersProvider);
      return order;
    });
    state = result;
    return result.valueOrNull;
  }
}

final checkoutControllerProvider =
    AutoDisposeAsyncNotifierProvider<CheckoutController, Order?>(CheckoutController.new);
