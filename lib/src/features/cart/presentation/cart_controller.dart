import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/domain/product.dart';
import '../data/cart_repository.dart';
import '../domain/cart.dart';

/// Server-backed cart with OPTIMISTIC updates: each mutation applies instantly
/// to local state (so the UI — add→stepper morph, cart bar — reacts with zero
/// perceived lag), then reconciles with the server's authoritative cart. On
/// failure it reverts to the last good cart and rethrows so the UI can show a
/// message without losing the basket.
class CartController extends AutoDisposeAsyncNotifier<Cart> {
  CartRepository get _repo => ref.read(cartRepositoryProvider);

  @override
  Future<Cart> build() => _repo.getCart();

  Future<void> add(Product product, int quantity) async {
    final current = state.valueOrNull ?? Cart.empty;
    final existing = current.quantityOf(product.id);
    final newQty =
        (existing + quantity) < product.moqQty ? product.moqQty : existing + quantity;
    final unitPrice = product.unitPricePaiseFor(newQty);

    // Optimistic: morph the card to a stepper immediately.
    state = AsyncData(current.withLine(CartLine(
      productId: product.id,
      name: product.name,
      unit: product.unit,
      quantity: newQty,
      moqQty: product.moqQty,
      stockQty: product.stockQty,
      unitPricePaise: unitPrice,
      lineSubtotalPaise: unitPrice * newQty,
      brand: product.brand,
      imageUrl: product.imageUrl,
      gstRatePercent: product.gstRatePercent,
    )));

    try {
      state = AsyncData(await _repo.addItem(product.id, quantity));
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> setQuantity(String productId, int quantity) async {
    final current = state.valueOrNull;

    if (current != null) {
      if (quantity <= 0) {
        state = AsyncData(current.withRemoved(productId));
      } else {
        final i = current.items.indexWhere((l) => l.productId == productId);
        if (i >= 0) {
          final l = current.items[i];
          state = AsyncData(current.withLine(CartLine(
            productId: l.productId,
            name: l.name,
            unit: l.unit,
            quantity: quantity,
            moqQty: l.moqQty,
            stockQty: l.stockQty,
            unitPricePaise: l.unitPricePaise,
            lineSubtotalPaise: l.unitPricePaise * quantity,
            brand: l.brand,
            imageUrl: l.imageUrl,
            gstRatePercent: l.gstRatePercent,
          )));
        }
      }
    }

    try {
      state = AsyncData(await _repo.setQuantity(productId, quantity));
    } catch (e) {
      if (current != null) state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> remove(String productId) async {
    final current = state.valueOrNull;
    if (current != null) state = AsyncData(current.withRemoved(productId));
    try {
      state = AsyncData(await _repo.removeItem(productId));
    } catch (e) {
      if (current != null) state = AsyncData(current);
      rethrow;
    }
  }

  /// Adds a specific variant to the cart. Variant lines can't use the optimistic
  /// product-keyed path (several variants share a productId), so this is
  /// server-authoritative: it calls the API and adopts the returned cart.
  Future<void> addVariant(String productId, String variantId, int quantity) async {
    state = AsyncData(await _repo.addItem(productId, quantity, variantId: variantId));
  }

  /// Sets the quantity of a specific (product, variant) line; 0 removes it.
  /// Server-authoritative, so it targets exactly one variant line.
  Future<void> setLineQuantity(String productId, int quantity, {String? variantId}) async {
    final current = state.valueOrNull;
    try {
      state = AsyncData(
        quantity <= 0
            ? await _repo.removeItem(productId, variantId: variantId)
            : await _repo.setQuantity(productId, quantity, variantId: variantId),
      );
    } catch (e) {
      if (current != null) state = AsyncData(current);
      rethrow;
    }
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
