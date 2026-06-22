import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/domain/product.dart';
import '../domain/cart_item.dart';

/// Manages the local shopping cart (a list of [CartItem]s keyed by variant).
class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  void add(Product product, ProductVariant variant, {int quantity = 1}) {
    final qty = quantity < variant.minOrderQty ? variant.minOrderQty : quantity;
    final index = state.indexWhere((item) => item.variant.id == variant.id);
    if (index >= 0) {
      final existing = state[index];
      final updated = existing.copyWith(quantity: existing.quantity + qty);
      state = [...state]..[index] = updated;
    } else {
      state = [...state, CartItem(product: product, variant: variant, quantity: qty)];
    }
  }

  void setQuantity(String variantId, int quantity) {
    if (quantity <= 0) {
      remove(variantId);
      return;
    }
    state = [
      for (final item in state)
        if (item.variant.id == variantId) item.copyWith(quantity: quantity) else item,
    ];
  }

  void remove(String variantId) {
    state = state.where((item) => item.variant.id != variantId).toList();
  }

  void clear() => state = const [];
}

final cartControllerProvider =
    NotifierProvider<CartController, List<CartItem>>(CartController.new);

/// Total number of units across all cart lines.
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartControllerProvider).fold(0, (sum, item) => sum + item.quantity);
});

/// Cart subtotal in currency units.
final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(cartControllerProvider).fold(0.0, (sum, item) => sum + item.lineTotal);
});
