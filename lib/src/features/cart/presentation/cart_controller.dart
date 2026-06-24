import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cart_repository.dart';
import '../domain/cart.dart';

/// Server-backed cart. Each mutation returns the recomputed cart from the API;
/// on failure it rethrows (state stays on the last good cart) so the UI can
/// show a message without losing the basket.
class CartController extends AutoDisposeAsyncNotifier<Cart> {
  CartRepository get _repo => ref.read(cartRepositoryProvider);

  @override
  Future<Cart> build() => _repo.getCart();

  Future<void> add(String productId, int quantity) async {
    state = AsyncData(await _repo.addItem(productId, quantity));
  }

  Future<void> setQuantity(String productId, int quantity) async {
    state = AsyncData(await _repo.setQuantity(productId, quantity));
  }

  Future<void> remove(String productId) async {
    state = AsyncData(await _repo.removeItem(productId));
  }

  Future<void> clear() async {
    state = AsyncData(await _repo.clear());
  }
}

final cartControllerProvider =
    AutoDisposeAsyncNotifierProvider<CartController, Cart>(CartController.new);

/// Total units in the cart (0 while loading) — drives the nav badge.
final cartCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(cartControllerProvider).valueOrNull?.totalQuantity ?? 0;
});

/// Units of a specific product currently in the cart (0 if absent). Powers the
/// Blinkit-style add→stepper morph on each product card.
final cartQuantityProvider = Provider.autoDispose.family<int, String>((ref, productId) {
  final cart = ref.watch(cartControllerProvider).valueOrNull;
  if (cart == null) return 0;
  for (final line in cart.items) {
    if (line.productId == productId) return line.quantity;
  }
  return 0;
});
