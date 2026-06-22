import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhstyx_customer/src/features/cart/presentation/cart_controller.dart';
import 'package:nhstyx_customer/src/features/products/domain/product.dart';

ProductVariant _variant(String id, {double price = 100, int moq = 1}) => ProductVariant(
      id: id,
      sku: 'SKU-$id',
      price: price,
      minOrderQty: moq,
      stockQuantity: 50,
    );

Product _product(String id, {List<ProductVariant>? variants}) => Product(
      id: id,
      name: 'Product $id',
      variants: variants ?? [_variant(id)],
    );

void main() {
  test('adds items and computes count + subtotal', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    final product = _product('1', variants: [_variant('1', price: 100)]);
    cart.add(product, product.variants.first, quantity: 2);

    expect(container.read(cartCountProvider), 2);
    expect(container.read(cartSubtotalProvider), 200);
  });

  test('adding the same variant merges quantities', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    final product = _product('1');
    cart.add(product, product.variants.first, quantity: 1);
    cart.add(product, product.variants.first, quantity: 3);

    expect(container.read(cartControllerProvider).length, 1);
    expect(container.read(cartCountProvider), 4);
  });

  test('respects minimum order quantity', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    final variant = _variant('2', moq: 6);
    final product = _product('2', variants: [variant]);
    cart.add(product, variant, quantity: 1); // below MOQ → bumped up

    expect(container.read(cartCountProvider), 6);
  });

  test('setQuantity to zero removes the line', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartControllerProvider.notifier);
    final product = _product('3');
    cart.add(product, product.variants.first);
    cart.setQuantity(product.variants.first.id, 0);

    expect(container.read(cartControllerProvider), isEmpty);
  });
}
