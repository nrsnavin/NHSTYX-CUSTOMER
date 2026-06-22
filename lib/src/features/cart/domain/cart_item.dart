import '../../products/domain/product.dart';

/// A line in the local shopping cart (held client-side until checkout).
class CartItem {
  const CartItem({
    required this.product,
    required this.variant,
    required this.quantity,
  });

  final Product product;
  final ProductVariant variant;
  final int quantity;

  double get lineTotal => variant.price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        product: product,
        variant: variant,
        quantity: quantity ?? this.quantity,
      );
}
