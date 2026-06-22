double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class OrderItem {
  const OrderItem({
    required this.productName,
    required this.quantity,
    required this.lineTotal,
  });

  final String productName;
  final int quantity;
  final double lineTotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: (json['productName'] ?? 'Item') as String,
      quantity: (json['quantity'] ?? 0) as int,
      lineTotal: _toDouble(json['lineTotal']),
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.createdAt,
    this.items = const [],
  });

  final String id;
  final String orderNumber;
  final String status;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> items;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      status: (json['status'] ?? 'PLACED') as String,
      total: _toDouble(json['total']),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
