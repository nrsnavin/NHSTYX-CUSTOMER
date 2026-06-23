int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class OrderItem {
  const OrderItem({
    required this.productName,
    required this.quantity,
    required this.unitPricePaise,
    required this.lineTotalPaise,
  });

  final String productName;
  final int quantity;
  final int unitPricePaise;
  final int lineTotalPaise;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: (json['productName'] ?? 'Item') as String,
      quantity: _toInt(json['quantity']),
      unitPricePaise: _toInt(json['unitPricePaise']),
      lineTotalPaise: _toInt(json['lineTotalPaise']),
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.subtotalPaise,
    required this.totalPaise,
    required this.amountDuePaise,
    required this.createdAt,
    this.cgstPaise = 0,
    this.sgstPaise = 0,
    this.igstPaise = 0,
    this.items = const [],
  });

  final String id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final int subtotalPaise;
  final int cgstPaise;
  final int sgstPaise;
  final int igstPaise;
  final int totalPaise;
  final int amountDuePaise;
  final DateTime createdAt;
  final List<OrderItem> items;

  int get taxPaise => cgstPaise + sgstPaise + igstPaise;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      status: (json['status'] ?? 'PENDING') as String,
      paymentStatus: (json['paymentStatus'] ?? 'UNPAID') as String,
      paymentMethod: (json['paymentMethod'] ?? 'COD') as String,
      subtotalPaise: _toInt(json['subtotalPaise']),
      cgstPaise: _toInt(json['cgstPaise']),
      sgstPaise: _toInt(json['sgstPaise']),
      igstPaise: _toInt(json['igstPaise']),
      totalPaise: _toInt(json['totalPaise']),
      amountDuePaise: _toInt(json['amountDuePaise']),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
