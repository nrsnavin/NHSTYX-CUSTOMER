import 'package:flutter_test/flutter_test.dart';
import 'package:nhstyx_customer/src/features/cart/domain/cart.dart';
import 'package:nhstyx_customer/src/features/products/domain/product.dart';
import 'package:nhstyx_customer/src/shared/formatters.dart';

void main() {
  group('Product', () {
    test('parses paise + price tiers and computes the lowest price', () {
      final product = Product.fromJson({
        'id': 'p1',
        'name': "Women's Cotton Kurti",
        'unit': 'PIECE',
        'pricePaise': 32000,
        'gstRatePercent': 5,
        'moqQty': 6,
        'stockQty': 240,
        'priceTiers': [
          {'minQty': 12, 'pricePaise': 30000},
          {'minQty': 50, 'pricePaise': 28000},
        ],
      });

      expect(product.pricePaise, 32000);
      expect(product.priceTiers.length, 2);
      expect(product.fromPricePaise, 28000); // cheapest tier
      expect(product.inStock, isTrue);
    });
  });

  group('Cart', () {
    test('parses server cart payload', () {
      final cart = Cart.fromJson({
        'items': [
          {
            'productId': 'p1',
            'name': 'Kurti',
            'unit': 'PIECE',
            'quantity': 12,
            'moqQty': 6,
            'stockQty': 240,
            'unitPricePaise': 30000,
            'lineSubtotalPaise': 360000,
            'gstRatePercent': 5,
          },
        ],
        'itemCount': 1,
        'totalQuantity': 12,
        'subtotalPaise': 360000,
      });

      expect(cart.items.single.unitPricePaise, 30000);
      expect(cart.subtotalPaise, 360000);
      expect(cart.isEmpty, isFalse);
    });

    test('empty cart constant', () {
      expect(Cart.empty.isEmpty, isTrue);
      expect(Cart.empty.subtotalPaise, 0);
    });
  });

  group('formatPaise', () {
    test('formats integer paise as rupees', () {
      expect(formatPaise(32000), '₹320.00');
      expect(formatPaise(360000), '₹3,600.00');
      expect(formatPaise(0), '₹0.00');
    });
  });
}
