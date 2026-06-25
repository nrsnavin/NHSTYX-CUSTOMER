import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/domain/product.dart';
import '../data/wishlist_repository.dart';

/// The set of product ids the shop has saved. Kept separate from the full
/// product list so the heart toggle on every product card can react instantly
/// (optimistic) without re-fetching cards.
class WishlistIdsController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return ref.watch(wishlistRepositoryProvider).ids();
  }

  bool isWishlisted(String productId) =>
      state.valueOrNull?.contains(productId) ?? false;

  /// Adds or removes a product, updating the local set optimistically and
  /// rolling back if the server call fails.
  Future<void> toggle(String productId) async {
    final repo = ref.read(wishlistRepositoryProvider);
    final current = state.valueOrNull ?? <String>{};
    final adding = !current.contains(productId);

    final next = Set<String>.from(current);
    adding ? next.add(productId) : next.remove(productId);
    state = AsyncData(next);

    try {
      adding ? await repo.add(productId) : await repo.remove(productId);
      // Keep the wishlist screen's full cards in sync.
      ref.invalidate(wishlistProvider);
    } catch (e) {
      state = AsyncData(current); // revert
      rethrow;
    }
  }
}

final wishlistIdsProvider =
    AsyncNotifierProvider<WishlistIdsController, Set<String>>(WishlistIdsController.new);

/// Full product cards for the wishlist screen.
final wishlistProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(wishlistRepositoryProvider).list();
});
