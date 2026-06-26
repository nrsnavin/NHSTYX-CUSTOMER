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
    this.id,
    this.productId,
    this.variantId,
    this.variantName,
  });

  /// The order-line id — needed to raise a return against this line.
  final String? id;
  final String productName;
  final int quantity;
  final int unitPricePaise;
  final int lineTotalPaise;

  /// The catalog product id, used to re-add the line when reordering.
  final String? productId;

  /// The ordered variant (size/colour), if any.
  final String? variantId;
  final String? variantName;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String?,
      productName: (json['productName'] ?? 'Item') as String,
      quantity: _toInt(json['quantity']),
      unitPricePaise: _toInt(json['unitPricePaise']),
      lineTotalPaise: _toInt(json['lineTotalPaise']),
      productId: json['productId'] as String?,
      variantId: json['variantId'] as String?,
      variantName: json['variantName'] as String?,
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
    this.courierName,
    this.trackingNumber,
    this.trackingUrl,
    this.shippedAt,
    this.deliveredAt,
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

  /// Shipment tracking (set when the order is dispatched).
  final String? courierName;
  final String? trackingNumber;
  final String? trackingUrl;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  int get taxPaise => cgstPaise + sgstPaise + igstPaise;

  bool get hasTracking => (trackingNumber ?? '').isNotEmpty;

  /// Whether the shop can raise a return (fulfilled, not cancelled/returned).
  bool get isReturnable =>
      const {'CONFIRMED', 'PACKED', 'SHIPPED', 'DELIVERED'}.contains(status);

  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
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
      courierName: json['courierName'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      trackingUrl: json['trackingUrl'] as String?,
      shippedAt: parseDate(json['shippedAt']),
      deliveredAt: parseDate(json['deliveredAt']),
    );
  }
}
