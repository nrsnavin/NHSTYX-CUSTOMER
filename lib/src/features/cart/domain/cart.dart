int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// A line in the server-side cart, with price already resolved (tier-aware).
class CartLine {
  const CartLine({
    required this.productId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.moqQty,
    required this.stockQty,
    required this.unitPricePaise,
    required this.lineSubtotalPaise,
    this.brand,
    this.imageUrl,
    this.gstRatePercent = 0,
  });

  final String productId;
  final String name;
  final String unit;
  final int quantity;
  final int moqQty;
  final int stockQty;
  final int unitPricePaise;
  final int lineSubtotalPaise;
  final String? brand;
  final String? imageUrl;
  final int gstRatePercent;

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      productId: json['productId'] as String,
      name: (json['name'] ?? '') as String,
      unit: (json['unit'] ?? 'PIECE') as String,
      quantity: _toInt(json['quantity']),
      moqQty: json['moqQty'] == null ? 1 : _toInt(json['moqQty']),
      stockQty: _toInt(json['stockQty']),
      unitPricePaise: _toInt(json['unitPricePaise']),
      lineSubtotalPaise: _toInt(json['lineSubtotalPaise']),
      brand: json['brand'] as String?,
      imageUrl: json['imageUrl'] as String?,
      gstRatePercent: _toInt(json['gstRatePercent']),
    );
  }
}

class Cart {
  const Cart({
    required this.items,
    required this.itemCount,
    required this.totalQuantity,
    required this.subtotalPaise,
  });

  final List<CartLine> items;
  final int itemCount;
  final int totalQuantity;
  final int subtotalPaise;

  bool get isEmpty => items.isEmpty;

  static const empty = Cart(items: [], itemCount: 0, totalQuantity: 0, subtotalPaise: 0);

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => CartLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemCount: _toInt(json['itemCount']),
      totalQuantity: _toInt(json['totalQuantity']),
      subtotalPaise: _toInt(json['subtotalPaise']),
    );
  }
}
